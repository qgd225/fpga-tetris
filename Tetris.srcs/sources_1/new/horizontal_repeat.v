//============================================================
// 模块：horizontal_repeat
// 作用：横向按键连发：首移直通，按住后按 DAS/ARR 产生移动脉冲。
// 时钟/复位：Clk_74M；Reset_n 低有效
// 时序：left_p/right_p 为已消抖的单拍按下脉冲；active 为 Playing。
//============================================================
module horizontal_repeat(
    input Clk_74M,
    input Reset_n,
    input active,
    input left_p,
    input right_p,
    input left_held,
    input right_held,
    output wire left_out,
    output wire right_out
    );

//    74.25MHz: 132ms = 9_801_000 拍, 33ms = 2_450_250 拍
    parameter [23:0] DAS_CNT = 24'd9_801_000;
    parameter [23:0] ARR_CNT = 24'd2_450_250;

    localparam [1:0] DIR_NONE  = 2'd0;
    localparam [1:0] DIR_LEFT  = 2'd1;
    localparam [1:0] DIR_RIGHT = 2'd2;

    reg [1:0]dir;
    reg armed;
    reg das_done;
    reg [23:0]timer_cnt;
    reg repeat_l;
    reg repeat_r;

//    首移由 left_p/right_p 当拍直通；连发只在 active 时输出
    assign left_out  = active && (left_p  || repeat_l);
    assign right_out = active && (right_p || repeat_r);

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    dir <= DIR_NONE;
    armed <= 1'b0;
    das_done <= 1'b0;
    timer_cnt <= 24'd0;
    repeat_l <= 1'b0;
    repeat_r <= 1'b0;
    end
    else begin
    repeat_l <= 1'b0;
    repeat_r <= 1'b0;

//    暂停、结束、方向全部松开时清除 DAS/ARR，恢复后必须重新按下
    if(!active || (!left_held && !right_held))begin
        dir <= DIR_NONE;
        armed <= 1'b0;
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
    end
//    新方向按下：立即首移，同时从零开始新方向 DAS
    else if(left_p && !right_p)begin
        dir <= DIR_LEFT;
        armed <= 1'b1;
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
    end
    else if(right_p && !left_p)begin
        dir <= DIR_RIGHT;
        armed <= 1'b1;
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
    end
//    暂停/结束后仍按着旧方向时，不自动恢复连发
    else if(!armed)begin
        dir <= DIR_NONE;
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
    end
//    双方向同时按住：暂停连发并把 DAS 归零
    else if(left_held && right_held)begin
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
    end
//    左方向保持
    else if(left_held)begin
        if(dir != DIR_LEFT)begin
        // 切换方向：立即补一拍，并从新方向 DAS 重新计时
        dir <= DIR_LEFT;
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
        repeat_l <= 1'b1;
        end
        else if(!das_done)begin
            if(timer_cnt == (DAS_CNT - 24'd1))begin
            das_done <= 1'b1;
            timer_cnt <= 24'd0;
            repeat_l <= 1'b1;
            end
            else
            timer_cnt <= timer_cnt + 24'd1;
        end
        else begin
            if(timer_cnt == (ARR_CNT - 24'd1))begin
            timer_cnt <= 24'd0;
            repeat_l <= 1'b1;
            end
            else
            timer_cnt <= timer_cnt + 24'd1;
        end
    end
//    右方向保持
    else if(right_held)begin
        if(dir != DIR_RIGHT)begin
        // 切换方向：立即补一拍，并从新方向 DAS 重新计时
        dir <= DIR_RIGHT;
        das_done <= 1'b0;
        timer_cnt <= 24'd0;
        repeat_r <= 1'b1;
        end
        else if(!das_done)begin
            if(timer_cnt == (DAS_CNT - 24'd1))begin
            das_done <= 1'b1;
            timer_cnt <= 24'd0;
            repeat_r <= 1'b1;
            end
            else
            timer_cnt <= timer_cnt + 24'd1;
        end
        else begin
            if(timer_cnt == (ARR_CNT - 24'd1))begin
            timer_cnt <= 24'd0;
            repeat_r <= 1'b1;
            end
            else
            timer_cnt <= timer_cnt + 24'd1;
        end
    end
    end
    end

endmodule
