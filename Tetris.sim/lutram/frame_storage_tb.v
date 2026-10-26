// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
// 形状 ROM 使用与硬件一致的时钟接口。
module Tetromino(input clka, input [4:0]addra, output reg [31:0]douta);
    always@(posedge clka) douta <= addra[1:0] == 0 ? 32'h00010203 : 32'h0F001F10;
endmodule
module weiyibiao(input clka, input [4:0]addra, output reg [7:0]douta);
    always@(posedge clka) douta <= 8'd0;
endmodule
module number(input clka, input ena, input [9:0]addra, output [19:0]douta);
    assign douta=20'd0;
endmodule
module letter(input clka, input ena, input [10:0]addra, output [19:0]douta);
    assign douta=20'd0;
endmodule
module frame_storage_tb;
    reg clk=0, rst=0;
    integer failures=0, n;
    reg [4:0]test_row;
    reg [23:0]test_data;
    reg [4:0]meta_col,meta_row;
    reg [3:0]meta_value,read_value;
    wire [23:0]rgb;
    always #6.734 clk=~clk;
    frame dut(
        .campaign(1'b1),.ship_select(1'b0),.level_id(2'd2),.result_option(2'd0),.Clk_74M(clk), .Reset_n(rst), .hcounter(11'd0), .vcounter(11'd0),
        .left_p_flag(1'b0), .right_p_flag(1'b0), .drop_r_flag(1'b0), .drop_en(1'b0),
        .rotate_p_flag(1'b0), .switch_r_flag(1'b0), .hold_p_flag(1'b0),
        .Idle(1'b0), .Playing(1'b1), .Stop(1'b0), .Finalize(1'b0),
        .choose(1'b0), .choose_cnt(4'd0), .duo(1'b1),
        .left_p_flag2(1'b0), .right_p_flag2(1'b0), .drop_r_flag2(1'b0),
        .drop_en2(1'b0), .rotate_p_flag2(1'b0), .hold_p_flag2(1'b0),
        .hint_show(1'b0), .rgb(rgb)
    );
    defparam dut.Playfield_inst.CLEAR_STEP=4;
    task check;
        input [255:0]name;
        input condition;
        begin
            if(condition !== 1'b1)begin
                failures=failures+1;
                $display("FAIL %0s",name);
            end
            else $display("PASS %0s",name);
        end
    endtask
    task write_metadata;
        input integer index;
        input [3:0]value;
        begin
            @(negedge clk);
            meta_col=index/20;meta_row=index%20;meta_value=value;
            force dut.meta_is_lock=1'b1;
            force dut.meta_lock_col=meta_col;
            force dut.meta_write_addr=meta_row;
            force dut.meta_lock_data=meta_value;
            @(posedge clk);@(negedge clk);
            release dut.meta_is_lock;release dut.meta_lock_col;
            release dut.meta_write_addr;release dut.meta_lock_data;
        end
    endtask
    task read_metadata;
        input integer index;
        begin
            meta_col=index/20;meta_row=index%20;
            force dut.C_num=meta_col;force dut.R_num=meta_row;
            #1;read_value=dut.meta_pixel;
            release dut.C_num;release dut.R_num;
        end
    endtask
    task write_row;
        input [4:0]address;
        input [23:0]data;
        begin
            @(negedge clk);
            test_row=address;test_data=data;
            force dut.Playfield_inst.row_addr=test_row;
            force dut.Playfield_inst.row_data=test_data;
            force dut.Playfield_inst.row_we=1'b1;
            @(posedge clk);@(negedge clk);
            force dut.Playfield_inst.row_we=1'b0;
            #1;
            release dut.Playfield_inst.row_we;
            release dut.Playfield_inst.row_addr;
            release dut.Playfield_inst.row_data;
        end
    endtask
    initial begin
        // 本测试聚焦存储, 预览几何使用显示回归中的零偏移测试模型。
        force dut.Next_piece_inst.Tetromino_dout=32'd0;
        force dut.Next_piece_inst.Tetromino_dout2=32'd0;
        $display("FRAME storage test starting");
        #100;rst=1;
        $display("FRAME reset released at %0t",$time);
        repeat(25)@(negedge clk);
        $display("FRAME initialization completed at %0t",$time);
        force dut.Playfield_inst.counter_c=5'd3;
        force dut.Playfield_inst.counter_r=5'd5;
        force dut.Playfield_inst.counter_c2=5'd15;
        force dut.Playfield_inst.counter_r2=5'd8;
        force dut.Playfield_inst.type=3'd1;
        force dut.Playfield_inst.type2=3'd4;
        force dut.Playfield_inst.rot=2'd0;
        force dut.Playfield_inst.rot2=2'd0;
        force dut.Playfield_inst.land_pulse=1'b1;
        force dut.Playfield_inst.land_pulse2=1'b1;
        @(negedge clk);
        release dut.Playfield_inst.land_pulse;
        release dut.Playfield_inst.land_pulse2;
        $display("FRAME lock requested at %0t",$time);
        repeat(14)@(negedge clk);
        for(n=0;n<4;n=n+1)begin
            check("P1 occupied",dut.state[3*20+5+n]);
            read_metadata(3*20+5+n);
            check("P1 color",read_value[2:0]==3'd1);
            check("P1 owner",read_value[3]==1'b0);
            check("P2 occupied",dut.state[15*20+8+n]);
            read_metadata(15*20+8+n);
            check("P2 color",read_value[2:0]==3'd4);
            check("P2 owner",read_value[3]==1'b1);
        end
        release dut.Playfield_inst.counter_c;release dut.Playfield_inst.counter_r;
        release dut.Playfield_inst.counter_c2;release dut.Playfield_inst.counter_r2;
        release dut.Playfield_inst.type;release dut.Playfield_inst.type2;
        release dut.Playfield_inst.rot;release dut.Playfield_inst.rot2;
        write_metadata(20*20+11,4'hE);
        write_row(11,(24'd1<<15)|(24'd1<<20));
        write_row(12,24'hFFFFFF);
        repeat(150)@(negedge clk);
        check("P1 moved occupancy",dut.state[3*20+6]);
        read_metadata(3*20+6);
        check("P1 moved color",read_value[2:0]==3'd1);
        check("P1 moved owner",read_value[3]==1'b0);
        check("P2 moved occupancy",dut.state[15*20+12]);
        read_metadata(15*20+12);
        check("P2 moved color",read_value[2:0]==3'd4);
        check("P2 moved owner",read_value[3]==1'b1);
        check("marker moved occupancy",dut.state[20*20+12]);
        read_metadata(20*20+12);
        check("marker moved color",read_value[2:0]==3'd6);
        check("marker moved owner",read_value[3]==1'b1);
        check("compaction completed",!dut.clear);
        if(failures==0)$display("=== ALL PASS: LUTRAM FRAME ===");
        else $display("=== FAILED %0d ===",failures);
        $finish;
    end
    initial begin
        #1000000;
        $display("=== FAILED: frame watchdog ===");
        $finish;
    end
endmodule
