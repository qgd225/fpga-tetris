module net_screen_tx(
  input         Clk_74M,
  input         Reset_n,

  //-------- 画面输入（来自 hdmi / frame）--------
  input         de,             // 1 = 当前像素在有效区(1280x720)
  input  [10:0] hcounter,
  input  [10:0] vcounter,
  input  [23:0] rgb,

  //-------- 以太网引脚 --------
  input         rgmii_rx_clk_i,
  input  [3:0]  rgmii_rxd,
  input         rgmii_rxdv,
  output        rgmii_tx_clk,
  output  [3:0] rgmii_txd,
  output        rgmii_txen,
  output        eth_rstn,
  output        eth_mdc,
  output        eth_mdio
);
parameter DST_MAC    = 48'hFF_FF_FF_FF_FF_FF;   // 默认广播，PC 端不用先知道也行
parameter DST_IP     = 32'hFF_FF_FF_FF;
parameter DST_PORT   = 16'd5000;
parameter FPS_DIV    = 1;                        // 1=60fps  2=30fps  3=20fps
parameter PAL_FRAMES = 60;                       // 每 60 帧插一个调色板包(=1s@60fps)
parameter LINE_LEN   = 16'd1287;                 // 7 字节包头 + 1280 个标号
parameter PAL_LEN    = 16'd112;                  // 4 + 27*4
parameter PAL_N      = 8'd27;

assign eth_rstn = 1'b1;
assign eth_mdc  = 1'b1;
assign eth_mdio = 1'b1;

//============================================================
//    eth_udp_loopback_rgmii 例化
//============================================================
reg         tog_line;
reg         tog_pal;
reg  [7:0]  tx_fifo_din;
wire        tx_fifo_we;
wire        tx_start_125;
wire [15:0] tx_len_125;
wire        pll_locked;
wire        clk125m;
reg         len_sel;          // 0=行包(1287)  1=调色板包(112)

eth_udp_loopback_rgmii eth_udp_loopback_rgmii_inst(
  .reset_n        (Reset_n        ),
  .clk_74m        (Clk_74M        ),
  .clk125m        (clk125m        ),
  .rgmii_rx_clk_i (rgmii_rx_clk_i ),
  .rgmii_rxd      (rgmii_rxd      ),
  .rgmii_rxdv     (rgmii_rxdv     ),
  .rgmii_tx_clk   (rgmii_tx_clk   ),
  .rgmii_txd      (rgmii_txd      ),
  .rgmii_txen     (rgmii_txen     ),
  .rx_rd_en       (1'b0           ),          // 键盘以后再加
  .tx             (tx_fifo_din    ),
  .tx_wr_en       (tx_fifo_we     ),
  .tx_start       (tx_start_125   ),
  .tx_dst_mac     (DST_MAC        ),
  .tx_dst_ip      (DST_IP         ),
  .tx_dst_port    (DST_PORT       ),
  .tx_data_length (tx_len_125     ),
  .msg_rd_en      (1'b0           ),
  .pll_locked     (pll_locked     )
);

//============================================================
//    clk125m 域：tx_start 脉冲 + 包长选择（toggle 握手）
//============================================================
reg  gl1, gl2, gl3;
reg  gp1, gp2, gp3;

always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gl1 <= 1'b0;
  else         gl1 <= tog_line;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gl2 <= 1'b0;
  else         gl2 <= gl1;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gl3 <= 1'b0;
  else         gl3 <= gl2;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gp1 <= 1'b0;
  else         gp1 <= tog_pal;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gp2 <= 1'b0;
  else         gp2 <= gp1;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gp3 <= 1'b0;
  else         gp3 <= gp2;
end

wire p_line = gl2 ^ gl3;
wire p_pal  = gp2 ^ gp3;

assign tx_start_125 = p_line | p_pal;
assign tx_len_125   = p_pal ? PAL_LEN : LINE_LEN;

//============================================================
//    pll_locked 同步到 74.25 域
//============================================================
reg pl_s1, pl_s2;

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) pl_s1 <= 1'b0;
  else         pl_s1 <= pll_locked;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) pl_s2 <= 1'b0;
  else         pl_s2 <= pl_s1;
end
wire link_up = pl_s2;

//============================================================
//    像素打一拍 + 颜色查表
//============================================================
reg        de_r, de_r2;
reg [10:0] vc_r;
reg [23:0] rgb_r;
reg  [7:0] code_r;
reg [10:0] line_num;

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) de_r <= 1'b0;
  else         de_r <= de;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) de_r2 <= 1'b0;
  else         de_r2 <= de_r;
end
always@(posedge Clk_74M)begin
  vc_r <= vcounter;
end
always@(posedge Clk_74M)begin
  rgb_r <= rgb;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)  line_num <= 11'd0;
  else if(de_r) line_num <= vc_r;
end

