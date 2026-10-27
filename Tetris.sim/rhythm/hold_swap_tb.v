`timescale 1ns/1ps
module hold_swap_tb;
 reg clk=0,rst=0,idle=1,playing=0,paused=0,req1=0,req2=0,land1=0,land2=0,tick60=0,busy=0;
 reg [2:0] type1=3,type2=5;
 wire bank_valid,swap_valid,up1,up2,ready,expired,rejected,reserved,owner2,wait1,wait2;
 wire [2:0] bank,swap_type,conditions;wire [1:0] blocks;wire [6:0] cooldown;wire [10:0] life;
 integer bad=0,saved_life,i;reg last_reject=0;
 always #5 clk=~clk;
 Playfield_hold_controller dut(.Clk_74M(clk),.Reset_n(rst),.Idle(idle),.Stop(paused),.board_busy(busy),
  .Finalize(1'b0),.switch_r_flag(1'b0),.hold_p_flag(req1),.hold_p_flag2(req2),.type(type1),.type2(type2),
  .hold_type(bank),.hold_up(up1),.hold_up2(up2),.Playing(playing),.duo(1'b1),.ui_tick(tick60),
  .land1(land1),.land2(land2),.hold_valid(bank_valid),.swap_valid(swap_valid),.swap_type(swap_type),
  .blocks_left(blocks),.cooldown_ticks(cooldown),.life_ticks(life),.ready(ready),.expired(expired),.rejected(rejected),
  .reserved(reserved),.owner2(owner2),.wait1(wait1),.wait2(wait2),.store_conditions(conditions));
 task cycle;begin @(posedge clk);#1;end endtask
 task ck;input pass;input [8*100-1:0] msg;begin if(pass!==1)begin bad=bad+1;$display("FAIL HOLD_CLAIM %0s",msg);end end endtask
 task press1;begin @(negedge clk);req1=1;cycle;last_reject=rejected;@(negedge clk);req1=0;cycle;end endtask
 task press2;begin @(negedge clk);req2=1;cycle;@(negedge clk);req2=0;cycle;end endtask
 initial begin
  repeat(3)cycle;rst=1;repeat(2)cycle;idle=0;playing=1;
  @(negedge clk);req1=1;cycle;ck(up1 && bank_valid && bank==3 && !swap_valid,"empty slot stores current only");@(negedge clk);req1=0;cycle;
  ck(blocks==2 && cooldown==120,"store starts shared two-condition cooldown");
  tick60=1;repeat(30)cycle;tick60=0;saved_life=life;
  press2;ck(reserved && owner2 && !up2 && bank==3 && !ready,"P2 claims despite store cooldown without swapping");
  tick60=1;repeat(1900)cycle;tick60=0;ck(life==saved_life && bank_valid && !expired,"claimed item cannot expire while awaiting owner");
  press1;ck(reserved && owner2 && last_reject,"other player cannot steal or cancel claim");
  press2;ck(!reserved && life==saved_life && bank==3,"owner cancels without refreshing saved lifetime");
  @(negedge clk);req1=1;req2=1;cycle;ck(reserved && !owner2,"claims rotate priority after P2 claim");@(negedge clk);req1=0;req2=0;cycle;
  @(negedge clk);land2=1;cycle;land2=0;repeat(40)cycle;ck(reserved && !wait2 && bank_valid,"other player's landing does not deliver claim");
  @(negedge clk);land1=1;busy=1;cycle;land1=0;repeat(80)cycle;ck(wait1 && bank_valid && !up1,"owner claim waits while lock or clear is busy");
  paused=1;busy=0;repeat(80)cycle;ck(wait1 && bank_valid,"pause freezes delivery");paused=0;
  i=0;while(!up1 && i<40)begin cycle;i=i+1;end
  ck(up1 && swap_valid && swap_type==3 && !bank_valid && !reserved,"safe retirement delivers captured bank once and empties slot");
  repeat(50)cycle;ck(!up1 && !up2 && !bank_valid,"claim cannot duplicate or store active piece");
  ck(conditions==7,"three indicators independently expose all store prerequisites");
  press2;ck(bank_valid && bank==5 && !swap_valid,"next empty-slot action stores fresh active type");
  tick60=1;repeat(1800)cycle;tick60=0;repeat(3)cycle;ck(!bank_valid && !reserved,"unclaimed bank still expires after 30 seconds");
  if(bad==0)$display("ALL PASS HOLD_CLAIM");else $display("FAILED HOLD_CLAIM %0d",bad);$finish;
 end
endmodule
