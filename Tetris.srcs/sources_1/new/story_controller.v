// Shared batch statistics and mode-specific mission rules.
module story_controller(
 input clk,reset_n,new_run,playing,paused,duo,
 input campaign,input [1:0] level_id,input [6:0] debris_remaining,
 input row_credit,batch_done,engine_quiescent,over_raw,
 output reg [19:0] lines_total,output reg [2:0] story_speed,
 output wire [1:0] story_phase,output reg [3:0] core_locked,
 output reg phase_enter,charge_pulse,batch_commit,
 output reg finish_pending,result_valid,result_success
);
 `include "game_mode_params.vh"
 reg mode_duo,mode_campaign;reg [1:0] ship;
 reg commit_pending;reg [1:0] credit_pending;
 wire [2:0] credit_delta={2'd0,row_credit}+{1'b0,credit_pending};
 wire [20:0] sum_lines={1'b0,lines_total}+credit_delta;
 wire [19:0] credited_lines=sum_lines>MODE_LINES_MAX?MODE_LINES_MAX:sum_lines[19:0];
 wire [7:0] target=mode_target(mode_duo,ship);
 wire success_eligible=mode_campaign && debris_remaining==0 && credited_lines>=target;
 wire [7:0] step_lines=mode_campaign?mode_step(mode_duo,ship):mode_endless_step(mode_duo);
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
   lines_total<=0;story_speed<=0;core_locked<=0;mode_duo<=0;mode_campaign<=0;ship<=0;
   commit_pending<=0;credit_pending<=0;phase_enter<=0;charge_pulse<=0;batch_commit<=0;
   finish_pending<=0;result_valid<=0;result_success<=0;
  end else if(new_run)begin
   lines_total<=0;story_speed<=campaign?mode_initial(duo,level_id):0;core_locked<=campaign?0:8;
   mode_duo<=duo;mode_campaign<=campaign;ship<=level_id;
   commit_pending<=0;credit_pending<=0;phase_enter<=0;charge_pulse<=0;batch_commit<=0;
   finish_pending<=0;result_valid<=0;result_success<=0;
  end else begin
   phase_enter<=0;charge_pulse<=0;batch_commit<=0;
   if(row_credit && paused && credit_pending!=3)credit_pending<=credit_pending+1'b1;
   if(batch_done)commit_pending<=1;
   if(playing && !paused && !result_valid)begin
    credit_pending<=0;
    if(credit_delta!=0)begin lines_total<=credited_lines;charge_pulse<=1;end
    if(success_eligible)finish_pending<=1;
    if((batch_done || commit_pending) && engine_quiescent)begin
     commit_pending<=0;batch_commit<=1;story_speed<=next_speed;core_locked<=next_core;
     phase_enter<=mode_campaign && next_phase!=current_phase;
     if(success_eligible)begin finish_pending<=1;result_valid<=1;result_success<=1;end
     else if(over_raw)begin result_valid<=1;result_success<=0;end
    end else if(over_raw && !success_eligible && !finish_pending && !commit_pending && !batch_done)begin result_valid<=1;result_success<=0;end
   end
  end
 end
endmodule
