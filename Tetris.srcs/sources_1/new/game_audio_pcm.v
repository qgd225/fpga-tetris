// 游戏音效转 PCM：与 sound 共用像素时钟，避免新增低速时钟域。
// 必须使用 fx_active 区分方波低电平和静音；两者不能混为一谈。
module game_audio_pcm #(
    parameter integer PIXEL_HZ = 74218750,
    parameter integer SAMPLE_HZ = 48000,
    parameter signed [15:0] VOLUME = 16'sd4096
)(
    input clk, input reset_n,
    input fx_wave, input fx_active,
    output sample_ce,
    output reg signed [15:0] pcm
);
    reg [26:0] phase;
    wire [27:0] phase_next = {1'b0, phase} + SAMPLE_HZ;
    assign sample_ce = reset_n && (phase_next >= PIXEL_HZ);
    // 采样使能平均精确为 48 kHz，间隔为 1546 或 1547 个像素周期。
    // pcm 组合值由下游在 sample_ce 有效时锁存，静音为有符号零。
    always @(*) begin
        if (!reset_n || !fx_active) pcm = 16'sd0;
        else pcm = fx_wave ? VOLUME : -VOLUME;
    end
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) phase <= 27'd0;
        else if (sample_ce) phase <= phase_next - PIXEL_HZ;
        else phase <= phase_next[26:0];
    end
endmodule
