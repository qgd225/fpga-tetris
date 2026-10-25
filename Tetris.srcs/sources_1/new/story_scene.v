`include "story_layout.vh"
// Compact hull, four repair branches and the original 4096x2 sprite atlas.
module story_scene(
 input clk,reset_n,input [10:0] x,y,field_right,
 input [1:0] phase,input success,failed,input [7:0] animation,
 input [4:0] charge_left,output [5:0] color_index
);
 reg [5:0] base_index,base_d;
 wire hull=x>=32 && x<1248 && y>=140 && y<704;
 wire hull_edge=hull && (x<34 || x>=1246 || y<142 || y>=702);
 wire seam=hull && ((y==176 && x<144) || (y==608 && x>=1104) || (x==144 && y>=208 && y<576));
 wire [10:0] port_y=phase==0?11'd564:phase==1?11'd500:phase==2?11'd436:11'd372;
 wire [1:0] branch=y>=548?2'd0:y>=484?2'd1:y>=420?2'd2:2'd3;
 wire port_band=(y>=564 && y<588)||(y>=500 && y<524)||(y>=436 && y<460)||(y>=372 && y<396);
 wire port=port_band && x>=field_right+6 && x<field_right+18;
 wire port_inner=port && x>=field_right+9 && x<field_right+15 && (y[5:0]>=60 || y[5:0]<4);
 wire branch_line=(y==575 || y==576 || y==511 || y==512 || y==447 || y==448 || y==383 || y==384) && x>=field_right+18 && x<984;
 wire bus=x>=982 && x<986 && y>=383 && y<592;
 wire bottom_line=y>=590 && y<594 && x>=984 && x<`STORY_CORE_X;
 wire [4:0] age=5'd24-charge_left;
 wire [10:0] flow_x_raw=field_right+18+(field_right==928?({6'd0,age}<<3):({6'd0,age}<<4));
    wire [10:0] flow_x=flow_x_raw>974?11'd974:flow_x_raw;
 wire flow_branch=branch_line && y>=port_y && y<port_y+24 && age<6 && x>=flow_x && x<flow_x+8;
 wire [1:0] bus_step=age-6;
    wire [10:0] bus_offset=phase==0?({9'd0,bus_step}<<1):phase==1?(({9'd0,bus_step}<<4)+({9'd0,bus_step}<<2)+({9'd0,bus_step}<<1)):phase==2?(({9'd0,bus_step}<<5)+({9'd0,bus_step}<<3)+({9'd0,bus_step}<<2)):(({9'd0,bus_step}<<6)+({9'd0,bus_step}<<1));
    wire [10:0] flow_y_raw=port_y+12+bus_offset;
    wire [10:0] flow_y=flow_y_raw>578?11'd578:flow_y_raw;
 wire flow_bus=bus && age>=6 && age<10 && y>=flow_y && y<flow_y+12;
 wire flow_bottom=bottom_line && age>=10 && age<12 && x<1000+{7'd0,age[1:0],4'b0}-32 && x>=984+{7'd0,age[1:0],4'b0}-32;
 wire flow=!failed && charge_left!=0 && (flow_branch||flow_bus||flow_bottom);
 wire tether=(y>=670 && y<672 && (x>=128 && x<176 || x>=1104 && x<1152)) ||
             (y>=670 && y<696 && (x>=126 && x<128 || x>=1152 && x<1154)) ||
             (y>=694 && y<696 && (x>=128 && x<208 || x>=1072 && x<1152));
 wire ring=(y>=668 && y<674 && (x>=158 && x<162 || x>=1118 && x<1122));
 wire star=(x[10:1]==40 && y[10:1]==12)||(x[10:1]==118 && y[10:1]==43)||
           (x[10:1]==148 && y[10:1]==16)||(x[10:1]==564 && y[10:1]==65)||
           (x[10:1]==615 && y[10:1]==26)||(x[10:1]==485 && y[10:1]==17);
 wire planet=x>=48 && x<176 && y>=72 && y<136;
 wire left_hand=x>=192 && x<320 && y>=640 && y<704;
 wire right_hand=x>=960 && x<1088 && y>=640 && y<704;
 wire [10:0] sx=planet?x-48:(left_hand?x-192:1087-x);
 wire [10:0] sy=planet?y-72:y-640;
 wire [11:0] sprite_address={(!planet),sy[5:1],sx[6:1]};
 wire [1:0] sprite_data;
 reg sprite_hit_d,glove_d;
 scene_sprite_rom sprites(.clk(clk),.address(sprite_address),.data(sprite_data));
 always @(*)begin
  base_index=44;
  if(hull)base_index=phase>=2 || success?53:47;
  if(hull_edge)base_index=21;
  if(seam)base_index=48;
  if(star && !hull)base_index=22;
  if(tether)base_index=23;
  if(ring)base_index=22;
  if(port)base_index=49;
  if(port_inner || branch_line)base_index=branch<phase || success?39:(branch==phase?43:48);
  if(bus || bottom_line)base_index=phase>=2 || success?39:48;
  if(flow)base_index=42;
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin base_d<=44;sprite_hit_d<=0;glove_d<=0;end
  else begin base_d<=base_index;sprite_hit_d<=planet||left_hand||right_hand;glove_d<=!planet;end
 end
 assign color_index=(!sprite_hit_d || sprite_data==0)?base_d:
   (sprite_data==1?(glove_d?6'd55:6'd47):(sprite_data==2?(glove_d?6'd22:6'd53):(glove_d?6'd23:6'd21)));
endmodule
