`include "story_layout.vh"
// Compact hull, four repair branches and the original 4096x2 sprite atlas.
module story_scene(
 input clk,reset_n,input [10:0] x,y,field_right,
 input [1:0] phase,input choose,success,failed,input [7:0] animation,input [10:0] star_drift,
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
 wire branch_line=(y==575 || y==576 || y==511 || y==512 || y==447 || y==448 || y==383 || y==384) && x>=field_right+18 && x<1000;
 wire bus=x>=982 && x<986 && y>=383 && y<592;
 wire bottom_line=y>=590 && y<594 && x>=984 && x<`STORY_CORE_X+32;
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
 wire [11:0] star_sum={1'b0,x}+{1'b0,star_drift};
 wire [10:0] star_x=star_sum>=1280?star_sum-12'd1280:star_sum[10:0];
 // 两侧折角检修舱、嵌入式状态灯和散热器，均位于玩法区外。
 wire [10:0] side_x=x>=1104?11'd1279-x:x;
 wire service=side_x>=48 && side_x<136 && y>=172 && y<620;
 wire chamfer=service && ((y<184 && side_x>124+(y-172)) || (y>=608 && side_x<48+(y-608)));
 wire service_edge=service && !chamfer && (side_x<50 || side_x>=134 || y<174 || y>=618 ||
     y>=174 && y<186 && side_x>=124+(y-174) || y>=606 && y<618 && side_x<50+(y-606));
 wire service_inset=service && side_x>=54 && side_x<130 && y>=190 && y<592;
 wire service_bolt=(side_x>=58 && side_x<64 || side_x>=120 && side_x<126) &&
     (y>=196 && y<202 || y>=578 && y<584);
 wire lamp_socket=side_x>=64 && side_x<78 && (y>=216 && y<240 || y>=356 && y<380 || y>=548 && y<572);
 wire lamp=side_x>=68 && side_x<74 && (y>=222 && y<230 || y>=362 && y<370 || y>=554 && y<562);
 wire vents=side_x>=92 && side_x<116 && y>=472 && y<528 && y[3:0]<5;
 wire rib=side_x>=84 && side_x<86 && y>=254 && y<438;
 wire access=side_x>=56 && side_x<132 && y>=632 && y<664;
 wire access_edge=access && (side_x<58 || side_x>=130 || y<634 || y>=662);
 wire access_vent=access && side_x>=66 && side_x<120 && (y>=642 && y<646 || y>=652 && y<656);
 wire star=(star_x[10:1]==40 && y[10:1]==12)||(star_x[10:1]==118 && y[10:1]==43)||
           (star_x[10:1]==148 && y[10:1]==16)||(star_x[10:1]==564 && y[10:1]==65)||
           (star_x[10:1]==615 && y[10:1]==26)||(star_x[10:1]==485 && y[10:1]==17);
 wire menu_stars=choose && ((x[10:1]==118 && y[10:1]==180)||(x[10:1]==288 && y[10:1]==264)||
     (x[10:1]==560 && y[10:1]==274)||(x[10:1]==148 && y[10:1]==284)||(x[10:1]==304 && y[10:1]==120));
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
  if(hull && !choose)base_index=phase>=2 || success?53:47;
  if(!choose && (hull_edge))base_index=21;
  if(!choose && (seam))base_index=48;
  if(hull && ((y==652 && (x>=352 && x<496 || x>=784 && x<928)) ||
      (y==688 && x>=448 && x<832) || (x==448 && y>=680 && y<688) || (x==832 && y>=680 && y<688)))base_index=48;
  if(y>=660 && y<680 && (x>=336 && x<376 || x>=904 && x<944) && y[2:0]<2)base_index=23;
  if((y==648 || y==684) && (x>=96 && x<112 || x>=1168 && x<1184))base_index=22;
  if(!choose && service && !chamfer)base_index=21;
  if(!choose && service_inset && !chamfer)base_index=23;
  if(!choose && (service_edge))base_index=22;
  if(!choose && (service_bolt))base_index=45;
  if(!choose && (lamp_socket))base_index=49;
  if(!choose && (lamp))base_index=failed?54:(phase>=2 || success?25:43);
  if(!choose && (vents || rib))base_index=45;
  if(access)base_index=21;
  if(access_edge)base_index=22;
  if(access_vent)base_index=45;
  if(star && (!hull || choose))base_index=22;
  if(menu_stars)base_index=22;
  if(tether)base_index=23;
  if(ring)base_index=22;
  if(!choose && port)base_index=49;
  if(!choose && (port_inner || branch_line))base_index=branch<phase || success?39:(branch==phase?43:48);
  if(!choose && (bus || bottom_line))base_index=phase>=2 || success?39:48;
  if(!choose && flow)base_index=42;
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin base_d<=44;sprite_hit_d<=0;glove_d<=0;end
  else begin base_d<=base_index;sprite_hit_d<=planet||left_hand||right_hand;glove_d<=!planet;end
 end
 assign color_index=(!sprite_hit_d || sprite_data==0)?base_d:
   (sprite_data==1?(glove_d?6'd55:6'd47):(sprite_data==2?(glove_d?6'd22:6'd53):(glove_d?6'd23:6'd21)));
endmodule
