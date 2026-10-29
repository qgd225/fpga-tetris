// Reference-driven visual layer. Reads game state only; no gameplay feedback.
module reference_ui_renderer(
 input clk,reset_n,input [10:0] x,y,
 input duo,campaign,choose,ship_select,Idle,input [3:0] choose_cnt,
 input [7:0] reserve_fill,input [1:0] reserve_alarm,input [23:0] score_bcd,
 input hint_active,hint_hit,input [2:0] hint_quota,hint_capacity,hint_type,input [9:0] hint_life,
 input [1:0] level_id,phase,input [3:0] locked,input [6:0] debris_left,
 input [2:0] speed,input [23:0] lines_bcd,input [15:0] time_bcd,
 input [7:0] animation,input [4:0] charge_left,
 input Stop,success,hold_ready,hold_visible,hold_reserved,hold_actor2,
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
 `include "game_mode_params.vh"
 `include "story_palette.vh"
 (* rom_style="block" *) reg [23:0] skin[0:4607999];
 (* rom_style="block" *) reg [23:0] material[0:REF_MATERIAL_WORDS-1];
 reg [7:0] font[0:2047];
 reg [7:0] digits[0:3119];
 initial begin
  $readmemh("reference_ui_skin.mem",skin);
  $readmemh("reference_ui_material.mem",material);
  $readmemh("story_font.mem",font);
  $readmemh("reference_ui_digits.mem",digits);
 end
 wire [2:0] skin_bank=choose?3'd4:duo?(campaign?3'd0:3'd3):(campaign?3'd1:3'd2);
 wire [22:0] address=skin_bank*921600+y*1280+x;
 wire [23:0] skin_pixel=(x<1280 && y<720)?skin[address]:24'd0;
 function inside;
  input integer bx,by,w,h;
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
  input integer n;
  reg [7:0] a,b;
  begin a=48+(n/10)%10;b=48+n%10;decimal2={a,b};end
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
  input integer n;
  begin percent4=n>=100?"100%":{8'd32,decimal2(n),8'd37};end
 endfunction
 function glyph;
  input [7:0] ch;input integer gx,gy;
  reg [7:0] row;
  begin
   if(ch==8'd37)begin
    case(gy)
     3:row=8'h62;4:row=8'h64;5:row=8'h08;6:row=8'h10;
     7:row=8'h20;8:row=8'h4c;9:row=8'h8c;default:row=0;
    endcase
   end else row=font[{ref_font_char(ch),4'd0}+gy];
   glyph=gx>=0 && gx<8 && gy>=0 && gy<16 && row[7-gx];
  end
 endfunction

 // Axis-aligned cell shader: actual 26x32 pixels with 4px corner radii.
 function [23:0] core_cell_face;
  input integer px,py;
  integer cx,cy,rr,gg,bb;
  begin
   cx=px<4?4:(px>21?21:px);
   cy=py<4?4:(py>27?27:py);
   rr=111-93*py/31;gg=245-46*py/31;bb=255-23*py/31;
   core_cell_face={rr[7:0],gg[7:0],bb[7:0]};
   if((px-cx)*(px-cx)+(py-cy)*(py-cy)>16)core_cell_face=24'h040c13;
   else if(px==0 || px==25 || py==0 || py==31)core_cell_face=24'h0b839e;
   else if((py==1 && px>=5 && px<=20) || (px==1 && py>=5 && py<=26))
    core_cell_face=24'hbbfbff;
  end
 endfunction
 // Dedicated 5x7 phase alphabet: no column loss in the narrow legend.
 function phase_glyph;
  input [7:0] ch;input integer px,py;
  reg [34:0] bitmap;
  begin
   case(ch)
    8'd65:bitmap=35'b01110100011000111111100011000110001;
    8'd66:bitmap=35'b11110100011000111110100011000111110;
    8'd67:bitmap=35'b01111100001000010000100001000001111;
    8'd68:bitmap=35'b11110100011000110001100011000111110;
    8'd69:bitmap=35'b11111100001000011110100001000011111;
    8'd71:bitmap=35'b01111100001000010111100011000101111;
    8'd72:bitmap=35'b10001100011000111111100011000110001;
    8'd73:bitmap=35'b01110001000010000100001000010001110;
    8'd76:bitmap=35'b10000100001000010000100001000011111;
    8'd78:bitmap=35'b10001110011100110101100111001110001;
    8'd79:bitmap=35'b01110100011000110001100011000101110;
    8'd82:bitmap=35'b11110100011000111110101001001010001;
    8'd83:bitmap=35'b01111100001000001110000010000111110;
    8'd84:bitmap=35'b11111001000010000100001000010000100;
    8'd85:bitmap=35'b10001100011000110001100011000101110;
    8'd90:bitmap=35'b11111000010001000100010001000011111;
    8'd80:bitmap=35'b11110100011000111110100001000010000;
    8'd48:bitmap=35'b01110100011001110101110011000101110;
    8'd49:bitmap=35'b00100011000010000100001000010001110;
    8'd50:bitmap=35'b01110100010000100010001000100011111;
    8'd51:bitmap=35'b11110000010000101110000010000111110;
    8'd52:bitmap=35'b00010001100101010010111110001000010;
    8'd53:bitmap=35'b11111100001000011110000010000111110;
    8'd54:bitmap=35'b01110100001000011110100011000101110;
    8'd55:bitmap=35'b11111000010001000100010000100001000;
    8'd56:bitmap=35'b01110100011000101110100011000101110;
    8'd57:bitmap=35'b01110100011000101111000010000101110;
    8'd47:bitmap=35'b00001000010001000100010001000010000;
    8'd70:bitmap=35'b11111100001000011110100001000010000;
    8'd74:bitmap=35'b00111000100001000010000101001001100;
    8'd75:bitmap=35'b10001100101010011000101001001010001;
    8'd77:bitmap=35'b10001110111010110101100011000110001;
    8'd81:bitmap=35'b01110100011000110001101011001001101;
    8'd86:bitmap=35'b10001100011000110001100010101000100;
    8'd87:bitmap=35'b10001100011000110101101011010101010;
    8'd88:bitmap=35'b10001100010101000100010101000110001;
    8'd89:bitmap=35'b10001100010101000100001000010000100;
    8'd45:bitmap=35'b00000000000000011111000000000000000;
    8'd58:bitmap=35'b00000001000010000000001000010000000;
    8'd43:bitmap=35'b00000001000010011111001000010000000;
    8'd37:bitmap=35'b11001110100010000100001000101110011;
    default:bitmap=35'd0;
   endcase
   phase_glyph=0;
   if(px>=0 && px<5 && py>=0 && py<7)phase_glyph=bitmap[34-py*5-px];
  end
 endfunction

 integer credits,target,total,charge_percent,debris_percent,slot,offset,i;
 integer menu_row,menu_y,menu_selection,reserve_percent,lit_top;
 integer mx,my,kind,mat_address,current_phase,phase_row;
 integer text_x,text_y,text_scale,text_width,text_pitch,text_height,column,gx,gy,digit_index,digit_x,digit_y;
 reg text_valid,compact_text;reg [255:0] message;reg [7:0] character;
 reg [23:0] color,text_ink;
 reg [23:0] p0,p1,p2,p3;
 reg ghosted,draw_piece,hinted;
 always @(*)begin
  credits=lines_bcd[3:0]+lines_bcd[7:4]*10+lines_bcd[11:8]*100+
   lines_bcd[15:12]*1000+lines_bcd[19:16]*10000+lines_bcd[23:20]*100000;
  target=mode_target(duo,level_id);total=mode_total(duo,level_id);
  charge_percent=campaign?(credits>=target?100:credits*100/target):(speed+1)*100/8;
  debris_percent=debris_left*100/total;
  color=skin_pixel;mx=0;my=0;kind=0;mat_address=0;draw_piece=0;ghosted=0;
  current_phase=locked<3?0:locked<5?1:locked<7?2:3;
  phase_row=0;slot=0;offset=0;i=0;hinted=0;
  menu_row=0;menu_y=172;menu_selection=ship_select?level_id:choose_cnt;
  reserve_percent=reserve_fill>=174?100:reserve_fill*100/174;
  lit_top=campaign?REF_CORE_Y+(8-locked)*REF_CORE_PITCH:REF_CORE_Y+REF_CORE_H-reserve_fill*REF_CORE_H/174;
  if(!choose)begin

  if(in_field)begin
   color=(local_x==23 || local_y==23)?24'h142b38:24'h091722;
   if(cell_visible)begin
    mx=local_x;my=local_y;
    if(piece1)begin draw_piece=1;kind=type1;end
    else if(piece2 && duo)begin draw_piece=1;kind=type2;end
    else if(occupied)begin draw_piece=1;kind=debris_cell?7:cell_type;end
    else if(!duo && hint_active && hint_hit)begin hinted=1;kind=hint_type;mx=local_x;my=local_y;end
    else if(ghost1 || (duo && ghost2))begin ghosted=1;kind=ghost1?type1:type2;end
   end
  end
  if(next1 || (duo && next2))begin draw_piece=1;kind=next2?next_type2:next_type1;mx=next_x;my=next_y;end
  if(hold && hold_visible)begin draw_piece=1;kind=hold_type;mx=hold_x;my=hold_y;end
  if(draw_piece && mx<22 && my<22)begin
   color=material[kind*484+my*22+mx];
   if(kind<7 && (mx==0 || mx==21) && (my==0 || my==21))
    color=in_field?24'h091722:24'h06121d;
  end
  if(ghosted && (((my==1 || my==20) && mx%7<4) || ((mx==1 || mx==20) && my%7<4)))
   color=story_palette(8+kind);
  if(hinted && (mx==0 || mx==21 || my==0 || my==21))color=24'hffe39c;
  if(corner(bounds1))color=24'h59e7ef;
  if(duo && corner(bounds2))color=24'he45bbf;

  // Tracks are segmented material slots; status changes do not change credit.
  if(inside(REF_CHARGE_TRACK_X,REF_CHARGE_TRACK_Y,REF_CHARGE_TRACK_W,REF_CHARGE_TRACK_H))begin
   slot=(x-REF_CHARGE_TRACK_X)*10/REF_CHARGE_TRACK_W;
   offset=(x-REF_CHARGE_TRACK_X)*10%REF_CHARGE_TRACK_W;
   mat_address=6000+((x-REF_CHARGE_TRACK_X)*100<REF_CHARGE_TRACK_W*charge_percent?0:224)+
    ((y-REF_CHARGE_TRACK_Y)*16/REF_CHARGE_TRACK_H)*14+offset*14/REF_CHARGE_TRACK_W;
   color=offset<REF_CHARGE_TRACK_W-20?material[mat_address]:24'h081824;
  end
  if(campaign && inside(REF_DEBRIS_TRACK_X,REF_DEBRIS_TRACK_Y,REF_DEBRIS_TRACK_W,REF_DEBRIS_TRACK_H))begin
   mat_address=6448+((x-REF_DEBRIS_TRACK_X)*100<REF_DEBRIS_TRACK_W*debris_percent?0:224)+
    ((y-REF_DEBRIS_TRACK_Y)*16/REF_DEBRIS_TRACK_H)*14+(x-REF_DEBRIS_TRACK_X)%14;
   color=material[mat_address];
  end
  // Local spill follows the real lit-cell height, and stays inside the mast.
  if((campaign?(locked>0 && locked<=8):reserve_fill>0) && y>=lit_top &&
     y<REF_CORE_Y+REF_CORE_H)begin
   if(inside(1151,REF_CORE_Y,6,REF_CORE_H) || inside(1183,REF_CORE_Y,5,REF_CORE_H))begin
    color={color[23:16]>>1,
     (color[15:8]>>1)+8'd63,(color[7:0]>>1)+8'd76};
   end
  end
  // Eight equal 36px slots. Each 26x32 face is inset 3px from the chamber wall.
  if(inside(REF_CORE_GLASS_X,REF_CORE_Y,REF_CORE_GLASS_W,REF_CORE_H))begin
   slot=(y-REF_CORE_Y)/REF_CORE_PITCH;my=(y-REF_CORE_Y)%REF_CORE_PITCH;mx=x-REF_CORE_GLASS_X;
   color=24'h040c13;
   if((7-slot)<locked && my>=2 && my<34)begin
    color=core_cell_face(mx,my-2);
    if(charge_left!=0 && animation[4] && my==3 && mx>=5 && mx<=20)
     color=24'hd5ffff;
   end else if(my==35 && mx>=2 && mx<24)color=24'h122937;
  end
  if(!campaign && inside(REF_CORE_GLASS_X,REF_CORE_Y,REF_CORE_GLASS_W,REF_CORE_H))begin
   mx=x-REF_CORE_GLASS_X;my=y-REF_CORE_Y;
   color=24'h040c13;
   if(y>=lit_top)begin
    color=reserve_alarm==2?24'hd8442e:reserve_alarm==1?24'hffc23a:24'h26d7ec;
    if(mx==1)color=reserve_alarm==0?24'hb5fbff:24'hffe5a3;
    if(y==lit_top || y==lit_top+1)color=24'hd5ffff;
   end
   if(my%36==35 && (mx<4 || mx>21))color=24'h607d91;
  end
  if(campaign && debris_left>mode_half(duo,level_id) && inside(1134,236,40,5))color=24'hd8442e;
  // Stacked legend chosen by the user: identical 14px rings on a 2px spine.
  if(campaign && inside(1199,272,78,222))begin
   phase_row=y<278?0:(y-278)/54;slot=3-phase_row;
   mx=2*x+1-2476;my=2*y+1-2*(294+phase_row*54);
   if(x>=1237 && x<1239 && y>=294 && y<=456)
    color=24'h607d91;
   // The full continuous spine is behind opaque name strips for legibility.
   if(y>=306+phase_row*54 && y<320+phase_row*54)color=24'h0e1c28;
   if(mx*mx+my*my<=196 && mx*mx+my*my>=100)
    color=slot==current_phase?24'hf5a21f:(slot<current_phase?24'h35e0f5:24'hb3c8d8);
   if(mx*mx+my*my<100)
    color=slot==current_phase?24'hffc96b:(slot<current_phase?24'h35e0f5:24'h0e1c28);
   offset=294+(3-current_phase)*54;
   if(y>=offset-20 && y<=offset-14 &&
      x>=1238-(offset-14-y)/2 && x<=1238+(offset-14-y)/2)
    color=24'hf5a21f;
  end
  for(i=0;i<3;i=i+1)begin
   if(inside(212+i*10,490,5,5))color=hold_conditions[i]?24'h6b9eaa:24'h2e4353;
  end
  if(hold_reserved && inside(282,405,6,12) && x-282<(y<411?y-405:416-y))color=hold_actor2?24'he45bbf:24'h7fe3ec;
  if((hold_reject_flash || hold_expire_flash || hold_reserved) && inside(166,366,116,116) &&
    (x<168 || x>=280 || y<368 || y>=480))
   color=hold_expire_flash?24'he8eef2:hold_reject_flash?24'hd8442e:hold_actor2?24'he45bbf:24'h7fe3ec;
  if(in_field && feedback_clear_row && local_y>=9 && local_y<12)color=feedback_clear_age<3?24'hffffff:24'hffc15b;
  if(in_field && feedback_clear && y>=570 && (x*3+y*7+animation)%173<3)color=24'hffc15b;

  end
  if(choose && inside(716,172,492,374))begin
   menu_row=(y-172)/98;menu_y=172+menu_row*98;
   if(y<menu_y+80 && menu_row<4 && menu_row==menu_selection)begin
    if(x<720 || x>=1204 || y<menu_y+3 || y>=menu_y+77)color=24'h35e0f5;
    else if(x>=768 && x<1200 && y>=menu_y+8 && y<menu_y+72)color=24'h0b2b39;
   end
  end
  text_valid=0;compact_text=0;message=0;text_x=0;text_y=0;text_scale=1;text_width=0;text_pitch=10;text_height=20;text_ink=24'he8eef2;
  if(!choose)begin
  if(campaign && inside(REF_CHARGE_VALUE_X,REF_CHARGE_VALUE_Y,REF_CHARGE_VALUE_W,REF_CHARGE_VALUE_H))begin
   text_valid=1;text_x=REF_CHARGE_VALUE_X;text_y=REF_CHARGE_VALUE_Y;text_width=5;text_pitch=12;
   if(credits<100)message={decimal2(credits),8'd47,decimal2(target),216'd0};
   else begin text_width=9;text_pitch=8;message={bcd6(lines_bcd),8'd47,decimal2(target),184'd0};end
   text_ink=24'h7fe3ec;
  end
  if(campaign && inside(REF_DEBRIS_VALUE_X,REF_DEBRIS_VALUE_Y,REF_DEBRIS_VALUE_W,REF_DEBRIS_VALUE_H))begin
   text_valid=1;text_x=REF_DEBRIS_VALUE_X;text_y=REF_DEBRIS_VALUE_Y+2;text_width=7;
   message={decimal2(debris_left)," LEFT",200'd0};text_ink=24'hffc15b;
  end
  if(campaign && inside(REF_CHARGE_PERCENT_X,REF_CHARGE_PERCENT_Y,REF_CHARGE_PERCENT_W,REF_CHARGE_PERCENT_H))begin
   text_valid=1;text_x=REF_CHARGE_PERCENT_X;text_y=REF_CHARGE_PERCENT_Y+1;text_width=4;
   message={percent4(charge_percent),224'd0};text_ink=24'h7fe3ec;text_pitch=9;
  end
  if(campaign && inside(REF_DEBRIS_PERCENT_X,REF_DEBRIS_PERCENT_Y,REF_DEBRIS_PERCENT_W,REF_DEBRIS_PERCENT_H))begin
   text_valid=1;text_x=REF_DEBRIS_PERCENT_X;text_y=REF_DEBRIS_PERCENT_Y+1;text_width=4;
   message={percent4(debris_percent),224'd0};text_ink=24'hffc15b;text_pitch=9;
  end
  if(campaign && inside(REF_SHIP_NUMBER_X,REF_SHIP_NUMBER_Y,REF_SHIP_NUMBER_W,REF_SHIP_NUMBER_H))begin
   text_valid=1;text_x=REF_SHIP_NUMBER_X;text_y=REF_SHIP_NUMBER_Y;text_scale=2;text_width=2;text_pitch=17;text_height=28;
   message={decimal2(level_id+1),240'd0};
  end
  if(inside(986,324,112,18))begin
   text_valid=1;compact_text=1;text_x=1007;text_y=326;text_width=7;text_pitch=10;text_height=14;
   message={"SPD ",8'd49+{5'd0,speed},"/8",200'd0};
  end
  if(inside(1122,624,77,24))begin
   text_valid=1;text_x=1134;text_y=628;text_width=6;
   if(!campaign)begin text_x=1129;text_width=7;text_pitch=9;message={"RESERVE",200'd0};text_ink=reserve_alarm==2?24'hd8442e:reserve_alarm==1?24'hffc15b:24'h7fe3ec;end
   else if(debris_left>mode_half(duo,level_id))begin message={"LOCKED",208'd0};text_ink=24'hd8442e;end
   else if(debris_left!=0)begin message={" HALF ",208'd0};text_ink=24'hffc15b;end
   else begin message={"ONLINE",208'd0};text_ink=24'h7fe3ec;end
  end
  if(campaign && inside(1211,278,54,216))begin
   phase_row=(y-278)/54;slot=3-phase_row;
   text_valid=1;compact_text=1;text_x=1211;text_y=306+phase_row*54;text_pitch=6;text_height=14;
   text_ink=slot==current_phase?24'hffc15b:(slot<current_phase?24'h7fe3ec:24'hb3c8d8);
   case(phase_row)
    0:begin text_x=1214;text_width=8;message={"RECHARGE",192'd0};end
    1:begin text_width=9;message={"STABILIZE",184'd0};end
    2:begin text_x=1217;text_width=7;message={"REBUILD",200'd0};end
    default:begin text_width=9;message={"RECONNECT",184'd0};end
   endcase
  end
  if(inside(REF_TIME_VALUE_X,REF_TIME_VALUE_Y,REF_TIME_VALUE_W,REF_TIME_VALUE_H))begin
   text_valid=1;text_x=REF_TIME_VALUE_X;text_y=REF_TIME_VALUE_Y;text_scale=2;text_width=5;text_pitch=23;text_height=32;
   message={8'd48+{4'd0,time_bcd[15:12]},8'd48+{4'd0,time_bcd[11:8]},8'd58,
    8'd48+{4'd0,time_bcd[7:4]},8'd48+{4'd0,time_bcd[3:0]},216'd0};text_ink=24'hb9edf4;
  end
  if(Stop && inside(592,300,96,32))begin
   text_valid=1;text_x=592;text_y=300;text_scale=2;text_width=5;message={"PAUSE",216'd0};
  end
  if((!duo) && inside(1017,156,72,22))begin
   text_valid=1;compact_text=1;text_x=1017;text_y=156;text_width=4;text_pitch=12;text_height=18;message={"HINT",224'd0};text_ink=24'h7fe3ec;
  end
  if((!duo) && inside(1011,210,76,18))begin
   text_valid=1;compact_text=1;text_x=1011;text_y=210;text_width=5;text_pitch=12;text_height=14;message={"GUIDE",216'd0};text_ink=24'he6f0f7;
  end
  if((!duo) && inside(1005,238,80,18))begin
   text_valid=1;compact_text=1;text_x=1005;text_y=238;text_width=6;text_pitch=12;text_height=14;message=hint_active?{"ACTIVE",208'd0}:{"READY",216'd0};text_ink=24'hffe39c;
  end
  if((!duo && campaign) && inside(1020,270,70,18))begin
   text_valid=1;compact_text=1;text_x=1020;text_y=270;text_width=3;text_pitch=12;text_height=14;message={8'd48+{5'd0,hint_quota},8'd47,8'd48+{5'd0,hint_capacity},232'd0};text_ink=24'h7fe3ec;
  end
  if((!duo && !campaign) && inside(1020,270,70,18))begin
   text_valid=1;compact_text=1;text_x=1020;text_y=270;text_width=4;text_pitch=10;text_height=14;message={"FREE",224'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(176,44,115,32))begin
   text_valid=1;compact_text=1;text_x=176;text_y=44;text_width=4;text_pitch=20;text_height=28;message=duo?{"DUO",232'd0}:{"SOLO",224'd0};text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(174,88,120,18))begin
   text_valid=1;compact_text=1;text_x=174;text_y=88;text_width=7;text_pitch=12;text_height=14;message={"ENDLESS",200'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(478,59,84,20))begin
   text_valid=1;compact_text=1;text_x=478;text_y=59;text_width=5;text_pitch=12;text_height=14;message={"SPEED",216'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(569,57,73,23))begin
   text_valid=1;compact_text=1;text_x=569;text_y=57;text_width=3;text_pitch=14;text_height=20;message={8'd49+{5'd0,speed},8'd47,8'd56,232'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(1010,57,38,23))begin
   text_valid=1;compact_text=0;text_x=1010;text_y=57;text_width=4;text_pitch=9;text_height=20;message={percent4(charge_percent),224'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(478,94,70,18))begin
   text_valid=1;compact_text=1;text_x=478;text_y=94;text_width=5;text_pitch=12;text_height=14;message={"SCORE",216'd0};text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(566,92,144,24))begin
   text_valid=1;compact_text=1;text_x=566;text_y=92;text_width=6;text_pitch=14;text_height=20;message={bcd6(score_bcd),208'd0};text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(752,94,70,18))begin
   text_valid=1;compact_text=1;text_x=752;text_y=94;text_width=5;text_pitch=12;text_height=14;message={"LINES",216'd0};text_ink=24'hffc15b;
  end
  if((!campaign) && inside(848,92,144,24))begin
   text_valid=1;compact_text=1;text_x=848;text_y=92;text_width=6;text_pitch=14;text_height=20;message={bcd6(lines_bcd),208'd0};text_ink=24'hffc15b;
  end
  if((!campaign) && inside(1210,290,66,18))begin
   text_valid=1;compact_text=1;text_x=1210;text_y=290;text_width=7;text_pitch=8;text_height=14;message={"RESERVE",200'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(1214,344,60,30))begin
   text_valid=1;compact_text=1;text_x=1214;text_y=344;text_width=4;text_pitch=12;text_height=28;message={percent4(reserve_percent),224'd0};text_ink=24'h7fe3ec;
  end
  if((!campaign) && inside(1218,410,58,18))begin
   text_valid=1;compact_text=1;text_x=1218;text_y=410;text_width=5;text_pitch=8;text_height=14;message={"POWER",216'd0};text_ink=24'he6f0f7;
  end
  if((!campaign) && inside(1214,450,60,18))begin
   text_valid=1;compact_text=1;text_x=1214;text_y=450;text_width=8;text_pitch=6;text_height=14;message=reserve_alarm==2?{"CRITICAL",192'd0}:reserve_alarm==1?{"LOW",232'd0}:{"STABLE",208'd0};text_ink=24'h7fe3ec;
  end
  if(!duo)begin
   for(i=0;i<4;i=i+1)begin
    if(inside(998+i*21,291,10,5))color=!campaign?24'h344f63:(i<hint_quota?24'h35e0f5:i<hint_capacity?24'h607d91:24'h1b2d3b);
   end
  end
  end
  if((choose) && inside(212,88,310,42))begin
   text_valid=1;compact_text=1;text_x=212;text_y=88;text_width=7;text_pitch=30;text_height=35;message={"CORE-07",200'd0};text_ink=24'he6f0f7;
  end
  if((choose) && inside(748,100,450,24))begin
   text_valid=1;compact_text=1;text_x=748;text_y=100;text_width=11;text_pitch=18;text_height=21;message=ship_select?{"SELECT SHIP",168'd0}:{"SELECT MODE",168'd0};text_ink=24'h7fe3ec;
  end
  if((choose) && inside(232,188,420,30))begin
   text_valid=1;compact_text=1;text_x=232;text_y=188;text_width=11;text_pitch=20;text_height=28;message=ship_select?{"SHIP ",decimal2(level_id+1),200'd0}:{"CORE REPAIR",168'd0};text_ink=24'h7fe3ec;
  end
  if((choose && !ship_select) && inside(232,478,420,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=478;text_width=19;text_pitch=12;text_height=14;message={"RECONNECT / REBUILD",104'd0};text_ink=24'he6f0f7;
  end
  if((choose && !ship_select) && inside(232,510,430,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=510;text_width=20;text_pitch=12;text_height=14;message={"STABILIZE / RECHARGE",96'd0};text_ink=24'he6f0f7;
  end
  if((choose && ship_select) && inside(232,478,300,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=478;text_width=13;text_pitch=12;text_height=14;message={"CHARGE TARGET",152'd0};text_ink=24'h7fe3ec;
  end
  if((choose && ship_select) && inside(610,478,60,18))begin
   text_valid=1;compact_text=1;text_x=610;text_y=478;text_width=2;text_pitch=16;text_height=14;message={decimal2(mode_target(duo,level_id)),240'd0};text_ink=24'h7fe3ec;
  end
  if((choose && ship_select) && inside(232,510,300,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=510;text_width=6;text_pitch=12;text_height=14;message={"DEBRIS",208'd0};text_ink=24'hffc15b;
  end
  if((choose && ship_select) && inside(610,510,60,18))begin
   text_valid=1;compact_text=1;text_x=610;text_y=510;text_width=2;text_pitch=16;text_height=14;message={decimal2(mode_total(duo,level_id)),240'd0};text_ink=24'hffc15b;
  end
  if((choose && ship_select) && inside(232,542,300,18))begin
   text_valid=1;compact_text=1;text_x=232;text_y=542;text_width=11;text_pitch=12;text_height=14;message={"START SPEED",168'd0};text_ink=24'he6f0f7;
  end
  if((choose && ship_select) && inside(610,542,60,18))begin
   text_valid=1;compact_text=1;text_x=610;text_y=542;text_width=3;text_pitch=16;text_height=14;message={8'd49+mode_initial(duo,level_id),8'd47,8'd56,232'd0};text_ink=24'he6f0f7;
  end
  if((choose) && inside(230,584,432,18))begin
   text_valid=1;compact_text=1;text_x=230;text_y=584;text_width=25;text_pitch=12;text_height=14;message=ship_select?(duo?{"DUO CAMPAIGN",160'd0}:{"SOLO CAMPAIGN",152'd0}):{"ORBITAL RECOVERY TERMINAL",56'd0};text_ink=24'h7fe3ec;
  end
  if((choose) && inside(768,584,432,18))begin
   text_valid=1;compact_text=1;text_x=768;text_y=584;text_width=14;text_pitch=14;text_height=14;message={"SELECT / START",144'd0};text_ink=24'he6f0f7;
  end
  if(choose && inside(768,172,432,374))begin
   menu_row=(y-172)/98;menu_y=172+menu_row*98;
   if(y>=menu_y+18 && y<menu_y+44)begin
    text_valid=1;compact_text=1;text_x=780;text_y=menu_y+18;text_width=13;text_pitch=16;text_height=21;
    text_ink=menu_row==menu_selection?24'h7fe3ec:24'he6f0f7;
    if(ship_select)begin text_width=7;message={"SHIP ",decimal2(menu_row+1),200'd0};end
    else case(menu_row)
     0:begin text_width=12;message={"SOLO ENDLESS",160'd0};end
     1:begin text_width=11;message={"DUO ENDLESS",168'd0};end
     2:begin text_width=13;message={"SOLO CAMPAIGN",152'd0};end
     default:begin text_width=12;message={"DUO CAMPAIGN",160'd0};end
    endcase
   end
   if(y>=menu_y+50 && y<menu_y+68)begin
    text_valid=1;compact_text=1;text_x=780;text_y=menu_y+50;text_width=20;text_pitch=12;text_height=14;text_ink=24'h8fabbf;
    if(ship_select)message={"CHARGE ",decimal2(mode_target(duo,menu_row[1:0])),"  DEBRIS ",decimal2(mode_total(duo,menu_row[1:0])),96'd0};
    else if(menu_row<2)message={"SURVIVE AND RECHARGE",96'd0};
    else message={"RESTORE THE FLEET",120'd0};
   end
  end
  if(choose && inside(565,649,240,28))begin
   text_valid=1;compact_text=1;text_x=565;text_y=649;text_width=12;text_pitch=18;text_height=21;
   message={"SYSTEM READY",160'd0};text_ink=24'h8ecad7;
  end
  column=(x-text_x)/text_pitch;gx=((x-text_x)%text_pitch)*8/text_pitch;gy=(y-text_y)*16/text_height;
  character=0;digit_index=-1;digit_x=0;digit_y=0;
  if(text_valid && x>=text_x && y>=text_y && column>=0 && column<text_width && column<32 && gy<16)begin
   character=message[255-column*8-:8];
   if(character>=48 && character<=57)digit_index=character-48;
   else if(character==58)digit_index=10;else if(character==47)digit_index=11;else if(character==37)digit_index=12;
   if(compact_text)begin
    if(phase_glyph(character,((x-text_x)%text_pitch)*6/text_pitch,(y-text_y)*7/text_height))color=text_ink;
   end else if(digit_index>=0)begin
    digit_x=((x-text_x)%text_pitch)*12/text_pitch;digit_y=(y-text_y)*20/text_height;
    if(digits[digit_index*240+digit_y*12+digit_x]>100)color=text_ink;
   end else if(glyph(character,gx,gy) || (gx>0 && glyph(character,gx-1,gy)))color=text_ink;
  end
  if(x>=1280 || y>=720)color=0;
 end
 // Four stages here plus the existing story_ui output register = five pixels.
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin p0<=0;p1<=0;p2<=0;p3<=0;end
  else begin p0<=color;p1<=p0;p2<=p1;p3<=p2;end
 end
 assign rgb=p3;
endmodule
