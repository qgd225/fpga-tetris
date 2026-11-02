`timescale 1ns/1ps
module ui_core_chain_render_tb;
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 integer fd,n,id;
 task frame;begin
  @(negedge scenes.clk);scenes.set_pixel(0,0);
  @(negedge scenes.clk);scenes.set_pixel(1,0);repeat(6)@(negedge scenes.clk);
 end endtask
 task capture;input [511:0] name;begin
  fd=$fopen(name,"wb");$fwrite(fd,"P6\n100 420\n255\n");
  repeat(8)@(negedge scenes.clk);
  for(n=0;n<42004;n=n+1)begin
   @(negedge scenes.clk);
   if(n<42000)scenes.set_pixel(1144+n%100,208+n/100);else scenes.set_pixel(1,0);
   @(posedge scenes.clk);#1;
   if(n>=4)begin
    if(^scenes.rgb===1'bx)begin $display("FAIL CORE_RENDER unknown");$finish;end
    $fwrite(fd,"%c%c%c",scenes.rgb[23:16],scenes.rgb[15:8],scenes.rgb[7:0]);
   end
  end
  $fclose(fd);
 end endtask
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;scenes.configure_scene(4);scenes.charge_left=0;
  scenes.debris_left=48;scenes.locked=0;frame;capture("locked.ppm");
  scenes.debris_left=18;scenes.locked=3;frame;for(id=0;id<18;id=id+1)frame;capture("half_chained.ppm");
  scenes.debris_left=0;scenes.locked=7;frame;for(id=0;id<18;id=id+1)frame;capture("online.ppm");
  scenes.choose=1;frame;scenes.choose=0;scenes.debris_left=48;scenes.locked=0;frame;
  scenes.debris_left=47;frame;for(id=0;id<8;id=id+1)frame;capture("locked_scan.ppm");
  $display("ALL PASS CORE_RENDER 4 actual RTL crops");$finish;
 end
endmodule
