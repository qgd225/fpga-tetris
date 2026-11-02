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
  output [4:0]  kb_p1_keys, kb_p2_keys,
  output        kb_cancel, kb_back_en,
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

assign eth_rstn=1'b1;assign eth_mdc=1'b1;assign eth_mdio=1'b1;
wire [7:0] rx_byte;wire rx_empty,kb_rd_en,clk125m,pll_locked,tx_done,tx_full,underflow;
reg [1:0] link_sync;
reg [1:0] de_pipe;reg [23:0] rgb0,rgb1;reg [10:0] y0,y1;
always @(posedge Clk_74M or negedge Reset_n)begin
 if(!Reset_n)begin link_sync<=0;de_pipe<=0;end
 else begin link_sync<={link_sync[0],pll_locked};de_pipe<={de_pipe[0],de};end
end
always @(posedge Clk_74M)begin rgb0<=rgb;rgb1<=rgb0;y0<=vcounter;y1<=y0;end
wire [31:0] word_data;wire word_write,packet_ready,descriptor_full,codec_overflow;
wire [15:0] packet_length;
ui_rgb_packetizer packetizer(.clk(Clk_74M),.reset_n(Reset_n),.enable(link_sync[1]),
 .de(de_pipe[1]),.line(y1),.rgb(rgb1),.word_full(tx_full),.descriptor_full(descriptor_full),
 .word_data(word_data),.word_write(word_write),.packet_length(packet_length),.packet_ready(packet_ready),.overflow(codec_overflow));
wire [15:0] descriptor_head;wire descriptor_valid;
wire descriptor_pop;
ui_async_fifo #(.WIDTH(16),.ADDR_BITS(5),.STYLE("distributed")) packets(
 .reset_n(Reset_n),.wr_clk(Clk_74M),.rd_clk(clk125m),
 .write(packet_ready),.write_data(packet_length),.full(descriptor_full),
 .pop(descriptor_pop),.head(descriptor_head),.valid(descriptor_valid));
reg busy,start_packet;reg [6:0] gap;reg [15:0] length_send;
(* ASYNC_REG="TRUE" *) reg [1:0] stream_fault_sync;
always @(posedge clk125m or negedge Reset_n)begin
 if(!Reset_n)stream_fault_sync<=0;else stream_fault_sync<={stream_fault_sync[0],codec_overflow || underflow};
end
assign descriptor_pop=!busy && gap==0 && descriptor_valid && !stream_fault_sync[1];
always @(posedge clk125m or negedge Reset_n)begin
 if(!Reset_n)begin busy<=0;start_packet<=0;gap<=0;length_send<=0;end
 else begin
  start_packet<=0;
  if(tx_done)begin busy<=0;gap<=72;end
  else if(gap!=0)gap<=gap-1'b1;
  if(descriptor_pop)begin length_send<=descriptor_head;start_packet<=1;busy<=1;end
 end
end
eth_udp_loopback_rgmii #(.WORD_TX(1)) eth_udp_loopback_rgmii_inst(
 .reset_n(Reset_n),.clk_74m(Clk_74M),.clk125m(clk125m),
 .rgmii_rx_clk_i(rgmii_rx_clk_i),.rgmii_rxd(rgmii_rxd),.rgmii_rxdv(rgmii_rxdv),
 .rgmii_tx_clk(rgmii_tx_clk),.rgmii_txd(rgmii_txd),.rgmii_txen(rgmii_txen),
 .rx(rx_byte),.rx_empty(rx_empty),.rx_rd_en(kb_rd_en),
 .tx(8'd0),.tx_wr_en(1'b0),.tx_word(word_data),.tx_word_write(word_write),.tx_word_underflow(underflow),.tx_full(tx_full),
 .tx_start(start_packet),.tx_done(tx_done),.tx_dst_mac(DST_MAC),.tx_dst_ip(DST_IP),.tx_dst_port(DST_PORT),
 .tx_data_length(length_send),.msg_rd_en(1'b0),.pll_locked(pll_locked));
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
        .kb_p1_keys(kb_p1_keys), .kb_p2_keys(kb_p2_keys),
        .kb_cancel(kb_cancel), .kb_back_en(kb_back_en),
        .kb_activity(kb_activity)
    );
endmodule
