



module eth_udp_loopback_rgmii(
  input         reset_n,
  input         clk_74m,

  input         rgmii_rx_clk_i,
  input  [3:0]  rgmii_rxd,
  input         rgmii_rxdv,

  output        rgmii_tx_clk,
  output  [3:0] rgmii_txd,
  output        rgmii_txen,


  output [7:0]  rx,
  input         rx_rd_en,
  output        rx_empty,
  output        rx_full,
  output [15:0] rx_data_length,


  input  [7:0]  tx,
  input         tx_wr_en,
  output        tx_full,
  input         tx_start,
  input  [47:0] tx_dst_mac,
  input  [31:0] tx_dst_ip,
  input  [15:0] tx_dst_port,
  input  [15:0] tx_data_length,
  output        tx_done,


  output [111:0]msg_dout,
  input         msg_rd_en,
  output [4:0]  msg_count,
  output        msg_empty,
  output        rx_pkt_done,
  output        rx_pkt_err,
  output        pll_locked,
  output        clk125m
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


wire        gmii_rx_clk;
wire [7:0]  gmii_rxd;
wire        gmii_rxdv;

wire        gmii_tx_clk;
wire [7:0]  gmii_txd;
wire        gmii_txen;

wire        rgmii_rx_clk;

clk_wiz_0 clk_wiz_0
(

  .clk_out1(rgmii_rx_clk),
  .clk_in1(rgmii_rx_clk_i),
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


eth_data_buf eth_rx_data_buf (
  .rst   (reset_p          ),
  .wr_clk(clk125m          ),
  .rd_clk(clk_74m          ),
  .din   (rx_payload_dat   ),
  .wr_en (rx_payload_valid ),
  .rd_en (rx_rd_en         ),
  .dout  (rx               ),
  .full  (rx_full          ),
  .empty (rx_empty         )
);


eth_msg_buf eth_msg_buf (
  .rst        (reset_p                                     ),
  .clk        (clk125m                                     ),
  .din        ({exter_mac,exter_ip,exter_port,rx_data_length}),
  .wr_en      (rx_pkt_done                                 ),
  .rd_en      (msg_rd_en                                   ),
  .dout       (msg_dout                                    ),
  .full       (                                            ),
  .empty      (msg_empty                                   ),
  .data_count (msg_count                                   )
);


eth_data_buf eth_tx_data_buf (
  .rst   (reset_p          ),
  .wr_clk(clk_74m          ),
  .rd_clk(clk125m          ),
  .din   (tx               ),
  .wr_en (tx_wr_en         ),
  .rd_en (tx_payload_req   ),
  .dout  (tx_payload_dat   ),
  .full  (tx_full          ),
  .empty (                 )
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
