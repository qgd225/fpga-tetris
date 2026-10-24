// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 四段修复任务：按真实行信用累计，在整批搬移结束后更新档位和结果。
module story_controller(
    input clk, reset_n, new_run, playing, paused, duo,
    input row_credit, batch_done, engine_quiescent, over_raw,
    output reg [15:0] lines_total,
    output reg [2:0] story_speed,
    output wire [1:0] story_phase,
    output wire [3:0] core_locked,
    output reg phase_enter, charge_pulse, batch_commit,
    output reg finish_pending, result_valid, result_success
);
    reg mode_duo;
    reg commit_pending;
    reg credit_pending;
    reg [2:0] next_speed;
    wire [1:0] credit_delta = {1'b0,row_credit} + {1'b0,credit_pending};
    wire [15:0] credited_lines = lines_total + credit_delta;
    wire target_reached = credited_lines >= (mode_duo ? 16'd40 : 16'd32);
    assign story_phase = story_speed[2:1];
    assign core_locked = result_success ? 4'd8 : {1'b0,story_speed};
    always @(*) begin
        if(mode_duo)
            next_speed = (credited_lines>=35) ? 7 : (credited_lines>=30) ? 6 :
                         (credited_lines>=23) ? 5 : (credited_lines>=16) ? 4 :
                         (credited_lines>=11) ? 3 : (credited_lines>=6) ? 2 :
                         (credited_lines>=3) ? 1 : 0;
        else
            next_speed = (credited_lines>=28) ? 7 : (credited_lines>=24) ? 6 :
                         (credited_lines>=18) ? 5 : (credited_lines>=12) ? 4 :
                         (credited_lines>=8) ? 3 : (credited_lines>=4) ? 2 :
                         (credited_lines>=2) ? 1 : 0;
    end
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            lines_total<=0; story_speed<=0; mode_duo<=0; commit_pending<=0;
            phase_enter<=0; charge_pulse<=0; batch_commit<=0; credit_pending<=0; finish_pending<=0;
            result_valid<=0; result_success<=0;
        end else if(new_run) begin
            lines_total<=0; story_speed<=0; mode_duo<=duo; commit_pending<=0;
            phase_enter<=0; charge_pulse<=0; batch_commit<=0; credit_pending<=0; finish_pending<=0;
            result_valid<=0; result_success<=0;
        end else begin
            phase_enter<=0; charge_pulse<=0; batch_commit<=0;
            if(row_credit && paused) credit_pending<=1;
            if(batch_done) commit_pending<=1;
            if(playing && !paused && !result_valid) begin
                credit_pending<=0;
                if(credit_delta!=0) begin
                    lines_total<=credited_lines;
                    charge_pulse<=1;
                    if(target_reached) finish_pending<=1;
                end
                if((batch_done || commit_pending) && engine_quiescent) begin
                    commit_pending<=0; batch_commit<=1;
                    story_speed<=next_speed;
                    phase_enter<=next_speed[2:1]!=story_speed[2:1];
                    if(target_reached) begin
                        finish_pending<=1; result_valid<=1; result_success<=1;
                    end
                end else if(over_raw && !finish_pending && !target_reached) begin
                    result_valid<=1; result_success<=0;
                end
            end
        end
    end
endmodule
