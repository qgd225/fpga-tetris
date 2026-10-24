// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 导入模块：eth_udp_loopback_rgmii
// 本工程用途：RGMII 以太网 UDP 收发集成。
//============================================================
module eth_udp_loopback_rgmii(
  input         reset_n,
  input         clk_74m,  // 74.25MHz 像素时钟（给跨时钟 FIFO 用）

//eth_rx
  input         rgmii_rx_clk_i,
  input  [3:0]  rgmii_rxd,
  input         rgmii_rxdv,

//eth_tx
  output        rgmii_tx_clk,
  output  [3:0] rgmii_txd,
  output        rgmii_txen,

//-------- 接收方向：把收到的数据读出去 --------
  output [7:0]  rx,  // 收到的 payload 字节
  input         rx_rd_en,  // 1 拍脉冲 = 取走一个字节（请在 !rx_empty 时给）
  output        rx_empty,  // 1 = 没有数据可读
  output        rx_full,  // 1 = 接收 FIFO 满（同时也送给了 rx 模块做流控）
  output [15:0] rx_data_length,  // 这一包 payload 有多少字节

//-------- 发送方向：把要发的数据写进来 --------
  input  [7:0]  tx,  // 要发的 payload 字节
  input         tx_wr_en,  // 1 拍脉冲 = 写入一个字节（请在 !tx_full 时给）
  output        tx_full,  // 1 = 发送 FIFO 满
  input         tx_start,  // 1 拍脉冲 = 启动发送（mac 只在 IDLE 状态认它）
  input  [47:0] tx_dst_mac,
  input  [31:0] tx_dst_ip,
  input  [15:0] tx_dst_port,
  input  [15:0] tx_data_length,  // 这一包发这么多字节
  output        tx_done,  // 一包发完，1 拍

//-------- 报文信息与状态 --------
  output [111:0]msg_dout,  // {发件人MAC, 发件人IP, 发件人PORT, 该包长度}
  input         msg_rd_en,  // 1 拍脉冲 = 读走一条（标准FIFO，dout 下一拍才有效）
  output [4:0]  msg_count,  // 里面存了几条报文信息
  output        msg_empty,  // 1 = 没有报文信息
  output        rx_pkt_done,  // 收完一包，1 拍
  output        rx_pkt_err,  // 这一包有错
  output        pll_locked,  // clk_wiz_0 锁定
  output        clk125m  // 125MHz（来自 PHY RXC），给上层做跨时钟同步用
);
parameter LOCAL_MAC  = 48'h00_0a_35_01_fe_c0;
parameter LOCAL_IP   = 32'hc0_a8_00_02;
parameter LOCAL_PORT = 16'd5000;

wire        reset_p;
wire [47:0] exter_mac;
wire [31:0] exter_ip;
wire [15:0] exter_port;
wire [7:0]  rx_payload_dat;
wire        rx_payload_valid;

wire [7:0]  tx_payload_dat;
wire        tx_payload_req;

// gmii interface
wire        gmii_rx_clk;
wire [7:0]  gmii_rxd;
wire        gmii_rxdv;

wire        gmii_tx_clk;
wire [7:0]  gmii_txd;
wire        gmii_txen;

wire        rgmii_rx_clk;

clk_wiz_0 clk_wiz_0  //加锁相环调整相位，同时加强时钟扇出能力
(

// Clock out ports
  .clk_out1(rgmii_rx_clk),  // output clk_out1
  .clk_in1(rgmii_rx_clk_i),  // input clk_in1
  .locked (pll_locked)
);

assign reset_p = ~reset_n;

rgmii_to_gmii rgmii_to_gmii(
  .reset(reset_p),

  .rgmii_rx_clk(rgmii_rx_clk),
  .rgmii_rxd(rgmii_rxd),
  .rgmii_rxdv(rgmii_rxdv),

  .gmii_rx_clk(gmii_rx_clk),
  .gmii_rxdv(gmii_rxdv),
  .gmii_rxd(gmii_rxd),
  .gmii_rxer( )
);

