module net_screen_tx(
  input         Clk_74M,
  input         Reset_n,
  input         por_n,

  //-------- �������루���� hdmi / frame��--------
  input         de,             // 1 = ��ǰ��������Ч��(1280x720)
  input  [10:0] hcounter,
  input  [10:0] vcounter,
  input  [23:0] rgb,

  //-------- ��̫������ --------
  input         rgmii_rx_clk_i,
  input  [3:0]  rgmii_rxd,
  input         rgmii_rxdv,
  output        rgmii_tx_clk,
  output  [3:0] rgmii_txd,
  output        rgmii_txen,
  output        eth_rstn,
  output        eth_mdc,
  output        eth_mdio,

  //-------- ����(����)��������״����������һ�� --------
  output        kb_left_p,
  output        kb_right_p,
  output        kb_drop_r,
  output        kb_drop_en,
  output        kb_rotate_p,
  output        kb_switch_r,
  output        kb_switch_en,
  output        kb_hold_p,
  output        kb_hold_en,
  output        kb_reset_en,
  output        kb_activity,

  //-------- ������ݣ����� frame��--------
  input         Finalize,
  input         duo,
  input  [19:0] res_score,
  input  [2:0]  res_level,
  input  [15:0] res_lines,
  input  [13:0] res_time
);
parameter DST_MAC    = 48'hFF_FF_FF_FF_FF_FF;   // Ĭ�Ϲ㲥��PC �˲�����֪��Ҳ��
parameter DST_IP     = 32'hFF_FF_FF_FF;
parameter DST_PORT   = 16'd5000;
parameter FPS_DIV    = 1;                        // 1=60fps  2=30fps  3=20fps
parameter PAL_FRAMES = 60;                       // ÿ 60 ֡��һ����ɫ���(=1s@60fps)
parameter LINE_LEN   = 16'd1287;                 // 7 �ֽڰ�ͷ + 1280 �����
parameter PAL_LEN    = 16'd160;                  // 4 + 39*4
parameter [7:0] PAL_LAST = 8'd159;              // = 4 + PAL_N*4 - 1 (��β���)
parameter PAL_N      = 8'd39;
parameter KB_TIMEOUT = 24'd14_850_000;              // 200ms @74.25MHz û�а�������ȫ���ɿ�
parameter KB_RST_CNT = 25'd1_485_000;               // С����9��λ�� Reset_n ���� 20ms
parameter KB_ACT_CNT = 25'd22_275_000;              // �յ��������� kb_activity �� 0.3s
parameter KB_GAP_MAX = 8'd255;                     // �����ֽڼ����ʱ=��������������ͬ��
parameter RES_LEN    = 16'd14;                     // ���������
parameter RES_PERIOD = 26'd37_125_000;             // ����������ÿ 500ms �ط�һ�ν����

assign eth_rstn = 1'b1;
assign eth_mdc  = 1'b1;
assign eth_mdio = 1'b1;
wire [7:0] rx_byte;
wire       rx_empty;
wire       kb_rd_en;

//============================================================
//    eth_udp_loopback_rgmii ����
//============================================================
reg         tog_line;
reg         tog_pal;
reg         tog_res;
reg  [7:0]  tx_fifo_din;
wire        tx_fifo_we;
wire        tx_start_125;
wire [15:0] tx_len_125;
wire        pll_locked;
wire        clk125m;
reg  [1:0]  len_sel;          // 0=�а�(1287)  1=��ɫ���(112)  2=�����(13)

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
//    clk125m ��tx_start ���� + ����ѡ��toggle ���֣�
//============================================================
reg  gl1, gl2, gl3;
reg  gp1, gp2, gp3;
reg  gr1, gr2, gr3;

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
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gr1 <= 1'b0;
  else         gr1 <= tog_res;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gr2 <= 1'b0;
  else         gr2 <= gr1;
end
always@(posedge clk125m or negedge Reset_n)begin
  if(!Reset_n) gr3 <= 1'b0;
  else         gr3 <= gr2;
end

wire p_line = gl2 ^ gl3;
wire p_pal  = gp2 ^ gp3;
wire p_res  = gr2 ^ gr3;

assign tx_start_125 = p_line | p_pal | p_res;
assign tx_len_125   = p_pal ? PAL_LEN : (p_res ? RES_LEN : LINE_LEN);

