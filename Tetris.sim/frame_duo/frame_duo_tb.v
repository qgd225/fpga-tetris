// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps

//============================================================
// 测试台：frame_duo_tb
// 测试目标：frame 显示回归：方块/HUD/菜单/特效/结算页/智能提示和局部压暗。
//============================================================
//===== frame 级双人显示回归: P2 运动块/落格/下一块/Hold/新 HUD 布局/菜单屏 =====
module Tetromino(input clka, input [4:0] addra, output [31:0] douta);
  assign douta = 32'h0000_0000;  // 桩: 偏移全 0 -> 预览块占 (列1,行3)
endmodule
module weiyibiao(input clka, input [4:0] addra, output [7:0] douta);
  assign douta = 8'h00;
endmodule
module number(input clka, input ena, input [9:0] addra, output [19:0] douta);
  assign douta = 20'hF_FFFF;  // 桩: 全亮, 便于断言数字区域颜色
endmodule
module letter(input clka, input ena, input [10:0] addra, output [19:0] douta);
  assign douta = 20'hF_FFFF;  // 桩: 全亮, 便于断言标签/菜单文字颜色
endmodule

module frame_duo_tb;
    reg Clk=0,Rst=0;
    reg [10:0] hc=0,vc=0;
    reg duo=0,choose=0,Idle=1,Playing=0,Stop=0,Finalize=0,hint_show=0,sw=0;
    wire [23:0] rgb;
    wire [2:0] speed;
    wire [19:0] score;wire [15:0] lines;wire [13:0] time_sec;
    reg [7:0] font_reference[0:2047];
    integer errors=0,checks=0,i,j,c,r;
    reg [4:0] test_row,meta_col,meta_row;
    reg [23:0] test_data;
    reg [3:0] meta_value;
    reg [1:0] phase_value;
    reg [3:0] locked_value;
    reg [10:0] drift_snapshot;
    always #6.734 Clk=~Clk;
    frame #(.EFF_TICK(21'd8),.SUCCESS_TICKS(4)) dut(
        .Clk_74M(Clk),.Reset_n(Rst),.hcounter(hc),.vcounter(vc),.video_de(1'b1),
        .left_p_flag(1'b0),.right_p_flag(1'b0),.drop_r_flag(1'b0),.drop_en(1'b0),.rotate_p_flag(1'b0),
        .switch_r_flag(sw),.hold_p_flag(1'b0),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
        .choose(choose),.choose_cnt(duo?4'd1:4'd0),.duo(duo),
        .left_p_flag2(1'b0),.right_p_flag2(1'b0),.drop_r_flag2(1'b0),.drop_en2(1'b0),.rotate_p_flag2(1'b0),
        .hold_p_flag2(1'b0),.hint_show(hint_show),.rgb(rgb),.score(score),.lines(lines),.time_sec(time_sec),.speed_level(speed));
    task check;
        input condition;input [511:0] name;
        begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;$display("FAIL %0s rgb=%h hc=%0d vc=%0d",name,rgb,hc,vc);end end
    endtask
    task look;
        input integer x,y;
        begin
            // 固定坐标探针补偿四拍行内前取；逐时钟相位另由 VGA 联合台验证。
            @(negedge Clk);hc=x-4;vc=y;repeat(6)@(negedge Clk);
        end
    endtask
    task frame_edge;
        begin @(negedge Clk);hc=0;vc=0;repeat(3)@(negedge Clk);end
    endtask
    task glyph;
        input integer bx,by,char_id,scale;input [23:0] color;
        integer gy,gx,found;
        begin
            found=0;
            for(gy=0;gy<12;gy=gy+1)for(gx=0;gx<8;gx=gx+1)
                if(!found && font_reference[char_id*16+gy][7-gx])begin
                    look(bx+gx*scale,by+gy*scale);check(rgb===color,"real glyph pixel");found=1;
                end
            check(found==1,"glyph source is nonempty");
        end
    endtask
    task write_row;
        input [4:0] row;input [23:0] data;
        begin
            @(negedge Clk);test_row=row;test_data=data;
            force dut.Playfield_inst.row_we=1'b1;
            force dut.Playfield_inst.row_addr=test_row;force dut.Playfield_inst.row_data=test_data;
            @(posedge Clk);@(negedge Clk);
            release dut.Playfield_inst.row_we;release dut.Playfield_inst.row_addr;release dut.Playfield_inst.row_data;
        end
    endtask
    task clear_board;
        integer row;
        begin for(row=0;row<20;row=row+1)write_row(row,0);end
    endtask
    task metadata;
        input integer index;input [3:0] value;
        begin
            @(negedge Clk);meta_col=index/20;meta_row=index%20;meta_value=value;
            force dut.meta_is_lock=1'b1;force dut.meta_lock_col=meta_col;
            force dut.meta_write_addr=meta_row;force dut.meta_lock_data=meta_value;
            @(posedge Clk);@(negedge Clk);
            release dut.meta_is_lock;release dut.meta_lock_col;release dut.meta_write_addr;release dut.meta_lock_data;
        end
    endtask
    task lock2;
        begin
            force dut.Playfield_inst.counter_land2=25'd20_000_000;
            @(posedge Clk);release dut.Playfield_inst.counter_land2;@(posedge Clk);
            force dut.Playfield_inst.lock_counter2=25'd5_940_000;
            @(posedge Clk);release dut.Playfield_inst.lock_counter2;repeat(10)@(negedge Clk);
        end
    endtask
    initial begin
        $readmemh("story_font.mem",font_reference);
        force dut.over_raw=0;
        #100;Rst=1;repeat(32)@(negedge Clk);Idle=0;Playing=1;
        force dut.Playfield_inst.Drop=30'd100_000_000;
        clear_board;frame_edge;
        duo=1;
        force dut.Playfield_inst.counter_c2=5'd20;force dut.Playfield_inst.counter_r2=5'd0;force dut.Playfield_inst.type2=3'd0;
        look(842,154);check(rgb===24'h38B6C8,"P2 active piece at new coordinates");
        duo=0;look(842,154);check(rgb===24'h131D26,"solo suppresses P2 piece");
        release dut.Playfield_inst.counter_c2;release dut.Playfield_inst.counter_r2;
        clear_board;duo=1;
        force dut.Playfield_inst.counter_c2=5'd10;force dut.Playfield_inst.counter_r2=5'd19;force dut.Playfield_inst.type2=3'd3;
        repeat(4)@(negedge Clk);lock2;
        release dut.Playfield_inst.counter_c2;release dut.Playfield_inst.counter_r2;
        look(602,610);check(rgb===24'hC2453A,"P2 lock color survives real row write");
        check(dut.meta_pixel===4'hb,"P2 owner and type stored together");
        clear_board;metadata(23*20+17,4'h3);write_row(17,24'h800000);
        look(914,562);check(rgb===24'hC2453A,"duo column23 visible");
        duo=0;look(914,562);check(!dut.pixel_in_field,"solo clips column23");
        clear_board;
        force dut.type_t=3'd2;force dut.type_t2=3'd3;
        duo=1;look(210,282);check(rgb===24'hD9B23C,"P1 NEXT on left");
        look(1026,282);check(rgb===24'hC2453A,"P2 NEXT on right");
        duo=0;look(210,282);check(rgb===24'hD9B23C,"solo NEXT remains left");
        look(1026,282);check(!dut.next2 && !dut.next_slot,"solo hides right preview");
        force dut.en_hold=1'b1;force dut.hold_type=3'd5;
        duo=1;look(210,458);check(rgb===24'hD97B33,"one shared HOLD on left");
        look(1026,458);check(!dut.hold_slot && !dut.hold,"no second HOLD over core");
        release dut.en_hold;release dut.hold_type;release dut.type_t;release dut.type_t2;
        duo=0;hint_show=1;
        force dut.hint_valid=1;force dut.hint_c0=2;force dut.hint_c1=3;force dut.hint_c2=4;force dut.hint_c3=5;
        force dut.hint_r0=5;force dut.hint_r1=5;force dut.hint_r2=5;force dut.hint_r3=5;
        look(454,270);check(rgb===24'hE8EEF2,"hint white corner");
        look(458,274);check(rgb===24'hE8EEF2,"hint white center");
        look(456,272);check(rgb===24'h131D26,"hint does not fill whole cell");
        duo=1;look(454,270);check(rgb===24'h131D26,"duo hides solo hint");
        hint_show=0;release dut.hint_valid;release dut.hint_c0;release dut.hint_c1;release dut.hint_c2;release dut.hint_c3;
        release dut.hint_r0;release dut.hint_r1;release dut.hint_r2;release dut.hint_r3;
        force dut.story_phase=phase_value;force dut.core_locked=locked_value;
        phase_value=0;locked_value=0;frame_edge;
        look(1014,520);check(rgb===24'h3A4A58,"phase0 rail interrupted");
        phase_value=1;locked_value=2;repeat(3)@(negedge Clk);
        check(dut.display_phase==0,"phase waits visible frame boundary");
        frame_edge;look(1014,520);check(rgb===24'h7FE3EC,"phase1 lower rail restored");
        phase_value=2;locked_value=4;frame_edge;look(1014,392);check(rgb===24'h7FE3EC,"phase2 continuous rail");
        phase_value=3;locked_value=6;frame_edge;look(1040,372);check(rgb===24'h0C161E,"phase3 remaining segment stays dark");
        look(1032,357);check(rgb===24'h5B6E7E,"single upper connector approaches");
        force dut.danger_lvl=2'd2;frame_edge;look(1002,368);check(rgb===24'hD8442E,"real danger expands four paired teeth");
        look(1040,586);check(rgb===24'h2FA8B8,"danger preserves locked energy");
        release dut.danger_lvl;
        look(1000,40);check(rgb===24'h070A10,"no silent COMMS panel");
        force dut.result_valid=1;force dut.mission_success=1;locked_value=8;Finalize=1;Playing=0;
        frame_edge;look(352,56);check(!dut.story_ui_inst.text_valid,"success presentation suppresses text");
        repeat(40)@(negedge Clk);check(dut.result_ready,"success presentation completes");
        glyph(420,264,16,3,24'hE8EEF2);
        sw=1;@(negedge Clk);sw=0;#1;check(!dut.result_ready,"restart cancels old presentation");
        release dut.result_valid;release dut.mission_success;
        Finalize=0;Idle=1;repeat(30)@(negedge Clk);Idle=0;
        force dut.result_valid=1;force dut.mission_success=0;Finalize=1;frame_edge;
        glyph(500,264,12,3,24'hD8442E);
        release dut.result_valid;release dut.mission_success;release dut.story_phase;release dut.core_locked;
        Finalize=0;choose=1;duo=0;glyph(736,288,19,2,24'hE8EEF2);
        duo=1;glyph(736,360,4,2,24'hE8EEF2);
        choose=0;Idle=1;glyph(512,264,18,2,24'hE8EEF2);
        choose=0;Idle=0;Finalize=0;Playing=1;Stop=0;
        force dut.story_phase=phase_value;phase_value=0;
        drift_snapshot=dut.star_drift;repeat(600)@(negedge Clk);
        check(dut.star_drift!=drift_snapshot,"early repair stars drift slowly");
        Stop=1;drift_snapshot=dut.star_drift;repeat(600)@(negedge Clk);
        check(dut.star_drift==drift_snapshot,"pause freezes star position");
        Stop=0;phase_value=2;drift_snapshot=dut.star_drift;repeat(600)@(negedge Clk);
        check(dut.star_drift==drift_snapshot,"stable phase holds attained star position");
        release dut.story_phase;
        if(errors==0)$display("=== ALL PASS: STORY FRAME %0d checks ===",checks);
        else $display("=== FAILED STORY FRAME %0d ===",errors);
        $finish;
    end
    initial begin #2000000;$display("FAILED STORY FRAME watchdog");$finish;end
endmodule
