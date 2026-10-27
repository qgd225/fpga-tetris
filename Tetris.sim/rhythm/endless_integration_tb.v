`timescale 1ns/1ps
// End-to-end supply/time proof using actual horizontal-I inputs and real line commits.
module endless_integration_tb;
 reg clk=0,rst=0,idle=1,playing=0,l=0,r=0,hard=0,soft=0,rotate=0;
 reg [3:0] phase_tick=0;wire tick60=phase_tick==9;
 always #5 clk=~clk;
 always @(posedge clk)if(!rst || idle)phase_tick<=0;else if(playing)phase_tick<=tick60?0:phase_tick+1'b1;
 wire [18:0] elapsed;wire [13:0] seconds;wire [15:0] time_bcd;
 wire [2:0] time_speed,speed,batch_speed;wire [4:0] batch_n;
 wire [19:0] lines;wire [3:0] core;wire [1:0] story_phase;
 wire raw_over,done,quiet,commit,pending,result,success,finish,clear_busy,row_credit;
 wire [13:0] energy;wire waiting,failed;wire hold_all=waiting || failed || result;
 integer pieces=0,batches=0,bad=0,timeout,target,min_energy=5400;
 run_clock game_clock(clk,rst,idle,playing,1'b0,result,tick60,elapsed,seconds,time_bcd,time_speed);
 story_controller ctl(.batch_n(batch_n),.clk(clk),.reset_n(rst),.new_run(idle),.playing(playing),.paused(1'b0),.duo(1'b0),
  .campaign(1'b0),.level_id(2'd0),.debris_remaining(7'd0),.row_credit(row_credit),.batch_done(done),
  .engine_quiescent(quiet),.over_raw(raw_over || failed),.endless_speed(time_speed),.lines_total(lines),
  .story_speed(speed),.story_phase(story_phase),.core_locked(core),.batch_commit(commit),.finish_pending(finish),
  .result_valid(result),.result_success(success),.batch_pending(pending));
 reserve_timer supply(.clk(clk),.reset_n(rst),.new_run(idle),.playing(playing),.paused(1'b0),.campaign(1'b0),
  .finished(result),.tick(tick60),.batch_commit(commit),.batch_inflight(clear_busy || done || pending),.batch_n(batch_n),
  .reserve_ticks(energy),.waiting(waiting),.failed(failed));
 Playfield #(.MCNT(600),.MCNT_LAND(160),.MCNT_Drop(599),.LOCK_CYCLES(48),.CLEAR_STEP(51)) pf(
  .Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),.left_p_flag(l),.right_p_flag(r),
  .drop_r_flag(soft),.drop_en(hard),.rotate_p_flag(rotate),.switch_r_flag(1'b0),
  .Idle(idle),.Playing(playing),.Stop(1'b0),.Finalize(result),.mission_hold(hold_all),.story_speed(speed),
  .hint_enable(1'b0),.ui_tick(tick60),.hold_p_flag(1'b0),.score(20'd0),.time_sec(seconds),.duo(1'b0),
  .init_load(1'b0),.initial_mask(480'd0),.initial_total(7'd0),.left_p_flag2(1'b0),.right_p_flag2(1'b0),
  .drop_r_flag2(1'b0),.drop_en2(1'b0),.rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),
  .over(raw_over),.batch_done(done),.batch_n(batch_n),.batch_speed(batch_speed),.engine_quiescent(quiet),
  .clear_time(clear_busy),.clear_t_t(row_credit));
 always @(posedge clk)begin
  if(playing && energy<min_energy)min_energy=energy;
  if(commit)batches=batches+1;
 end
 task cycle;begin @(posedge clk);#1;end endtask
 task ck;input pass;input [8*100-1:0] label;begin if(pass!==1)begin bad=bad+1;if(bad<15)$display("FAIL ENDLESS %0s piece=%0d time=%0d",label,pieces,seconds);end end endtask
 initial begin
  force pf.rnd_type_t=3'd0;force pf.rnd_type_n=3'd0;force pf.rnd_type_t1=3'd0;force pf.rnd_type_n1=3'd0;
  repeat(3)cycle;rst=1;repeat(35)cycle;idle=0;playing=1;repeat(10)cycle;
  while(seconds<340 && !result && pieces<400)begin
   @(negedge clk);rotate=1;cycle;@(negedge clk);rotate=0;repeat(4)cycle;
   ck(pf.rot==1,"real ROM I piece rotates horizontally");
   target=(pieces%5)*4;timeout=0;
   while(pf.counter_c!=target && timeout<80)begin
    @(negedge clk);l=pf.counter_c>target;r=pf.counter_c<target;cycle;
    @(negedge clk);l=0;r=0;repeat(3)cycle;timeout=timeout+1;
   end
   ck(pf.counter_c==target,"horizontal inputs reach row fill position");
   @(negedge clk);hard=1;repeat(610)cycle;@(negedge clk);hard=0;soft=1;cycle;soft=0;repeat(100)cycle;
   timeout=0;while((!quiet || pf.counter_r!=0 || pf.lock_counter!=0) && timeout<15000)begin cycle;timeout=timeout+1;end
   ck(quiet && !failed && !raw_over,"supply maintained by actual line batches");pieces=pieces+1;
  end
  ck(seconds>=340 && elapsed>=20400,"continuous real gameplay passes 315 seconds");
  ck(speed==7 && time_speed==7 && !result && !success,"endless stays live at last speed");
  ck(lines>=40 && batches>=40 && min_energy>0,"real clears sustain supply beyond both old targets");
  release pf.rnd_type_t;release pf.rnd_type_n;release pf.rnd_type_t1;release pf.rnd_type_n1;
  if(bad==0)$display("ALL PASS ENDLESS_INTEGRATION seconds=%0d pieces=%0d batches=%0d lines=%0d min_energy_ticks=%0d",seconds,pieces,batches,lines,min_energy);
  else $display("FAILED ENDLESS_INTEGRATION %0d",bad);
  $finish;
 end
 initial begin #100000000;$display("FAILED ENDLESS_INTEGRATION timeout");$finish;end
endmodule
