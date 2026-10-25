// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 所有绘制层共用的坐标寄存级，切开VGA有效区门控/前取与格坐标/存储读取。
module story_pixel_frontend(
    input clk,reset_n,input [10:0] hcounter,vcounter,
    output reg [10:0] x,y
);
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin x<=0;y<=0;end
        else begin x<=hcounter+`STORY_LOOKAHEAD;y<=vcounter;end
    end
endmodule
