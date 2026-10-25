// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 七句共用播放器；每个 8k 样本由 48k 输出恰好保持六次。
`include "story_voice_config.vh"
(* use_dsp = "no" *)
module voice_player(
    input clk,reset_n,sample_ce,start,cancel,pause,input [2:0] voice_id,
    output busy,output reg done,output signed [15:0] pcm,
    output reg [16:0] sample_index,output reg [2:0] repeat_index
);
    `include "story_voice_ids.vh"
    reg [16:0] total_samples;
    reg active,ready;
    reg [2:0] fetch_state;
    reg [16:0] address;
    wire [3:0] code;
    wire signed [15:0] decoded;
    wire decoded_valid,decoder_busy;
    wire load=start && !cancel;
    voice_adpcm_rom storage(.clk(clk),.address(address),.code(code));
    ima_adpcm_decoder decoder(.clk(clk),.reset_n(reset_n),.load(load),.initial_predictor(16'sd0),.initial_index(7'd0),
        .decode_ce(fetch_state==2),.code(code),.predictor(decoded),.step_index(),.decoded_valid(decoded_valid),.busy(decoder_busy));
    reg signed [15:0] current;
    reg [3:0] gain;
    reg [3:0] envelope_count;
    wire fading=pause || !active || sample_index>=total_samples-32;
    wire signed [19:0] wide={{4{current[15]}},current};
    wire signed [19:0] gained=(gain[0]?wide:20'sd0)+(gain[1]?(wide<<<1):20'sd0)+
                              (gain[2]?(wide<<<2):20'sd0)+(gain[3]?(wide<<<3):20'sd0);
    // 素材归一化峰值约 8192；满包络缩为 1/16，目标约 ±512。
    assign pcm=active && ready ? (gained>>>7) : 16'sd0;
    assign busy=active && ready;
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            total_samples<=0;active<=0;ready<=0;fetch_state<=0;address<=0;current<=0;sample_index<=0;repeat_index<=0;
            gain<=0;envelope_count<=0;done<=0;
        end else if(cancel)begin
            active<=0;ready<=0;fetch_state<=0;current<=0;sample_index<=0;repeat_index<=0;gain<=0;envelope_count<=0;done<=0;
        end else if(start)begin
            total_samples<=voice_length(voice_id);
            active<=voice_length(voice_id)!=0;ready<=0;fetch_state<=voice_length(voice_id)!=0?3'd1:3'd0;address<=voice_base(voice_id);current<=0;sample_index<=0;repeat_index<=0;gain<=0;envelope_count<=0;done<=0;
        end else begin
            done<=0;
            case(fetch_state)
            1:fetch_state<=2;
            2:fetch_state<=3;
            3:if(decoded_valid)begin current<=decoded;ready<=1;fetch_state<=0;end
            default:fetch_state<=0;
            endcase
            if(sample_ce)begin
                if(envelope_count==15)begin
                    envelope_count<=0;
                    if(fading && gain!=0)gain<=gain-1'b1;
                    else if(!fading && ready && gain<8)gain<=gain+1'b1;
                end else envelope_count<=envelope_count+1'b1;
                if(active && ready && !pause)begin
                    if(repeat_index==5)begin
                        repeat_index<=0;
                        if(sample_index==total_samples-1)begin active<=0;ready<=0;current<=0;done<=1;end
                        else begin sample_index<=sample_index+1'b1;address<=address+1'b1;fetch_state<=1;end
                    end else repeat_index<=repeat_index+1'b1;
                end
            end
        end
    end
endmodule
