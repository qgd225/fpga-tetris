`timescale 1ns/1ps

//===== frame ��˫����ʾ�ع�: P2 �˶���/���/��һ��/Hold/�� HUD ����/�˵��� =====
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = 32'h0000_0000;      // ׮: ƫ��ȫ 0 -> Ԥ����ռ (��1,��3)
endmodule
module weiyibiao(input clka, input [4:0] addra, output [7:0] douta);
  assign douta = 8'h00;
endmodule
module number(input clka, input ena, input [9:0] addra, output [19:0] douta);
  assign douta = 20'hF_FFFF;         // ׮: ȫ��, ���ڶ�������������ɫ
endmodule
module letter(input clka, input ena, input [10:0] addra, output [19:0] douta);
  assign douta = 20'hF_FFFF;         // ׮: ȫ��, ���ڶ��Ա�ǩ/�˵�������ɫ
endmodule

module frame_duo_tb;
reg Clk=0, Rst=0;
reg [10:0] hc=0, vc=0;
reg duo=0, choose=0, Idle=0, Playing=1, Stop=0, Finalize=0, hint_show=0;
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

reg scan_en = 0;
reg [79:0]lit;
reg prev;
integer nrun;
integer nbad;
integer runlen;
integer k;
integer n1;
integer n2;
integer seen_gap;
always@(posedge Clk) if(scan_en) hc <= hc + 11'd1;

frame #(.EFF_TICK(21'd8)) dut(
  .Clk_74M(Clk), .Reset_n(Rst), .hcounter(hc), .vcounter(vc),
  .left_p_flag(l1), .right_p_flag(r1), .drop_r_flag(d1), .drop_en(de1),
  .rotate_p_flag(rt1), .switch_r_flag(sw1), .hold_p_flag(hd1),
  .Idle(Idle), .Playing(Playing), .Stop(Stop), .Finalize(Finalize),
  .choose(choose), .choose_cnt(choose_cnt), .duo(duo),
  .left_p_flag2(l2), .right_p_flag2(r2), .drop_r_flag2(d2), .drop_en2(de2),
  .rotate_p_flag2(rt2), .hold_p_flag2(hd2), .hint_show(hint_show),
  .rgb(rgb), .over(over), .clear(clear), .speed_level(speed_level),
  .score(score), .lines(lines), .time_sec(time_sec)
);

integer bad;
integer ybar;
function [23:0] lvcol;
input [2:0] v;
begin
case(v)
3'd0: lvcol = 24'h00E5FF;
3'd1: lvcol = 24'h55A630;
3'd2: lvcol = 24'hFFF_F00;
3'd3: lvcol = 24'hF77F24;
3'd4: lvcol = 24'hE63946;
3'd5: lvcol = 24'hFF4DA6;
3'd6: lvcol = 24'h9933CC;
default: lvcol = 24'hFFF_FFF;
endcase
end
endfunction
function [23:0] hintcol;
input [2:0] v;
begin
case(v)
3'd0: hintcol = 24'h00CCFF;
3'd1: hintcol = 24'h9933CC;
3'd2: hintcol = 24'hFFF_F00;
3'd3: hintcol = 24'hE63946;
3'd4: hintcol = 24'h55A630;
3'd5: hintcol = 24'hF77F24;
3'd6: hintcol = 24'hFF4DA6;
default: hintcol = 24'h000_000;
endcase
end
endfunction
task chk;
input [8*30-1:0] name; input [23:0] got; input [23:0] exp;
begin
  if(got !== exp)begin $display("  FAIL %0s got=%h exp=%h @(%0d,%0d)", name, got, exp, hc, vc); bad = bad + 1; end
  else $display("  ok   %0s = %h", name, got);
end
endtask
task look;
input [10:0] x; input [10:0] y;
begin hc = x; vc = y; repeat(4) @(posedge Clk); end
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

//    ��ɫ(�� frame һ��)
`define CYAN     24'h00CCFF
`define YELLOW   24'hFFF_F00
`define RED      24'hE63946
`define WHITE    24'hFFF_FFF
`define BLACK    24'h000_000
`define CY_MENU  24'h00E5FF
`define PINK2    24'hFF4DA6
`define GRAY_MID 24'h606060
`define GRAY_LBL 24'hB0B0B0
`define SLOT_BG  24'h202020
`define FLDBG    24'h0A0F16
`define SLOT_P1  24'h081A1E
`define SLOT_P2  24'h1E0812

