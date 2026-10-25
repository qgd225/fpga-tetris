// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps

//============================================================
// 测试台：duo_tb
// 测试目标：Playfield 双人模式回归：出生、互撞、锁存、Hold、消行、幽灵和音效门控。
//============================================================
//===== Playfield Duo 专项测试: 互撞/顶住/幽灵/共用Hold/出生列/时间阈值/消行 =====
module Tetromino(input clka,input [4:0] addra,output [31:0] douta);
 reg [31:0] mem[0:31],q;
 initial begin mem[0]=32'hd0e0f00; mem[1]=32'h30201000; mem[2]=32'hd0e0f00; mem[3]=32'h30201000; mem[4]=32'h1fff0f00; mem[5]=32'he1f0f00; mem[6]=32'h1f201000; mem[7]=32'heff0f00; mem[8]=32'h1f0f1000; mem[9]=32'h1f0f1000; mem[10]=32'h1f0f1000; mem[11]=32'h1f0f1000; mem[12]=32'h1f0ff0ff; mem[13]=32'h10000f0e; mem[14]=32'h1f1e0fff; mem[15]=32'hf0efe; mem[16]=32'h101f0fff; mem[17]=32'h1e000f0e; mem[18]=32'h1f0ffffe; mem[19]=32'hf0ef0; mem[20]=32'h10000fff; mem[21]=32'h1f1e000f; mem[22]=32'h1f0f0efe; mem[23]=32'hf0ef0ff; mem[24]=32'h1f000ff0; mem[25]=32'h101f0f0e; mem[26]=32'h1e0f0eff; mem[27]=32'hffffe; mem[28]=32'h0; mem[29]=32'h0; mem[30]=32'h0; mem[31]=32'h0; end
 always @(posedge clka)q<=mem[addra];
 assign douta=duo_tb.use_rom?q:duo_tb.shape_val;
endmodule
module weiyibiao(input clka,input [4:0] addra,output [7:0] douta);
 reg [7:0] mem[0:31],q;
 initial begin mem[0]=8'h10; mem[1]=8'hf0; mem[2]=8'h10; mem[3]=8'hf0; mem[4]=8'h0; mem[5]=8'h0; mem[6]=8'h0; mem[7]=8'h0; mem[8]=8'h0; mem[9]=8'h0; mem[10]=8'h0; mem[11]=8'h0; mem[12]=8'h0; mem[13]=8'hff; mem[14]=8'h11; mem[15]=8'h0; mem[16]=8'h0; mem[17]=8'hff; mem[18]=8'h11; mem[19]=8'h0; mem[20]=8'h0; mem[21]=8'hff; mem[22]=8'h11; mem[23]=8'h0; mem[24]=8'h0; mem[25]=8'hff; mem[26]=8'h11; mem[27]=8'h0; mem[28]=8'h0; mem[29]=8'h0; mem[30]=8'h0; mem[31]=8'h0; end
 always @(posedge clka)q<=mem[addra];
 assign douta=duo_tb.use_rom?q:8'd0;
endmodule

module duo_tb;
reg use_rom=0;
reg [2:0] test_story_speed=0;
reg [2:0] rt;
reg [1:0] rr;
reg [4:0] peer_c,peer_r;
integer pi,ti,ri,xc,yr,ai,bi,ax,ay,bx,by,nx,ny,dc,dr,rot_checks=0,rot_blocked=0;
reg now_overlap,next_overlap;
reg [31:0] current_shape,next_shape,peer_shape;
function integer signed_nibble;input [3:0] value;begin signed_nibble=value[3]?value-16:value;end endfunction

