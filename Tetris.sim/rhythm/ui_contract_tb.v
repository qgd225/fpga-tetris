`timescale 1ns/1ps
module ui_contract_tb;
 `include "ui_text_templates.vh"
 reg [8:0] templates[0:UI_TEXT_WORDS-1];reg [255:0] displayed;
 reg choose=0,ship_select=0;reg [1:0] window=0,level_id=3,alarm=0;
 reg show_comms=0;reg pulse=0,cap=0,no_gain=0;reg [5:0] popup_age=0;reg [9:0] popup_units=96;
 reg clk=0,rst=0,duo=1,finalize=0,success=0,charge_done=0;reg campaign=1;reg [23:0] credits_bcd=24'h000018;reg [6:0] debris=12;reg [10:0] x=0,y=0;
 wire [23:0] rgb;integer bad=0;
 always #5 clk=~clk;
 story_ui dut(.clear_credit(5'd0),.clear_credit_age(6'd0),.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(choose),.Idle(1'b0),.Playing(!finalize),.Stop(1'b0),.Finalize(finalize),
  .debris_percent(7'd0),.success_age(7'd72),.campaign(campaign),.ship_select(ship_select),.debris_cell(1'b0),.level_id(level_id),.result_option(2'd0),.debris_left(debris),
  .menu_offset(window),.reserve_alarm(alarm),.hold_blocks(2'd2),.reserve_fill(8'd104),.hold_life(11'd1500),.hold_ready(1'b0),.hold_visible(1'b1),.hold_expire_flash(1'b0),.hold_reject_flash(1'b0),
  .hint_quota(3'd1),.hint_capacity(3'd3),.hint_life(10'd720),.hint_active(1'b1),.hold_reserved(1'b1),.hold_actor2(1'b1),.hold_conditions(3'b101),.rank(2'd2),.average_tenths(8'd28),.charge_done(charge_done),.charge_fill(5'd10),.debris_fill(5'd8),
  .recharge_age(popup_age),.recharge_units(popup_units),.speed_flash(6'd0),.reserve_pulse(pulse),.recharge_capped(cap),.recharge_no_gain(no_gain),.comms_visible(show_comms),.comms_id(3'd0),.choose_cnt(4'd3),.phase(2'd0),.danger(2'd0),.locked(4'd2),.success(success),.result_ready(1'b1),
  .speed(3'd3),.lines_bcd(credits_bcd),.score_bcd(24'd0),.time_bcd(16'h0312),.animation(8'd0),.star_drift(11'd0),.charge_left(5'd0),.bounds1(44'd0),.bounds2(44'd0),.feedback_clear_age(5'd0),.feedback_clear_row(1'b0),.feedback_lock(1'b0),.feedback_hard_left(1'b0),.feedback_hard_right(1'b0),.feedback_clear(1'b0),.feedback_sides(4'd0),.feedback_inset(4'd0),.feedback_rotation(2'd0),
  .in_field(1'b0),.cell_visible(1'b0),.local_x(5'd0),.local_y(5'd0),.occupied(1'b0),.piece1(1'b0),.piece2(1'b0),.ghost1(1'b0),.ghost2(1'b0),.hint_hit(1'b0),.type1(3'd0),.type2(3'd0),.cell_type(3'd0),.hint_type(3'd0),.owner(1'b0),.next1(1'b0),.next2(1'b0),.hold(1'b0),.next_slot(1'b0),.hold_slot(1'b0),.next_type1(3'd0),.next_type2(3'd0),.hold_type(3'd0),.next_x(5'd0),.next_y(5'd0),.hold_x(5'd0),.hold_y(5'd0),.rgb(rgb));
 function [255:0] shown;
  input dummy;integer i;reg [8:0] word;
  begin for(i=0;i<32;i=i+1)begin
   word=templates[dut.reference_layer.text_id*32+i];
   shown[255-i*8-:8]=word[8]?dut.reference_layer.message[255-i*8-:8]:word[7:0];
  end end
 endfunction
 task at;input integer px,py;begin @(negedge clk);x=px;y=py;repeat(6)@(posedge clk);#1;displayed=shown(0);end endtask
 task ck;input pass;input [8*100-1:0] msg;begin if(pass!==1)begin bad=bad+1;$display("FAIL UI_CONTRACT %0s",msg);end end endtask
 initial begin
  $readmemh("ui_text_templates.mem",templates);repeat(3)@(posedge clk);rst=1;
  at(1020,165);ck(dut.reference_layer.text_valid && dut.reference_layer.text_x==1017 && dut.reference_layer.text_width==4,"P2 NEXT centered over preview");
  at(1010,330);ck(dut.reference_layer.text_valid && dut.reference_layer.text_y==326,"SPD baseline declared once");
  at(580,66);ck(dut.reference_layer.text_valid && dut.reference_layer.message[255-:16]==16'h3138,"charge reads credited total eighteen");
  at(580,100);ck(dut.reference_layer.text_valid && dut.reference_layer.message[255-:16]==16'h3132,"debris twelve beside task track");
  at(1040,250);ck(!dut.reference_layer.text_valid,"duo has no hint status words");
  duo=0;at(1040,250);ck(!dut.reference_layer.text_valid,"solo hint is graphical rather than status words");
  at(500,68);ck(!dut.reference_layer.force_paint,"unfinished task no completion strike");
  credits_bcd=24'h000045;at(500,68);ck(dut.reference_layer.force_paint,"real target credits activate strike");
  debris=0;at(500,103);ck(dut.reference_layer.force_paint,"debris completion strike independent");
  finalize=1;success=1;at(805,414);ck(dut.reference_layer.terminal_panel && dut.reference_layer.text_width==1 && dut.reference_layer.text_x==800,"result rank right aligned");
  success=0;debris=12;
  at(600,260);ck(displayed[255-:72]=="LINK LOST","failure title follows story specification");
  at(500,414);ck(displayed[255-:48]=="DEBRIS","failure reports remaining debris");
  at(740,414);ck(displayed[255-:56]=="12 LEFT","failure debris value right aligned");
  at(780,454);ck(!dut.reference_layer.text_valid,"failure has no rating or average row");
  at(758,334);ck(dut.reference_layer.text_width==5 && dut.reference_layer.text_x==752,"result charge shares credited source");
  credits_bcd=24'h000123;at(710,334);ck(displayed[255-:72]=="   123/36","result retains real over-target credited value");
  at(600,337);ck(dut.reference_layer.force_paint,"failed completed charge still struck");
  debris=0;at(500,417);ck(dut.reference_layer.force_paint,"failed completed debris still struck");
  campaign=0;at(500,374);ck(displayed[255-:40]=="LINES","endless result retains lines");
  at(500,414);ck(displayed[255-:32]=="TIME","endless result retains time");
  at(500,454);ck(!dut.reference_layer.text_valid,"endless result adds no speed statistic");
  at(670,550);ck(displayed[255-:32]=="MENU","endless result returns to menu");
  finalize=0;cap=1;popup_age=48;at(725,525);ck(displayed[255-:32]=="+096","recharge shows real supplied units");
  at(744,550);ck(displayed[255-:24]=="MAX","clipped recharge also reports max");
  no_gain=1;at(725,525);ck(displayed[255-:24]=="MAX","already full reports only max");
  no_gain=0;at(1194,443);ck(rgb==24'hb5fbff,"recharge stripe persists for eighteen UI ticks");
  popup_age=29;at(1194,443);ck(rgb==24'h26d7ec,"recharge stripe expires after short event");
  popup_age=0;alarm=2;pulse=1;at(1165,251);ck(rgb==24'hd8442e,"critical reserve uses real warning pulse");
  alarm=0;pulse=0;choose=1;ship_select=1;campaign=1;window=1;level_id=3;
  at(780,190);ck(displayed[255-:56]=="SHIP 01","first row fixed despite old window one");
  at(780,484);ck(displayed[255-:56]=="SHIP 04" && dut.reference_layer.text_ink==24'h7fe3ec,"fourth ship visible and selected in fourth row");
  level_id=2;at(780,386);ck(displayed[255-:56]=="SHIP 03" && dut.reference_layer.text_ink==24'h7fe3ec,"third ship stays in third row");
  level_id=1;at(780,288);ck(displayed[255-:56]=="SHIP 02" && dut.reference_layer.text_ink==24'h7fe3ec,"second ship stays in second row");
  level_id=0;window=0;at(780,190);ck(displayed[255-:56]=="SHIP 01","first ship fixed row");
  choose=0;ship_select=0;duo=0;campaign=1;debris=80;at(1160,600);
  ck(displayed[255-:48]=="LOCKED" && dut.reference_layer.text_x==1158 && dut.reference_layer.text_y==595,"status centered directly below translated mast");
  campaign=0;at(1160,600);ck(displayed[255-:56]=="RESERVE" && dut.reference_layer.text_x==1152,"reserve shares centered plate");
  at(176,90);ck(dut.reference_layer.text_pitch==8 && dut.reference_layer.text_x==170,"endless label clears complete ship nose");
  choose=0;ship_select=0;duo=1;campaign=0;at(1118,200);ck(!dut.reference_layer.mission.selected,"endless removes physical charge conduit");
  at(143,148);ck(rgb==24'h314b5f,"NEXT transparent chamfer reveals continuous hull");
  at(154,332);ck(rgb==24'h314b5f,"HOLD transparent chamfer reveals continuous hull");
  at(959,148);ck(rgb==24'h3a5064,"P2 transparent corner reveals side rail rather than black");
  show_comms=1;campaign=1;duo=1;at(570,175);
  ck(dut.reference_layer.dialog_x==552 && dut.reference_layer.text_x==570,"duo dialogue at field upper right");
  duo=0;at(522,175);ck(dut.reference_layer.dialog_x==504 && dut.reference_layer.text_x==522,"solo dialogue at field upper right");
  if(bad==0)$display("ALL PASS UI_CONTRACT");else $display("FAILED UI_CONTRACT %0d",bad);$finish;
 end
endmodule