initial begin
  bad = 0;
  Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk);
  force dut.Playfield_inst.Drop = 30'd100_000_000;   // �����Զ�����

  $display("=== 1) ˫��: P2 �˶�������(ͬɫ��) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd20; force dut.Playfield_inst.counter_r2 = 5'd0;
  force dut.Playfield_inst.type2 = 3'd0;
  look(11'd971, 11'd91);                       // ��20�� ��0��
  chk("duo=1 P2 ����=��ɫ", rgb, `CYAN);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd971, 11'd91);
  chk("duo=0 ͬλ���� P2 ����", rgb, `BLACK);
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  clr_state;

  $display("=== 2) ˫��: P2 ������ʾ��ɫ ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  force dut.Playfield_inst.type2 = 3'd3;
  repeat(4) @(posedge Clk);
  lock2;                                        // P2 ���� (10,19)
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd656, 11'd704);                       // ��10�� ��19��
  chk("duo=1 P2 ���=��ɫ", rgb, `RED);
  clr_state;
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  repeat(4) @(posedge Clk);
  lock2;                                        // ����: ��Ӧд��
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd643, 11'd691);
  chk("duo=0 P2 �����ʾ", rgb, `FLDBG);
  clr_state;

  $display("=== 3) 24 �г�����������Ҳ����ʾ ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  dut.state_color[23*20 + 17] = 3'd3; dut.Playfield_inst.state[23*20 + 17] = 1'b1;
  look(11'd1067, 11'd630);                      // ��23�� ��17��
  chk("duo=1 ��23�и�=��ɫ", rgb, `RED);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1067, 11'd630);
  chk("duo=0 ��23�в��ڳ���", rgb, `BLACK);
  clr_state;
  dut.state_color[23*20 + 17] = 3'd0; dut.Playfield_inst.state[23*20 + 17] = 1'b0;

  $display("=== 4) ����岼��: ɫ�� + ��λ��ɫ(�޿�) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd100, 11'd140);   chk("duo=1 P1 Next ��λ", rgb, `SLOT_P1);
  look(11'd100, 11'd123);   chk("duo=1 P1 Next ɫ��", rgb, `CY_MENU);
  look(11'd100, 11'd356);   chk("duo=1 P1 Hold ��λ", rgb, `SLOT_P1);
  look(11'd100, 11'd339);   chk("duo=1 P1 Hold ɫ��", rgb, `CY_MENU);
  look(11'd1230, 11'd140);  chk("duo=1 P2 Next ��λ", rgb, `SLOT_P2);
  look(11'd1230, 11'd123);  chk("duo=1 P2 Next ɫ��", rgb, `PINK2);
  look(11'd1230, 11'd356);  chk("duo=1 P2 Hold ��λ", rgb, `SLOT_P2);
  look(11'd1230, 11'd339);  chk("duo=1 P2 Hold ɫ��", rgb, `PINK2);
  look(11'd1059, 11'd140);  chk("duo=1 ���˲�λλ��=��", rgb, `FLDBG);
  look(11'd1059, 11'd123);  chk("duo=1 ����ɫ��λ��=��", rgb, `FLDBG);
  look(11'd1104, 11'd100);  chk("�� Next ���λ��=��", rgb, `BLACK);
  look(11'd1120, 11'd203);  chk("���м�����λ��=��", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1059, 11'd140);  chk("duo=0 ���� Next ��λ", rgb, `SLOT_P1);
  look(11'd1059, 11'd123);  chk("duo=0 ���� Next ɫ��", rgb, `GRAY_MID);
  look(11'd1059, 11'd356);  chk("duo=0 ���� Hold ��λ", rgb, `SLOT_P1);
  look(11'd100, 11'd140);   chk("duo=0 ˫�˲�λλ��=��", rgb, `BLACK);
  look(11'd100, 11'd123);   chk("duo=0 ˫��ɫ��λ��=��", rgb, `BLACK);
  look(11'd1230, 11'd140);  chk("duo=0 �� P2 ��λ", rgb, `BLACK);
  look(11'd1230, 11'd123);  chk("duo=0 �� P2 ɫ��", rgb, `BLACK);
  look(11'd1104, 11'd500);  chk("duo=0 �� Next ���λ��=��", rgb, `BLACK);
  look(11'd1040, 11'd100);  chk("duo=0 �ɵ������λ��=��", rgb, `BLACK);

  $display("=== 5) ��һ��Ԥ��(ê���沼��Ǩ��) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.type_t2 = 3'd3;
  force dut.Playfield_inst.type_t  = 3'd2;
  repeat(4) @(posedge Clk);
  look(11'd1161, 11'd240);                      // P2 Ԥ�� (��1,��3)
  chk("duo=1 P2 ��һ��=��", rgb, `RED);
  look(11'd140, 11'd240);                       // P1 Ԥ�� (��1,��3)
  chk("duo=1 P1 ��һ��=��", rgb, `YELLOW);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd140, 11'd240);
  chk("duo=0 ����λ����Ԥ��", rgb, `BLACK);
  look(11'd1101, 11'd240);                      // ����Ԥ�� (��1,��3)
  chk("duo=0 ������һ��=��", rgb, `YELLOW);
  look(11'd1161, 11'd240);
  chk("duo=0 �� P2 Ԥ��", rgb, `SLOT_P1);
  release dut.Playfield_inst.type_t2; release dut.Playfield_inst.type_t;

  $display("=== 6) Hold λ�� ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd1104, 11'd400);  chk("duo=1 �� Hold ���λ��=��", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1040, 11'd300);  chk("duo=0 �� Hold ���λ��=��", rgb, `BLACK);
  look(11'd1230, 11'd356);  chk("duo=0 ˫�� Hold λ��=��", rgb, `BLACK);

  $display("=== 7) ���� P1 ��ʾ�ع� ===");
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c = 5'd9; force dut.Playfield_inst.counter_r = 5'd0;
  force dut.Playfield_inst.type = 3'd2;
  look(11'd619, 11'd91);                        // ��9�� ��0��
  chk("duo=0 P1 ����=��", rgb, `YELLOW);
  release dut.Playfield_inst.counter_c; release dut.Playfield_inst.counter_r; release dut.Playfield_inst.type;

  $display("=== 8) 2px ����ȡɫ����(��������޸�) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  dut.state_color[20*20 + 3] = 3'd3;
  dut.Playfield_inst.state[20*20 + 3] = 1'b1;
  look(11'd351, 11'd200);                       // �м� 2px ����
  chk("��������=��", rgb, `FLDBG);
  dut.state_color[20*20 + 3] = 3'd0;
  dut.Playfield_inst.state[20*20 + 3] = 1'b0;
  look(11'd318, 11'd40);                        // �߿��Ϸ�: ��߿�Ӧ��ͷ
  chk("��߿򲻳�ͷ(�Ϸ�=��)", rgb, `BLACK);
  look(11'd318, 11'd200);                       // �߿���: ��߿�����
  chk("��߿�����(�Ա�=��)", rgb, `WHITE);
  look(11'd321, 11'd81);
  chk("��Ч��(��0�е�0��)", rgb, `FLDBG);

  $display("=== 9) ������Ŀ�: �ߴ�ǳɫ / �ڲ����� ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd351, 11'd85);   chk("��ĩ����=��", rgb, `FLDBG);
  force dut.Playfield_inst.Piece = 1'b0;  force dut.Playfield_inst.Piece2 = 1'b0;
  force dut.Playfield_inst.ghost = 1'b1;  force dut.Playfield_inst.type = 3'd0;
  force dut.Playfield_inst.ghost2 = 1'b0;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd85);   chk("������ߴ�=ǳ��", rgb, 24'h99EEFF);
  look(11'd349, 11'd108);  chk("�����ұߴ�=ǳ��", rgb, 24'h99EEFF);
  look(11'd325, 11'd82);   chk("�����ϱߴ�=ǳ��", rgb, 24'h99EEFF);
  look(11'd348, 11'd109);  chk("�����±ߴ�=ǳ��", rgb, 24'h99EEFF);
  look(11'd325, 11'd85);   chk("ghost inner tick TL", rgb, 24'h99EEFF);
  look(11'd330, 11'd90);   chk("ghost interior black", rgb, `FLDBG);
  look(11'd348, 11'd108);  chk("ghost inner tick BR", rgb, 24'h99EEFF);
  force dut.Playfield_inst.ghost = 1'b0;
  force dut.Playfield_inst.ghost2 = 1'b1; force dut.Playfield_inst.type2 = 3'd3;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd85);   chk("P2 ������ߴ�=ǳ��", rgb, 24'hFFB3B9);
  look(11'd348, 11'd109);  chk("P2 �����±ߴ�=ǳ��", rgb, 24'hFFB3B9);
  look(11'd325, 11'd85);   chk("P2 ghost inner tick", rgb, 24'hFFB3B9);
  look(11'd330, 11'd90);   chk("P2 ghost interior black", rgb, `FLDBG);
  force dut.Playfield_inst.ghost2 = 1'b0;
  //    ghost restart must not trigger dynamic dash ring
  force dut.Playfield_inst.ghost = 1'b1; force dut.Playfield_inst.type = 3'd0;
  l1 = 1'b1; @(posedge Clk); #1; l1 = 1'b0; repeat(4) @(posedge Clk);
  look(11'd331, 11'd85); chk("ghost no rescan flash", rgb, `FLDBG);
  repeat(8) @(posedge Clk);
  look(11'd331, 11'd85); chk("ghost stays static", rgb, `FLDBG);  force dut.Playfield_inst.Piece = 1'b1; force dut.Playfield_inst.type = 3'd0;
  repeat(4) @(posedge Clk);
  look(11'd330, 11'd90);   chk("���䷽���ڲ�=ʵɫ", rgb, 24'h00CCFF);
  look(11'd322, 11'd85);   chk("falling edge P1 soft", rgb, 24'h6BF0FF);
  release dut.Playfield_inst.Piece; release dut.Playfield_inst.Piece2;
  release dut.Playfield_inst.ghost; release dut.Playfield_inst.ghost2;
  release dut.Playfield_inst.type;  release dut.Playfield_inst.type2;
  repeat(4) @(posedge Clk);

  //    ��̬ɨ��: ����ʵ����(�� force ghost), hcounter ÿ�� +1, ץ 1 �Ĵ�λ���µ���խ�ҿ�
  force dut.Playfield_inst.counter_c = 5'd8;
  force dut.Playfield_inst.counter_r = 5'd0;
  force dut.Playfield_inst.counter_ghost_r_t = 5'd19;
  force dut.Playfield_inst.ghost_done = 1'b1;
  force dut.Playfield_inst.type = 3'd0;
  vc = 11'd700; hc = 11'd575; repeat(3) @(posedge Clk);
  scan_en = 1'b1;
  for(k = 0; k < 70; k = k + 1)begin
    @(posedge Clk); #1; lit[k] = (rgb === 24'h99EEFF) ? 1'b1 : 1'b0;
  end
  scan_en = 1'b0;
  nrun = 0; nbad = 0; runlen = 0; prev = 1'b0;
  for(k = 0; k < 70; k = k + 1)begin
    if(lit[k])begin
      if(!prev) runlen = 1;
      else      runlen = runlen + 1;
    end
    else if(prev)begin
      nrun = nrun + 1;
      if(runlen != 2) nbad = nbad + 1;
    end
    prev = lit[k];
  end
  if(prev)begin nrun = nrun + 1; if(runlen != 2) nbad = nbad + 1; end
  chk("ɨ��: ÿ���ߴ������� 2px", nbad, 0);
  chk("ɨ��: �������� 2 ���ߴ�", nrun, 2);
  release dut.Playfield_inst.counter_c; release dut.Playfield_inst.counter_r;
  release dut.Playfield_inst.counter_ghost_r_t; release dut.Playfield_inst.ghost_done;
  release dut.Playfield_inst.type;
  repeat(2) @(posedge Clk);

  //    �ĽǸ��� 1x1: �ǵ��, ���ڱߴ���
  force dut.Playfield_inst.ghost = 1'b1; force dut.Playfield_inst.ghost2 = 1'b0;
  force dut.Playfield_inst.type = 3'd0;
  repeat(3) @(posedge Clk);
  look(11'd321, 11'd81);   chk("���Ͻ��н�=��", rgb, `FLDBG);
  look(11'd322, 11'd81);   chk("���Ͻ��Ҳ�=ǳ��", rgb, 24'h99EEFF);
  look(11'd321, 11'd82);   chk("���Ͻ��²�=ǳ��", rgb, 24'h99EEFF);
  look(11'd350, 11'd81);   chk("���Ͻ��н�=��", rgb, `FLDBG);
  look(11'd321, 11'd110);  chk("���½��н�=��", rgb, `FLDBG);
  release dut.Playfield_inst.ghost; release dut.Playfield_inst.type;
  repeat(2) @(posedge Clk);

  $display("=== 10) level energy bar: bottom-up + cap + frame ===\n");
  duo = 1'b0; repeat(4) @(posedge Clk);
  for(k = 0; k < 8; k = k + 1)begin
    force dut.Playfield_inst.speed_level = k[2:0];
    repeat(40) @(posedge Clk);
    ybar = 88 + (7 - k) * 78 + 40;
    look(11'd293, ybar[10:0]); chk("current body level color", rgb, lvcol(k[2:0]));
    look(11'd293, (ybar-37));  chk("current cap white", rgb, `WHITE);
    if(k > 0)begin
      ybar = 88 + (7 - (k-1)) * 78 + 40;
      look(11'd293, ybar[10:0]); chk("achieved body color", rgb, lvcol(k[2:0]));
    end
    if(k < 7)begin
      ybar = 88 + (7 - (k+1)) * 78 + 40;
      look(11'd293, ybar[10:0]); chk("unlit body dark", rgb, 24'h303030);
    end
  end
  force dut.Playfield_inst.speed_level = 3'd0; repeat(40) @(posedge Clk);
  look(11'd277, 11'd440);   chk("level frame left", rgb, 24'h606060);
  look(11'd279, 11'd440);   chk("outside bar black", rgb, `BLACK);
  look(11'd280, 11'd440);   chk("bar left inner", rgb, 24'h303030);
  look(11'd306, 11'd440);   chk("bar inner right", rgb, 24'h303030);
  look(11'd307, 11'd440);   chk("bar right inner", rgb, 24'h303030);
  look(11'd310, 11'd440);   chk("level frame right", rgb, 24'h606060);
  look(11'd293, 11'd88);    chk("segment gap dark", rgb, `SLOT_BG);
  look(11'd292, 11'd40);    chk("level digit color", rgb, 24'h00E5FF);
  look(11'd234, 11'd50);    chk("LV label color", rgb, 24'h00E5FF);
  look(11'd240, 11'd72);    chk("LV rule color", rgb, 24'h00E5FF);
  look(11'd240, 11'd74);    chk("LV rule below black", rgb, `BLACK);
  look(11'd340, 11'd40);    chk("time still white", rgb, `WHITE);
  release dut.Playfield_inst.speed_level; repeat(4) @(posedge Clk);
  $display("=== 11) �˵���: �޿�ѡ�� + ��ɫѡ�б�� ===");
  Playing = 1'b0; choose = 1'b1; choose_cnt = 4'd0; repeat(4) @(posedge Clk);
  hc = 11'd495; vc = 11'd110; repeat(3) @(posedge Clk);       // ����� 1 ��ǰ 1 ����
  chk("����ȡַ��Ԥȡ", dut.choose_menu_inst.ena_n, 1'b1);
  chk("����ȡַ Y ��ȷ", dut.choose_menu_inst.Y, 11'd96);
  chk("���� vt ��ȷ(2x)", dut.choose_menu_inst.vt, 6'd7);
  chk("�˵���ģʹ����Ԥȡ", dut.choose_menu_inst.letter_inst0.ena, 1'b1);
  hc = 11'd437; vc = 11'd570; repeat(3) @(posedge Clk);       // ��ʾ 1 �� 1 ��ǰ 1 ����
  chk("��ʾȡַ Y ��ȷ", dut.choose_menu_inst.Y, 11'd560);
  chk("��ʾ big=0(1x)", dut.choose_menu_inst.big, 1'b0);
  chk("��ʾ vt ��ȷ(1x)", dut.choose_menu_inst.vt, 6'd10);
  look(11'd426, 11'd290);   chk("ѡ��������=��", rgb, `CY_MENU);
  look(11'd600, 11'd337);   chk("ѡ�����»���=��", rgb, `CY_MENU);
  look(11'd426, 11'd450);   chk("δѡ����������", rgb, `BLACK);
  look(11'd500, 11'd110);   chk("��������=��", rgb, `WHITE);
  look(11'd500, 11'd280);   chk("ѡ��������=��", rgb, `WHITE);
  look(11'd500, 11'd440);   chk("δѡ��������=��", rgb, `GRAY_MID);
  choose_cnt = 4'd1; repeat(4) @(posedge Clk);
  look(11'd426, 11'd450);   chk("�л�������=��", rgb, `CY_MENU);
  look(11'd600, 11'd497);   chk("�л����»���=��", rgb, `CY_MENU);
  look(11'd426, 11'd290);   chk("ԭѡ����������", rgb, `BLACK);
  look(11'd500, 11'd440);   chk("�л����������=��", rgb, `WHITE);
  look(11'd500, 11'd280);   chk("�л���ԭ������=��", rgb, `GRAY_MID);
  choose = 1'b0; choose_cnt = 4'd0; Playing = 1'b1; repeat(4) @(posedge Clk);

  $display("=== 12) ����: �����Ҷ��� + ʱ�� + LV ���� + ��ǩ ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("duo=1 �����������ұ߽�", rgb, `WHITE);
  look(11'd113,  11'd90);   chk("duo=1 NEXT ��ǩ=��ǩ��", rgb, `GRAY_LBL);
  look(11'd95,   11'd90);   chk("duo=1 ��ǩ��λ��=��(�Ѿ���)", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("duo=0 �ô��޷���", rgb, `BLACK);
  look(11'd935,  11'd40);   chk("duo=0 �����������ұ߽�", rgb, `WHITE);
  look(11'd95,   11'd90);   chk("duo=0 ˫�˱�ǩλ��=��", rgb, `BLACK);
  look(11'd1077, 11'd90);   chk("duo=0 ���� NEXT ��ǩ", rgb, `GRAY_LBL);
  look(11'd340,  11'd40);   chk("ʱ������=��", rgb, `WHITE);
  force dut.Playfield_inst.speed_level = 3'd0; repeat(40) @(posedge Clk);
  look(11'd292,  11'd40);   chk("LV ����=�ȼ�ɫ", rgb, 24'h00E5FF);
  look(11'd240,  11'd40);   chk("LV ��ǩ=�ȼ�ɫ", rgb, 24'h00E5FF);
  release dut.Playfield_inst.speed_level; repeat(4) @(posedge Clk);
  Finalize = 1'b1; duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd113,   11'd90);   chk("Finalize label dim", rgb, `SLOT_BG);
  look(11'd292,   11'd40);   chk("Finalize LV digit kept", rgb, 24'h00E5FF);
  look(11'd234,   11'd50);   chk("Finalize LV label kept", rgb, 24'h00E5FF);
  look(11'd293,   11'd674);  chk("Finalize level bar kept", rgb, 24'h00E5FF);
  look(11'd277,   11'd440);  chk("Finalize level frame kept", rgb, 24'h606060);  Finalize = 1'b0; repeat(4) @(posedge Clk);

  $display("=== 13) ��ǩ��ģ 1 ����Ԥȡ(�޵� 1 �д���) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  hc = 11'd94 + 11'd41; vc = 11'd100; repeat(3) @(posedge Clk);
  chk("NEXT ��2�ֵ�ַ��Ԥȡ", dut.lb_g, 5'd4);
  chk("BRAM ʹ����Ԥȡ(ena_n)", dut.letter_hud_inst.ena, 1'b1);
  chk("��ʾ���ڴ�ʱ�Թ�", dut.lb_ena, 1'b0);
  chk("��ַ�����ѿ�", dut.lb_ena_n, 1'b1);
  hc = 11'd94 + 11'd42; vc = 11'd100; repeat(3) @(posedge Clk);
  chk("NEXT ��2�ֵ�1��ȡ����ģ", dut.lb_g, 5'd4);
  chk("NEXT ��2�ֵ�1����", dut.lbl_r, 1'b1);
  chk("��ʾ�����ѿ�", dut.lb_ena, 1'b1);
  hc = 11'd236 + 11'd23; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV ��2�ֵ�ַ��Ԥȡ", dut.lb_g, 5'd21);
  chk("LV BRAM ʹ����Ԥȡ", dut.letter_hud_inst.ena, 1'b1);
  chk("LV ��ַ�����ѿ�", dut.lb_ena_n, 1'b1);
  hc = 11'd282; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV ����ʹ����Ԥȡ", dut.number_lv_inst.ena, 1'b1);
  chk("LV ������ʾ�����Թ�", dut.lvd_ena, 1'b0);
  hc = 11'd283; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV ������ʾ�����ѿ�", dut.lvd_ena, 1'b1);

  $display("=== 14) ˫�� P2 Hold �� HOLD ��ɼ� ===");
  duo = 1'b1; Playing = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.type2 = 3'd3;
  force dut.Playfield_inst.type_t2 = 3'd0;
  hd2 = 1'b0; repeat(4) @(posedge Clk);
  look(11'd140, 11'd458);  chk("P2 hold ǰ HOLD ��Ϊ��", rgb, `SLOT_P1);
  hd2 = 1'b1; @(posedge Clk); hd2 = 1'b0; repeat(2) @(posedge Clk);
  chk("P2 en_hold2=1", dut.Playfield_inst.en_hold2, 1'b1);
  chk("���ò۴���� P2 �Ŀ�", dut.Playfield_inst.hold_type, 3'd3);
  look(11'd140, 11'd458);
  chk("����˲�� HOLD Ԥ������", rgb, `WHITE);
  repeat(40) @(posedge Clk);
  look(11'd140, 11'd458);
  chk("P2 hold �� HOLD ����ʾ����", rgb, `RED);
  release dut.Playfield_inst.type2; release dut.Playfield_inst.type_t2;

  $display("=== 15) UI ����: ������/Ԥ������/������˿�� ===");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; Idle = 1'b0; Stop = 1'b0;
  repeat(40) @(posedge Clk);
  look(11'd100, 11'd718);   chk("P1 ������=��", rgb, `CY_MENU);
  look(11'd1130, 11'd718);  chk("P2 ������=��", rgb, `PINK2);
  look(11'd125, 11'd163);   chk("Ԥ���۵���=404040", rgb, 24'h404040);
  look(11'd400, 11'd300);   chk("�����ڵ�ɫ=0A0F16", rgb, `FLDBG);
  look(11'd250, 11'd600);   chk("�������ɫ=��", rgb, `BLACK);
  look(11'd126, 11'd163);   chk("������=�۵�", rgb, `SLOT_P1);
  look(11'd171, 11'd640);   chk("P1 ����ձ�=��", rgb, `CY_MENU);
  look(11'd1185, 11'd624);  chk("P2 ����ձ�=��", rgb, `PINK2);
  look(11'd470, 11'd40);    chk("������˿��=��ǩ��", rgb, `GRAY_LBL);
  look(11'd469, 11'd40);    chk("��˿�����=��", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1060, 11'd718);  chk("����������=��", rgb, `GRAY_MID);
  look(11'd171, 11'd640);   chk("�����޺���ձ�", rgb, `BLACK);
  duo = 1'b1; repeat(4) @(posedge Clk);

  $display("=== 16) �˵������� ===");
  Playing = 1'b0; choose = 1'b1; choose_cnt = 4'd0; repeat(4) @(posedge Clk);
  look(11'd600, 11'd181);   chk("�˵�������=��", rgb, `CY_MENU);
  look(11'd600, 11'd179);   chk("�������Ϸ�=��", rgb, `BLACK);
  force dut.choose_menu_inst.breath = 1'b1; repeat(4) @(posedge Clk);
  look(11'd426, 11'd290);   chk("�˵�ѡ�б�Ǻ���=����", rgb, 24'h00697F);
  release dut.choose_menu_inst.breath; repeat(4) @(posedge Clk);
  choose = 1'b0; Playing = 1'b1; repeat(4) @(posedge Clk);

  $display("=== 17) UI ��Ч: ��������/��������/��������/�����»��� ===");
  duo = 1'b1; repeat(40) @(posedge Clk);
  look(11'd100, 11'd123);   chk("����ǰ P1 ɫ��=��", rgb, `CY_MENU);
  force dut.lock_we = 1'b1; @(posedge Clk); release dut.lock_we;
  look(11'd100, 11'd123);   chk("����˲�� P1 ɫ��=��", rgb, `WHITE);
  repeat(40) @(posedge Clk);
  look(11'd100, 11'd123);   chk("����� P1 ɫ�߻���", rgb, `CY_MENU);
  force dut.Playfield_inst.speed_level = 3'd5; repeat(2) @(posedge Clk);
  look(11'd293, 11'd280);   chk("����˲�䵱ǰ��=��", rgb, `WHITE);
  repeat(40) @(posedge Clk);
  look(11'd293, 11'd280);   chk("������ǰ�λ���", rgb, 24'hFF4DA6);
  release dut.Playfield_inst.speed_level; repeat(40) @(posedge Clk);
  force dut.Playfield_inst.score = 20'd777; repeat(2) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("�ӷ�˲�����=��", rgb, `CY_MENU);
  repeat(40) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("�ӷֺ����=��", rgb, `WHITE);
  release dut.Playfield_inst.score; repeat(40) @(posedge Clk);
  Finalize = 1'b1; repeat(40) @(posedge Clk);
  look(11'd600, 11'd445);   chk("�����»��߷Ǻ�", (rgb !== `BLACK), 1);
  Finalize = 1'b0; repeat(40) @(posedge Clk);
  $display("=== 18) ʵ�ķ��� 2px Բ�� ===");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0;
  dut.state_color[0] = 3'd0;
  dut.Playfield_inst.state[0] = 1'b0;
  repeat(40) @(posedge Clk);
  force dut.Playfield_inst.Piece = 1'b1;
  force dut.Playfield_inst.type = 3'd2;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("��������Ͻ�=��", rgb, `FLDBG);
  look(11'd322, 11'd82);   chk("corner inner P1 soft", rgb, 24'h6BF0FF);
  look(11'd323, 11'd81);   chk("��������Ե=��", rgb, `YELLOW);
  look(11'd321, 11'd83);   chk("������ϱ�Ե=��", rgb, `YELLOW);
  look(11'd336, 11'd96);   chk("���������=��", rgb, `YELLOW);
  force dut.Playfield_inst.Piece = 1'b0;
  force dut.Playfield_inst.Piece2 = 1'b1;
  force dut.Playfield_inst.type2 = 3'd4;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("P2 ������=��", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("P2 ������=��", rgb, 24'h55A630);
  force dut.Playfield_inst.Piece2 = 1'b0;
  dut.state_color[0] = 3'd3;
  dut.Playfield_inst.state[0] = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("�������=��", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("�������=��", rgb, `RED);
  force dut.Playfield_inst.Piece = 1'b1;
  force dut.Playfield_inst.type = 3'd2;
  force dut.land_we = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("�������׽�=��", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("�������ױ�=��", rgb, 24'hEEEEEE);
  release dut.land_we;
  release dut.Playfield_inst.Piece;
  release dut.Playfield_inst.type;
  force dut.clear_t_r = 1'b1;
  force dut.flash_r = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("�������׽�=��", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("�������ױ�=��", rgb, 24'hEEEEEE);
  release dut.clear_t_r;
  release dut.flash_r;
  dut.state_color[0] = 3'd0;
  dut.Playfield_inst.state[0] = 1'b0;
  repeat(4) @(posedge Clk);
  $display("=== 19) Ԥ������ 1px Բ�� ===");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; repeat(40) @(posedge Clk);
  force dut.Playfield_inst.type_t = 3'd2;
  force dut.Playfield_inst.type_t2 = 3'd4;
  repeat(40) @(posedge Clk);
  look(11'd126, 11'd228);   chk("P1 NEXT Ԥ����=�۵�", rgb, `SLOT_P1);
  look(11'd128, 11'd228);   chk("P1 NEXT Ԥ����=��", rgb, `YELLOW);
  look(11'd126, 11'd230);   chk("P1 NEXT Ԥ���±�=��", rgb, `YELLOW);
  look(11'd140, 11'd240);   chk("P1 NEXT Ԥ������=��", rgb, `YELLOW);
  look(11'd1153, 11'd228);  chk("P2 NEXT Ԥ����=�۵�", rgb, `SLOT_P2);
  look(11'd1155, 11'd228);  chk("P2 NEXT Ԥ����=��", rgb, 24'h55A630);
  look(11'd1167, 11'd240);  chk("P2 NEXT Ԥ������=��", rgb, 24'h55A630);
  force dut.Playfield_inst.hold_type = 3'd3;
  force dut.en_hold = 1'b1;
  repeat(40) @(posedge Clk);
  look(11'd126, 11'd444);   chk("HOLD Ԥ����=�۵�", rgb, `SLOT_P1);
  look(11'd128, 11'd444);   chk("HOLD Ԥ����=��", rgb, `RED);
  look(11'd140, 11'd456);   chk("HOLD Ԥ������=��", rgb, `RED);
  release dut.Playfield_inst.hold_type;
  release dut.en_hold;
  release dut.Playfield_inst.type_t;
  release dut.Playfield_inst.type_t2;
  repeat(4) @(posedge Clk);
  $display("=== 20) danger band and rails ===\n");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; clr_state;
  look(11'd314, 11'd400); chk("duo left rail cyan", rgb, `CY_MENU);
  look(11'd1093, 11'd400); chk("duo right rail pink", rgb, `PINK2);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd314, 11'd400); chk("solo left rail cyan", rgb, `CY_MENU);
  look(11'd965, 11'd400); chk("solo right rail cyan", rgb, `CY_MENU);
  clr_state;
  dut.Playfield_inst.state[1*20 + 0] = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd400, 11'd79); chk("danger band red", rgb, `RED);
  clr_state;
  dut.Playfield_inst.state[0*20 + 2] = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd400, 11'd79); chk("caution band orange", rgb, 24'hF77F24);
  clr_state;
  $display("=== 21) action effects ===\n");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; clr_state;
  force dut.piece_cmin1 = 5'd4; force dut.piece_cmax1 = 5'd4;
  force dut.piece_rmin1 = 5'd4; force dut.piece_rmax1 = 5'd4;
  force dut.rotf1 = 3'd6;
  look(11'd449, 11'd209); chk("rotate blocked mark cyan", rgb, `CY_MENU);
  force dut.mbl1 = 2'd2;
  look(11'd314, 11'd400); chk("move blocked left rail white", rgb, `WHITE);
  force dut.hdf1 = 2'd2;
  look(11'd458, 11'd240); chk("hard drop impact cyan", rgb, `CY_MENU);
  release dut.piece_cmin1; release dut.piece_cmax1;
  release dut.piece_rmin1; release dut.piece_rmax1;
  release dut.rotf1; release dut.mbl1; release dut.hdf1;
  repeat(4) @(posedge Clk);
  $display("=== 22) owner tint / lock rim / piece bracket ===\n");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; clr_state;
  dut.state_color[0] = 3'd3; dut.Playfield_inst.state[0] = 1'b1; dut.state_owner[0] = 1'b0;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd82); chk("locked P1 bevel tint", rgb, 24'h6BF0FF);
  dut.state_owner[0] = 1'b1; repeat(4) @(posedge Clk);
  look(11'd322, 11'd82); chk("locked P2 bevel tint", rgb, 24'hFF98CB);
  force dut.lf1 = 2'd2;
  look(11'd322, 11'd81); chk("lock white rim", rgb, `WHITE);
  release dut.lf1;
  force dut.piece_cmin1 = 5'd4; force dut.piece_cmax1 = 5'd4;
  force dut.piece_rmin1 = 5'd4; force dut.piece_rmax1 = 5'd4;
  look(11'd440, 11'd200); chk("piece corner bracket", rgb, `CY_MENU);
  release dut.piece_cmin1; release dut.piece_cmax1;
  release dut.piece_rmin1; release dut.piece_rmax1;
  clr_state; repeat(4) @(posedge Clk);
  $display("=== 23) clear pixel collapse: 1~4 lines ===\n");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; clr_state;
  dut.state_color[0] = 3'd3; dut.Playfield_inst.state[0] = 1'b1;
  force dut.clear_t_r = 1'b1; force dut.clear_shrink_r = 1'b1; force dut.flash_r = 1'b0;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);  chk("collapse edge black", rgb, `FLDBG);
  look(11'd337, 11'd97);  chk("collapse center color", rgb, `RED);
  force dut.flash_r = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);  chk("collapse flash edge black", rgb, `FLDBG);
  look(11'd337, 11'd97);  chk("collapse flash center white", rgb, 24'hEEEEEE);
  release dut.clear_t_r; release dut.clear_shrink_r; release dut.flash_r;
  force dut.clear_t = 1'b1; force dut.clear_flash = 1'b0;
  force dut.line_t = 20'h00001;
  repeat(2) @(posedge Clk);
  chk("clear1 shrink active", {23'd0, dut.clear_shrink_r}, 1);
  force dut.line_t = 20'h00003;
  repeat(2) @(posedge Clk);
  chk("clear2 shrink active", {23'd0, dut.clear_shrink_r}, 1);
  force dut.line_t = 20'h00007;
  repeat(2) @(posedge Clk);
  chk("clear3 shrink active", {23'd0, dut.clear_shrink_r}, 1);
  force dut.line_t = 20'h0000F;
  repeat(2) @(posedge Clk);
  chk("clear4 shrink active", {23'd0, dut.clear_shrink_r}, 1);
  force dut.clear_t = 1'b0;
  repeat(2) @(posedge Clk);
  chk("clear end shrink off", {23'd0, dut.clear_shrink_r}, 0);
  release dut.clear_t; release dut.clear_flash; release dut.line_t;
  clr_state; repeat(4) @(posedge Clk);
  $display("=== 24) game over center / simultaneous / local dim ===\n");
  duo = 1'b0; Playing = 1'b0; choose = 1'b0; Finalize = 1'b1; clr_state;
  force dut.cn_r = 4'd15;
  repeat(4) @(posedge Clk);
  look(11'd452, 11'd368); chk("GO G visible", rgb, `WHITE);
  look(11'd500, 11'd368); chk("GO A visible", rgb, `WHITE);
  look(11'd548, 11'd368); chk("GO M visible", rgb, `WHITE);
  look(11'd596, 11'd368); chk("GO E visible", rgb, `WHITE);
  look(11'd644, 11'd368); chk("GO O visible", rgb, `WHITE);
  look(11'd692, 11'd368); chk("GO V visible", rgb, `WHITE);
  look(11'd740, 11'd368); chk("GO E2 visible", rgb, `WHITE);
  look(11'd788, 11'd368); chk("GO R visible", rgb, `WHITE);
  look(11'd432, 11'd349); chk("GO dim inside", rgb, 24'h101010);
  look(11'd431, 11'd349); chk("GO dim outside left", rgb, `FLDBG);
  look(11'd432, 11'd348); chk("GO dim checker other", rgb, `FLDBG);
  look(11'd846, 11'd349); chk("GO dim inside right", rgb, 24'h101010);
  look(11'd847, 11'd349); chk("GO dim right checker", rgb, `FLDBG);
  look(11'd848, 11'd349); chk("GO dim outside right", rgb, `FLDBG);
  release dut.cn_r;
  Finalize = 1'b0; repeat(4) @(posedge Clk);
  clr_state;

  $display("=== 25) Impact Glass lower-left 6x1 soft bar ===\n");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; clr_state;
  force dut.Playfield_inst.Piece = 1'b1; force dut.Playfield_inst.type = 3'd2;
  repeat(4) @(posedge Clk);
  look(11'd327, 11'd107); chk("P1 soft bar start", rgb, 24'h6BF0FF);
  look(11'd332, 11'd107); chk("P1 soft bar end", rgb, 24'h6BF0FF);
  look(11'd333, 11'd107); chk("P1 soft bar outside", rgb, `YELLOW);
  release dut.Playfield_inst.Piece; release dut.Playfield_inst.type;
  force dut.Playfield_inst.Piece2 = 1'b1; force dut.Playfield_inst.type2 = 3'd4;
  repeat(4) @(posedge Clk);
  look(11'd327, 11'd107); chk("P2 soft bar", rgb, 24'hFF98CB);
  look(11'd333, 11'd107); chk("P2 soft bar outside", rgb, 24'h55A630);
  release dut.Playfield_inst.Piece2; release dut.Playfield_inst.type2;
  dut.state_color[0] = 3'd3; dut.Playfield_inst.state[0] = 1'b1; dut.state_owner[0] = 1'b0;
  repeat(4) @(posedge Clk);
  look(11'd327, 11'd107); chk("locked soft bar", rgb, 24'h6BF0FF);
  look(11'd333, 11'd107); chk("locked bar outside", rgb, `RED);
  clr_state;
  force dut.Playfield_inst.type_t = 3'd2; force dut.Playfield_inst.type_t2 = 3'd4;
  repeat(40) @(posedge Clk);
  look(11'd132, 11'd254); chk("P1 next soft bar", rgb, 24'hFFFF99);
  look(11'd138, 11'd254); chk("P1 next outside", rgb, `YELLOW);
  look(11'd1159, 11'd254); chk("P2 next soft bar", rgb, 24'hBDE0AA);
  look(11'd1165, 11'd254); chk("P2 next outside", rgb, 24'h55A630);
  force dut.Playfield_inst.hold_type = 3'd3; force dut.en_hold = 1'b1;
  repeat(40) @(posedge Clk);
  look(11'd132, 11'd470); chk("hold soft bar", rgb, 24'hFFB3B9);
  look(11'd138, 11'd470); chk("hold outside", rgb, `RED);
  release dut.en_hold; release dut.Playfield_inst.hold_type;
  release dut.Playfield_inst.type_t; release dut.Playfield_inst.type_t2;
  clr_state; repeat(4) @(posedge Clk);
  $display("=== 26) solo hold hint: dashed target / 2x2 dot / no lock overlap ===\n");
  duo=0; Playing=1; choose=0; Finalize=0; clr_state;
  force dut.Playfield_inst.type = 3'd0;
  force dut.hint_valid = 1'b1;
  force dut.hint_type = 3'd0;
  force dut.hint_c0 = 5'd2; force dut.hint_c1 = 5'd2;
  force dut.hint_c2 = 5'd2; force dut.hint_c3 = 5'd2;
  force dut.hint_r0 = 5'd10; force dut.hint_r1 = 5'd10;
  force dut.hint_r2 = 5'd10; force dut.hint_r3 = 5'd10;
  hint_show = 1'b1;
  for(k=0;k<7;k=k+1)begin
    force dut.Playfield_inst.type = k[2:0];
    force dut.hint_type = k[2:0];
    repeat(5) @(posedge Clk);
    look(11'd394,11'd410); chk("hint top dash on", rgb, hintcol(k[2:0]));
    look(11'd395,11'd410); chk("hint top dash gap", rgb, `FLDBG);
    look(11'd399,11'd415); chk("hint center dot", rgb, hintcol(k[2:0]));
  end
  dut.Playfield_inst.state[2*20+10] = 1'b1;
  dut.state_color[2*20+10] = 3'd3;
  dut.state_owner[2*20+10] = 1'b0;
  repeat(5) @(posedge Clk);
  look(11'd399,11'd415); chk("hint clipped by real locked cell", rgb, `RED);
  clr_state;
  repeat(5) @(posedge Clk);
  hint_show = 1'b0; duo=0; Playing=1; repeat(5) @(posedge Clk);
  look(11'd399,11'd415); chk("hint hidden after short/release", rgb, `FLDBG);
  hint_show = 1'b1; duo=1; repeat(5) @(posedge Clk);
  look(11'd399,11'd415); chk("hint hidden in duo", rgb, `FLDBG);
  duo=0; Playing=0; repeat(5) @(posedge Clk);
  look(11'd399,11'd415); chk("hint hidden not playing", rgb, `FLDBG);
  Playing=1; force dut.Playfield_inst.type = 3'd1; force dut.hint_type = 3'd0;
  repeat(5) @(posedge Clk);
  look(11'd399,11'd415); chk("hint hidden type mismatch", rgb, `FLDBG);
  release dut.Playfield_inst.type; release dut.hint_valid; release dut.hint_type;
  release dut.hint_c0; release dut.hint_c1; release dut.hint_c2; release dut.hint_c3;
  release dut.hint_r0; release dut.hint_r1; release dut.hint_r2; release dut.hint_r3;
  hint_show=0; duo=0; Playing=1; clr_state; repeat(4) @(posedge Clk);
  $display("=== 27) GAME OVER result stats and local dim ===\n");
  duo=0; Playing=0; choose=0; Finalize=1; Idle=0; clr_state;
  force dut.score_bcd = 24'h012345;
  force dut.lines_bcd = 20'h00128;
  force dut.time_bcd = 16'h0623;
  force dut.Playfield_inst.speed_level = 3'd6;
  repeat(6) @(posedge Clk);
  look(11'd404,11'd468); chk("result SOLO mode cyan", rgb, `CY_MENU);
  look(11'd370,11'd510); chk("result score rule cyan", rgb, `CY_MENU);
  look(11'd365,11'd526); chk("result label gray", rgb, `GRAY_LBL);
  force dut.letter_hud_inst.douta = 20'h00000;
  repeat(4) @(posedge Clk);
  look(11'd404,11'd468); chk("result SOLO mode blank glyph", rgb, `FLDBG);
  look(11'd365,11'd526); chk("result label blank glyph", rgb, 24'h101010);
  release dut.letter_hud_inst.douta;
  repeat(4) @(posedge Clk);
  look(11'd365,11'd562); chk("result score white", rgb, `WHITE);
  look(11'd568,11'd562); chk("result level color", rgb, 24'h9933CC);
  look(11'd748,11'd562); chk("result lines pink", rgb, `PINK2);
  look(11'd900,11'd562); chk("result time yellow", rgb, `YELLOW);
  look(11'd950,11'd576); chk("result time colon", rgb, `YELLOW);
  look(11'd924,11'd562); chk("result time tens BCD", dut.result_num_dig, 6);
  look(11'd796,11'd562); chk("result lines hundreds BCD", dut.result_num_dig, 1);
  look(11'd361,11'd470); chk("result dim checker on", rgb, 24'h101010);
  look(11'd360,11'd470); chk("result dim checker off", rgb, `FLDBG);
  dut.Playfield_inst.state[4*20+10] = 1'b1;
  dut.state_color[4*20+10] = 3'd3;
  dut.state_owner[4*20+10] = 1'b0;
  repeat(5) @(posedge Clk);
  look(11'd450,11'd402); chk("result masks locked cell", rgb, `FLDBG);
  dut.Playfield_inst.state[4*20+10] = 1'b0;
  duo=1; repeat(6) @(posedge Clk);
  look(11'd404,11'd468); chk("result DUO mode pink", rgb, `PINK2);
  Finalize=0; repeat(6) @(posedge Clk);
  look(11'd404,11'd468); chk("result hidden outside finalize", rgb, `FLDBG);
  release dut.score_bcd; release dut.lines_bcd; release dut.time_bcd;
  release dut.Playfield_inst.speed_level;
  duo=0; Playing=1; Finalize=0; clr_state; repeat(4) @(posedge Clk);
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
