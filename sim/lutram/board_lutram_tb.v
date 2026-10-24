// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module Tetromino(input clka, input [4:0]addra, output [31:0]douta);
    // 使用四个不同的行地址, 覆盖各个并行读口。
    assign douta = addra[1:0] == 0 ? 32'h00010203 : 32'h0F001F10;
endmodule
module weiyibiao(input clka, input [4:0]addra, output [7:0]douta);
    assign douta = 8'd0;
endmodule

module board_lutram_tb;
    reg clk=0, rst=0, idle=0, playing=0, finalize=0, switch_key=0;
    reg duo=1;
    wire [479:0]board;
    integer failures=0, comparisons=0, writes1=0, writes2=0;
    integer n, c, r;
    reg [4:0]test_addr=0;
    reg [23:0]test_data;
    always #6.734 clk=~clk;
    Playfield #(.MCNT_LAND(20_000_000), .CLEAR_STEP(4)) dut(
        .Clk_74M(clk), .Reset_n(rst), .hcounter(11'd0), .vcounter(11'd0),
        .left_p_flag(1'b0), .right_p_flag(1'b0), .drop_r_flag(1'b0), .drop_en(1'b0),
        .rotate_p_flag(1'b0), .switch_r_flag(switch_key), .Idle(idle),
        .Playing(playing), .hint_enable(1'b0), .Stop(1'b0), .Finalize(finalize),
        .hold_p_flag(1'b0), .score(20'd0), .time_sec(14'd0), .duo(duo),
        .left_p_flag2(1'b0), .right_p_flag2(1'b0), .drop_r_flag2(1'b0),
        .drop_en2(1'b0), .rotate_p_flag2(1'b0), .hold_p_flag2(1'b0), .state(board)
    );

    task check;
        input [255:0]name;
        input condition;
        begin
            if(condition !== 1'b1)begin
                $display("FAIL %0s",name);
                failures=failures+1;
            end
            else $display("PASS %0s",name);
        end
    endtask

    function [23:0]expected_row;
        input [4:0]address;
        integer column;
        begin
            expected_row=24'd0;
            if(address<20)
                for(column=0;column<24;column=column+1)
                    expected_row[column]=board[column*20+address];
        end
    endfunction

    // 检查可观测输出, 同一测试同时适用于行为模型和 UNISIM 存储原语。
    genvar lane;
    generate for(lane=0;lane<4;lane=lane+1)begin : monitor
        always@(negedge clk)begin
            if(rst && !dut.board_init)begin
                if(dut.read_current1[lane] !== expected_row(dut.board_reads[lane].current1.read_addr) ||
                   dut.read_below1[lane] !== expected_row(dut.board_reads[lane].below1.read_addr) ||
                   dut.read_current2[lane] !== expected_row(dut.board_reads[lane].current2.read_addr) ||
                   dut.read_below2[lane] !== expected_row(dut.board_reads[lane].below2.read_addr) ||
                   dut.read_ghost1[lane] !== expected_row(dut.board_reads[lane].ghost1.read_addr) ||
                   dut.read_ghost2[lane] !== expected_row(dut.board_reads[lane].ghost2.read_addr) ||
                   dut.read_rotate1[lane] !== expected_row(dut.board_reads[lane].rotate1.read_addr) ||
                   dut.read_rotate2[lane] !== expected_row(dut.board_reads[lane].rotate2.read_addr))begin
                    failures=failures+1;
                    $display("FAIL replica lane %0d at %0t",lane,$time);
                end
                comparisons=comparisons+8;
            end
        end
    end endgenerate
    always@(posedge clk)begin
        if(dut.lock_commit1)writes1=writes1+1;
        if(dut.lock_commit2)writes2=writes2+1;
    end

    task write_row;
        input [4:0]address;
        input [23:0]data;
        begin
            @(negedge clk); #1;
            test_addr=address;
            test_data=data;
            force dut.row_we=1'b1;
            force dut.row_addr=test_addr;
            force dut.row_data=test_data;
            @(posedge clk); @(negedge clk); #1;
            force dut.row_we=1'b0;
            #1;
            release dut.row_we;
            release dut.row_addr;
            release dut.row_data;
        end
    endtask

    task reset_board;
        begin
            @(negedge clk);rst=0;
            repeat(2)@(negedge clk);
            rst=1;
            repeat(25)@(negedge clk);
            check("reset cleared every cell",board===480'd0);
            check("board initialized",!dut.board_init);
        end
    endtask

    initial begin
        #100; reset_board;
        // 随机行数据配合四个独立变化的读地址, 检查读写一致性。
        force dut.counter_r=test_addr;
        force dut.counter_r2=test_addr;
        force dut.ghost_scan_r=test_addr;
        force dut.ghost_scan_r2=test_addr;
        for(n=0;n<200;n=n+1)
            write_row(n%20,$random & (n[0] ? 24'hFFFFFE : 24'h7FFFFF));
        release dut.counter_r; release dut.counter_r2;
        release dut.ghost_scan_r; release dut.ghost_scan_r2;
        reset_board;

        write_row(5,24'h000001);
        write_row(6,24'h000002);
        write_row(7,24'h000004);
        write_row(8,24'h000008);
        @(negedge clk);
        force dut.type=3'd0; force dut.rot=2'd0;
        force dut.counter_r=5'd5;
        #1;
        check("lane 0 reads row 8",dut.read_current1[0]==24'h000008);
        check("lane 1 reads row 7",dut.read_current1[1]==24'h000004);
        check("lane 2 reads row 6",dut.read_current1[2]==24'h000002);
        check("lane 3 reads row 5",dut.read_current1[3]==24'h000001);
        release dut.counter_r; release dut.type; release dut.rot;
        reset_board;

        // 两名玩家同时开始落锁, 每个方块的四个格子位于不同的行。
        @(negedge clk);
        force dut.counter_c=5'd3; force dut.counter_r=5'd5;
        force dut.counter_c2=5'd15; force dut.counter_r2=5'd8;
        force dut.type=3'd0; force dut.rot=2'd0;
        force dut.type2=3'd0; force dut.rot2=2'd0;
        force dut.land_pulse=1'b1; force dut.land_pulse2=1'b1;
        @(negedge clk);
        release dut.land_pulse; release dut.land_pulse2;
        repeat(14)@(negedge clk);
        check("P1 commits all four cells",writes1==4);
        check("P2 commits all four cells",writes2==4);
        for(n=0;n<4;n=n+1)begin
            check("P1 locked cell",board[3*20+5+n]);
            check("P2 locked cell",board[15*20+8+n]);
        end
        check("P2 queue drained",!dut.lock_pending2 && !dut.lock_we2);
        release dut.counter_c; release dut.counter_r;
        release dut.counter_c2; release dut.counter_r2;
        release dut.type; release dut.rot; release dut.type2; release dut.rot2;

        // P2 已写入部分格子时, P1 可抢占公共写口。
        reset_board;
        writes1=0; writes2=0;
        force dut.counter_c=5'd3; force dut.counter_r=5'd5;
        force dut.counter_c2=5'd3; force dut.counter_r2=5'd11;
        force dut.type=3'd0; force dut.rot=2'd0;
        force dut.type2=3'd0; force dut.rot2=2'd0;
        force dut.land_pulse2=1'b1;
        @(negedge clk);release dut.land_pulse2;
        repeat(2)@(negedge clk);
        force dut.land_pulse=1'b1;
        @(negedge clk);release dut.land_pulse;
        repeat(14)@(negedge clk);
        check("preempting P1 commits four cells",writes1==4);
        check("preempted P2 commits four cells",writes2==4);
        for(n=0;n<4;n=n+1)begin
            check("preempting P1 cell",board[3*20+5+n]);
            check("resumed P2 cell",board[3*20+11+n]);
        end
        release dut.counter_c; release dut.counter_r;
        release dut.counter_c2; release dut.counter_r2;
        release dut.type; release dut.rot; release dut.type2; release dut.rot2;

        // 通过实际重开输入清场, 不直接强制修改棋盘镜像。
        @(negedge clk);finalize=1;switch_key=1;
        @(negedge clk);switch_key=0;
        repeat(25)@(negedge clk);
        check("restart cleared all rows",board===480'd0);
        finalize=0;

        // 满行消除后自下向上逐行搬移, 检查每行只搬移一次且不丢格子。
        write_row(5,24'h000008);
        write_row(6,24'hFFFFFF);
        force dut.clear_t=1'b0;
        repeat(30)@(negedge clk);
        release dut.clear_t;
        check("full row removed",expected_row(6)==24'h000008);
        check("old row moved",expected_row(5)==24'd0);
        check("row zero cleared",expected_row(0)==24'd0);
        check("move finished",!dut.move_active);

        write_row(9,24'h000020);
        write_row(10,24'hFFFFFF);
        write_row(11,24'hFFFFFF);
        repeat(150)@(negedge clk);
        check("two-line compaction",expected_row(11)==24'h000020);
        check("two-line upper row cleared",expected_row(9)==24'd0);
        check("clear pipeline completed",!dut.clear_time);

        // 即使 Idle 只持续一个时钟周期, 清场初始化也必须完成。
        @(negedge clk);idle=1;
        @(negedge clk);idle=0;
        repeat(25)@(negedge clk);
        check("one-cycle idle clears board",board===480'd0);
        $display("Replica comparisons: %0d",comparisons);
        if(failures==0)$display("=== ALL PASS: LUTRAM ===");
        else $display("=== FAILED %0d ===",failures);
        $finish;
    end
    initial begin
        #1000000;
        $display("=== FAILED: watchdog ===");
        $finish;
    end
endmodule
