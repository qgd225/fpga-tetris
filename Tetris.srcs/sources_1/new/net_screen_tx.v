// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: net_screen_tx
// 作用: 协调以太网画面发送以及电脑端键盘输入。
// 分工: 网络按键帧解析、按键状态和复位请求由 net_keyboard_receiver 负责。
// 时钟/复位: Clk_74M, Reset_n 和 por_n 均为低有效。
//============================================================
module net_screen_tx(
  input         Clk_74M,
  input         Reset_n,
  input         por_n,

//-------- 画面输入（来自 hdmi / frame）--------
  input         de,  // 1 = 当前像素在有效区(1280x720)
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
  output        eth_mdio,

//-------- 键盘(网络)按键：形状与物理按键一致 --------
  output        kb_left_p,
  output        kb_right_p,
  output        kb_left_held,
  output        kb_right_held,
  output        kb_drop_r,
  output        kb_drop_en,
  output        kb_rotate_p,
  output        kb_switch_r,
  output        kb_switch_en,
  output        kb_hold_p,
  output        kb_hold_en,
  output        kb_reset_en,
  output        kb_activity
);
parameter DST_MAC    = 48'hFF_FF_FF_FF_FF_FF;  // 默认广播，PC 端不用先知道也行
parameter DST_IP     = 32'hFF_FF_FF_FF;
parameter DST_PORT   = 16'd5000;
parameter FPS_DIV    = 1;  // 1=60fps  2=30fps  3=20fps
parameter PAL_FRAMES = 60;  // 每 60 帧插一个调色板包(=1s@60fps)
parameter LINE_LEN   = 16'd1287;  // 7 字节包头 + 1280 个标号
parameter PAL_LEN    = 16'd228;
parameter [7:0] PAL_LAST = 8'd227;
parameter PAL_N      = 8'd56;
parameter KB_TIMEOUT = 24'd14_850_000;  // 200ms @74.25MHz 没有按键包就全部松开
parameter KB_RST_CNT = 25'd1_485_000;  // 小键盘9复位把 Reset_n 拉低 20ms
parameter KB_ACT_CNT = 25'd22_275_000;  // 收到按键包后 kb_activity 亮 0.3s
parameter KB_GAP_MAX = 8'd255;  // 包内字节间隔超时=包不完整，重新同步

assign eth_rstn = 1'b1;
assign eth_mdc  = 1'b1;
assign eth_mdio = 1'b1;
wire [7:0] rx_byte;
wire       rx_empty;
wire       kb_rd_en;

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
reg         pal_next;

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
  .rx             (rx_byte        ),
  .rx_empty       (rx_empty       ),
  .rx_rd_en       (kb_rd_en       ),
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
wire [5:0] code_r;

rgb_to_palette rgb_to_palette_inst(
  .Clk(Clk_74M),
  .rgb(rgb_r),
  .code(code_r)
);
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

// RGB→调色板索引：8 位无碰撞哈希后查 BRAM 表，避免 24 位全色比较。
// 映射由 rgb_to_palette.v 的同步 ROM 完成，结果直接写入 TX FIFO。
//============================================================
//    行末/场末 打包序列器
//============================================================
localparam SEQ_IDLE = 4'd0;
localparam SEQ_HDR  = 4'd1;  // 写下一行包头 7 字节
localparam SEQ_TOG  = 4'd2;  // tx_start（行包）
localparam SEQ_PAL  = 4'd3;  // 写调色板包
localparam SEQ_PTOG = 4'd4;  // tx_start（调色板包）
localparam SEQ_H0   = 4'd5;  // 写下一帧第 0 行包头
localparam SEQ_WAIT = 4'd6;  // 等 MAC 发完上一包

reg [3:0]  seq;
reg [7:0]  seq_idx;
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

//============================================================
//    行末/调色板发送标志寄存
//============================================================
reg         h0_lat;
reg         pal_lat;

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) h0_lat <= 1'b0;
  else if(seq == SEQ_TOG) h0_lat <= line_719;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) pal_lat <= 1'b0;
  else if(seq == SEQ_TOG) pal_lat <= send_pal;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  seq <= SEQ_IDLE;
  else
  case(seq)
  SEQ_IDLE: if(de_fall && frame_on && link_up)
            seq <= SEQ_TOG;
  SEQ_TOG:  if(send_pal) seq <= SEQ_WAIT;
            else if(line_719)                                 seq <= SEQ_H0;
            else                                              seq <= SEQ_HDR;
  SEQ_WAIT: if(wait_cnt == 11'd1023 && (!de_r))begin
                if(pal_lat)                seq <= SEQ_PAL;
                else if(h0_lat)            seq <= SEQ_H0;
                else                       seq <= SEQ_HDR;
            end
  SEQ_HDR:  if(seq_idx == 7'd6)   seq <= SEQ_IDLE;
  SEQ_PAL:  if(seq_idx == PAL_LAST) seq <= SEQ_PTOG;
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
  seq_idx <= (seq_idx == PAL_LAST) ? 7'd0 : (seq_idx + 7'd1);
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
  else if(start_pulse_74 && !pal_next) tog_line <= ~tog_line;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) tog_pal <= 1'b0;
  else if(start_pulse_74 && pal_next) tog_pal <= ~tog_pal;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  pal_next <= 1'b0;
  else if(seq == SEQ_PAL)
  pal_next <= 1'b1;
  else if(seq == SEQ_HDR || seq == SEQ_H0)
  pal_next <= 1'b0;
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

