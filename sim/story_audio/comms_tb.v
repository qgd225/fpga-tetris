// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module comms_tb;
 reg clk=0,rst=0,Idle=1,choose=0,Playing=0,Stop=0,Finalize=0,restart=0,busy=0,done=0,success=0,ready=0,tick=0;
 reg [1:0] phase=0,danger=0;always #5 clk=~clk;
 wire start,cancel,visible,alarm;wire [2:0] id;
 integer errors=0,checks=0,k;
 story_comms dut(.clk(clk),.reset_n(rst),.Idle(Idle),.choose(choose),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),.restart(restart),
 .voice_busy(busy),.voice_done(done),.success(success),.result_ready(ready),.tick_60hz(tick),.phase(phase),.danger(danger),
 .voice_start(start),.voice_cancel(cancel),.comms_visible(visible),.comms_id(id),.alarm2_pulse(alarm));
 task cycle;begin @(negedge clk);#1;end endtask
 task check;input c;input[511:0]label;begin checks=checks+1;if(c!==1'b1)begin errors=errors+1;$display("FAIL comms %0s id=%0d",label,id);end end endtask
 task finish_voice;begin busy=0;done=1;cycle;done=0;cycle;end endtask
 task new_game;begin Idle=1;Playing=0;Finalize=0;success=0;ready=0;phase=0;danger=0;busy=0;done=0;cycle;Idle=0;Playing=1;cycle;end endtask
 initial begin
  cycle;cycle;rst=1;cycle;new_game;check(start && id==0,"opening once");
  repeat(12)cycle;check(!start,"startup reservation prevents duplicate before player busy");busy=1;
  phase=1;cycle;check(start && id==1,"phase response preempts opening");
  phase=2;cycle;check(!start && dut.pending_id==2,"same priority queues");phase=3;cycle;check(dut.pending_id==3,"only latest phase retained");
  finish_voice;check(start && id==3,"latest phase dispatches");busy=1;
  danger=2;cycle;check(start && id==4 && alarm,"severe alert preempts stage and shares FX event");
  danger=0;cycle;danger=2;cycle;check(!start && !alarm,"eight second cooldown suppresses duplicates");
  Stop=1;#1;check(!visible,"paused captions hidden");phase=1;cycle;check(!start,"paused queue stays frozen");Stop=0;cycle;
  Finalize=1;Playing=0;success=1;ready=0;cycle;check(cancel && !visible && !start,"quiet success cancels old voice");
  repeat(20)cycle;check(!start,"no success speech before presentation complete");ready=1;cycle;
  check(start && id==5 && !cancel,"success after presentation");busy=1;repeat(5)cycle;check(!start,"terminal only once");
  new_game;busy=1;phase=2;cycle;Finalize=1;Playing=0;success=0;cycle;
  check(start && id==6 && !dut.pending_valid,"failure replaces all outdated speech");
  busy=0;#1;check(!visible,"no silent tail");restart=1;cycle;check(cancel && !visible,"restart clears queue");restart=0;
  new_game;busy=1;danger=2;cycle;finish_voice;
  for(k=0;k<480;k=k+1)begin tick=1;cycle;tick=0;end
  danger=0;cycle;danger=2;cycle;check(start && id==4,"alert re-arms after eight seconds");
  if(errors==0)$display("ALL PASS STORY COMMS checks=%0d",checks);else $display("FAILED STORY COMMS errors=%0d",errors);
  $finish;
 end
endmodule
