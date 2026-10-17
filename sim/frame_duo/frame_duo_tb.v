`timescale 1ns/1ps

//===== frame 级双人显示回归: P2 运动块/落格/下一块/Hold/新 HUD 布局/菜单屏 =====
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = 32'h0000_0000;      // 桩: 偏移全 0 -> 预览块占 (列1,行3)
endmodule
module weiyibiao(input clka, input [4:0] addra, output [7:0] douta);
  assign douta = 8'h00;
endmodule
module number(input clka, input ena, input [9:0] addra, output [19:0] douta);
  assign douta = 20'hF_FFFF;         // 桩: 全亮, 便于断言数字区域颜色
endmodule
module letter(input clka, input ena, input [10:0] addra, output [19:0] douta);
  assign douta = 20'hF_FFFF;         // 桩: 全亮, 便于断言标签/菜单文字颜色
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
  .rotate_p_flag2(rt2), .hold_p_flag2(hd2),
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
task chk;
input [8*30-1:0] name; input [23:0] got; input [23:0] exp;
begin
  if(got !== exp)begin $display("  FAIL %0s got=%h exp=%h @(%0d,%0d)", name, got, exp, hc, vc); bad = bad + 1; end
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

//    颜色(与 frame 一致)
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
  force dut.Playfield_inst.Drop = 30'd100_000_000;   // 抑制自动下落

  $display("=== 1) 双人: P2 运动块像素(同色表) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd20; force dut.Playfield_inst.counter_r2 = 5'd0;
  force dut.Playfield_inst.type2 = 3'd0;
  look(11'd971, 11'd91);                       // 第20列 第0行
  chk("duo=1 P2 方块=青色", rgb, `CYAN);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd971, 11'd91);
  chk("duo=0 同位置无 P2 方块", rgb, `BLACK);
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  clr_state;

  $display("=== 2) 双人: P2 落格后显示颜色 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  force dut.Playfield_inst.type2 = 3'd3;
  repeat(4) @(posedge Clk);
  lock2;                                        // P2 落锁 (10,19)
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd643, 11'd691);                       // 第10列 第19行
  chk("duo=1 P2 落格=红色", rgb, `RED);
  clr_state;
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  repeat(4) @(posedge Clk);
  lock2;                                        // 单人: 不应写入
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd643, 11'd691);
  chk("duo=0 P2 落格不显示", rgb, `FLDBG);
  clr_state;

  $display("=== 3) 24 列场地最右两列也能显示 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  dut.state_color[23*20 + 17] = 3'd3; dut.Playfield_inst.state[23*20 + 17] = 1'b1;
  look(11'd1067, 11'd630);                      // 第23列 第17行
  chk("duo=1 第23列格=红色", rgb, `RED);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1067, 11'd630);
  chk("duo=0 第23列不在场地", rgb, `BLACK);
  clr_state;
  dut.state_color[23*20 + 17] = 3'd0; dut.Playfield_inst.state[23*20 + 17] = 1'b0;

  $display("=== 4) 新面板布局: 色线 + 槽位底色(无框) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd100, 11'd140);   chk("duo=1 P1 Next 槽位", rgb, `SLOT_P1);
  look(11'd100, 11'd123);   chk("duo=1 P1 Next 色线", rgb, `CY_MENU);
  look(11'd100, 11'd356);   chk("duo=1 P1 Hold 槽位", rgb, `SLOT_P1);
  look(11'd100, 11'd339);   chk("duo=1 P1 Hold 色线", rgb, `CY_MENU);
  look(11'd1230, 11'd140);  chk("duo=1 P2 Next 槽位", rgb, `SLOT_P2);
  look(11'd1230, 11'd123);  chk("duo=1 P2 Next 色线", rgb, `PINK2);
  look(11'd1230, 11'd356);  chk("duo=1 P2 Hold 槽位", rgb, `SLOT_P2);
  look(11'd1230, 11'd339);  chk("duo=1 P2 Hold 色线", rgb, `PINK2);
  look(11'd1059, 11'd140);  chk("duo=1 单人槽位位置=黑", rgb, `FLDBG);
  look(11'd1059, 11'd123);  chk("duo=1 单人色线位置=黑", rgb, `FLDBG);
  look(11'd1104, 11'd100);  chk("旧 Next 外框位置=黑", rgb, `BLACK);
  look(11'd1120, 11'd203);  chk("旧中间虚线位置=黑", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1059, 11'd140);  chk("duo=0 单人 Next 槽位", rgb, `SLOT_P1);
  look(11'd1059, 11'd123);  chk("duo=0 单人 Next 色线", rgb, `GRAY_MID);
  look(11'd1059, 11'd356);  chk("duo=0 单人 Hold 槽位", rgb, `SLOT_P1);
  look(11'd100, 11'd140);   chk("duo=0 双人槽位位置=黑", rgb, `BLACK);
  look(11'd100, 11'd123);   chk("duo=0 双人色线位置=黑", rgb, `BLACK);
  look(11'd1230, 11'd140);  chk("duo=0 无 P2 槽位", rgb, `BLACK);
  look(11'd1230, 11'd123);  chk("duo=0 无 P2 色线", rgb, `BLACK);
  look(11'd1104, 11'd500);  chk("duo=0 旧 Next 外框位置=黑", rgb, `BLACK);
  look(11'd1040, 11'd100);  chk("duo=0 旧单人外框位置=黑", rgb, `BLACK);

  $display("=== 5) 下一块预览(锚点随布局迁移) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.type_t2 = 3'd3;
  force dut.Playfield_inst.type_t  = 3'd2;
  repeat(4) @(posedge Clk);
  look(11'd1161, 11'd240);                      // P2 预览 (列1,行3)
  chk("duo=1 P2 下一块=红", rgb, `RED);
  look(11'd140, 11'd240);                       // P1 预览 (列1,行3)
  chk("duo=1 P1 下一块=黄", rgb, `YELLOW);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd140, 11'd240);
  chk("duo=0 左栏位置无预览", rgb, `BLACK);
  look(11'd1101, 11'd240);                      // 单人预览 (列1,行3)
  chk("duo=0 单人下一块=黄", rgb, `YELLOW);
  look(11'd1161, 11'd240);
  chk("duo=0 无 P2 预览", rgb, `SLOT_P1);
  release dut.Playfield_inst.type_t2; release dut.Playfield_inst.type_t;

  $display("=== 6) Hold 位置 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd1104, 11'd400);  chk("duo=1 旧 Hold 外框位置=黑", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1040, 11'd300);  chk("duo=0 旧 Hold 外框位置=黑", rgb, `BLACK);
  look(11'd1230, 11'd356);  chk("duo=0 双人 Hold 位置=黑", rgb, `BLACK);

  $display("=== 7) 单人 P1 显示回归 ===");
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c = 5'd9; force dut.Playfield_inst.counter_r = 5'd0;
  force dut.Playfield_inst.type = 3'd2;
  look(11'd619, 11'd91);                        // 第9列 第0行
  chk("duo=0 P1 方块=黄", rgb, `YELLOW);
  release dut.Playfield_inst.counter_c; release dut.Playfield_inst.counter_r; release dut.Playfield_inst.type;

  $display("=== 8) 2px 死区取色屏蔽(编号搜索修复) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  dut.state_color[20*20 + 3] = 3'd3;
  dut.Playfield_inst.state[20*20 + 3] = 1'b1;
  look(11'd351, 11'd200);                       // 列间 2px 死区
  chk("死区像素=黑", rgb, `FLDBG);
  dut.state_color[20*20 + 3] = 3'd0;
  dut.Playfield_inst.state[20*20 + 3] = 1'b0;
  look(11'd318, 11'd40);                        // 边框上方: 左边框不应出头
  chk("左边框不出头(上方=黑)", rgb, `BLACK);
  look(11'd318, 11'd200);                       // 边框旁: 左边框正常
  chk("左边框正常(旁边=白)", rgb, `WHITE);
  look(11'd321, 11'd81);
  chk("有效格(第0行第0列)", rgb, `FLDBG);

  $display("=== 9) 幽灵空心框: 边带浅色 / 内部纯黑 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd351, 11'd85);   chk("格末死区=黑", rgb, `FLDBG);
  force dut.Playfield_inst.Piece = 1'b0;  force dut.Playfield_inst.Piece2 = 1'b0;
  force dut.Playfield_inst.ghost = 1'b1;  force dut.Playfield_inst.type = 3'd0;
  force dut.Playfield_inst.ghost2 = 1'b0;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd85);   chk("幽灵左边带=浅青", rgb, 24'h99EEFF);
  look(11'd349, 11'd108);  chk("幽灵右边带=浅青", rgb, 24'h99EEFF);
  look(11'd325, 11'd82);   chk("幽灵上边带=浅青", rgb, 24'h99EEFF);
  look(11'd348, 11'd109);  chk("幽灵下边带=浅青", rgb, 24'h99EEFF);
  look(11'd325, 11'd85);   chk("幽灵内部=纯黑", rgb, `FLDBG);
  look(11'd348, 11'd108);  chk("幽灵内部靠角=纯黑", rgb, `FLDBG);
  force dut.Playfield_inst.ghost = 1'b0;
  force dut.Playfield_inst.ghost2 = 1'b1; force dut.Playfield_inst.type2 = 3'd3;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd85);   chk("P2 幽灵左边带=浅红", rgb, 24'hFFB3B9);
  look(11'd348, 11'd109);  chk("P2 幽灵下边带=浅红", rgb, 24'hFFB3B9);
  look(11'd325, 11'd85);   chk("P2 幽灵内部=纯黑", rgb, `FLDBG);
  force dut.Playfield_inst.ghost2 = 1'b0;
  force dut.Playfield_inst.Piece = 1'b1; force dut.Playfield_inst.type = 3'd0;
  repeat(4) @(posedge Clk);
  look(11'd325, 11'd85);   chk("下落方块内部=实色", rgb, 24'h00CCFF);
  look(11'd322, 11'd85);   chk("下落方块边带=实色", rgb, 24'h00CCFF);
  release dut.Playfield_inst.Piece; release dut.Playfield_inst.Piece2;
  release dut.Playfield_inst.ghost; release dut.Playfield_inst.ghost2;
  release dut.Playfield_inst.type;  release dut.Playfield_inst.type2;
  repeat(4) @(posedge Clk);

  //    动态扫描: 用真实幽灵(不 force ghost), hcounter 每拍 +1, 抓 1 拍错位导致的左窄右宽
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
  chk("扫描: 每条边带都正好 2px", nbad, 0);
  chk("扫描: 单格正好 2 条边带", nrun, 2);
  release dut.Playfield_inst.counter_c; release dut.Playfield_inst.counter_r;
  release dut.Playfield_inst.counter_ghost_r_t; release dut.Playfield_inst.ghost_done;
  release dut.Playfield_inst.type;
  repeat(2) @(posedge Clk);

  //    四角各切 1x1: 角点黑, 紧邻边带亮
  force dut.Playfield_inst.ghost = 1'b1; force dut.Playfield_inst.ghost2 = 1'b0;
  force dut.Playfield_inst.type = 3'd0;
  repeat(3) @(posedge Clk);
  look(11'd321, 11'd81);   chk("左上角切角=黑", rgb, `FLDBG);
  look(11'd322, 11'd81);   chk("左上角右侧=浅青", rgb, 24'h99EEFF);
  look(11'd321, 11'd82);   chk("左上角下侧=浅青", rgb, 24'h99EEFF);
  look(11'd350, 11'd81);   chk("右上角切角=黑", rgb, `FLDBG);
  look(11'd321, 11'd110);  chk("左下角切角=黑", rgb, `FLDBG);
  release dut.Playfield_inst.ghost; release dut.Playfield_inst.type;
  repeat(2) @(posedge Clk);

  $display("=== 10) 等级: 8 级热力色 + 加宽条 + LV 组 ==");
  duo = 1'b0; repeat(4) @(posedge Clk);
  for(k = 0; k < 8; k = k + 1)begin
    force dut.Playfield_inst.speed_level = k[2:0];
    repeat(40) @(posedge Clk);
    ybar = 88 + (7 - k) * 78 + 40;
    look(11'd293, ybar[10:0]);   chk("当前段=白", rgb, `WHITE);
    if(k > 0)begin
      ybar = 88 + (7 - (k-1)) * 78 + 40;
      look(11'd293, ybar[10:0]); chk("已点亮段=等级色", rgb, lvcol(k[2:0]));
    end
    if(k < 7)begin
      ybar = 88 + (7 - (k+1)) * 78 + 40;
      look(11'd293, ybar[10:0]); chk("未点亮段=303030", rgb, 24'h303030);
    end
  end
  force dut.Playfield_inst.speed_level = 3'd0; repeat(40) @(posedge Clk);
  look(11'd279, 11'd440);   chk("条左外=黑", rgb, `BLACK);
  look(11'd280, 11'd440);   chk("条左边=303030", rgb, 24'h303030);
  look(11'd305, 11'd440);   chk("条右边=303030", rgb, 24'h303030);
  look(11'd306, 11'd440);   chk("条右外=黑", rgb, `BLACK);
  look(11'd293, 11'd88);    chk("段缝=202020", rgb, `SLOT_BG);
  look(11'd292, 11'd40);    chk("等级数字=等级色0", rgb, 24'h00E5FF);
  look(11'd234, 11'd50);    chk("LV 标签=等级色0", rgb, 24'h00E5FF);
  look(11'd240, 11'd72);    chk("LV 组色线=等级色0", rgb, 24'h00E5FF);
  look(11'd240, 11'd74);    chk("色线下方=黑", rgb, `BLACK);
  look(11'd340, 11'd40);    chk("时间仍为白", rgb, `WHITE);
  release dut.Playfield_inst.speed_level; repeat(4) @(posedge Clk);

  $display("=== 11) 菜单屏: 无框选项 + 青色选中标记 ===");
  Playing = 1'b0; choose = 1'b1; choose_cnt = 4'd0; repeat(4) @(posedge Clk);
  hc = 11'd495; vc = 11'd110; repeat(3) @(posedge Clk);       // 标题第 1 字前 1 像素
  chk("标题取址已预取", dut.choose_menu_inst.ena_n, 1'b1);
  chk("标题取址 Y 正确", dut.choose_menu_inst.Y, 11'd96);
  chk("标题 vt 正确(2x)", dut.choose_menu_inst.vt, 6'd7);
  chk("菜单字模使能已预取", dut.choose_menu_inst.letter_inst0.ena, 1'b1);
  hc = 11'd437; vc = 11'd570; repeat(3) @(posedge Clk);       // 提示 1 第 1 字前 1 像素
  chk("提示取址 Y 正确", dut.choose_menu_inst.Y, 11'd560);
  chk("提示 big=0(1x)", dut.choose_menu_inst.big, 1'b0);
  chk("提示 vt 正确(1x)", dut.choose_menu_inst.vt, 6'd10);
  look(11'd426, 11'd290);   chk("选中项竖条=青", rgb, `CY_MENU);
  look(11'd600, 11'd337);   chk("选中项下划线=青", rgb, `CY_MENU);
  look(11'd426, 11'd450);   chk("未选中行无竖条", rgb, `BLACK);
  look(11'd500, 11'd110);   chk("标题文字=白", rgb, `WHITE);
  look(11'd500, 11'd280);   chk("选中项文字=白", rgb, `WHITE);
  look(11'd500, 11'd440);   chk("未选中项文字=灰", rgb, `GRAY_MID);
  choose_cnt = 4'd1; repeat(4) @(posedge Clk);
  look(11'd426, 11'd450);   chk("切换后竖条=青", rgb, `CY_MENU);
  look(11'd600, 11'd497);   chk("切换后下划线=青", rgb, `CY_MENU);
  look(11'd426, 11'd290);   chk("原选中行无竖条", rgb, `BLACK);
  look(11'd500, 11'd440);   chk("切换后该项文字=白", rgb, `WHITE);
  look(11'd500, 11'd280);   chk("切换后原项文字=灰", rgb, `GRAY_MID);
  choose = 1'b0; choose_cnt = 4'd0; Playing = 1'b1; repeat(4) @(posedge Clk);

  $display("=== 12) 顶栏: 分数右对齐 + 时间 + LV 数字 + 标签 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("duo=1 分数贴场地右边界", rgb, `WHITE);
  look(11'd113,  11'd90);   chk("duo=1 NEXT 标签=标签灰", rgb, `GRAY_LBL);
  look(11'd95,   11'd90);   chk("duo=1 标签旧位置=黑(已居中)", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("duo=0 该处无分数", rgb, `BLACK);
  look(11'd935,  11'd40);   chk("duo=0 分数贴场地右边界", rgb, `WHITE);
  look(11'd95,   11'd90);   chk("duo=0 双人标签位置=黑", rgb, `BLACK);
  look(11'd1077, 11'd90);   chk("duo=0 单人 NEXT 标签", rgb, `GRAY_LBL);
  look(11'd340,  11'd40);   chk("时间数字=白", rgb, `WHITE);
  force dut.Playfield_inst.speed_level = 3'd0; repeat(40) @(posedge Clk);
  look(11'd292,  11'd40);   chk("LV 数字=等级色", rgb, 24'h00E5FF);
  look(11'd240,  11'd40);   chk("LV 标签=等级色", rgb, 24'h00E5FF);
  release dut.Playfield_inst.speed_level; repeat(4) @(posedge Clk);
  Finalize = 1'b1; duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd113,   11'd90);   chk("Finalize 标签暗化", rgb, `SLOT_BG);
  Finalize = 1'b0; repeat(4) @(posedge Clk);

  $display("=== 13) 标签字模 1 像素预取(修第 1 列串字) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  hc = 11'd94 + 11'd41; vc = 11'd100; repeat(3) @(posedge Clk);
  chk("NEXT 第2字地址已预取", dut.lb_g, 5'd4);
  chk("BRAM 使能已预取(ena_n)", dut.letter_hud_inst.ena, 1'b1);
  chk("显示窗口此时仍关", dut.lb_ena, 1'b0);
  chk("地址窗口已开", dut.lb_ena_n, 1'b1);
  hc = 11'd94 + 11'd42; vc = 11'd100; repeat(3) @(posedge Clk);
  chk("NEXT 第2字第1列取到字模", dut.lb_g, 5'd4);
  chk("NEXT 第2字第1列亮", dut.lbl_r, 1'b1);
  chk("显示窗口已开", dut.lb_ena, 1'b1);
  hc = 11'd236 + 11'd23; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV 第2字地址已预取", dut.lb_g, 5'd21);
  chk("LV BRAM 使能已预取", dut.letter_hud_inst.ena, 1'b1);
  chk("LV 地址窗口已开", dut.lb_ena_n, 1'b1);
  hc = 11'd282; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV 数字使能已预取", dut.number_lv_inst.ena, 1'b1);
  chk("LV 数字显示窗口仍关", dut.lvd_ena, 1'b0);
  hc = 11'd283; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV 数字显示窗口已开", dut.lvd_ena, 1'b1);

  $display("=== 14) 双人 P2 Hold 在 HOLD 框可见 ===");
  duo = 1'b1; Playing = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.type2 = 3'd3;
  force dut.Playfield_inst.type_t2 = 3'd0;
  hd2 = 1'b0; repeat(4) @(posedge Clk);
  look(11'd140, 11'd458);  chk("P2 hold 前 HOLD 框为空", rgb, `SLOT_P1);
  hd2 = 1'b1; @(posedge Clk); hd2 = 1'b0; repeat(2) @(posedge Clk);
  chk("P2 en_hold2=1", dut.Playfield_inst.en_hold2, 1'b1);
  chk("共用槽存的是 P2 的块", dut.Playfield_inst.hold_type, 3'd3);
  look(11'd140, 11'd458);
  chk("换块瞬间 HOLD 预览闪白", rgb, `WHITE);
  repeat(40) @(posedge Clk);
  look(11'd140, 11'd458);
  chk("P2 hold 后 HOLD 框显示方块", rgb, `RED);
  release dut.Playfield_inst.type2; release dut.Playfield_inst.type_t2;

  $display("=== 15) UI 升级: 面板底条/预览点阵/顶栏发丝线 ===");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; Idle = 1'b0; Stop = 1'b0;
  repeat(40) @(posedge Clk);
  look(11'd100, 11'd718);   chk("P1 面板底条=青", rgb, `CY_MENU);
  look(11'd1130, 11'd718);  chk("P2 面板底条=粉", rgb, `PINK2);
  look(11'd125, 11'd163);   chk("预览槽点阵=404040", rgb, 24'h404040);
  look(11'd400, 11'd300);   chk("场地内底色=0A0F16", rgb, `FLDBG);
  look(11'd250, 11'd600);   chk("场地外底色=黑", rgb, `BLACK);
  look(11'd126, 11'd163);   chk("点阵旁=槽底", rgb, `SLOT_P1);
  look(11'd171, 11'd640);   chk("P1 号码徽标=青", rgb, `CY_MENU);
  look(11'd1185, 11'd624);  chk("P2 号码徽标=粉", rgb, `PINK2);
  look(11'd470, 11'd40);    chk("顶栏发丝线=标签灰", rgb, `GRAY_LBL);
  look(11'd469, 11'd40);    chk("发丝线左侧=黑", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1060, 11'd718);  chk("单人面板底条=灰", rgb, `GRAY_MID);
  look(11'd171, 11'd640);   chk("单人无号码徽标", rgb, `BLACK);
  duo = 1'b1; repeat(4) @(posedge Clk);

  $display("=== 16) 菜单标题线 ===");
  Playing = 1'b0; choose = 1'b1; choose_cnt = 4'd0; repeat(4) @(posedge Clk);
  look(11'd600, 11'd181);   chk("菜单标题线=青", rgb, `CY_MENU);
  look(11'd600, 11'd179);   chk("标题线上方=黑", rgb, `BLACK);
  force dut.choose_menu_inst.breath = 1'b1; repeat(4) @(posedge Clk);
  look(11'd426, 11'd290);   chk("菜单选中标记呼吸=暗青", rgb, 24'h00697F);
  release dut.choose_menu_inst.breath; repeat(4) @(posedge Clk);
  choose = 1'b0; Playing = 1'b1; repeat(4) @(posedge Clk);

  $display("=== 17) UI 特效: 落锁脉冲/升级闪白/分数闪青/结束下划线 ===");
  duo = 1'b1; repeat(40) @(posedge Clk);
  look(11'd100, 11'd123);   chk("脉冲前 P1 色线=青", rgb, `CY_MENU);
  force dut.lock_we = 1'b1; @(posedge Clk); release dut.lock_we;
  look(11'd100, 11'd123);   chk("落锁瞬间 P1 色线=白", rgb, `WHITE);
  repeat(40) @(posedge Clk);
  look(11'd100, 11'd123);   chk("脉冲后 P1 色线回青", rgb, `CY_MENU);
  force dut.Playfield_inst.speed_level = 3'd5; repeat(2) @(posedge Clk);
  look(11'd293, 11'd280);   chk("升级瞬间当前段=白", rgb, `WHITE);
  repeat(40) @(posedge Clk);
  look(11'd293, 11'd280);   chk("升级后当前段回青", rgb, `WHITE);
  release dut.Playfield_inst.speed_level; repeat(40) @(posedge Clk);
  force dut.Playfield_inst.score = 20'd777; repeat(2) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("加分瞬间分数=青", rgb, `CY_MENU);
  repeat(40) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("加分后分数=白", rgb, `WHITE);
  release dut.Playfield_inst.score; repeat(40) @(posedge Clk);
  Finalize = 1'b1; repeat(40) @(posedge Clk);
  look(11'd600, 11'd445);   chk("结束下划线非黑", (rgb !== `BLACK), 1);
  Finalize = 1'b0; repeat(40) @(posedge Clk);
  $display("=== 18) 实心方块 2px 圆角 ===");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0;
  dut.state_color[0] = 3'd0;
  dut.Playfield_inst.state[0] = 1'b0;
  repeat(40) @(posedge Clk);
  force dut.Playfield_inst.Piece = 1'b1;
  force dut.Playfield_inst.type = 3'd2;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("下落块左上角=黑", rgb, `FLDBG);
  look(11'd322, 11'd82);   chk("下落块角内第2像素=黄", rgb, `YELLOW);
  look(11'd323, 11'd81);   chk("下落块左边缘=黄", rgb, `YELLOW);
  look(11'd321, 11'd83);   chk("下落块上边缘=黄", rgb, `YELLOW);
  look(11'd336, 11'd96);   chk("下落块中心=黄", rgb, `YELLOW);
  force dut.Playfield_inst.Piece = 1'b0;
  force dut.Playfield_inst.Piece2 = 1'b1;
  force dut.Playfield_inst.type2 = 3'd4;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("P2 下落块角=黑", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("P2 下落块边=绿", rgb, 24'h55A630);
  force dut.Playfield_inst.Piece2 = 1'b0;
  dut.state_color[0] = 3'd3;
  dut.Playfield_inst.state[0] = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("已锁格角=黑", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("已锁格边=红", rgb, `RED);
  force dut.Playfield_inst.Piece = 1'b1;
  force dut.Playfield_inst.type = 3'd2;
  force dut.land_we = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("落锁闪白角=黑", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("落锁闪白边=白", rgb, 24'hEEEEEE);
  release dut.land_we;
  release dut.Playfield_inst.Piece;
  release dut.Playfield_inst.type;
  force dut.clear_t_r = 1'b1;
  force dut.flash_r = 1'b1;
  repeat(4) @(posedge Clk);
  look(11'd321, 11'd81);   chk("消行闪白角=黑", rgb, `FLDBG);
  look(11'd323, 11'd81);   chk("消行闪白边=白", rgb, 24'hEEEEEE);
  release dut.clear_t_r;
  release dut.flash_r;
  dut.state_color[0] = 3'd0;
  dut.Playfield_inst.state[0] = 1'b0;
  repeat(4) @(posedge Clk);
  $display("=== 19) 预览方块 1px 圆角 ===");
  duo = 1'b1; Playing = 1'b1; choose = 1'b0; Finalize = 1'b0; repeat(40) @(posedge Clk);
  force dut.Playfield_inst.type_t = 3'd2;
  force dut.Playfield_inst.type_t2 = 3'd4;
  repeat(40) @(posedge Clk);
  look(11'd126, 11'd228);   chk("P1 NEXT 预览角=槽底", rgb, `SLOT_P1);
  look(11'd128, 11'd228);   chk("P1 NEXT 预览边=黄", rgb, `YELLOW);
  look(11'd126, 11'd230);   chk("P1 NEXT 预览下边=黄", rgb, `YELLOW);
  look(11'd140, 11'd240);   chk("P1 NEXT 预览中心=黄", rgb, `YELLOW);
  look(11'd1153, 11'd228);  chk("P2 NEXT 预览角=槽底", rgb, `SLOT_P2);
  look(11'd1155, 11'd228);  chk("P2 NEXT 预览边=绿", rgb, 24'h55A630);
  look(11'd1167, 11'd240);  chk("P2 NEXT 预览中心=绿", rgb, 24'h55A630);
  force dut.Playfield_inst.hold_type = 3'd3;
  force dut.en_hold = 1'b1;
  repeat(40) @(posedge Clk);
  look(11'd126, 11'd444);   chk("HOLD 预览角=槽底", rgb, `SLOT_P1);
  look(11'd128, 11'd444);   chk("HOLD 预览边=红", rgb, `RED);
  look(11'd140, 11'd456);   chk("HOLD 预览中心=红", rgb, `RED);
  release dut.Playfield_inst.hold_type;
  release dut.en_hold;
  release dut.Playfield_inst.type_t;
  release dut.Playfield_inst.type_t2;
  repeat(4) @(posedge Clk);
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
