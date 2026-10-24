// HDMI 顶层：PLL、原有视频时序、音视频编码与物理输出。
module hdmi(
    input Clk, input Reset_n,
    input [23:0] rgb,
    input audio_sample_ce,
    input [15:0] audio_pcm,
    output Clk_74M,
    output hdmi_clk_p, hdmi_clk_n,
    output [2:0] hdmi_data_p, hdmi_data_n,
    output hdmi_oe,
    output [10:0] hcounter, vcounter,
    output de
);
    wire clk5x, locked;
    wire hs, vs;
    wire [10:0] raw_h, raw_v;
    // PLL 锁定后同步释放视频域复位，避免锁定前输出无效包。
    (* ASYNC_REG = "TRUE" *) reg [2:0] reset_pipe = 3'b111;
    always @(posedge Clk_74M or negedge Reset_n or negedge locked) begin
        if(!Reset_n || !locked) reset_pipe <= 3'b111;
        else reset_pipe <= {reset_pipe[1:0],1'b0};
    end
    wire av_reset = reset_pipe[2];
    assign hdmi_oe = 1'b1;
    hdmi_pll hdmi_pll_inst(.clk_out1(Clk_74M),.clk_out2(clk5x),
        .reset(!Reset_n),.locked(locked),.clk_in1(Clk));
    VGA_1280_720 VGA_1280_720_inst(.Clk_74M(Clk_74M),.Reset_n(!av_reset),
        .Data_in(24'd0),.hcounter(hcounter),.vcounter(vcounter),
        .VGA_HS(hs),.VGA_VS(vs),.VGA_BLK(de),.VGA_CLK(),.VGA_DATA(),
        .raw_h(raw_h),.raw_v(raw_v));
    // 原有 VGA 同步是低有效；720p HDMI 使用正极性同步。
    hdmi_av_encoder av_encoder(.pixelclk(Clk_74M),.pixelclk5x(clk5x),.reset(av_reset),
        .rgb(rgb),.raw_h(raw_h),.raw_v(raw_v),.de(de),.hsync(!hs),.vsync(!vs),
        .sample_ce(audio_sample_ce && !av_reset),.pcm(audio_pcm),
        .tmds_clk_p(hdmi_clk_p),.tmds_clk_n(hdmi_clk_n),
        .tmds_data_p(hdmi_data_p),.tmds_data_n(hdmi_data_n));
endmodule
