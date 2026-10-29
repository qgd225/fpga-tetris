`timescale 1ns/1ps
module ui_renderer_equivalence_tb;
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 wire [23:0] golden_rgb;
 `include "ui_renderer_golden_instance.vh"
 reg [31:0] seed=32'h20261029;
 integer n;
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  for(n=0;n<120012;n=n+1)begin
   @(negedge scenes.clk);
   if(n%997==0)begin
    scenes.configure_scene((n/997)%7);
    scenes.comms_visible=(n/997)%3==1;
    scenes.Stop=(n/997)%5==1;
    scenes.Finalize=(n/997)%7==3;scenes.result_ready=scenes.Finalize;
   end
   seed=seed*1664525+1013904223;
   scenes.set_pixel(seed%1280,(seed/1280)%720);
   @(posedge scenes.clk);#1;
   if(n>=12 && scenes.rgb!==golden_rgb)begin
    $display("FAIL BACKGROUND_RETIME n=%0d actual=%h golden=%h",n,scenes.rgb,golden_rgb);$finish;
   end
  end
  $display("ALL PASS BACKGROUND_RETIME 120000 RANDOM_PIXELS MODES_DIALOG_PAUSE_RESULT");$finish;
 end
endmodule
