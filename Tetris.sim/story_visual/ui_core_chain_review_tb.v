`timescale 1ns/1ps
module ui_core_chain_review_tb;
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
  scenes.configure_scene(4);scenes.debris_left=39;scenes.locked=0;
  capture("core_locked.ppm",1110,208,118,456);
  capture("duo_campaign_locked.ppm",0,0,1280,720);
  $display("ALL_CORE_CHAIN_FRAMES_DONE");
  $finish;
 end
endmodule