//============================================================
//    pll_locked ͬ���� 74.25 ��
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
//    ���ش�һ�� + ��ɫ���
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
  24'h00_00_00: code_r = 8'd0;      // ��/��
  24'h00_CC_FF: code_r = 8'd1;      // I
  24'h99_33_CC: code_r = 8'd2;      // T
  24'hFF_FF_00: code_r = 8'd3;      // O
  24'hE6_39_46: code_r = 8'd4;      // S
  24'h55_A6_30: code_r = 8'd5;      // Z
  24'hF7_7F_24: code_r = 8'd6;      // L
  24'hFF_4D_A6: code_r = 8'd7;      // J
  24'h99_EE_FF: code_r = 8'd8;      // ���� I
  24'hD9_B3_E6: code_r = 8'd9;      // ���� T
  24'hFF_FF_99: code_r = 8'd10;     // ���� O
  24'hFF_B3_B9: code_r = 8'd11;     // ���� S
  24'hBD_E0_AA: code_r = 8'd12;     // ���� Z
  24'hFF_D9_B3: code_r = 8'd13;     // ���� L
  24'hFF_B3_D9: code_r = 8'd14;     // ���� J
  24'hEE_EE_EE: code_r = 8'd15;     // ����
  24'hFF_FF_FF: code_r = 8'd16;     // ��(�߿�/����/ʱ��/��)
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
  24'h0A_0F_16: code_r = 8'd27;
  24'h08_1A_1E: code_r = 8'd28;
  24'h1E_08_12: code_r = 8'd29;
  24'h04_63_7E: code_r = 8'd30;
  24'h47_1F_67: code_r = 8'd31;
  24'h74_79_0D: code_r = 8'd32;
  24'h69_22_2C: code_r = 8'd33;
  24'h29_52_23: code_r = 8'd34;
  24'h71_41_1D: code_r = 8'd35;
  24'h74_2B_56: code_r = 8'd36;
  24'h6B_F0_FF: code_r = 8'd37;
  24'hFF_98_CB: code_r = 8'd38;
  default:      code_r = 8'd0;
  endcase
end

//============================================================
//    ��ĩ/��ĩ ���������
//============================================================
localparam SEQ_IDLE = 4'd0;
localparam SEQ_HDR  = 4'd1;   // д��һ�а�ͷ 7 �ֽ�
localparam SEQ_TOG  = 4'd2;   // tx_start���а���
localparam SEQ_PAL  = 4'd3;   // д��ɫ���
localparam SEQ_PTOG = 4'd4;   // tx_start����ɫ�����
localparam SEQ_H0   = 4'd5;   // д��һ֡�� 0 �а�ͷ
localparam SEQ_WAIT = 4'd6;   // �� MAC ������һ������ɫ���/������ã�
localparam SEQ_RES  = 4'd7;   // д����� 14 字节
localparam SEQ_RTOG = 4'd8;   // tx_start���������

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
//    ������������������ÿ 500ms ��һ�Σ�ֱ������ؿ�
//============================================================
reg         h0_lat;
reg         pal_lat;
reg         res_lat;
reg         res_done;
reg         fin_d;
reg  [7:0]  res_no;
reg  [25:0] res_cnt;

