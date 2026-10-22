`timescale 1ns/1ps

//============================================================
// 测试台：hold_gesture_tb
// 测试目标：Hold 短按换块与长按智能提示手势回归。
//============================================================
module hold_gesture_tb;
reg Clk=0, Rst=0;
reg board_hold=0, pc_hold=0, legacy_hold=0, duo=0;
wire held = board_hold | pc_hold;
wire short_pulse, long_level, routed_hold, hint_show;
reg long_d, hint_latched;
integer bad=0;

always #5 Clk=~Clk;

hold_gesture #(.HOLD_LONG_CNT(25'd300)) dut(
.Clk_74M(Clk), .Reset_n(Rst), .held(held),
.short_pulse(short_pulse), .long_level(long_level)
);

// 与 Tetris 顶层相同: 第一次长按打开提示, 再次长按关闭
assign routed_hold = duo ? legacy_hold : short_pulse;
assign hint_show = !duo && hint_latched;
always@(posedge Clk or negedge Rst)begin
if(!Rst)begin
long_d <= 1'b0;
hint_latched <= 1'b0;
end
else begin
long_d <= long_level;
if(duo)
hint_latched <= 1'b0;
else if(long_level && !long_d)
hint_latched <= ~hint_latched;
end
end

task chk;
input [8*44-1:0] name;
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

task long_press_board;
begin
  board_hold=1; hold_cycles(300); hold_cycles(1);
  board_hold=0; @(posedge Clk); #1;
end
endtask

task long_press_pc;
begin
  pc_hold=1; hold_cycles(300); hold_cycles(1);
  pc_hold=0; @(posedge Clk); #1;
end
endtask

initial begin
  $display("=== hold_gesture: 299/300 周期、长按开关与板载/PC 合并 ===");
  reset_dut;
  board_hold=1;
  hold_cycles(299);
  chk("299 cycles no long", long_level, 0);
  hold_cycles(1);
  chk("300 cycles long high", long_level, 1);
  hold_cycles(1);
  chk("first long opens hint", hint_show, 1);
  board_hold=0; @(posedge Clk); #1;
  chk("release keeps hint latched", hint_show, 1);
  chk("long release no short", short_pulse, 0);
  chk("long release no hold", routed_hold, 0);
  long_press_board;
  chk("second long closes hint", hint_show, 0);
  chk("second long no short", short_pulse, 0);

  reset_dut;
  long_press_board;
  chk("board long opens hint", hint_show, 1);
  hold_cycles(80);
  chk("holding does not retoggle", hint_show, 1);
  long_press_board;
  chk("board long toggles off", hint_show, 0);

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
  hold_cycles(1);
  chk("PC long opens hint", hint_show, 1);
  pc_hold=0; @(posedge Clk); #1;
  chk("PC release keeps hint", hint_show, 1);
  long_press_pc;
  chk("PC second long closes hint", hint_show, 0);
  chk("PC release no hold", routed_hold, 0);

  reset_dut;
  long_press_board;
  chk("hint on before duo", hint_show, 1);
  duo=1; legacy_hold=1; repeat(2) @(posedge Clk); #1;
  chk("duo forces hint off", hint_show, 0);
  chk("duo legacy hold direct", routed_hold, 1);
  board_hold=1; hold_cycles(301);
  chk("duo long never shows hint", hint_show, 0);
  chk("duo gesture does not alter legacy hold", routed_hold, 1);
  legacy_hold=0; board_hold=0; @(posedge Clk); #1;
  chk("duo legacy hold release", routed_hold, 0);

  if(bad==0)$display("=== ALL PASS ==="); else $display("=== FAILED %0d ===",bad);
  $finish;
end
endmodule
