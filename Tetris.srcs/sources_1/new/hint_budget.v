// Opening, visibility and free closing have independent ownership.
module hint_budget(input clk,reset_n,new_run,playing,paused,finished,duo,campaign,tick,request,
 input batch_commit,input [4:0] batch_n,input [3:0] core,
 output reg active,output reg [2:0] quota,output reg rejected,recharged,output [2:0] quota_capacity,output [9:0] life_ticks);
 `include "rhythm_params.vh"
 reg [9:0] life;
 reg [5:0] rows;
 reg [3:0] old_core;
 wire [2:0] capacity=core==0?1:core<=2?2:core<=4?3:4;
 assign quota_capacity=capacity;assign life_ticks=life;
 wire [3:0] interval_rows=core<=2?8:core<=4?6:4;
 reg deferred_credit;reg [4:0] deferred_n;
 wire has_commit=batch_commit || deferred_credit;
 wire [4:0] credited_n=deferred_credit?deferred_n:batch_n;
 wire [6:0] accumulated={1'b0,rows}+{2'd0,credited_n};
 reg [4:0] earned;
 reg [6:0] remainder;
 wire [6:0] quota_sum={4'd0,quota}+{2'd0,earned};
 reg [6:0] row_sum;reg [3:0] q_next;integer k;
 always @(*)begin
  earned=0;remainder=0;
  if(core<=2)begin earned=accumulated[6:3];remainder={4'd0,accumulated[2:0]};end
  else if(core<=4)begin
   // Independent threshold comparisons, never a chain of subtract-and-compare stages.
   for(k=1;k<=5;k=k+1)if(accumulated>=k*6)earned=k;
   remainder=accumulated-earned*6;
  end else begin earned=accumulated[6:2];remainder={5'd0,accumulated[1:0]};end
  row_sum={1'b0,rows};q_next={1'b0,quota};
  if(has_commit && old_core!=0 && core!=0 && core<8 && quota<capacity)begin
   q_next=quota_sum>=capacity?{1'b0,capacity}:quota_sum[3:0];row_sum=remainder;
  end
  if(core==0 || old_core==0 || q_next>=capacity)row_sum=0;
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin deferred_credit<=0;deferred_n<=0;active<=0;quota<=1;rows<=0;old_core<=0;life<=0;rejected<=0;recharged<=0;end
  else if(new_run)begin deferred_credit<=0;deferred_n<=0;active<=0;quota<=1;rows<=0;old_core<=0;life<=0;rejected<=0;recharged<=0;end
  else begin
   rejected<=0;recharged<=0;
   if(batch_commit && paused && campaign && !duo && !finished)begin deferred_credit<=1;deferred_n<=batch_n;end
   if(finished || duo)begin deferred_credit<=0;active<=0;life<=0;end
   else if(playing && !paused)begin
    deferred_credit<=0;
    old_core<=core;
    if(campaign)begin
     quota<=q_next[2:0];rows<=row_sum[5:0];recharged<=q_next>quota;
     if(tick && active)begin if(life<=1)begin active<=0;life<=0;end else life<=life-1'b1;end
    end
    if(request)begin
     if(active)begin active<=0;life<=0;end
     else if(!campaign)active<=1;
     else if(quota!=0)begin active<=1;life<=RHYTHM_HINT_LIFE;quota<=q_next-1'b1;end
     else rejected<=1;
    end
   end
  end
 end
endmodule
