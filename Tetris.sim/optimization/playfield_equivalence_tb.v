// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module Tetromino(input clka, input [4:0]addra, output reg [31:0]douta);
    reg [31:0]memory[0:31];
    initial $readmemh("shape_rom.hex",memory);
    always@(posedge clka) douta <= memory[addra];
endmodule
module weiyibiao(input clka, input [4:0]addra, output reg [7:0]douta);
    reg [7:0]memory[0:31];
    initial $readmemh("offset_rom.hex",memory);
    always@(posedge clka) douta <= memory[addra];
endmodule
module playfield_equivalence_tb;
    reg clk=0, rst=0, duo=1;
    reg [10:0]hc=0,vc=0;
    reg [4:0]c1=8,r1=0,c2=16,r2=0;
    reg [2:0]t1=0,t2=0;
    reg [1:0]rot1=0,rot2=0;
    reg pulse1=0,pulse2=0;
    reg [4:0]write_addr;
    reg [23:0]write_data;
    wire [479:0]board,reference_board;
    integer failures=0,checks=0,n,k,seed=73517;
    always #6.734 clk=~clk;
    Playfield dut(.ui_tick(1'b1),
  .init_load(1'b0),.initial_mask(480'd0),.initial_total(7'd0),.mission_hold(1'b0), .story_speed(3'd0),
        .Clk_74M(clk),.Reset_n(rst),.hcounter(hc),.vcounter(vc),
        .Idle(1'b0),.Playing(1'b1),.Stop(1'b0),.Finalize(1'b0),.duo(duo),
        .left_p_flag(1'b0),.right_p_flag(1'b0),.drop_r_flag(1'b0),.drop_en(1'b0),
        .rotate_p_flag(1'b0),.switch_r_flag(1'b0),.hold_p_flag(1'b0),
        .left_p_flag2(1'b0),.right_p_flag2(1'b0),.drop_r_flag2(1'b0),.drop_en2(1'b0),
        .rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),.hint_enable(1'b0),
        .score(20'd0),.time_sec(14'd0),.state(board)
    );
    Playfield_reference reference_dut(
        .Clk_74M(clk),.Reset_n(rst),.hcounter(hc),.vcounter(vc),
        .Idle(1'b0),.Playing(1'b1),.Stop(1'b0),.Finalize(1'b0),.duo(duo),
        .left_p_flag(1'b0),.right_p_flag(1'b0),.drop_r_flag(1'b0),.drop_en(1'b0),
        .rotate_p_flag(1'b0),.switch_r_flag(1'b0),.hold_p_flag(1'b0),
        .left_p_flag2(1'b0),.right_p_flag2(1'b0),.drop_r_flag2(1'b0),.drop_en2(1'b0),
        .rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),.hint_enable(1'b0),
        .score(20'd0),.time_sec(14'd0),.state(reference_board)
    );
    wire [17:0]collision = {dut.land,dut.land2,dut.touch_top,dut.touch_top2,
        dut.boundary_collision_left,dut.boundary_collision_right,
        dut.boundary_collision_left2,dut.boundary_collision_right2,
        dut.other_down_hold,dut.other_down_hold2,
        dut.ghost_blocked1,dut.ghost_blocked2,dut.Piece,dut.Piece2,
        dut.ghost,dut.ghost2,dut.ghost_blk_other1,dut.ghost_blk_other2};
    wire [17:0]reference_collision = {reference_dut.land,reference_dut.land2,
        reference_dut.touch_top,reference_dut.touch_top2,
        reference_dut.boundary_collision_left,reference_dut.boundary_collision_right,
        reference_dut.boundary_collision_left2,reference_dut.boundary_collision_right2,
        reference_dut.other_down_hold,reference_dut.other_down_hold2,
        reference_dut.ghost_blocked1,reference_dut.ghost_blocked2,
        reference_dut.Piece,reference_dut.Piece2,reference_dut.ghost,reference_dut.ghost2,
        reference_dut.ghost_blk_other1,reference_dut.ghost_blk_other2};
    // 旋转属于本轮有意修复的行为：不用旧版缺少互撞的结果作真值。
    // 独立整数模型同时覆盖边界、负行、落定格和对方四格。
    function expected_rotation_block;
        input [4:0] ac,ar,bc,br;
        input [3:0] dc,dr;
        input [31:0] rotated,peer;
        input [479:0] cells;
        input two;
        integer i,j,c,r,pc,pr,sc,sr;
        begin
            expected_rotation_block=0;
            for(i=0;i<4;i=i+1)begin
                sc=rotated[i*8+4 +:4];if(sc>=8)sc=sc-16;
                sr=rotated[i*8 +:4];if(sr>=8)sr=sr-16;
                c=(ac+(dc>=8?dc-16:dc)+sc)&63;
                r=(ar+(dr>=8?dr-16:dr)+sr)&63;
                if(c>=(two?24:20) || (r>=20 && r<32))expected_rotation_block=1;
                if(c<(two?24:20) && r<20 && cells[c*20+r])expected_rotation_block=1;
                for(j=0;j<4;j=j+1)begin
                    sc=peer[j*8+4 +:4];if(sc>=8)sc=sc-16;
                    sr=peer[j*8 +:4];if(sr>=8)sr=sr-16;
                    pc=(bc+sc)&63;pr=(br+sr)&63;
                    if(two && pc==c && pr==r)expected_rotation_block=1;
                end
            end
        end
    endfunction
    task check;
        input condition;
        input [255:0]name;
        begin
            checks=checks+1;
            if(condition !== 1'b1)begin
                failures=failures+1;
                if(failures<20)$display("FAIL %0s at %0t",name,$time);
            end
        end
    endtask
    always@(negedge clk)if(rst)begin
        check(board===reference_board,"canonical board");
        check(collision===reference_collision,"unchanged collision and rendering");
        check(dut.rot_block===expected_rotation_block(c1,r1,c2,r2,dut.ddc,dut.ddr,dut.Tetromino_dout1,dut.Tetromino_dout2,board,duo),"P1 independent rotation model");
        check(dut.rot_block2===expected_rotation_block(c2,r2,c1,r1,dut.ddc2,dut.ddr2,dut.Tetromino_dout3,dut.Tetromino_dout,board,duo),"P2 independent rotation model");
        check({dut.row_we,dut.row_addr}==={reference_dut.row_we,reference_dut.row_addr},"write address and enable");
        if(dut.row_we)check(dut.row_data===reference_dut.row_data,"row write data");
    end
    task write_row;
        input [4:0]address;
        input [23:0]data;
        begin
            @(negedge clk);#1;
            write_addr=address;write_data=data;
            force dut.row_we=1'b1;force reference_dut.row_we=1'b1;
            force dut.row_addr=write_addr;force reference_dut.row_addr=write_addr;
            force dut.row_data=write_data;force reference_dut.row_data=write_data;
            @(negedge clk);#1;
            release dut.row_we;release reference_dut.row_we;
            release dut.row_addr;release reference_dut.row_addr;
            release dut.row_data;release reference_dut.row_data;
        end
    endtask
    initial begin
        force dut.counter_c=c1;force reference_dut.counter_c=c1;
        force dut.counter_r=r1;force reference_dut.counter_r=r1;
        force dut.counter_c2=c2;force reference_dut.counter_c2=c2;
        force dut.counter_r2=r2;force reference_dut.counter_r2=r2;
        force dut.type=t1;force reference_dut.type=t1;
        force dut.type2=t2;force reference_dut.type2=t2;
        force dut.rot=rot1;force reference_dut.rot=rot1;
        force dut.rot2=rot2;force reference_dut.rot2=rot2;
        force dut.land_pulse=pulse1;force reference_dut.land_pulse=pulse1;
        force dut.land_pulse2=pulse2;force reference_dut.land_pulse2=pulse2;
        #100;rst=1;
        repeat(25)@(negedge clk);
        for(n=0;n<20;n=n+1)write_row(n,$random(seed)&24'h7FFFFF);
        // 覆盖实际 ROM 形状、负偏移、场地边界以及单双人模式。
        for(n=0;n<3000;n=n+1)begin
            @(negedge clk);#1;
            c1=$random(seed);r1=$random(seed);
            c2=$random(seed);r2=$random(seed);
            t1=($random(seed)&32'h7FFFFFFF)%7;
            t2=($random(seed)&32'h7FFFFFFF)%7;
            rot1=$random(seed);rot2=$random(seed);duo=$random(seed);
            hc=321+(($random(seed)&32'h7FFFFFFF)%800);
            vc=81+(($random(seed)&32'h7FFFFFFF)%650);
            repeat(4)@(negedge clk);
        end
        duo=1;
        // 随机生成同时和错拍的落锁提交, 结果必须与旧版写口一致。
        for(n=0;n<128;n=n+1)begin
            @(negedge clk);#1;
            c1=3+(($random(seed)&32'h7FFFFFFF)%15);
            c2=3+(($random(seed)&32'h7FFFFFFF)%15);
            r1=4+(($random(seed)&32'h7FFFFFFF)%12);
            r2=4+(($random(seed)&32'h7FFFFFFF)%12);
            repeat(4)@(negedge clk);
            #1;pulse1=1;pulse2=n[0];
            @(negedge clk);#1;pulse1=0;pulse2=0;
            repeat(15)@(negedge clk);
        end
        for(k=0;k<20;k=k+1)write_row(k,24'd0);
        for(n=0;n<8;n=n+1)begin
            write_row(3+n,24'h000005);
            write_row(4+n,24'hFFFFFF);
            repeat(160)@(negedge clk);
        end
        $display("Equivalence checks: %0d",checks);
        if(failures==0)$display("=== ALL PASS: PLAYFIELD EQUIVALENCE ===");
        else $display("=== FAILED %0d ===",failures);
        $finish;
    end
    initial begin
        #1000000;
        $display("=== FAILED: equivalence watchdog ===");
        $finish;
    end
endmodule
