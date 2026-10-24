// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module Tetromino(input clka,input [4:0]addra,output reg [31:0]douta);
    always@(posedge clka)douta<=32'h00010203;
endmodule
module weiyibiao(input clka,input [4:0]addra,output [7:0]douta);
    assign douta=8'd0;
endmodule
module number(input clka,input ena,input [9:0]addra,output [19:0]douta);
    assign douta=20'd0;
endmodule
module letter(input clka,input ena,input [10:0]addra,output [19:0]douta);
    assign douta=20'd0;
endmodule
module metadata_tb;
    reg clk=0,rst=0,manual=1,manual_we=0;
    reg [4:0]write_col=0,write_row=0,read_col=0,read_row=0,move_target=1;
    reg [3:0]write_value=0;
    reg [3:0]expected[0:479];
    integer n,c,r,failures=0,checks=0,seed=1539;
    always #6.734 clk=~clk;
    frame dut(
        .Clk_74M(clk),.Reset_n(rst),.hcounter(11'd0),.vcounter(11'd0),
        .Idle(1'b0),.Playing(1'b1),.Stop(1'b0),.Finalize(1'b0),.duo(1'b1),
        .left_p_flag(1'b0),.right_p_flag(1'b0),.drop_r_flag(1'b0),.drop_en(1'b0),
        .rotate_p_flag(1'b0),.switch_r_flag(1'b0),.hold_p_flag(1'b0),
        .left_p_flag2(1'b0),.right_p_flag2(1'b0),.drop_r_flag2(1'b0),.drop_en2(1'b0),
        .rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),.hint_show(1'b0),
        .choose(1'b0),.choose_cnt(4'd0)
    );
    task check;
        input condition;
        input [255:0]name;
        begin
            checks=checks+1;
            if(condition !== 1'b1)begin
                failures=failures+1;
                if(failures<20)$display("FAIL %0s col=%0d row=%0d",name,read_col,read_row);
            end
        end
    endtask
    task scan_board;
        integer x,y;
        begin
            for(x=0;x<24;x=x+1)
                for(y=0;y<20;y=y+1)begin
                    read_col=x;read_row=y;
                    #1;check(dut.meta_pixel===expected[x*20+y],"display port");
                end
        end
    endtask
    // 参考模型按原有画面存储接口更新颜色和归属。
    always@(posedge clk)if(rst && !manual)begin
        if(dut.lock_commit1)begin
            $display("COMMIT P1 c=%0d r=%0d type=%0d",dut.cc_t[dut.lock_idx],dut.rr_t[dut.lock_idx],dut.type_d);
            expected[dut.cc_t[dut.lock_idx]*20+dut.rr_t[dut.lock_idx]]={1'b0,dut.type_d};
        end
        else if(dut.lock_commit2)
            expected[dut.cc_t2[dut.lock_idx2]*20+dut.rr_t2[dut.lock_idx2]]={1'b1,dut.type_d2};
        else if(dut.move_we && dut.move_row!=0)
            for(c=0;c<24;c=c+1)
                expected[c*20+dut.move_row]=expected[c*20+dut.move_row-1];
    end
    initial begin
        for(n=0;n<480;n=n+1)expected[n]=0;
        force dut.Next_piece_inst.Tetromino_dout=32'd0;
        force dut.Next_piece_inst.Tetromino_dout2=32'd0;
        force dut.C_num=read_col;force dut.R_num=read_row;
        force dut.meta_is_lock=manual_we;
        force dut.meta_lock_col=write_col;
        force dut.meta_write_addr=write_row;
        force dut.meta_lock_data=write_value;
        force dut.move_we=1'b0;
        #100;rst=1;
        repeat(30)@(negedge clk);
        for(n=0;n<1000;n=n+1)begin
            @(negedge clk);#1;
            write_col=($random(seed)&32'h7FFFFFFF)%24;
            write_row=($random(seed)&32'h7FFFFFFF)%20;
            write_value=$random(seed);manual_we=1;
            @(posedge clk);#1;
            expected[write_col*20+write_row]=write_value;
            @(negedge clk);#1;manual_we=0;
            if(n%50==0)scan_board;
        end
        scan_board;
        release dut.meta_write_addr;
        force dut.move_row=move_target;
        for(n=0;n<40;n=n+1)begin
            @(negedge clk);#1;
            move_target=1+(($random(seed)&32'h7FFFFFFF)%19);
            force dut.move_we=1'b1;
            @(posedge clk);#1;
            for(r=0;r<24;r=r+1)expected[r*20+move_target]=expected[r*20+move_target-1];
            @(negedge clk);#1;force dut.move_we=1'b0;
            scan_board;
        end
        release dut.meta_is_lock;release dut.meta_lock_col;
        release dut.meta_lock_data;release dut.move_we;release dut.move_row;
        manual=0;
        // 强制搬移事务结束后, 等待棋盘控制器完成剩余操作。
        repeat(30)@(negedge clk);
        force dut.Playfield_inst.counter_c=5'd3;
        force dut.Playfield_inst.counter_r=5'd5;
        force dut.Playfield_inst.counter_c2=5'd15;
        force dut.Playfield_inst.counter_r2=5'd8;
        force dut.Playfield_inst.type=3'd1;force dut.Playfield_inst.type2=3'd4;
        force dut.Playfield_inst.rot=2'd0;force dut.Playfield_inst.rot2=2'd0;
        repeat(3)@(negedge clk);
        #1;force dut.Playfield_inst.land_pulse=1'b1;
        force dut.Playfield_inst.land_pulse2=1'b1;
        @(negedge clk);#1;
        release dut.Playfield_inst.land_pulse;release dut.Playfield_inst.land_pulse2;
        repeat(15)@(negedge clk);
        scan_board;
        for(n=0;n<4;n=n+1)begin
            check(expected[3*20+5+n]==4'h1,"P1 original commit contract");
            check(expected[15*20+8+n]==4'hC,"P2 original commit contract");
        end
        $display("Metadata checks: %0d",checks);
        if(failures==0)$display("=== ALL PASS: METADATA ===");
        else $display("=== FAILED %0d ===",failures);
        $finish;
    end
    initial begin
        #1000000;
        $display("=== FAILED: metadata watchdog ===");
        $finish;
    end
endmodule
