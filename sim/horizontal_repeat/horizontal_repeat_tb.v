`timescale 1ns/1ps




module horizontal_repeat_tb;
reg Clk_74M = 0;
reg Reset_n = 0;
reg active = 0;
reg left_p = 0;
reg right_p = 0;
reg left_held = 0;
reg right_held = 0;
wire left_out;
wire right_out;
integer bad = 0;
integer checks = 0;

always #5 Clk_74M = ~Clk_74M;

horizontal_repeat #(
.DAS_CNT(25'd5),
.ARR_CNT(25'd3)
) dut(
.Clk_74M(Clk_74M),
.Reset_n(Reset_n),
.active(active),
.left_p(left_p),
.right_p(right_p),
.left_held(left_held),
.right_held(right_held),
.left_out(left_out),
.right_out(right_out)
);

task chk;
input [8*56-1:0] name;
input integer got;
input integer exp;
begin
  checks = checks + 1;
  if(got !== exp)begin
    bad = bad + 1;
    $display("  FAIL %0s got=%0d exp=%0d", name, got, exp);
  end
  else
    $display("  ok   %0s = %0d", name, got);
end
endtask

task tick;
begin
  @(posedge Clk_74M);
  #1;
end
endtask

initial begin
  $display("=== horizontal_repeat 横向连发 ===");
  repeat(2) tick();
  Reset_n = 1;
  active = 1;
  tick();


  @(negedge Clk_74M);
  left_held = 1;
  left_p = 1;
  tick();
  chk("left first move immediate", left_out, 1);
  left_p = 0;
  @(negedge Clk_74M);
  chk("left DAS not yet 1", left_out, 0);
  tick();
  chk("left DAS not yet 2", left_out, 0);
  tick();
  chk("left DAS not yet 3", left_out, 0);
  tick();
  chk("left DAS not yet 4", left_out, 0);
  tick();
  tick();
  chk("left first repeat after DAS", left_out, 1);
  tick();
  chk("left ARR gap 1", left_out, 0);
  tick();
  chk("left ARR gap 2", left_out, 0);
  tick();
  chk("left second repeat after ARR", left_out, 1);


  @(negedge Clk_74M);
  left_held = 0;
  tick();
  chk("left release clears das", dut.timer_cnt, 0);
  chk("left release clears repeat", left_out, 0);
  chk("left release disarms", dut.armed, 0);


  @(negedge Clk_74M);
  left_held = 1;
  left_p = 1;
  tick();
  chk("left repress first move", left_out, 1);
  left_p = 0;
  @(negedge Clk_74M);
  tick();
  tick();
  tick();
  tick();
  chk("left repress waits DAS", left_out, 0);
  tick();
  chk("left repress repeat after DAS", left_out, 1);


  @(negedge Clk_74M);
  right_held = 1;
  right_p = 1;
  tick();
  chk("direction switch right immediate", right_out, 1);
  chk("direction switch left silent", left_out, 0);
  right_p = 0;
  @(negedge Clk_74M);
  left_held = 0;
  chk("direction switch resets das", dut.timer_cnt, 0);
  tick();
  tick();
  tick();
  tick();
  chk("right switch waits DAS", right_out, 0);
  tick();
  chk("right switch repeat after DAS", right_out, 1);


  @(negedge Clk_74M);
  active = 0;
  tick();
  chk("pause clears das", dut.timer_cnt, 0);
  chk("pause clears armed", dut.armed, 0);
  chk("pause blocks right output", right_out, 0);
  active = 1;
  tick();
  tick();
  chk("resume held key does not auto repeat", right_out, 0);
  chk("resume held key stays disarmed", dut.armed, 0);

  right_held = 0;
  tick();
  @(negedge Clk_74M);
  right_held = 1;
  right_p = 1;
  tick();
  chk("repress after resume immediate", right_out, 1);
  right_p = 0;
  @(negedge Clk_74M);
  active = 0;
  tick();
  chk("finalize/pause reset timer", dut.timer_cnt, 0);
  chk("finalize/pause reset das_done", dut.das_done, 0);

  if(bad == 0) $display("=== ALL PASS: %0d checks ===", checks);
  else         $display("=== FAILED %0d / %0d ===", bad, checks);
  $finish;
end
endmodule
