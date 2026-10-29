`timescale 1ns/1ps
module ui_a2_integration_tb #(parameter OVERLAY_ONLY=0);
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 wire [23:0] golden_renderer;
 reg [23:0] golden_rgb;
 // Generated pin-for-pin connection to the pre-A2 renderer snapshot. It reads
 // exactly the same fixture inputs and the same reviewed near-color skin.
 `include "ui_a2_golden_instance.vh"
 always @(posedge scenes.clk)golden_rgb<=golden_renderer;
 integer fd,pixel,count,scene,id;
 reg [511:0] filename;
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
      $display("A2_PARITY_FAIL %0s x=%0d y=%0d actual=%h golden=%h",name,x0+(pixel-4)%width,y0+(pixel-4)/width,scenes.rgb,golden_rgb);
      $finish;
     end
     $fwrite(fd,"%c%c%c",scenes.rgb[23:16],scenes.rgb[15:8],scenes.rgb[7:0]);
    end
   end
   $fclose(fd);$display("A2_RTL_FRAME_DONE %0s %0d %0d ORIGIN %0d %0d ZERO_MISMATCHES",name,width,height,x0,y0);
  end
 endtask
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  if(!OVERLAY_ONLY)begin
  scenes.configure_scene(4);capture("duo_campaign.ppm",0,0,1280,720);
  scenes.configure_scene(3);capture("solo_campaign.ppm",0,0,1280,720);
  scenes.configure_scene(6);capture("duo_endless.ppm",0,0,1280,720);
  scenes.configure_scene(5);capture("solo_endless.ppm",0,0,1280,720);
  for(scene=0;scene<3;scene=scene+1)begin
   scenes.configure_scene(scene);$sformat(filename,"menu_%0d.ppm",scene);capture(filename,0,0,1280,720);
  end
  end
  scenes.configure_scene(4);scenes.comms_visible=1;scenes.comms_id=1;
  capture("comms_overlay.ppm",352,144,576,144);scenes.comms_visible=0;
  scenes.Stop=1;capture("pause_overlay.ppm",560,284,160,64);scenes.Stop=0;
  scenes.held_reserved=0;scenes.held_actor=0;scenes.reject_flash=0;scenes.expire_flash=0;
  scenes.held_conditions=3'b000;scenes.held_visible=1;
  capture("hold_0.ppm",152,328,146,184);
  scenes.held_reserved=1;scenes.held_conditions=3'b001;
  capture("hold_1.ppm",152,328,146,184);
  scenes.held_actor=1;scenes.held_conditions=3'b010;
  capture("hold_2.ppm",152,328,146,184);
  scenes.held_reserved=0;scenes.held_actor=0;scenes.reject_flash=1;scenes.held_conditions=3'b011;
  capture("hold_3.ppm",152,328,146,184);
  scenes.reject_flash=0;scenes.expire_flash=1;scenes.held_conditions=3'b100;scenes.held_visible=0;
  capture("hold_4.ppm",152,328,146,184);
  scenes.configure_scene(4);scenes.feedback_clear=1;
  capture("clear_feedback.ppm",352,570,576,54);
  scenes.configure_scene(4);scenes.debris_left=0;scenes.locked=7;scenes.lines_bcd=24'h000035;
  capture("completed_header.ppm",468,48,584,72);
  if(OVERLAY_ONLY)$display("A2_OVERLAY_FRAMES_PASS");else $display("A2_ALL_INTEGRATION_FRAMES_PASS");$finish;
 end
endmodule
