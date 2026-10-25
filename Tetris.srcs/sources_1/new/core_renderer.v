// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 厚壁分段核心：八格能量舱、双轨、侧卡扣及四路实体接头。
module core_renderer(
 input [10:0] x,y,input [1:0] phase,danger,input [3:0] locked,
 input success,failed,charging,input [7:0] animation,
 output hit,output reg [5:0] color_index
);
 wire [10:0] cx=x-`STORY_CORE_X,cy=y-`STORY_CORE_Y;
 wire [2:0] segment=cy[7:5];
 wire [3:0] from_bottom=4'd7-{1'b0,segment};
 wire [1:0] branch=2'd3-cy[7:6];
 wire [10:0] cap_y=success?11'd6:(phase==3?11'd4:11'd0);
 wire rail=(cx>=14 && cx<18 || cx>=62 && cx<66) && cy>=12 && cy<248;
 wire rail_enabled=phase>=2 || phase==1 && cy>=128 || phase==0 && !segment[0];
 wire body=cx>=22 && cx<58 && cy>=12 && cy<248;
 wire channel=cx>=28 && cx<52 && cy[4:0]>=4 && cy[4:0]<28 && cy>=12 && cy<248;
 wire front_cap=locked!=0 && from_bottom==locked-1 && cy[4:0]>=4 && cy[4:0]<7;
 wire rising=!failed && !success && danger==0 && !charging && cy[4:0]==(5'd27-animation[4:0]);
 wire cap=cx>=14 && cx<66 && (cy>=cap_y && cy<cap_y+6 || cy>=248 && cy<254);
 wire socket=cx>=20 && cx<60 && (cy>=8 && cy<14 || cy>=244 && cy<248);
 wire clamp=(cx>=8 && cx<22 || cx>=58 && cx<72) && cy[5:0]>=12 && cy[5:0]<26;
 wire bolt=(cx>=11 && cx<15 || cx>=65 && cx<69) && cy[5:0]>=17 && cy[5:0]<21;
 wire seam=body && (cy[4:0]<4 || cy[4:0]>=28);
 wire inlet=cx<24 && cy[5:0]>=29 && cy[5:0]<35;
 wire collar=cx>=8 && cx<22 && cy[5:0]>=26 && cy[5:0]<38;
 wire teeth=(cx>=2 && cx<8 || cx>=72 && cx<78) && cy[5:0]>=16 && cy[5:0]<20;
 assign hit=x>=`STORY_CORE_X && x<`STORY_CORE_X+`STORY_CORE_W && y>=`STORY_CORE_Y && y<`STORY_CORE_Y+`STORY_CORE_H;
 always @(*)begin
  color_index=phase>=2 || success?6'd53:6'd47;
  if(rail)color_index=rail_enabled?(failed?6'd21:6'd37):6'd21;
  if(body)color_index=(cx==22 || cx==57)?6'd22:6'd49;
  if(seam)color_index=cy[4:0]==29?6'd22:6'd45;
  if(channel)begin
   if(from_bottom<locked)color_index=success?6'd16:(front_cap?6'd37:(cx<32?6'd37:6'd25));
   else if(from_bottom==locked)color_index=failed?6'd43:(rising || cy[4:0]<7?6'd42:(cx<32?6'd42:6'd41));
   else color_index=(cx==29 || cy[4:0]==5)?6'd21:6'd50;
  end
  if(cap || socket)color_index=cap?(cx<18 || cx>=62?6'd21:6'd22):6'd23;
  if(clamp)color_index=cy[5:0]<14?6'd22:6'd21;
  if(bolt)color_index=6'd45;
  if(collar)color_index=6'd21;
  if(cy>=238 && cy<242 && cx<28)color_index=charging?6'd42:6'd39;
  if(inlet)color_index=branch<phase || success?6'd39:(branch==phase?6'd43:6'd23);
  if(teeth)color_index=danger==2?6'd54:(danger==1?6'd43:6'd22);
 end
endmodule
