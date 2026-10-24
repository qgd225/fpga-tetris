// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: Playfield_pixel_mapper
// 作用: 将有效像素坐标转换为场地行列编号, 格缝和场外统一输出哨兵值 24。
// 时钟/复位: 组合逻辑。
//============================================================
module Playfield_pixel_mapper(
    input [10:0] hcounter,
    input [10:0] vcounter,
    input [4:0] columns,
    output reg [4:0] column,
    output reg [4:0] row
);
    always @(*) begin
        column = 5'd24;
        if ((hcounter >= 11'd321) &&
            (hcounter < (321 + 32*columns)) &&
            (((hcounter - 11'd321) & 11'd31) < 11'd30))
            column = (hcounter - 11'd321) >> 5;
    end

    always @(*) begin
        row = 5'd24;
        if ((vcounter >= 11'd81) && (vcounter < 11'd721) &&
            (((vcounter - 11'd81) & 11'd31) < 11'd30))
            row = (vcounter - 11'd81) >> 5;
    end
endmodule
