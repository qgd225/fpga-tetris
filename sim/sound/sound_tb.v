`timescale 1ns/1ps

//===== sound 模块级回归: 事件优先级 / 双音反馈 / 开关长短按 =====
module sound_tb;
reg Clk_74M = 0;
reg Reset_n = 0;
reg over = 0;
reg clear = 0;
reg [2:0]clr_n = 0;
reg lvl_up = 0;
reg sw_short = 0;
reg sw_long = 0;
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
reg blk_rot1 = 0;
reg blk_rot2 = 0;
wire buzz_else;

reg sm_switch_r = 0;
reg sm_switch_en = 0;
wire sm_short;
wire sm_long;
wire sm_choose;
wire sm_idle;
wire sm_playing;
wire sm_stop;
wire sm_finalize;
wire [3:0]sm_choose_cnt;

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
    .sw_short(sw_short),
    .sw_long(sw_long),
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
    .blk_rot1(blk_rot1),
    .blk_rot2(blk_rot2),
    .buzz_else(buzz_else)
);

Game_state_machine #(
    .MCNT(64)
) gsm(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .left_p(1'b0),
    .right_p(1'b0),
    .switch_r_flag(sm_switch_r),
    .switch_en(sm_switch_en),
    .over(1'b0),
    .Choose(sm_choose),
    .Idle(sm_idle),
    .Playing(sm_playing),
    .Stop(sm_stop),
    .Finalize(sm_finalize),
    .choose_cnt(sm_choose_cnt),
    .sw_short(sm_short),
    .sw_long(sm_long)
);

integer bad = 0;
integer checks = 0;
integer cycles;
integer edges;
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
    sw_short = 0;
    sw_long = 0;
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
    blk_rot1 = 0;
    blk_rot2 = 0;
end
endtask

task do_reset;
begin
    clear_all;
    sm_switch_r = 0;
    sm_switch_en = 0;
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

task wait_done;
begin
    while(dut.en != 0)begin
        @(posedge Clk_74M);
        #1;
    end
end
endtask

task check_event;
input [8*40-1:0] name;
input integer exp_en;
begin
    chk(name, dut.en, exp_en);
    clear_all;
    wait_done;
end
endtask

task wait_st;
input [3:0] target;
begin
    cycles = 0;
    while((dut.st != target) && (cycles < 200000))begin
        @(posedge Clk_74M);
        #1;
        cycles = cycles + 1;
    end
    chk("到达音符状态", dut.st, target);
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
    sw_short = 1; one_pulse; check_event("sw_short -> 15", 15);
    sw_long = 1; one_pulse; check_event("sw_long -> 17", 17);
    blk_rot1 = 1; one_pulse; check_event("blk_rot1 -> 18", 18);
    blk_rot2 = 1; one_pulse; check_event("blk_rot2 -> 18", 18);
    over = 1; one_pulse; check_event("over -> 16", 16);

    $display("=== 2) 同拍优先级 ===");
    do_reset;
    over = 1; sw_long = 1; sw_short = 1; one_pulse;
    check_event("over > switch", 16);
    do_reset;
    sw_long = 1; sw_short = 1; one_pulse;
    check_event("switch_long > switch_short", 17);
    do_reset;
    blk1 = 1; blk_rot1 = 1; soft1 = 1; one_pulse;
    check_event("move_blocked > rotate_blocked", 4);
    do_reset;
    blk_rot1 = 1; soft1 = 1; one_pulse;
    check_event("rotate_blocked > soft", 18);
    do_reset;
    hard1 = 1; land1 = 1; hold1 = 1; one_pulse;
    check_event("hard > land > hold", 9);
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
    wait_done;
    chk("clear held no retrigger", dut.en, 0);
    clear = 0;
    @(posedge Clk_74M);
    #1;
    clear = 1;
    @(posedge Clk_74M);
    #1;
    chk("clear release then high retrigger", dut.en, 11);
    clear = 0;

    $display("=== 6) 控制音高与时序 ===");
    do_reset;
    over = 1; one_pulse;
    chk("over st0 note=G5", dut.note, 47360);
    chk("over st0 cnt=180ms", dut.cnt, 180);
    chk("over st_last=3", dut.st_last, 3);
    clear_all;
    wait_done;
    do_reset;
    menu_l = 1; one_pulse;
    chk("menu note=F5", dut.note, 53163);
    chk("menu cnt=18ms", dut.cnt, 18);
    clear_all;
    wait_done;
    do_reset;
    lft1 = 1; one_pulse;
    chk("move note=E5", dut.note, 56335);
    chk("move cnt=20ms", dut.cnt, 20);
    clear_all;
    wait_done;
    do_reset;
    rot1 = 1; one_pulse;
    chk("rotate note=G5", dut.note, 47360);
    chk("rotate cnt=20ms", dut.cnt, 20);
    clear_all;
    wait_done;

    do_reset; clear = 1; clr_n = 1; one_pulse;
    chk("clear1 st0 cnt=30ms", dut.cnt, 30); chk("clear1 st_last=1", dut.st_last, 1);
    clear_all; wait_done;
    do_reset; clear = 1; clr_n = 2; one_pulse;
    chk("clear2 st0 cnt=30ms", dut.cnt, 30); chk("clear2 st_last=2", dut.st_last, 2);
    clear_all; wait_done;
    do_reset; clear = 1; clr_n = 3; one_pulse;
    chk("clear3 st0 cnt=30ms", dut.cnt, 30); chk("clear3 st_last=3", dut.st_last, 3);
    clear_all; wait_done;
    do_reset; clear = 1; clr_n = 4; one_pulse;
    chk("clear4 st0 cnt=30ms", dut.cnt, 30); chk("clear4 st_last=4", dut.st_last, 4);
    clear_all; wait_done;

    $display("=== 7) 被挡双音与开关双音 ===");
    do_reset;
    blk1 = 1; one_pulse;
    chk("move blocked st0 note=E5", dut.note, 56335);
    chk("move blocked st0 cnt=30ms", dut.cnt, 30);
    wait_st(1);
    chk("move blocked rest note=0", dut.note, 0);
    chk("move blocked rest cnt=8ms", dut.cnt, 8);
    wait_st(2);
    chk("move blocked st2 note=C5", dut.note, 70985);
    chk("move blocked st2 cnt=45ms", dut.cnt, 45);
    clear_all;
    wait_done;

    do_reset;
    blk_rot1 = 1; one_pulse;
    chk("rotate blocked st0 note=D5", dut.note, 63245);
    chk("rotate blocked st0 cnt=30ms", dut.cnt, 30);
    wait_st(1);
    chk("rotate blocked rest note=0", dut.note, 0);
    chk("rotate blocked rest cnt=8ms", dut.cnt, 8);
    wait_st(2);
    chk("rotate blocked st2 note=B4", dut.note, 75188);
    chk("rotate blocked st2 cnt=45ms", dut.cnt, 45);
    clear_all;
    wait_done;

    do_reset;
    sw_short = 1; one_pulse;
    chk("switch short st0 note=E5", dut.note, 56335);
    chk("switch short st0 cnt=45ms", dut.cnt, 45);
    wait_st(1);
    chk("switch short st1 note=G5", dut.note, 47360);
    chk("switch short st1 cnt=60ms", dut.cnt, 60);
    clear_all;
    wait_done;

    do_reset;
    sw_long = 1; one_pulse;
    chk("switch long st0 note=G5", dut.note, 47360);
    chk("switch long st0 cnt=60ms", dut.cnt, 60);
    wait_st(1);
    chk("switch long st1 note=C5", dut.note, 70985);
    chk("switch long st1 cnt=90ms", dut.cnt, 90);
    clear_all;
    wait_done;

    $display("=== 8) 音符切换时长 ===");
    do_reset;
    hold1 = 1; one_pulse;
    cycles = 0;
    while((dut.en != 0) && (dut.st == 0))begin
        @(posedge Clk_74M);
        #1;
        cycles = cycles + 1;
    end
    chk("hold first note 35ms*32", (cycles >= 1120) && (cycles <= 1121), 1);
    clear_all;
    wait_done;

    $display("=== 9) 方波翻转次数 ===");
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
    chk("menu F5 18ms toggle count", edges, 11);

    $display("=== 10) 复位静音 ===");
    do_reset;
    chk("reset en=0", dut.en, 0);
    chk("reset buzz=0", buzz_else, 0);
    repeat(20) @(posedge Clk_74M);
    #1;
    chk("idle buzz=0", buzz_else, 0);

    $display("=== 11) switch 状态机长短按映射 ===");
    do_reset;
    sm_switch_en = 1;
    repeat(8) @(posedge Clk_74M);
    #1;
    sm_switch_en = 0;
    sm_switch_r = 1;
    @(posedge Clk_74M);
    #1;
    chk("state machine short pulse", sm_short, 1);
    chk("state machine short no long", sm_long, 0);
    sm_switch_r = 0;
    @(posedge Clk_74M);
    #1;

    do_reset;
    sm_switch_en = 1;
    cycles = 0;
    while((sm_long == 0) && (cycles < 200))begin
        @(posedge Clk_74M);
        #1;
        cycles = cycles + 1;
    end
    chk("state machine long pulse", sm_long, 1);
    chk("state machine long no short", sm_short, 0);
    sm_switch_en = 0;
    sm_switch_r = 1;
    @(posedge Clk_74M);
    #1;
    chk("long release no short", sm_short, 0);
    sm_switch_r = 0;

    $display("检查项: %0d", checks);
    if(bad == 0)
        $display("=== ALL PASS ===");
    else
        $display("=== FAILED %0d ===", bad);
    $finish;
end

endmodule