always@(*)begin
  case(rgb_r)
  24'h00_00_00: code_r = 8'd0;      // 空/黑
  24'h00_CC_FF: code_r = 8'd1;      // I
  24'h99_33_CC: code_r = 8'd2;      // T
  24'hFF_FF_00: code_r = 8'd3;      // O
  24'hE6_39_46: code_r = 8'd4;      // S
  24'h55_A6_30: code_r = 8'd5;      // Z
  24'hF7_7F_24: code_r = 8'd6;      // L
  24'hFF_4D_A6: code_r = 8'd7;      // J
  24'h99_EE_FF: code_r = 8'd8;      // 幽灵 I
  24'hD9_B3_E6: code_r = 8'd9;      // 幽灵 T
  24'hFF_FF_99: code_r = 8'd10;     // 幽灵 O
  24'hFF_B3_B9: code_r = 8'd11;     // 幽灵 S
  24'hBD_E0_AA: code_r = 8'd12;     // 幽灵 Z
  24'hFF_D9_B3: code_r = 8'd13;     // 幽灵 L
  24'hFF_B3_D9: code_r = 8'd14;     // 幽灵 J
  24'hEE_EE_EE: code_r = 8'd15;     // 闪白
  24'hFF_FF_FF: code_r = 8'd16;     // 白(边框/分数/时间/框)
  24'h10_10_10: code_r = 8'd17;
  24'h20_20_20: code_r = 8'd18;
  24'h40_40_40: code_r = 8'd19;
  24'h60_60_60: code_r = 8'd20;
  24'h90_90_90: code_r = 8'd21;
  24'hB0_B0_B0: code_r = 8'd22;
  24'hD8_D8_D8: code_r = 8'd23;
  24'h30_30_30: code_r = 8'd24;
  24'h00_E5_FF: code_r = 8'd25;
  24'h00_69_7F: code_r = 8'd26;
  default:      code_r = 8'd0;
  endcase
end

//============================================================
//    行末/场末 打包序列器
//============================================================
localparam SEQ_IDLE = 3'd0;
localparam SEQ_HDR  = 3'd1;   // 写下一行包头 7 字节
localparam SEQ_TOG  = 3'd2;   // tx_start（行包）
localparam SEQ_PAL  = 3'd3;   // 写调色板包
localparam SEQ_PTOG = 3'd4;   // tx_start（调色板包）
localparam SEQ_H0   = 3'd5;   // 写下一帧第 0 行包头
localparam SEQ_WAIT = 3'd6;   // 等 MAC 发完上一包（调色板包用）

reg [2:0]  seq;
reg [6:0]  seq_idx;
reg [15:0] frame_cnt;
reg [3:0]  fps_cnt;
reg [7:0]  pal_cnt;
reg [10:0] wait_cnt;
reg        start_pulse_74;
reg        first;
reg        armed;

