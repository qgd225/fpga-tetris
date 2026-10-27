`timescale 1ns/1ps
module ui_contract_tb;
 reg clk=0,rst=0,duo=1,finalize=0,success=0,charge_done=0;reg [6:0] debris=12;reg [10:0] x=0,y=0;
 wire [23:0] rgb;integer bad=0;
 always #5 clk=~clk;
 story_ui dut(.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(1'b0),.Idle(1'b0),.Playing(!finalize),.Stop(1'b0),.Finalize(finalize),
  .debris_percent(7'd0),.success_age(7'd72),.campaign(1'b1),.ship_select(1'b0),.debris_cell(1'b0),.level_id(2'd3),.result_option(2'd0),.debris_left(debris),
  .menu_offset(2'd0),.reserve_alarm(2'd0),.hold_blocks(2'd2),.reserve_fill(8'd104),.hold_life(11'd1500),.hold_ready(1'b0),.hold_visible(1'b1),.hold_expire_flash(1'b0),.hold_reject_flash(1'b0),
  .hint_quota(3'd1),.hint_capacity(3'd3),.hint_life(10'd720),.hint_active(1'b1),.hold_reserved(1'b1),.hold_actor2(1'b1),.hold_conditions(3'b101),.rank(2'd2),.average_tenths(8'd28),.charge_done(charge_done),.charge_fill(5'd10),.debris_fill(5'd8),
  .recharge_age(6'd0),.recharge_units(10'd0),.speed_flash(6'd0),.reserve_pulse(1'b0),.recharge_capped(1'b0),.recharge_no_gain(1'b0),.comms_visible(1'b0),.comms_id(3'd0),.choose_cnt(4'd3),.phase(2'd0),.danger(2'd0),.locked(4'd2),.success(success),.result_ready(1'b1),
  .speed(3'd3),.lines_bcd(24'h000018),.score_bcd(24'd0),.time_bcd(16'h0312),.animation(8'd0),.star_drift(11'd0),.charge_left(5'd0),.bounds1(44'd0),.bounds2(44'd0),.feedback_clear_age(5'd0),.feedback_clear_row(1'b0),.feedback_lock(1'b0),.feedback_hard_left(1'b0),.feedback_hard_right(1'b0),.feedback_clear(1'b0),.feedback_sides(4'd0),.feedback_inset(4'd0),.feedback_rotation(2'd0),
  .in_field(1'b0),.cell_visible(1'b0),.local_x(5'd0),.local_y(5'd0),.occupied(1'b0),.piece1(1'b0),.piece2(1'b0),.ghost1(1'b0),.ghost2(1'b0),.hint_hit(1'b0),.type1(3'd0),.type2(3'd0),.cell_type(3'd0),.hint_type(3'd0),.owner(1'b0),.next1(1'b0),.next2(1'b0),.hold(1'b0),.next_slot(1'b0),.hold_slot(1'b0),.next_type1(3'd0),.next_type2(3'd0),.hold_type(3'd0),.next_x(5'd0),.next_y(5'd0),.hold_x(5'd0),.hold_y(5'd0),.rgb(rgb));
 task at;input integer px,py;begin @(negedge clk);x=px;y=py;repeat(6)@(posedge clk);#1;end endtask
 task ck;input pass;input [8*100-1:0] msg;begin if(pass!==1)begin bad=bad+1;$display("FAIL UI_CONTRACT %0s",msg);end end endtask
 initial begin
  repeat(3)@(posedge clk);rst=1;
  at(992,156);ck(dut.text_regions[8],"P2 NEXT remains in original header slot");
  at(1090,326);ck(dut.text_regions[26] && !dut.text_regions[7],"campaign speed sits next to core without CORE descriptor overlap");
  at(354,82);ck(dut.text_regions[28] && dut.dynamic_kind==6,"charge task uses mission credit descriptor");
  at(354,114);ck(dut.text_regions[37] && dut.dynamic_kind==13,"debris task is adjacent to charge");
  at(1080,388);ck(!dut.text_regions[38],"duo has no hint budget label");duo=0;at(1080,388);ck(dut.text_regions[38] && dut.dynamic_kind==16,"solo hint shows remaining and variable capacity by core");
  at(400,86);ck(!dut.task_charge_strike,"unfinished charge has no strike");charge_done=1;at(400,86);ck(dut.task_charge_strike,"completed charge has strike");
  debris=0;at(400,118);ck(dut.task_debris_strike,"cleared debris has independent strike");
  finalize=1;success=1;at(500,496);ck(dut.dynamic_kind==18 && !dut.text_regions[37],"victory shows rank and average, no debris task");
  success=0;debris=12;at(500,496);ck(dut.dynamic_kind==13,"failure shows remaining debris instead of rank");
  at(448,400);ck(dut.dynamic_kind==6,"result charge uses same credit source, never actual-cleared total");
  at(400,668);ck(!dut.text_regions[34],"campaign result does not repeat bottom statistics");
  if(bad==0)$display("ALL PASS UI_CONTRACT");else $display("FAILED UI_CONTRACT %0d",bad);$finish;
 end
endmodule
