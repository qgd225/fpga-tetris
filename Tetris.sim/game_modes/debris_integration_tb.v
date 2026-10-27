`timescale 1ns/1ps
// Real type/rotation ROM; controlled future-piece stream, never forced board state.
module Tetromino(input clka,input [4:0] addra,output reg [31:0] douta);
 reg [31:0] words[0:27];initial $readmemh("D:/vivado_project/Tetris/temporary/sim/game_modes/build/shape_reference.mem",words);
 always @(posedge clka)douta<=words[addra];
endmodule
module weiyibiao(input clka,input [4:0] addra,output reg [7:0] douta);
 reg [31:0] words[0:27];initial $readmemh("D:/vivado_project/Tetris/temporary/sim/game_modes/build/offset_reference.mem",words);
 always @(posedge clka)douta<=words[addra][7:0];
endmodule
module debris_integration_tb;
 reg clk=0,rst=0,start=0,idle=1,load=0,playing=0,duo=0;
 reg [1:0] level=0;reg [15:0] seed=1;
 reg l=0,r=0,hard=0,release_drop=0,l2=0,r2=0,hard2=0,release_drop2=0;reg actor2=0;reg [3:0] tick_phase=0;
 wire ui_tick=tick_phase==9;
 always @(posedge clk)if(!rst || idle)tick_phase<=0;else if(playing)tick_phase<=ui_tick?0:tick_phase+1'b1;
 wire ready,quiet,over,done;wire [479:0] initial_mask,board,debris;
 wire [6:0] remaining;wire [4:0] batch_n;wire [2:0] layout;
 reg [7:0] columns[0:11519],expected[0:11519],lengths[0:63];
 integer bad=0,cfg,variant,steps,timeout,target,initial_total,half,saw_half,index,travel_row;
 always #5 clk=~clk;
 story_debris loader(.clk(clk),.reset_n(rst),.start(start),.campaign(1'b1),.duo(duo),
  .level_id(level),.seed(seed),.ready(ready),.initial_mask(initial_mask),.debris_seed(),.layout_id(layout));
 // 600 symbolic clocks/second: all timing ratios and the final HOLD limits remain active.
 Playfield #(.MCNT(600),.MCNT_LAND(160),.MCNT_Drop(599),.LOCK_CYCLES(48),.CLEAR_STEP(51)) pf(
  .Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),.left_p_flag(l),.right_p_flag(r),
  .drop_r_flag(release_drop),.drop_en(hard),.rotate_p_flag(1'b0),.switch_r_flag(1'b0),
  .Idle(idle),.Playing(playing),.Stop(1'b0),.Finalize(1'b0),.mission_hold(1'b0),.story_speed(3'd0),
  .hint_enable(1'b0),.ui_tick(ui_tick),.hold_p_flag(1'b0),.score(20'd0),.time_sec(14'd0),.duo(duo),
  .init_load(load),.initial_mask(initial_mask),.initial_total(initial_total[6:0]),
  .debris_mask(debris),.debris_remaining(remaining),.left_p_flag2(l2),.right_p_flag2(r2),
  .drop_r_flag2(release_drop2),.drop_en2(hard2),.rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),
  .state(board),.over(over),.batch_done(done),.batch_n(batch_n),.engine_quiescent(quiet));
 function integer count_debris;input [479:0] bits;integer k;begin count_debris=0;for(k=0;k<480;k=k+1)count_debris=count_debris+bits[k];end endfunction
 task tick;begin @(posedge clk);#1;end endtask
 task check;input pass;input [8*90-1:0] msg;
 begin if(pass!==1)begin bad=bad+1;if(bad<16)$display("FAIL %0s cfg=%0d layout=%0d left=%0d step=%0d r1=%0d r2=%0d lock1=%0d lock2=%0d",msg,cfg,layout,remaining,steps,pf.counter_r,pf.counter_r2,pf.lock_counter,pf.lock_counter2);end end endtask
 initial begin
  $readmemh("D:/vivado_project/Tetris/temporary/sim/game_modes/build/witness_columns.mem",columns);
  $readmemh("D:/vivado_project/Tetris/temporary/sim/game_modes/build/witness_remaining.mem",expected);
  $readmemh("D:/vivado_project/Tetris/temporary/sim/game_modes/build/witness_lengths.mem",lengths);
  // This selects an explicit legal I stream; the active-piece ROM and engine are unchanged.
  force pf.rnd_type_t=3'd0;force pf.rnd_type_n=3'd0;force pf.rnd_type_t1=3'd0;force pf.rnd_type_n1=3'd0;
  for(cfg=0;cfg<8;cfg=cfg+1)for(variant=0;variant<8;variant=variant+1)begin
   playing=0;idle=1;rst=0;start=0;load=0;l=0;r=0;hard=0;release_drop=0;l2=0;r2=0;hard2=0;release_drop2=0;
   duo=cfg/4;level=cfg%4;seed=2*variant+1;saw_half=0;steps=0;
   initial_total=duo?(level==0?31:level==1?48:level==2?66:85):(level==0?25:level==1?39:level==2?54:70);
   half=level==0?(duo?16:13):(2*initial_total+4)/5;
   repeat(3)tick;rst=1;start=1;tick;start=0;repeat(26)tick;
   load=1;tick;load=0;repeat(30)tick;
   check(board===initial_mask && debris===initial_mask && remaining==initial_total,"initial field and mask match");
   check(layout==variant,"seed maps to recorded layout");idle=0;playing=1;repeat(30)tick;
   while(steps<lengths[cfg*8+variant] && !over)begin
    actor2=duo && steps%2!=0;
    travel_row=duo?(actor2?pf.counter_r:pf.counter_r2)+5:5;
    timeout=0;
    while((actor2?pf.counter_r2:pf.counter_r)<travel_row && timeout<16)begin @(negedge clk);if(actor2)release_drop2=1;else release_drop=1;tick;@(negedge clk);release_drop=0;release_drop2=0;repeat(2)tick;timeout=timeout+1;end
    index=(cfg*8+variant)*180+steps;target=columns[index];timeout=0;
    while((actor2?pf.counter_c2:pf.counter_c)!=target && timeout<80)begin
     @(negedge clk);if(actor2)begin l2=pf.counter_c2>target;r2=pf.counter_c2<target;end else begin l=pf.counter_c>target;r=pf.counter_c<target;end tick;
     @(negedge clk);l=0;r=0;l2=0;r2=0;repeat(3)tick;timeout=timeout+1;
    end
    check((actor2?pf.counter_c2:pf.counter_c)==target,"legal inputs reach target column");
    @(negedge clk);if(actor2)hard2=1;else hard=1;repeat(610)tick;@(negedge clk);hard=0;hard2=0;if(actor2)release_drop2=1;else release_drop=1;tick;release_drop=0;release_drop2=0;repeat(100)tick;
    timeout=0;while((!quiet || (actor2?pf.counter_r2:pf.counter_r)!=0 || (actor2?pf.lock_counter2:pf.lock_counter)!=0) && timeout<15000)begin tick;timeout=timeout+1;end
    check(quiet,"batch settles within bounded scaled time");
    check(count_debris(debris)==remaining && (debris & ~board)==0,"committed debris count and occupancy agree");
    check(remaining==expected[index],"real engine matches recorded witness remaining");
    if(remaining!=0 && remaining<=half)saw_half=1;
    steps=steps+1;
   end
   check(!over && remaining==0 && debris==0,"recorded legal sequence clears all debris");check(saw_half,"HALF reachable in real engine");
   $display("DEBRIS_WITNESS_V2 cfg=%0d layout=%0d pieces=%0d HALF=%0d remaining=%0d",cfg,layout,steps,saw_half,remaining);
  end
  release pf.rnd_type_t;release pf.rnd_type_n;release pf.rnd_type_t1;release pf.rnd_type_n1;
  if(bad==0)$display("ALL PASS DEBRIS_INTEGRATION layouts=64 version=2 final_hold_limits=active");else $display("FAILED DEBRIS_INTEGRATION %0d",bad);
  $finish;
 end
 initial begin #1000000000;$display("FAILED DEBRIS_INTEGRATION timeout");$finish;end
endmodule
