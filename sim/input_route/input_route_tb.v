`timescale 1ns/1ps

module input_route_tb;
reg duo = 0;
reg btn_left=0, btn_right=0, btn_drop_r=0, btn_drop_en=0, btn_rotate=0, btn_hold=0;
reg btn_left_held=0, btn_right_held=0;
reg pc_left=0, pc_right=0, pc_drop_r=0, pc_drop_en=0, pc_rotate=0, pc_hold=0;
reg pc_left_held=0, pc_right_held=0;
wire p1_left,p1_right,p1_drop_r,p1_drop_en,p1_rotate,p1_hold;
wire p1_left_held,p1_right_held;
wire p2_left,p2_right,p2_drop_r,p2_drop_en,p2_rotate,p2_hold;
wire p2_left_held,p2_right_held;
integer bad=0;

control_route dut(
.duo(duo),
.btn_left(btn_left), .btn_right(btn_right),
.btn_drop_r(btn_drop_r), .btn_drop_en(btn_drop_en),
.btn_rotate(btn_rotate), .btn_hold(btn_hold),
.btn_left_held(btn_left_held), .btn_right_held(btn_right_held),
.pc_left(pc_left), .pc_right(pc_right),
.pc_drop_r(pc_drop_r), .pc_drop_en(pc_drop_en),
.pc_rotate(pc_rotate), .pc_hold(pc_hold),
.pc_left_held(pc_left_held), .pc_right_held(pc_right_held),
.p1_left(p1_left), .p1_right(p1_right),
.p1_drop_r(p1_drop_r), .p1_drop_en(p1_drop_en),
.p1_rotate(p1_rotate), .p1_hold(p1_hold),
.p1_left_held(p1_left_held), .p1_right_held(p1_right_held),
.p2_left(p2_left), .p2_right(p2_right),
.p2_drop_r(p2_drop_r), .p2_drop_en(p2_drop_en),
.p2_rotate(p2_rotate), .p2_hold(p2_hold),
.p2_left_held(p2_left_held), .p2_right_held(p2_right_held)
);

task chk;
input [8*48-1:0] name;
input integer got;
input integer exp;
begin
  if(got !== exp)begin
    $display("  FAIL %0s got=%0d exp=%0d", name, got, exp);
    bad = bad + 1;
  end
  else
    $display("  ok   %0s = %0d", name, got);
end
endtask

task clear_all;
begin
  btn_left=0; btn_right=0; btn_drop_r=0; btn_drop_en=0; btn_rotate=0; btn_hold=0;
  btn_left_held=0; btn_right_held=0;
  pc_left=0; pc_right=0; pc_drop_r=0; pc_drop_en=0; pc_rotate=0; pc_hold=0;
  pc_left_held=0; pc_right_held=0;
  #1;
end
endtask

initial begin
  $display("=== input_route 输入路由 ===");
  clear_all; duo=0; btn_left=1; #1;
  chk("solo btn left -> P1", p1_left, 1);
  chk("solo btn left -> no P2", p2_left, 0);
  clear_all; duo=0; btn_left_held=1; #1;
  chk("solo btn left held -> P1", p1_left_held, 1);
  chk("solo btn left held -> no P2", p2_left_held, 0);
  clear_all; duo=0; pc_left=1; pc_right=1; pc_drop_r=1; pc_drop_en=1; pc_rotate=1; pc_hold=1; #1;
  chk("solo pc left -> P1", p1_left, 1);
  chk("solo pc right -> P1", p1_right, 1);
  chk("solo pc drop_r -> P1", p1_drop_r, 1);
  chk("solo pc drop_en -> P1", p1_drop_en, 1);
  chk("solo pc rotate -> P1", p1_rotate, 1);
  chk("solo pc hold -> P1", p1_hold, 1);
  chk("solo pc left -> no P2", p2_left, 0);
  chk("solo pc hold -> no P2", p2_hold, 0);
  clear_all; duo=0; pc_right_held=1; #1;
  chk("solo pc right held -> P1", p1_right_held, 1);
  chk("solo pc right held -> no P2", p2_right_held, 0);
  clear_all; duo=1; btn_right=1; btn_hold=1; #1;
  chk("duo btn right -> P1", p1_right, 1);
  chk("duo btn hold -> P1", p1_hold, 1);
  chk("duo btn right -> no P2", p2_right, 0);
  clear_all; duo=1; btn_right_held=1; #1;
  chk("duo btn right held -> P1", p1_right_held, 1);
  chk("duo btn right held -> no P2", p2_right_held, 0);
  clear_all; duo=1; pc_left=1; pc_right=1; pc_drop_r=1; pc_drop_en=1; pc_rotate=1; pc_hold=1;
  pc_left_held=1; pc_right_held=1; #1;
  chk("duo pc left -> P2", p2_left, 1);
  chk("duo pc right -> P2", p2_right, 1);
  chk("duo pc drop_r -> P2", p2_drop_r, 1);
  chk("duo pc drop_en -> P2", p2_drop_en, 1);
  chk("duo pc rotate -> P2", p2_rotate, 1);
  chk("duo pc hold -> P2", p2_hold, 1);
  chk("duo pc left -> no P1", p1_left, 0);
  chk("duo pc hold -> no P1", p1_hold, 0);
  chk("duo pc left held -> P2", p2_left_held, 1);
  chk("duo pc left held -> no P1", p1_left_held, 0);
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
