// Energy is in 1/60 unit ticks. Only an already active clear may rescue zero.
module reserve_timer #(parameter WAIT_LIMIT=265073566)(
 input clk,reset_n,new_run,playing,paused,campaign,finished,tick,
 input batch_commit,batch_inflight,input [4:0] batch_n,
 output reg [13:0] reserve_ticks,output reg waiting,failed,
 output reg recharge,warning,critical_tick,clipped,no_gain,output reg [8:0] recharge_units);
 `include "rhythm_params.vh"
 reg deferred_credit;reg [4:0] deferred_n;
 wire [4:0] credited_n=deferred_credit?deferred_n:batch_n;
 reg [28:0] wait_cycles;
 reg [5:0] critical_phase;
 wire active=playing && !paused && !finished && !campaign && !failed;
 wire [8:0] gain_units=RHYTHM_RESERVE_BASE+({4'd0,credited_n}*RHYTHM_RESERVE_PER_LINE)+(credited_n==4?RHYTHM_RESERVE_FOUR_BONUS:0);
 wire [14:0] gain_ticks={6'd0,gain_units}*15'd60;
 wire has_commit=batch_commit || deferred_credit;
 wire credit=has_commit && credited_n!=0;
 wire [13:0] spent=reserve_ticks-((tick && reserve_ticks!=0)?14'd1:14'd0);
 wire [14:0] sum={1'b0,spent}+(credit?gain_ticks:15'd0);
 wire [13:0] next_reserve=sum>RHYTHM_RESERVE_CAP?RHYTHM_RESERVE_CAP:sum[13:0];
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin deferred_credit<=0;deferred_n<=0;reserve_ticks<=RHYTHM_RESERVE_INITIAL;waiting<=0;failed<=0;wait_cycles<=0;recharge<=0;warning<=0;critical_tick<=0;recharge_units<=0;critical_phase<=0;clipped<=0;no_gain<=0;end
  else if(new_run)begin deferred_credit<=0;deferred_n<=0;reserve_ticks<=RHYTHM_RESERVE_INITIAL;waiting<=0;failed<=0;wait_cycles<=0;recharge<=0;warning<=0;critical_tick<=0;recharge_units<=0;critical_phase<=0;clipped<=0;no_gain<=0;end
  else begin
   recharge<=0;warning<=0;critical_tick<=0;
   if(finished)deferred_credit<=0;
   else if(batch_commit && paused && !campaign)begin deferred_credit<=1;deferred_n<=batch_n;end
   if(active)begin
    deferred_credit<=0;
    reserve_ticks<=next_reserve;
    if(credit)begin recharge<=1;recharge_units<=gain_units;clipped<=sum>=RHYTHM_RESERVE_CAP;no_gain<=spent>=RHYTHM_RESERVE_CAP;end
    if(reserve_ticks>RHYTHM_RESERVE_LOW && next_reserve<=RHYTHM_RESERVE_LOW)warning<=1;
    if(tick)begin
     if(next_reserve<=RHYTHM_RESERVE_CRITICAL && next_reserve!=0)begin
      if(critical_phase==59)begin critical_phase<=0;critical_tick<=1;end else critical_phase<=critical_phase+1'b1;
     end else critical_phase<=0;
    end
    if(waiting)begin
     if(has_commit)begin waiting<=0;wait_cycles<=0;if(next_reserve==0)failed<=1;end
     else if(wait_cycles>=WAIT_LIMIT-1)begin waiting<=0;failed<=1;end
     else wait_cycles<=wait_cycles+1'b1;
    end else if(next_reserve==0)begin
     if(batch_inflight && !has_commit)begin waiting<=1;wait_cycles<=0;end
     else failed<=1;
    end
   end
  end
 end
endmodule
