`timescale 1ns/1ps

//===== sound 模块级回归: 事件优先级 / 查表音色 / 序列时长 / 方波翻转 =====
module sound_tb;
reg Clk_74M = 0;
reg Reset_n = 0;
reg over = 0;
reg clear = 0;
reg [2:0]clr_n = 0;
reg lvl_up = 0;
reg sw = 0;
reg menu_l = 0;
reg menu_r = 0;
reg land1 = 0;
reg land2 = 0;
reg lft1 = 0;
reg rgt1 = 0;
reg rot1 = 0;
reg hard1 = 0;
reg soft1 = 0;
reg hold1 = 0;
reg blk1 = 0;
reg lft2 = 0;
reg rgt2 = 0;
reg rot2 = 0;
reg hard2 = 0;
reg soft2 = 0;
reg hold2 = 0;
reg blk2 = 0;
wire buzz_else;

sound #(
    .MS_MAX(17'd31),
    .NOTE_SH(4'd10)
) dut(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .over(over),
    .clear(clear),
    .clr_n(clr_n),
    .lvl_up(lvl_up),
    .sw(sw),
    .menu_l(menu_l),
    .menu_r(menu_r),
    .land1(land1),
    .land2(land2),
    .lft1(lft1),
    .rgt1(rgt1),
    .rot1(rot1),
    .hard1(hard1),
    .soft1(soft1),
    .hold1(hold1),
    .blk1(blk1),
    .lft2(lft2),
    .rgt2(rgt2),
    .rot2(rot2),
    .hard2(hard2),
    .soft2(soft2),
    .hold2(hold2),
    .blk2(blk2),
    .buzz_else(buzz_else)
);

integer bad = 0;
integer checks = 0;
integer i;
integer edges;
integer cycles;
integer notes;
reg prev_buzz;
reg [3:0]prev_st;

always #5 Clk_74M = ~Clk_74M;

task chk;
input [8*40-1:0] name;
input integer got;
input integer exp;
begin
    checks = checks + 1;
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
    over = 0;
    clear = 0;
    clr_n = 0;
    lvl_up = 0;
    sw = 0;
    menu_l = 0;
    menu_r = 0;
    land1 = 0;
    land2 = 0;
    lft1 = 0;
    rgt1 = 0;
    rot1 = 0;
    hard1 = 0;
    soft1 = 0;
    hold1 = 0;
    blk1 = 0;
    lft2 = 0;
    rgt2 = 0;
    rot2 = 0;
    hard2 = 0;
    soft2 = 0;
    hold2 = 0;
    blk2 = 0;
end
endtask

task do_reset;
begin
    clear_all;
    Reset_n = 0;
    repeat(4) @(posedge Clk_74M);
    #1;
    Reset_n = 1;
    @(posedge Clk_74M);
    #1;
end
endtask

task one_pulse;
begin
    @(posedge Clk_74M);
    #1;
    clear_all;
end
endtask

task check_event;
input [8*32-1:0] name;
input integer exp_en;
begin
    chk(name, dut.en, exp_en);
    clear_all;
    while(dut.en != 0)begin
        @(posedge Clk_74M);
        #1;
    end
end
endtask

task run_clear_sequence;
input [2:0]n;
input integer exp_notes;
input [8*40-1:0]name;
begin
    do_reset;
    clr_n = n;
    clear = 1;
    @(posedge Clk_74M);
    #1;
    clear = 0;
    notes = 1;
    prev_st = dut.st;
    while(dut.en != 0)begin
        @(posedge Clk_74M);
        #1;
        if((dut.en != 0) && (!dut.tick) && (dut.st != prev_st))begin
            notes = notes + 1;
            prev_st = dut.st;
        end
    end
    chk(name, notes, exp_notes);
end
endtask

initial begin
    $display("=== sound 模块级测试 ===");
    do_reset;

    $display("=== 1) 事件编号 ===");
    menu_l = 1; one_pulse; check_event("menu_l -> 2", 2);
    soft1 = 1; one_pulse; check_event("soft1 -> 3", 3);
    soft2 = 1; one_pulse; check_event("soft2 -> 3", 3);
    blk1 = 1; one_pulse; check_event("blk1 -> 4", 4);
    blk2 = 1; one_pulse; check_event("blk2 -> 4", 4);
    lft1 = 1; one_pulse; check_event("lft1 -> 5", 5);
    rgt2 = 1; one_pulse; check_event("rgt2 -> 5", 5);
    rot1 = 1; one_pulse; check_event("rot1 -> 6", 6);
    rot2 = 1; one_pulse; check_event("rot2 -> 6", 6);
    hold1 = 1; one_pulse; check_event("hold1 -> 7", 7);
    hold2 = 1; one_pulse; check_event("hold2 -> 7", 7);
    land1 = 1; one_pulse; check_event("land1 -> 8", 8);
    land2 = 1; one_pulse; check_event("land2 -> 8", 8);
    hard1 = 1; one_pulse; check_event("hard1 -> 9", 9);
    hard2 = 1; one_pulse; check_event("hard2 -> 9", 9);
    lvl_up = 1; one_pulse; check_event("lvl_up -> 10", 10);
    clear = 1; clr_n = 1; one_pulse; check_event("clear1 -> 11", 11);
    clear = 1; clr_n = 2; one_pulse; check_event("clear2 -> 12", 12);
    clear = 1; clr_n = 3; one_pulse; check_event("clear3 -> 13", 13);
    clear = 1; clr_n = 4; one_pulse; check_event("clear4 -> 14", 14);
    sw = 1; one_pulse; check_event("sw -> 15", 15);
    over = 1; one_pulse; check_event("over -> 16", 16);

    $display("=== 2) 同拍优先级 ===");
    do_reset;
    over = 1; clear = 1; clr_n = 4; rot1 = 1; one_pulse;
    check_event("over > clear4 > rotate", 16);
    do_reset;
    clear = 1; clr_n = 4; rot1 = 1; soft1 = 1; one_pulse;
    check_event("clear4 > rotate > soft", 14);
    do_reset;
    hard1 = 1; land1 = 1; hold1 = 1; one_pulse;
    check_event("hard > land > hold", 9);
    do_reset;
    hold1 = 1; rot2 = 1; one_pulse;
    check_event("hold > rotate", 7);
    do_reset;
    blk1 = 1; soft1 = 1; one_pulse;
    check_event("blocked > soft", 4);
    do_reset;
    rot1 = 1; rot2 = 1; one_pulse;
    check_event("P1/P2 same rotate", 6);

    $display("=== 3) 播放中忽略新事件 ===");
    do_reset;
    rot1 = 1; one_pulse;
    chk("rotate starts en=6", dut.en, 6);
    hard1 = 1; over = 1;
    @(posedge Clk_74M);
    #1;
    chk("playing keeps en=6", dut.en, 6);
    clear_all;

    $display("=== 4) 消行序列长度 ===");
    run_clear_sequence(1, 2, "clear1 note count");
    run_clear_sequence(2, 3, "clear2 note count");
    run_clear_sequence(3, 4, "clear3 note count");
    run_clear_sequence(4, 5, "clear4 note count");

    $display("=== 5) 消行高电平只响一次 ===");
    do_reset;
    clear = 1; clr_n = 1;
    @(posedge Clk_74M);
    #1;
    chk("clear high starts en=11", dut.en, 11);
    while(dut.en != 0)begin
        @(posedge Clk_74M);
        #1;
    end
    chk("clear held no retrigger", dut.en, 0);
    clear = 0;
    @(posedge Clk_74M);
    #1;
    clear = 1;
    @(posedge Clk_74M);
    #1;
    chk("clear release then high retrigger", dut.en, 11);
    clear = 0;

    $display("=== 6) 音高/时长查表 ===");
    do_reset;
    over = 1; one_pulse;
    chk("over st0 note=C6", dut.note, 35459);
    chk("over st0 cnt=200ms", dut.cnt, 200);
    chk("over st_last=3", dut.st_last, 3);
    clear_all;
    @(posedge Clk_74M);
    #1;
    do_reset;
    clear = 1; clr_n = 4; one_pulse;
    chk("clear4 st0 note=C5", dut.note, 70985);
    chk("clear4 st_last=4", dut.st_last, 4);
    clear_all;
    @(posedge Clk_74M);
    #1;

    $display("=== 7) 音符切换时长 ===");
    do_reset;
    hold1 = 1; one_pulse;
    cycles = 0;
    while((dut.en != 0) && (dut.st == 0))begin
        @(posedge Clk_74M);
        #1;
        cycles = cycles + 1;
    end
    chk("hold first note 40ms*32", (cycles >= 1280) && (cycles <= 1281), 1);
    clear_all;

    $display("=== 8) 方波翻转次数 ===");
    do_reset;
    menu_l = 1; one_pulse;
    edges = 0;
    prev_buzz = buzz_else;
    while(dut.en != 0)begin
        @(posedge Clk_74M);
        #1;
        if(buzz_else != prev_buzz)begin
            edges = edges + 1;
            prev_buzz = buzz_else;
        end
    end
    chk("menu B5 15ms toggle count", edges, 13);

    $display("=== 9) 复位静音 ===");
    do_reset;
    chk("reset en=0", dut.en, 0);
    chk("reset buzz=0", buzz_else, 0);
    repeat(20) @(posedge Clk_74M);
    #1;
    chk("idle buzz=0", buzz_else, 0);

    $display("检查项: %0d", checks);
    if(bad == 0)
        $display("=== ALL PASS ===");
    else
        $display("=== FAILED %0d ===", bad);
    $finish;
end

endmodule