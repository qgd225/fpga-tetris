// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: Playfield_ghost_scanner
// 作用: 每拍向下扫描一行, 根据外部碰撞结果保存幽灵落点和阻挡来源。
// 时钟/复位: Clk_74M, Reset_n 低有效。
//============================================================
module Playfield_ghost_scanner(
    input Clk_74M,
    input Reset_n,
    input restart,
    input blocked,
    input blocked_by_other,
    input [4:0] current_row,
    output reg [4:0] scan_row,
    output reg done,
    output reg valid,
    output reg blocked_by_other_latched,
    output reg [4:0] landing_row
);
    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n) begin
            scan_row <= 5'd0;
            done <= 1'b0;
            valid <= 1'b0;
            blocked_by_other_latched <= 1'b0;
            landing_row <= 5'd0;
        end
        else if (restart) begin
            scan_row <= current_row;
            done <= 1'b0;
            blocked_by_other_latched <= 1'b0;
        end
        else if (!done) begin
            if (blocked) begin
                done <= 1'b1;
                valid <= 1'b1;
                blocked_by_other_latched <= blocked_by_other;
                landing_row <= (scan_row > current_row) ?
                               (scan_row - 5'd1) : current_row;
            end
            else if (scan_row < 5'd21)
                scan_row <= scan_row + 5'd1;
            else begin
                done <= 1'b1;
                valid <= 1'b1;
            end
        end
    end
endmodule
