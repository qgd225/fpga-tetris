`timescale 1ns/1ps
module hold_engine_tb;
 reg clk=0,rst=0,idle=1,play=0,req=0,hard=0,soft=0,duo=0,req2=0,hard2=0,soft2=0,rotate=0,l=0,r=0;
 reg [3:0] tick_phase=0;wire tick60=tick_phase==9;
 always @(posedge clk)if(!rst || idle)tick_phase<=0;else if(play)tick_phase<=tick60?0:tick_phase+1'b1;
 wire bank_valid,reserved,quiet,over;wire [2:0] bank;wire [479:0] board;
 integer bad=0,timeout,lands=0,takes=0,takes2=0,piece_idx,target,clear_batches=0;reg [2:0] saved_next;
 always #5 clk=~clk;
 Playfield #(.MCNT(600),.MCNT_LAND(160),.MCNT_Drop(599),.LOCK_CYCLES(48),.CLEAR_STEP(51)) pf(
  .Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),.left_p_flag(l),.right_p_flag(r),.drop_r_flag(soft),.drop_en(hard),.rotate_p_flag(rotate),.switch_r_flag(1'b0),
  .Idle(idle),.Playing(play),.Stop(1'b0),.Finalize(1'b0),.mission_hold(1'b0),.story_speed(3'd0),.hint_enable(1'b0),.ui_tick(tick60),.hold_p_flag(req),.score(20'd0),.time_sec(14'd0),.duo(duo),
  .init_load(1'b0),.initial_mask(480'd0),.initial_total(7'd0),.left_p_flag2(1'b0),.right_p_flag2(1'b0),.drop_r_flag2(soft2),.drop_en2(hard2),.rotate_p_flag2(1'b0),.hold_p_flag2(req2),
  .hold_valid(bank_valid),.hold_type(bank),.hold_reserved(reserved),.engine_quiescent(quiet),.over(over),.state(board));
 always @(posedge clk)if(rst && play)begin
  if(pf.land_pulse)lands=lands+1;
  if(pf.hold_up && pf.hold_swap_valid)begin
   takes=takes+1;
   $display("CLAIM_DELIVERY type=%0d bank=%0d swap=%0d stop=%0d board_busy=%0d clear=%0d row=%0d",pf.type,bank,pf.hold_swap_type,pf.player_stop1,pf.board_busy,pf.clear_time,pf.counter_r);
  end
  if(pf.hold_up2 && pf.hold_swap_valid)takes2=takes2+1;
  if(pf.batch_done)clear_batches=clear_batches+1;
  if((pf.hold_up || pf.hold_up2) && pf.hold_swap_valid && pf.clear_time)begin
   bad=bad+1;$display("FAIL HOLD_ENGINE claim delivered before real compression ends");
  end
 end
 task cycle;begin @(posedge clk);#1;end endtask
 task ck;input pass;input [8*110-1:0] msg;begin if(pass!==1)begin bad=bad+1;$display("FAIL HOLD_ENGINE %0s type=%0d next=%0d r=%0d lock=%0d wait=%0d",msg,pf.type,pf.type_t,pf.counter_r,pf.lock_counter,pf.take_wait1);end end endtask
 task press;begin @(negedge clk);req=1;cycle;@(negedge clk);req=0;repeat(3)cycle;end endtask
 initial begin
  force pf.rnd_type_t=3'd2;force pf.rnd_type_n=3'd0;force pf.rnd_type_t1=3'd0;force pf.rnd_type_n1=3'd0;
  repeat(3)cycle;rst=1;repeat(30)cycle;idle=0;play=1;repeat(30)cycle;
  force pf.rnd_type_n=3'd1;press;ck(bank_valid && bank==2 && pf.type==0 && pf.type_t==1,"store removes current and consumes NEXT once");
  saved_next=pf.type_t;press;ck(reserved && pf.type==0 && pf.type_t==saved_next,"claim during store cooldown leaves active and NEXT unchanged");
  @(negedge clk);hard=1;repeat(610)cycle;@(negedge clk);hard=0;soft=1;cycle;soft=0;
  timeout=0;while((reserved || takes==0 || !quiet) && timeout<10000)begin cycle;timeout=timeout+1;end
  ck(!reserved && !bank_valid && pf.type==2,"actual lock retirement delivers bank and empties HOLD");
  ck(pf.type_t==saved_next && takes==1 && lands==1,"retrieval consumes no NEXT and emits exactly one spawn");
  ck(board!=0 && !over,"landed active piece remains on actual board");
  repeat(100)cycle;ck(takes==1,"delivery never repeats");
  play=0;idle=1;rst=0;duo=1;repeat(3)cycle;rst=1;force pf.rnd_type_n=3'd0;force pf.rnd_type_n1=3'd6;repeat(30)cycle;idle=0;play=1;repeat(30)cycle;
  press;ck(bank_valid && bank==2,"duo P1 stores shared bank");saved_next=pf.type_t2;
  @(negedge clk);req2=1;cycle;@(negedge clk);req2=0;repeat(3)cycle;ck(reserved && pf.hold_owner2,"duo P2 owns claim during store cooldown");
  @(negedge clk);hard2=1;repeat(610)cycle;@(negedge clk);hard2=0;soft2=1;cycle;soft2=0;
  timeout=0;while((reserved || takes2==0 || !quiet) && timeout<10000)begin cycle;timeout=timeout+1;end
  ck(!reserved && !bank_valid && pf.type2==2 && pf.type==0,"duo P2 receives bank without replacing P1 active piece");
  ck(pf.type_t2==saved_next && takes2==1,"duo P2 NEXT preserved and claim delivered once");
  play=0;idle=1;rst=0;duo=0;force pf.rnd_type_n=3'd0;force pf.rnd_type_n1=3'd0;repeat(3)cycle;rst=1;repeat(30)cycle;idle=0;play=1;repeat(30)cycle;press;ck(bank==2,"clear scenario starts with known stored type");
  for(piece_idx=0;piece_idx<5;piece_idx=piece_idx+1)begin
   if(piece_idx==3)force pf.rnd_type_n=3'd6;
   @(negedge clk);rotate=1;cycle;@(negedge clk);rotate=0;repeat(4)cycle;
   target=piece_idx*4;timeout=0;
   while(pf.counter_c!=target && timeout<80)begin @(negedge clk);l=pf.counter_c>target;r=pf.counter_c<target;cycle;@(negedge clk);l=0;r=0;repeat(3)cycle;timeout=timeout+1;end
   ck(pf.counter_c==target,"real horizontal I reaches fill column");
   if(piece_idx==4)begin saved_next=pf.type_t;press;ck(reserved,"claim registered before the row-completing landing");end
   @(negedge clk);hard=1;repeat(610)cycle;@(negedge clk);hard=0;soft=1;cycle;soft=0;repeat(100)cycle;
   timeout=0;while((!quiet || reserved && piece_idx==4 || pf.counter_r!=0 || pf.lock_counter!=0 || pf.hold_up) && timeout<15000)begin cycle;timeout=timeout+1;end
  end
  ck(clear_batches==1 && board==0,"five real I pieces clear and compress an actual row");
  $display("CLAIM_CLEAR_END valid=%0d reserved=%0d type=%0d swap=%0d saved=%0d takes=%0d",bank_valid,reserved,pf.type,pf.hold_swap_type,saved_next,takes);
  ck(!reserved && !bank_valid && pf.type==2 && pf.type_t==saved_next && saved_next==6,"claim delivers after actual clear while preserving queued NEXT");
  release pf.rnd_type_t;release pf.rnd_type_n;release pf.rnd_type_t1;release pf.rnd_type_n1;
  if(bad==0)$display("ALL PASS HOLD_ENGINE");else $display("FAILED HOLD_ENGINE %0d",bad);$finish;
 end
 initial begin #20000000;$display("FAILED HOLD_ENGINE timeout");$finish;end
endmodule
