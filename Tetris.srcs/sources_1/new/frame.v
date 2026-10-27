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
    input comms_visible,input [2:0] comms_id,
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
    input campaign,ship_select,input [1:0] level_id,result_option,menu_window,output wire run_ready,
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
    output [19:0]lines,
    output [13:0]time_sec,
    output reg core_half_event,core_online_event,debris_clear_event,
    output rhythm_reject,rhythm_expire,rhythm_recharge,rhythm_warning,rhythm_critical,
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
    output [1:0] danger_lvl,
    output story_tick_60hz,
    output story_result_ready
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

    wire [19:0]lines_total;
    wire over_raw, batch_done, engine_quiescent;
    wire [4:0]batch_n;
    wire [2:0]batch_speed;
    wire batch_commit;
    wire finish_pending, result_valid,batch_pending;
    wire [3:0]core_locked;
    wire phase_enter, charge_pulse;
    `include "game_mode_params.vh"
    `include "rhythm_params.vh"
    wire [479:0] initial_mask,debris_mask;
    wire [6:0] debris_remaining;
    wire debris_ready;reg debris_ready_d,idle_seed_d;
    reg [15:0] frame_seed;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin frame_seed<=0;debris_ready_d<=0;idle_seed_d<=0;end
        else begin
            if(video_de && hcounter==0 && vcounter==0)frame_seed<=frame_seed+1'b1;
            debris_ready_d<=debris_ready;idle_seed_d<=Idle;
        end
    end
    story_debris initial_debris(.clk(Clk_74M),.reset_n(Reset_n),.start(Idle && !idle_seed_d),
        .campaign(campaign),.duo(duo),.level_id(level_id),.seed(frame_seed),
        .ready(debris_ready),.initial_mask(initial_mask),.debris_seed(),.layout_id());
    wire debris_load=debris_ready && !debris_ready_d;
    assign run_ready=debris_ready && debris_ready_d && engine_quiescent;
    wire new_run = Idle || choose || (Finalize && switch_r_flag);
    wire [2:0] endless_speed;wire [18:0] elapsed_ticks;
    wire [15:0] time_bcd;wire [13:0] reserve_ticks;
    wire supply_wait,supply_failed,reserve_recharge,reserve_warning,reserve_critical;
    wire [8:0] recharge_units;wire recharge_clipped,recharge_no_gain;
    wire hint_active,hint_rejected,hint_recharged;wire [2:0] hint_quota,hint_capacity;wire [9:0] hint_life;
    reg hint_show_d;
    always @(posedge Clk_74M or negedge Reset_n)if(!Reset_n)hint_show_d<=0;else if(new_run)hint_show_d<=0;else hint_show_d<=hint_show;
    run_clock game_clock(.clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.playing(Playing),.paused(Stop),
      .finished(result_valid),.tick(story_tick_60hz),.elapsed_ticks(elapsed_ticks),.seconds(time_sec),.time_bcd(time_bcd),.speed(endless_speed));
    reserve_timer supply(.clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.playing(Playing),.paused(Stop),
      .campaign(campaign),.finished(result_valid),.tick(story_tick_60hz),.batch_commit(batch_commit),
      .batch_inflight(clear_time || batch_done || batch_pending),.batch_n(batch_n),
      .reserve_ticks(reserve_ticks),.waiting(supply_wait),.failed(supply_failed),.recharge(reserve_recharge),
      .warning(reserve_warning),.critical_tick(reserve_critical),.recharge_units(recharge_units),.clipped(recharge_clipped),.no_gain(recharge_no_gain));
    hint_budget prediction(.clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.playing(Playing),.paused(Stop),
      .finished(result_valid),.duo(duo),.campaign(campaign),.tick(story_tick_60hz),
      .request((hint_show ^ hint_show_d) && !supply_wait && !supply_failed),.batch_commit(batch_commit),
      .batch_n(batch_n),.core(core_locked),.active(hint_active),.quota(hint_quota),.rejected(hint_rejected),.recharged(hint_recharged),.quota_capacity(hint_capacity),.life_ticks(hint_life));
    wire hold_valid,hold_ready,hold_expired,hold_rejected,hold_reserved,hold_owner2,hold_condition_player2;
    wire [2:0] hold_store_conditions;
    wire [19:0] real_lines,clear_count;wire [1:0] mission_grade;wire [7:0] average_tenths;
    wire [1:0] hold_blocks_left;wire [6:0] hold_cooldown_ticks;wire [10:0] hold_life_ticks;
    assign rhythm_reject=hint_rejected || hold_rejected;
    assign rhythm_expire=hold_expired;
    assign rhythm_recharge=reserve_recharge || hint_recharged;
    assign rhythm_warning=reserve_warning;
    assign rhythm_critical=reserve_critical || (Playing && !Stop && !mission_hold && hold_valid && !hold_reserved && hold_life_ticks<=180 && hold_life_ticks!=0 && story_tick_60hz && hold_life_ticks%30==0);


    assign mission_hold = finish_pending || result_valid || supply_wait || supply_failed;
    assign mission_win = result_valid && mission_success;
    assign over = result_valid && !mission_success && !Finalize;
    story_controller story_inst(
        .clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),
        .playing(Playing),.paused(Stop),.duo(duo),.campaign(campaign),.level_id(level_id),.debris_remaining(debris_remaining),
        .row_credit(clear_t_t),.batch_done(batch_done),.batch_n(batch_n),.real_lines(real_lines),.clear_count(clear_count),
        .engine_quiescent(engine_quiescent),.over_raw(over_raw || supply_failed),.endless_speed(endless_speed),
        .lines_total(lines_total),.story_speed(speed_level),
        .story_phase(story_phase),.core_locked(core_locked),
        .phase_enter(phase_enter),.charge_pulse(charge_pulse),.batch_commit(batch_commit),
        .finish_pending(finish_pending),.result_valid(result_valid),.batch_pending(batch_pending),
        .result_success(mission_success)
    );


    mission_rank grade_calc(.clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.real_lines(real_lines),.clear_count(clear_count),.elapsed_ticks(elapsed_ticks),.rank(mission_grade),.average_tenths(average_tenths));

    (* rom_style="block" *) reg [6:0] debris_percent_rom[0:1023];
    initial $readmemh("D:/vivado_project/Tetris/Tetris.srcs/sources_1/new/story_debris_percent.mem",debris_percent_rom);
    reg [6:0] debris_percent;
    always @(posedge Clk_74M)debris_percent<=debris_percent_rom[{duo,level_id,debris_remaining}];
    reg [6:0] debris_event_d,audio_debris_d;
    always @(posedge Clk_74M or negedge Reset_n)begin
      if(!Reset_n)begin debris_event_d<=0;audio_debris_d<=0;end
      else if(new_run)begin
       debris_event_d<=campaign?mode_total(duo,level_id):0;
       audio_debris_d<=campaign?mode_total(duo,level_id):0;
      end else begin
       if(batch_commit)debris_event_d<=debris_remaining;
       if(Playing && !Stop)audio_debris_d<=debris_event_d;
      end
    end
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin core_half_event<=0;core_online_event<=0;debris_clear_event<=0;end
        else if(new_run)begin core_half_event<=0;core_online_event<=0;debris_clear_event<=0;end
        else begin
            core_online_event<=Playing && campaign && !mission_success && audio_debris_d!=0 && debris_event_d==0;
            core_half_event<=Playing && campaign && !mission_success && debris_event_d!=0 && debris_event_d<=mode_half(duo,level_id) && audio_debris_d>mode_half(duo,level_id);
            debris_clear_event<=Playing && campaign && !mission_success && debris_event_d<audio_debris_d;
        end
    end
    assign lines = lines_total;

    wire [23:0]lines_bcd;
    bin_to_bcd #(.WIDTH(20),.DIGITS(6)) line_digits(.clk(Clk_74M),.reset_n(Reset_n),
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
    wire [23:0] debris_rows[0:19];
    genvar gr, gc;
    generate for(gr = 0; gr < 20; gr = gr + 1)begin : gen_rowf
        for(gc = 0; gc < 24; gc = gc + 1)begin : gen_colf
            assign row_f[gr][gc] = state[gc*20+gr];
            assign debris_rows[gr][gc] = debris_mask[gc*20+gr];
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
    .hint_enable(hint_active),.ui_tick(story_tick_60hz),.hold_valid(hold_valid),.hold_ready(hold_ready),.hold_expired(hold_expired),.hold_rejected(hold_rejected),.hold_reserved(hold_reserved),.hold_owner2(hold_owner2),.hold_condition_player2(hold_condition_player2),.hold_store_conditions(hold_store_conditions),.hold_blocks_left(hold_blocks_left),.hold_cooldown_ticks(hold_cooldown_ticks),.hold_life_ticks(hold_life_ticks),
    .Stop(Stop),
    .Finalize(Finalize),
    .score(score),
    .time_sec(time_sec),
    .duo(duo),.init_load(debris_load),.initial_mask(initial_mask),.initial_total(campaign?mode_total(duo,level_id):8'd0),.debris_mask(debris_mask),.debris_remaining(debris_remaining),
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
    wire hint_draw=hint_active && !duo && Playing && hint_valid && hint_match && !occupied_now && !Piece && !Piece2;
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
    assign story_tick_60hz=eff_tick;
    reg [7:0] animation;
    reg [10:0] star_drift;
    reg [4:0] charge_left;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin eff_cnt<=0;animation<=0;star_drift<=0;charge_left<=0;end
        else if(new_run)begin eff_cnt<=0;animation<=0;star_drift<=0;charge_left<=0;end
        else if(!Stop)begin
            if(eff_tick)eff_cnt<=0;else eff_cnt<=eff_cnt+1'b1;
            if(eff_tick)begin animation<=animation+1'b1;if(story_phase<2 && animation[4:0]==0 && !Finalize)star_drift<=star_drift==1279?11'd0:star_drift+1'b1;end
            if(charge_pulse)charge_left<=24;
            else if(eff_tick && charge_left!=0)charge_left<=charge_left-1'b1;
        end
    end
    wire result_ready;
    assign story_result_ready=result_ready;
    wire [6:0] success_age;
    story_presentation #(.SUCCESS_TICKS(SUCCESS_TICKS)) presentation(
        .clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),.ui_tick(eff_tick),
        .result_valid(result_valid),.result_success(mission_success),.result_ready(result_ready),.success_age(success_age));

    (* rom_style="block" *) reg [7:0] reserve_fill_rom[0:RHYTHM_RESERVE_CAP];
    initial $readmemh("D:/vivado_project/Tetris/Tetris.srcs/sources_1/new/reserve_fill.mem",reserve_fill_rom);
    reg [7:0] reserve_fill;reg [1:0] reserve_alarm;
    always @(posedge Clk_74M)begin
     reserve_fill<=reserve_fill_rom[reserve_ticks];
     reserve_alarm<=reserve_ticks<=RHYTHM_RESERVE_CRITICAL?2:reserve_ticks<=RHYTHM_RESERVE_LOW?1:0;
    end
    reg [5:0] recharge_age,reject_age;reg expire_pending;
    reg display_expire;reg [7:0] display_reserve_fill;
    reg [1:0] display_reserve_alarm,display_hold_blocks;
    reg [10:0] display_hold_life;reg display_hold_ready,display_hold_visible;
    reg display_hold_reserved,display_hold_actor2,display_hint_active;reg [2:0] display_hold_conditions,display_hint_capacity;reg [9:0] display_hint_life;reg [1:0] display_grade;reg [7:0] display_average;reg display_charge_done;reg [4:0] display_charge_fill,display_debris_fill;reg [4:0] charge_fill,debris_fill;integer fill_i;
    always @(*)begin charge_fill=0;debris_fill=0;for(fill_i=1;fill_i<=20;fill_i=fill_i+1)begin if({1'b0,lines_total}*21'd20>=fill_i*mode_target(duo,level_id))charge_fill=fill_i;if({5'd0,debris_remaining}*12'd20>=fill_i*mode_total(duo,level_id))debris_fill=fill_i;end end
    reg [2:0] display_hint_quota;reg [5:0] display_recharge_age,display_reject_age;
    reg [9:0] display_recharge_units;
    reg [9:0] popup_units;reg popup_clipped,popup_no_gain;
    reg [2:0] previous_speed;reg [5:0] speed_flash,warning_phase;
    reg [5:0] display_speed_flash;reg display_reserve_pulse,display_recharge_clipped,display_recharge_no_gain;
    wire [10:0] popup_sum={1'b0,popup_units}+recharge_units;
    always @(posedge Clk_74M or negedge Reset_n)begin
     if(!Reset_n)begin popup_units<=0;popup_clipped<=0;popup_no_gain<=0;previous_speed<=0;speed_flash<=0;warning_phase<=0;end
     else if(new_run)begin popup_units<=0;popup_clipped<=0;popup_no_gain<=0;previous_speed<=speed_level;speed_flash<=0;warning_phase<=0;end
     else if(Playing && !Stop)begin
      previous_speed<=speed_level;
      if(speed_level>previous_speed)speed_flash<=6;
      else if(story_tick_60hz && speed_flash!=0)speed_flash<=speed_flash-1'b1;
      if(story_tick_60hz)warning_phase<=warning_phase==59?0:warning_phase+1'b1;
      if(reserve_recharge)begin
       popup_units<=recharge_age==0?recharge_units:(popup_sum>999?999:popup_sum[9:0]);
       popup_clipped<=recharge_clipped;popup_no_gain<=recharge_no_gain;
      end
     end
    end
    always @(posedge Clk_74M or negedge Reset_n)begin
     if(!Reset_n)begin recharge_age<=0;reject_age<=0;expire_pending<=0;end
     else if(new_run)begin recharge_age<=0;reject_age<=0;expire_pending<=0;end
     else begin
      if(video_de && hcounter==0 && vcounter==0)expire_pending<=0;
      else if(hold_expired)expire_pending<=1;
      if(rhythm_reject)reject_age<=6;
      else if(story_tick_60hz && !Stop && reject_age!=0)reject_age<=reject_age-1'b1;
      if(reserve_recharge)recharge_age<=48;
      else if(story_tick_60hz && !Stop && recharge_age!=0)recharge_age<=recharge_age-1'b1;
     end
    end

    reg [1:0] display_phase,display_danger;
    reg [3:0] display_locked;
    reg display_success;
    reg [2:0] display_speed;
    reg [23:0] display_lines;
    reg [23:0] display_score;
    reg [15:0] display_time;reg [6:0] display_debris;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            display_phase<=0;display_danger<=0;display_locked<=0;display_success<=0;
            display_speed<=0;display_lines<=0;display_score<=0;display_time<=0;display_debris<=0;
            display_reserve_fill<=104;display_hold_reserved<=0;display_hold_actor2<=0;display_hold_conditions<=7;display_hint_capacity<=1;display_hint_life<=0;display_hint_active<=0;display_grade<=0;display_average<=0;display_charge_done<=0;display_charge_fill<=0;display_debris_fill<=20;display_reserve_alarm<=0;display_hold_blocks<=0;display_hold_life<=0;display_hold_ready<=1;display_hold_visible<=1;display_hint_quota<=1;display_recharge_age<=0;display_recharge_units<=0;display_reject_age<=0;display_expire<=0;display_speed_flash<=0;display_reserve_pulse<=0;display_recharge_clipped<=0;display_recharge_no_gain<=0;
        end else if(video_de && hcounter==0 && vcounter==0)begin
            display_phase<=story_phase;display_danger<=danger_lvl;display_locked<=core_locked;display_success<=mission_success;
            display_reserve_fill<=reserve_fill;display_hold_reserved<=hold_reserved;display_hold_actor2<=hold_condition_player2;display_hold_conditions<=hold_store_conditions;display_hint_capacity<=hint_capacity;display_hint_life<=hint_life;display_hint_active<=hint_active;display_grade<=mission_grade;display_average<=average_tenths;display_charge_done<=lines_total>=mode_target(duo,level_id);display_charge_fill<=charge_fill;display_debris_fill<=debris_fill;display_reserve_alarm<=reserve_alarm;display_hold_blocks<=hold_blocks_left;display_hold_life<=hold_life_ticks;display_hold_ready<=hold_ready;display_hint_quota<=hint_quota;display_recharge_age<=recharge_age;display_recharge_units<=popup_units;display_recharge_clipped<=popup_clipped;display_recharge_no_gain<=popup_no_gain;display_speed_flash<=speed_flash;display_reserve_pulse<=reserve_alarm==2?(warning_phase<15 || (warning_phase>=30 && warning_phase<45)):warning_phase<30;display_reject_age<=reject_age;display_expire<=expire_pending || hold_expired;
            display_hold_visible<=hold_reserved || hold_life_ticks>480 || (hold_life_ticks>180?(hold_life_ticks%30<15):(hold_life_ticks%10<5));
            display_speed<=speed_level;display_lines<=lines_bcd;display_score<=score_bcd;display_time<=time_bcd;display_debris<=batch_commit?debris_remaining:debris_event_d;
        end
    end
    wire [4:0] feedback_clear_age;
    wire feedback_clear_row;
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
        .clear_hit(feedback_clear),.clear_age_out(feedback_clear_age),.clear_row_hit(feedback_clear_row),.clear_inset(feedback_inset),.side_marks(feedback_sides),.rotation_marks(feedback_rotation));
    reg [19:0] bounds_cells1,bounds_cells2;
    reg bounds_duo;
    reg [43:0] bounds1,bounds2;
    function [10:0] pitch24;input [4:0] c;begin pitch24=({6'd0,c}<<4)+({6'd0,c}<<3);end endfunction
    function [43:0] pixel_bounds;
        input [19:0] c;input two;
        reg [10:0] fx,fr,x0,x1,y0,y1;
        begin
            fx=two?352:400;fr=two?928:880;
            x0=fx+pitch24(c[4:0])-(c[4:0]==0?0:3);
            x1=c[9:5]>=(two?23:19)?fr-1:fx+pitch24(c[9:5])+25;
            y0=144+pitch24(c[14:10])-(c[14:10]==0?0:3);
            y1=c[19:15]>=19?623:144+pitch24(c[19:15])+25;
            pixel_bounds={y1,y0,x1,x0};
        end
    endfunction
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin bounds_cells1<=0;bounds_cells2<=0;bounds_duo<=0;bounds1<=0;bounds2<=0;end
        else begin
            bounds_cells1<={piece_rmax1,piece_rmin1,piece_cmax1,piece_cmin1};
            bounds_cells2<={piece_rmax2,piece_rmin2,piece_cmax2,piece_cmin2};bounds_duo<=duo;
            bounds1<=pixel_bounds(bounds_cells1,bounds_duo);bounds2<=pixel_bounds(bounds_cells2,bounds_duo);
        end
    end
    story_ui story_ui_inst(
        .clk(Clk_74M),.reset_n(Reset_n),.x(render_h),.y(render_v),
        .reserve_fill(display_reserve_fill),.reserve_alarm(display_reserve_alarm),.hold_blocks(display_hold_blocks),.hold_life(display_hold_life),.hold_ready(display_hold_ready),.hold_visible(display_hold_visible),.hold_expire_flash(display_expire),.hold_reject_flash(display_reject_age!=0),.hint_quota(display_hint_quota),.hint_capacity(display_hint_capacity),.hint_life(display_hint_life),.hint_active(display_hint_active),.hold_reserved(display_hold_reserved),.hold_actor2(display_hold_actor2),.hold_conditions(display_hold_conditions),.rank(display_grade),.average_tenths(display_average),.charge_done(display_charge_done),.charge_fill(display_charge_fill),.debris_fill(display_debris_fill),.recharge_age(display_recharge_age),.recharge_units(display_recharge_units),.speed_flash(display_speed_flash),.reserve_pulse(display_reserve_pulse),.recharge_capped(display_recharge_clipped),.recharge_no_gain(display_recharge_no_gain),
        .comms_visible(comms_visible),.comms_id(comms_id),.duo(duo),.campaign(campaign),.ship_select(ship_select),.level_id(level_id),.result_option(result_option),.menu_offset(menu_window),.debris_percent(debris_percent),.debris_left(display_debris),.debris_cell((R_num<20 && C_num<24)?debris_rows[R_num][C_num]:1'b0),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),.choose_cnt(choose_cnt),
        .success_age(success_age),.phase(display_phase),.danger(display_danger),.locked(display_locked),.success(display_success),.result_ready(result_ready),
        .speed(display_speed),.lines_bcd(display_lines),.score_bcd(display_score),.time_bcd(display_time),
        .feedback_lock(feedback_lock),.feedback_hard_left(feedback_hard_left),.feedback_hard_right(feedback_hard_right),
        .bounds1(bounds1),.bounds2(bounds2),.star_drift(star_drift),.feedback_clear_age(feedback_clear_age),.feedback_clear_row(feedback_clear_row),
        .feedback_clear(feedback_clear),.feedback_inset(feedback_inset),.feedback_sides(feedback_sides),.feedback_rotation(feedback_rotation),
        .animation(animation),.charge_left(charge_left),.in_field(pixel_in_field),.cell_visible(pixel_visible),.local_x(local_x),.local_y(local_y),
        .occupied(occupied_now),.piece1(Piece),.piece2(Piece2),.ghost1(ghost),.ghost2(ghost2),.hint_hit(hint_draw),
        .type1(type),.type2(type2),.cell_type(meta_pixel[2:0]),.hint_type(hint_type),.owner(meta_pixel[3]),
        .next1(next),.next2(next2),.hold(hold),.next_slot(next_slot),.hold_slot(hold_slot),
        .next_type1(type_t),.next_type2(type_t2),.hold_type(hold_type),.next_x(next_x),.next_y(next_y),.hold_x(hold_x),.hold_y(hold_y),.rgb(rgb));
    assign snd_clr_n=c_clear>4?3'd4:c_clear[2:0];
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
