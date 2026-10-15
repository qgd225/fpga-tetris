`timescale 1ns/1ps

//===== frame 级双人显示测试: P2 方块/落格/下一块/虚线/面板位置 =====
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = 32'h0;      // 桩: 单格(偏移 0)
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

module frame_duo_tb;
reg Clk=0, Rst=0;
reg [10:0] hc=0, vc=0;
reg duo=0, choose=0, Idle=0, Playing=1, Stop=0, Finalize=0;
reg [3:0] choose_cnt=0;
reg l1=0,r1=0,d1=0,de1=0,rt1=0,sw1=0,hd1=0;
reg l2=0,r2=0,d2=0,de2=0,rt2=0,hd2=0;
wire [23:0] rgb;
wire over, clear;
wire [2:0] speed_level;
wire [19:0] score;
wire [15:0] lines;
wire [13:0] time_sec;

always #6.734 Clk = ~Clk;

frame dut(
  .Clk_74M(Clk), .Reset_n(Rst), .hcounter(hc), .vcounter(vc),
  .left_p_flag(l1), .right_p_flag(r1), .drop_r_flag(d1), .drop_en(de1),
  .rotate_p_flag(rt1), .switch_r_flag(sw1), .hold_p_flag(hd1),
  .Idle(Idle), .Playing(Playing), .Stop(Stop), .Finalize(Finalize),
  .choose(choose), .choose_cnt(choose_cnt), .duo(duo),
  .left_p_flag2(l2), .right_p_flag2(r2), .drop_r_flag2(d2), .drop_en2(de2),
  .rotate_p_flag2(rt2), .hold_p_flag2(hd2),
  .rgb(rgb), .over(over), .clear(clear), .speed_level(speed_level),
  .score(score), .lines(lines), .time_sec(time_sec)
);

integer bad;
task chk;
input [8*30-1:0] name; input [23:0] got; input [23:0] exp;
begin
  if(got !== exp)begin $display("  FAIL %0s got=%h exp=%h", name, got, exp); bad = bad + 1; end
  else $display("  ok   %0s = %h", name, got);
end
endtask
task look;
input [10:0] x; input [10:0] y;
begin hc = x; vc = y; repeat(3) @(posedge Clk); end
endtask
task lock2;
begin
  force dut.Playfield_inst.counter_land2 = 25'd20_000_000;
  @(posedge Clk); release dut.Playfield_inst.counter_land2; @(posedge Clk);
  force dut.Playfield_inst.lock_counter2 = 25'd5_940_000;
  @(posedge Clk); release dut.Playfield_inst.lock_counter2;
  repeat(10) @(posedge Clk);
end
endtask
task clr_state;
integer q;
begin
  force dut.Playfield_inst.state = 480'd0; @(posedge Clk);
  release dut.Playfield_inst.state; @(posedge Clk);
  for(q = 0; q < 480; q = q + 1) dut.state_color[q] = 3'd0;
end
endtask

// 颜色常量(与 frame 一致)
`define CYAN   24'h00CCFF
`define YELLOW 24'hFFF_F00
`define RED    24'hE63946
`define WHITE  24'hFFF_FFF
`define BLACK  24'h000_000

initial begin
  bad = 0;
  Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk);
  force dut.Playfield_inst.Drop = 30'd100_000_000;   // 关自动下落

  $display("=== 1) 双人: P2 方块像素(同色表) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd20; force dut.Playfield_inst.counter_r2 = 5'd0;
  force dut.Playfield_inst.type2 = 3'd0;
  look(11'd971, 11'd91);                       // 第20列 第0行
  chk("duo=1 P2 方块=青色", rgb, `CYAN);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd971, 11'd91);
  chk("duo=0 同一位置无 P2 方块", rgb, `BLACK);
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  clr_state;

  $display("=== 2) 双人: P2 落格后该格显示颜色 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  force dut.Playfield_inst.type2 = 3'd3;
  repeat(4) @(posedge Clk);
  lock2;                                        // P2 锁到 (10,19)
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd641, 11'd689);                       // 第10列 第19行
  chk("duo=1 P2 落格=红色", rgb, `RED);
  clr_state;
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  repeat(4) @(posedge Clk);
  lock2;                                        // 单机: 不应写入
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd641, 11'd689);
  chk("duo=0 P2 落格不显示", rgb, `BLACK);
  clr_state;

  $display("=== 3) 24 列场地右侧格子也能显示 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  dut.state_color[23*20 + 5] = 3'd3; dut.Playfield_inst.state[23*20 + 5] = 1'b1;
  look(11'd1067, 11'd251);                      // 第23列 第5行
  chk("duo=1 第23列格子=红色", rgb, `RED);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1067, 11'd251);
  chk("duo=0 第23列在场地外", rgb, `BLACK);
  clr_state;
  dut.state_color[23*20 + 5] = 3'd0; dut.Playfield_inst.state[23*20 + 5] = 1'b0;

  $display("=== 4) Next 盒子位置(双人右移加高) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd1104, 11'd100);  chk("duo=1 Next 左边框(1104)", rgb, `WHITE);
  look(11'd1040, 11'd100);  chk("duo=1 单机位置为空", rgb, `BLACK);
  look(11'd1120, 11'd203);  chk("duo=1 中间虚线亮段", rgb, `WHITE);
  look(11'd1128, 11'd203);  chk("duo=1 中间虚线暗段", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1040, 11'd100);  chk("duo=0 Next 左边框(1040)", rgb, `WHITE);
  look(11'd1104, 11'd100);  chk("duo=0 双人位置为空", rgb, `BLACK);

  $display("=== 5) 双人: P2 下一块预览 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.type_t2 = 3'd3;
  look(11'd1161, 11'd316);                      // P2 预览格(1,3)
  chk("duo=1 P2 下一块=红色", rgb, `RED);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1161, 11'd316);
  chk("duo=0 无 P2 下一块", rgb, `BLACK);
  release dut.Playfield_inst.type_t2;

  $display("=== 6) Hold 盒子位置 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd1104, 11'd400);  chk("duo=1 Hold 左边框(1104,400)", rgb, `WHITE);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1040, 11'd300);  chk("duo=0 Hold 左边框(1040,300)", rgb, `WHITE);
  look(11'd1104, 11'd400);  chk("duo=0 双人 Hold 位置为空", rgb, `BLACK);

  $display("=== 7) 单机 P1 显示回归 ===");
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c = 5'd9; force dut.Playfield_inst.counter_r = 5'd0;
  force dut.Playfield_inst.type = 3'd2;
  look(11'd619, 11'd91);                        // 第9列 第0行
  chk("duo=0 P1 方块=黄色(与原来一致)", rgb, `YELLOW);
  release dut.Playfield_inst.counter_c; release dut.Playfield_inst.counter_r; release dut.Playfield_inst.type;

  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
