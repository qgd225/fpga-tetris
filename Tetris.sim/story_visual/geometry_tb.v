`timescale 1ns/1ps
module geometry_tb;
 reg clk=0,rst=0;always #5 clk=~clk;
 // Shared fixture expanded during directory migration.
// 固定局面是测试输入，绘制器/字形/小图块均使用正式RTL和真实初始化文件。
reg [10:0] x=0,y=0;
reg duo=1,choose=0,Idle=0,Playing=1,Stop=0,Finalize=0;
reg [1:0] phase=0,danger=0;
reg [3:0] locked=1;
reg success=0,result_ready=0;
reg [2:0] speed=1;
reg [19:0] lines_bcd=20'h00004;
reg [23:0] score_bcd=24'h006400;
reg [15:0] time_bcd=16'h0248;
reg [7:0] animation=6;
reg [4:0] charge_left=20;
`ifdef PHASE_STRESS
wire in_field,cell_visible;
wire [4:0] local_x,local_y,map_column,map_row;
story_pixel_mapper mapper(.hcounter(x),.vcounter(y),.duo(duo),.in_field(in_field),.cell_visible(cell_visible),
    .column(map_column),.row(map_row),.local_x(local_x),.local_y(local_y));
`else
reg in_field=0,cell_visible=0;
reg [4:0] local_x=0,local_y=0;
`endif
reg occupied=0,piece1=0,piece2=0,ghost1=0,ghost2=0,hint_hit=0;
reg [2:0] type1=0,type2=4,cell_type=0,hint_type=1;
reg owner=0,next1=0,next2=0,hold=0,next_slot=0,hold_slot=0;
reg [2:0] next_type1=1,next_type2=6,hold_type=5;
reg [4:0] next_x=0,next_y=0,hold_x=0,hold_y=0;
reg feedback_lock=0,feedback_hard_left=0,feedback_hard_right=0,feedback_clear=0;
reg [3:0] feedback_inset=0,feedback_sides=0;reg [1:0] feedback_rotation=0;
reg comms_visible=0;reg [2:0] comms_id=0;
wire [23:0] rgb;
reg board[0:479];reg [2:0] board_type[0:479];reg board_owner[0:479];
reg [23:0] palette[0:55];
integer bi;
story_ui dut(.debris_percent(7'd50),.success_age(7'd72),.campaign(1'b1),.ship_select(1'b0),.level_id(2'd2),.result_option(2'd0),.debris_left(7'd0),.debris_cell(1'b0),.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
    .comms_visible(comms_visible),.comms_id(comms_id),.choose_cnt(duo?4'd1:4'd0),.phase(phase),.danger(danger),.locked(locked),.success(success),.result_ready(result_ready),
    .bounds1({11'd241,11'd213,(duo?11'd545:11'd593),(duo?11'd445:11'd493)}),
    .bounds2({11'd289,11'd237,11'd833,11'd757}),.star_drift(11'd0),.feedback_clear_age(5'd0),.feedback_clear_row(feedback_clear),
    .feedback_lock(feedback_lock),.feedback_hard_left(feedback_hard_left),.feedback_hard_right(feedback_hard_right),.feedback_clear(feedback_clear),
    .feedback_inset(feedback_inset),.feedback_sides(feedback_sides),.feedback_rotation(feedback_rotation),.speed(speed),.lines_bcd(lines_bcd),.score_bcd(score_bcd),.time_bcd(time_bcd),.animation(animation),.charge_left(charge_left),
    .in_field(in_field),.cell_visible(cell_visible),.local_x(local_x),.local_y(local_y),
    .occupied(occupied),.piece1(piece1),.piece2(piece2),.ghost1(ghost1),.ghost2(ghost2),.hint_hit(hint_hit),
    .type1(type1),.type2(type2),.cell_type(cell_type),.hint_type(hint_type),.owner(owner),
    .next1(next1),.next2(next2),.hold(hold),.next_slot(next_slot),.hold_slot(hold_slot),
    .next_type1(next_type1),.next_type2(next_type2),.hold_type(hold_type),.next_x(next_x),.next_y(next_y),.hold_x(hold_x),.hold_y(hold_y),.rgb(rgb));
task tile;
    input integer c,r,t,p;
    begin board[r*24+c]=1;board_type[r*24+c]=t;board_owner[r*24+c]=p;end
endtask
task initialize_board;
    begin
        for(bi=0;bi<480;bi=bi+1)begin board[bi]=0;board_type[bi]=0;board_owner[bi]=0;end
        tile(0,19,0,0);tile(1,19,0,0);tile(2,19,0,0);tile(3,19,0,0);
        tile(4,18,2,0);tile(5,18,2,0);tile(4,19,2,0);tile(5,19,2,0);
        tile(6,19,5,0);tile(7,19,5,0);tile(8,19,5,0);tile(8,18,5,0);
        tile(9,19,4,0);tile(10,19,4,0);tile(10,18,4,0);tile(11,18,4,0);
        tile(12,19,1,1);tile(13,19,1,1);tile(14,19,1,1);tile(13,18,1,1);
        tile(15,16,0,1);tile(15,17,0,1);tile(15,18,0,1);tile(15,19,0,1);
        tile(16,18,2,1);tile(17,18,2,1);tile(16,19,2,1);tile(17,19,2,1);
        tile(18,19,6,1);tile(19,19,6,1);tile(20,19,6,1);tile(18,18,6,1);
        tile(21,18,3,1);tile(22,18,3,1);tile(22,19,3,1);tile(23,19,3,1);
    end
