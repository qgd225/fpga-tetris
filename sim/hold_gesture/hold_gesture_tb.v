`timescale 1ns/1ps
module hold_gesture_tb;
reg Clk=0, Rst=0;
reg board_hold=0, pc_hold=0, legacy_hold=0, duo=0;
wire held = board_hold | pc_hold;
wire short_pulse, long_level, routed_hold, hint_show;
integer bad=0;

always #5 Clk=~Clk;

hold_gesture #(.HOLD_LONG_CNT(25'd300)) dut(
.Clk_74M(Clk), .Reset_n(Rst), .held(held),
.short_pulse(short_pulse), .long_level(long_level)
);
// 与 Tetris 顶层相同的路由: 双人保留旧脉冲, 单人使用新手势
assign routed_hold = duo ? legacy_hold : short_pulse;
assign hint_show = !duo && long_level;

task chk;
input [8*40-1:0] name;
input integer got;
input integer exp;
begin
  if(got !== exp)begin
    $display("  FAIL %0s got=%0d exp=%0d", name, got, exp);
    bad = bad + 1;
  end
  else
    $display("  ok   %0s = %0d", name, got);
end
endtask

task reset_dut;
begin
  Rst=0; board_hold=0; pc_hold=0; legacy_hold=0; duo=0;
  repeat(4) @(posedge Clk); Rst=1; repeat(2) @(posedge Clk); #1;
end
endtask

task hold_cycles;
input integer n;
integer i;
begin
  for(i=0;i<n;i=i+1) @(posedge Clk);
  #1;
end
endtask

initial begin
  $display("=== hold_gesture: 299/300 周期与板载/PC 合并 ===");
  reset_dut;
  board_hold=1;
  hold_cycles(299);
  chk("299 cycles no long", long_level, 0);
  hold_cycles(1);
  chk("300 cycles long high", long_level, 1);
  chk("long shows hint", hint_show, 1);
  board_hold=0; @(posedge Clk); #1;
  chk("long release clears level", long_level, 0);
  chk("long release no short", short_pulse, 0);
  chk("long release no hold", routed_hold, 0);

  reset_dut;
  pc_hold=1; hold_cycles(120); pc_hold=0; @(posedge Clk); #1;
  chk("PC short pulse", short_pulse, 1);
  chk("PC short routes hold", routed_hold, 1);
  chk("PC short no hint", hint_show, 0);

  reset_dut;
  board_hold=1; hold_cycles(80); board_hold=0; @(posedge Clk); #1;
  chk("board short pulse", short_pulse, 1);

  reset_dut;
  pc_hold=1; hold_cycles(299);
  chk("PC 299 no long", long_level, 0);
  hold_cycles(1);
  chk("PC 300 long", long_level, 1);
  pc_hold=0; @(posedge Clk); #1;
  chk("PC release no hold", routed_hold, 0);

  reset_dut;
  duo=1; legacy_hold=1; #1;
  chk("duo legacy hold direct", routed_hold, 1);
  board_hold=1; hold_cycles(300);
  chk("duo long never shows hint", hint_show, 0);
  chk("duo gesture does not alter legacy hold", routed_hold, 1);
  legacy_hold=0; board_hold=0; @(posedge Clk); #1;
  chk("duo legacy hold release", routed_hold, 0);

  if(bad==0)$display("=== ALL PASS ==="); else $display("=== FAILED %0d ===",bad);
  $finish;
end
endmodule
