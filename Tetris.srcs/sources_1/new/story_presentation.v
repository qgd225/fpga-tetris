// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 表现控制不生成任务结果，不恢复游戏，不重复发出结果事件。
module story_presentation # (parameter SUCCESS_TICKS=72)(
    input clk,reset_n,new_run,ui_tick,result_valid,result_success,
    output reg result_ready,
    output reg [6:0] success_age
);
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin result_ready<=0;success_age<=0;end
        else if(new_run)begin result_ready<=0;success_age<=0;end
        else if(result_valid && !result_ready)begin
            if(!result_success)result_ready<=1;
            else if(ui_tick)begin
                if(success_age>=SUCCESS_TICKS-1)result_ready<=1;
                else success_age<=success_age+1'b1;
            end
        end
    end
endmodule
