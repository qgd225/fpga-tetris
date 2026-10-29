// A2 public base plane: field, original block/debris shader, shared previews.
// Reads game state only. Three clocks to RGB/hit, matched to the panel ROM.
module ui_basic_layer(
 input clk,reset_n,enable,duo,campaign,input [10:0] x,y,
 input [23:0] panel_rgb,
 input in_field,cell_visible,occupied,debris_cell,piece1,piece2,ghost1,ghost2,
 input hint_active,hint_hit,input [2:0] hint_type,type1,type2,cell_type,
 input [4:0] local_x,local_y,
 input next1,next2,hold,hold_visible,input [2:0] next_type1,next_type2,hold_type,
 input [4:0] next_x,next_y,hold_x,hold_y,
 input [43:0] bounds1,bounds2,
 input [2:0] hold_conditions,input hold_reserved,hold_actor2,hold_expire_flash,hold_reject_flash,
 input feedback_clear_row,feedback_clear,input [4:0] feedback_clear_age,input [7:0] animation,
 output [23:0] rgb,output hit,output material_only
);
 `include "story_palette.vh"
 function box;
  input [10:0] px,py,bx,by,w,h;
  begin box=px>=bx && px<bx+w && py>=by && py<by+h;end
 endfunction
 function corner;
  input [43:0] b;
  reg [10:0] l,r,t,bot;
  begin
   l=b[10:0];r=b[21:11];t=b[32:22];bot=b[43:33];
   corner=x>=l && x<=r && y>=t && y<=bot &&
    (((x<l+2 || x+2>r) && (y<t+9 || y+9>bot)) ||
     ((y<t+2 || y+2>bot) && (x<l+9 || x+9>r)));
  end
 endfunction
 function dash;
  input [4:0] value;
  begin dash=value<4 || (value>=7 && value<11) || (value>=14 && value<18) || value==21;end
 endfunction
 reg panel_hit,foreground,coverage,draw_piece,ghosted,hinted;
 reg [1:0] panel_id;
 reg [7:0] panel_x,panel_y;
 reg [2:0] kind;
 reg [4:0] mx,my;
 reg [23:0] color;
 wire [13:0] spark_seed=x*14'd3+y*14'd7+animation;
 integer i;
 reg [23:0] base_color,overlay_color,base_q,overlay_q;
 reg overlay_hit,overlay_hit_q,field_q,draw_q,ghost_q,hint_q;
 reg [2:0] kind_q;reg [4:0] mx_q,my_q;
 always @(*)begin
  panel_hit=0;panel_id=0;panel_x=0;panel_y=0;
  if(box(x,y,143,148,155,172))begin panel_hit=1;panel_x=x-143;panel_y=y-148;end
  else if(duo && box(x,y,959,148,155,172))begin panel_hit=1;panel_id=campaign?1:3;panel_x=x-959;panel_y=y-148;end
  else if(box(x,y,154,332,140,174))begin panel_hit=1;panel_id=2;panel_x=x-154;panel_y=y-332;end
  coverage=enable && (in_field || panel_hit);
  base_color=(local_x==23 || local_y==23)?24'h142b38:24'h091722;
  overlay_hit=0;overlay_color=0;draw_piece=0;ghosted=0;hinted=0;kind=0;mx=0;my=0;
  if(in_field && cell_visible)begin
   mx=local_x;my=local_y;
   if(piece1)begin draw_piece=1;kind=type1;end
   else if(piece2 && duo)begin draw_piece=1;kind=type2;end
   else if(occupied)begin draw_piece=1;kind=debris_cell?7:cell_type;end
   else if(!duo && hint_active && hint_hit)begin hinted=1;kind=hint_type;end
   else if(ghost1 || (duo && ghost2))begin ghosted=1;kind=ghost1?type1:type2;end
  end
  if(next1 || (duo && next2))begin draw_piece=1;kind=next2?next_type2:next_type1;mx=next_x;my=next_y;end
  if(hold && hold_visible)begin draw_piece=1;kind=hold_type;mx=hold_x;my=hold_y;end
  if(corner(bounds1))begin overlay_hit=1;overlay_color=24'h59e7ef;end
  if(duo && corner(bounds2))begin overlay_hit=1;overlay_color=24'he45bbf;end
  for(i=0;i<3;i=i+1)begin
   if(box(x,y,212+i*10,490,5,5))begin overlay_hit=1;overlay_color=hold_conditions[i]?24'h6b9eaa:24'h2e4353;end
  end
  if(hold_reserved && box(x,y,282,405,6,12) && x-282<(y<411?y-405:416-y))begin
   overlay_hit=1;overlay_color=hold_actor2?24'he45bbf:24'h7fe3ec;
  end
  if((hold_reject_flash || hold_expire_flash || hold_reserved) && box(x,y,166,366,116,116) &&
    (x<168 || x>=280 || y<368 || y>=480))begin
   overlay_hit=1;overlay_color=hold_expire_flash?24'he8eef2:hold_reject_flash?24'hd8442e:hold_actor2?24'he45bbf:24'h7fe3ec;
  end
  if(in_field && feedback_clear_row && local_y>=9 && local_y<12)begin
   overlay_hit=1;overlay_color=feedback_clear_age<3?24'hffffff:24'hffc15b;
  end
 end
 // Clock one selects geometry/type; clock two shades; clock three aligns RGB.
 always @(posedge clk)begin
  base_q<=base_color;overlay_q<=overlay_color;overlay_hit_q<=overlay_hit;
  kind_q<=kind;mx_q<=mx;my_q<=my;field_q<=in_field;
  draw_q<=draw_piece;ghost_q<=ghosted;hint_q<=hinted;
 end
 always @(*)begin
  color=base_q;foreground=field_q;
  if(draw_q && mx_q<22 && my_q<22)begin
   foreground=1;
   if(kind_q==7)begin
    if(mx_q==0 || my_q==0)color=story_palette(22);
    else if(mx_q==my_q || mx_q+my_q==21)color=story_palette(21);
    else color=story_palette(23);
   end else if((mx_q==0 || mx_q==21) && (my_q==0 || my_q==21))color=field_q?24'h091722:24'h06121d;
   else if(mx_q==0 || my_q==0)color=story_palette(8+kind_q);
   else if(mx_q==21 || my_q==21)color=story_palette(30+kind_q);
   else color=story_palette(1+kind_q);
  end
  if(ghost_q && (((my_q==1 || my_q==20) && dash(mx_q)) || ((mx_q==1 || mx_q==20) && dash(my_q))))begin
   foreground=1;color=story_palette(8+kind_q);
  end
  if(hint_q && (mx_q==0 || mx_q==21 || my_q==0 || my_q==21))begin foreground=1;color=24'hffe39c;end
  if(overlay_hit_q)begin foreground=1;color=overlay_q;end
 end
 reg [23:0] c1,c2;
 reg [2:0] cover_pipe,panel_pipe;reg [1:0] fg_pipe;
 reg [13:0] spark_seed_q;
 reg [7:0] spark_remainder_q;
 reg [2:0] spark_enable_pipe;
 reg spark_hit;
 always @(posedge clk)begin
  c1<=color;c2<=c1;
  spark_seed_q<=spark_seed;spark_remainder_q<=spark_seed_q%173;
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin cover_pipe<=0;panel_pipe<=0;fg_pipe<=0;spark_enable_pipe<=0;spark_hit<=0;end
  else begin
   cover_pipe<={cover_pipe[1:0],coverage};panel_pipe<={panel_pipe[1:0],panel_hit};fg_pipe<={fg_pipe[0],foreground};
   spark_enable_pipe<={spark_enable_pipe[1:0],in_field && feedback_clear && y>=570};
   spark_hit<=spark_enable_pipe[1] && spark_remainder_q<3;
  end
 end
 assign rgb=spark_hit?24'hffc15b:panel_pipe[2] && !fg_pipe[1]?panel_rgb:c2;
 assign hit=cover_pipe[2];
 assign material_only=panel_pipe[2] && !fg_pipe[1] && !spark_hit;
endmodule
