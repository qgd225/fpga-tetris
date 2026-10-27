`timescale 1ns/1ps
module rhythm_tb;
 reg clk=0,rst=0,fresh=0,playing=1,paused=0,finished=0,tick60=0,campaign=0,duo=0;
 reg commit=0,inflight=0,request=0,hreq1=0,hreq2=0,land1=0,land2=0,bank=0;
 reg [4:0] n=0;reg [3:0] core=0;
 wire [18:0] elapsed;wire [13:0] seconds;wire [15:0] bcd;wire [2:0] speed,quota;
 wire [13:0] energy;wire waiting,failed,recharge,warning,critical,clipped,no_gain;
 wire hint_active,hint_reject,hint_recharge,accept1,accept2,expired,rejected,ready;
 wire [1:0] blocks;wire [6:0] cooldown;wire [8:0] gain;wire [10:0] life;
 integer checks=0,bad=0,i,k,energy_before;
 always #5 clk=~clk;
 run_clock clock_dut(clk,rst,fresh,playing,paused,finished,tick60,elapsed,seconds,bcd,speed);
 reserve_timer #(.WAIT_LIMIT(16)) supply(clk,rst,fresh,playing,paused,campaign,finished,tick60,commit,inflight,n,energy,waiting,failed,recharge,warning,critical,clipped,no_gain,gain);
 hint_budget hint(clk,rst,fresh,playing,paused,finished,duo,campaign,tick60,request,commit,n,core,hint_active,quota,hint_reject,hint_recharge,,);
 hold_limits limits(clk,rst,fresh,playing,paused,1'b0,finished,duo,tick60,hreq1,hreq2,land1,land2,bank,accept1,accept2,expired,rejected,blocks,cooldown,life,ready,,);
 task cycle;begin @(posedge clk);#1;end endtask
 task ck;input condition;input [8*110-1:0] label;begin checks=checks+1;if(condition!==1)begin bad=bad+1;if(bad<20)$display("FAIL RHYTHM %0s",label);end end endtask
 task reset_run;begin @(negedge clk);fresh=1;commit=0;n=0;tick60=0;request=0;hreq1=0;hreq2=0;land1=0;land2=0;bank=0;paused=0;finished=0;inflight=0;core=0;cycle;@(negedge clk);fresh=0;cycle;end endtask
 task ticks;input integer count;begin @(negedge clk);tick60=1;repeat(count)cycle;@(negedge clk);tick60=0;cycle;end endtask
 task batch;input [4:0] count;begin @(negedge clk);commit=1;n=count;cycle;@(negedge clk);commit=0;n=0;cycle;end endtask
 task toggle_hint;begin @(negedge clk);request=1;cycle;@(negedge clk);request=0;cycle;end endtask
 initial begin
  repeat(3)cycle;rst=1;reset_run;
  campaign=1;
  ticks(2699);ck(speed==0 && elapsed==2699 && seconds==44,"time before first boundary");ticks(1);ck(speed==1 && seconds==45 && bcd==16'h0045,"time and speed first boundary");
  ticks(16200);ck(speed==7 && seconds==315,"all seven boundaries reach last speed");ticks(60);ck(speed==7 && seconds==316 && bcd==16'h0516,"TIME continues after speed clamps");
  paused=1;ticks(120);ck(seconds==316 && elapsed==18960,"paused time frozen");paused=0;
  ticks(340980);ck(elapsed==359940 && seconds==5999 && bcd==16'h9959 && speed==7,"time saturates at 99:59");ticks(100);ck(elapsed==359940,"time does not wrap");
  campaign=0;reset_run;ck(energy==5400,"initial energy");batch(0);ck(energy==5400,"empty batch no credit");batch(1);ck(energy==7560,"one-line credit");batch(2);ck(energy==9000,"two-line credit");batch(3);ck(energy==9000 && clipped,"three-line saturates");batch(20);ck(energy==9000 && no_gain && gain==264,"large batch saturates without overflow");
  reset_run;ticks(5000);batch(4);ck(gain==96 && energy==6160,"four-row supply bonus is exactly 24 units");
  reset_run;ticks(5400);ck(failed && !waiting && energy==0,"no-transaction zero fails");
  reset_run;ticks(5399);@(negedge clk);tick60=1;commit=1;n=1;cycle;ck(!failed && energy==2160,"same-tick credit rescues zero");@(negedge clk);tick60=0;commit=0;n=0;
  reset_run;inflight=1;ticks(5400);ck(waiting && !failed,"already started clear gets one grace transaction");batch(1);ck(!waiting && !failed && energy==2160,"single grace transaction rescues supply");
  reset_run;inflight=1;ticks(5400);batch(0);ck(failed && !waiting,"empty grace transaction cannot extend play");
  reset_run;inflight=1;ticks(5400);repeat(20)cycle;ck(failed,"grace wait bounded");
  campaign=1;reset_run;toggle_hint;ck(hint_active && quota==0,"last hint credit starts full lifetime");ticks(719);ck(hint_active,"zero balance does not hide active hint");toggle_hint;ck(!hint_active && quota==0,"free close at zero balance");toggle_hint;ck(hint_reject || !hint_active,"zero balance rejects only new opening");
  batch(20);ck(hint.rows==0,"locked rows never bank hint recharge");core=1;batch(2);ck(quota==0 && hint.rows==0,"unlock batch not retroactively credited");batch(7);core=3;batch(2);ck(quota==1 && hint.rows==3,"cross-stage remainder uses new interval");
  batch(20);ck(quota==3 && hint.rows==0,"full quota discards banked rows");toggle_hint;ck(hint_active && quota==2,"opening after full consumes once");ticks(720);ck(!hint_active && quota==2,"expiry closes without refund");
  campaign=0;reset_run;toggle_hint;ticks(600);ck(hint_active && quota==1,"endless hints unlimited and persistent");toggle_hint;ck(!hint_active,"endless hint closes freely");
  reset_run;hreq1=1;#1;ck(accept1,"first HOLD allowed");cycle;@(negedge clk);hreq1=0;bank=1;cycle;ck(blocks==3 && cooldown==120,"both cooldown conditions start");
  land1=1;repeat(3)cycle;land1=0;cycle;ck(blocks==0 && !ready,"block count alone insufficient");ticks(120);ck(ready,"both conditions release HOLD");
  reset_run;hreq1=1;cycle;hreq1=0;bank=1;ticks(120);ck(blocks==3 && !ready,"elapsed time alone insufficient");
  reset_run;duo=1;hreq1=1;hreq2=1;#1;ck(accept1 && !accept2,"P1 initial tie priority");cycle;hreq1=0;hreq2=0;bank=1;land1=1;land2=1;cycle;land1=0;land2=0;ticks(120);hreq1=1;hreq2=1;#1;ck(!accept1 && accept2,"successful grant rotates tie priority");cycle;hreq1=0;hreq2=0;bank=1;ticks(1800);ck(life==0,"bank lifetime expires");
  duo=0;campaign=0;reset_run;inflight=1;ticks(5400);ck(waiting,"zero grace before pause");
  paused=1;commit=1;n=1;cycle;commit=0;n=0;ticks(30);ck(energy==0 && waiting && !failed,"paused commit is retained without charging");
  paused=0;cycle;ck(energy==2160 && !waiting && !failed,"resume consumes deferred supply commit once");repeat(4)cycle;ck(energy==2160,"deferred supply commit not repeated");
  campaign=1;reset_run;core=1;batch(1);batch(7);paused=1;commit=1;n=1;cycle;commit=0;n=0;ticks(30);ck(quota==1 && hint.rows==7,"paused hint recharge is retained");
  paused=0;cycle;ck(quota==2 && hint.rows==0,"resume recharges hint quota exactly once");repeat(4)cycle;ck(quota==2,"hint deferred commit not repeated");
  if(bad==0)$display("ALL PASS RHYTHM checks=%0d",checks);else $display("FAILED RHYTHM bad=%0d checks=%0d",bad,checks);
  $finish;
 end
 initial begin #100000000;$display("FAILED RHYTHM timeout");$finish;end
endmodule
