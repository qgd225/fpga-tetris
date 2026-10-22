module hdmi(
    Clk,
    Clk_74M,
    Reset_n,
    hdmi_clk_p,
    hdmi_clk_n,
    hdmi_data_p,
    hdmi_data_n,
    hdmi_oe,
    hcounter,
    vcounter,
    rgb,
    de
    );

    input Clk;
    input Reset_n;

    input wire [23:0]rgb;

    output hdmi_clk_p;
    output hdmi_clk_n;
    output [2:0]hdmi_data_p;
    output [2:0]hdmi_data_n;
    output hdmi_oe;

    output wire [10:0]hcounter;
    output wire [10:0]vcounter;
    output wire Clk_74M;
    output wire de;

    wire Clk_371M;
    wire Clk_50M;
    wire hdmi_hs;
    wire hdmi_vs;

    reg hdmi_de_r;
    reg hdmi_hs_r;
    reg hdmi_vs_r;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    hdmi_de_r <= 1'b0;
    hdmi_hs_r <= 1'b0;
    hdmi_vs_r <= 1'b0;
    end
    else begin
    hdmi_de_r <= de;
    hdmi_hs_r <= hdmi_hs;
    hdmi_vs_r <= hdmi_vs;
    end
    end

   assign hdmi_oe = 1;

    hdmi_pll hdmi_pll_inst
 (

  .clk_out1(Clk_74M),
  .clk_out2(Clk_371M),

  .reset(!Reset_n),

  .clk_in1(Clk)
 );

    VGA_1280_720 VGA_1280_720_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .Data_in(24'h000_000),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .VGA_HS(hdmi_hs),
    .VGA_VS(hdmi_vs),
    .VGA_BLK(de),
    .VGA_CLK(),
    .VGA_DATA()
    );

    dvi_encoder dvi_encoder_inst(
    .pixelclk(Clk_74M),
    .pixelclk5x(Clk_371M),
    .rst_p(!Reset_n),
    .blue_din(rgb[7:0]),
    .green_din(rgb[15:8]),
    .red_din(rgb[23:16]),
    .hsync(hdmi_hs_r),
    .vsync(hdmi_vs_r),
    .de(hdmi_de_r),
    .tmds_clk_p(hdmi_clk_p),
    .tmds_clk_n(hdmi_clk_n),
    .tmds_data_p(hdmi_data_p),
    .tmds_data_n(hdmi_data_n)
);

    endmodule
