`timescale 1ns/1ps
// A1 palette appearance review only. Full-frame backgrounds still use the
// existing preview renderer; compressed ROMs have separate standalone tests.
module ui_a1_palette_frame_tb;
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 integer fd,pixel,limit;
 task capture;
  input [511:0] filename;
  begin
   repeat(8)@(negedge scenes.clk);
   fd=$fopen(filename,"wb");$fwrite(fd,"P6\n1280 720\n255\n");limit=1280*720;
   for(pixel=0;pixel<limit+4;pixel=pixel+1)begin
    @(negedge scenes.clk);
    if(pixel<limit)scenes.set_pixel(pixel%1280,pixel/1280);
    else scenes.set_pixel(0,0);
    @(posedge scenes.clk);#1;
    if(pixel>=4)$fwrite(fd,"%c%c%c",scenes.rgb[23:16],scenes.rgb[15:8],scenes.rgb[7:0]);
   end
   $fclose(fd);$display("A1_PALETTE_FRAME_DONE %0s",filename);
  end
 endtask
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  scenes.configure_scene(4);capture("duo_campaign_near_palette.ppm");
  scenes.debris_left=39;scenes.locked=0;capture("duo_campaign_locked_near_palette.ppm");
  $display("A1_PALETTE_REVIEW_FRAMES_DONE");$finish;
 end
endmodule
