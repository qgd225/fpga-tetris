// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
module audio_mixer(input clk,reset_n,input signed [15:0] fx,bgm,voice,
    input voice_busy,urgent,force_silence,output reg signed [15:0] pcm);
    // 运算仍在上升沿收束，下降沿送出；FIFO 上升沿采样时数据已稳定半周期。
    reg signed [15:0] mixed;
    always @(negedge clk or negedge reset_n)begin
        if(!reset_n)pcm<=0;
        else pcm<=mixed;
    end
    wire signed [17:0] fx_wide={{2{fx[15]}},fx};
    wire signed [17:0] bgm_wide={{2{bgm[15]}},bgm};
    wire signed [17:0] voice_wide={{2{voice[15]}},voice};
    wire signed [17:0] mix=(voice_busy && !urgent?(fx_wide>>>1):fx_wide)+
                           (voice_busy?(bgm_wide>>>2):bgm_wide)+voice_wide;
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)mixed<=0;
        else if(force_silence)mixed<=0;
        else if(mix>18'sd1024)mixed<=16'sd1024;
        else if(mix< -18'sd1024)mixed<= -16'sd1024;
        else mixed<=mix[15:0];
    end
endmodule
