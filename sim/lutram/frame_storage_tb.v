`timescale 1ns/1ps
// Match the clocked shape ROM interface used by the hardware.
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
    wire [23:0]rgb;
    always #6.734 clk=~clk;
    frame dut(
        .Clk_74M(clk), .Reset_n(rst), .hcounter(11'd0), .vcounter(11'd0),
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
        // Preview geometry is outside this storage test; use the display regression's zero-offset fixture.
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
            check("P1 color",dut.state_color[3*20+5+n]==3'd1);
            check("P1 owner",dut.state_owner[3*20+5+n]==1'b0);
            check("P2 occupied",dut.state[15*20+8+n]);
            check("P2 color",dut.state_color[15*20+8+n]==3'd4);
            check("P2 owner",dut.state_owner[15*20+8+n]==1'b1);
        end
        release dut.Playfield_inst.counter_c;release dut.Playfield_inst.counter_r;
        release dut.Playfield_inst.counter_c2;release dut.Playfield_inst.counter_r2;
        release dut.Playfield_inst.type;release dut.Playfield_inst.type2;
        release dut.Playfield_inst.rot;release dut.Playfield_inst.rot2;
        dut.state_color[20*20+11]=3'd6;
        dut.state_owner[20*20+11]=1'b1;
        write_row(11,(24'd1<<15)|(24'd1<<20));
        write_row(12,24'hFFFFFF);
        repeat(150)@(negedge clk);
        check("P1 moved occupancy",dut.state[3*20+6]);
        check("P1 moved color",dut.state_color[3*20+6]==3'd1);
        check("P1 moved owner",dut.state_owner[3*20+6]==1'b0);
        check("P2 moved occupancy",dut.state[15*20+12]);
        check("P2 moved color",dut.state_color[15*20+12]==3'd4);
        check("P2 moved owner",dut.state_owner[15*20+12]==1'b1);
        check("marker moved occupancy",dut.state[20*20+12]);
        check("marker moved color",dut.state_color[20*20+12]==3'd6);
        check("marker moved owner",dut.state_owner[20*20+12]==1'b1);
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
