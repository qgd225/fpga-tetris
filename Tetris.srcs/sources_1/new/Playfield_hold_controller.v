// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: Playfield_hold_controller
// 作用: 维护两名玩家的 Hold 状态、状态变化沿和共用的暂存方块。
// 时钟/复位: Clk_74M, Reset_n 低有效。
//============================================================
module Playfield_hold_controller(
    input Clk_74M,
    input Reset_n,
    input Idle,
    input Stop,
    input board_busy,
    input Finalize,
    input switch_r_flag,
    input hold_p_flag,
    input hold_p_flag2,
    input [2:0] type,
    input [2:0] type2,
    output reg en_hold,
    output reg en_hold2,
    output reg [2:0] hold_type,
    output reg en_hold_t,
    output reg en_hold_t2,
    output wire hold_up,
    output wire hold_down,
    output wire hold_up2,
    output wire hold_down2
);
    assign hold_up = !en_hold_t && en_hold;
    assign hold_down = en_hold_t && !en_hold;
    assign hold_up2 = !en_hold_t2 && en_hold2;
    assign hold_down2 = en_hold_t2 && !en_hold2;

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            en_hold <= 1'b0;
        else if (Idle)
            en_hold <= 1'b0;
        else if (Stop || board_busy)
            en_hold <= en_hold;
        else if (Finalize) begin
            if (switch_r_flag)
                en_hold <= 1'b0;
        end
        else if (!en_hold && hold_p_flag)
            en_hold <= 1'b1;
        else if (en_hold && hold_p_flag)
            en_hold <= 1'b0;
    end

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            en_hold_t <= 1'b0;
        else
            en_hold_t <= en_hold;
    end

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            en_hold2 <= 1'b0;
        else if (Idle)
            en_hold2 <= 1'b0;
        else if (Stop || board_busy)
            en_hold2 <= en_hold2;
        else if (Finalize) begin
            if (switch_r_flag)
                en_hold2 <= 1'b0;
        end
        else if (!en_hold2 && hold_p_flag2)
            en_hold2 <= 1'b1;
        else if (en_hold2 && hold_p_flag2)
            en_hold2 <= 1'b0;
    end

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            en_hold_t2 <= 1'b0;
        else
            en_hold_t2 <= en_hold2;
    end

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            hold_type <= 3'd0;
        else if (hold_up)
            hold_type <= type;
        else if (hold_up2)
            hold_type <= type2;
    end
endmodule