wire de_fall   = de_r2 && (!de_r);
wire line_719  = (line_num == 11'd719);
wire frame_on  = (fps_cnt == 4'd0);
wire pal_due   = (pal_cnt == PAL_FRAMES - 1);
wire send_pal  = line_719 && pal_due && frame_on;

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  seq <= SEQ_IDLE;
  else
  case(seq)
  SEQ_IDLE: if(de_fall && frame_on && link_up)
            seq <= SEQ_TOG;
  SEQ_TOG:  if(send_pal)        seq <= SEQ_WAIT;
            else if(line_719)   seq <= SEQ_H0;
            else                seq <= SEQ_HDR;
  SEQ_WAIT: if(wait_cnt == 11'd1023 && (!de_r)) seq <= SEQ_PAL;
  SEQ_HDR:  if(seq_idx == 7'd6)   seq <= SEQ_IDLE;
  SEQ_PAL:  if(seq_idx == 7'd111) seq <= SEQ_PTOG;
  SEQ_PTOG: seq <= SEQ_H0;
  SEQ_H0:   if(seq_idx == 7'd6)   seq <= SEQ_IDLE;
  default:  seq <= SEQ_IDLE;
  endcase
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  seq_idx <= 7'd0;
  else if(seq == SEQ_IDLE || seq == SEQ_TOG || seq == SEQ_PTOG || seq == SEQ_WAIT)
  seq_idx <= 7'd0;
  else if(seq == SEQ_PAL)
  seq_idx <= (seq_idx == 7'd111) ? 7'd0 : (seq_idx + 7'd1);
  else
  seq_idx <= (seq_idx == 7'd6) ? 7'd0 : (seq_idx + 7'd1);
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  start_pulse_74 <= 1'b0;
  else if((seq == SEQ_TOG || seq == SEQ_PTOG) && (!first))
  start_pulse_74 <= 1'b1;
  else
  start_pulse_74 <= 1'b0;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) first <= 1'b1;
  else if(seq == SEQ_TOG) first <= 1'b0;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) armed <= 1'b0;
  else if(de_fall) armed <= 1'b1;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) tog_line <= 1'b0;
  else if(start_pulse_74 && (!len_sel)) tog_line <= ~tog_line;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) tog_pal <= 1'b0;
  else if(start_pulse_74 && len_sel) tog_pal <= ~tog_pal;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  len_sel <= 1'b0;
  else if(seq == SEQ_PAL)
  len_sel <= 1'b1;
  else if(seq == SEQ_HDR || seq == SEQ_H0)
  len_sel <= 1'b0;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  frame_cnt <= 16'd0;
  else if(de_fall && frame_on && line_719)
  frame_cnt <= frame_cnt + 16'd1;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  fps_cnt <= 4'd0;
  else if(de_fall && line_719)begin
      if(fps_cnt == (FPS_DIV - 1))
      fps_cnt <= 4'd0;
      else
      fps_cnt <= fps_cnt + 4'd1;
  end
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  pal_cnt <= 8'd0;
  else if(de_fall && frame_on && line_719)begin
      if(pal_due)
      pal_cnt <= 8'd0;
      else
      pal_cnt <= pal_cnt + 8'd1;
  end
end

//============================================================
//    包头 / 调色板包 字节
//============================================================
wire [10:0] hdr_line  = (seq == SEQ_H0) ? 11'd0 : (line_num + 11'd1);
wire [15:0] hdr_frame = frame_cnt;

reg  [7:0] hdr_byte;
always@(*)begin
  case(seq_idx)
  7'd0: hdr_byte = 8'hA5;
  7'd1: hdr_byte = 8'h5A;
  7'd2: hdr_byte = 8'd1;
  7'd3: hdr_byte = hdr_frame[15:8];
  7'd4: hdr_byte = hdr_frame[7:0];
  7'd5: hdr_byte = {5'd0, hdr_line[10:8]};
  7'd6: hdr_byte = hdr_line[7:0];
  default: hdr_byte = 8'h00;
  endcase
end

wire [4:0] pel     = seq_idx[6:2] - 5'd1;
wire [1:0] psub    = seq_idx[1:0];

reg [23:0] pal_rgb;
always@(*)begin
  case(pel)
  5'd0:  pal_rgb = 24'h00_00_00;
  5'd1:  pal_rgb = 24'h00_CC_FF;
  5'd2:  pal_rgb = 24'h99_33_CC;
  5'd3:  pal_rgb = 24'hFF_FF_00;
  5'd4:  pal_rgb = 24'hE6_39_46;
  5'd5:  pal_rgb = 24'h55_A6_30;
  5'd6:  pal_rgb = 24'hF7_7F_24;
  5'd7:  pal_rgb = 24'hFF_4D_A6;
  5'd8:  pal_rgb = 24'h99_EE_FF;
  5'd9:  pal_rgb = 24'hD9_B3_E6;
  5'd10: pal_rgb = 24'hFF_FF_99;
  5'd11: pal_rgb = 24'hFF_B3_B9;
  5'd12: pal_rgb = 24'hBD_E0_AA;
  5'd13: pal_rgb = 24'hFF_D9_B3;
  5'd14: pal_rgb = 24'hFF_B3_D9;
  5'd15: pal_rgb = 24'hEE_EE_EE;
  5'd16: pal_rgb = 24'hFF_FF_FF;
  5'd17: pal_rgb = 24'h10_10_10;
  5'd18: pal_rgb = 24'h20_20_20;
  5'd19: pal_rgb = 24'h40_40_40;
  5'd20: pal_rgb = 24'h60_60_60;
  5'd21: pal_rgb = 24'h90_90_90;
  5'd22: pal_rgb = 24'hB0_B0_B0;
  5'd23: pal_rgb = 24'hD8_D8_D8;
  5'd24: pal_rgb = 24'h30_30_30;
  5'd25: pal_rgb = 24'h00_E5_FF;
  5'd26: pal_rgb = 24'h00_69_7F;
  default: pal_rgb = 24'h00_00_00;
  endcase
end

reg [7:0] pal_byte;
always@(*)begin
  if(seq_idx == 7'd0)      pal_byte = 8'hA5;
  else if(seq_idx == 7'd1) pal_byte = 8'h5A;
  else if(seq_idx == 7'd2) pal_byte = 8'd2;
  else if(seq_idx == 7'd3) pal_byte = PAL_N;
  else begin
      case(psub)
      2'd0: pal_byte = {3'd0, pel};
      2'd1: pal_byte = pal_rgb[23:16];
      2'd2: pal_byte = pal_rgb[15:8];
      2'd3: pal_byte = pal_rgb[7:0];
      endcase
  end
end

//============================================================
//    FIFO 写：像素 / 包头 / 调色板
//============================================================
always@(*)begin
  if(seq == SEQ_HDR || seq == SEQ_H0)
  tx_fifo_din = hdr_byte;
  else if(seq == SEQ_PAL)
  tx_fifo_din = pal_byte;
  else if(de_r)
  tx_fifo_din = code_r;
  else
  tx_fifo_din = 8'h00;
end

assign tx_fifo_we = ((de_r && frame_on && link_up && armed)
                  || (seq == SEQ_HDR) || (seq == SEQ_PAL) || (seq == SEQ_H0));

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) wait_cnt <= 11'd0;
  else if(seq == SEQ_WAIT) wait_cnt <= wait_cnt + 11'd1;
  else wait_cnt <= 11'd0;
end
endmodule
