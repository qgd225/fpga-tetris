`timescale 1ns/1ps
module ui_component_review_tb;
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 integer fd,pixel,case_id,limit;
 reg [511:0] name;
 task capture;
  input [511:0] filename;
  input integer x0,y0,width,height;
  begin
   repeat(8)@(negedge scenes.clk);
   fd=$fopen(filename,"wb");
   $fwrite(fd,"P6\n%0d %0d\n255\n",width,height);
   limit=width*height;
   for(pixel=0;pixel<limit+4;pixel=pixel+1)begin
    @(negedge scenes.clk);
    if(pixel<limit)scenes.set_pixel(x0+pixel%width,y0+pixel/width);
    else scenes.set_pixel(x0,y0);
    @(posedge scenes.clk);#1;
    if(pixel>=4)$fwrite(fd,"%c%c%c",scenes.rgb[23:16],scenes.rgb[15:8],scenes.rgb[7:0]);
   end
   $fclose(fd);
   $display("RTL_COMPONENT_DONE %0s %0d %0d ORIGIN %0d %0d",filename,width,height,x0,y0);
  end
 endtask
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  scenes.configure_scene(4);
  capture("duo_campaign_tab.ppm",0,0,1280,720);
  scenes.configure_scene(6);
  capture("duo_endless_tab.ppm",0,0,1280,720);
  for(case_id=0;case_id<8;case_id=case_id+1)begin
   scenes.configure_scene(4);
   case(case_id)
    0:begin scenes.debris_left=48;scenes.locked=0;scenes.lines_bcd=24'h000015;end
    1:begin scenes.debris_left=18;scenes.locked=0;scenes.lines_bcd=24'h000001;end
    2:begin scenes.debris_left=18;scenes.locked=3;scenes.lines_bcd=24'h000015;end
    3:begin scenes.debris_left=18;scenes.locked=4;scenes.lines_bcd=24'h000020;end
    4:begin scenes.debris_left=0;scenes.locked=5;scenes.lines_bcd=24'h000024;end
    5:begin scenes.debris_left=0;scenes.locked=7;scenes.lines_bcd=24'h000031;end
    6:begin scenes.debris_left=0;scenes.locked=8;scenes.lines_bcd=24'h000035;scenes.success=1;end
    7:begin scenes.debris_left=0;scenes.locked=8;scenes.lines_bcd=24'h000035;scenes.success=1;scenes.animation=20;end
   endcase
   $sformat(name,"core_%0d.ppm",case_id);
   capture(name,1124,208,156,456);
  end
  for(case_id=0;case_id<5;case_id=case_id+1)begin
   scenes.configure_scene(6);
   case(case_id)
    0:begin scenes.reserve_pixels=174;scenes.reserve_alert=0;end
    1:begin scenes.reserve_pixels=104;scenes.reserve_alert=0;end
    2:begin scenes.reserve_pixels=17;scenes.reserve_alert=1;end
    3:begin scenes.reserve_pixels=5;scenes.reserve_alert=2;end
    4:begin scenes.reserve_pixels=0;scenes.reserve_alert=2;end
   endcase
   $sformat(name,"reserve_%0d.ppm",case_id);
   capture(name,1124,208,156,456);
  end
  for(case_id=0;case_id<7;case_id=case_id+1)begin
   scenes.configure_scene(3);scenes.locked=0;scenes.lines_bcd=24'h000001;
   scenes.hint_show=0;scenes.hint_cap=1;scenes.quota=1;
   case(case_id)
    0:begin end
    1:begin scenes.hint_show=1;scenes.quota=0;scenes.hint_ticks=360;end
    2:begin scenes.locked=3;scenes.hint_show=1;scenes.quota=1;scenes.hint_cap=3;scenes.hint_ticks=120;end
    3:begin scenes.locked=3;scenes.quota=0;scenes.hint_cap=3;scenes.hint_ticks=0;end
    4:begin scenes.locked=5;scenes.quota=4;scenes.hint_cap=4;end
    5:begin scenes.configure_scene(5);scenes.hint_show=0;end
    6:begin scenes.configure_scene(5);scenes.hint_show=1;end
   endcase
   $sformat(name,"hint_%0d.ppm",case_id);
   capture(name,968,146,140,164);
  end
  for(case_id=0;case_id<8;case_id=case_id+1)begin
   scenes.configure_scene(4);
   case(case_id)
    0:begin scenes.held_visible=0;scenes.hold_available=1;end
    1:begin scenes.held_visible=0;scenes.hold_available=0;scenes.held_conditions=3'b001;end
    2:begin scenes.held_visible=1;scenes.hold_available=0;scenes.held_conditions=3'b101;end
    3:begin scenes.held_visible=1;scenes.held_reserved=1;scenes.held_actor=0;end
    4:begin scenes.held_visible=1;scenes.held_reserved=1;scenes.held_actor=1;end
    5:begin scenes.held_visible=1;scenes.expire_flash=1;scenes.hold_lifetime=1;end
    6:begin scenes.held_visible=0;scenes.reject_flash=1;scenes.held_conditions=3'b001;end
    7:begin scenes.held_visible=0;scenes.expire_flash=1;scenes.hold_lifetime=0;end
   endcase
   $sformat(name,"hold_%0d.ppm",case_id);
   capture(name,150,326,148,184);
  end
  for(case_id=0;case_id<8;case_id=case_id+1)begin
   scenes.configure_scene(6);scenes.speed=case_id;
   case(case_id)
    0:scenes.time_bcd=16'h0000;
    1:scenes.time_bcd=16'h0045;
    2:scenes.time_bcd=16'h0130;
    3:scenes.time_bcd=16'h0215;
    4:scenes.time_bcd=16'h0300;
    5:scenes.time_bcd=16'h0345;
    6:scenes.time_bcd=16'h0430;
    7:scenes.time_bcd=16'h0515;
   endcase
   $sformat(name,"speed_%0d.ppm",case_id);
   capture(name,468,48,584,36);
  end
  for(case_id=0;case_id<5;case_id=case_id+1)begin
   scenes.configure_scene(4);
   case(case_id)
    0:begin scenes.lines_bcd=0;scenes.debris_left=48;scenes.locked=0;end
    1:begin scenes.lines_bcd=24'h000015;scenes.debris_left=18;scenes.locked=3;end
    2:begin scenes.lines_bcd=24'h000035;scenes.debris_left=18;scenes.locked=4;end
    3:begin scenes.lines_bcd=24'h000031;scenes.debris_left=0;scenes.locked=7;end
    4:begin scenes.lines_bcd=24'h000035;scenes.debris_left=0;scenes.locked=8;scenes.success=1;end
   endcase
   $sformat(name,"task_%0d.ppm",case_id);
   capture(name,464,46,590,78);
  end
  $display("ALL_PLAYER_TAB_AND_COMPONENT_STATES_DONE");
  $finish;
 end
endmodule
