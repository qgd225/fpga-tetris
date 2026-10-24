// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps

//============================================================
// 测试台：net_level_tb
// 测试目标：单人计分、等级阈值和自动下落速度回归。
//============================================================
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = 32'h0;
endmodule
module weiyibiao(input clka, input [4:0] addra, output [7:0] douta);
  assign douta = 8'h00;
endmodule
module number(input clka, input ena, input [9:0] addra, output [19:0] douta);
  assign douta = 20'h0;
endmodule
module letter(input clka, input ena, input [10:0] addra, output [19:0] douta);
  assign douta = 20'h0;
endmodule

module net_level_tb;
reg Clk_74M=0, Rst=0;
reg [10:0] hc=0, vc=0;
reg left_p=0, right_p=0, drop_r=0, drop_en=0, rotate_p=0, switch_r=0, hold_p=0;
reg Idle=0, Playing=1, Stop=0, Finalize=0;
wire [23:0] rgb; wire over, clear; wire [2:0] speed_level;
wire [19:0] score; wire [15:0] lines; wire [13:0] time_sec;
integer bad, m;

always #6.734 Clk_74M = ~Clk_74M;

frame #(.EFF_TICK(21'd8)) dut(
  .Clk_74M(Clk_74M), .Reset_n(Rst), .hcounter(hc), .vcounter(vc),
  .left_p_flag(left_p), .right_p_flag(right_p), .drop_r_flag(drop_r), .drop_en(drop_en),
  .rotate_p_flag(rotate_p), .switch_r_flag(switch_r), .hold_p_flag(hold_p),
  .Idle(Idle), .Playing(Playing), .Stop(Stop), .Finalize(Finalize),
  .duo(1'b0),
  .left_p_flag2(1'b0), .right_p_flag2(1'b0), .drop_r_flag2(1'b0), .drop_en2(1'b0),
  .rotate_p_flag2(1'b0), .hold_p_flag2(1'b0), .hint_show(1'b0),
  .rgb(rgb), .over(over), .clear(clear), .speed_level(speed_level),
  .score(score), .lines(lines), .time_sec(time_sec));

task chk;
input [8*26-1:0] name; input integer got; input integer exp;
begin
  if(got !== exp)begin $display("  FAIL %0s got=%0d exp=%0d", name, got, exp); bad = bad + 1; end
  else $display("  ok   %0s = %0d", name, got);
end
endtask

task set_score;
input [19:0] s;
begin
  force dut.scoring_inst.counter = s;
  repeat(4) @(posedge Clk_74M);
end
endtask

task rel_score;
begin
  release dut.scoring_inst.counter;
  repeat(4) @(posedge Clk_74M);
end
endtask

task set_time;
input integer s;
begin
  force dut.timer_inst.counter3 = s / 600;
  force dut.timer_inst.counter2 = (s % 600) / 60;
  force dut.timer_inst.counter1 = (s % 60) / 10;
  force dut.timer_inst.counter0 = s % 10;
  repeat(4) @(posedge Clk_74M);
end
endtask

task rel_time;
begin
  release dut.timer_inst.counter3;
  release dut.timer_inst.counter2;
  release dut.timer_inst.counter1;
  release dut.timer_inst.counter0;
  repeat(4) @(posedge Clk_74M);
end
endtask

task add_clear;
input [4:0] k;
input integer n;
begin
  force dut.Playfield_inst.c_clear = k;
  for(m=0; m<n; m=m+1)begin
    @(posedge Clk_74M);
    force dut.Playfield_inst.clear_t_t = 1'b1;
    @(posedge Clk_74M);
    release dut.Playfield_inst.clear_t_t;
    @(posedge Clk_74M);
  end
  release dut.Playfield_inst.c_clear;
  repeat(8) @(posedge Clk_74M);
end
endtask

initial begin
  bad = 0;
  Rst = 0; #200; Rst = 1;
  repeat(20) @(posedge Clk_74M);

  $display("=== 1) 加分 x2 (等级0) ===");
  set_score(20'd0); rel_score;
  add_clear(5'd1, 1);
  chk("1个脉冲 c_clear=1", score, 2);
  set_score(20'd0); rel_score;
  add_clear(5'd1, 2);
  chk("2个脉冲 c_clear=1 (等级仍0)", score, 4);
  set_score(20'd0); rel_score;
  add_clear(5'd4, 1);
  chk("1个脉冲 c_clear=4", score, 8);

  $display("=== 2) 分数等级(4/15/35/70/150/300/600) ===");
  set_time(0);
  set_score(20'd3);    chk("score=3",   speed_level, 0);
  set_score(20'd4);    chk("score=4",   speed_level, 1);
  set_score(20'd14);   chk("score=14",  speed_level, 1);
  set_score(20'd15);   chk("score=15",  speed_level, 2);
  set_score(20'd299);  chk("score=299", speed_level, 5);
  set_score(20'd300);  chk("score=300", speed_level, 6);
  set_score(20'd599);  chk("score=599", speed_level, 6);
  set_score(20'd600);  chk("score=600", speed_level, 7);
  set_score(20'd1000); chk("score=1000",speed_level, 7);

  $display("=== 3) 时间等级(20/60/120/200/300/440/600 秒) ===");
  set_score(20'd0);
  set_time(19);   chk("19s",  speed_level, 0);
  set_time(20);   chk("20s",  speed_level, 1);
  set_time(60);   chk("60s",  speed_level, 2);
  set_time(120);  chk("120s", speed_level, 3);
  set_time(440);  chk("440s", speed_level, 6);
  set_time(599);  chk("599s", speed_level, 6);
  set_time(600);  chk("600s", speed_level, 7);

  $display("=== 4) 取较大者 ===");
  set_score(20'd3);   set_time(60);  chk("分数0+时间2", speed_level, 2);
  set_score(20'd300); set_time(20);  chk("分数6+时间1", speed_level, 6);
  set_score(20'd3);   set_time(600); chk("分数0+时间7", speed_level, 7);
  set_score(20'd600); set_time(0);   chk("分数7+时间0", speed_level, 7);

  $display("=== 5) 清零回落 ===");
  rel_score; rel_time;
  set_score(20'd0); set_time(0);
  repeat(8) @(posedge Clk_74M);
  chk("都清零", speed_level, 0);

  $display("=== 6) 落速表回归 ===");
  repeat(4) @(posedge Clk_74M);
  chk("level0 Drop", dut.Playfield_inst.Drop, (64'd74_249_999*64'd80)/64'd100);
  set_score(20'd600);
  repeat(8) @(posedge Clk_74M);
  chk("level7 Drop", dut.Playfield_inst.Drop, (64'd74_249_999*64'd21)/64'd100);
  rel_score; rel_time;

  $display("=== 7) 分数 BCD(串行转换)与十进制逐位一致 ===");
  begin : bcd_chk
    integer vi, v, e0, e1, e2, e3, e4, e5, badv;
    badv = 0;
    for(vi = 0; vi < 7; vi = vi + 1)begin
      case(vi)
      0: v = 0;
      1: v = 9;
      2: v = 10;
      3: v = 999;
      4: v = 1000;
      5: v = 12345;
      default: v = 999999;
      endcase
      force dut.scoring_inst.counter = v[19:0];
      repeat(40) @(posedge Clk_74M);
      e0 = v % 10;
      e1 = (v / 10) % 10;
      e2 = (v / 100) % 10;
      e3 = (v / 1000) % 10;
      e4 = (v / 10000) % 10;
      e5 = (v / 100000) % 10;
      if((dut.scoring_inst.counter0 !== e0[3:0]) || (dut.scoring_inst.counter1 !== e1[3:0]) ||
         (dut.scoring_inst.counter2 !== e2[3:0]) || (dut.scoring_inst.counter3 !== e3[3:0]) ||
         (dut.scoring_inst.counter4 !== e4[3:0]) || (dut.scoring_inst.counter5 !== e5[3:0]))begin
        $display("  FAIL BCD v=%0d got=%0d%0d%0d%0d%0d%0d exp=%0d%0d%0d%0d%0d%0d", v,
                 dut.scoring_inst.counter5, dut.scoring_inst.counter4, dut.scoring_inst.counter3,
                 dut.scoring_inst.counter2, dut.scoring_inst.counter1, dut.scoring_inst.counter0,
                 e5, e4, e3, e2, e1, e0);
        badv = badv + 1;
      end
    end
    release dut.scoring_inst.counter;
    chk("分数 BCD 逐位一致(7 个值)", badv, 0);
  end

  $display("=== 8) level energy bar geometry ===");
  begin : level_geom
    force dut.Playfield_inst.speed_level = 3'd3;
    repeat(4) @(posedge Clk_74M);
    hc = 11'd293; vc = 11'd400; #1;
    chk("segment margin", dut.level_inst.margin, 1);
    hc = 11'd293; vc = 11'd402; #1;
    chk("current inner", dut.level_inst.inner, 1);
    chk("current segment", dut.level_inst.cur, 1);
    chk("current segment index", dut.level_inst.seg, 3);
    chk("current cap", dut.level_inst.cap, 1);
    vc = 11'd408; #1;
    chk("cap ends at 6px", dut.level_inst.cap, 0);
    vc = 11'd440; #1;
    chk("current body lit", dut.level_inst.on, 1);
    vc = 11'd360; #1;
    chk("above segment unlit", dut.level_inst.on, 0);
    hc = 11'd267; vc = 11'd440; #1;
    chk("outside left", dut.level_inst.inner, 0);
    hc = 11'd268; #1;
    chk("width starts 268", dut.level_inst.inner, 1);
    hc = 11'd301; #1;
    chk("width ends 301", dut.level_inst.inner, 1);
    hc = 11'd302; #1;
    chk("outside right", dut.level_inst.inner, 0);
    release dut.Playfield_inst.speed_level;
    hc = 11'd0; vc = 11'd0;
  end
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
