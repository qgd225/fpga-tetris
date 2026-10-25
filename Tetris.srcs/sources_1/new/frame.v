// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: frame
// 作用: 合成游戏场地、信息面板、菜单、结算画面和显示特效。
// 分工: 静态背景颜色由 frame_background 生成, 本模块负责图层优先级和最终取色。
// 时钟/复位: Clk_74M, Reset_n 低有效。
//============================================================
module frame(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input video_de,
    input left_p_flag,
    input right_p_flag,
    input drop_r_flag,
    input drop_en,
    input rotate_p_flag,
    input switch_r_flag,
    input hold_p_flag,
    input Idle,
    input Playing,
    input Stop,
    input Finalize,
    input choose,
    input [3:0]choose_cnt,
    input duo,
    input left_p_flag2,
    input right_p_flag2,
    input drop_r_flag2,
    input drop_en2,
    input rotate_p_flag2,
    input hold_p_flag2,
    input hint_show,

    output wire [23:0]rgb,
    output over,
    output clear,
    output [2:0]speed_level,
    output [19:0]score,
    output [15:0]lines,
    output [13:0]time_sec,
    output snd_land1,
    output snd_land2,
    output snd_hard1,
    output snd_hard2,
    output snd_soft1,
    output snd_soft2,
    output blk_l1,
    output blk_r1,
    output blk_l2,
    output blk_r2,
    output snd_hold1,
    output snd_hold2,
    output blk_rot1,
    output blk_rot2,
    output [2:0]snd_clr_n,
    output mission_win,
    output mission_hold,
    output [1:0] story_phase,
    output mission_success,
    output [1:0] danger_lvl
    );
    `include "story_layout.vh"
    // 坐标寄存加三拍绘制共四级；屏幕左右安全边保持统一底色。
    wire [10:0] render_h,render_v;
    story_pixel_frontend render_coordinates(.clk(Clk_74M),.reset_n(Reset_n),.hcounter(hcounter),.vcounter(vcounter),.x(render_h),.y(render_v));
    wire [4:0] local_x,local_y;
    wire pixel_in_field,pixel_visible;

//    游戏区
    wire [4:0]C_num;
    wire [4:0]R_num;
    wire [479:0]state;
    wire lock_commit1, lock_commit2, move_we;
    wire [4:0]move_row;
    wire Piece;
    wire ghost;
    wire clear_t;
    wire [2:0]type_t;
    wire [2:0]type;
    wire clear_time;
    wire clear_pulse;
    wire clear_t_t;
    wire [4:0]c_clear;
    wire [4:0]clear_row;
    wire [19:0]cc_d;
    wire [19:0]rr_d;
    wire lock_t;
    wire lock_we;
    wire [1:0]lock_idx;
    wire [2:0]type_d;
    wire [2:0]hold_type;
    wire en_hold;
    wire en_hold2;
    wire land_we;
    wire [19:0]line_t;
    wire clear_flash;

//    P2(双人)显示用
    wire Piece2;
    wire ghost2;
    wire [2:0]type2;
    wire [2:0]type_d2;
    wire [2:0]type_t2;
    wire [19:0]cc_d2;
    wire [19:0]rr_d2;
    wire lock_we2;
    wire [1:0]lock_idx2;
    wire land_we2;
    wire next2;
    wire [4:0]cc_t2 [0:3];
    wire [4:0]rr_t2 [0:3];
    wire ghost_ev1;
    wire ghost_ev2;
    wire [4:0]piece_cmin1, piece_cmax1, piece_rmin1, piece_rmax1;
    wire [4:0]piece_cmin2, piece_cmax2, piece_rmin2, piece_rmax2;
    wire hint_valid;
    wire [2:0]hint_type;
    wire [4:0]hint_c0, hint_c1, hint_c2, hint_c3;
    wire [4:0]hint_r0, hint_r1, hint_r2, hint_r3;

    wire [15:0]lines_total;
    wire over_raw, batch_done, engine_quiescent;
    wire [4:0]batch_n;
    wire [2:0]batch_speed;
    wire batch_commit;
    wire finish_pending, result_valid;
    wire [3:0]core_locked;
    wire phase_enter, charge_pulse;
    wire new_run = Idle || choose || (Finalize && switch_r_flag);
    assign mission_hold = finish_pending || result_valid;
    assign mission_win = result_valid && mission_success;
    assign over = result_valid && !mission_success && !Finalize;
    story_controller story_inst(
        .clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),
        .playing(Playing),.paused(Stop),.duo(duo),
        .row_credit(clear_t_t),.batch_done(batch_done),
        .engine_quiescent(engine_quiescent),.over_raw(over_raw),
        .lines_total(lines_total),.story_speed(speed_level),
        .story_phase(story_phase),.core_locked(core_locked),
        .phase_enter(phase_enter),.charge_pulse(charge_pulse),.batch_commit(batch_commit),
        .finish_pending(finish_pending),.result_valid(result_valid),
        .result_success(mission_success)
    );

    assign lines = lines_total;

    wire [19:0]lines_bcd;
    bin_to_bcd line_digits(.clk(Clk_74M),.reset_n(Reset_n),
                          .value(lines_total),.bcd(lines_bcd));

    wire [4:0]cc_t [0:3];
    wire [4:0]rr_t [0:3];

    assign cc_t[0] = cc_d[19:15];
    assign cc_t[1] = cc_d[14:10];
    assign cc_t[2] = cc_d[9:5];
    assign cc_t[3] = cc_d[4:0];

    assign rr_t[0] = rr_d[19:15];
    assign rr_t[1] = rr_d[14:10];
    assign rr_t[2] = rr_d[9:5];
    assign rr_t[3] = rr_d[4:0];

    assign cc_t2[0] = cc_d2[19:15];
    assign cc_t2[1] = cc_d2[14:10];
    assign cc_t2[2] = cc_d2[9:5];
    assign cc_t2[3] = cc_d2[4:0];
    assign rr_t2[0] = rr_d2[19:15];
    assign rr_t2[1] = rr_d2[14:10];
    assign rr_t2[2] = rr_d2[9:5];
    assign rr_t2[3] = rr_d2[4:0];

//    取格行字: 20 行, 每行 24 列(state) / 24x3 位(颜色号) / owner; 纯连线, 0 LUT
    wire [23:0]row_f[0:19];
    genvar gr, gc;
    generate for(gr = 0; gr < 20; gr = gr + 1)begin : gen_rowf
        for(gc = 0; gc < 24; gc = gc + 1)begin : gen_colf
            assign row_f[gr][gc] = state[gc*20+gr];
        end
    end endgenerate

    wire meta_is_lock = lock_commit1 || lock_commit2;
    wire [4:0]meta_lock_col = lock_commit1 ? cc_t[lock_idx] : cc_t2[lock_idx2];
    wire [4:0]meta_write_addr = meta_is_lock ?
        (lock_commit1 ? rr_t[lock_idx] : rr_t2[lock_idx2]) : move_row;
    wire [3:0]meta_lock_data = lock_commit1 ? {1'b0,type_d} : {1'b1,type_d2};
    wire [95:0]meta_display;
    wire [3:0]meta_pixel = meta_display[C_num*4 +: 4];
    genvar bank;
    generate for(bank=0;bank<24;bank=bank+1)begin : metadata_banks
        wire [3:0]copy_data;
        wire we = meta_is_lock ? meta_lock_col == bank : move_we && move_row != 0;
        cell_metadata_bank storage(
            .clk(Clk_74M),.we(we),.write_addr(meta_write_addr),
            .write_data(meta_is_lock ? meta_lock_data : copy_data),
            .display_row(R_num),.copy_row(move_row-5'd1),
            .display_data(meta_display[bank*4 +:4]),.copy_data(copy_data)
        );
    end endgenerate

    Playfield #(.STORY_DISPLAY(1)) Playfield_inst(
    .pixel_x(local_x),.pixel_y(local_y),.pixel_in_field(pixel_in_field),.pixel_visible(pixel_visible),
    .lock_commit1(lock_commit1), .lock_commit2(lock_commit2),
    .mission_hold(mission_hold), .story_speed(speed_level),
    .batch_done(batch_done), .batch_n(batch_n), .batch_speed(batch_speed), .engine_quiescent(engine_quiescent),
    .move_we(move_we), .move_row(move_row),
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(render_h),
    .vcounter(render_v),
    .left_p_flag(left_p_flag),
    .right_p_flag(right_p_flag),
    .drop_r_flag(drop_r_flag),
    .drop_en(drop_en),
    .rotate_p_flag(rotate_p_flag),
    .switch_r_flag(switch_r_flag),
    .hold_p_flag(hold_p_flag),
    .Idle(Idle),
    .Playing(Playing),
    .hint_enable(hint_show),
    .Stop(Stop),
    .Finalize(Finalize),
    .score(score),
    .time_sec(time_sec),
    .duo(duo),
    .left_p_flag2(left_p_flag2),
    .right_p_flag2(right_p_flag2),
    .drop_r_flag2(drop_r_flag2),
    .drop_en2(drop_en2),
    .rotate_p_flag2(rotate_p_flag2),
    .hold_p_flag2(hold_p_flag2),

    .state(state),
    .Piece(Piece),
    .ghost(ghost),
    .C_num(C_num),
    .R_num(R_num),
    .over(over_raw),
    .clear_time(clear_time),
    .clear_t(clear_t),
    .clear_pulse(clear_pulse),
    .clear_t_t(clear_t_t),
    .c_clear(c_clear),
    .type_t(type_t),
    .type(type),
    .clear(clear),
    .cc_d(cc_d),
    .rr_d(rr_d),
    .lock_t(lock_t),
    .lock_we(lock_we),
    .lock_idx(lock_idx),
    .clear_row(clear_row),
    .type_d(type_d),
    .en_hold(en_hold),
    .en_hold2(en_hold2),
    .hold_type(hold_type),
    .speed_level(),
    .land_we(land_we),
    .line_t(line_t),
    .clear_flash(clear_flash),
    .Piece2(Piece2),
    .ghost2(ghost2),
    .type2_out(type2),
    .type_d2_out(type_d2),
    .type_t2_out(type_t2),
    .cc_d2(cc_d2),
    .rr_d2(rr_d2),
    .lock_we2(lock_we2),
    .lock_idx2(lock_idx2),
    .land_we2(land_we2),
    .snd_land1(snd_land1),
    .snd_land2(snd_land2),
    .snd_hard1(snd_hard1),
    .snd_hard2(snd_hard2),
    .snd_soft1(snd_soft1),
    .snd_soft2(snd_soft2),
    .blk_l1(blk_l1),
    .blk_r1(blk_r1),
    .blk_l2(blk_l2),
    .blk_r2(blk_r2),
    .snd_hold1(snd_hold1),
    .snd_hold2(snd_hold2),
    .blk_rot1(blk_rot1),
    .blk_rot2(blk_rot2),
    .ghost_ev1(ghost_ev1),
    .ghost_ev2(ghost_ev2),
    .piece_cmin1(piece_cmin1), .piece_cmax1(piece_cmax1),
    .piece_rmin1(piece_rmin1), .piece_rmax1(piece_rmax1),
    .piece_cmin2(piece_cmin2), .piece_cmax2(piece_cmax2),
    .piece_rmin2(piece_rmin2), .piece_rmax2(piece_rmax2),
    .hint_valid(hint_valid), .hint_type(hint_type),
    .hint_c0(hint_c0), .hint_c1(hint_c1), .hint_c2(hint_c2), .hint_c3(hint_c3),
    .hint_r0(hint_r0), .hint_r1(hint_r1), .hint_r2(hint_r2), .hint_r3(hint_r3)
    );

    wire time_lit;
    wire [15:0]time_bcd;

    timer timer_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(render_h),
    .vcounter(render_v),
    .switch_r_flag(switch_r_flag),
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop || mission_hold),
    .Finalize(Finalize),

    .lit(time_lit),
    .bcd(time_bcd),
    .seconds(time_sec)
    );

    wire score_lit;
    wire [23:0]score_bcd;

    scoring scoring_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(render_h),
    .vcounter(render_v),
    .switch_r_flag(switch_r_flag),
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize),
    .clear_t_t(batch_commit),
    .c_clear(batch_n),
    .speed_level(batch_speed),
    .duo(duo),

    .counter(score),
    .bcd(score_bcd),
    .lit(score_lit)
    );

    wire next,next_margin,next_slot,hold,hold_margin,hold_slot;
    wire [4:0] next_x,next_y,hold_x,hold_y;
    Next_piece #(.CELL_PITCH(`STORY_CELL)) Next_piece_inst(
        .Clk_74M(Clk_74M),.Reset_n(Reset_n),.hcounter(render_h),.vcounter(render_v),.Idle(Idle),.duo(duo),
        .type_t(type_t),.type_t2(type_t2),.X1(`STORY_NEXT1_X),.Y1(`STORY_NEXT_Y),.X2(`STORY_NEXT2_X),.Y2(`STORY_NEXT_Y),
        .next(next),.next2(next2),.next_margin(next_margin),.next_slot(next_slot),.pixel_x(next_x),.pixel_y(next_y));
    hold_piece #(.CELL_PITCH(`STORY_CELL)) hold_piece_inst(
        .Clk_74M(Clk_74M),.Reset_n(Reset_n),.hcounter(render_h),.vcounter(render_v),.Idle(Idle),.duo(duo),
        .en_hold(en_hold | (duo && en_hold2)),.hold_type(hold_type),
        .X1(`STORY_NEXT1_X),.Y1(`STORY_HOLD_Y),.X2(`STORY_NEXT2_X),.Y2(`STORY_HOLD_Y),
        .hold(hold),.hold_margin(hold_margin),.hold_slot(hold_slot),.pixel_x(hold_x),.pixel_y(hold_y));

    wire occupied_now=(R_num<20 && C_num<24)?row_f[R_num][C_num]:1'b0;
    wire hint_match=(C_num==hint_c0 && R_num==hint_r0) || (C_num==hint_c1 && R_num==hint_r1) ||
                    (C_num==hint_c2 && R_num==hint_r2) || (C_num==hint_c3 && R_num==hint_r3);
    wire hint_draw=hint_show && !duo && Playing && hint_valid && hint_match && !occupied_now && !Piece && !Piece2;
    // 存储回归保留这些只读采样点；实际绘制使用同一P0像素的材质和归属。
    reg cell_r,owner_r;reg [2:0] sc_r;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin cell_r<=0;owner_r<=0;sc_r<=0;end
        else begin cell_r<=occupied_now;owner_r<=meta_pixel[3];sc_r<=meta_pixel[2:0];end
    end
    wire [23:0] col_mask=duo?24'hFFFFFF:24'h0FFFFF;
    wire danger_state=|(row_f[0]&col_mask) || |(row_f[1]&col_mask) || |(row_f[2]&col_mask) || |(row_f[3]&col_mask);
    wire caution_state=danger_state || |(row_f[4]&col_mask) || |(row_f[5]&col_mask) || |(row_f[6]&col_mask);
    assign danger_lvl=danger_state?2'd2:(caution_state?2'd1:2'd0);

    parameter [20:0] EFF_TICK=21'd1_237_499;
    parameter SUCCESS_TICKS=72;
    reg [20:0] eff_cnt;
    wire eff_tick=eff_cnt==EFF_TICK;
    reg [7:0] animation;
    reg [4:0] charge_left;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin eff_cnt<=0;animation<=0;charge_left<=0;end
        else if(new_run)begin eff_cnt<=0;animation<=0;charge_left<=0;end
        else if(!Stop)begin
            if(eff_tick)eff_cnt<=0;else eff_cnt<=eff_cnt+1'b1;
            if(charge_pulse)begin animation<=0;charge_left<=24;end
            else if(eff_tick)begin animation<=animation+1'b1;if(charge_left!=0)charge_left<=charge_left-1'b1;end
        end
    end
    wire result_ready;
    wire [6:0] success_age;
    story_presentation #(.SUCCESS_TICKS(SUCCESS_TICKS)) presentation(
        .clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.ui_tick(eff_tick),
        .result_valid(result_valid),.result_success(mission_success),.result_ready(result_ready),.success_age(success_age));
    reg [1:0] display_phase,display_danger;
    reg [3:0] display_locked;
    reg display_success;
    reg [2:0] display_speed;
    reg [19:0] display_lines;
    reg [23:0] display_score;
    reg [15:0] display_time;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            display_phase<=0;display_danger<=0;display_locked<=0;display_success<=0;
            display_speed<=0;display_lines<=0;display_score<=0;display_time<=0;
        end else if(video_de && hcounter==0 && vcounter==0)begin
            display_phase<=story_phase;display_danger<=danger_lvl;display_locked<=core_locked;display_success<=mission_success;
            display_speed<=speed_level;display_lines<=lines_bcd;display_score<=score_bcd;display_time<=time_bcd;
        end
    end
    wire feedback_lock,feedback_hard_left,feedback_hard_right,feedback_clear;
    wire [3:0] feedback_sides,feedback_inset;
    wire [1:0] feedback_rotation;
    story_feedback feedback(.clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.ui_tick(eff_tick),
        .Playing(Playing || Stop),.Stop(Stop),.Finalize(Finalize),.duo(duo),
        .lock1(lock_commit1),.lock2(lock_commit2),.lock_index1(lock_idx),.lock_index2(lock_idx2),
        .columns1(cc_d),.rows1(rr_d),.columns2(cc_d2),.rows2(rr_d2),
        .hard1(snd_hard1),.hard2(snd_hard2),.block_l1(blk_l1),.block_r1(blk_r1),.block_l2(blk_l2),.block_r2(blk_r2),
        .block_rot1(blk_rot1),.block_rot2(blk_rot2),.clear_start(clear_pulse),.clear_active(clear_time),.clear_mask(line_t),
        .column(C_num),.row(R_num),.lock_hit(feedback_lock),.hard_left(feedback_hard_left),.hard_right(feedback_hard_right),
        .clear_hit(feedback_clear),.clear_inset(feedback_inset),.side_marks(feedback_sides),.rotation_marks(feedback_rotation));
    story_ui story_ui_inst(
        .clk(Clk_74M),.reset_n(Reset_n),.x(render_h),.y(render_v),
        .duo(duo),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),.choose_cnt(choose_cnt),
        .phase(display_phase),.danger(display_danger),.locked(display_locked),.success(display_success),.result_ready(result_ready),
        .speed(display_speed),.lines_bcd(display_lines),.score_bcd(display_score),.time_bcd(display_time),
        .feedback_lock(feedback_lock),.feedback_hard_left(feedback_hard_left),.feedback_hard_right(feedback_hard_right),
        .feedback_clear(feedback_clear),.feedback_inset(feedback_inset),.feedback_sides(feedback_sides),.feedback_rotation(feedback_rotation),
        .animation(animation),.charge_left(charge_left),.in_field(pixel_in_field),.cell_visible(pixel_visible),.local_x(local_x),.local_y(local_y),
        .occupied(occupied_now),.piece1(Piece),.piece2(Piece2),.ghost1(ghost),.ghost2(ghost2),.hint_hit(hint_draw),
        .type1(type),.type2(type2),.cell_type(meta_pixel[2:0]),.hint_type(hint_type),.owner(meta_pixel[3]),
        .next1(next),.next2(next2),.hold(hold),.next_slot(next_slot),.hold_slot(hold_slot),
        .next_type1(type_t),.next_type2(type_t2),.hold_type(hold_type),.next_x(next_x),.next_y(next_y),.hold_x(hold_x),.hold_y(hold_y),.rgb(rgb));
    assign snd_clr_n=c_clear[2:0];
