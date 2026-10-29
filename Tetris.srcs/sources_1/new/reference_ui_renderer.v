// Reference-driven visual layer. Reads game state only; no gameplay feedback.
module reference_ui_renderer(
 input clk,reset_n,input [10:0] x,y,
 input duo,campaign,choose,ship_select,Idle,input [3:0] choose_cnt,input [1:0] menu_offset,
 input [7:0] reserve_fill,input [1:0] reserve_alarm,input [23:0] score_bcd,
 input hint_active,hint_hit,input [2:0] hint_quota,hint_capacity,hint_type,input [9:0] hint_life,
 input [1:0] level_id,phase,input [3:0] locked,input [6:0] debris_left,
 input [2:0] speed,input [23:0] lines_bcd,input [15:0] time_bcd,
 input [7:0] animation,input [4:0] charge_left,
 input comms_visible,input [2:0] comms_id,
 input Stop,success,hold_ready,hold_visible,hold_reserved,hold_actor2,
 input Finalize,result_ready,input [1:0] result_option,rank,input [7:0] average_tenths,
 input reserve_pulse,recharge_capped,recharge_no_gain,input [5:0] speed_flash,
 input [5:0] recharge_age,input [9:0] recharge_units,input [4:0] clear_credit,input [5:0] clear_credit_age,
 input hold_expire_flash,hold_reject_flash,input [2:0] hold_conditions,
 input in_field,cell_visible,occupied,debris_cell,piece1,piece2,ghost1,ghost2,
 input [4:0] local_x,local_y,input [2:0] type1,type2,cell_type,
 input next1,next2,hold,input [2:0] next_type1,next_type2,hold_type,
 input [4:0] next_x,next_y,hold_x,hold_y,
 input [43:0] bounds1,bounds2,input feedback_clear,feedback_clear_row,
 input [4:0] feedback_clear_age,
 output [23:0] rgb
);
 `include "reference_ui_geometry.vh"
 `include "ui_layout_geometry.vh"
 `include "game_mode_params.vh"
 `include "story_palette.vh"
 `include "ui_text_templates.vh"
 wire [23:0] skin_pixel;
 ui_hull_background hull(.x(x),.y(y),.duo(duo),.choose(choose),.rgb(skin_pixel));
 function inside;
  input [10:0] bx,by,w,h;
  begin inside=x>=bx && x<bx+w && y>=by && y<by+h;end
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
 function [15:0] decimal2;
  input [7:0] n;
  reg [7:0] a,b;
  begin a=48+(n/10)%10;b=48+n%10;decimal2={a,b};end
 endfunction
 function [7:0] digit8;
  input [19:0] n;begin digit8=8'd48+n;end
 endfunction
 function [47:0] bcd6;
  input [23:0] b;
  integer i;reg started;reg [3:0] digit;
  begin
   bcd6=48'h202020202020;started=0;
   for(i=5;i>=0;i=i-1)begin
    digit=(b>>(i*4))&15;
    if(digit!=0 || started || i==0)begin bcd6[i*8+:8]=8'd48+digit;started=1;end
   end
  end
 endfunction
 function [31:0] percent4;
  input [8:0] n;
  begin percent4=n>=100?"100%":{8'd32,decimal2(n),8'd37};end
 endfunction
 // Four-cell outline used by the graphical solo landing-assist panel.
 function hint_mino;
  input [2:0] t;input integer c,r;
  begin
   hint_mino=0;
   if(c>=0 && c<4 && r>=0 && r<2)begin
    case(t)
     0:hint_mino=r==0;
     1:hint_mino=(r==0 && c<3) || (r==1 && c==1);
     2:hint_mino=c<2;
     3:hint_mino=(r==0 && c<2) || (r==1 && c>=1 && c<3);
     4:hint_mino=(r==0 && c>=1 && c<3) || (r==1 && c<2);
     5:hint_mino=(r==0 && c==2) || (r==1 && c<3);
     6:hint_mino=(r==0 && c==0) || (r==1 && c<3);
     default:hint_mino=0;
    endcase
   end
  end
 endfunction
 localparam [48:0] HINT_DOT=49'h021f3efef9f08;
 localparam [279:0] HINT_INFINITY=280'h02000803fe0ff8f07bc1ee03b80ec01f007e03b80ef07bc1e3fe0ff802000800000000;
 wire [5:0] hint_dot_address=(y-163)*6'd7+x-1037;
 wire [8:0] hint_infinity_address=(y-290)*9'd28+x-1026;
 reg [6:0] credits;reg [7:0] target,total;reg [6:0] charge_percent,reserve_percent;reg [8:0] debris_percent;
 reg [9:0] lit_top;integer slot,offset,i;
 reg [1:0] menu_ship_index;reg [2:0] menu_row;reg [10:0] menu_y,button_left;reg [3:0] menu_selection;
 wire [8:0] menu_dy=y-172,phase_dy=y-372;
 wire [7:0] terminal_dy=y-330;
 wire [5:0] credit_drift=(6'd48-clear_credit_age)/6'd3;
 wire [10:0] credit_y=11'd540-{5'd0,credit_drift};
 reg [10:0] dialog_x;
 reg [2:0] hint_cols,hc;reg [1:0] hr;reg [10:0] hint_left;reg [3:0] hx,hy;
 wire [5:0] hint_local_x=x-hint_left;
 wire [4:0] hint_top_y=y-202,hint_bottom_y=y-258;
 reg [23:0] hint_ink;
 integer mx,my,kind,mat_address;reg [1:0] current_phase,phase_row;
 reg [10:0] text_x,text_y;reg [5:0] text_width,text_pitch,text_height;integer text_scale,column,gx,gy,digit_index,digit_x,digit_y;
 reg text_valid,compact_text;reg [6:0] text_id;reg [255:0] message;reg [7:0] character;
 reg [23:0] color,text_ink;
 reg [23:0] p0,p1,p2,p3;
 reg force_paint;
 reg color_owned;reg [2:0] owned_pipe;reg [23:0] skin0,skin1,skin2;
 reg [23:0] ink0,ink1,ink2;
 reg [2:0] force_pipe;
 reg font_lit_q;
 wire basic_hit,shared_font_lit,basic_material_only;
 wire [23:0] basic_rgb,mission_rgb,panel_rgb;
 wire mission_hit;
 wire terminal_panel=Finalize && result_ready && x>=416 && x<864 && y>=232 && y<592;
 wire pause_panel=Stop && x>=560 && x<720 && y>=276 && y<340;
 wire basic_enable=!choose && !terminal_panel && !pause_panel && !(comms_visible && x>=(duo?UI_DIALOG_DUO_X:UI_DIALOG_SOLO_X) && x<(duo?UI_DIALOG_DUO_X+360:UI_DIALOG_SOLO_X+360) && y>=160 && y<264);
 wire [4:0] mission_flash=campaign?charge_left:(!recharge_no_gain && recharge_age>30?recharge_age-6'd30:6'd0);
 ui_mission_layer mission(.clk(clk),.reset_n(reset_n),.enable(choose || basic_enable),.duo(duo),.campaign(campaign),
  .blocked(debris_left>mode_half(duo,level_id)),.choose(choose),.x(x),.y(y),.locked(locked),.reserve_alarm(reserve_alarm),
  .reserve_fill(reserve_fill),.animation(animation),.charge_left(mission_flash),.reserve_pulse(reserve_pulse),
  .charge_percent(charge_percent[6:0]),.debris_percent(debris_percent[6:0]),.lit_top(lit_top[9:0]),
  .panel_rgb(panel_rgb),.rgb(mission_rgb),.hit(mission_hit));
 wire [11:0] shared_dx={1'b0,x}-{1'b0,text_x};
 wire [11:0] shared_dy={1'b0,y}-{1'b0,text_y};
 ui_basic_layer basic(
  .clk(clk),.reset_n(reset_n),.enable(basic_enable),.duo(duo),.campaign(campaign),.x(x),.y(y),
  .in_field(in_field),.cell_visible(cell_visible),.occupied(occupied),.debris_cell(debris_cell),
  .piece1(piece1),.piece2(piece2),.ghost1(ghost1),.ghost2(ghost2),
  .hint_active(hint_active),.hint_hit(hint_hit),.hint_type(hint_type),.type1(type1),.type2(type2),.cell_type(cell_type),
  .local_x(local_x),.local_y(local_y),.next1(next1),.next2(next2),.hold(hold),.hold_visible(hold_visible),
  .next_type1(next_type1),.next_type2(next_type2),.hold_type(hold_type),
  .next_x(next_x),.next_y(next_y),.hold_x(hold_x),.hold_y(hold_y),.bounds1(bounds1),.bounds2(bounds2),
  .hold_conditions(hold_conditions),.hold_reserved(hold_reserved),.hold_actor2(hold_actor2),
  .hold_expire_flash(hold_expire_flash),.hold_reject_flash(hold_reject_flash),
  .feedback_clear_row(feedback_clear_row),.feedback_clear(feedback_clear),.feedback_clear_age(feedback_clear_age),.animation(animation),
  .panel_rgb(panel_rgb),.rgb(basic_rgb),.hit(basic_hit),.material_only(basic_material_only));
 ui_text_compact shared_text(
  .clk(clk),.reset_n(reset_n),.enable(text_valid),
  .message(message),.text_id(text_id),.dx(shared_dx),.dy(shared_dy),
  .pitch(text_pitch[5:0]),.height(text_height[5:0]),.length(text_width[5:0]),.lit(shared_font_lit));

 (* rom_style="distributed" *) reg [6:0] charge_table[0:511],reserve_percent_table[0:255];
 (* rom_style="distributed" *) reg [8:0] debris_table[0:1023],reserve_height_table[0:255];
 initial begin
  $readmemh("ui_charge_percent.mem",charge_table);$readmemh("ui_debris_percent.mem",debris_table);
  $readmemh("ui_reserve_height.mem",reserve_height_table);$readmemh("ui_reserve_percent.mem",reserve_percent_table);
 end
 reg ghosted,draw_piece,hinted;
 always @(*)begin
  dialog_x=duo?UI_DIALOG_DUO_X:UI_DIALOG_SOLO_X;
  credits=lines_bcd[23:8]!=0?7'd100:lines_bcd[3:0]+lines_bcd[7:4]*7'd10;
  target=mode_target(duo,level_id);total=mode_total(duo,level_id);
  charge_percent=campaign?(credits>=target?100:charge_table[{duo,level_id,credits[5:0]}]):(speed+1)*100/8;
  debris_percent=debris_table[{duo,level_id,debris_left}];
  force_paint=0;color=24'd0;color_owned=0;mx=0;my=0;kind=0;mat_address=0;draw_piece=0;ghosted=0;
  current_phase=locked<3?0:locked<5?1:locked<7?2:3;
  phase_row=0;slot=0;offset=0;i=0;hinted=0;
  hint_cols=hint_type==0?4:hint_type==2?2:3;hint_left=1040-hint_cols*6;
  hx=0;hy=0;hc=0;hr=0;hint_ink=hint_active?24'h7fe3ec:(!campaign || hint_quota>0)?24'h587d91:24'h72542c;
  button_left=0;menu_ship_index=0;menu_row=0;menu_y=172;menu_selection=ship_select?level_id:choose_cnt;
  reserve_percent=reserve_fill>=174?100:reserve_percent_table[reserve_fill];
  lit_top=campaign?REF_CORE_Y+(8-locked)*REF_CORE_PITCH:REF_CORE_Y+REF_CORE_H-reserve_height_table[reserve_fill];
  if(choose && inside(716,172,492,374))begin
   menu_row=menu_dy/7'd98;menu_y=172+menu_row*98;menu_ship_index=menu_row[1:0];
   if(y<menu_y+80 && menu_row<4 && (ship_select?{1'b0,menu_ship_index}:menu_row)==menu_selection)begin
    if(x<720 || x>=1204 || y<menu_y+3 || y>=menu_y+77)begin color_owned=1;color=24'h35e0f5;end 
    else if(x>=768 && x<1200 && y>=menu_y+8 && y<menu_y+72)begin color_owned=1;color=24'h0b2b39;end 
   end
  end
  text_valid=0;compact_text=0;begin text_id=7'd0;message=256'd0;end text_x=0;text_y=0;text_scale=1;text_width=0;text_pitch=12;text_height=14;text_ink=24'he8eef2;
  if(!choose)begin
  if(campaign && inside(REF_CHARGE_VALUE_X,REF_CHARGE_VALUE_Y,REF_CHARGE_VALUE_W,REF_CHARGE_VALUE_H))begin
   text_valid=1;text_x=REF_CHARGE_VALUE_X;text_y=61;text_width=5;text_pitch=12;
   if(credits<100)begin text_id=7'd11;message={decimal2(credits),8'd0,decimal2(target),216'd0};end 
   else begin text_width=9;text_pitch=8;begin text_id=7'd12;message={bcd6(lines_bcd),8'd0,decimal2(target),184'd0};end end
   text_ink=24'h7fe3ec;
  end
  if(campaign && inside(REF_DEBRIS_VALUE_X,REF_DEBRIS_VALUE_Y,REF_DEBRIS_VALUE_W,REF_DEBRIS_VALUE_H))begin
   text_valid=1;text_x=REF_DEBRIS_VALUE_X;text_y=97;text_width=7;
   begin text_id=7'd13;message={decimal2(debris_left),40'd0,200'd0};end text_ink=24'hffc15b;
  end
  if(campaign && inside(REF_CHARGE_PERCENT_X,REF_CHARGE_PERCENT_Y,REF_CHARGE_PERCENT_W,REF_CHARGE_PERCENT_H))begin
   text_valid=1;text_x=REF_CHARGE_PERCENT_X;text_y=61;text_width=4;
   begin text_id=7'd14;message={percent4(charge_percent),224'd0};end text_ink=24'h7fe3ec;text_pitch=12;
  end
  if(campaign && inside(REF_DEBRIS_PERCENT_X,REF_DEBRIS_PERCENT_Y,REF_DEBRIS_PERCENT_W,REF_DEBRIS_PERCENT_H))begin
   text_valid=1;text_x=REF_DEBRIS_PERCENT_X;text_y=97;text_width=4;
   begin text_id=7'd14;message={percent4(debris_percent),224'd0};end text_ink=24'hffc15b;text_pitch=12;
  end
   if(campaign && inside(478,61,84,14))begin
    text_valid=1;text_x=478;text_y=61;text_width=6;begin text_id=7'd15;message={48'd0,208'd0};end text_ink=24'h7fe3ec;
   end
   if(campaign && inside(478,97,84,14))begin
    text_valid=1;text_x=478;text_y=97;text_width=6;begin text_id=7'd16;message={48'd0,208'd0};end text_ink=24'hffc15b;
   end
   if(campaign && inside(170,45,126,21))begin
    text_valid=1;text_x=170;text_y=45;text_width=7;text_pitch=18;text_height=21;
    begin text_id=7'd17;message={40'd0,decimal2(level_id+1),200'd0};end 
   end
  if(inside(986,324,112,18))begin
   text_valid=1;compact_text=1;text_x=999;text_y=326;text_width=7;text_pitch=12;text_height=14;
   begin text_id=7'd18;message={32'd0,8'd49+{5'd0,speed},16'd0,200'd0};end if(speed_flash!=0 && animation[2])text_ink=24'h7fe3ec;
  end
  if(inside(UI_STATUS_X+6,UI_STATUS_Y+6,84,24))begin
   text_valid=1;text_x=UI_CORE_CENTER_X-36;text_y=UI_STATUS_Y+11;text_width=6;
   if(!campaign)begin text_x=UI_CORE_CENTER_X-42;text_width=7;text_pitch=12;begin text_id=7'd19;message={56'd0,200'd0};end text_ink=reserve_alarm==2?24'hd8442e:reserve_alarm==1?24'hffc15b:24'h7fe3ec;end
   else if(debris_left>mode_half(duo,level_id))begin begin text_id=7'd20;message={48'd0,208'd0};end text_ink=24'hd8442e;end
   else if(debris_left!=0)begin begin text_id=7'd21;message={48'd0,208'd0};end text_ink=24'hffc15b;end
   else begin begin text_id=7'd22;message={48'd0,208'd0};end text_ink=24'h7fe3ec;end
  end
   if(campaign && inside(986,372,108,216))begin
    phase_row=phase_dy/6'd54;slot=3-phase_row;
    text_valid=1;text_y=400+phase_row*54;text_pitch=12;text_height=14;
    text_ink=slot==current_phase?24'hffc15b:(slot<current_phase?24'h7fe3ec:24'hb3c8d8);
    case(phase_row)
     0:begin text_width=8;begin text_id=7'd23;message={64'd0,192'd0};end end
     1:begin text_width=9;begin text_id=7'd24;message={72'd0,184'd0};end end
     2:begin text_width=7;begin text_id=7'd25;message={56'd0,200'd0};end end
     default:begin text_width=9;begin text_id=7'd26;message={72'd0,184'd0};end end
    endcase
    text_x=1041-text_width*6;
   end
   if(inside(555,649,240,28))begin
    text_valid=1;text_x=555;text_y=649;text_width=10;text_pitch=24;text_height=28;
    begin text_id=7'd27;message={40'd0,8'd48+{4'd0,time_bcd[15:12]},8'd48+{4'd0,time_bcd[11:8]},8'd0,8'd48+{4'd0,time_bcd[7:4]},8'd48+{4'd0,time_bcd[3:0]},176'd0};end text_ink=24'hb9edf4;
   end
   if(inside(157,158,27,21))begin
    text_valid=1;text_x=160;text_y=161;text_width=2;begin text_id=7'd28;message={16'd0,240'd0};end text_ink=24'h05121c;
   end
   if(duo && inside(973,158,27,21))begin
    text_valid=1;text_x=976;text_y=161;text_width=2;begin text_id=7'd29;message={16'd0,240'd0};end text_ink=24'h05121c;
   end
   if(inside(196,153,74,26) || duo && inside(1012,153,74,26))begin
    text_valid=1;text_x=x<900?201:1017;text_y=161;text_width=4;begin text_id=7'd30;message={32'd0,224'd0};end 
   end
   if(inside(196,334,74,21))begin
    text_valid=1;text_x=201;text_y=338;text_width=4;begin text_id=7'd31;message={32'd0,224'd0};end 
   end
  if(Stop && inside(592,300,96,32))begin
   text_valid=1;text_x=592;text_y=300;text_scale=2;text_width=5;begin text_id=7'd32;message={40'd0,216'd0};end 
  end
  if((!campaign) && inside(168,44,64,32))begin
   text_valid=1;compact_text=1;text_x=168;text_y=44;text_width=4;text_pitch=16;text_height=28;begin text_id=(duo?7'd33:7'd34);message=(duo?{24'd0,232'd0}:{32'd0,224'd0});end text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(170,88,56,18))begin
   text_valid=1;compact_text=1;text_x=170;text_y=88;text_width=7;text_pitch=8;text_height=14;begin text_id=7'd35;message={56'd0,200'd0};end text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(478,59,84,20))begin
   text_valid=1;compact_text=1;text_x=478;text_y=61;text_width=5;text_pitch=12;text_height=14;begin text_id=7'd36;message={40'd0,216'd0};end text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(569,57,73,23))begin
   text_valid=1;compact_text=1;text_x=569;text_y=61;text_width=3;text_pitch=12;text_height=14;begin text_id=7'd37;message={8'd49+{5'd0,speed},8'd0,8'd0,232'd0};end text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(1000,57,48,23))begin
   text_valid=1;compact_text=0;text_x=1000;text_y=61;text_width=4;text_pitch=12;text_height=14;begin text_id=7'd14;message={percent4(charge_percent),224'd0};end text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(478,94,70,18))begin
   text_valid=1;compact_text=1;text_x=478;text_y=97;text_width=5;text_pitch=12;text_height=14;begin text_id=7'd38;message={40'd0,216'd0};end text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(566,92,144,24))begin
   text_valid=1;compact_text=1;text_x=566;text_y=97;text_width=6;text_pitch=12;text_height=14;begin text_id=7'd39;message={bcd6(score_bcd),208'd0};end text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(752,94,70,18))begin
   text_valid=1;compact_text=1;text_x=752;text_y=97;text_width=5;text_pitch=12;text_height=14;begin text_id=7'd40;message={40'd0,216'd0};end text_ink=24'hffc15b;
  end
  if((!campaign) && inside(848,92,144,24))begin
   text_valid=1;compact_text=1;text_x=848;text_y=97;text_width=6;text_pitch=12;text_height=14;begin text_id=7'd39;message={bcd6(lines_bcd),208'd0};end text_ink=24'hffc15b;
  end
  if((!campaign) && inside(998,390,84,14))begin
   text_valid=1;compact_text=1;text_x=999;text_y=390;text_width=7;text_pitch=12;text_height=14;begin text_id=7'd19;message={56'd0,200'd0};end text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(1006,438,72,21))begin
   text_valid=1;compact_text=1;text_x=1006;text_y=438;text_width=4;text_pitch=18;text_height=21;begin text_id=7'd14;message={percent4(reserve_percent),224'd0};end text_ink=reserve_alarm==2?24'hd8442e:reserve_alarm==1?24'hffc15b:24'h7fe3ec;
  end
  if((!campaign) && inside(1010,500,60,14))begin
   text_valid=1;compact_text=1;text_x=1011;text_y=500;text_width=5;text_pitch=12;text_height=14;begin text_id=7'd41;message={40'd0,216'd0};end text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(992,544,96,14))begin
   text_valid=1;compact_text=1;text_x=reserve_alarm==2?993:reserve_alarm==1?1023:1005;text_y=544;text_width=8;text_pitch=12;text_height=14;begin text_id=(reserve_alarm==2?7'd42:(reserve_alarm==1?7'd43:7'd44));message=(reserve_alarm==2?{64'd0,192'd0}:(reserve_alarm==1?{24'd0,232'd0}:{48'd0,208'd0}));end text_ink=reserve_alarm==2?24'hd8442e:reserve_alarm==1?24'hffc15b:24'h7fe3ec;
  end
  // Graphical landing assistance. No heading, status words or quota numerals.
  if(!duo)begin
   if(inside(1026,157,28,18) &&
      (((x==1026 || x==1053) && (y<162 || y>169)) ||
       ((y==157 || y==174) && (x<1032 || x>1047))))begin color_owned=1;color=hint_ink;end 
   if(inside(1037,163,7,7) && HINT_DOT[hint_dot_address])begin color_owned=1;color=hint_ink;end 
   // Solid falling piece, dashed vertical path, and matching hollow landing.
   if(inside(hint_left,202,hint_cols*12,24))begin
    hc=hint_local_x/6'd12;hr=hint_top_y/5'd12;hx=hint_local_x%6'd12;hy=hint_top_y%5'd12;
    if(hint_mino(hint_type,hc,hr) && hx<10 && hy<10)begin
     begin color_owned=1;color=hint_ink;end 
     if(hx==0 || hy==0)begin color_owned=1;color=hint_active?24'hcbfbff:24'h7596a8;end 
    end
   end
   if(x>=1038 && x<1040 && y>=232 && y<246 && y%6<3)begin color_owned=1;color=hint_ink;end 
   if(y>=243 && y<=250 && x>=1039-(250-y)/2 && x<=1039+(250-y)/2)begin color_owned=1;color=hint_ink;end 
   if(inside(hint_left,258,hint_cols*12,24))begin
    hc=hint_local_x/6'd12;hr=hint_bottom_y/5'd12;hx=hint_local_x%6'd12;hy=hint_bottom_y%5'd12;
    if(hint_mino(hint_type,hc,hr) && hx<10 && hy<10 &&
       (hx==0 || hx==9 || hy==0 || hy==9))begin color_owned=1;color=hint_active?24'hffe39c:24'h3c5364;end 
   end
   if(inside(1002,285,76,2))begin color_owned=1;color=hint_active?24'h7fe3ec:24'h30495d;end 
   if((x==1002 || x==1077) && y>=280 && y<287)begin color_owned=1;color=hint_ink;end 
   // Available, consumed and unopened campaign capacity is read from the budget.
   if(campaign)begin
    for(i=0;i<4;i=i+1)begin
     if(inside(1006+i*18,292,10,6))begin
      if(i<hint_quota)begin color_owned=1;color=24'h35e0f5;end 
      else if(x==1006+i*18 || x==1015+i*18 || y==292 || y==297)
       begin color_owned=1;color=i<hint_capacity?(hint_active?24'hffe39c:24'h607d91):24'h243949;end 
      else begin color_owned=1;color=24'h06121d;end 
     end
    end
    if(hint_active && inside(995,301,90,2))
     begin color_owned=1;color=((x-995)<<3)<hint_life?24'h7fe3ec:24'h203747;end 
   end else begin
    // Linked loops are the unlimited-use symbol; no FREE text or fake quota.
    if(inside(1026,290,28,10) && HINT_INFINITY[hint_infinity_address])
     begin color_owned=1;color=hint_ink;end 
   end
  end
  end
  if((choose) && inside(212,88,310,42))begin
   text_valid=1;compact_text=1;text_x=212;text_y=88;text_width=7;text_pitch=30;text_height=35;begin text_id=7'd45;message={56'd0,200'd0};end text_ink=24'he6f0f7;
  end
  if((choose) && inside(748,100,450,24))begin
   text_valid=1;compact_text=1;text_x=748;text_y=100;text_width=11;text_pitch=18;text_height=21;begin text_id=(ship_select?7'd46:7'd47);message=(ship_select?{88'd0,168'd0}:{88'd0,168'd0});end text_ink=24'h7fe3ec;
  end
  if((choose) && inside(232,188,420,30))begin
   text_valid=1;compact_text=1;text_x=232;text_y=188;text_width=11;text_pitch=20;text_height=28;begin text_id=(ship_select?7'd17:7'd48);message=(ship_select?{40'd0,decimal2(level_id+1),200'd0}:{88'd0,168'd0});end text_ink=24'h7fe3ec;
  end
  if((choose && !ship_select) && inside(232,478,420,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=478;text_width=19;text_pitch=12;text_height=14;begin text_id=7'd49;message={152'd0,104'd0};end text_ink=24'he6f0f7;
  end
  if((choose && !ship_select) && inside(232,510,430,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=510;text_width=20;text_pitch=12;text_height=14;begin text_id=7'd50;message={160'd0,96'd0};end text_ink=24'he6f0f7;
  end
  if((choose && ship_select) && inside(232,478,300,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=478;text_width=13;text_pitch=12;text_height=14;begin text_id=7'd51;message={104'd0,152'd0};end text_ink=24'h7fe3ec;
  end
  if((choose && ship_select) && inside(610,478,60,18))begin
   text_valid=1;compact_text=1;text_x=610;text_y=478;text_width=2;text_pitch=16;text_height=14;begin text_id=7'd52;message={decimal2(mode_target(duo,level_id)),240'd0};end text_ink=24'h7fe3ec;
  end
  if((choose && ship_select) && inside(232,510,300,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=510;text_width=6;text_pitch=12;text_height=14;begin text_id=7'd16;message={48'd0,208'd0};end text_ink=24'hffc15b;
  end
  if((choose && ship_select) && inside(610,510,60,18))begin
   text_valid=1;compact_text=1;text_x=610;text_y=510;text_width=2;text_pitch=16;text_height=14;begin text_id=7'd52;message={decimal2(mode_total(duo,level_id)),240'd0};end text_ink=24'hffc15b;
  end
  if((choose && ship_select) && inside(232,542,300,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=542;text_width=11;text_pitch=12;text_height=14;begin text_id=7'd53;message={88'd0,168'd0};end text_ink=24'he6f0f7;
  end
  if((choose && ship_select) && inside(610,542,60,18))begin
   text_valid=1;compact_text=1;text_x=610;text_y=542;text_width=3;text_pitch=16;text_height=14;begin text_id=7'd37;message={8'd49+mode_initial(duo,level_id),8'd0,8'd0,232'd0};end text_ink=24'he6f0f7;
  end
  if((choose) && inside(230,584,432,18))begin
   text_valid=1;compact_text=1;text_x=230;text_y=584;text_width=25;text_pitch=12;text_height=14;begin text_id=(ship_select?(duo?7'd54:7'd55):7'd56);message=(ship_select?(duo?{96'd0,160'd0}:{104'd0,152'd0}):{200'd0,56'd0});end text_ink=24'h7fe3ec;
  end
  if((choose) && inside(768,584,432,18))begin
   text_valid=1;compact_text=1;text_x=768;text_y=584;text_width=14;text_pitch=14;text_height=14;begin text_id=7'd57;message={112'd0,144'd0};end text_ink=24'he6f0f7;
  end
  if(choose && inside(768,172,432,374))begin
   menu_row=menu_dy/7'd98;menu_y=172+menu_row*98;menu_ship_index=menu_row[1:0];
   if(menu_row<4 && y>=menu_y+18 && y<menu_y+44)begin
    text_valid=1;compact_text=1;text_x=780;text_y=menu_y+18;text_width=13;text_pitch=16;text_height=21;
    text_ink=(ship_select?{1'b0,menu_ship_index}:menu_row)==menu_selection?24'h7fe3ec:24'he6f0f7;
    if(ship_select)begin text_width=7;begin text_id=7'd17;message={40'd0,decimal2(menu_ship_index+1),200'd0};end end
    else case(menu_row)
     0:begin text_width=12;begin text_id=7'd58;message={96'd0,160'd0};end end
     1:begin text_width=11;begin text_id=7'd59;message={88'd0,168'd0};end end
     2:begin text_width=13;begin text_id=7'd55;message={104'd0,152'd0};end end
     default:begin text_width=12;begin text_id=7'd54;message={96'd0,160'd0};end end
    endcase
   end
   if(menu_row<4 && y>=menu_y+50 && y<menu_y+68)begin
    text_valid=1;compact_text=1;text_x=780;text_y=menu_y+50;text_width=20;text_pitch=12;text_height=14;text_ink=24'h8fabbf;
    if(ship_select)begin text_id=7'd60;message={56'd0,decimal2(mode_target(duo,menu_ship_index)),72'd0,decimal2(mode_total(duo,menu_ship_index)),96'd0};end 
    else if(menu_row<2)begin text_id=7'd61;message={160'd0,96'd0};end 
    else begin text_id=7'd62;message={136'd0,120'd0};end 
   end
  end
  if(choose && inside(565,649,240,28))begin
   text_valid=1;compact_text=1;text_x=565;text_y=649;text_width=12;text_pitch=18;text_height=21;
   begin text_id=7'd63;message={96'd0,160'd0};end text_ink=24'h8ecad7;
  end
   if(!choose && comms_visible && inside(dialog_x,160,360,104))begin
    text_valid=0;begin color_owned=1;color=24'h091722;end 
    if(x<dialog_x+2 || x>=dialog_x+358 || y<162 || y>=262)begin color_owned=1;color=24'h607d91;end 
    if(x>=dialog_x+5 && x<dialog_x+7 && y>=169 && y<254)begin color_owned=1;color=24'h35e0f5;end 
    if(y>=172 && y<186)begin
     text_valid=1;text_x=dialog_x+18;text_y=172;text_width=5;text_pitch=12;text_height=14;
     begin text_id=7'd64;message={40'd0,216'd0};end text_ink=24'h7fe3ec;
    end
    if(y>=202 && y<216 || y>=230 && y<244)begin
     text_valid=1;text_x=dialog_x+18;text_y=y<230?202:230;text_width=26;text_pitch=12;text_height=14;
     begin text_id=ui_comms_template(comms_id,y>=230);message=256'd0;end text_ink=24'he8eef2;
    end
   end

  if(pause_panel)begin
   begin color_owned=1;color=24'h091722;end 
   if(x<563 || x>=717 || y<279 || y>=337)begin color_owned=1;color=24'h607d91;end 
  end
  if(!choose && !Finalize && clear_credit!=0 && clear_credit_age!=0 && inside(duo?730:706,520,60,48))begin
   text_valid=1;text_x=duo?730:706;text_y=credit_y;text_width=2;text_pitch=18;text_height=21;
   if(clear_credit<10)begin text_id=7'd65;message={8'd0,8'd48+{3'd0,clear_credit},240'd0};end 
   else begin text_width=3;begin text_id=7'd66;message={8'd0,decimal2(clear_credit),232'd0};end end text_ink=24'h7fe3ec;
  end
  if(!choose && !campaign && recharge_age!=0 && inside(720,520,96,48))begin
   text_valid=1;text_x=720;text_y=520;text_width=4;text_pitch=18;text_height=21;
   if(recharge_no_gain)begin text_width=3;begin text_id=7'd67;message={24'd0,232'd0};end text_ink=24'hffc15b;end
   else begin
    begin text_id=7'd68;message={8'd0,digit8((recharge_units/100)%10),decimal2(recharge_units%100),224'd0};end text_ink=24'h7fe3ec;
    if(recharge_capped && y>=546)begin text_x=738;text_y=546;text_pitch=12;text_height=14;text_width=3;begin text_id=7'd67;message={24'd0,232'd0};end text_ink=24'hffc15b;end
   end
  end
  if(terminal_panel)begin
   begin color_owned=1;color=24'h091722;end text_valid=0;
   if(x<419 || x>=861 || y<235 || y>=589)begin color_owned=1;color=24'h607d91;end 
   if(inside(440,256,400,21))begin
    text_valid=1;text_x=success?500:550;text_y=256;text_width=success?14:9;text_pitch=20;text_height=21;
    begin text_id=(success?7'd69:7'd70);message=(success?{112'd0,144'd0}:{72'd0,184'd0});end text_ink=success?24'h7fe3ec:24'hd8442e;
   end
   if(inside(440,290,400,14))begin
    text_valid=1;text_x=campaign?598:duo?574:568;text_y=290;text_width=campaign?7:12;
    begin text_id=(campaign?7'd17:(duo?7'd59:7'd58));message=(campaign?{40'd0,decimal2(level_id+1),200'd0}:(duo?{88'd0,168'd0}:{96'd0,160'd0}));end text_ink=24'hb3c8d8;
   end
   if(y>=330 && y<502 && x>=456 && x<824)begin
    menu_row=terminal_dy/6'd40;text_y=330+menu_row*40;text_x=456;text_pitch=12;text_height=14;text_width=9;
    if(y<text_y+14 && menu_row<(campaign && success?4:3))begin
     text_valid=1;text_ink=24'he8eef2;
     if(x<650)begin
      case(menu_row)
       0:begin text_id=(campaign?7'd15:7'd38);message=(campaign?{48'd0,208'd0}:{40'd0,216'd0});end 
       1:begin text_id=(campaign?7'd71:7'd40);message=(campaign?{32'd0,224'd0}:{40'd0,216'd0});end 
       2:begin text_id=(campaign?(success?7'd72:7'd16):7'd71);message=(campaign?(success?{32'd0,224'd0}:{48'd0,208'd0}):{32'd0,224'd0});end 
       default:begin text_id=7'd73;message={72'd0,184'd0};end 
      endcase
     end else begin
      case(menu_row)
       0:begin
        text_x=campaign?752:740;text_width=campaign?5:6;begin text_id=(campaign?7'd11:7'd39);message=(campaign?{decimal2(credits),8'd0,decimal2(target),216'd0}:{bcd6(score_bcd),208'd0});end 
        if(campaign && credits>=100)begin text_x=704;text_width=9;begin text_id=7'd12;message={bcd6(lines_bcd),8'd0,decimal2(target),184'd0};end end
       end
       1:begin
        text_x=campaign?752:740;text_width=campaign?5:6;
        begin text_id=(campaign?7'd74:7'd39);message=(campaign?{8'd48+{4'd0,time_bcd[15:12]},8'd48+{4'd0,time_bcd[11:8]},8'd0,8'd48+{4'd0,time_bcd[7:4]},8'd48+{4'd0,time_bcd[3:0]},216'd0}:{bcd6(lines_bcd),208'd0});end 
       end
       2:begin
        text_x=campaign?(success?800:728):752;text_width=campaign?(success?1:7):5;
        begin text_id=(campaign?(success?7'd75:7'd13):7'd74);message=(campaign?(success?{(rank==0?8'd83:rank==1?8'd65:rank==2?8'd66:8'd67),248'd0}:{decimal2(debris_left),40'd0,200'd0}):{8'd48+{4'd0,time_bcd[15:12]},8'd48+{4'd0,time_bcd[11:8]},8'd0,8'd48+{4'd0,time_bcd[7:4]},8'd48+{4'd0,time_bcd[3:0]},216'd0});end text_ink=24'hffc15b;
       end
       default:begin text_x=776;text_width=3;begin text_id=(campaign?7'd76:7'd37);message=(campaign?{digit8(average_tenths/10),8'd0,digit8(average_tenths%10),232'd0}:{8'd49+{5'd0,speed},8'd0,8'd0,232'd0});end end
      endcase
     end
    end
   end
   for(i=0;i<3;i=i+1)begin
    button_left=(campaign && success && level_id!=3?440:507)+i*134;
    if(i<(campaign && success && level_id!=3?3:2) && inside(button_left,532,126,36))begin
     begin color_owned=1;color=i==result_option?24'h35e0f5:24'h142534;end 
     if(x==button_left || x==button_left+125 || y==532 || y==567)begin color_owned=1;color=24'h607d91;end 
     text_valid=1;text_x=button_left+21;text_y=543;text_width=7;text_pitch=12;text_height=14;
     text_ink=i==result_option?24'h05121c:24'he8eef2;
     case(i)
      0:begin text_id=7'd77;message={40'd0,216'd0};end 1:begin text_id=(campaign?(success && level_id!=3?7'd30:7'd78):7'd79);message=(campaign?(success && level_id!=3?{32'd0,224'd0}:{48'd0,208'd0}):{32'd0,224'd0});end default:begin text_id=7'd78;message={48'd0,208'd0};end 
     endcase
    end
   end
  end
  if(terminal_panel && campaign && !success)begin
   if(credits>=target && inside(456,337,356,1))begin begin color_owned=1;color=24'h7fe3ec;end force_paint=1;end
   if(debris_left==0 && inside(456,417,356,1))begin begin color_owned=1;color=24'hffc15b;end force_paint=1;end
  end
  if(!choose && campaign && credits>=target && inside(476,68,170,1))begin begin color_owned=1;color=24'h7fe3ec;end force_paint=1;end
  if(!choose && campaign && debris_left==0 && inside(476,103,174,1))begin begin color_owned=1;color=24'hffc15b;end force_paint=1;end
  if(x>=1280 || y>=720)begin begin color_owned=1;color=0;end force_paint=1;end
 end
 // Same four clocks as before: the atlas has three reads; the glyph has
 // two. Register their final priority mux on clock four, then story_ui adds one.
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin
   p0<=0;p1<=0;p2<=0;p3<=0;owned_pipe<=0;skin0<=0;skin1<=0;skin2<=0;ink0<=0;ink1<=0;ink2<=0;force_pipe<=0;font_lit_q<=0;
  end else begin
   p0<=color;p1<=p0;p2<=p1;skin0<=skin_pixel;skin1<=skin0;skin2<=skin1;owned_pipe<={owned_pipe[1:0],color_owned};
   ink0<=text_ink;ink1<=ink0;ink2<=ink1;
   force_pipe<={force_pipe[1:0],force_paint};font_lit_q<=shared_font_lit;
   p3<=force_pipe[2]?p2:shared_font_lit?ink2:(basic_hit && (!basic_material_only || mission_hit))?basic_rgb:mission_hit?mission_rgb:owned_pipe[2]?p2:skin2;
  end
 end
 assign rgb=p3;
endmodule
