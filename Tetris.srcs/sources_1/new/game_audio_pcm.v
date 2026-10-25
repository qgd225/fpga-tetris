// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 仅一份精确 48k 使能与 PCM 混音入口；不保留原蜂鸣器方波映射。
module game_audio_pcm #(
    parameter integer PIXEL_HZ=74218750,parameter integer SAMPLE_HZ=48000
)(input clk,reset_n,input signed [15:0] fx,bgm,voice,
    input voice_busy,urgent,force_silence,output sample_ce,output signed [15:0] pcm);
    reg [26:0] phase;
    wire [27:0] phase_next={1'b0,phase}+SAMPLE_HZ;
    assign sample_ce=reset_n && phase_next>=PIXEL_HZ;
    audio_mixer mixer_inst(.clk(clk),.reset_n(reset_n),.fx(fx),.bgm(bgm),.voice(voice),
        .voice_busy(voice_busy),.urgent(urgent),.force_silence(force_silence),.pcm(pcm));
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)phase<=0;
        else if(sample_ce)phase<=phase_next-PIXEL_HZ;
        else phase<=phase_next[26:0];
    end
endmodule
