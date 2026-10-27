// Shared batch statistics and mode-specific mission rules.
module story_controller(
 input clk,reset_n,new_run,playing,paused,duo,
 input campaign,input [1:0] level_id,input [6:0] debris_remaining,
 input row_credit,batch_done,engine_quiescent,over_raw,
 input [2:0] endless_speed,
 output reg [19:0] lines_total,output reg [2:0] story_speed,
 output wire [1:0] story_phase,output reg [3:0] core_locked,
 output reg phase_enter,charge_pulse,batch_commit,
 output reg finish_pending,result_valid,result_success,output wire batch_pending,
 input [4:0] batch_n,output reg [19:0] real_lines,clear_count
);
 `include "game_mode_params.vh"
 `include "rhythm_params.vh"
 reg mode_duo,mode_campaign;reg [1:0] ship;
 reg commit_pending;
 assign batch_pending=commit_pending;reg [1:0] credit_pending;
 wire [2:0] credit_delta={2'd0,row_credit}+{1'b0,credit_pending};
 wire retire=commit_pending && engine_quiescent;
 reg [4:0] pending_n;wire [4:0] retired_n=pending_n;
 wire [2:0] bonus=(mode_campaign && pending_n==4)?RHYTHM_CAMPAIGN_FOUR_BONUS:0;
 wire [20:0] row_sum={1'b0,lines_total}+credit_delta;
 wire [19:0] row_lines=row_sum>MODE_LINES_MAX?MODE_LINES_MAX:row_sum[19:0];
 wire [20:0] sum_lines={1'b0,row_lines}+bonus;
 wire [19:0] credited_lines=sum_lines>MODE_LINES_MAX?MODE_LINES_MAX:sum_lines[19:0];
 wire [7:0] target=mode_target(mode_duo,ship);
 wire success_eligible=mode_campaign && debris_remaining==0 && credited_lines>=target;
 wire [7:0] step_lines=mode_step(mode_duo,ship);
 reg [2:0] next_speed;reg [3:0] next_core,earned;
 reg [1:0] next_phase;integer k;
 wire [1:0] current_phase=core_locked>6?2'd3:core_locked>4?2'd2:core_locked>2?2'd1:2'd0;
 assign story_phase=mode_campaign?current_phase:2'd0;
 always @(*)begin
  next_speed=mode_campaign?mode_initial(mode_duo,ship):0;
  for(k=1;k<8;k=k+1)
   if(credited_lines>=k*step_lines)begin
    if(k+(mode_campaign?mode_initial(mode_duo,ship):0)>7)next_speed=7;
    else next_speed=k+(mode_campaign?mode_initial(mode_duo,ship):0);
   end
  earned=0;
  for(k=1;k<=8;k=k+1)if({credited_lines,3'b000}>=k*target)earned=k;
  if(!mode_campaign)next_core=8;
  else if(debris_remaining>mode_half(mode_duo,ship))next_core=0;
  else if(debris_remaining!=0)next_core=earned>4?4:earned;
  else if(success_eligible)next_core=8;
  else next_core=earned>7?7:earned;
  next_phase=next_core>6?3:next_core>4?2:next_core>2?1:0;
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin
   real_lines<=0;clear_count<=0;pending_n<=0;lines_total<=0;story_speed<=0;core_locked<=0;mode_duo<=0;mode_campaign<=0;ship<=0;
   commit_pending<=0;credit_pending<=0;phase_enter<=0;charge_pulse<=0;batch_commit<=0;
   finish_pending<=0;result_valid<=0;result_success<=0;
  end else if(new_run)begin
   real_lines<=0;clear_count<=0;pending_n<=0;lines_total<=0;story_speed<=campaign?mode_initial(duo,level_id):0;core_locked<=campaign?0:8;
   mode_duo<=duo;mode_campaign<=campaign;ship<=level_id;
   commit_pending<=0;credit_pending<=0;phase_enter<=0;charge_pulse<=0;batch_commit<=0;
   finish_pending<=0;result_valid<=0;result_success<=0;
  end else begin
   phase_enter<=0;charge_pulse<=0;batch_commit<=0;
   if(row_credit && paused && credit_pending!=3)credit_pending<=credit_pending+1'b1;
   if(batch_done)begin commit_pending<=1;pending_n<=batch_n;end
   if(playing && !paused && !result_valid)begin
    credit_pending<=0;
    if(!mode_campaign)story_speed<=endless_speed;
    if(credit_delta!=0)begin lines_total<=row_lines;charge_pulse<=1;end
    if(credit_delta!=0)real_lines<=({1'b0,real_lines}+credit_delta)>MODE_LINES_MAX?MODE_LINES_MAX:real_lines+credit_delta;
    if(success_eligible)finish_pending<=1;
    if(retire)begin
     commit_pending<=0;pending_n<=0;batch_commit<=1;lines_total<=credited_lines;if(bonus!=0)charge_pulse<=1;if(retired_n!=0 && clear_count<MODE_LINES_MAX)clear_count<=clear_count+1'b1;story_speed<=mode_campaign?next_speed:endless_speed;core_locked<=next_core;
     phase_enter<=mode_campaign && next_phase!=current_phase;
     if(success_eligible)begin finish_pending<=1;result_valid<=1;result_success<=1;end
     else if(over_raw)begin result_valid<=1;result_success<=0;end
    end else if(over_raw && !success_eligible && !finish_pending && !commit_pending && !batch_done)begin result_valid<=1;result_success<=0;end
   end
  end
 end
endmodule

// Exact threshold comparisons. Only the decimal presentation is rounded down.
module mission_rank(input clk,reset_n,new_run,input [19:0] real_lines,clear_count,
 input [18:0] elapsed_ticks,output reg [1:0] rank,output reg [7:0] average_tenths);
 wire [31:0] rows={12'd0,real_lines},batches={12'd0,clear_count};
 wire [31:0] elapsed={13'd0,elapsed_ticks};
 reg [19:0] old_rows,old_batches;reg [23:0] remainder;reg [7:0] quotient;reg dividing;
 always @(*)begin
  rank=0;
  if(real_lines!=0 && clear_count!=0)begin
   if(rows>=3*batches && elapsed<=rows*720)rank=3;
   else if(rows*10>=batches*22 && elapsed<=rows*1080)rank=2;
   else if(rows*2>=batches*3 && elapsed<=rows*1680)rank=1;
  end
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin old_rows<=0;old_batches<=0;remainder<=0;quotient<=0;dividing<=0;average_tenths<=0;end
  else if(new_run)begin old_rows<=0;old_batches<=0;remainder<=0;quotient<=0;dividing<=0;average_tenths<=0;end
  else if(old_rows!=real_lines || old_batches!=clear_count)begin
   old_rows<=real_lines;old_batches<=clear_count;remainder<={4'd0,real_lines}*10;quotient<=0;
   dividing<=clear_count!=0;if(clear_count==0)average_tenths<=0;
  end else if(dividing)begin
   if(remainder>={4'd0,old_batches} && quotient<200)begin remainder<=remainder-{4'd0,old_batches};quotient<=quotient+1'b1;end
   else begin average_tenths<=quotient;dividing<=0;end
  end
 end
endmodule
