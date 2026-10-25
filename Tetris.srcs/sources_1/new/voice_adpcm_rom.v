// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_voice_config.vh"
module voice_adpcm_rom(input clk,input [16:0] address,output reg [3:0] code);
    (* rom_style="block" *) reg [3:0] data[0:`STORY_VOICE_DEPTH-1];
    initial $readmemh("story_voice.mem",data);
    always @(posedge clk)code<=address<`STORY_VOICE_DEPTH?data[address]:4'd0;
endmodule