endtask
task set_pixel;
    input integer px,py;
    integer fx,dx,dy,c,r,ax,ay,pc,pr;
    begin
        x=px;y=py;fx=duo?352:400;dx=px-fx;dy=py-144;
        occupied=0;piece1=0;piece2=0;ghost1=0;ghost2=0;hint_hit=0;cell_type=0;owner=0;
`ifndef PHASE_STRESS
        in_field=px>=fx && px<fx+(duo?24:20)*24 && py>=144 && py<624;
        local_x=dx%24;local_y=dy%24;
        cell_visible=in_field && (dx%24)<22 && (dy%24)<22;
`endif
        if(px>=fx && px<fx+(duo?24:20)*24 && py>=144 && py<624)begin
            c=dx/24;r=dy/24;
`ifdef PHASE_STRESS
            occupied=1;cell_type=c%7;owner=c%2;
`else
            occupied=board[r*24+c] && !Idle;cell_type=board_type[r*24+c];owner=board_owner[r*24+c];
            if(!Idle && !Finalize)begin
                piece1=r==3 && c>=4 && c<=7;
                piece2=duo && (r==4 && c>=18 && c<=19 || r==5 && c>=17 && c<=18);
                ghost1=r==17 && c>=4 && c<=7;
                ghost2=duo && (r==16 && c>=18 && c<=19 || r==17 && c>=17 && c<=18);
            end
