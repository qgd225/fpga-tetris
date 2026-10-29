`timescale 1ns/1ps
module ui_mission_dynamic_tb;
 reg clk=0,rst=0,campaign=1,blocked=0;always #5 clk=~clk;
 reg [10:0] x=1194,y=404;reg [3:0] locked=3;reg [4:0] age=0;reg [7:0] animation=0;
 wire [23:0] rgb,panel;wire hit;reg [23:0] steady;
 ui_mission_layer dut(.clk(clk),.reset_n(rst),.enable(1'b1),.duo(1'b1),.campaign(campaign),.choose(1'b0),.blocked(blocked),.x(x),.y(y),.locked(locked),.reserve_pulse(1'b0),.reserve_alarm(2'd0),.reserve_fill(8'd104),.animation(animation),.charge_left(age),.charge_percent(7'd42),.debris_percent(7'd37),.lit_top(10'd440),.panel_rgb(panel),.rgb(rgb),.hit(hit));
 task settle;begin repeat(5)@(negedge clk);end endtask
 task ck;input ok;input [511:0] label;begin if(ok!==1)begin $display("FAIL UI_DYNAMIC %0s rgb=%h",label,rgb);$finish;end end endtask
 initial begin
  repeat(4)@(negedge clk);rst=1;settle;ck(rgb==24'h040c13,"unlit glass is dark");
  age=10;settle;ck(rgb==24'hb5fbff,"charge scan crosses whole glass column");
  y=260;age=2;settle;ck(rgb==24'hb5fbff,"scan reaches the top chamber edge");
  y=404;age=0;settle;ck(rgb==24'h040c13,"scan expires without changing stored state");
  x=1108;y=66;age=0;settle;steady=rgb;age=16;settle;ck(hit && dut.pipe_orange && rgb==24'hffe39c && rgb!=steady,"event packet advances along original pipe surface");
  campaign=0;settle;ck(!hit,"endless has no charge conduit");
  campaign=1;age=0;x=1177;y=520;locked=7;animation=0;settle;steady=rgb;animation=32;settle;
  ck(rgb!=steady,"online rail breathes with animation phase");
  $display("ALL PASS UI_DYNAMIC PIPE_SCAN_BREATH_MODE");$finish;
 end
endmodule
