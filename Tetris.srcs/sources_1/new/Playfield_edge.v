// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块：Playfield_margin
// 作用：场地边框绘制：根据单双人模式输出边界像素。
// 时钟/复位：纯组合逻辑
//============================================================
module Playfield_margin(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input duo,

    output reg margin
    );

    parameter [10:0]XR20 = 11'd960,
                     XR24 = 11'd1088;

    wire [10:0]XR = duo ? XR24 : XR20;

    always@(*)begin
    if(     (hcounter >= 317 && hcounter < 320 && vcounter >= 80) ||
            (hcounter >= 317 && hcounter < (XR + 3) && vcounter < 80 && vcounter >= 77) ||
            (hcounter >= XR && hcounter < (XR + 3) && vcounter >= 80))
    margin = 1'b1;
    else
    margin = 1'b0;
    end

endmodule
