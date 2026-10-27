`timescale 1ns/1ps
module number(input clka,input ena,input [9:0] addra,output [19:0] douta);assign douta=0;endmodule
module score_pause_tb;
 reg clk=0,rst=0,idle=1,playing=0,stop=0,finalize=0,credit=0;
 reg [4:0] n=0;reg [2:0] speed=0;wire [19:0] score;integer bad=0;
 always #5 clk=~clk;
 scoring dut(.Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),.Idle(idle),.Playing(playing),
 .Stop(stop),.Finalize(finalize),.switch_r_flag(1'b0),.clear_t_t(credit),.c_clear(n),.speed_level(speed),.duo(1'b0),.counter(score));
 task cycle;begin @(posedge clk);#1;end endtask
 task ck;input pass;input [8*100-1:0] label;begin if(pass!==1)begin bad=bad+1;$display("FAIL SCORE_PAUSE %0s score=%0d",label,score);end end endtask
 initial begin
  repeat(3)cycle;rst=1;cycle;idle=0;stop=1;playing=0;credit=1;n=2;speed=1;cycle;credit=0;n=0;speed=7;repeat(20)cycle;
  ck(score==0,"pause retains score transaction without publishing");stop=0;playing=1;cycle;ck(score==16,"resume consumes original n and old multiplier");repeat(4)cycle;ck(score==16,"pending score counted once");
  stop=1;playing=0;credit=1;n=1;speed=2;cycle;credit=0;stop=0;finalize=1;cycle;ck(score==22,"paused final transaction retires before result freeze");repeat(4)cycle;ck(score==22,"result does not recount transaction");
  if(bad==0)$display("ALL PASS SCORE_PAUSE");else $display("FAILED SCORE_PAUSE %0d",bad);$finish;
 end
endmodule