endmodule

module cell_metadata_bank(
    input clk,input we,input [4:0]write_addr,input [3:0]write_data,
    input [4:0]display_row,input [4:0]copy_row,
    output [3:0]display_data,output [3:0]copy_data
);
`ifdef SYNTHESIS
    genvar bit_index;
    generate for(bit_index=0;bit_index<4;bit_index=bit_index+1)begin : bits
        RAM32X1D #(.INIT(32'd0)) display_ram(
            .D(write_data[bit_index]),.WE(we),.WCLK(clk),
            .A0(write_addr[0]),.A1(write_addr[1]),.A2(write_addr[2]),
            .A3(write_addr[3]),.A4(write_addr[4]),
            .DPRA0(display_row[0]),.DPRA1(display_row[1]),.DPRA2(display_row[2]),
            .DPRA3(display_row[3]),.DPRA4(display_row[4]),
            .DPO(display_data[bit_index]),.SPO()
        );
        RAM32X1D #(.INIT(32'd0)) copy_ram(
            .D(write_data[bit_index]),.WE(we),.WCLK(clk),
            .A0(write_addr[0]),.A1(write_addr[1]),.A2(write_addr[2]),
            .A3(write_addr[3]),.A4(write_addr[4]),
            .DPRA0(copy_row[0]),.DPRA1(copy_row[1]),.DPRA2(copy_row[2]),
            .DPRA3(copy_row[3]),.DPRA4(copy_row[4]),
            .DPO(copy_data[bit_index]),.SPO()
        );
    end endgenerate
`else
    reg [3:0]memory[0:31];
    integer address;
    initial for(address=0;address<32;address=address+1)memory[address]=4'd0;
    always@(posedge clk)if(we)memory[write_addr]<=write_data;
    assign display_data=memory[display_row];
    assign copy_data=memory[copy_row];
`endif
endmodule