//以太网接收
eth_udp_rx_gmii eth_udp_rx_gmii(
  .reset_p         (reset_p               ),

  .local_mac       (LOCAL_MAC             ),
  .local_ip        (LOCAL_IP              ),
  .local_port      (LOCAL_PORT            ),

  .clk125m_o       (clk125m               ),
  .exter_mac       (exter_mac             ),
  .exter_ip        (exter_ip              ),
  .exter_port      (exter_port            ),
  .rx_data_length  (rx_data_length        ),
  .data_overflow_i (rx_full               ),
  .payload_valid_o (rx_payload_valid      ),
  .payload_dat_o   (rx_payload_dat        ),

  .one_pkt_done    (rx_pkt_done           ),
  .pkt_error       (rx_pkt_err            ),
  .debug_crc_check (                      ),

  .gmii_rx_clk     (gmii_rx_clk           ),
  .gmii_rxdv       (gmii_rxdv             ),
  .gmii_rxd        (gmii_rxd              )
);

//对以太网接收数据缓存（你在这里读出去）
eth_data_buf eth_rx_data_buf (
  .rst   (reset_p          ),  // input wire rst
  .wr_clk(clk125m          ),  // input wire wr_clk  (rx 模块写)
  .rd_clk(clk_74m          ),  // input wire rd_clk  (你读)
  .din   (rx_payload_dat   ),  // input wire [7 : 0] din
  .wr_en (rx_payload_valid ),  // input wire wr_en
  .rd_en (rx_rd_en         ),  // input wire rd_en
  .dout  (rx               ),  // output wire [7 : 0] dout
  .full  (rx_full          ),  // output wire full
  .empty (rx_empty         )  // output wire empty
);

//同时对报文中MAC、IP等消息数据缓存
eth_msg_buf eth_msg_buf (
  .rst        (reset_p                                     ),  // input wire rst
  .clk        (clk125m                                     ),  // input wire clk
  .din        ({exter_mac,exter_ip,exter_port,rx_data_length}),  // input wire [111 : 0] din
  .wr_en      (rx_pkt_done                                 ),  // input wire wr_en
  .rd_en      (msg_rd_en                                   ),  // input wire rd_en
  .dout       (msg_dout                                    ),  // output wire [111 : 0] dout
  .full       (                                            ),  // output wire full
  .empty      (msg_empty                                   ),  // output wire empty
  .data_count (msg_count                                   )  // output wire [4 : 0] data_count
);

//对以太网发出数据缓存（你把要发的东西写进来）
eth_data_buf eth_tx_data_buf (
  .rst   (reset_p          ),  // input wire rst
  .wr_clk(clk_74m          ),  // input wire wr_clk  (打包逻辑写)
  .rd_clk(clk125m          ),  // input wire rd_clk  (mac 读)
  .din   (tx               ),  // input wire [7 : 0] din
  .wr_en (tx_wr_en         ),  // input wire wr_en
  .rd_en (tx_payload_req   ),  // input wire rd_en
  .dout  (tx_payload_dat   ),  // output wire [7 : 0] dout
  .full  (tx_full          ),  // output wire full
  .empty (                 )  // output wire empty
);

eth_udp_tx_gmii eth_udp_tx_gmii
(
  .clk125m       (clk125m               ),
  .reset_p       (reset_p               ),

  .tx_en_pulse   (tx_start              ),
  .tx_done       (tx_done               ),

  .dst_mac       (tx_dst_mac            ),
  .src_mac       (LOCAL_MAC             ),
  .dst_ip        (tx_dst_ip             ),
  .src_ip        (LOCAL_IP              ),
  .dst_port      (tx_dst_port           ),
  .src_port      (LOCAL_PORT            ),

  .data_length   (tx_data_length        ),

  .payload_req_o (tx_payload_req        ),
  .payload_dat_i (tx_payload_dat        ),

  .gmii_tx_clk   (gmii_tx_clk           ),
  .gmii_txen     (gmii_txen             ),
  .gmii_txd      (gmii_txd              )
);

gmii_to_rgmii gmii_to_rgmii(
  .reset_n(reset_n),

  .gmii_tx_clk(gmii_tx_clk),
  .gmii_txd(gmii_txd),
  .gmii_txen(gmii_txen),
  .gmii_txer(1'b0),

  .rgmii_tx_clk(rgmii_tx_clk),
  .rgmii_txd(rgmii_txd),
  .rgmii_txen(rgmii_txen)
);
endmodule
