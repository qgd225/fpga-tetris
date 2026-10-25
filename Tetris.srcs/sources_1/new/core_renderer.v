// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 唯一机械开合位于顶部主接头；八段只改变固定结构掩码和能量状态。
module core_renderer(
    input [10:0] x,y,
    input [1:0] phase,danger,
    input [3:0] locked,
    input success,failed,charging,
    input [7:0] animation,
    output hit,
    output reg [5:0] color_index
);
    wire [10:0] cx=x-`STORY_CORE_X,cy=y-`STORY_CORE_Y;
    wire [2:0] segment=cy[7:5];
    wire [3:0] from_bottom=4'd7-{1'b0,segment};
    wire [10:0] cap_y=success?11'd6:(phase==3?11'd4:11'd0);
    wire rail=(cx==8 || cx==9 || cx==38 || cx==39);
    wire rail_enabled=phase>=2 || (phase==1 && cy>=128) || (phase==0 && !segment[0]);
    wire teeth=locked>=6 && ((cx>=(danger==2?0:2) && cx<8) || (cx>=40 && cx<(danger==2?48:46))) && cy[5:0]>=14 && cy[5:0]<16;
    wire front_cap=locked!=0 && from_bottom==locked-1 && cy[4:0]>=3 && cy[4:0]<7;
    wire rising=!failed && !success && danger==0 && !charging && cy[4:0]==(5'd28-animation[4:0]) && cx>=23 && cx<25;
    wire body=cx>=18 && cx<30 && cy>=10 && cy<248;
    wire channel=cx>=21 && cx<27 && cy[4:0]>=3 && cy[4:0]<29 && cy>=12 && cy<248;
    wire cap=cx>=16 && cx<32 && cy>=cap_y && cy<cap_y+3;
    wire socket=cx>=14 && cx<34 && cy>=9 && cy<12;
    assign hit=x>=`STORY_CORE_X && x<`STORY_CORE_X+`STORY_CORE_W &&
               y>=`STORY_CORE_Y && y<`STORY_CORE_Y+`STORY_CORE_H;
    always @(*)begin
        color_index=phase>=2 || success?6'd53:6'd47;
        if(cap || socket)color_index=success?6'd16:6'd22;
        else if(rail && rail_enabled)color_index=failed?6'd21:(phase>=2?6'd37:6'd53);
        else if(teeth)color_index=danger==2?6'd54:6'd43;
        else if(channel)begin
            if(from_bottom<locked)color_index=success?6'd16:(front_cap?6'd42:(cx>=23 && cx<25?6'd25:6'd39));
            else if(from_bottom==locked)color_index=failed?6'd43:(rising?6'd42:(cx>=23 && cx<25?6'd41:6'd43));
            else color_index=(cx==23 && cy[4:0]==16)?6'd22:6'd50;
        end else if(cy>=238 && cy<242 && cx<24 && phase!=0)color_index=failed?6'd26:(phase==3?6'd37:6'd48);
        else if(body)color_index=6'd49;
    end
endmodule
