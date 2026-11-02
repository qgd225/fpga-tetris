`timescale 1ns/1ps
module input_route_tb;
 reg clk=0,rst=0,duo=0,cancel=0;
 reg [4:0] b1=0,b2=0,c1=0,c2=0;
 wire [7:0] p1,p2;wire hold_held;
 integer bad=0,i,j;
 always #5 clk=~clk;
 control_route dut(.Clk(clk),.Reset_n(rst),.duo(duo),.pc_cancel(cancel),
 .btn1(b1),.btn2(b2),.pc1(c1),.pc2(c2),.p1_hold_held(hold_held),
 .p1_left(p1[0]),.p1_right(p1[1]),.p1_drop_r(p1[2]),.p1_drop_en(p1[3]),
 .p1_rotate(p1[4]),.p1_hold(p1[5]),.p1_left_held(p1[6]),.p1_right_held(p1[7]),
 .p2_left(p2[0]),.p2_right(p2[1]),.p2_drop_r(p2[2]),.p2_drop_en(p2[3]),
 .p2_rotate(p2[4]),.p2_hold(p2[5]),.p2_left_held(p2[6]),.p2_right_held(p2[7]));
 task check;input ok;input [8*100-1:0] msg;
 begin if(ok!==1)begin bad=bad+1;$display("FAIL %0s",msg);end end endtask
 task tick;begin @(posedge clk);#1;end endtask
 task clear;begin @(negedge clk);b1=0;b2=0;c1=0;c2=0;cancel=0;tick;end endtask
 initial begin
  repeat(2)tick;rst=1;duo=1;tick;
  // Every action from each of four sources reaches exactly its intended player.
  for(i=0;i<4;i=i+1)for(j=0;j<5;j=j+1)begin
   clear;@(negedge clk);
   case(i)0:b1=1<<j;1:c1=1<<j;2:b2=1<<j;3:c2=1<<j;endcase
   #1;
   if(i<2)begin check(p2==0,"P1 does not affect P2");
    case(j)0:check(p1[0]&&p1[6],"P1 left");1:check(p1[1]&&p1[7],"P1 right");
    2:check(p1[3]&&!p1[2],"P1 drop held");3:check(p1[4],"P1 rotate");4:check(p1[5]&&hold_held,"P1 hold");endcase
   end else begin check(p1==0,"P2 does not affect P1");
    case(j)0:check(p2[0]&&p2[6],"P2 left");1:check(p2[1]&&p2[7],"P2 right");
    2:check(p2[3]&&!p2[2],"P2 drop held");3:check(p2[4],"P2 rotate");4:check(p2[5],"P2 hold");endcase
   end
   tick;
  end
  clear;@(negedge clk);b1=5'b00101;c1=5'b00101;b2=5'b00110;c2=5'b00110;tick;
  @(negedge clk);c1=0;c2=0;#1;
  check(p1[3]&&p1[6]&&!p1[2]&&!p1[0],"PC release preserves held GPIO1 without duplicate edge");
  check(p2[3]&&p2[7]&&!p2[2],"PC release preserves GPIO2");tick;
  @(negedge clk);b1=0;b2=0;#1;check(p1[2]&&p2[2],"final intentional drop release");tick;
  clear;@(negedge clk);c1=4;c2=4;tick;
  @(negedge clk);c1=0;c2=0;cancel=1;#1;
  check(p1==0&&p2==0,"focus loss and timeout do not hard drop");tick;
  clear;cancel=1;@(negedge clk);b1=4;b2=4;tick;
  @(negedge clk);b1=0;b2=0;#1;check(p1[2]&&p2[2],"disconnected PC does not disable local drop");tick;
  clear;duo=0;tick;@(negedge clk);c2=9;b2=31;#1;
  check(p1[0]&&p1[4]&&p2==0,"solo legacy arrows control P1; GPIO2 is disabled");tick;
  @(negedge clk);duo=1;#1;check(!p1[2]&&!p2[0]&&!p2[4],"mode transition does not replay pulses");tick;
  if(bad==0)$display("=== ALL PASS: INPUT ROUTE ===");else $display("=== FAILED %0d ===",bad);
  $finish;
 end
endmodule
