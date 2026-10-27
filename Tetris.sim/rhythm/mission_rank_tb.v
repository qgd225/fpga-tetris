`timescale 1ns/1ps
module mission_rank_tb;
 reg clk=0,rst=0,fresh=0;reg [19:0] rows=0,batches=0;reg [18:0] elapsed=0;
 wire [1:0] rank;wire [7:0] avg;
 reg credit=0,done=0,paused=0,quiet=1;reg [4:0] n=0;wire [19:0] points,real_rows,clear_count;
 integer bad=0,i;
 always #5 clk=~clk;
 mission_rank r(clk,rst,fresh,rows,batches,elapsed,rank,avg);
 story_controller ctl(.clk(clk),.reset_n(rst),.new_run(fresh),.playing(1'b1),.paused(paused),.duo(1'b0),.campaign(1'b1),.level_id(2'd3),.debris_remaining(7'd70),.row_credit(credit),.batch_done(done),.engine_quiescent(quiet),.over_raw(1'b0),.endless_speed(3'd0),.batch_n(n),.lines_total(points),.real_lines(real_rows),.clear_count(clear_count));
 task cycle;begin @(posedge clk);#1;end endtask
 task ck;input pass;input [8*100-1:0] msg;begin if(pass!==1)begin bad=bad+1;$display("FAIL MISSION_RANK %0s rank=%0d",msg,rank);end end endtask
 task sample;input integer a,b,t,expect_rank;begin @(negedge clk);rows=a;batches=b;elapsed=t;cycle;ck(rank==expect_rank,"highest tier requires both exact conditions");end endtask
 initial begin
  repeat(3)cycle;rst=1;fresh=1;cycle;fresh=0;cycle;
  sample(30,10,30*12*60,3);sample(30,10,30*12*60+1,2);
  sample(22,10,22*18*60,2);sample(22,10,22*18*60+1,1);
  sample(15,10,15*28*60,1);sample(15,10,15*28*60+1,0);
  sample(32,10,32*35*60,0);sample(21,10,1,1);sample(0,0,0,0);
  sample(28,10,7*60*60,2);repeat(205)cycle;ck(avg==28,"display average computed exactly in tenths without affecting rank");
  @(negedge clk);credit=1;repeat(4)cycle;@(negedge clk);credit=0;n=4;done=1;paused=1;cycle;done=0;repeat(3)cycle;
  ck(points==4 && real_rows==4 && clear_count==0,"paused batch defers bonus and statistics retirement");
  paused=0;cycle;ck(points==6 && real_rows==4 && clear_count==1,"four actual rows earn six mission credit once");repeat(4)cycle;ck(points==6 && clear_count==1,"retirement cannot duplicate bonus");
  @(negedge clk);credit=1;repeat(5)cycle;@(negedge clk);credit=0;n=5;done=1;cycle;done=0;cycle;
  ck(points==11 && real_rows==9 && clear_count==2,"five-row batch follows explicitly adopted exact-four bonus rule");
  if(bad==0)$display("ALL PASS MISSION_RANK");else $display("FAILED MISSION_RANK %0d",bad);$finish;
 end
endmodule