wire [5:0] pel     = seq_idx[7:2] - 6'd1;
wire [1:0] psub    = seq_idx[1:0];

reg [23:0] pal_rgb;
always@(*)begin
  case(pel)
  6'd0: pal_rgb = 24'h000000;
  6'd1: pal_rgb = 24'h38B6C8;
  6'd2: pal_rgb = 24'h9B6BB5;
  6'd3: pal_rgb = 24'hD9B23C;
  6'd4: pal_rgb = 24'hC2453A;
  6'd5: pal_rgb = 24'h4FA86B;
  6'd6: pal_rgb = 24'hD97B33;
  6'd7: pal_rgb = 24'h3E6FBF;
  6'd8: pal_rgb = 24'h74CCD8;
  6'd9: pal_rgb = 24'hB997CB;
  6'd10: pal_rgb = 24'hE4C976;
  6'd11: pal_rgb = 24'hD47D75;
  6'd12: pal_rgb = 24'h84C297;
  6'd13: pal_rgb = 24'hE4A370;
  6'd14: pal_rgb = 24'h789AD2;
  6'd15: pal_rgb = 24'hEEEEEE;
  6'd16: pal_rgb = 24'hE8EEF2;
  6'd17: pal_rgb = 24'h101010;
  6'd18: pal_rgb = 24'h202020;
  6'd19: pal_rgb = 24'h404040;
  6'd20: pal_rgb = 24'h606060;
  6'd21: pal_rgb = 24'h3A4A58;
  6'd22: pal_rgb = 24'h5B6E7E;
  6'd23: pal_rgb = 24'h243240;
  6'd24: pal_rgb = 24'h303030;
  6'd25: pal_rgb = 24'h2FA8B8;
  6'd26: pal_rgb = 24'h7A2418;
  6'd27: pal_rgb = 24'h0A1118;
  6'd28: pal_rgb = 24'h2A3644;
  6'd29: pal_rgb = 24'h1C2836;
  6'd30: pal_rgb = 24'h1F646E;
  6'd31: pal_rgb = 24'h553B64;
  6'd32: pal_rgb = 24'h776221;
  6'd33: pal_rgb = 24'h6B2620;
  6'd34: pal_rgb = 24'h2B5C3B;
  6'd35: pal_rgb = 24'h77441C;
  6'd36: pal_rgb = 24'h223D69;
  6'd37: pal_rgb = 24'h7FE3EC;
  6'd38: pal_rgb = 24'hC4527A;
  6'd39: pal_rgb = 24'h1B6B76;
  6'd40: pal_rgb = 24'h7E2E4A;
  6'd41: pal_rgb = 24'hE8A23C;
  6'd42: pal_rgb = 24'hFFC96B;
  6'd43: pal_rgb = 24'h8A5A18;
  6'd44: pal_rgb = 24'h070A10;
  6'd45: pal_rgb = 24'h050A0E;
  6'd46: pal_rgb = 24'h131D26;
  6'd47: pal_rgb = 24'h334650;
  6'd48: pal_rgb = 24'h22303D;
  6'd49: pal_rgb = 24'h16212B;
  6'd50: pal_rgb = 24'h0C161E;
  6'd51: pal_rgb = 24'hA8B6C0;
  6'd52: pal_rgb = 24'hC9D2D8;
  6'd53: pal_rgb = 24'h526774;
  6'd54: pal_rgb = 24'hD8442E;
  6'd55: pal_rgb = 24'h0E151C;
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
  else if(de_r2)
  tx_fifo_din = code_r;
  else
  tx_fifo_din = 8'h00;
end

assign tx_fifo_we = ((de_r2 && frame_on && link_up && armed)
                  || (seq == SEQ_HDR) || (seq == SEQ_PAL) || (seq == SEQ_H0));

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) wait_cnt <= 11'd0;
  else if(seq == SEQ_WAIT) wait_cnt <= wait_cnt + 11'd1;
  else wait_cnt <= 11'd0;
end

    // 网络键盘接收: 解析接收 FIFO 中的按键帧, 输出游戏操作信号。
    net_keyboard_receiver #(
        .KB_TIMEOUT(KB_TIMEOUT), .KB_RST_CNT(KB_RST_CNT),
        .KB_ACT_CNT(KB_ACT_CNT), .KB_GAP_MAX(KB_GAP_MAX)
    ) keyboard_receiver_inst(
        .Clk_74M(Clk_74M), .Reset_n(Reset_n), .por_n(por_n),
        .rx_byte(rx_byte), .rx_empty(rx_empty), .kb_rd_en(kb_rd_en),
        .kb_left_p(kb_left_p), .kb_right_p(kb_right_p),
        .kb_left_held(kb_left_held), .kb_right_held(kb_right_held),
        .kb_drop_r(kb_drop_r), .kb_drop_en(kb_drop_en),
        .kb_rotate_p(kb_rotate_p), .kb_switch_r(kb_switch_r),
        .kb_switch_en(kb_switch_en), .kb_hold_p(kb_hold_p),
        .kb_hold_en(kb_hold_en), .kb_reset_en(kb_reset_en),
        .kb_activity(kb_activity)
    );
endmodule
