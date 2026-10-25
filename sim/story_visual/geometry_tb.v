`timescale 1ns/1ps
module geometry_tb;
 reg clk=0,rst=0;always #5 clk=~clk;
 `include "scene_fixture.vh"
 integer errors=0,checks=0,m,px,py,fx,fr,count1,count2,counth,ports,core_pixels,k,t,dx,dy;
 reg expected;
 task check;input condition;input [511:0] label;
 begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;if(errors<16)$display("FAIL UI geometry %0s x=%0d y=%0d",label,x,y);end end endtask
 task position;input integer ax,ay;begin @(negedge clk);set_pixel(ax,ay);#1;end endtask
 task rgb_check;input integer ax,ay,index;input [511:0] label;
 begin position(ax,ay);repeat(4)@(negedge clk);check(rgb===palette[index],label);end endtask
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
    check(dut.core_hit==(px>=1016 && px<1064 && py>=352 && py<608),"core fixed bbox");
    if(dut.panel1)count1=count1+1;if(dut.panel2)count2=count2+1;if(dut.panelh)counth=counth+1;
    if(dut.scene.port)ports=ports+1;if(dut.core_hit)core_pixels=core_pixels+1;
   end
   check(count1==12544 && count2==(m?12544:0) && counth==12544,"panel areas");
   check(ports==4*12*24 && core_pixels==48*256,"four ports core area");
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
   phase=3;locked=6;danger=2;position(1016,366);check(dut.core_index==54,"extended severe tooth");
   danger=1;position(1018,366);check(dut.core_index==43,"four amber warning pairs");
   locked=5;danger=0;position(1018,366);check(dut.core_index==53,"no premature structural teeth");
   phase=0;locked=1;charge_left=0;
   position(fx,144);check(!dut.margin && dut.foreground && dut.material_kind==0,"first logical pixel preserved");
   position(fx-1,200);check(dut.margin,"left exterior channel");position(fr,200);check(dut.margin,"right exterior channel");
   for(k=0;k<8;k=k+1)begin
    position(1040,352+k*32+16);check(dut.core.segment==k && dut.core.from_bottom==7-k,"eight core segment mapping");
   end
   text_check(fx,72,288,24,2);text_check(fx+304,80,24,12,0);text_check(fx+336,72,48,24,1);
   text_check(fx,116,88,12,0);text_check(176,156,96,24,2);text_check(168,540,90,12,4);text_check(176,120,20,12,4);
   text_check(fx,634,112,12,0);
   comms_visible=1;position(fx+383,90);check(dut.text_x==fx+336,"speed remains outside COMMS");
   position(1072,120);if(m)check(dut.text_x==1072 && dut.text_y==120,"P2 below COMMS");comms_visible=0;
   rgb_check(fx,144,46,"rounded field corner returns field floor");
   rgb_check(200,224,50,"rounded preview corner returns panel floor");
   Finalize=1;result_ready=1;success=1;
   rgb_check(fx+10,610,30,"result darkens only field material");
   rgb_check(fx,634,49,"result leaves plate base unchanged");
   text_check(420,264,440,36,3);text_check(448,344,384,24,1);text_check(580,496,120,12,0);text_check(556,544,168,12,0);
   position(448+23*16,344);score_bcd=0;#1;check(dut.direct_char==dut.CHAR_DASH,"zero score dash at right edge");score_bcd=24'h006400;
   success=0;text_check(500,264,280,36,3);
   position(430,250);check(dut.foreground_index==27,"result panel unchanged anchor");
   success=1;result_ready=0;comms_visible=1;position(816,56);check(!dut.text_valid && !dut.comms_allowed,"success silent interval hides COMMS");
   Finalize=0;result_ready=0;success=0;comms_visible=0;
  end
  if(errors==0)$display("ALL PASS UI GEOMETRY checks=%0d",checks);else $display("FAILED UI GEOMETRY errors=%0d",errors);
  $finish;
 end
endmodule
