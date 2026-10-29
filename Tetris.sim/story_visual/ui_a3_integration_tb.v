`timescale 1ns/1ps
module ui_a3_integration_tb #(parameter SMOKE=0);
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 wire [23:0] golden_renderer;
 reg [23:0] golden_rgb;
 `include "ui_a3_golden_instance.vh"
 always @(posedge scenes.clk)golden_rgb<=golden_renderer;
 integer fd,pixel,count,n;
 task capture;
  input [511:0] name;
  input integer x0,y0,width,height;
  begin
   repeat(8)@(negedge scenes.clk);
   fd=$fopen(name,"wb");$fwrite(fd,"P6\n%0d %0d\n255\n",width,height);count=width*height;
   for(pixel=0;pixel<count+4;pixel=pixel+1)begin
    @(negedge scenes.clk);
    if(pixel<count)scenes.set_pixel(x0+pixel%width,y0+pixel/width);
    else scenes.set_pixel(0,0);
    @(posedge scenes.clk);#1;
    if(pixel>=4)begin
     if((^scenes.rgb)===1'bx || (^golden_rgb)===1'bx || scenes.rgb!==golden_rgb)begin
      $display("A3_PARITY_FAIL %0s x=%0d y=%0d actual=%h golden=%h",name,x0+(pixel-4)%width,y0+(pixel-4)/width,scenes.rgb,golden_rgb);
      $finish;
     end
     $fwrite(fd,"%c%c%c",scenes.rgb[23:16],scenes.rgb[15:8],scenes.rgb[7:0]);
    end
   end
   $fclose(fd);$display("A3_RTL_FRAME_DONE %0s %0d %0d ORIGIN %0d %0d ZERO_MISMATCHES",name,width,height,x0,y0);
  end
 endtask
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  scenes.configure_scene(4);capture("mission_joints.ppm",468,32,746,310);
  capture("core_half.ppm",1120,208,100,370);capture("legend_rebuild.ppm",972,364,136,248);
  scenes.debris_left=39;scenes.locked=0;
  capture("core_locked.ppm",1120,208,100,370);capture("legend_reconnect.ppm",972,364,136,248);
  scenes.debris_left=8;scenes.locked=5;scenes.animation=16;
  capture("core_five.ppm",1120,208,100,370);capture("legend_stabilize.ppm",972,364,136,248);
  scenes.debris_left=0;scenes.locked=7;
  capture("core_online7.ppm",1120,208,100,370);capture("legend_recharge.ppm",972,364,136,248);
  scenes.locked=8;scenes.lines_bcd=24'h000035;scenes.success=1;
  capture("core_success8.ppm",1120,208,100,370);capture("header_complete.ppm",156,32,893,96);
  scenes.configure_scene(6);scenes.reserve_pixels=0;capture("reserve_empty.ppm",972,208,248,452);
  scenes.reserve_pixels=174;capture("reserve_full.ppm",972,208,248,452);
  scenes.reserve_pixels=70;scenes.reserve_alert=1;capture("reserve_low.ppm",972,208,248,452);
  scenes.reserve_pixels=20;scenes.reserve_alert=2;capture("reserve_critical.ppm",972,208,248,452);
  if(!SMOKE)begin
   scenes.configure_scene(4);capture("duo_campaign.ppm",0,0,1280,720);
   scenes.configure_scene(3);capture("solo_campaign.ppm",0,0,1280,720);
   scenes.configure_scene(6);capture("duo_endless.ppm",0,0,1280,720);
   scenes.configure_scene(5);capture("solo_endless.ppm",0,0,1280,720);
   scenes.configure_scene(0);capture("menu_unchanged.ppm",0,0,1280,720);
   scenes.configure_scene(4);scenes.comms_visible=1;scenes.comms_id=1;
   capture("comms_overlay.ppm",352,144,576,144);
  end
  $display("A3_ALL_INTEGRATION_FRAMES_PASS");$finish;
 end
endmodule
