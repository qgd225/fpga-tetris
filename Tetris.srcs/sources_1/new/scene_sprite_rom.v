// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
module scene_sprite_rom #(parameter INIT_FILE="story_sprites.mem")(
    input clk,input [11:0] address,output reg [1:0] data
);
    (* rom_style="block" *) reg [1:0] memory[0:4095];
    initial $readmemh(INIT_FILE,memory);
    always @(posedge clk)data<=memory[address];
endmodule
