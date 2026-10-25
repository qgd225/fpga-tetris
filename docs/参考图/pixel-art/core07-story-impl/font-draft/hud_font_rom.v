// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 一块共享双口同步 ROM：前半字形，后半固定文本；目标 RAMB18。
module hud_font_rom #(parameter INIT_FILE="story_font.mem")(
    input clk,
    input [10:0] address_a,address_b,
    output reg [7:0] data_a,data_b
);
    (* rom_style="block" *) reg [7:0] memory [0:2047];
    initial $readmemh(INIT_FILE,memory);
    always @(posedge clk)begin
        data_a<=memory[address_a];
        data_b<=memory[address_b];
    end
endmodule
