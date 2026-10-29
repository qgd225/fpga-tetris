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
 `include "ui_layout_geometry.vh"
    reg campaign=1;

    reg Clk=0,Rst=0;
    reg [10:0] hc=0,vc=0;
    reg duo=0,choose=0,Idle=1,Playing=0,Stop=0,Finalize=0,hint_show=0,sw=0;
    wire [23:0] rgb;
    wire [2:0] speed;
    wire [19:0] score;wire [15:0] lines;wire [13:0] time_sec;
    reg [34:0] font_reference[0:127];
    integer errors=0,checks=0,i,j,c,r;
    reg [4:0] test_row,meta_col,meta_row;
    reg [23:0] test_data;
    reg [3:0] meta_value;
    reg [1:0] phase_value;
    reg [3:0] locked_value;
    reg [10:0] drift_snapshot;
    always #6.734 Clk=~Clk;
    frame #(.EFF_TICK(21'd8),.SUCCESS_TICKS(4)) dut(.comms_visible(1'b0),.comms_id(3'd0),.menu_window(2'd0),
        .campaign(campaign),.ship_select(1'b0),.level_id(2'd2),.result_option(2'd0),.Clk_74M(Clk),.Reset_n(Rst),.hcounter(hc),.vcounter(vc),.video_de(1'b1),
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
            @(negedge Clk);hc=x-6;vc=y;repeat(8)@(negedge Clk);
        end
    endtask
    task frame_edge;
        begin @(negedge Clk);hc=0;vc=0;repeat(3)@(negedge Clk);end
    endtask
    // Probe the shared 5x7 glyph at its declared pitch and cap height.
    task glyph;
        input integer bx,by,char_id,pitch,height;input [23:0] color;
        integer gy,gx,found;
        begin
            found=0;
            for(gy=0;gy<7;gy=gy+1)for(gx=0;gx<5;gx=gx+1)
                if(!found && font_reference[char_id][34-gy*5-gx])begin
                    look(bx+(gx*pitch+5)/6,by+(gy*height+6)/7);check(rgb===color,"shared glyph pixel");found=1;
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
        $readmemh("ui_font_5x7.mem",font_reference);
        force dut.over_raw=0;
        #100;Rst=1;repeat(32)@(negedge Clk);Idle=0;Playing=1;
        force dut.Playfield_inst.Drop=30'd100_000_000;
        clear_board;frame_edge;
        duo=1;
        force dut.Playfield_inst.counter_c2=5'd20;force dut.Playfield_inst.counter_r2=5'd0;force dut.Playfield_inst.type2=3'd0;
        look(842,154);check(rgb===24'h38B6C8,"P2 active piece at new coordinates");
        duo=0;look(842,154);check(rgb===24'h091722,"solo suppresses P2 piece");
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
        // Type 3 occupies row 2, column 1; its row 3, column 1 is empty.
        look(1026,258);check(rgb===24'hC2453A,"P2 NEXT on right");
        duo=0;look(210,282);check(rgb===24'hD9B23C,"solo NEXT remains left");
        look(1026,282);check(!dut.next2 && !dut.next_slot,"solo hides right preview");
        force dut.en_hold=1'b1;force dut.hold_type=3'd5;
        duo=1;look(210,458);check(rgb===24'hD97B33,"one shared HOLD on left");
        look(1026,458);check(!dut.hold_slot && !dut.hold,"no second HOLD over core");
        release dut.en_hold;release dut.hold_type;release dut.type_t;release dut.type_t2;
        duo=0;hint_show=1;force dut.hint_active=1;frame_edge;
        force dut.hint_valid=1;force dut.hint_c0=2;force dut.hint_c1=3;force dut.hint_c2=4;force dut.hint_c3=5;
        force dut.hint_r0=5;force dut.hint_r1=5;force dut.hint_r2=5;force dut.hint_r3=5;
        look(448,270);check(rgb===24'hFFE39C,"solo hint hollow left edge");
        look(454,264);check(rgb===24'hFFE39C,"solo hint hollow top edge");
        look(456,272);check(rgb===24'h091722,"hint does not fill whole cell");
        duo=1;look(454,270);check(rgb===24'h091722,"duo hides solo hint");
        hint_show=0;release dut.hint_active;release dut.hint_valid;release dut.hint_c0;release dut.hint_c1;release dut.hint_c2;release dut.hint_c3;
        release dut.hint_r0;release dut.hint_r1;release dut.hint_r2;release dut.hint_r3;
        force dut.charge_left=0;force dut.story_phase=phase_value;force dut.core_locked=locked_value;force dut.display_debris=7'd0;
        phase_value=0;locked_value=0;frame_edge;
        look(UI_CORE_CENTER_X,494);check(rgb===24'h040c13,"core zero cells dark");
        phase_value=1;locked_value=2;repeat(3)@(negedge Clk);
        check(dut.display_phase==0 && dut.display_locked==0,"phase and cells wait visible frame boundary");
        frame_edge;look(UI_CORE_CENTER_X,494);check(rgb===24'h3fdef4,"core two lower cells");
        phase_value=2;locked_value=4;frame_edge;look(UI_CORE_CENTER_X,422);check(rgb===24'h3fdef4,"core four lower cells");
        phase_value=3;locked_value=6;frame_edge;look(UI_CORE_CENTER_X,300);check(rgb===24'h040c13,"core upper slot remains dark");
        force dut.danger_lvl=2'd2;frame_edge;look(UI_CORE_CENTER_X,530);check(rgb===24'h3fdef4,"danger preserves attained cells");
        release dut.danger_lvl;
        check(!dut.comms_visible,"no silent COMMS panel");
        force dut.result_valid=1;force dut.mission_success=1;locked_value=8;Finalize=1;Playing=0;
        frame_edge;look(352,56);check(!dut.story_ui_inst.reference_layer.terminal_panel,"success waits presentation before result overlay");
        repeat(40)@(negedge Clk);check(dut.result_ready,"success presentation completes");
        glyph(500,256,80,20,21,24'h7FE3EC);
        sw=1;@(negedge Clk);sw=0;#1;check(!dut.result_ready,"restart cancels old presentation");
        release dut.result_valid;release dut.mission_success;
        Finalize=0;Idle=1;repeat(30)@(negedge Clk);Idle=0;
        force dut.result_valid=1;force dut.mission_success=0;Finalize=1;frame_edge;
        glyph(550,256,76,20,21,24'hD8442E);
        release dut.result_valid;release dut.mission_success;release dut.story_phase;release dut.core_locked;release dut.display_debris;
        Finalize=0;choose=1;duo=0;glyph(780,190,83,16,21,24'h7FE3EC);
        duo=1;glyph(780,288,68,16,21,24'h7FE3EC);
        choose=0;Idle=1;frame_edge;check(dut.story_ui_inst.Idle,"Idle display state latched");
        choose=0;Idle=0;Finalize=0;Playing=1;Stop=0;
        force dut.story_phase=phase_value;phase_value=0;
        drift_snapshot=dut.star_drift;repeat(600)@(negedge Clk);
        check(dut.star_drift!=drift_snapshot,"early repair stars drift slowly");
        Stop=1;drift_snapshot=dut.star_drift;repeat(600)@(negedge Clk);
        check(dut.star_drift==drift_snapshot,"pause freezes star position");
        Stop=0;phase_value=2;drift_snapshot=dut.star_drift;repeat(600)@(negedge Clk);
        check(dut.star_drift==drift_snapshot,"stable phase holds attained star position");
        release dut.story_phase;
        // Full frame transition must replace the campaign mask with an empty endless board.
        choose=0;Finalize=0;Playing=0;Idle=1;campaign=1;
        repeat(100)@(negedge Clk);
        check(dut.debris_remaining!=0 && dut.state!=0,"campaign initializes residual debris");
        Idle=0;Playing=1;repeat(8)@(negedge Clk);
        Idle=1;Playing=0;campaign=0;repeat(100)@(negedge Clk);
        check(dut.debris_remaining==0 && dut.debris_mask==0 && dut.state==0,"campaign to endless reloads empty board");
        check(dut.run_ready,"cross-mode initialization becomes ready");
        // UI award latches are read-only observers of the real batch contract.
        Idle=0;Playing=1;Stop=0;repeat(3)@(negedge Clk);
        force dut.batch_commit=1;force dut.batch_n=4;@(negedge Clk);
        check(dut.ui_clear_credit==6 && dut.ui_clear_credit_age==48,"four lines show six credited units");
        release dut.batch_commit;release dut.batch_n;
        Stop=1;force dut.eff_tick=1;repeat(3)@(negedge Clk);
        check(dut.ui_clear_credit_age==48,"pause freezes credit popup");
        Stop=0;repeat(5)@(negedge Clk);check(dut.ui_clear_credit_age==43,"popup ages on UI tick");
        release dut.eff_tick;
        force dut.batch_commit=1;force dut.batch_n=8;@(negedge Clk);
        check(dut.ui_clear_credit==8,"wide batch credit is not truncated");release dut.batch_commit;release dut.batch_n;
        force dut.new_run=1;@(negedge Clk);
        check(dut.ui_clear_credit==0 && dut.ui_clear_credit_age==0,"new run clears credit popup");release dut.new_run;
        if(errors==0)$display("=== ALL PASS: STORY FRAME %0d checks ===",checks);
        else $display("=== FAILED STORY FRAME %0d ===",errors);
        $finish;
    end
    initial begin #2000000;$display("FAILED STORY FRAME watchdog");$finish;end
endmodule