`endif
        end
        next1=0;next2=0;hold=0;next_slot=0;hold_slot=0;next_x=0;next_y=0;hold_x=0;hold_y=0;
        if(py>=200 && py<296 && (px>=176 && px<272 || duo && px>=992 && px<1088))begin
            ax=px>=992?px-992:px-176;ay=py-200;pc=ax/24;pr=ay/24;
            next_slot=1;next_x=ax%24;next_y=ay%24;
            if(!Idle && ax%24<22 && ay%24<22)begin
                if(px<992)next1=(pr==1 && pc==1 || pr==2 && pc<=2);
                else next2=(pr==1 && pc<=2 || pr==2 && pc==2);
            end
        end
        if(py>=376 && py<472 && px>=176 && px<272)begin
            ax=px-176;ay=py-376;pc=ax/24;pr=ay/24;
            hold_slot=1;hold_x=ax%24;hold_y=ay%24;
            hold=!Idle && ax%24<22 && ay%24<22 && (pr==1 && pc<=2 || pr==0 && pc==2);
        end
    end
endtask

 integer errors=0,checks=0,m,px,py,fx,fr,count1,count2,counth,ports,core_pixels,k,t,dx,dy;
 reg expected;
 task check;input condition;input [511:0] label;
 begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;if(errors<16)$display("FAIL UI geometry %0s x=%0d y=%0d",label,x,y);end end endtask
 task position;input integer ax,ay;begin @(negedge clk);set_pixel(ax,ay);@(posedge clk);#1;end endtask
 task rgb_check;input integer ax,ay,index;input [511:0] label;
 begin position(ax,ay);repeat(6)@(negedge clk);check(rgb===palette[index],label);end endtask
 task text_check;input integer ax,ay,w,h,style;
 begin
  for(dy=0;dy<h;dy=dy+1)for(dx=0;dx<w;dx=dx+1)begin
   position(ax+dx,ay+dy);
   check(dut.text_valid && dut.text_x==ax && dut.text_y==ay && dut.text_style==style,"text request geometry");
   case(style)
   0:begin check(dut.text_column==dx/8 && dut.glyph_column==dx%8 && dut.glyph_row==dy,"1x metrics");end
   1:begin check(dut.text_column==dx/16 && dut.glyph_column==(dx%16)/2 && dut.glyph_row==dy/2,"2x metrics");end
   2:begin check(dut.text_column==dx/24 && dut.glyph_column==((dx%24)%16)/2 && dut.glyph_row==dy/2 && dut.glyph_area==(dx%24<16),"spaced 2x metrics");end
   3:begin check(dut.text_column==dx/32 && dut.glyph_column==((dx%32)/3)%8 && dut.glyph_row==dy/3 && dut.glyph_area==(dx%32<24),"3x title metrics");end
   4:begin check(dut.text_column==dx/10 && dut.glyph_column==((dx%10)%8) && dut.glyph_row==dy && dut.glyph_area==(dx%10<8),"maintenance metrics");end
   endcase
  end
 end endtask
 initial begin
  initialize_board;$readmemh("palette_reference.mem",palette);repeat(3)@(negedge clk);rst=1;charge_left=0;
  for(m=0;m<2;m=m+1)begin
   duo=m;fx=m?352:400;fr=m?928:880;count1=0;count2=0;counth=0;ports=0;core_pixels=0;
   // Full raster checks are independent formulas, not shared layout constants.
   for(py=0;py<720;py=py+1)for(px=0;px<1280;px=px+1)begin
    x=px;y=py;#1;
    check(dut.panel1==(px>=168 && px<280 && py>=192 && py<304),"left 112 panel");
    check(dut.panel2==(m && px>=984 && px<1096 && py>=192 && py<304),"right 112 panel");
    check(dut.panelh==(px>=168 && px<280 && py>=368 && py<480),"shared 112 panel");
    check(dut.core_hit==(px>=1000 && px<1080 && py>=352 && py<608),"core fixed bbox");
    if(dut.panel1)count1=count1+1;if(dut.panel2)count2=count2+1;if(dut.panelh)counth=counth+1;
    if(dut.scene.port)ports=ports+1;if(dut.core_hit)core_pixels=core_pixels+1;
   end
   check(count1==12544 && count2==(m?12544:0) && counth==12544,"panel areas");
   check(ports==4*12*24 && core_pixels==80*256,"four ports core area");
   for(k=0;k<4;k=k+1)begin
    position(fr+12,576-k*64);check(dut.scene.port && dut.scene.port_inner,"port pair exact center");
    check(dut.scene.branch==k,"port phase assignment");
   end
   t=0;
   for(k=fx;k<fr;k=k+1)begin position(k,625);if(dut.bottom_vent)t=t+1;end
   check(t==(m?48:40),"24-pitch bottom diagonals, two pixels per cell");
   for(k=0;k<4;k=k+1)begin
    phase=k;charge_left=19;position(978,576-k*64);check(dut.scene.flow,"horizontal pulse reaches bus in both modes");
    charge_left=15;position(983,582);check(dut.scene.flow,"vertical pulse reaches lower outlet");
    charge_left=14;position(990,591);check(dut.scene.flow,"lower pulse first half");
    charge_left=13;position(1008,591);check(dut.scene.flow,"lower pulse last half");
    charge_left=12;position(1008,591);check(!dut.scene.flow,"200ms pulse expires");
   end
   phase=3;locked=6;danger=2;position(1002,368);check(dut.core_index==54,"extended severe tooth");
   danger=1;position(1002,368);check(dut.core_index==43,"four amber warning pairs");
   locked=5;danger=0;position(1002,368);check(dut.core_index==22,"fixed mechanical teeth join rails");
   phase=0;locked=1;charge_left=0;
   position(fx,144);check(!dut.margin && dut.foreground && dut.material_kind==0,"first logical pixel preserved");
   position(fx-1,200);check(dut.margin,"left exterior channel");position(fr,200);check(dut.margin,"right exterior channel");
   for(k=0;k<8;k=k+1)begin
    position(1040,352+k*32+16);check(dut.core.segment==k && dut.core.from_bottom==7-k,"eight core segment mapping");
   end
   text_check(fx,72,288,24,2);text_check(fx+304,80,24,12,0);text_check(fx+336,72,48,24,1);
   text_check(fx,116,88,12,0);text_check(176,156,96,24,2);text_check(168,540,90,12,4);text_check(176,120,20,12,4);
   position(fx+10,610);check(dut.bottom_text_hidden,"bottom labels never cover occupied cells");
   comms_visible=1;position(fx+383,90);check(dut.text_x==fx+336,"speed remains outside COMMS");
   position(1072,120);if(m)check(dut.text_x==1072 && dut.text_y==120,"P2 below COMMS");comms_visible=0;
   rgb_check(fx,144,46,"rounded field corner returns field floor");
   rgb_check(200,224,50,"rounded preview corner returns panel floor");
   Finalize=1;result_ready=1;success=1;
   rgb_check(fx+10,610,30,"result darkens only field material");
   rgb_check(fx,634,53,"detached nameplate removed");
   text_check(420,264,440,36,3);text_check(448,360,384,24,1);text_check(448,400,384,24,1);text_check(448,440,384,24,1);text_check(500,496,280,12,0);text_check(556,544,168,12,0);
   position(448+23*16,344);check(!dut.text_valid,"unused score row removed");
   success=0;text_check(500,264,280,36,3);
   position(430,250);check(dut.foreground_index==27,"result panel unchanged anchor");
   success=1;result_ready=0;comms_visible=1;position(816,56);check(!dut.text_valid && !dut.comms_allowed,"success silent interval hides COMMS");
   Finalize=0;result_ready=0;success=0;comms_visible=0;
  end
  choose=1;Finalize=0;Playing=0;
  text_check(320,152,224,36,3);text_check(656,212,352,24,1);
  text_check(736,288,336,24,1);text_check(736,360,336,24,1);
  position(680,426);check(dut.menu_entry,"implemented third mode visible");
  position(900,214);check(dut.text_length==11 && dut.text_column>=dut.text_length,"menu subtitle cannot read into next text");
  if(errors==0)$display("ALL PASS UI GEOMETRY checks=%0d",checks);else $display("FAILED UI GEOMETRY errors=%0d",errors);
  $finish;
 end
endmodule
