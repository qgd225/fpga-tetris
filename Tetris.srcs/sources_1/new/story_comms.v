// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 当前句加一个待播槽；阶段只留最新，终局清旧槽，危险播前复核。
module story_comms(input clk,reset_n,Idle,choose,Playing,Stop,Finalize,restart,
    input voice_busy,voice_done,success,result_ready,tick_60hz,
    input [1:0] phase,danger,
    output reg voice_start,alarm2_pulse,output voice_cancel,comms_visible,output [2:0] comms_id);
    `include "story_audio_priority.vh"
    reg opening_armed,result_queued,inflight,pending_valid;
    reg [2:0] current_id,pending_id;
    reg [1:0] phase_d,danger_d;
    reg [8:0] danger_cooldown;
    wire quiet=Finalize && success && !result_ready;
    assign voice_cancel=Idle || choose || restart || quiet;
    assign comms_visible=voice_busy && !Stop && !voice_cancel;
    assign comms_id=current_id;
    function [2:0] priority_of;
        input [2:0] id;
        begin
            case(id)
                5,6:priority_of=`AUDIO_RESULT;
                4:priority_of=`AUDIO_ALERT;
                1,2,3:priority_of=`AUDIO_PHASE;
                default:priority_of=`AUDIO_NORMAL;
            endcase
        end
    endfunction
    reg request_valid;reg [2:0] request_id;
    wire pending_live=pending_valid && !(pending_id==4 && danger!=2);
    always @(*)begin
        request_valid=0;request_id=0;
        if(Finalize && !result_queued && (!success || result_ready))begin request_valid=1;request_id=success?3'd5:3'd6;end
        else if(Playing && !Finalize)begin
            if(danger==2 && danger_d!=2 && danger_cooldown==0)begin request_valid=1;request_id=4;end
            else if(phase!=phase_d && phase!=0)begin request_valid=1;request_id={1'b0,phase};end
            else if(opening_armed)begin request_valid=1;request_id=0;end
        end
    end
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            opening_armed<=1;result_queued<=0;inflight<=0;pending_valid<=0;current_id<=0;pending_id<=0;
            phase_d<=0;danger_d<=0;danger_cooldown<=0;voice_start<=0;alarm2_pulse<=0;
        end else if(Idle || choose || restart)begin
            opening_armed<=1;result_queued<=0;inflight<=0;pending_valid<=0;current_id<=0;pending_id<=0;
            phase_d<=0;danger_d<=0;danger_cooldown<=0;voice_start<=0;alarm2_pulse<=0;
        end else begin
            voice_start<=0;alarm2_pulse<=0;
            if(voice_done)inflight<=0;
            if(quiet)begin inflight<=0;pending_valid<=0;end
            if(!Stop)begin
                phase_d<=phase;danger_d<=danger;
                if(tick_60hz && danger_cooldown!=0)danger_cooldown<=danger_cooldown-1'b1;
                if(!pending_live)pending_valid<=0;
                if(!quiet)begin
                    if(request_valid)begin
                        opening_armed<=0;
                        if(request_id==4)begin alarm2_pulse<=1;danger_cooldown<=480;end
                        if(request_id>=5)result_queued<=1;
                        if(!inflight || priority_of(request_id)>priority_of(current_id))begin
                            current_id<=request_id;voice_start<=1;inflight<=1;
                            if(request_id>=5)pending_valid<=0;
                            if(request_id==4)danger_cooldown<=480;
                        end else if(request_id!=current_id && (!pending_live || priority_of(request_id)>=priority_of(pending_id)))begin
                            pending_id<=request_id;pending_valid<=1;
                        end
                    end else if(!inflight && pending_live)begin
                        current_id<=pending_id;voice_start<=1;inflight<=1;pending_valid<=0;
                        if(pending_id==4)danger_cooldown<=480;
                    end
                end
            end
        end
    end
endmodule
