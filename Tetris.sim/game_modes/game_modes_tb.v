`timescale 1ns/1ps
module game_modes_tb;
 reg clk=0,rst=0,start=0,campaign=0,duo=0,paused=0,playing=1;
 reg [1:0] level=0;
 reg [15:0] seed=0;
 wire ready;wire [479:0] mask;wire [15:0] actual_seed;wire [2:0] layout;
 reg credit=0,done=0,over=0,quiet=1;reg [6:0] left=0;
 wire [19:0] lines;wire [2:0] speed;wire [1:0] phase;wire [3:0] core;
 wire valid,success,commit,pending;
 integer bad=0,checks=0,i,j,k,c,y,total,count,expected,seen;
 reg [479:0] saved[0:7];
 always #5 clk=~clk;
 story_debris loader(clk,rst,start,campaign,duo,level,seed,ready,mask,actual_seed,layout);
 story_controller ctl(.clk(clk),.reset_n(rst),.new_run(start),.playing(playing),.paused(paused),
  .duo(duo),.campaign(campaign),.level_id(level),.debris_remaining(left),.row_credit(credit),
  .batch_done(done),.engine_quiescent(quiet),.over_raw(over),.lines_total(lines),.story_speed(speed),
  .story_phase(phase),.core_locked(core),.phase_enter(),.charge_pulse(),.batch_commit(commit),
  .finish_pending(pending),.result_valid(valid),.result_success(success));
 task tick;begin @(posedge clk);#1;end endtask
 task check;input condition;input [8*90-1:0] label;
  begin checks=checks+1;if(condition!==1'b1)begin bad=bad+1;$display("FAIL %0s",label);end end
 endtask
 task fresh;begin @(negedge clk);start=1;tick;check(!ready,"new run deasserts ready even across modes");@(negedge clk);start=0;repeat(26)tick;end endtask
 task batch;input integer n;
  begin for(j=0;j<n;j=j+1)begin @(negedge clk);credit=1;tick;end
   @(negedge clk);credit=0;done=1;tick;@(negedge clk);done=0;tick;
  end
 endtask
 initial begin
  #2;rst=0;#13;rst=1;
  campaign=1;
  for(i=0;i<8;i=i+1)begin
   duo=i/4;level=i%4;seen=0;
   for(k=0;k<8;k=k+1)begin
    seed=2*k+1;fresh;
    check(ready,"loader ready before engine release");check(actual_seed!=0,"nonzero effective seed");
    check(!(seen & (1<<layout)),"each layout index covered once");seen=seen|(1<<layout);
    total=0;
    for(y=0;y<20;y=y+1)begin
     count=0;for(c=0;c<(duo?24:20);c=c+1)count=count+mask[c*20+y];
     expected=y>=18-level?(duo?16:13)+level-(19-y):0;
     check(count==expected,"independent per-row block count");total=total+count;
     if(!duo)for(c=20;c<24;c=c+1)check(!mask[c*20+y],"unused columns clear");
    end
    check(total==(duo?(level==0?31:level==1?48:level==2?66:85):(level==0?25:level==1?39:level==2?54:70)),"independent total anchors");
    saved[layout]=mask;
   end
   for(k=0;k<8;k=k+1)for(c=k+1;c<8;c=c+1)check(saved[k]!=saved[c],"eight genuinely distinct boards");
   for(k=0;k<4;k=k+1)for(c=0;c<(duo?24:20);c=c+1)for(y=0;y<20;y=y+1)
    check(saved[k][c*20+y]==saved[k+4][((duo?24:20)-1-c)*20+y],"mirror pairs");
  end
  campaign=0;duo=0;seed=0;fresh;
  check(mask==0 && core==8,"endless empty field and active core");
  batch(20);batch(20);batch(20);
  check(lines==60 && speed==7 && !valid && !pending,"endless passes old target and remains live at maximum speed");
  @(negedge clk);ctl.lines_total=999998;batch(4);
  check(lines==999999 && !valid,"endless line counter saturates without ending game");
  @(negedge clk);over=1;tick;check(valid && !success,"endless real top-out fails");over=0;
  campaign=1;duo=0;level=0;left=25;fresh;batch(12);
  check(core==0 && !valid,"locked progress retained");
  left=13;batch(1);check(core==4 && !valid,"teaching threshold 13 reaches HALF");
  left=1;batch(20);check(lines==33 && core==4 && !valid && !pending,"target alone cannot freeze or win");
  left=0;batch(1);check(success && valid && core==8,"clear debris and target commit together");
  campaign=1;duo=1;level=0;left=16;fresh;batch(15);
  check(core==4 && !valid,"duo teaching threshold 16");
  left=0;batch(1);check(core<8 && !valid,"online below target not success");
  campaign=1;duo=0;level=0;left=1;quiet=1;over=0;fresh;batch(23);
  @(negedge clk);credit=1;tick;
  @(negedge clk);credit=0;done=1;quiet=0;over=1;tick;
  @(negedge clk);done=0;repeat(3)tick;
  check(!valid,"pending debris accounting defers top-out decision");
  @(negedge clk);left=0;quiet=1;tick;
  check(valid && success,"committed clear-and-target beats overlapping top alarm");
  if(bad==0)$display("ALL PASS GAME_MODES: %0d checks",checks);
  else $display("FAILED GAME_MODES %0d/%0d",bad,checks);
  $finish;
 end
 initial begin #4000000;$display("FAILED GAME_MODES timeout");$finish;end
endmodule