wire fin_rise = Finalize && (!fin_d);
wire res_due  = Finalize && (res_cnt == 26'd0);

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) h0_lat <= 1'b0;
  else if(seq == SEQ_TOG) h0_lat <= line_719;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) pal_lat <= 1'b0;
  else if(seq == SEQ_TOG) pal_lat <= send_pal;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) res_lat <= 1'b0;
  else if(seq == SEQ_TOG) res_lat <= res_due && line_719 && frame_on;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) res_done <= 1'b0;
  else if(seq == SEQ_TOG) res_done <= 1'b0;
  else if(seq == SEQ_RTOG) res_done <= 1'b1;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) fin_d <= 1'b0;
  else fin_d <= Finalize;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) res_no <= 8'd0;
  else if(fin_rise) res_no <= res_no + 8'd1;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) res_cnt <= 26'd0;
  else if(!Finalize) res_cnt <= 26'd0;
  else if(seq == SEQ_RTOG) res_cnt <= RES_PERIOD;
  else if(res_cnt != 26'd0) res_cnt <= res_cnt - 26'd1;
end

wire [7:0]res_byte;
result_packet result_packet_inst(
.res_no(res_no), .mode(duo), .score(res_score), .level(res_level),
.lines(res_lines), .time_sec(res_time), .idx(seq_idx[3:0]), .dout(res_byte)
);
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  seq <= SEQ_IDLE;
  else
  case(seq)
  SEQ_IDLE: if(de_fall && frame_on && link_up)
            seq <= SEQ_TOG;
  SEQ_TOG:  if((res_due && line_719 && frame_on) || send_pal) seq <= SEQ_WAIT;
            else if(line_719)                                 seq <= SEQ_H0;
            else                                              seq <= SEQ_HDR;
  SEQ_WAIT: if(wait_cnt == 11'd1023 && (!de_r))begin
                if(res_lat && (!res_done)) seq <= SEQ_RES;
                else if(pal_lat)           seq <= SEQ_PAL;
                else if(h0_lat)            seq <= SEQ_H0;
                else                       seq <= SEQ_HDR;
            end
  SEQ_RES:  if(seq_idx == 7'd13) seq <= SEQ_RTOG;
  SEQ_RTOG: if(pal_lat)          seq <= SEQ_WAIT;
            else if(h0_lat)      seq <= SEQ_H0;
            else                 seq <= SEQ_HDR;
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
  else if(seq == SEQ_IDLE || seq == SEQ_TOG || seq == SEQ_PTOG || seq == SEQ_WAIT || seq == SEQ_RTOG)
  seq_idx <= 7'd0;
  else if(seq == SEQ_PAL)
  seq_idx <= (seq_idx == PAL_LAST) ? 7'd0 : (seq_idx + 7'd1);
  else if(seq == SEQ_RES)
  seq_idx <= (seq_idx == 7'd13) ? 7'd0 : (seq_idx + 7'd1);
  else
  seq_idx <= (seq_idx == 7'd6) ? 7'd0 : (seq_idx + 7'd1);
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  start_pulse_74 <= 1'b0;
  else if((seq == SEQ_TOG || seq == SEQ_PTOG || seq == SEQ_RTOG) && (!first))
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
  else if(start_pulse_74 && (len_sel == 2'd0)) tog_line <= ~tog_line;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) tog_pal <= 1'b0;
  else if(start_pulse_74 && (len_sel == 2'd1)) tog_pal <= ~tog_pal;
end
always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) tog_res <= 1'b0;
  else if(start_pulse_74 && (len_sel == 2'd2)) tog_res <= ~tog_res;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  len_sel <= 2'd0;
  else if(seq == SEQ_PAL)
  len_sel <= 2'd1;
  else if(seq == SEQ_RES)
  len_sel <= 2'd2;
  else if(seq == SEQ_HDR || seq == SEQ_H0)
  len_sel <= 2'd0;
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
//    ��ͷ / ��ɫ��� �ֽ�
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
  5'd27:  pal_rgb = 24'h0A_0F_16;
  5'd28:  pal_rgb = 24'h08_1A_1E;
  5'd29:  pal_rgb = 24'h1E_08_12;
  6'd30:  pal_rgb = 24'h04_63_7E;
  6'd31:  pal_rgb = 24'h47_1F_67;
  6'd32:  pal_rgb = 24'h74_79_0D;
  6'd33:  pal_rgb = 24'h69_22_2C;
  6'd34:  pal_rgb = 24'h29_52_23;
  6'd35:  pal_rgb = 24'h71_41_1D;
  6'd36:  pal_rgb = 24'h74_2B_56;
  6'd37:  pal_rgb = 24'h6B_F0_FF;
  6'd38:  pal_rgb = 24'hFF_98_CB;
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
//    FIFO д������ / ��ͷ / ��ɫ�� / �����
//============================================================
always@(*)begin
  if(seq == SEQ_HDR || seq == SEQ_H0)
  tx_fifo_din = hdr_byte;
  else if(seq == SEQ_PAL)
  tx_fifo_din = pal_byte;
  else if(seq == SEQ_RES)
  tx_fifo_din = res_byte;
  else if(de_r)
  tx_fifo_din = code_r;
  else
  tx_fifo_din = 8'h00;
end

assign tx_fifo_we = ((de_r && frame_on && link_up && armed)
                  || (seq == SEQ_HDR) || (seq == SEQ_PAL) || (seq == SEQ_H0) || (seq == SEQ_RES));

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n) wait_cnt <= 11'd0;
  else if(seq == SEQ_WAIT) wait_cnt <= wait_cnt + 11'd1;
  else wait_cnt <= 11'd0;
end
//============================================================
//    ���簴�����ӽ��� FIFO ���� A5 5A 03 | λͼ
//============================================================
localparam KB_WA5 = 2'd0;
localparam KB_W5A = 2'd1;
localparam KB_W03 = 2'd2;
localparam KB_BIT = 2'd3;

reg  [1:0]  kb_st;
reg  [7:0]  kb_bits;
reg  [7:0]  kb_bits_d;
reg  [23:0] kb_timer;
reg  [24:0] kb_act_cnt;
reg  [24:0] kb_rst_cnt;
reg  [7:0]  kb_gap;
reg         kb_rst_hold;

wire kb_hit      = kb_rd_en && (kb_st == KB_BIT);
wire kb_gap_done = (kb_gap >= KB_GAP_MAX);
wire kb_tout     = (kb_timer >= KB_TIMEOUT);
wire kb_rst_trig = kb_bits[6] && (!kb_bits_d[6]);

assign kb_rd_en = (!rx_empty);


always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  kb_st <= KB_WA5;
  else if(kb_rd_en)
  case(kb_st)
  KB_WA5: kb_st <= (rx_byte == 8'hA5) ? KB_W5A : KB_WA5;
  KB_W5A: kb_st <= (rx_byte == 8'h5A) ? KB_W03 : ((rx_byte == 8'hA5) ? KB_W5A : KB_WA5);
  KB_W03: kb_st <= (rx_byte == 8'd3)  ? KB_BIT : ((rx_byte == 8'hA5) ? KB_W5A : KB_WA5);
  KB_BIT: kb_st <= KB_WA5;
  default:kb_st <= KB_WA5;
  endcase
  else if(kb_gap_done)
  kb_st <= KB_WA5;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  kb_gap <= 8'd0;
  else if(kb_rd_en)
  kb_gap <= 8'd0;
  else if(kb_gap < KB_GAP_MAX)
  kb_gap <= kb_gap + 8'd1;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  kb_bits <= 8'd0;
  else if(kb_hit)
  kb_bits <= rx_byte;
  else if(kb_tout)
  kb_bits <= 8'd0;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  kb_bits_d <= 8'd0;
  else
  kb_bits_d <= kb_bits;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  kb_timer <= 24'd0;
  else if(kb_hit)
  kb_timer <= 24'd0;
  else if(kb_timer < KB_TIMEOUT)
  kb_timer <= kb_timer + 24'd1;
end

always@(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)
  kb_act_cnt <= 25'd0;
  else if(kb_hit)
  kb_act_cnt <= KB_ACT_CNT;
  else if(kb_act_cnt != 25'd0)
  kb_act_cnt <= kb_act_cnt - 25'd1;
end

//    С����9��λ���� Reset_n ����һ��ʱ�䣬��Ч�����ϸ�λ��
always@(posedge Clk_74M or negedge por_n)begin
  if(!por_n)
  kb_rst_cnt <= 25'd0;
  else if(kb_rst_trig)
  kb_rst_cnt <= 25'd0;
  else if(kb_rst_hold && (kb_rst_cnt < KB_RST_CNT))
  kb_rst_cnt <= kb_rst_cnt + 25'd1;
end

always@(posedge Clk_74M or negedge por_n)begin
  if(!por_n)
  kb_rst_hold <= 1'b0;
  else if(kb_rst_trig)
  kb_rst_hold <= 1'b1;
  else if(kb_rst_cnt == KB_RST_CNT)
  kb_rst_hold <= 1'b0;
end

assign kb_reset_en = kb_rst_hold;
assign kb_activity = (kb_act_cnt != 25'd0);

assign kb_left_p    = kb_bits[0] && (!kb_bits_d[0]);
assign kb_right_p   = kb_bits[1] && (!kb_bits_d[1]);
assign kb_rotate_p  = kb_bits[3] && (!kb_bits_d[3]);
assign kb_hold_p    = kb_bits[4] && (!kb_bits_d[4]);
assign kb_hold_en   = kb_bits[4];
assign kb_drop_en   = kb_bits[2];
assign kb_drop_r    = (!kb_bits[2]) && kb_bits_d[2];
assign kb_switch_en = kb_bits[5];
assign kb_switch_r  = (!kb_bits[5]) && kb_bits_d[5];
endmodule
