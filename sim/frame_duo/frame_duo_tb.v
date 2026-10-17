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
  look(11'd641, 11'd689);                       // 第10列 第19行
  chk("duo=1 P2 落格=红色", rgb, `RED);
  clr_state;
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.counter_c2 = 5'd10; force dut.Playfield_inst.counter_r2 = 5'd19;
  repeat(4) @(posedge Clk);
  lock2;                                        // 单人: 不应写入
  release dut.Playfield_inst.counter_c2; release dut.Playfield_inst.counter_r2;
  look(11'd641, 11'd689);
  chk("duo=0 P2 落格不显示", rgb, `BLACK);
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
  look(11'd100, 11'd140);   chk("duo=1 P1 Next 槽位", rgb, `SLOT_BG);
  look(11'd100, 11'd123);   chk("duo=1 P1 Next 色线", rgb, `CY_MENU);
  look(11'd100, 11'd356);   chk("duo=1 P1 Hold 槽位", rgb, `SLOT_BG);
  look(11'd100, 11'd339);   chk("duo=1 P1 Hold 色线", rgb, `CY_MENU);
  look(11'd1230, 11'd140);  chk("duo=1 P2 Next 槽位", rgb, `SLOT_BG);
  look(11'd1230, 11'd123);  chk("duo=1 P2 Next 色线", rgb, `PINK2);
  look(11'd1230, 11'd356);  chk("duo=1 P2 Hold 槽位", rgb, `SLOT_BG);
  look(11'd1230, 11'd339);  chk("duo=1 P2 Hold 色线", rgb, `PINK2);
  look(11'd1059, 11'd140);  chk("duo=1 单人槽位位置=黑", rgb, `BLACK);
  look(11'd1059, 11'd123);  chk("duo=1 单人色线位置=黑", rgb, `BLACK);
  look(11'd1104, 11'd100);  chk("旧 Next 外框位置=黑", rgb, `BLACK);
  look(11'd1120, 11'd203);  chk("旧中间虚线位置=黑", rgb, `BLACK);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1059, 11'd140);  chk("duo=0 单人 Next 槽位", rgb, `SLOT_BG);
  look(11'd1059, 11'd123);  chk("duo=0 单人 Next 色线", rgb, `GRAY_MID);
  look(11'd1059, 11'd356);  chk("duo=0 单人 Hold 槽位", rgb, `SLOT_BG);
  look(11'd100, 11'd140);   chk("duo=0 双人槽位位置=黑", rgb, `BLACK);
  look(11'd100, 11'd123);   chk("duo=0 双人色线位置=黑", rgb, `BLACK);
  look(11'd1230, 11'd140);  chk("duo=0 无 P2 槽位", rgb, `BLACK);
  look(11'd1230, 11'd123);  chk("duo=0 无 P2 色线", rgb, `BLACK);
  look(11'd1104, 11'd100);  chk("duo=0 旧 Next 外框位置=黑", rgb, `BLACK);
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
  chk("duo=0 无 P2 预览", rgb, `SLOT_BG);
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
  chk("死区像素=黑", rgb, `BLACK);
  dut.state_color[20*20 + 3] = 3'd0;
  dut.Playfield_inst.state[20*20 + 3] = 1'b0;
  look(11'd318, 11'd40);                        // 边框上方: 左边框不应出头
  chk("左边框不出头(上方=黑)", rgb, `BLACK);
  look(11'd318, 11'd200);                       // 边框旁: 左边框正常
  chk("左边框正常(旁边=白)", rgb, `WHITE);
  look(11'd321, 11'd81);
  chk("有效格(第0行第0列)", rgb, `BLACK);

  $display("=== 9) 幽灵空心框: 边带浅色 / 内部纯黑 ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd351, 11'd85);   chk("格末死区=黑", rgb, `BLACK);
  force dut.Playfield_inst.Piece = 1'b0;  force dut.Playfield_inst.Piece2 = 1'b0;
  force dut.Playfield_inst.ghost = 1'b1;  force dut.Playfield_inst.type = 3'd0;
  force dut.Playfield_inst.ghost2 = 1'b0;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd85);   chk("幽灵左边带=浅青", rgb, 24'h99EEFF);
  look(11'd349, 11'd108);  chk("幽灵右边带=浅青", rgb, 24'h99EEFF);
  look(11'd325, 11'd82);   chk("幽灵上边带=浅青", rgb, 24'h99EEFF);
  look(11'd348, 11'd109);  chk("幽灵下边带=浅青", rgb, 24'h99EEFF);
  look(11'd325, 11'd85);   chk("幽灵内部=纯黑", rgb, `BLACK);
  look(11'd348, 11'd108);  chk("幽灵内部靠角=纯黑", rgb, `BLACK);
  force dut.Playfield_inst.ghost = 1'b0;
  force dut.Playfield_inst.ghost2 = 1'b1; force dut.Playfield_inst.type2 = 3'd3;
  repeat(4) @(posedge Clk);
  look(11'd322, 11'd85);   chk("P2 幽灵左边带=浅红", rgb, 24'hFFB3B9);
  look(11'd348, 11'd109);  chk("P2 幽灵下边带=浅红", rgb, 24'hFFB3B9);
  look(11'd325, 11'd85);   chk("P2 幽灵内部=纯黑", rgb, `BLACK);
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
  look(11'd321, 11'd81);   chk("左上角切角=黑", rgb, `BLACK);
  look(11'd322, 11'd81);   chk("左上角右侧=浅青", rgb, 24'h99EEFF);
  look(11'd321, 11'd82);   chk("左上角下侧=浅青", rgb, 24'h99EEFF);
  look(11'd350, 11'd81);   chk("右上角切角=黑", rgb, `BLACK);
  look(11'd321, 11'd110);  chk("左下角切角=黑", rgb, `BLACK);
  release dut.Playfield_inst.ghost; release dut.Playfield_inst.type;
  repeat(2) @(posedge Clk);

  $display("=== 10) 等级 8 段竖条 ===");
  duo = 1'b0; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.speed_level = 3'd3; repeat(4) @(posedge Clk);
  look(11'd293, 11'd440);   chk("lv3 当前段=青", rgb, `CY_MENU);
  look(11'd293, 11'd520);   chk("lv3 第2段(已达)=灰", rgb, `GRAY_MID);
  look(11'd293, 11'd690);   chk("lv3 第0段(已达)=灰", rgb, `GRAY_MID);
  look(11'd293, 11'd360);   chk("lv3 第4段(未达)=暗", rgb, `SLOT_BG);
  look(11'd293, 11'd88);    chk("竖条顶部段缝=暗", rgb, `SLOT_BG);
  look(11'd293, 11'd80);    chk("竖条上方=黑", rgb, `BLACK);
  look(11'd310, 11'd440);   chk("竖条右侧=黑", rgb, `BLACK);
  force dut.Playfield_inst.speed_level = 3'd0; repeat(4) @(posedge Clk);
  look(11'd293, 11'd690);   chk("lv0 当前段=青", rgb, `CY_MENU);
  look(11'd293, 11'd590);   chk("lv0 第1段(未达)=暗", rgb, `SLOT_BG);
  release dut.Playfield_inst.speed_level; repeat(4) @(posedge Clk);

  $display("=== 11) 菜单屏: 无框选项 + 青色选中标记 ===");
  Playing = 1'b0; choose = 1'b1; choose_cnt = 4'd0; repeat(4) @(posedge Clk);
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
  look(11'd95,  11'd90);    chk("duo=1 NEXT 标签=标签灰", rgb, `GRAY_LBL);
  duo = 1'b0; repeat(4) @(posedge Clk);
  look(11'd1070, 11'd40);   chk("duo=0 该处无分数", rgb, `BLACK);
  look(11'd935,  11'd40);   chk("duo=0 分数贴场地右边界", rgb, `WHITE);
  look(11'd95,   11'd90);   chk("duo=0 双人标签位置=黑", rgb, `BLACK);
  look(11'd1059, 11'd90);   chk("duo=0 单人 NEXT 标签", rgb, `GRAY_LBL);
  look(11'd340,  11'd40);   chk("时间数字=白", rgb, `WHITE);
  look(11'd290,  11'd40);   chk("LV 数字=白", rgb, `WHITE);
  look(11'd240,  11'd40);   chk("LV 标签=标签灰", rgb, `GRAY_LBL);
  Finalize = 1'b1; duo = 1'b1; repeat(4) @(posedge Clk);
  look(11'd95,   11'd90);   chk("Finalize 标签暗化", rgb, `SLOT_BG);
  Finalize = 1'b0; repeat(4) @(posedge Clk);

  $display("=== 13) 标签字模 1 像素预取(修第 1 列串字) ===");
  duo = 1'b1; repeat(4) @(posedge Clk);
  hc = 11'd94 + 11'd23; vc = 11'd100; repeat(3) @(posedge Clk);
  chk("NEXT 第2字地址已预取", dut.lb_g, 5'd4);
  hc = 11'd94 + 11'd24; vc = 11'd100; repeat(3) @(posedge Clk);
  chk("NEXT 第2字第1列取到字模", dut.lb_g, 5'd4);
  chk("NEXT 第2字第1列亮", dut.lbl_r, 1'b1);
  hc = 11'd236 + 11'd23; vc = 11'd40; repeat(3) @(posedge Clk);
  chk("LV 第2字地址已预取", dut.lb_g, 5'd21);

  $display("=== 14) 双人 P2 Hold 在 HOLD 框可见 ===");
  duo = 1'b1; Playing = 1'b1; repeat(4) @(posedge Clk);
  force dut.Playfield_inst.type2 = 3'd3;
  force dut.Playfield_inst.type_t2 = 3'd0;
  hd2 = 1'b0; repeat(4) @(posedge Clk);
  look(11'd140, 11'd458);  chk("P2 hold 前 HOLD 框为空", rgb, 24'h202020);
  hd2 = 1'b1; @(posedge Clk); hd2 = 1'b0; repeat(8) @(posedge Clk);
  chk("P2 en_hold2=1", dut.Playfield_inst.en_hold2, 1'b1);
  chk("共用槽存的是 P2 的块", dut.Playfield_inst.hold_type, 3'd3);
  look(11'd140, 11'd458);
  chk("P2 hold 后 HOLD 框显示方块", rgb, `RED);
  release dut.Playfield_inst.type2; release dut.Playfield_inst.type_t2;

  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
