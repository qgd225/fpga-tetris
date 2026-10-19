`timescale 1ns/1ps

//===== Playfield Duo ר�����: ��ײ/��ס/����/����Hold/������/ʱ����ֵ/���� =====
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = duo_tb.shape_val;   // ׮: Ĭ�� 0 -> ����; ��ת����ʱ�� tb ���ϳ���״
endmodule
module weiyibiao(input clka, input [4:0] addra, output [7:0] douta);
  assign douta = 8'h00;   // ׮: ��תƫ�� 0
endmodule

module duo_tb;
reg Clk_74M=0, Rst=0;
reg [10:0] hc=0, vc=0;
reg left1=0, right1=0, drop1=0, drop_en1=0, rot1=0, sw1=0, hold1=0;
reg left2=0, right2=0, drop2=0, drop_en2=0, rot2=0, hold2=0;
reg Idle=0, Playing=1, Stop=0, Finalize=0;
reg [19:0] score=0;
reg [13:0] time_sec=0;
reg duo=1;
reg duu=1;
reg [31:0] shape_val = 32'h0;   // �ϳ���״(Ĭ���˻�����)

wire [479:0] state;
wire Piece, ghost, Piece2, ghost2, over, clear, clear_time, clear_pulse, clear_t_t, clear_t;
wire [4:0] C_num, R_num, C_num2, R_num2, c_clear, clear_row;
wire [2:0] type, type_t, type_d, type2_out, type_t2_out, speed_level;
wire [1:0] lock_idx, lock_idx2;
wire lock_t, lock_we, land_we, en_hold, lock_we2, land_we2;
wire [19:0] cc_d, rr_d, cc_d2, rr_d2, line_t;
wire [2:0] hold_type;
wire ghost_ev1;
wire snd_land2, snd_hard2, snd_soft2, snd_hold2;
wire blk_l2, blk_rot2;

always #6.734 Clk_74M = ~Clk_74M;

Playfield dut(
  .Clk_74M(Clk_74M), .Reset_n(Rst), .hcounter(hc), .vcounter(vc),
  .left_p_flag(left1), .right_p_flag(right1), .drop_r_flag(drop1), .drop_en(drop_en1),
  .rotate_p_flag(rot1), .switch_r_flag(sw1), .hold_p_flag(hold1),
  .Idle(Idle), .Playing(Playing), .hint_enable(1'b1), .Stop(Stop), .Finalize(Finalize),
  .score(score), .time_sec(time_sec), .duo(duo),
  .left_p_flag2(left2), .right_p_flag2(right2), .drop_r_flag2(drop2), .drop_en2(drop_en2),
  .rotate_p_flag2(rot2), .hold_p_flag2(hold2),
  .state(state), .Piece(Piece), .ghost(ghost), .C_num(C_num), .R_num(R_num),
  .C_num2(C_num2), .R_num2(R_num2), .over(over),
  .clear_time(clear_time), .clear_pulse(clear_pulse), .clear_t_t(clear_t_t), .clear_t(clear_t),
  .c_clear(c_clear), .type_t(type_t), .type(type), .clear(clear), .clear_row(clear_row),
  .cc_d(cc_d), .rr_d(rr_d), .lock_t(lock_t), .lock_we(lock_we), .lock_idx(lock_idx),
  .type_d(type_d), .en_hold(en_hold), .hold_type(hold_type), .speed_level(speed_level),
  .land_we(land_we), .line_t(line_t), .Piece2(Piece2), .ghost2(ghost2),
  .type2_out(type2_out), .cc_d2(cc_d2), .rr_d2(rr_d2), .type_d2_out(type_d2_out),
  .lock_we2(lock_we2), .lock_idx2(lock_idx2), .land_we2(land_we2), .type_t2_out(type_t2_out),
  .ghost_ev1(ghost_ev1), .snd_land2(snd_land2), .snd_hard2(snd_hard2),
  .snd_soft2(snd_soft2), .snd_hold2(snd_hold2), .blk_l2(blk_l2), .blk_rot2(blk_rot2)
);

integer bad;
task chk;
input [8*32-1:0] name; input integer got; input integer exp;
begin
  if(got !== exp)begin $display("  FAIL %0s got=%0d exp=%0d", name, got, exp); bad = bad + 1; end
  else $display("  ok   %0s = %0d", name, got);
end
endtask

task chk_no_x;
input [8*32-1:0] name; input [4:0] sig;
begin
  if((^sig) === 1'bx)begin $display("  FAIL %0s ���� X", name); bad = bad + 1; end
  else $display("  ok   %0s �� X (=%0d)", name, sig);
end
endtask

// ��������(ʱ�ӵ͵�ƽ�ڶ���, ���⾺��)
task p_left1;  begin @(negedge Clk_74M); left1 =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); left1 =1'b0; @(posedge Clk_74M); end endtask
task p_right1; begin @(negedge Clk_74M); right1=1'b1; @(posedge Clk_74M); @(negedge Clk_74M); right1=1'b0; @(posedge Clk_74M); end endtask
task p_drop1;  begin @(negedge Clk_74M); drop1 =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); drop1 =1'b0; @(posedge Clk_74M); end endtask
task p_rot1;   begin @(negedge Clk_74M); rot1  =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); rot1  =1'b0; @(posedge Clk_74M); end endtask
task p_hold1;  begin @(negedge Clk_74M); hold1 =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); hold1 =1'b0; @(posedge Clk_74M); end endtask
task p_left2;  begin @(negedge Clk_74M); left2 =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); left2 =1'b0; @(posedge Clk_74M); end endtask
task p_right2; begin @(negedge Clk_74M); right2=1'b1; @(posedge Clk_74M); @(negedge Clk_74M); right2=1'b0; @(posedge Clk_74M); end endtask
task p_drop2;  begin @(negedge Clk_74M); drop2 =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); drop2 =1'b0; @(posedge Clk_74M); end endtask
task p_rot2;   begin @(negedge Clk_74M); rot2  =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); rot2  =1'b0; @(posedge Clk_74M); end endtask
task p_hold2;  begin @(negedge Clk_74M); hold2 =1'b1; @(posedge Clk_74M); @(negedge Clk_74M); hold2 =1'b0; @(posedge Clk_74M); end endtask

task settle; begin repeat(40) @(posedge Clk_74M); end endtask

// P1 Ӳ��(���� drop_en)
task hard1;
begin
  force dut.counter = 27'd74_250_000;
  drop_en1 = 1'b1;
  repeat(4) @(posedge Clk_74M);
  drop_en1 = 1'b0;
  release dut.counter;
  repeat(4) @(posedge Clk_74M);
end
endtask
task hard2;
begin
  force dut.counter2 = 27'd74_250_000;
  drop_en2 = 1'b1;
  repeat(4) @(posedge Clk_74M);
  drop_en2 = 1'b0;
  release dut.counter2;
  repeat(4) @(posedge Clk_74M);
end
endtask

// ����һ������(��������ʱ��ֱ���Ƶ���ֵ)
task lock1;
begin
  force dut.counter_land = 25'd20_000_000;
  @(posedge Clk_74M);
  release dut.counter_land;
  @(posedge Clk_74M);
  force dut.lock_counter = 25'd5_940_000;
  @(posedge Clk_74M);
  release dut.lock_counter;
  repeat(10) @(posedge Clk_74M);
end
endtask
task lock2;
begin
  force dut.counter_land2 = 25'd20_000_000;
  @(posedge Clk_74M);
  release dut.counter_land2;
  @(posedge Clk_74M);
  force dut.lock_counter2 = 25'd5_940_000;
  @(posedge Clk_74M);
  release dut.lock_counter2;
  repeat(10) @(posedge Clk_74M);
end
endtask

task clr_state; begin force dut.state = 480'd0; @(posedge Clk_74M); release dut.state; @(posedge Clk_74M); end endtask

initial begin
  bad = 0;
  Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk_74M);

  $display("=== 1) ������(˫�� = 24 �����ȷֵ�) ===");
  chk("duo=1 P1 ������", dut.counter_c, 8);
  chk("duo=1 P2 ������", dut.counter_c2, 16);
  duo = 1'b0; Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk_74M);
  chk("duo=0 P1 ������", dut.counter_c, 9);
  chk("duo=0 P2 ������", dut.counter_c2, 9);
  duo = 1'b1; Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk_74M);
  force dut.Drop = 30'd100_000_000;      // �ر��Զ�����, ���ھ�ȷ����

  $display("=== 2) ѹ�ڶԷ��˶�������: ͣס������ʼ���� ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("���б��Է���ס", dut.other_down_hold, 1);
  chk("��סʱ���� land", dut.land, 0);
  chk("��סʱ�������ʱ", dut.counter_land, 0);
  p_drop1;
  chk("��סʱ������Ч", dut.counter_r, 10);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  repeat(4) @(posedge Clk_74M);

  $display("=== 3) �Է����� state ��: ����������ײ�������ʱ���� ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  lock2;                                  // P2 ���浽 (8,11)
  chk("P2 ��������ͼ", dut.state[8*20 + 11], 1);
  chk("�Ϸ����� land=1", dut.land, 1);
  repeat(6) @(posedge Clk_74M);
  chk("�����ʱ����", (dut.counter_land > 0), 1);
  lock1;                                  // ���� P1 ���浽 (8,10)
  chk("P1 ���浽��ͼ", dut.state[8*20 + 10], 1);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 4) �Է����� -> �ָ����� ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("����סʱ����", dut.other_down_hold, 1);
  release dut.counter_c2; force dut.counter_c2 = 5'd12;   // �Է�����
  repeat(4) @(posedge Clk_74M);
  chk("���ߺ��ٱ���ס", dut.other_down_hold, 0);
  release dut.counter_r;
  repeat(4) @(posedge Clk_74M);
  chk("���ߺ��ѽ����ס(land ��Ϊ0)", dut.land, 0);
  p_drop1;
  chk("���ߺ�ָ�����", (dut.counter_r > 10), 1);
  release dut.counter_c; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 5) ���ұ��Է���ס ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd9;  force dut.counter_r2 = 5'd10;
  repeat(4) @(posedge Clk_74M);
  p_right1;
  chk("���Ʊ��Է���ס", dut.counter_c, 8);
  release dut.counter_c2; force dut.counter_c2 = 5'd12;
  repeat(4) @(posedge Clk_74M);
  release dut.counter_c;
  repeat(2) @(posedge Clk_74M);
  p_right1;
  chk("�Է��ÿ����������", dut.counter_c, 9);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 6) Ӳ��ͣ�ڶԷ������� + ���鲻��ʾ ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd0;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  settle;
  chk("�������=�Է�������һ��", dut.counter_ghost_r_t, 10);
  chk("���鱻�Է���ס��־", dut.ghost_blk_oth, 1);
  hc = 11'd577; vc = 11'd337;            // ��8�� ��11��
  repeat(2) @(posedge Clk_74M);
  chk("���Է���סʱ��������", ghost, 0);
  release dut.counter_r;
  repeat(2) @(posedge Clk_74M);
  hard1;
  chk("Ӳ��ͣ�ڶԷ�������(��10)", dut.counter_r, 10);
  chk("ͣ�ڶԷ�����ʱ�������ʱ", dut.counter_land, 0);
  hc = 11'd0; vc = 11'd0; repeat(2) @(posedge Clk_74M);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 7) ����������ʾ(�ճ����䵽��) ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd0;
  force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd0;
  settle;
  chk("�������=�ذ�", dut.counter_ghost_r_t, 19);
  chk("δ���Է���ס", dut.ghost_blk_oth, 0);
  hc = 11'd577; vc = 11'd689;            // ��8�� ��19��
  repeat(2) @(posedge Clk_74M);
  chk("����������ʾ", ghost, 1);
  hc = 11'd0; vc = 11'd0; repeat(2) @(posedge Clk_74M);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;

  $display("=== 8) P2 ������(22/23)���鲻���� X ===");
  force dut.counter_c2 = 5'd22; force dut.counter_r2 = 5'd0;
  force dut.counter_c  = 5'd1;  force dut.counter_r  = 5'd0;
  settle;
  chk_no_x("P2 �������", dut.counter_ghost_r_t2);
  chk("P2 �������=�ذ�", dut.counter_ghost_r_t2, 19);
  force dut.counter_c2 = 5'd23;
  settle;
  chk_no_x("P2 ��23���������", dut.counter_ghost_r_t2);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;

  $display("=== 9) ������ת(����������ض���)��Խ���赲 ===");
  force dut.counter_c = 5'd8; force dut.counter_r = 5'd0;
  force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd0;
  force dut.rot = 2'd0;
  shape_val = 32'h0F0F0F0F;              // ÿ��: ��ƫ�� 0, ��ƫ�� -1(����֮��)
  repeat(4) @(posedge Clk_74M);
  release dut.rot;
  repeat(2) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("����(�� -1)��ת������", dut.rot, 1);
  chk_no_x("��ת���к�", dut.rr_r);
  chk("��ת���к�Ϊ��(bit5=1)", dut.rr_r[5], 1);
  shape_val = 32'h04040404;              // ��ƫ�� +4
  force dut.counter_r = 5'd16;           // 16+4 = 20 �� = �ذ�����
  repeat(4) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("��ת���ذ����±��赲", dut.rot, 1);
  shape_val = 32'h50505050;              // ��ƫ�� +5(�߰��ֽ�)
  force dut.counter_r = 5'd0; force dut.counter_c = 5'd20;   // 20+5 = 25 > 23
  repeat(4) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("��ת�����ǽ���赲", dut.rot, 1);
  shape_val = 32'h0;
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 10) ���˹���һ�� Hold �� ===");
  force dut.type  = 3'd3;  force dut.type2 = 3'd5;
  repeat(4) @(posedge Clk_74M);
  p_hold1; repeat(2) @(posedge Clk_74M);
  chk("P1 �� -> ��=P1 �Ŀ�", dut.hold_type, 3);
  p_hold2; repeat(2) @(posedge Clk_74M);
  chk("P2 �� -> ��=P2 �Ŀ�", dut.hold_type, 5);
  p_hold2; repeat(2) @(posedge Clk_74M);
  chk("P2 ȡ -> �۽��� P2 ��һ��", dut.type_t2, 5);
  p_hold1; repeat(2) @(posedge Clk_74M);
  chk("P1 ȡ -> �۽��� P1 ��һ��", dut.type_t, 5);
  release dut.type; release dut.type2;
  repeat(4) @(posedge Clk_74M);

  $display("=== 11) ����һ�������: ����ȡ�黥������ ===");
  begin : rnd_loop
    integer t0, n_chg;
    n_chg = 0;
    force dut.counter_c = 5'd8; force dut.counter_r = 5'd2;
    force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd2;
    t0 = dut.type;
    for(integer q = 0; q < 5; q = q + 1)begin
      lock1;
      if(dut.type !== t0) n_chg = n_chg + 1;
      t0 = dut.type;
      if(dut.type > 6) bad = bad + 1;
    end
    chk("P1 ����ȡ���б仯(�����ƽ�)", (n_chg > 0), 1);
    chk("P1 ȡ�Ŀ�Ϸ�", (dut.type <= 6), 1);
    release dut.counter_c; release dut.counter_r;
    clr_state;
    force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd2;
    t0 = dut.type2;
    n_chg = 0;
    for(integer q2 = 0; q2 < 5; q2 = q2 + 1)begin
      lock2;
      if(dut.type2 !== t0) n_chg = n_chg + 1;
      t0 = dut.type2;
    end
    chk("P2 ����ȡ���б仯(�����ƽ�)", (n_chg > 0), 1);
    chk("P2 ȡ�Ŀ�Ϸ�", (dut.type2 <= 6), 1);
    release dut.counter_c2; release dut.counter_r2;
    clr_state;
  end

  $display("=== 12) �������� P2 Ӱ��(��ײ�ر�) ===");
  duo = 1'b0; repeat(4) @(posedge Clk_74M);
  force dut.counter_c  = 5'd8; force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8; force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("�������ж�ס", dut.other_down_hold, 0);
  chk("���� land ֻ����ͼ/�ذ�", dut.land, 0);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  duo = 1'b1; repeat(4) @(posedge Clk_74M);
  clr_state;

  $display("=== 13) ˫��ʱ����ֵ(40/120/240/400/600/880/1200) ===");
  score = 20'd0;
  duo = 1'b1;
  time_sec = 14'd39;  repeat(4) @(posedge Clk_74M); chk("duo 39s",  speed_level, 0);
  time_sec = 14'd40;  repeat(4) @(posedge Clk_74M); chk("duo 40s",  speed_level, 1);
  time_sec = 14'd120; repeat(4) @(posedge Clk_74M); chk("duo 120s", speed_level, 2);
  time_sec = 14'd240; repeat(4) @(posedge Clk_74M); chk("duo 240s", speed_level, 3);
  time_sec = 14'd400; repeat(4) @(posedge Clk_74M); chk("duo 400s", speed_level, 4);
  time_sec = 14'd600; repeat(4) @(posedge Clk_74M); chk("duo 600s", speed_level, 5);
  time_sec = 14'd880; repeat(4) @(posedge Clk_74M); chk("duo 880s", speed_level, 6);
  time_sec = 14'd1200;repeat(4) @(posedge Clk_74M); chk("duo 1200s", speed_level, 7);
  score = 20'd4; time_sec = 14'd0;
  repeat(4) @(posedge Clk_74M); chk("duo �����ȼ�����Ч", speed_level, 1);
  $display("=== 14) ����ʱ����ֵ�ع�(20/60/...) ===");
  duo = 1'b0; score = 20'd0;
  time_sec = 14'd19;  repeat(4) @(posedge Clk_74M); chk("solo 19s", speed_level, 0);
  time_sec = 14'd20;  repeat(4) @(posedge Clk_74M); chk("solo 20s", speed_level, 1);
  time_sec = 14'd60;  repeat(4) @(posedge Clk_74M); chk("solo 60s", speed_level, 2);
  time_sec = 14'd600; repeat(4) @(posedge Clk_74M); chk("solo 600s", speed_level, 7);
  duo = 1'b1; time_sec = 14'd0; repeat(4) @(posedge Clk_74M);

  $display("=== 17) ����: ���ر仯��Ҫ����, �Ҳ����ܵ������Ϸ� ===");
  begin : ghost_chk
    clr_state;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
    // (a) �ճ���: ����Ӧ�ڵذ�(19)
    force dut.counter_c = 5'd8;  force dut.counter_r = 5'd0;
    force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd0;
    settle;
    chk("�ճ�������=19", dut.counter_ghost_r_t, 19);
    // (b) �Է�����ѹ���·�(�˶�����): ����ǯλ��"������һ��", �ұ�Ǳ��Է���ס
    release dut.counter_c2; force dut.counter_c2 = 5'd8; force dut.counter_r2 = 5'd11;
    settle;
    chk("���Է��˶����鵲סʱ����=10", dut.counter_ghost_r_t, 10);
    chk("��ʱ�������ر��=1", dut.ghost_blk_oth, 1);
    // (c) �Է���������: ���ر仯���봥������ -> ��������10, ����Ϊ"�����������"(Ҫ��ʾ)
    lock2;
    repeat(6) @(posedge Clk_74M);
    chk("�Է���������=10", dut.counter_ghost_r_t, 10);
    chk("�Է�����������ʾ(�����ǶԷ�����)", dut.ghost_blk_oth, 0);
    // (d) ���鱾�����ڱ�������(�ص�): ���鲻���ܵ������Ϸ�
    force dut.counter_r = 5'd11;
    settle;
    chk("��㱻��ʱ����ǯλ>=������", (dut.counter_ghost_r_t >= dut.counter_r), 1);
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
    clr_state;
  end

  $display("=== 15) ����: ���� 24 ����� ===");
  clr_state;
  for(integer c1 = 0; c1 < 12; c1 = c1 + 1) dut.state[c1*20 + 5] = 1'b1;
  repeat(2) @(posedge Clk_74M);
  chk("ֻ�� 12 ������", clear, 0);
  clr_state;
  for(integer c2 = 0; c2 < 24; c2 = c2 + 1) dut.state[c2*20 + 5] = 1'b1;
  repeat(2) @(posedge Clk_74M);
  chk("���� 24 ������", clear, 1);
  clr_state;
  for(integer c3 = 0; c3 < 24; c3 = c3 + 1)begin
    dut.state[c3*20 + 5] = 1'b1;
    dut.state[c3*20 + 7] = 1'b1;
  end
  repeat(3) @(posedge Clk_74M);
  chk("����ͬʱ�� clear=1", clear, 1);
  chk("d_clear=2", dut.d_clear, 2);
  clr_state;

  $display("=== 16) ���ȡ��: ʱ����� / ͬ�ķ��� / Idle ���� ===");
  begin : rnd_chk
    reg [2:0] t_a;
    reg [31:0] exp_ns;
    integer q, qn, d1, d2, d3;
    reg [2:0] t1, t2;
    force dut.counter_c = 5'd1; force dut.counter_r = 5'd19;
    force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd19;
    Idle = 1'b0; Playing = 1'b1; repeat(4) @(posedge Clk_74M);
    t_a = dut.rnd_type_t;
    d3 = 0;
    for(qn = 0; qn < 6; qn = qn + 1)begin
      repeat(5) @(posedge Clk_74M);
      if(dut.rnd_type_t !== t_a) d3 = d3 + 1;
      t_a = dut.rnd_type_t;
    end
    chk("Playing ��ȡ��ʱȡ��ֵ��ʱ��仯", (d3 > 0), 1);
    d2 = 0;
    for(q = 0; q < 8; q = q + 1)begin
      exp_ns = {dut.rnd[30:0], dut.rnd[31]^dut.rnd[21]^dut.rnd[1]^dut.rnd[0]};
      @(posedge Clk_74M);
      if(dut.rnd !== exp_ns) d2 = d2 + 1;
    end
    chk("Playing ʱ���ӽ���", d2, 0);
    Idle = 1'b1; Playing = 1'b0; repeat(4) @(posedge Clk_74M);
    d1 = 0;
    for(q = 0; q < 8; q = q + 1)begin
      exp_ns = {dut.rnd[30:0], dut.rnd[31]^dut.rnd[21]^dut.rnd[1]^dut.rnd[0]};
      @(posedge Clk_74M);
      if(dut.rnd !== exp_ns) d1 = d1 + 1;
    end
    chk("Idle ������Ч", (d1 > 0), 1);
    Idle = 1'b0; Playing = 1'b1; repeat(2) @(posedge Clk_74M);
    force dut.rnd = 32'h000000F0; force dut.rnd_cnt = 16'h0000;
    repeat(2) @(posedge Clk_74M);
    force dut.land_pulse = 1'b1; force dut.land_pulse2 = 1'b1;
    @(posedge Clk_74M);
    release dut.land_pulse; release dut.land_pulse2;
    repeat(2) @(posedge Clk_74M);
    t1 = dut.type_t; t2 = dut.type_t2;
    $display("  [info] ͬ��ȡ��(��̬): P1 next=%0d, P2 next=%0d", t1, t2);
    chk("ͬ�������õ���ͬ��", (t1 !== t2), 1);
    release dut.rnd; release dut.rnd_cnt;
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  end

  $display("=== 20) �������: ɨ��������ҲҪ����(����ͣ��ֵ) ===");
  begin : ghost_row_chk
    clr_state;
    duo = 1'b0; repeat(4) @(posedge Clk_74M);
    force dut.clear_t = 1'b0;                  // ǰ��������µ����׻ᵲס������ʾ
    force dut.counter_land = 25'd0; force dut.lock_counter = 25'd0;
    force dut.lock_t = 1'b0; force dut.lock_cnt = 2'd0;
    force dut.drop_r_t = 1'b1;
    force dut.counter_c = 5'd5; force dut.counter_r = 5'd5;
    shape_val = 32'h30201000;                    // 4 ��ͬ��(��ƫ��ȫ 0): ê����ൽ 19
    p_rot1; repeat(20) @(posedge Clk_74M);
    chk("��ƫ��ȫ 0: ���=19", dut.counter_ghost_r_t, 19);
    shape_val = 32'h1F0FFFFE;                    // ��ƫ�� -1/-2(û�� 0): ê����뵽 20
    p_rot1; repeat(30) @(posedge Clk_74M);
    chk("��ƫ�� -1/-2: ���=20", dut.counter_ghost_r_t, 20);
    hc = 11'd481; vc = 11'd689;                  // ��5�� ��19��, �ճ���: ����Ӧ������
    repeat(2) @(posedge Clk_74M);
    chk("���黭�ڵ�19��(������)", ghost, 1);
    hc = 11'd0; vc = 11'd0; repeat(2) @(posedge Clk_74M);
    release dut.counter_c; release dut.counter_r;
    hard1;                                       // Ӳ��Ҫͣ�����
    chk("Ӳ��ͣ�����(20)", dut.counter_r, 20);
    chk("ͣ�����ʱ���������", dut.land, 1);
    release dut.counter_land; release dut.lock_counter;
    release dut.lock_t; release dut.lock_cnt; release dut.drop_r_t; release dut.clear_t;
    shape_val = 32'h0;
    clr_state;
  end

  $display("=== 21) ���鲻��ѹ�ڶԷ��˶������� ===");
  begin : ghost_oth_chk
    clr_state;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
    shape_val = 32'h000FFFFE;                    // J rot3: (-1,-2)(-1,-1)(0,-1)(0,0)
    force dut.counter_c  = 5'd16; force dut.counter_r  = 5'd19;   // P1: (15,17)(15,18)(16,18)(16,19)
    force dut.counter_c2 = 5'd16; force dut.counter_r2 = 5'd4;    // P2: (15,2)(15,3)(16,3)(16,4)
    p_rot1; p_rot2; repeat(40) @(posedge Clk_74M);
    chk("P2 �������� P1 �����Ϸ�(=17)", dut.counter_ghost_r_t2, 17);
    chk("���Է����鵲סҪ���", dut.ghost_blk_oth2, 1);
    chk("P1 �������ڵװ�(=19)", dut.counter_ghost_r_t, 19);
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
    hard2;                                       // Ӳ��Ҫͣ�ڶԷ�������
    chk("P2 Ӳ��ͣ�ڶԷ�������(17)", dut.counter_r2, 17);
    shape_val = 32'h0;
    clr_state;
  end

  $display("=== 22) C_num/R_num ���: ��ԭ�����Ƚ���λ�ȼ� ===");
  begin : num_chk
    integer hc2, vc2, bad_c, bad_r, c_exp, r_exp, o2, p2, col_now;
    bad_c = 0; bad_r = 0;
    duu = 1'b1; col_now = 24;
    for(hc2 = 300; hc2 <= 1100; hc2 = hc2 + 1)begin
      hc = hc2[10:0]; vc = 11'd400;
      #1;
      c_exp = 24;
      for(o2 = 0; o2 < 24; o2 = o2 + 1)
      if((o2 < col_now) && (hc2 >= (321 + 32*o2)) && (hc2 < (351 + 32*o2))) c_exp = o2;
      if(C_num !== c_exp[4:0]) bad_c = bad_c + 1;
    end
    chk("duo=1 �б�����һ��(801 ��)", bad_c, 0);
    for(vc2 = 60; vc2 <= 740; vc2 = vc2 + 1)begin
      hc = 11'd577; vc = vc2[10:0];
      #1;
      r_exp = 24;
      for(p2 = 0; p2 < 20; p2 = p2 + 1)
      if((vc2 >= (81 + 32*p2)) && (vc2 < (111 + 32*p2))) r_exp = p2;
      if(R_num !== r_exp[4:0]) bad_r = bad_r + 1;
    end
    chk("duo=1 �б�����һ��(681 ��)", bad_r, 0);
    duo = 1'b0; col_now = 20; bad_c = 0; bad_r = 0;
    for(hc2 = 300; hc2 <= 1100; hc2 = hc2 + 1)begin
      hc = hc2[10:0]; vc = 11'd400;
      #1;
      c_exp = 24;
      for(o2 = 0; o2 < 24; o2 = o2 + 1)
      if((o2 < col_now) && (hc2 >= (321 + 32*o2)) && (hc2 < (351 + 32*o2))) c_exp = o2;
      if(C_num !== c_exp[4:0]) bad_c = bad_c + 1;
    end
    chk("duo=0 �б�����һ��(801 ��)", bad_c, 0);
    duo = 1'b1;
    hc = 11'd0; vc = 11'd0; #1;
  end

  $display("=== 23) ghost rescan excludes vertical down ===");
  begin : ghost_down_chk
    clr_state;
    duo = 1'b1; Playing = 1'b1; Stop = 1'b0; Finalize = 1'b0;
    force dut.counter_c = 5'd5;  force dut.counter_r = 5'd5;
    force dut.counter_c2 = 5'd10; force dut.counter_r2 = 5'd5;
    force dut.type2 = 3'd1; force dut.rot2 = 2'd0;
    force dut.sig_p2_d = 11'b1_01010_001_00;
    #1; chk("P2 down no ghost rescan", ghost_ev1, 0);
    force dut.counter_c2 = 5'd11;
    #1; chk("P2 horizontal still rescan", ghost_ev1, 1);
    release dut.counter_c; release dut.counter_r;
    release dut.counter_c2; release dut.counter_r2;
    release dut.type2; release dut.rot2; release dut.sig_p2_d;
  end

  $display("=== 24) solo gates all P2 sound events ===");
  begin : p2_sound_gate
    duo = 1'b0;
    force dut.lock_t2 = 1'b1;
    #1; chk("solo land2 muted", snd_land2, 0);
    duo = 1'b1; #1; chk("duo land2 active", snd_land2, 1);
    duo = 1'b0;
    force dut.drop_hold2 = 1'b1; #1; chk("solo hard2 muted", snd_hard2, 0);
    duo = 1'b1; #1; chk("duo hard2 active", snd_hard2, 1);
    duo = 1'b0;
    force dut.drop_r2 = 1'b1; #1; chk("solo soft2 muted", snd_soft2, 0);
    duo = 1'b1; #1; chk("duo soft2 active", snd_soft2, 1);
    duo = 1'b0;
    force dut.hold_up2 = 1'b1; #1; chk("solo hold2 muted", snd_hold2, 0);
    duo = 1'b1; #1; chk("duo hold2 active", snd_hold2, 1);
    duo = 1'b0;
    force dut.left_p_flag2 = 1'b1; force dut.boundary_collision_left2 = 1'b1;
    #1; chk("solo left block2 muted", blk_l2, 0);
    duo = 1'b1; #1; chk("duo left block2 active", blk_l2, 1);
    duo = 1'b0;
    force dut.rotate_p_flag2 = 1'b1; force dut.rot_block2 = 1'b1; force dut.lock_we2 = 1'b0;
    #1; chk("solo rot block2 muted", blk_rot2, 0);
    duo = 1'b1; #1; chk("duo rot block2 active", blk_rot2, 1);
    release dut.lock_t2; release dut.drop_hold2; release dut.drop_r2; release dut.hold_up2;
    release dut.left_p_flag2; release dut.boundary_collision_left2;
    release dut.rotate_p_flag2; release dut.rot_block2; release dut.lock_we2;
    duo = 1'b1;
  end
  $display("=== 25) ghost keeps old row during rescan ===");
  begin : ghost_hold_chk
    clr_state;
    duo = 1'b0; repeat(4) @(posedge Clk_74M);
    force dut.clear_t = 1'b0;
    force dut.counter_land = 25'd0; force dut.lock_counter = 25'd0;
    force dut.lock_t = 1'b0; force dut.lock_cnt = 2'd0;
    force dut.drop_r_t = 1'b1;
    force dut.counter_c = 5'd5; force dut.counter_r = 5'd5;
    shape_val = 32'h30201000;
    p_rot1; repeat(24) @(posedge Clk_74M);
    chk("ghost valid after first scan", dut.ghost_valid, 1);
    chk("ghost old row 19", dut.counter_ghost_r_t, 19);
    hc = 11'd481; vc = 11'd689; repeat(2) @(posedge Clk_74M);
    chk("ghost visible before restart", ghost, 1);
    force dut.ghost_restart1 = 1'b1; @(posedge Clk_74M);
    release dut.ghost_restart1; @(posedge Clk_74M);
    chk("ghost valid survives restart", dut.ghost_valid, 1);
    chk("ghost row held during scan", dut.counter_ghost_r_t, 19);
    chk("ghost visible during scan", ghost, 1);
    repeat(30) @(posedge Clk_74M);
    chk("ghost valid after rescan", dut.ghost_valid, 1);
    release dut.counter_c; release dut.counter_r;
    release dut.counter_land; release dut.lock_counter;
    release dut.lock_t; release dut.lock_cnt; release dut.drop_r_t; release dut.clear_t;
    shape_val = 32'h0; hc = 11'd0; vc = 11'd0; clr_state;
  end
  $display("=== 26) hint search starts only after lock writes finish ===");
  begin : hint_lock_done_chk
    duo = 1'b0; Playing = 1'b1; Idle = 1'b0; Stop = 1'b0; Finalize = 1'b0;
    clr_state; repeat(20) @(posedge Clk_74M);
    force dut.new_piece1 = 1'b0;
    force dut.hold_up = 1'b0;
    force dut.clear_down = 1'b0;
    force dut.lock_we = 1'b1;
    repeat(3) @(posedge Clk_74M); #1;
    chk("no hint start during lock writes", dut.hint_start, 0);
    force dut.lock_we = 1'b0; #1;
    chk("hint start on lock falling edge", dut.hint_start, 1);
    @(posedge Clk_74M); #1;
    chk("hint start pulse ends", dut.hint_start, 0);
    release dut.new_piece1; release dut.hold_up; release dut.clear_down;
    release dut.lock_we;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
  end
  $display("=== 27) normal piece/field changes do not restart hint ===");
  begin : hint_no_flash_chk
    duo = 1'b0; Playing = 1'b1; Idle = 1'b0; Stop = 1'b0; Finalize = 1'b0;
    repeat(20) @(posedge Clk_74M);
    force dut.new_piece1 = 1'b1;
    force dut.field_chg = 1'b1;
    #1; chk("new piece alone no restart", dut.hint_start, 0);
    release dut.new_piece1; release dut.field_chg;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
  end
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
