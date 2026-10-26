`timescale 1ns/1ps
module number(input clka,input ena,input [9:0] addra,output [19:0] douta);
 assign douta=0;
endmodule
module mode_statistics_tb;
 reg clk=0,rst=0,idle=1,play=0,pause=0,finalize=0,clear=0;
 wire [19:0] score;wire [23:0] bcd;wire [15:0] time_bcd;wire [13:0] seconds;
 reg [19:0] line_value=0;wire [23:0] line_bcd;
 bin_to_bcd #(.WIDTH(20),.DIGITS(6)) line_digits(clk,rst,line_value,line_bcd);
 integer bad=0;
 always #5 clk=~clk;
 scoring s(.Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),
  .Idle(idle),.Playing(play),.Stop(pause),.Finalize(finalize),.switch_r_flag(1'b0),
  .clear_t_t(clear),.c_clear(5'd20),.speed_level(3'd7),.duo(1'b0),.counter(score),.bcd(bcd),.lit());
 timer #(.SECOND_CYCLES(3)) t(.Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),
  .Idle(idle),.Playing(play),.Stop(pause),.Finalize(finalize),.switch_r_flag(1'b0),
  .bcd(time_bcd),.seconds(seconds),.lit());
 task tick;begin @(posedge clk);#1;end endtask
 task check;input pass;input [8*80-1:0] msg;
 begin if(pass!==1)begin bad=bad+1;$display("FAIL %0s",msg);end end endtask
 initial begin
  #2;rst=0;#13;rst=1;repeat(3)tick;idle=0;play=1;
  @(negedge clk);s.counter=999990;clear=1;tick;clear=0;
  check(score==999999,"score preserves carry then saturates");
  clear=1;tick;clear=0;check(score==999999,"saturated score never wraps");
  @(negedge clk);t.counter3=9;t.counter2=9;t.counter1=5;t.counter0=8;
  repeat(12)tick;check(time_bcd==16'h9959 && seconds==5999,"time saturates at 99:59");
  finalize=1;repeat(40)tick;check(score==999999 && bcd==24'h999999 && seconds==5999,"final values remain stable and BCD agrees");
  line_value=65536;repeat(50)tick;check(line_bcd==24'h065536,"six-digit lines cross the old 16-bit boundary");
  line_value=999999;repeat(50)tick;check(line_bcd==24'h999999,"six-digit line BCD at display maximum");
  if(bad==0)$display("ALL PASS MODE_STATISTICS");else $display("FAILED MODE_STATISTICS %0d",bad);
  $finish;
 end
endmodule