reg Clk_74M=0, Rst=0;
reg [10:0] hc=0, vc=0;
reg left1=0, right1=0, drop1=0, drop_en1=0, rot1=0, sw1=0, hold1=0;
reg left2=0, right2=0, drop2=0, drop_en2=0, rot2=0, hold2=0;
reg Idle=0, Playing=1, Stop=0, Finalize=0;
reg [19:0] score=0;
reg [13:0] time_sec=0;
reg duo=1;
reg duu=1;
reg [31:0] shape_val = 32'h0;  // 合成形状(默认退化单格)

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
  .mission_hold(1'b0), .story_speed(test_story_speed),
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

reg [4:0]test_row;
task clr_state;
begin
  // 通过公共写口清场, 保证全部物理存储副本同步清零。
  @(negedge Clk_74M);
  force dut.row_we = 1'b1;
  force dut.row_data = 24'd0;
  force dut.row_addr = test_row;
  for(test_row=0; test_row<20; test_row=test_row+1)begin
    @(posedge Clk_74M); @(negedge Clk_74M);
  end
  force dut.row_we = 1'b0;
  #1;
  release dut.row_we;
  release dut.row_data;
  release dut.row_addr;
  @(posedge Clk_74M);
end
endtask

initial begin
  bad = 0;
  Rst = 0; #200; Rst = 1; repeat(30) @(posedge Clk_74M);

  $display("=== 1) 出生列(双人 = 24 列三等分点) ===");
  chk("duo=1 P1 出生列", dut.counter_c, 8);
  chk("duo=1 P2 出生列", dut.counter_c2, 16);
  duo = 1'b0; Rst = 0; #200; Rst = 1; repeat(30) @(posedge Clk_74M);
  chk("duo=0 P1 出生列", dut.counter_c, 9);
  chk("duo=0 P2 出生列", dut.counter_c2, 9);
  duo = 1'b1; Rst = 0; #200; Rst = 1; repeat(30) @(posedge Clk_74M);
  force dut.Drop = 30'd100_000_000;  // 关闭自动下落, 便于精确测试

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
  lock2;  // P2 锁存到 (8,11)
  chk("P2 已锁进地图", dut.state[8*20 + 11], 1);
  chk("上方方块 land=1", dut.land, 1);
  repeat(6) @(posedge Clk_74M);
  chk("锁存计时在走", (dut.counter_land > 0), 1);
  lock1;  // 触发 P1 锁存到 (8,10)
  chk("P1 锁存到地图", dut.state[8*20 + 10], 1);
  release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
  clr_state;

  $display("=== 4) 对方滑走 -> 恢复下落 ===");
  force dut.counter_c  = 5'd8;  force dut.counter_r  = 5'd10;
  force dut.counter_c2 = 5'd8;  force dut.counter_r2 = 5'd11;
  repeat(4) @(posedge Clk_74M);
  chk("被顶住时不落", dut.other_down_hold, 1);
  release dut.counter_c2; force dut.counter_c2 = 5'd12;  // 对方滑走
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
  hc = 11'd577; vc = 11'd337;  // 第8列 第11行
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
  hc = 11'd577; vc = 11'd689;  // 第8列 第19行
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
  shape_val = 32'h0F0F0F0F;  // 每格: 列偏移 0, 行偏移 -1(顶部之外)
  repeat(4) @(posedge Clk_74M);
  release dut.rot;
  repeat(2) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("顶部(行 -1)旋转被允许", dut.rot, 1);
  chk_no_x("旋转后行号", dut.rr_r);
  chk("旋转后行号为负(bit5=1)", dut.rr_r[5], 1);
  shape_val = 32'h04040404;  // 行偏移 +4
  force dut.counter_r = 5'd16;  // 16+4 = 20 行 = 地板以下
  repeat(4) @(posedge Clk_74M);
  p_rot1; repeat(2) @(posedge Clk_74M);
  chk("旋转到地板以下被阻挡", dut.rot, 1);
  shape_val = 32'h50505050;  // 列偏移 +5(高半字节)
  force dut.counter_r = 5'd0; force dut.counter_c = 5'd20;  // 20+5 = 25 > 23
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
  time_sec=14'd1200; score=20'd99999;
  repeat(4) @(posedge Clk_74M); chk("time and score cannot accelerate",speed_level,0);
  for(integer sp=0;sp<8;sp=sp+1)begin
    test_story_speed=sp; repeat(4) @(posedge Clk_74M);
    chk("mission speed forwarded",speed_level,sp);
  end
  test_story_speed=0; time_sec=0; score=0;

  $display("=== 14) 单机时间阈值回归(20/60/...) ===");
  duo = 1'b0; score = 20'd0;
  time_sec = 14'd19;  repeat(4) @(posedge Clk_74M); chk("solo 19s", speed_level, 0);
  time_sec = 14'd20;  repeat(4) @(posedge Clk_74M); chk("solo time does not accelerate", speed_level, 0);
  time_sec = 14'd60;  repeat(4) @(posedge Clk_74M); chk("solo time does not accelerate", speed_level, 0);
  time_sec = 14'd600; repeat(4) @(posedge Clk_74M); chk("solo time does not accelerate", speed_level, 0);
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
  for(integer c1 = 0; c1 < 12; c1 = c1 + 1) dut.state[c1*20 + 5] = 1'b1;
  repeat(2) @(posedge Clk_74M);
  chk("只填 12 格不消行", clear, 0);
  clr_state;
  for(integer c2 = 0; c2 < 24; c2 = c2 + 1) dut.state[c2*20 + 5] = 1'b1;
  repeat(2) @(posedge Clk_74M);
  chk("填满 24 格消行", clear, 1);
  clr_state;
  for(integer c3 = 0; c3 < 24; c3 = c3 + 1)begin
    dut.state[c3*20 + 5] = 1'b1;
    dut.state[c3*20 + 7] = 1'b1;
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

  $display("=== 20) 幽灵落点: 扫到行上限也要更新(不能停旧值) ===");
  begin : ghost_row_chk
    clr_state;
    duo = 1'b0; repeat(4) @(posedge Clk_74M);
    force dut.clear_t = 1'b0;  // 前面测试留下的闪白会挡住幽灵显示
    force dut.counter_land = 25'd0; force dut.lock_counter = 25'd0;
    force dut.lock_t = 1'b0; force dut.lock_cnt = 2'd0;
    force dut.drop_r_t = 1'b1;
    force dut.counter_c = 5'd5; force dut.counter_r = 5'd5;
    shape_val = 32'h30201000;  // 4 格同行(行偏移全 0): 锚点最多到 19
    p_rot1; repeat(20) @(posedge Clk_74M);
    chk("行偏移全 0: 落点=19", dut.counter_ghost_r_t, 19);
    shape_val = 32'h1F0FFFFE;  // 行偏移 -1/-2(没有 0): 锚点必须到 20
    p_rot1; repeat(30) @(posedge Clk_74M);
    chk("行偏移 -1/-2: 落点=20", dut.counter_ghost_r_t, 20);
    hc = 11'd481; vc = 11'd689;  // 第5列 第19行, 空场地: 幽灵应在这里
    repeat(2) @(posedge Clk_74M);
    chk("幽灵画在第19行(不悬空)", ghost, 1);
    hc = 11'd0; vc = 11'd0; repeat(2) @(posedge Clk_74M);
    release dut.counter_c; release dut.counter_r;
    hard1;  // 硬降要停在落点
    chk("硬降停在落点(20)", dut.counter_r, 20);
    chk("停在落点时已满足落底", dut.land, 1);
    release dut.counter_land; release dut.lock_counter;
    release dut.lock_t; release dut.lock_cnt; release dut.drop_r_t; release dut.clear_t;
    shape_val = 32'h0;
    clr_state;
  end

  $display("=== 21) 幽灵不能压在对方运动方块上 ===");
  begin : ghost_oth_chk
    clr_state;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
    shape_val = 32'h000FFFFE;  // J rot3: (-1,-2)(-1,-1)(0,-1)(0,0)
    force dut.counter_c  = 5'd16; force dut.counter_r  = 5'd19;  // P1: (15,17)(15,18)(16,18)(16,19)
    force dut.counter_c2 = 5'd16; force dut.counter_r2 = 5'd4;  // P2: (15,2)(15,3)(16,3)(16,4)
    p_rot1; p_rot2; repeat(40) @(posedge Clk_74M);
    chk("P2 幽灵落在 P1 方块上方(=17)", dut.counter_ghost_r_t2, 17);
    chk("被对方方块挡住要标记", dut.ghost_blk_oth2, 1);
    chk("P1 幽灵落在底板(=19)", dut.counter_ghost_r_t, 19);
    release dut.counter_c; release dut.counter_r; release dut.counter_c2; release dut.counter_r2;
    hard2;  // 硬降要停在对方方块上
    chk("P2 硬降停在对方方块上(17)", dut.counter_r2, 17);
    shape_val = 32'h0;
    clr_state;
  end

  $display("=== 22) C_num/R_num 编号: 与原来逐格比较逐位等价 ===");
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
    chk("duo=1 列编号逐点一致(801 点)", bad_c, 0);
    for(vc2 = 60; vc2 <= 740; vc2 = vc2 + 1)begin
      hc = 11'd577; vc = vc2[10:0];
      #1;
      r_exp = 24;
      for(p2 = 0; p2 < 20; p2 = p2 + 1)
      if((vc2 >= (81 + 32*p2)) && (vc2 < (111 + 32*p2))) r_exp = p2;
      if(R_num !== r_exp[4:0]) bad_r = bad_r + 1;
    end
    chk("duo=1 行编号逐点一致(681 点)", bad_r, 0);
    duo = 1'b0; col_now = 20; bad_c = 0; bad_r = 0;
    for(hc2 = 300; hc2 <= 1100; hc2 = hc2 + 1)begin
      hc = hc2[10:0]; vc = 11'd400;
      #1;
      c_exp = 24;
      for(o2 = 0; o2 < 24; o2 = o2 + 1)
      if((o2 < col_now) && (hc2 >= (321 + 32*o2)) && (hc2 < (351 + 32*o2))) c_exp = o2;
      if(C_num !== c_exp[4:0]) bad_c = bad_c + 1;
    end
    chk("duo=0 列编号逐点一致(801 点)", bad_c, 0);
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
  $display("=== 28) hint row map and type refresh ===");
  begin : hint_map_type_chk
    duo = 1'b0; Playing = 1'b1; Idle = 1'b0; Stop = 1'b0; Finalize = 1'b0;
    clr_state; repeat(20) @(posedge Clk_74M);
    dut.state[3*20 + 19] = 1'b1; #1;
    chk("hint map bottom row 19", dut.hint_row_bits[19*24 + 3], 1);
    dut.state[3*20 + 19] = 1'b0;
    dut.state[3*20 + 0] = 1'b1; #1;
    chk("hint map top row 0", dut.hint_row_bits[3], 1);
    dut.state[3*20 + 0] = 1'b0;
    force dut.type = 3'd2; repeat(2) @(posedge Clk_74M); #1;
    force dut.type = 3'd5; #1;
    chk("hint type change restarts", dut.hint_start, 1);
    @(posedge Clk_74M); #1; release dut.type;
    duo = 1'b1; repeat(4) @(posedge Clk_74M);
  end
  $display("=== 29) real synchronous ROM rotation collision sweep ===");
  clr_state;use_rom=1;duo=1;Playing=1;Stop=1;
  for(pi=0;pi<2;pi=pi+1)begin
  if(pi==0)begin
    force dut.type=rt;force dut.rot=rr;force dut.type2=3'd2;force dut.rot2=2'd0;
    force dut.counter_c=5'd10;force dut.counter_r=5'd9;force dut.counter_c2=peer_c;force dut.counter_r2=peer_r;
  end else begin
    force dut.type2=rt;force dut.rot2=rr;force dut.type=3'd2;force dut.rot=2'd0;
    force dut.counter_c2=5'd10;force dut.counter_r2=5'd9;force dut.counter_c=peer_c;force dut.counter_r=peer_r;
  end
  force dut.counter_drop=30'd0;force dut.counter_drop2=30'd0;
  for(ti=0;ti<7;ti=ti+1)for(ri=0;ri<4;ri=ri+1)begin
    rt=ti;rr=ri;
    for(xc=7;xc<=13;xc=xc+1)for(yr=6;yr<=12;yr=yr+1)begin
      Stop=1;peer_c=xc;peer_r=yr;repeat(4)@(negedge Clk_74M);
      current_shape=dut.Tetromino_inst0.mem[ti*4+ri];
      next_shape=dut.Tetromino_inst0.mem[ti*4+((ri+1)%4)];
      peer_shape=dut.Tetromino_inst0.mem[8];
      dc=signed_nibble(pi==0?dut.ddc:dut.ddc2);dr=signed_nibble(pi==0?dut.ddr:dut.ddr2);
      now_overlap=0;next_overlap=0;
      for(ai=0;ai<4;ai=ai+1)begin
        ax=10+signed_nibble(current_shape[ai*8+4 +:4]);ay=9+signed_nibble(current_shape[ai*8 +:4]);
        nx=10+dc+signed_nibble(next_shape[ai*8+4 +:4]);ny=9+dr+signed_nibble(next_shape[ai*8 +:4]);
        for(bi=0;bi<4;bi=bi+1)begin
          bx=xc+signed_nibble(peer_shape[bi*8+4 +:4]);by=yr+signed_nibble(peer_shape[bi*8 +:4]);
          if(ax==bx && ay==by)now_overlap=1;
          if(nx==bx && ny==by)next_overlap=1;
        end
      end
      if(!now_overlap)begin
        Stop=0;#1;rot_checks=rot_checks+1;
        if((pi==0?dut.Tetromino_addr1:dut.Tetromino_addr3) !== (ti*4+(ri+1)%4))begin bad=bad+1;$display("FAIL real rotation address");end
        if((pi==0?dut.rot_block:dut.rot_block2) !== next_overlap)begin bad=bad+1;$display("FAIL real rotation prediction type=%0d rot=%0d peer=%0d,%0d",ti,ri,xc,yr);end
        if(over)begin bad=bad+1;$display("FAIL separated real pieces report over");end
        if(next_overlap)begin
          rot_blocked=rot_blocked+1;rot1=pi==0;rot2=pi==1;#1;
          if((pi==0?dut.en_rotate:dut.en_rotate2) || !(pi==0?dut.blk_rot1:dut.blk_rot2))begin bad=bad+1;$display("FAIL rotation into peer accepted");end
          @(negedge Clk_74M);rot1=0;rot2=0;#1;
          if(over)begin bad=bad+1;$display("FAIL rejected rotation ends game");end
        end
      end
    end
  end
  end
  Stop=1;rot1=0;rot2=0;
  release dut.type;release dut.rot;release dut.type2;release dut.rot2;
  release dut.counter_c;release dut.counter_r;release dut.counter_c2;release dut.counter_r2;
  release dut.counter_drop;release dut.counter_drop2;
  // 合法旋转必须真正提交，检查同步ROM切换期间也不会误报终局。
  force dut.type=rt;force dut.type2=rt;
  for(ti=0;ti<7;ti=ti+1)for(ri=0;ri<4;ri=ri+1)begin
    Stop=1;rt=ti;
    @(negedge Clk_74M);dut.rot=ri;dut.rot2=ri;
    dut.counter_c=6;dut.counter_r=9;dut.counter_c2=18;dut.counter_r2=9;
    repeat(4)@(negedge Clk_74M);Stop=0;rot1=1;rot2=1;#1;
    if(!dut.en_rotate || !dut.en_rotate2)begin bad=bad+1;$display("FAIL separated simultaneous rotation refused type=%0d rot=%0d",ti,ri);end
    @(negedge Clk_74M);rot1=0;rot2=0;
    repeat(4)begin @(negedge Clk_74M);if(over)begin bad=bad+1;$display("FAIL accepted rotation reports over");end end
    if(dut.rot!==(ri+1)%4 || dut.rot2!==(ri+1)%4)begin bad=bad+1;$display("FAIL accepted rotation did not advance");end
  end
  release dut.type;release dut.type2;
  chk("real cases exercised",rot_checks>500,1);chk("blocked real cases exercised",rot_blocked>20,1);
  $display("REAL_ROTATION_CASES %0d blocked=%0d",rot_checks,rot_blocked);
  if(bad == 0) $display("=== ALL PASS ===");
  else         $display("=== FAILED %0d ===", bad);
  $finish;
end
endmodule
