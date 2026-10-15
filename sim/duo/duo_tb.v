`timescale 1ns/1ps

//===== Playfield Duo 专项测试: 互撞/顶住/幽灵/共用Hold/出生列/时间阈值/消行 =====
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = duo_tb.shape_val;   // 桩: 默认 0 -> 单格; 旋转测试时由 tb 赋合成形状
endmodule
module weiyibiao(input clka, input [4:0] addra, output [7:0] douta);
  assign douta = 8'h00;   // 桩: 旋转偏移 0
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
reg [31:0] shape_val = 32'h0;   // 合成形状(默认退化单格)

wire [479:0] state;
wire Piece, ghost, Piece2, ghost2, over, clear, clear_time, clear_pulse, clear_t_t, clear_t;
wire [4:0] C_num, R_num, C_num2, R_num2, c_clear, clear_row;
wire [2:0] type, type_t, type_d, type2_out, type_t2_out, type_d2_out, speed_level;
wire [1:0] lock_idx, lock_idx2;
wire lock_t, lock_we, land_we, en_hold, lock_we2, land_we2;
wire [19:0] cc_d, rr_d, cc_d2, rr_d2, line_t;
wire [2:0] hold_type;

always #6.734 Clk_74M = ~Clk_74M;

Playfield dut(
  .Clk_74M(Clk_74M), .Reset_n(Rst), .hcounter(hc), .vcounter(vc),
  .left_p_flag(left1), .right_p_flag(right1), .drop_r_flag(drop1), .drop_en(drop_en1),
  .rotate_p_flag(rot1), .switch_r_flag(sw1), .hold_p_flag(hold1),
  .Idle(Idle), .Playing(Playing), .Stop(Stop), .Finalize(Finalize),
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
  .lock_we2(lock_we2), .lock_idx2(lock_idx2), .land_we2(land_we2), .type_t2_out(type_t2_out)
);

integer bad;
integer ram_bad = 0;
reg ram_chk_on = 1'b1;   // 第19组故意只写副本这一段会关掉
integer mq, mcc;
reg [23:0] mw;
// 全程核查: 镜像与 8 份副本内容必须逐位一致
// 复位期间镜像走异步复位、副本靠 20 拍清零, 那段时间不比; 其余时刻必须一致
always @(posedge Clk_74M) begin
  #1;
  if(ram_chk_on && (Rst === 1'b1) && (dut.boot_clr === 1'b0) && (ram_eq_state(1'b0) !== 1))begin
    if(ram_bad == 0)begin
      $display("  [dbg] 首次镜像!=副本 @%0t row_we=%0d row_a=%0d wm=%0d mv_act=%0d", $time, dut.row_we, dut.row_a, dut.wm, dut.mv_act);
      for(mq = 0; mq < 20; mq = mq + 1)begin
        mw = 24'd0;
        for(mcc = 0; mcc < 24; mcc = mcc + 1) mw[mcc] = dut.state[mcc*20 + mq];
        if(mw !== dut.state_ram[0][mq]) $display("  [dbg] row %0d mirror=%h r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h", mq, mw, dut.state_ram[0][mq], dut.state_ram[1][mq], dut.state_ram[2][mq], dut.state_ram[3][mq], dut.state_ram[4][mq], dut.state_ram[5][mq], dut.state_ram[6][mq], dut.state_ram[7][mq]);
      end
    end
    ram_bad = ram_bad + 1;
  end
end
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
  if((^sig) === 1'bx)begin $display("  FAIL %0s 出现 X", name); bad = bad + 1; end
  else $display("  ok   %0s 无 X (=%0d)", name, sig);
end
endtask

// 单拍脉冲(时钟低电平期动作, 避免竞争)
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

// P1 硬降(长按 drop_en)
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

// 触发一次锁存(把两个计时器直接推到阈值)
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

// 摆场地: 镜像与 8 份副本同时写(判定读副本, 渲染读镜像)
task set_cell;
input [4:0] cc; input [4:0] rr;
begin
  dut.state[cc*20 + rr] = 1'b1;
  dut.state_ram[0][rr][cc] = 1'b1;
  dut.state_ram[1][rr][cc] = 1'b1;
  dut.state_ram[2][rr][cc] = 1'b1;
  dut.state_ram[3][rr][cc] = 1'b1;
  dut.state_ram[4][rr][cc] = 1'b1;
  dut.state_ram[5][rr][cc] = 1'b1;
  dut.state_ram[6][rr][cc] = 1'b1;
  dut.state_ram[7][rr][cc] = 1'b1;
end
endtask

// 只写 8 份副本(不写镜像): 验证判定/幽灵确实读副本
task set_cell_ram;
input [4:0] cc; input [4:0] rr;
begin
  dut.state_ram[0][rr][cc] = 1'b1;
  dut.state_ram[1][rr][cc] = 1'b1;
  dut.state_ram[2][rr][cc] = 1'b1;
  dut.state_ram[3][rr][cc] = 1'b1;
  dut.state_ram[4][rr][cc] = 1'b1;
  dut.state_ram[5][rr][cc] = 1'b1;
  dut.state_ram[6][rr][cc] = 1'b1;
  dut.state_ram[7][rr][cc] = 1'b1;
end
endtask

// 清场: 镜像与 8 份副本一起清(副本没有异步复位, 只能这样清)
task clr_state;
integer q;
begin
  force dut.row_we = 1'b0;
  @(posedge Clk_74M);
  dut.state = 480'd0;
  for(q = 0; q < 20; q = q + 1)begin
    dut.state_ram[0][q] = 24'd0;
    dut.state_ram[1][q] = 24'd0;
    dut.state_ram[2][q] = 24'd0;
    dut.state_ram[3][q] = 24'd0;
    dut.state_ram[4][q] = 24'd0;
    dut.state_ram[5][q] = 24'd0;
    dut.state_ram[6][q] = 24'd0;
    dut.state_ram[7][q] = 24'd0;
  end
  @(posedge Clk_74M);
  release dut.row_we;
  @(posedge Clk_74M);
end
endtask

// 镜像与 8 份副本内容是否逐位一致
function integer ram_eq_state;
input d;
integer q, cc;
reg [23:0] w;
begin
  ram_eq_state = 1;
  for(q = 0; q < 20; q = q + 1)begin
    w = 24'd0;
    for(cc = 0; cc < 24; cc = cc + 1)
    w[cc] = dut.state[cc*20 + q];
    if(w !== dut.state_ram[0][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[1][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[2][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[3][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[4][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[5][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[6][q]) ram_eq_state = 0;
    if(w !== dut.state_ram[7][q]) ram_eq_state = 0;
  end
end
endfunction

// 某行已落格数(读镜像)
function integer row_cnt;
input integer rr;
integer cc;
begin
  row_cnt = 0;
  for(cc = 0; cc < 24; cc = cc + 1)
  if(dut.state[cc*20 + rr] === 1'b1) row_cnt = row_cnt + 1;
end
endfunction

// 场地上已落格总数(读镜像)
function integer field_cnt;
input d;
integer cc, rr;
begin
  field_cnt = 0;
  for(rr = 0; rr < 20; rr = rr + 1)
  for(cc = 0; cc < 24; cc = cc + 1)
  if(dut.state[cc*20 + rr] === 1'b1) field_cnt = field_cnt + 1;
end
endfunction

// 8 份副本里含 X 的字数
function integer ram_x_cnt;
input d;
integer q;
begin
  ram_x_cnt = 0;
  for(q = 0; q < 20; q = q + 1)begin
    if((^dut.state_ram[0][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[1][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[2][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[3][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[4][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[5][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[6][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
    if((^dut.state_ram[7][q]) === 1'bx) ram_x_cnt = ram_x_cnt + 1;
  end
end
endfunction

initial begin
  bad = 0;
  Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk_74M);

  $display("=== 1) 出生列(双人 = 24 列三等分点) ===");
  chk("duo=1 P1 出生列", dut.counter_c, 8);
  chk("duo=1 P2 出生列", dut.counter_c2, 16);
  duo = 1'b0; Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk_74M);
  chk("duo=0 P1 出生列", dut.counter_c, 9);
  chk("duo=0 P2 出生列", dut.counter_c2, 9);
  duo = 1'b1; Rst = 0; #200; Rst = 1; repeat(10) @(posedge Clk_74M);
  force dut.Drop = 30'd100_000_000;      // 关闭自动下落, 便于精确测试

  $display("=== 2) 压在对方运动方块上: 停住但不开始锁存 ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("下行被对方顶住", dut.other_down_hold, 1);
  chk("顶住时不置 land", dut.land, 0);
  chk("顶住时不锁存计时", dut.counter_land, 0);
  p_drop1;
  chk("顶住时软降无效", dut.counter_r, 10);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  repeat(4) @(posedge Clk_74M);

  $display("=== 3) 对方锁进 state 后: 立刻满足落底并正常计时锁存 ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  lock2;                                  // P2 锁存到 (8,11)
  chk("P2 已锁进地图", dut.state[8*20 + 11], 1);
  chk("上方方块 land=1", dut.land, 1);
  repeat(6) @(posedge Clk_74M);
  chk("锁存计时在走", (dut.counter_land > 0), 1);
  lock1;                                  // 触发 P1 锁存到 (8,10)
  chk("P1 锁存到地图", dut.state[8*20 + 10], 1);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 4) 对方滑走 -> 恢复下落 ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("被顶住时不落", dut.other_down_hold, 1);
  release dut.counter_c2; force dut.counter_c2 = 5'd12;   // 对方滑走
  repeat(4) @(posedge Clk_74M);
  chk("滑走后不再被顶住", dut.other_down_hold, 0);
  release dut.counter_r;
  repeat(4) @(posedge Clk_74M);
  chk("滑走后已解除顶住(land 仍为0)", dut.land, 0);
  p_drop1;
  chk("滑走后恢复下落", (dut.counter_r > 10), 1);
  release dut.counter_c; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 5) 左右被对方挡住 ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd9;  force dut.counter_r2 = 5'd10;
  repeat(4) @(posedge Clk_74M);
  p_right1;
  chk("右移被对方挡住", dut.counter_c, 8);
  release dut.counter_c2; force dut.counter_c2 = 5'd12;
  repeat(4) @(posedge Clk_74M);
  release dut.counter_c;
  repeat(2) @(posedge Clk_74M);
  p_right1;
  chk("对方让开后可以右移", dut.counter_c, 9);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 6) 硬降停在对方方块上 + 幽灵不显示 ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd0;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  settle;
  chk("幽灵落点=对方方块上一行", dut.counter_ghost_r_t, 10);
  chk("幽灵被对方挡住标志", dut.ghost_blk_oth, 1);
  hc = 11'd577; vc = 11'd337;            // 第8列 第11行
  repeat(2) @(posedge Clk_74M);
  chk("被对方挡住时不画幽灵", ghost, 0);
  release dut.counter_r;
  repeat(2) @(posedge Clk_74M);
  hard1;
  chk("硬降停在对方方块上(行10)", dut.counter_r, 10);
  chk("停在对方身上时不锁存计时", dut.counter_land, 0);
  hc = 11'd0; vc = 11'd0; repeat(2) @(posedge Clk_74M);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 7) 幽灵正常显示(空场地落到底) ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd0;
  force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd0;
  settle;
  chk("幽灵落点=地板", dut.counter_ghost_r_t, 19);
  chk("未被对方挡住", dut.ghost_blk_oth, 0);
  hc = 11'd577; vc = 11'd689;            // 第8列 第19行
  repeat(2) @(posedge Clk_74M);
  chk("幽灵像素显示", ghost, 1);
  hc = 11'd0; vc = 11'd0; repeat(2) @(posedge Clk_74M);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;

  $display("=== 8) P2 靠右列(22/23)幽灵不出现 X ===");
  force dut.counter_c2 = 5'd22; force dut.counter_r2 = 5'd0;
  force dut.counter_c  = 5'd1;  force dut.counter_r  = 5'd0;
  settle;
  chk_no_x("P2 幽灵落点", dut.counter_ghost_r_t2);
  chk("P2 幽灵落点=地板", dut.counter_ghost_r_t2, 19);
  force dut.counter_c2 = 5'd23;
  settle;
  chk_no_x("P2 第23列幽灵落点", dut.counter_ghost_r_t2);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;

  $display("=== 9) 顶部旋转(格子伸出场地顶部)与越界阻挡 ===");
  force dut.counter_c = 5'd8; force dut.counter_r = 5'd0;
  force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd0;
  force dut.rot = 2'd0;
  shape_val = 32'h0F0F0F0F;              // 每格: 列偏移 0, 行偏移 -1(顶部之外)
  repeat(4) @(posedge Clk_74M);
  release dut.rot;
  repeat(2) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("顶部(行 -1)旋转被允许", dut.rot, 1);
  chk_no_x("旋转后行号", dut.rr_r);
  chk("旋转后行号为负(bit5=1)", dut.rr_r[5], 1);
  shape_val = 32'h04040404;              // 行偏移 +4
  force dut.counter_r = 5'd16;           // 16+4 = 20 行 = 地板以下
  repeat(4) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("旋转到地板以下被阻挡", dut.rot, 1);
  shape_val = 32'h50505050;              // 列偏移 +5(高半字节)
  force dut.counter_r = 5'd0; force dut.counter_c = 5'd20;   // 20+5 = 25 > 23
  repeat(4) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("旋转伸出右墙被阻挡", dut.rot, 1);
  shape_val = 32'h0;
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 10) 两人共用一个 Hold 槽 ===");
  force dut.type  = 3'd3;  force dut.type2 = 3'd5;
  repeat(4) @(posedge Clk_74M);
  p_hold1; repeat(2) @(posedge Clk_74M);
  chk("P1 存 -> 槽=P1 的块", dut.hold_type, 3);
  p_hold2; repeat(2) @(posedge Clk_74M);
  chk("P2 存 -> 槽=P2 的块", dut.hold_type, 5);
  p_hold2; repeat(2) @(posedge Clk_74M);
  chk("P2 取 -> 槽进入 P2 下一块", dut.type_t2, 5);
  p_hold1; repeat(2) @(posedge Clk_74M);
  chk("P1 取 -> 槽进入 P1 下一块", dut.type_t, 5);
  release dut.type; release dut.type2;
  repeat(4) @(posedge Clk_74M);

  $display("=== 11) 共用一条随机流: 各自取块互不阻塞 ===");
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
    chk("P1 连续取块有变化(流在推进)", (n_chg > 0), 1);
    chk("P1 取的块合法", (dut.type <= 6), 1);
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
    chk("P2 连续取块有变化(流在推进)", (n_chg > 0), 1);
    chk("P2 取的块合法", (dut.type2 <= 6), 1);
    release dut.counter_c2; release dut.counter_r2;
    clr_state;
  end

  $display("=== 12) 单机不受 P2 影响(互撞关闭) ===");
  duo = 1'b0; repeat(4) @(posedge Clk_74M);
  force dut.counter_c  = 5'd8; force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8; force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("单机不判顶住", dut.other_down_hold, 0);
  chk("单机 land 只看地图/地板", dut.land, 0);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  duo = 1'b1; repeat(4) @(posedge Clk_74M);
  clr_state;

  $display("=== 13) 双人时间阈值(40/120/240/400/600/880/1200) ===");
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
  repeat(4) @(posedge Clk_74M); chk("duo 分数等级仍生效", speed_level, 1);
  $display("=== 14) 单机时间阈值回归(20/60/...) ===");
  duo = 1'b0; score = 20'd0;
  time_sec = 14'd19;  repeat(4) @(posedge Clk_74M); chk("solo 19s", speed_level, 0);
  time_sec = 14'd20;  repeat(4) @(posedge Clk_74M); chk("solo 20s", speed_level, 1);
  time_sec = 14'd60;  repeat(4) @(posedge Clk_74M); chk("solo 60s", speed_level, 2);
  time_sec = 14'd600; repeat(4) @(posedge Clk_74M); chk("solo 600s", speed_level, 7);
  duo = 1'b1; time_sec = 14'd0; repeat(4) @(posedge Clk_74M);

  $display("=== 17) 幽灵: 场地变化后要重算, 且不能跑到方块上方 ===");
  begin : ghost_chk
    clr_state;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
    // (a) 空场地: 幽灵应在地板(19)
    force dut.counter_c = 5'd8;  force dut.counter_r = 5'd0;
    force dut.counter_c2 = 5'd20; force dut.counter_r2 = 5'd0;
    settle;
    chk("空场地幽灵=19", dut.counter_ghost_r_t, 19);
    // (b) 对方方块压在下方(运动方块): 幽灵钳位到"方块上一行", 且标记被对方挡住
    release dut.counter_c2; force dut.counter_c2 = 5'd8; force dut.counter_r2 = 5'd11;
    settle;
    chk("被对方运动方块挡住时幽灵=10", dut.counter_ghost_r_t, 10);
    chk("此时幽灵隐藏标记=1", dut.ghost_blk_oth, 1);
    // (c) 对方锁进场地: 场地变化必须触发重算 -> 幽灵仍在10, 但改为"落在已落格上"(要显示)
    lock2;
    repeat(6) @(posedge Clk_74M);
    chk("对方落格后幽灵=10", dut.counter_ghost_r_t, 10);
    chk("对方落格后幽灵显示(不再是对方方块)", dut.ghost_blk_oth, 0);
    // (d) 方块本身就在被挡的行(重叠): 幽灵不能跑到方块上方
    force dut.counter_r = 5'd11;
    settle;
    chk("起点被挡时幽灵钳位>=方块行", (dut.counter_ghost_r_t >= dut.counter_r), 1);
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
    clr_state;
  end

  $display("=== 15) 消行: 整行 24 格才消 ===");
  clr_state;
  for(integer c1 = 0; c1 < 12; c1 = c1 + 1) set_cell(c1[4:0], 5'd5);
  repeat(2) @(posedge Clk_74M);
  chk("只填 12 格不消行", clear, 0);
  clr_state;
  for(integer c2 = 0; c2 < 24; c2 = c2 + 1) set_cell(c2[4:0], 5'd5);
  repeat(2) @(posedge Clk_74M);
  chk("填满 24 格消行", clear, 1);
  clr_state;
  for(integer c3 = 0; c3 < 24; c3 = c3 + 1)begin
    set_cell(c3[4:0], 5'd5);
    set_cell(c3[4:0], 5'd7);
  end
  repeat(3) @(posedge Clk_74M);
  chk("两行同时满 clear=1", clear, 1);
  chk("d_clear=2", dut.d_clear, 2);
  clr_state;

  $display("=== 16) 随机取样: 时间采样 / 同拍分配 / Idle 搅动 ===");
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
    chk("Playing 无取块时取样值随时间变化", (d3 > 0), 1);
    d2 = 0;
    for(q = 0; q < 8; q = q + 1)begin
      exp_ns = {dut.rnd[30:0], dut.rnd[31]^dut.rnd[21]^dut.rnd[1]^dut.rnd[0]};
      @(posedge Clk_74M);
      if(dut.rnd !== exp_ns) d2 = d2 + 1;
    end
    chk("Playing 时不加搅动", d2, 0);
    Idle = 1'b1; Playing = 1'b0; repeat(4) @(posedge Clk_74M);
    d1 = 0;
    for(q = 0; q < 8; q = q + 1)begin
      exp_ns = {dut.rnd[30:0], dut.rnd[31]^dut.rnd[21]^dut.rnd[1]^dut.rnd[0]};
      @(posedge Clk_74M);
      if(dut.rnd !== exp_ns) d1 = d1 + 1;
    end
    chk("Idle 搅动生效", (d1 > 0), 1);
    Idle = 1'b0; Playing = 1'b1; repeat(2) @(posedge Clk_74M);
    force dut.rnd = 32'h000000F0; force dut.rnd_cnt = 16'h0000;
    repeat(2) @(posedge Clk_74M);
    force dut.land_pulse = 1'b1; force dut.land_pulse2 = 1'b1;
    @(posedge Clk_74M);
    release dut.land_pulse; release dut.land_pulse2;
    repeat(2) @(posedge Clk_74M);
    t1 = dut.type_t; t2 = dut.type_t2;
    $display("  [info] 同拍取块(定态): P1 next=%0d, P2 next=%0d", t1, t2);
    chk("同拍两人拿到不同块", (t1 !== t2), 1);
    release dut.rnd; release dut.rnd_cnt;
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  end

  $display("=== 17) 场地副本: 消行搬移 20 拍搬完, 内容逐位一致 ===");
  begin : mv_chk
    integer c4;
    force dut.counter_land = 25'd0; force dut.counter_land2 = 25'd0;
    force dut.lock_counter = 25'd0; force dut.lock_counter2 = 25'd0;
    force dut.lock_t = 1'b0; force dut.lock_t2 = 1'b0;
    force dut.lock_cnt = 2'd0; force dut.lock_cnt2 = 2'd0;
    clr_state;
    duo = 1'b0; repeat(4) @(posedge Clk_74M);
    set_cell(5'd5, 5'd4);                                    // 第4行第5列
    set_cell(5'd0, 5'd5); set_cell(5'd1, 5'd5); set_cell(5'd2, 5'd5);
    set_cell(5'd9, 5'd7);                                    // 满行之上, 不该动
    for(c4 = 0; c4 < 20; c4 = c4 + 1) set_cell(c4[4:0], 5'd6);
    repeat(2) @(posedge Clk_74M);
    chk("20 列填满后 clear=1", clear, 1);
    chk("摆场后镜像=8 份副本", ram_eq_state(1'b0), 1);
    force dut.clear_t = 1'b0;                                // 跳过闪白, 直接看搬移
    repeat(60) @(posedge Clk_74M);
    release dut.clear_t;
    chk("搬移后镜像=8 份副本", ram_eq_state(1'b0), 1);
    chk("搬移后 clear=0", clear, 0);
    chk("搬移后格子总数=5", field_cnt(1'b0), 5);
    chk("搬移后 第5行格数=1", row_cnt(5), 1);
    chk("搬移后 第6行格数=3", row_cnt(6), 3);
    chk("搬移后 第7行格数=1", row_cnt(7), 1);
    chk("搬移后 (5,5) 搬下来了", dut.state[5*20 + 5], 1);
    chk("搬移后 (5,4) 已空", dut.state[5*20 + 4], 0);
    chk("搬移后 (0,6)=1", dut.state[0*20 + 6], 1);
    chk("搬移后 (1,6)=1", dut.state[1*20 + 6], 1);
    chk("搬移后 (2,6)=1", dut.state[2*20 + 6], 1);
    chk("搬移后 (3,6)=0", dut.state[3*20 + 6], 0);
    chk("搬移后 (9,7) 没动", dut.state[9*20 + 7], 1);
    release dut.counter_land; release dut.counter_land2;
    release dut.lock_counter; release dut.lock_counter2;
    release dut.lock_t; release dut.lock_t2;
    release dut.lock_cnt; release dut.lock_cnt2;
    clr_state;
  end

  $display("=== 18) 复位/清场后场地全 0(镜像与 8 份副本), 初值无 X ===");
  clr_state;
  Rst = 0; #200; Rst = 1; repeat(30) @(posedge Clk_74M);
  chk("复位后镜像全 0", (dut.state === 480'd0), 1);
  chk("复位后镜像=8 份副本", ram_eq_state(1'b0), 1);
  chk("复位后副本无 X", ram_x_cnt(1'b0), 0);
  chk("复位后格子总数=0", field_cnt(1'b0), 0);

  $display("=== 19) 判定读副本: 只写副本也算数 ===");
  begin : ram_read_chk
    clr_state;
    duo = 1'b0; repeat(4) @(posedge Clk_74M);
    force dut.counter_c = 5'd5; force dut.counter_r = 5'd18;
    force dut.counter_c2 = 5'd0; force dut.counter_r2 = 5'd0;
    repeat(4) @(posedge Clk_74M);
    chk("空场时 land=0", dut.land, 0);
    ram_chk_on = 1'b0;                                       // 这一段本来就故意只写副本
    set_cell_ram(5'd5, 5'd19);                               // 只写副本
    repeat(4) @(posedge Clk_74M);
    chk("只写副本也能判定落底", dut.land, 1);
    chk("只写副本时未顶到", dut.touch_top, 0);
    clr_state;
    ram_chk_on = 1'b1;
    set_cell(5'd5, 5'd19);                                   // 镜像+副本
    repeat(4) @(posedge Clk_74M);
    chk("镜像+副本判定一致", dut.land, 1);
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
    clr_state;
  end

  chk("全程 镜像=8 份副本", (ram_bad == 0), 1);

  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
