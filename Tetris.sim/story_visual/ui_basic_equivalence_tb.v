`timescale 1ns/1ps
module ui_basic_equivalence_tb;
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 wire [23:0] golden_rgb;wire golden_hit;
 ui_basic_layer_golden golden(.clk(scenes.dut.reference_layer.basic.clk),.reset_n(scenes.dut.reference_layer.basic.reset_n),.enable(scenes.dut.reference_layer.basic.enable),.duo(scenes.dut.reference_layer.basic.duo),.campaign(scenes.dut.reference_layer.basic.campaign),.x(scenes.dut.reference_layer.basic.x),.y(scenes.dut.reference_layer.basic.y),.panel_rgb(scenes.dut.reference_layer.basic.panel_rgb),.in_field(scenes.dut.reference_layer.basic.in_field),.cell_visible(scenes.dut.reference_layer.basic.cell_visible),.occupied(scenes.dut.reference_layer.basic.occupied),.debris_cell(scenes.dut.reference_layer.basic.debris_cell),.piece1(scenes.dut.reference_layer.basic.piece1),.piece2(scenes.dut.reference_layer.basic.piece2),.ghost1(scenes.dut.reference_layer.basic.ghost1),.ghost2(scenes.dut.reference_layer.basic.ghost2),.hint_active(scenes.dut.reference_layer.basic.hint_active),.hint_hit(scenes.dut.reference_layer.basic.hint_hit),.hint_type(scenes.dut.reference_layer.basic.hint_type),.type1(scenes.dut.reference_layer.basic.type1),.type2(scenes.dut.reference_layer.basic.type2),.cell_type(scenes.dut.reference_layer.basic.cell_type),.local_x(scenes.dut.reference_layer.basic.local_x),.local_y(scenes.dut.reference_layer.basic.local_y),.next1(scenes.dut.reference_layer.basic.next1),.next2(scenes.dut.reference_layer.basic.next2),.hold(scenes.dut.reference_layer.basic.hold),.hold_visible(scenes.dut.reference_layer.basic.hold_visible),.next_type1(scenes.dut.reference_layer.basic.next_type1),.next_type2(scenes.dut.reference_layer.basic.next_type2),.hold_type(scenes.dut.reference_layer.basic.hold_type),.next_x(scenes.dut.reference_layer.basic.next_x),.next_y(scenes.dut.reference_layer.basic.next_y),.hold_x(scenes.dut.reference_layer.basic.hold_x),.hold_y(scenes.dut.reference_layer.basic.hold_y),.bounds1(scenes.dut.reference_layer.basic.bounds1),.bounds2(scenes.dut.reference_layer.basic.bounds2),.hold_conditions(scenes.dut.reference_layer.basic.hold_conditions),.hold_reserved(scenes.dut.reference_layer.basic.hold_reserved),.hold_actor2(scenes.dut.reference_layer.basic.hold_actor2),.hold_expire_flash(scenes.dut.reference_layer.basic.hold_expire_flash),.hold_reject_flash(scenes.dut.reference_layer.basic.hold_reject_flash),.feedback_clear_row(scenes.dut.reference_layer.basic.feedback_clear_row),.feedback_clear(scenes.dut.reference_layer.basic.feedback_clear),.feedback_clear_age(scenes.dut.reference_layer.basic.feedback_clear_age),.animation(scenes.dut.reference_layer.basic.animation),.rgb(golden_rgb),.hit(golden_hit));
 reg [31:0] seed=32'h20261028;integer n;
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  for(n=0;n<100008;n=n+1)begin
   @(negedge scenes.clk);
   if(n%997==0)scenes.configure_scene((n/997)%7);
   seed=seed*1664525+1013904223;scenes.set_pixel(seed%1280,(seed/1280)%720);
   @(posedge scenes.clk);#1;
   if(n>=8 && (golden_rgb!==scenes.dut.reference_layer.basic.rgb || golden_hit!==scenes.dut.reference_layer.basic.hit))begin
    $display("FAIL BASIC_RETIME n=%0d actual=%h golden=%h",n,scenes.dut.reference_layer.basic.rgb,golden_rgb);$finish;
   end
  end
  $display("ALL PASS BASIC_RETIME 100000 RANDOM_PIXELS SEVEN_MODES");$finish;
 end
endmodule
