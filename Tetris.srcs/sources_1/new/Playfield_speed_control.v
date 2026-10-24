// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: Playfield_speed_control
// 作用: 根据分数和游戏时间选择速度等级, 输出对应的自动下落间隔。
// 时钟/复位: Clk_74M, Reset_n 低有效。
//============================================================
module Playfield_speed_control #(
    parameter MCNT_Drop = 74_250_000 - 1,
    parameter [19:0] LV1_TH = 20'd4,
    parameter [19:0] LV2_TH = 20'd15,
    parameter [19:0] LV3_TH = 20'd35,
    parameter [19:0] LV4_TH = 20'd70,
    parameter [19:0] LV5_TH = 20'd150,
    parameter [19:0] LV6_TH = 20'd300,
    parameter [19:0] LV7_TH = 20'd600,
    parameter [13:0] TIME_LV1 = 14'd20,
    parameter [13:0] TIME_LV2 = 14'd60,
    parameter [13:0] TIME_LV3 = 14'd120,
    parameter [13:0] TIME_LV4 = 14'd200,
    parameter [13:0] TIME_LV5 = 14'd300,
    parameter [13:0] TIME_LV6 = 14'd440,
    parameter [13:0] TIME_LV7 = 14'd600,
    parameter [13:0] TIME_LV1_D = 14'd40,
    parameter [13:0] TIME_LV2_D = 14'd120,
    parameter [13:0] TIME_LV3_D = 14'd240,
    parameter [13:0] TIME_LV4_D = 14'd400,
    parameter [13:0] TIME_LV5_D = 14'd600,
    parameter [13:0] TIME_LV6_D = 14'd880,
    parameter [13:0] TIME_LV7_D = 14'd1200
)(
    input Clk_74M,
    input Reset_n,
    input [19:0] score,
    input [13:0] time_sec,
    input duo,
    output reg [2:0] speed_level,
    output reg [29:0] Drop
);
    wire [2:0] lv_score = (score >= LV7_TH) ? 3'd7 :
                         (score >= LV6_TH) ? 3'd6 :
                         (score >= LV5_TH) ? 3'd5 :
                         (score >= LV4_TH) ? 3'd4 :
                         (score >= LV3_TH) ? 3'd3 :
                         (score >= LV2_TH) ? 3'd2 :
                         (score >= LV1_TH) ? 3'd1 : 3'd0;
    wire [2:0] lv_time_s = (time_sec >= TIME_LV7) ? 3'd7 :
                          (time_sec >= TIME_LV6) ? 3'd6 :
                          (time_sec >= TIME_LV5) ? 3'd5 :
                          (time_sec >= TIME_LV4) ? 3'd4 :
                          (time_sec >= TIME_LV3) ? 3'd3 :
                          (time_sec >= TIME_LV2) ? 3'd2 :
                          (time_sec >= TIME_LV1) ? 3'd1 : 3'd0;
    wire [2:0] lv_time_d = (time_sec >= TIME_LV7_D) ? 3'd7 :
                          (time_sec >= TIME_LV6_D) ? 3'd6 :
                          (time_sec >= TIME_LV5_D) ? 3'd5 :
                          (time_sec >= TIME_LV4_D) ? 3'd4 :
                          (time_sec >= TIME_LV3_D) ? 3'd3 :
                          (time_sec >= TIME_LV2_D) ? 3'd2 :
                          (time_sec >= TIME_LV1_D) ? 3'd1 : 3'd0;
    wire [2:0] lv_time = duo ? lv_time_d : lv_time_s;
    wire [2:0] lv_now = (lv_score > lv_time) ? lv_score : lv_time;

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            speed_level <= 3'd0;
        else
            speed_level <= lv_now;
    end

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
            Drop <= MCNT_Drop;
        else
            case (speed_level)
                0: Drop <= (MCNT_Drop*64'd80)/64'd100;
                1: Drop <= (MCNT_Drop*64'd71)/64'd100;
                2: Drop <= (MCNT_Drop*64'd63)/64'd100;
                3: Drop <= (MCNT_Drop*64'd55)/64'd100;
                4: Drop <= (MCNT_Drop*64'd46)/64'd100;
                5: Drop <= (MCNT_Drop*64'd38)/64'd100;
                6: Drop <= (MCNT_Drop*64'd30)/64'd100;
                7: Drop <= (MCNT_Drop*64'd21)/64'd100;
            endcase
    end
endmodule
