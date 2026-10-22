module rgmii_to_gmii(
  reset,

  rgmii_rx_clk,
  rgmii_rxd,
  rgmii_rxdv,

  gmii_rx_clk,
  gmii_rxdv,
  gmii_rxd,
  gmii_rxer
);

  input         reset;

  input         rgmii_rx_clk;
  input  [3:0]  rgmii_rxd;
  input         rgmii_rxdv;

  output        gmii_rx_clk;
  output [7:0]  gmii_rxd;
  output        gmii_rxdv;
  output        gmii_rxer;

  wire          gmii_rxer_r;

  assign gmii_rx_clk = rgmii_rx_clk;

  genvar i;
  generate
    for(i=0;i<4;i=i+1)
    begin: rgmii_rxd_i
      IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),

        .INIT_Q1(1'b0   ),
        .INIT_Q2(1'b0   ),
        .SRTYPE ("SYNC" )
      ) IDDR_rxd (
        .Q1   (gmii_rxd[i]   ),
        .Q2   (gmii_rxd[i+4] ),
        .C    (rgmii_rx_clk  ),
        .CE   (1'b1          ),
        .D    (rgmii_rxd[i]  ),
        .R    (reset         ),
        .S    (1'b0          )
      );
    end
  endgenerate

  IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),

    .INIT_Q1(1'b0   ),
    .INIT_Q2(1'b0   ),
    .SRTYPE ("SYNC" )
  ) IDDR_rxdv (
    .Q1   (gmii_rxdv),
    .Q2   (gmii_rxer_r),
    .C    (rgmii_rx_clk ),
    .CE   (1'b1         ),
    .D    (rgmii_rxdv   ),
    .R    (reset        ),
    .S    (1'b0         )
  );

    assign gmii_rxer = gmii_rxer_r^gmii_rxdv;
endmodule
