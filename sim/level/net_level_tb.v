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
integer bad, m, sp;

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
  force dut.batch_n = k;
  force dut.batch_speed = dut.story_inst.story_speed;
  for(m=0; m<n; m=m+1)begin
    @(negedge Clk_74M);
    force dut.batch_commit = 1'b1;
    @(negedge Clk_74M);
    release dut.batch_commit;
    @(posedge Clk_74M);
  end
  release dut.batch_n; release dut.batch_speed;
  repeat(8) @(posedge Clk_74M);
end
endtask

initial begin
  // 视觉/数值单元测试隔离顶出；真实终局由 sim/story 联合验证。
  force dut.over_raw=0;
  bad = 0;
  Rst = 0; #200; Rst = 1;
  repeat(20) @(posedge Clk_74M);

  $display("=== batch scoring and mission-only speed ===");
  set_score(20'd0); rel_score;add_clear(1,1);chk("one line batch",score,2);
  set_score(20'd0); rel_score;add_clear(1,2);chk("two separate batches",score,4);
  set_score(20'd0); rel_score;add_clear(4,1);chk("four-line batch once",score,32);
  force dut.story_inst.story_speed=3'd3;
  set_score(20'd0);rel_score;add_clear(2,1);chk("captured batch multiplier",score,32);
  force dut.story_inst.story_speed=0;
  release dut.story_inst.story_speed;
  set_score(20'd999999);set_time(999);
  chk("time and score cannot override mission",speed_level,0);
  rel_score;rel_time;
  for(sp=0;sp<8;sp=sp+1)begin
    force dut.story_inst.story_speed=sp[2:0];repeat(4)@(negedge Clk_74M);
    case(sp)
      0:chk("Drop0",dut.Playfield_inst.Drop,(64'd74218749*80)/100);
      1:chk("Drop1",dut.Playfield_inst.Drop,(64'd74218749*71)/100);
      2:chk("Drop2",dut.Playfield_inst.Drop,(64'd74218749*63)/100);
      3:chk("Drop3",dut.Playfield_inst.Drop,(64'd74218749*55)/100);
      4:chk("Drop4",dut.Playfield_inst.Drop,(64'd74218749*46)/100);
      5:chk("Drop5",dut.Playfield_inst.Drop,(64'd74218749*38)/100);
      6:chk("Drop6",dut.Playfield_inst.Drop,(64'd74218749*30)/100);
      7:chk("Drop7",dut.Playfield_inst.Drop,(64'd74218749*21)/100);
    endcase
  end
  release dut.story_inst.story_speed;
  @(negedge Clk_74M);Stop=1;
  dut.timer_inst.counter=74218749;
  dut.timer_inst.counter0=0;dut.timer_inst.counter1=0;
  dut.timer_inst.counter2=0;dut.timer_inst.counter3=0;
  repeat(4)@(negedge Clk_74M);chk("pause at exact second does not carry",time_sec,0);
  Stop=0;@(negedge Clk_74M);chk("resume carries once",time_sec,1);
  repeat(4)@(negedge Clk_74M);chk("second boundary not repeated",time_sec,1);

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
      repeat(44) @(posedge Clk_74M);
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
    force dut.story_inst.story_speed = 3'd3;
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
    release dut.story_inst.story_speed;
    hc = 11'd0; vc = 11'd0;
  end
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
