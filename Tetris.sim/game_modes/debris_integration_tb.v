`timescale 1ns/1ps
// Legal vertical-I sequence; only the cosmetic lock timer is accelerated.
module Tetromino(input clka,input [4:0] addra,output [31:0] douta);
 assign douta=32'h00010203;
endmodule
module weiyibiao(input clka,input [4:0] addra,output [7:0] douta);
 assign douta=0;
endmodule
module debris_integration_tb;
 reg clk=0,rst=0,start=0,idle=1,load=0,playing=0,duo=0;
 reg [1:0] level=0;reg [15:0] seed=1;
 reg l=0,r=0,hard=0,release_drop=0;
 wire ready,quiet,over,done;wire [479:0] initial_mask,board,debris;
 wire [6:0] remaining;wire [4:0] batch_n;wire [2:0] layout;
 integer bad=0,cfg,variant,c,steps,timeout,target,initial_total,half,saw_half;
 always #5 clk=~clk;
 story_debris loader(.clk(clk),.reset_n(rst),.start(start),.campaign(1'b1),.duo(duo),
  .level_id(level),.seed(seed),.ready(ready),.initial_mask(initial_mask),.debris_seed(),.layout_id(layout));
 Playfield #(.MCNT(3),.MCNT_LAND(3),.MCNT_Drop(1000000),.CLEAR_STEP(1)) pf(
  .Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),.left_p_flag(l),.right_p_flag(r),
  .drop_r_flag(release_drop),.drop_en(hard),.rotate_p_flag(1'b0),.switch_r_flag(1'b0),
  .Idle(idle),.Playing(playing),.Stop(1'b0),.Finalize(1'b0),.mission_hold(1'b0),.story_speed(3'd0),
  .hint_enable(1'b0),.hold_p_flag(1'b0),.score(20'd0),.time_sec(14'd0),.duo(duo),
  .init_load(load),.initial_mask(initial_mask),.initial_total(initial_total[6:0]),
  .debris_mask(debris),.debris_remaining(remaining),.left_p_flag2(1'b0),.right_p_flag2(1'b0),
  .drop_r_flag2(1'b0),.drop_en2(1'b0),.rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),
  .state(board),.over(over),.batch_done(done),.batch_n(batch_n),.engine_quiescent(quiet));
 always @(negedge clk) if(playing && pf.lock_counter==1)pf.lock_counter=5939998;
 always @(posedge clk) if(playing && remaining>0 && remaining<=half)saw_half=1;
 function integer count_debris;input [479:0] bits;integer k;begin count_debris=0;for(k=0;k<480;k=k+1)count_debris=count_debris+bits[k];end endfunction
 task tick;begin @(posedge clk);#1;end endtask
 task check;input pass;input [8*90-1:0] msg;
 begin if(pass!==1)begin bad=bad+1;$display("FAIL %0s cfg=%0d layout=%0d left=%0d",msg,cfg,layout,remaining);end end endtask
 initial begin
  for(cfg=0;cfg<8;cfg=cfg+1)for(variant=0;variant<8;variant=variant+1)begin
   playing=0;idle=1;rst=0;start=0;load=0;l=0;r=0;hard=0;release_drop=0;
   duo=cfg/4;level=cfg%4;seed=2*variant+1;saw_half=0;
   initial_total=duo?(level==0?31:level==1?48:level==2?66:85):(level==0?25:level==1?39:level==2?54:70);
   half=level==0?(duo?16:13):(2*initial_total+4)/5;
   repeat(3)tick;rst=1;start=1;tick;start=0;repeat(26)tick;
   load=1;tick;load=0;repeat(30)tick;
   check(board===initial_mask && debris===initial_mask && remaining==initial_total,"initial field and mask match");
   idle=0;playing=1;repeat(100)tick;steps=0;
   while(remaining!=0 && steps<48 && !over)begin
    // Move below the stationary second player's spawn area before translating.
    repeat(4)begin @(negedge clk);release_drop=1;tick;@(negedge clk);release_drop=0;tick;end
    target=-1;
    for(c=0;c<(duo?24:20);c=c+1)if(!board[c*20+19] && target<0)target=c;
    check(target>=0,"bottom row exposes a fillable column");
    timeout=0;
    while(pf.counter_c!=target && timeout<80)begin
     @(negedge clk);l=pf.counter_c>target;r=pf.counter_c<target;tick;
     @(negedge clk);l=0;r=0;repeat(3)tick;timeout=timeout+1;
    end
    check(pf.counter_c==target,"horizontal inputs reach target");
    repeat(100)tick;@(negedge clk);hard=1;repeat(6)tick;
    @(negedge clk);hard=0;release_drop=1;tick;release_drop=0;
    repeat(180)tick;steps=steps+1;
    check(count_debris(debris)==remaining,"stable mask popcount equals committed remaining");
    check((debris & ~board)==0,"remaining mask never occupies an empty cell");
   end
   check(!over && remaining==0,"legal I-piece sequence clears all debris");
   check(debris==0,"final debris mask empty");
   check(saw_half,"HALF actually reachable through engine moves");
   $display("DEBRIS_WITNESS cfg=%0d layout=%0d seed=%0d pieces=%0d HALF=%0d left=%0d",cfg,layout,seed,steps,saw_half,remaining);
  end
  if(bad==0)$display("ALL PASS DEBRIS_INTEGRATION layouts=64");else $display("FAILED DEBRIS_INTEGRATION %0d",bad);
  $finish;
 end
 initial begin #50000000;$display("FAILED DEBRIS_INTEGRATION timeout");$finish;end
endmodule
