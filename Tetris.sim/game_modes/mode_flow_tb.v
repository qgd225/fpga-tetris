`timescale 1ns/1ps
module mode_flow_tb;
 reg clk=0,rst=0,l=0,r=0,confirm=0,held=0,over=0,success=0,ready=0;
 wire choose,idle,playing,stop,finalize,short_p,long_p,select,campaign;
 reg back=0,cancel_switch=0;
 wire [3:0] mode;wire [1:0] level,option,menu_window;
 integer bad=0,m,t;
 always #5 clk=~clk;
 Game_state_machine #(.MCNT(4)) dut(clk,rst,l,r,confirm,held,over,success,ready,
  choose,idle,playing,stop,finalize,short_p,long_p,mode,select,level,campaign,option,menu_window,back,cancel_switch);
 task tick;begin @(posedge clk);#1;end endtask
 task press;begin @(negedge clk);confirm=1;tick;@(negedge clk);confirm=0;tick;end endtask
 task right;begin @(negedge clk);r=1;tick;@(negedge clk);r=0;tick;end endtask
 task left;begin @(negedge clk);l=1;tick;@(negedge clk);l=0;tick;end endtask
 task check;input pass;input [8*80-1:0] message;
 begin if(pass!==1)begin bad=bad+1;$display("FAIL %0s",message);end end endtask
 initial begin
  for(m=0;m<4;m=m+1)begin
   rst=0;repeat(2)tick;rst=1;tick;ready=0;over=0;success=0;
   repeat(m)right;
   check(mode==m && campaign==(m>=2),"mode mapping");press;
   if(m>=2)begin check(select && choose && !playing,"campaign must select ship first");repeat(3)right;check(level==3 && menu_window==1,"all ships available initially");left;check(level==2 && menu_window==1,"previous selection moves highlight within stable window");left;check(level==1 && menu_window==1,"second previous selection keeps window");left;check(level==0 && menu_window==0,"only crossing top edge scrolls window");left;check(level==0,"first ship does not wrap");repeat(3)right;press;end
   check(idle && !playing,"initialization gate");repeat(80)tick;
   check(!playing,"cannot start before loader ready");ready=1;repeat(3)tick;
   check(playing,"ready starts gameplay");press;check(stop,"pause");press;check(playing,"resume");
   press;check(stop,"pause before result collision");over=1;tick;over=0;check(finalize,"result enters once");
   press;check(idle,"retry re-enters initialization");repeat(80)tick;check(playing,"retry starts a fresh run");
   over=1;tick;over=0;check(finalize && option==0,"retry clears result selection");right;check(option==1,"result selection");
   press;check(choose,"return result to correct menu");
   if(m>=2)check(select,"campaign returns to ship selection");else check(!select,"endless returns main");
  end
  for(m=2;m<4;m=m+1)begin
   rst=0;ready=1;over=0;success=0;repeat(2)tick;rst=1;tick;repeat(m)right;press;press;repeat(80)tick;
   success=1;over=1;tick;over=0;check(finalize,"campaign success result");right;
   check(option==1,"next ship option");press;check(idle && level==1,"next ship initializes exactly once");repeat(80)tick;check(playing,"next ship starts gameplay");
   over=1;tick;over=0;right;right;check(option==2,"successful intermediate ship offers selection");press;check(select,"return to ship selection after success");
   right;right;check(level==3,"select final ship");press;repeat(80)tick;over=1;tick;over=0;right;right;
   check(finalize && option==0,"final ship has no next option");
   @(negedge clk);held=1;repeat(7)tick;held=0;tick;press;check(select && choose,"long return release does not confirm a new run");
  end
  for(m=0;m<4;m=m+1)begin
   rst=0;back=0;success=0;over=0;ready=1;repeat(2)tick;rst=1;tick;
   repeat(m)right;press;if(m>=2)press;repeat(80)tick;
   check(playing,"Esc test enters play");
   @(negedge clk);back=1;tick;@(negedge clk);back=0;tick;
   check(choose && select==(m>=2),"Esc returns to correct menu");
   press;check(idle || select,"Enter immediately works after Esc");
  end
  // Esc while Enter is held returns once and consumes that Enter release.
  rst=0;back=0;ready=1;held=0;confirm=0;repeat(2)tick;rst=1;tick;right;right;press;press;repeat(80)tick;
  @(negedge clk);held=1;back=1;tick;
  @(negedge clk);back=0;repeat(7)tick;
  check(select,"Esc with held Enter returns one level only");
  @(negedge clk);held=0;confirm=1;tick;
  @(negedge clk);confirm=0;tick;
  check(select,"Esc consumes pre-existing Enter release");
  // Timeout/blur after a long press rearms the next confirmation without replay.
  rst=0;ready=1;held=0;confirm=0;repeat(2)tick;rst=1;tick;press;repeat(80)tick;
  @(negedge clk);held=1;repeat(7)tick;
  @(negedge clk);held=0;cancel_switch=1;tick;
  @(negedge clk);cancel_switch=0;tick;
  check(choose && !idle,"cancelled long press stays in menu");
  press;check(idle,"first confirmation after cancellation works");
  if(bad==0)$display("ALL PASS MODE_FLOW");else $display("FAILED MODE_FLOW %0d",bad);
  $finish;
 end
 initial begin #100000;$display("FAILED MODE_FLOW timeout");$finish;end
endmodule
