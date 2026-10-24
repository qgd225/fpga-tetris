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

    output reg [23:0]rgb,
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
    output [1:0] danger_lvl
    );
    reg [23:0]rgb_c;
    reg [6:0]psel;  // 当前像素的组合命中码
    reg [6:0]psel_r;  // 命中码寄存一级，整屏统一右移 1 像素

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

//============================================================
//    HUD 布局(唯一来源): 面板锚点 / 标签 / 分隔线 / 槽位 / 等级条 / 等级数字
//============================================================
    localparam [10:0] XPNL1 = 11'd94,  //双人 P1 面板(左栏)锚点
                     XPNL2 = 11'd1121,  //双人 P2 面板(右栏)锚点
                     XSOLO = 11'd1057,  //单人面板(右栏)锚点
                     YNEXT = 11'd132,  //预览槽位 Y
                     YHOLD = 11'd348,  //Hold 槽位 Y
                     YLBNX = 11'd84,  //NEXT 标签 Y
                     YLBHD = 11'd300,  //HOLD 标签 Y
                     YRLNX = 11'd122,  //NEXT 分隔线 Y
                     YRLHD = 11'd338,  //HOLD 分隔线 Y
                     XLVLB = 11'd232,  //LV 标签 X
                     XLDIG = 11'd283,  //等级数字 X(与等级条同轴)
                     YLBLV = 11'd36,  //LV 标签 Y(与 44px 高的数字底部对齐)
                     YDIGI = 11'd24,
                     XRSCORE = 11'd365, XRLEVEL = 11'd568, XRLINES = 11'd748, XRTIME = 11'd900,
                     YRMODE = 11'd468, YRLAB = 11'd526, YRNUM = 11'd562,
                     XBREACH = 11'd508, YBREACH = 11'd422;
    wire [10:0]XPN1 = duo ? XPNL1 : XSOLO;
    wire [10:0]XPN2 = XPNL2;

//    NEXT/HOLD 标签居中: 4 字 x 24 间距(实宽 92) 在 128 宽面板里左边距 18
    wire [10:0]XLBN1 = XPN1 + 11'd18;
    wire [10:0]XLBN2 = XPN2 + 11'd18;
    wire [10:0]XP1LBL = duo ? 11'd88 : 11'd1032;
    wire [10:0]XP2LBL = duo ? 11'd1123 : 11'd1032;
    wire [10:0]XSCORELBL = duo ? 11'd819 : 11'd688;

    reg [15:0]lines_total;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    lines_total <= 16'd0;
    else if(Finalize)begin
        if(switch_r_flag)
        lines_total <= 16'd0;
        else
        lines_total <= lines_total;
        end
    else if(Stop)
    lines_total <= lines_total;
    else if(Playing)begin
        if(clear_t_t)
        lines_total <= lines_total + 16'd1;
        end
    else
    lines_total <= 16'd0;
    end

    assign lines = lines_total;

    reg [19:0]lines_bcd;
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    lines_bcd <= 20'd0;
    else if(Finalize)begin
        if(switch_r_flag)
        lines_bcd <= 20'd0;
    end
    else if(Stop)
    lines_bcd <= lines_bcd;
    else if(Playing && clear_t_t)begin
        if(lines_bcd[3:0] != 4'd9)
        lines_bcd[3:0] <= lines_bcd[3:0] + 4'd1;
        else begin
        lines_bcd[3:0] <= 4'd0;
        if(lines_bcd[7:4] != 4'd9)
            lines_bcd[7:4] <= lines_bcd[7:4] + 4'd1;
        else begin
            lines_bcd[7:4] <= 4'd0;
            if(lines_bcd[11:8] != 4'd9)
                lines_bcd[11:8] <= lines_bcd[11:8] + 4'd1;
            else begin
                lines_bcd[11:8] <= 4'd0;
                if(lines_bcd[15:12] != 4'd9)
                    lines_bcd[15:12] <= lines_bcd[15:12] + 4'd1;
                else begin
                    lines_bcd[15:12] <= 4'd0;
                    if(lines_bcd[19:16] != 4'd9)
                        lines_bcd[19:16] <= lines_bcd[19:16] + 4'd1;
                end
            end
        end
        end
    end
    else if(!Playing)
    lines_bcd <= 20'd0;
    end

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

    Playfield Playfield_inst(
    .lock_commit1(lock_commit1), .lock_commit2(lock_commit2),
    .move_we(move_we), .move_row(move_row),
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
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
    .over(over),
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
    .speed_level(speed_level),
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

    wire margin;

    Playfield_margin Playfield_margin_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .duo(duo),

    .margin(margin)
    );

    wire time_lit;
    wire [15:0]time_bcd;

    timer timer_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .switch_r_flag(switch_r_flag),
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop),
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
    .hcounter(hcounter),
    .vcounter(vcounter),
    .switch_r_flag(switch_r_flag),
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize),
    .clear_t_t(clear_t_t),
    .c_clear(c_clear),
    .speed_level(speed_level),
    .duo(duo),

    .counter(score),
    .bcd(score_bcd),
    .lit(score_lit)
    );

    wire next;
    wire next_margin;

    Next_piece Next_piece_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .Idle(Idle),
    .duo(duo),
    .type_t(type_t),
    .type_t2(type_t2),
    .X1(XPN1),
    .Y1(YNEXT),
    .X2(XPN2),
    .Y2(YNEXT),

    .next(next),
    .next2(next2),
    .next_margin(next_margin),
    .next_slot(next_slot)
    );

    wire hold;
    wire hold_margin;

    hold_piece hold_piece_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .Idle(Idle),
    .duo(duo),
    .en_hold(en_hold | (duo && en_hold2)),
    .hold_type(hold_type),
    .X1(XPN1),
    .Y1(YHOLD),
    .X2(XPN2),
    .Y2(YHOLD),

    .hold(hold),
    .hold_margin(hold_margin),
    .hold_slot(hold_slot)
    );

    wire level_margin;
    wire level_inner;
    wire level_cap;
    wire [2:0] level_seg;
    wire on;
    wire cur;

    level level_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .speed_level(speed_level),

    .margin(level_margin),
    .inner(level_inner),
    .on(on),
    .cur(cur),
    .cap(level_cap),
    .seg(level_seg)
    );

    wire over_lit;
    wire tick;
    wire [3:0]cn;

    game_over game_over_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .Finalize(Finalize),

    .lit(over_lit),
    .tick(tick),
    .cn(cn)
    );

    wire chs_margin;
    wire chs_inner;
    wire chs_text;
    wire chs_dim;
    wire chs_breath;

    choose_menu choose_menu_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .choose(choose),
    .choose_cnt(choose_cnt),

    .margin(chs_margin),
    .inner(chs_inner),
    .text(chs_text),
    .dim(chs_dim),
    .breath(chs_breath)
    );

//    文字标签 NEXT/HOLD/LV: 1x 字号(20x32), 字距 24
//    地址与 BRAM 使能提前 1 像素(ena_n 用 lb_hn, 左边界多减 1): 否则每字第 1 列会串上一字第 1 列
    reg [10:0]lb_X;
    reg [10:0]lb_Y;
    reg [4:0] lb_g;
    reg       lb_ena;
    reg       lb_ena_n;
    reg       lb_lv;
    reg       lb_mode;
    reg       lb_result_lbl;
    reg       lb_breach;
    integer   li;
    wire [10:0]lb_hn = hcounter + 11'd1;
    always@(*)begin
    lb_X = 11'd0;
    lb_Y = 11'd0;
    lb_g = 5'd26;
    lb_ena = 1'b0;
    lb_ena_n = 1'b0;
    lb_lv = 1'b0;
    lb_mode = 1'b0;
    lb_result_lbl = 1'b0;
    lb_breach = 1'b0;
    for(li = 0; li < 4; li = li + 1)begin
        if((hcounter >= (XLBN1 + li*24)) && (hcounter < (XLBN1 + li*24 + 11'd20)) &&
           (vcounter >= YLBNX) && (vcounter < (YLBNX + 11'd32)))begin
            lb_ena = 1'b1;
            lb_X = XLBN1 + li*24;
            lb_Y = YLBNX;
        end
        if((lb_hn >= (XLBN1 + li*24 - 11'd1)) && (lb_hn < (XLBN1 + li*24 + 11'd20)) &&
           (vcounter >= YLBNX) && (vcounter < (YLBNX + 11'd32)))begin
            lb_ena_n = 1'b1;
            lb_Y = YLBNX;
            case(li)
            0:lb_g = 5'd13;
            1:lb_g = 5'd4;
            2:lb_g = 5'd23;
            3:lb_g = 5'd19;
            default:lb_g = 5'd26;
            endcase
        end
        if((hcounter >= (XLBN1 + li*24)) && (hcounter < (XLBN1 + li*24 + 11'd20)) &&
           (vcounter >= YLBHD) && (vcounter < (YLBHD + 11'd32)))begin
            lb_ena = 1'b1;
            lb_X = XLBN1 + li*24;
            lb_Y = YLBHD;
        end
        if((lb_hn >= (XLBN1 + li*24 - 11'd1)) && (lb_hn < (XLBN1 + li*24 + 11'd20)) &&
           (vcounter >= YLBHD) && (vcounter < (YLBHD + 11'd32)))begin
            lb_ena_n = 1'b1;
            lb_Y = YLBHD;
            case(li)
            0:lb_g = 5'd7;
            1:lb_g = 5'd14;
            2:lb_g = 5'd11;
            3:lb_g = 5'd3;
            default:lb_g = 5'd26;
            endcase
        end
        if(duo)begin
            if((hcounter >= (XLBN2 + li*24)) && (hcounter < (XLBN2 + li*24 + 11'd20)) &&
               (vcounter >= YLBNX) && (vcounter < (YLBNX + 11'd32)))begin
                lb_ena = 1'b1;
                lb_X = XLBN2 + li*24;
                lb_Y = YLBNX;
            end
            if((lb_hn >= (XLBN2 + li*24 - 11'd1)) && (lb_hn < (XLBN2 + li*24 + 11'd20)) &&
               (vcounter >= YLBNX) && (vcounter < (YLBNX + 11'd32)))begin
                lb_ena_n = 1'b1;
                lb_Y = YLBNX;
                case(li)
                0:lb_g = 5'd13;
                1:lb_g = 5'd4;
                2:lb_g = 5'd23;
                3:lb_g = 5'd19;
                default:lb_g = 5'd26;
                endcase
            end
            if((hcounter >= (XLBN2 + li*24)) && (hcounter < (XLBN2 + li*24 + 11'd20)) &&
               (vcounter >= YLBHD) && (vcounter < (YLBHD + 11'd32)))begin
                lb_ena = 1'b1;
                lb_X = XLBN2 + li*24;
                lb_Y = YLBHD;
            end
            if((lb_hn >= (XLBN2 + li*24 - 11'd1)) && (lb_hn < (XLBN2 + li*24 + 11'd20)) &&
               (vcounter >= YLBHD) && (vcounter < (YLBHD + 11'd32)))begin
                lb_ena_n = 1'b1;
                lb_Y = YLBHD;
                case(li)
                0:lb_g = 5'd7;
                1:lb_g = 5'd14;
                2:lb_g = 5'd11;
                3:lb_g = 5'd3;
                default:lb_g = 5'd26;
                endcase
            end
        end
    end
    for(li = 0; li < 2; li = li + 1)begin
        if((hcounter >= (XLVLB + li*24)) && (hcounter < (XLVLB + li*24 + 11'd20)) &&
           (vcounter >= YLBLV) && (vcounter < (YLBLV + 11'd32)))begin
            lb_ena = 1'b1;
            lb_X = XLVLB + li*24;
            lb_Y = YLBLV;
            lb_lv = 1'b1;
        end
        if((lb_hn >= (XLVLB + li*24 - 11'd1)) && (lb_hn < (XLVLB + li*24 + 11'd20)) &&
           (vcounter >= YLBLV) && (vcounter < (YLBLV + 11'd32)))begin
            lb_ena_n = 1'b1;
            lb_Y = YLBLV;
            case(li)
            0:lb_g = 5'd11;
            1:lb_g = 5'd21;
            default:lb_g = 5'd26;
            endcase
        end
    end
    if(Finalize)begin
        for(li = 0; li < 11; li = li + 1)begin
            if((hcounter >= (XBREACH + li*24)) && (hcounter < (XBREACH + li*24 + 11'd20)) &&
               (vcounter >= YBREACH) && (vcounter < (YBREACH + 11'd32)))begin
                lb_ena = 1'b1; lb_X = XBREACH + li*24; lb_Y = YBREACH; lb_breach = 1'b1;
            end
            if((lb_hn >= (XBREACH + li*24 - 11'd1)) && (lb_hn < (XBREACH + li*24 + 11'd20)) &&
               (vcounter >= YBREACH) && (vcounter < (YBREACH + 11'd32)))begin
                lb_ena_n = 1'b1; lb_Y = YBREACH;
                case(li)
                0:lb_g=5'd2; 1:lb_g=5'd14; 2:lb_g=5'd17; 3:lb_g=5'd4;
                4:lb_g=5'd26; 5:lb_g=5'd1; 6:lb_g=5'd17; 7:lb_g=5'd4;
                8:lb_g=5'd0; 9:lb_g=5'd2; default:lb_g=5'd7;
                endcase
            end
        end
        for(li = 0; li < 4; li = li + 1)begin
            if((hcounter >= (11'd404 + li*24)) && (hcounter < (11'd404 + li*24 + 11'd20)) &&
               (vcounter >= YRMODE) && (vcounter < (YRMODE + 11'd32)))begin
                lb_ena = 1'b1; lb_X = 11'd404 + li*24; lb_Y = YRMODE; lb_mode = 1'b1;
            end
            if((lb_hn >= (11'd404 + li*24 - 11'd1)) && (lb_hn < (11'd404 + li*24 + 11'd20)) &&
               (vcounter >= YRMODE) && (vcounter < (YRMODE + 11'd32)))begin
                lb_ena_n = 1'b1; lb_Y = YRMODE;
                if(duo) case(li) 0:lb_g=5'd3; 1:lb_g=5'd20; 2:lb_g=5'd14; default:lb_g=5'd26; endcase
                else case(li) 0:lb_g=5'd18; 1:lb_g=5'd14; 2:lb_g=5'd11; default:lb_g=5'd14; endcase
            end
        end
        for(li = 0; li < 5; li = li + 1)begin
            if((hcounter >= (XRSCORE + li*24)) && (hcounter < (XRSCORE + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena=1'b1; lb_X=XRSCORE+li*24; lb_Y=YRLAB; lb_result_lbl=1'b1;
            end
            if((lb_hn >= (XRSCORE + li*24 - 11'd1)) && (lb_hn < (XRSCORE + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena_n=1'b1; lb_Y=YRLAB;
                case(li) 0:lb_g=5'd18; 1:lb_g=5'd2; 2:lb_g=5'd14; 3:lb_g=5'd17; default:lb_g=5'd4; endcase
            end
            if((hcounter >= (XRLEVEL + li*24)) && (hcounter < (XRLEVEL + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena=1'b1; lb_X=XRLEVEL+li*24; lb_Y=YRLAB; lb_result_lbl=1'b1;
            end
            if((lb_hn >= (XRLEVEL + li*24 - 11'd1)) && (lb_hn < (XRLEVEL + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena_n=1'b1; lb_Y=YRLAB;
                case(li) 0:lb_g=5'd11; 1:lb_g=5'd4; 2:lb_g=5'd21; 3:lb_g=5'd4; default:lb_g=5'd11; endcase
            end
            if((hcounter >= (XRLINES + li*24)) && (hcounter < (XRLINES + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena=1'b1; lb_X=XRLINES+li*24; lb_Y=YRLAB; lb_result_lbl=1'b1;
            end
            if((lb_hn >= (XRLINES + li*24 - 11'd1)) && (lb_hn < (XRLINES + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena_n=1'b1; lb_Y=YRLAB;
                case(li) 0:lb_g=5'd11; 1:lb_g=5'd8; 2:lb_g=5'd13; 3:lb_g=5'd4; default:lb_g=5'd18; endcase
            end
        end
        for(li = 0; li < 4; li = li + 1)begin
            if((hcounter >= (XRTIME + li*24)) && (hcounter < (XRTIME + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena=1'b1; lb_X=XRTIME+li*24; lb_Y=YRLAB; lb_result_lbl=1'b1;
            end
            if((lb_hn >= (XRTIME + li*24 - 11'd1)) && (lb_hn < (XRTIME + li*24 + 11'd20)) &&
               (vcounter >= YRLAB) && (vcounter < (YRLAB + 11'd32)))begin
                lb_ena_n=1'b1; lb_Y=YRLAB;
                case(li) 0:lb_g=5'd19; 1:lb_g=5'd8; 2:lb_g=5'd12; default:lb_g=5'd4; endcase
            end
        end
    end
    end

    wire [5:0]lb_vt = vcounter - lb_Y;
    wire [19:0]lb_dout;
    letter letter_hud_inst(
    .clka(Clk_74M),
    .ena(lb_ena_n),
    .addra({lb_g, lb_vt}),
    .douta(lb_dout)
    );
    wire lbl_lit = lb_ena ? lb_dout[19 - (hcounter - lb_X)] : 1'b0;

//    顶栏发丝线(时间/分数分组) 与 结束画面下划线: 都走标签灰
    wire top_rule_lit = (hcounter >= 11'd470) && (hcounter <= 11'd470) &&
                        (vcounter >= 11'd24) && (vcounter < 11'd68);
    wire over_line_lit = Finalize && (hcounter >= 11'd449) && (hcounter <= 11'd825) &&
                         (vcounter >= 11'd417) && (vcounter <= 11'd419);

//    面板分隔线: 2px, 位于标签下方
    wire rule1_lit = ((vcounter >= YRLNX) && (vcounter < (YRLNX + 11'd2)) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128))) ||
                     ((vcounter >= YRLHD) && (vcounter < (YRLHD + 11'd2)) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128))) ||
                     ((vcounter >= 11'd717) && (vcounter < 11'd721) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128)));
    wire level_frame_lit =
        (((hcounter >= 11'd263) && (hcounter <= 11'd264)) ||
         ((hcounter >= 11'd303) && (hcounter <= 11'd304))) &&
        (vcounter >= 11'd86) && (vcounter <= 11'd713) ||
        (((vcounter >= 11'd86) && (vcounter <= 11'd87)) ||
         ((vcounter >= 11'd712) && (vcounter <= 11'd713))) &&
        (hcounter >= 11'd263) && (hcounter <= 11'd304);
    wire rule2_lit = duo && (((vcounter >= YRLNX) && (vcounter < (YRLNX + 11'd2)) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))) ||
                             ((vcounter >= YRLHD) && (vcounter < (YRLHD + 11'd2)) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))) ||
                             ((vcounter >= 11'd717) && (vcounter < 11'd721) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))));
    wire slot_frame_lit =
        ((hcounter >= XPN1) && (hcounter <= (XPN1 + 11'd128)) &&
         ((vcounter == YNEXT) || (vcounter == (YNEXT + 11'd128)) ||
          (vcounter == YHOLD) || (vcounter == (YHOLD + 11'd128)))) ||
        ((hcounter == XPN1) || (hcounter == (XPN1 + 11'd128))) &&
         (((vcounter >= YNEXT) && (vcounter <= (YNEXT + 11'd128))) ||
          ((vcounter >= YHOLD) && (vcounter <= (YHOLD + 11'd128)))) ||
        (duo &&
         (((hcounter >= XPN2) && (hcounter <= (XPN2 + 11'd128)) &&
           ((vcounter == YNEXT) || (vcounter == (YNEXT + 11'd128)) ||
            (vcounter == YHOLD) || (vcounter == (YHOLD + 11'd128)))) ||
          ((hcounter == XPN2) || (hcounter == (XPN2 + 11'd128))) &&
           (((vcounter >= YNEXT) && (vcounter <= (YNEXT + 11'd128))) ||
            ((vcounter >= YHOLD) && (vcounter <= (YHOLD + 11'd128))))));

//    等级数字: 1 位, 与等级条同轴
    wire [3:0] lv_dig = {1'b0, speed_level};
    wire [10:0]vdv = vcounter - YDIGI;
    wire lvd_ena = (hcounter >= XLDIG) && (hcounter < (XLDIG + 11'd20)) &&
                   (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd44));

//    取字使能提前 1 像素(number 也是 READ_LATENCY=1): 否则每行第 1 列会串上一行
    wire lvd_ena_n = (lb_hn >= (XLDIG - 11'd1)) && (lb_hn < (XLDIG + 11'd20)) &&
                     (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd44));

//    结算页数值复用 number ROM：SCORE(6 位)/LEVEL(1 位)/LINES(5 位)/TIME(MM:SS)
    reg result_num_ena;
    reg result_num_ena_n;
    reg [10:0]result_num_X;
    reg [10:0]result_num_Y;
    reg [3:0]result_num_dig;
    reg [1:0]result_num_sel;
    integer rni;
    always@(*)begin
    result_num_ena = 1'b0;
    result_num_ena_n = 1'b0;
    result_num_X = 11'd0;
    result_num_Y = YRNUM;
    result_num_dig = 4'd0;
    result_num_sel = 2'd0;
    if(Finalize)begin
        for(rni = 0; rni < 6; rni = rni + 1)begin
            if((hcounter >= (XRSCORE + rni*24)) && (hcounter < (XRSCORE + rni*24 + 11'd20)) &&
               (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
                result_num_ena = 1'b1; result_num_X = XRSCORE + rni*24; result_num_dig = score_bcd[(5-rni)*4 +: 4]; result_num_sel = 2'd0;
            end
            if((lb_hn >= (XRSCORE + rni*24 - 11'd1)) && (lb_hn < (XRSCORE + rni*24 + 11'd20)) &&
               (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
                result_num_ena_n = 1'b1; result_num_dig = score_bcd[(5-rni)*4 +: 4]; result_num_sel = 2'd0;
            end
        end
        if((hcounter >= XRLEVEL) && (hcounter < (XRLEVEL + 11'd20)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena = 1'b1; result_num_X = XRLEVEL; result_num_dig = {1'b0,speed_level}; result_num_sel = 2'd1;
        end
        if((lb_hn >= (XRLEVEL - 11'd1)) && (lb_hn < (XRLEVEL + 11'd20)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena_n = 1'b1; result_num_dig = {1'b0,speed_level}; result_num_sel = 2'd1;
        end
        for(rni = 0; rni < 5; rni = rni + 1)begin
            if((hcounter >= (XRLINES + rni*24)) && (hcounter < (XRLINES + rni*24 + 11'd20)) &&
               (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
                result_num_ena = 1'b1; result_num_X = XRLINES + rni*24; result_num_dig = lines_bcd[(4-rni)*4 +: 4]; result_num_sel = 2'd2;
            end
            if((lb_hn >= (XRLINES + rni*24 - 11'd1)) && (lb_hn < (XRLINES + rni*24 + 11'd20)) &&
               (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
                result_num_ena_n = 1'b1; result_num_dig = lines_bcd[(4-rni)*4 +: 4]; result_num_sel = 2'd2;
            end
        end
        if((hcounter >= XRTIME) && (hcounter < (XRTIME + 11'd20)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena=1'b1; result_num_X=XRTIME; result_num_dig=time_bcd[15:12]; result_num_sel=2'd3;
        end
        if((lb_hn >= (XRTIME - 11'd1)) && (lb_hn < (XRTIME + 11'd20)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena_n=1'b1; result_num_dig=time_bcd[15:12]; result_num_sel=2'd3;
        end
        if((hcounter >= (XRTIME + 11'd24)) && (hcounter < (XRTIME + 11'd44)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena=1'b1; result_num_X=XRTIME+11'd24; result_num_dig=time_bcd[11:8]; result_num_sel=2'd3;
        end
        if((lb_hn >= (XRTIME + 11'd23)) && (lb_hn < (XRTIME + 11'd44)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena_n=1'b1; result_num_dig=time_bcd[11:8]; result_num_sel=2'd3;
        end
        if((hcounter >= (XRTIME + 11'd68)) && (hcounter < (XRTIME + 11'd88)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena=1'b1; result_num_X=XRTIME+11'd68; result_num_dig=time_bcd[7:4]; result_num_sel=2'd3;
        end
        if((lb_hn >= (XRTIME + 11'd67)) && (lb_hn < (XRTIME + 11'd88)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena_n=1'b1; result_num_dig=time_bcd[7:4]; result_num_sel=2'd3;
        end
        if((hcounter >= (XRTIME + 11'd92)) && (hcounter < (XRTIME + 11'd112)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena=1'b1; result_num_X=XRTIME+11'd92; result_num_dig=time_bcd[3:0]; result_num_sel=2'd3;
        end
        if((lb_hn >= (XRTIME + 11'd91)) && (lb_hn < (XRTIME + 11'd112)) && (vcounter >= YRNUM) && (vcounter < (YRNUM + 11'd44)))begin
            result_num_ena_n=1'b1; result_num_dig=time_bcd[3:0]; result_num_sel=2'd3;
        end
    end
    end
    wire [10:0]result_num_vt = vcounter - result_num_Y;
    wire number_ena_n = result_num_ena_n || lvd_ena_n;
    wire [9:0]number_addra = result_num_ena_n ? {result_num_dig,result_num_vt[5:0]} : {lv_dig,vdv[5:0]};
    wire [19:0]lvd_dout;
    number number_lv_inst(
    .clka(Clk_74M),
    .ena(number_ena_n),
    .addra(number_addra),
    .douta(lvd_dout)
    );
    wire lvd_lit = lvd_ena ? lvd_dout[19 - (hcounter - XLDIG)] : 1'b0;
    wire result_num_lit = result_num_ena ? lvd_dout[19 - (hcounter - result_num_X)] : 1'b0;

//    等级色: CORE-07 压力柱 8 级热力渐变
    localparam [23:0] LV_H0 = 24'h00E5FF,
                      LV_H1 = 24'h38D996,
                      LV_H2 = 24'h9BD64D,
                      LV_H3 = 24'hFFD23F,
                      LV_H4 = 24'hFF9F1C,
                      LV_H5 = 24'hFF6B35,
                      LV_H6 = 24'hE63946,
                      LV_H7 = 24'hFFFFFF;
    reg [23:0]lv_color;
    always@(*)begin
    case(speed_level)
    0:lv_color = LV_H0;
    1:lv_color = LV_H1;
    2:lv_color = LV_H2;
    3:lv_color = LV_H3;
    4:lv_color = LV_H4;
    5:lv_color = LV_H5;
    6:lv_color = LV_H6;
    7:lv_color = LV_H7;
    default:lv_color = LV_H0;
    endcase
    end

    reg [2:0] level_seg_r;
    reg [23:0]level_seg_color;
    always@(*)begin
    case(level_seg_r)
    3'd0:level_seg_color = LV_H0;
    3'd1:level_seg_color = LV_H1;
    3'd2:level_seg_color = LV_H2;
    3'd3:level_seg_color = LV_H3;
    3'd4:level_seg_color = LV_H4;
    3'd5:level_seg_color = LV_H5;
    3'd6:level_seg_color = LV_H6;
    default:level_seg_color = LV_H7;
    endcase
    end

//    LV 组下方 2px 等级色横线: 并入等级数字分支(同色)
    wire lv_rule_lit = (hcounter >= 11'd232) && (hcounter < 11'd306) &&
                       (vcounter >= 11'd72) && (vcounter < 11'd74);
    wire lvd_all_lit = lvd_lit || lv_rule_lit;
    wire result_score_rule = Finalize && (vcounter >= 11'd510) && (vcounter <= 11'd511) && (hcounter >= XRSCORE) && (hcounter < (XRSCORE + 11'd96));
    wire result_level_rule = Finalize && (vcounter >= 11'd510) && (vcounter <= 11'd511) && (hcounter >= XRLEVEL) && (hcounter < (XRLEVEL + 11'd96));
    wire result_lines_rule = Finalize && (vcounter >= 11'd510) && (vcounter <= 11'd511) && (hcounter >= XRLINES) && (hcounter < (XRLINES + 11'd96));
    wire result_time_rule = Finalize && (vcounter >= 11'd510) && (vcounter <= 11'd511) && (hcounter >= XRTIME) && (hcounter < (XRTIME + 11'd96));
    wire [1:0]result_rule_sel = result_level_rule ? 2'd1 : result_lines_rule ? 2'd2 : result_time_rule ? 2'd3 : 2'd0;
    wire result_colon_lit = Finalize && (hcounter >= 11'd950) && (hcounter <= 11'd953) &&
                            (((vcounter >= 11'd576) && (vcounter <= 11'd579)) ||
                             ((vcounter >= 11'd590) && (vcounter <= 11'd593)));

//    结算区域先屏蔽底层游戏内容，再用棋盘纹压暗；标题、标签和数值在其上层绘制
    wire result_region = Finalize &&
                      (((hcounter >= 11'd432) && (hcounter <= 11'd847) && (vcounter >= 11'd310) && (vcounter <= 11'd451)) ||
                       ((hcounter >= 11'd352) && (hcounter <= 11'd1048) && (vcounter >= 11'd456) && (vcounter <= 11'd620)));
    wire result_dim = result_region && (hcounter[0] ^ vcounter[0]);

//    幽灵框: 2px 边带 + 四角各切 1x1(内部纯黑, 与实心下落方块区分)
//    判定必须与 ghost_r 同拍寄存: ghost_r 比 hcounter 晚 1 拍, 否则框会左窄右宽
    wire [10:0]glx = (hcounter - 11'd321) & 11'd31;
    wire [10:0]gly = (vcounter - 11'd81) & 11'd31;
    wire glx_bd = (glx < 11'd2) || (glx > 11'd27);
    wire gly_bd = (gly < 11'd2) || (gly > 11'd27);
    wire glx_cn = (glx < 11'd1) || (glx > 11'd28);
    wire gly_cn = (gly < 11'd1) || (gly > 11'd28);
    wire ghost_edge = (glx_bd || gly_bd) && !(glx_cn && gly_cn);

//    实心方块 1px 圆角: 四角各切 1x1(与幽灵切角同一判定)
    wire piece_round = !(glx_cn && gly_cn);

    reg over_lit_r;
    reg tick_r;
    reg [3:0]cn_r;
    reg level_margin_r;
    reg level_inner_r;
    reg level_cap_r;
    reg on_r;
    reg cur_r;
    reg hold_r;
    reg hold_margin_r;
    reg next_r;
    reg next_margin_r;
    reg score_lit_r;
    reg time_lit_r;
    reg margin_r;
    (* DONT_TOUCH = "TRUE" *) reg Piece_r;
    (* DONT_TOUCH = "TRUE" *) reg ghost_r;
    (* DONT_TOUCH = "TRUE" *) reg ghost_edge_r;
    reg [10:0]glx_r;
    reg [10:0]gly_r;

//    幽灵内角标：使用与 ghost_r 对齐的寄存局部坐标
    wire gt_tl = ((glx_r >= 11'd4) && (glx_r <= 11'd8) && (gly_r == 11'd4)) ||
                 ((glx_r == 11'd4) && (gly_r >= 11'd5) && (gly_r <= 11'd8));
    wire gt_tr = ((glx_r >= 11'd23) && (glx_r <= 11'd27) && (gly_r == 11'd4)) ||
                 ((glx_r == 11'd27) && (gly_r >= 11'd5) && (gly_r <= 11'd8));
    wire gt_bl = ((glx_r >= 11'd4) && (glx_r <= 11'd8) && (gly_r == 11'd27)) ||
                 ((glx_r == 11'd4) && (gly_r >= 11'd23) && (gly_r <= 11'd26));
    wire gt_br = ((glx_r >= 11'd23) && (glx_r <= 11'd27) && (gly_r == 11'd27)) ||
                 ((glx_r == 11'd27) && (gly_r >= 11'd23) && (gly_r <= 11'd26));
    wire ghost_tick = gt_tl || gt_tr || gt_bl || gt_br;
    reg piece_round_r;
    reg pv_round_r;
    reg [10:0]pvx_r;
    reg [10:0]pvy_r;
    reg land_we_r;
    reg [2:0]type_r;
    reg [2:0]type_t_r;
    reg [2:0]hold_type_r;
    (* DONT_TOUCH = "TRUE" *) reg cell_r;
    reg [2:0]sc_r;
    reg owner_r;
    reg clear_t_r;
    reg clear_shrink_r;
    wire collapse_ring_r = clear_shrink_r &&
        (((glx_r == 11'd10) || (glx_r == 11'd21)) &&
         (gly_r >= 11'd10) && (gly_r <= 11'd21) ||
         ((gly_r == 11'd10) || (gly_r == 11'd21)) &&
         (glx_r >= 11'd10) && (glx_r <= 11'd21));
    wire collapse_spark_r = clear_shrink_r &&
        (glx_r >= 11'd14) && (glx_r <= 11'd17) &&
        (gly_r >= 11'd14) && (gly_r <= 11'd17);
    reg flash_r;
    reg chs_margin_r;
    reg chs_inner_r;
    reg chs_text_r;
    reg chs_dim_r;
    reg chs_breath_r;
    (* DONT_TOUCH = "TRUE" *) reg Piece2_r;
    (* DONT_TOUCH = "TRUE" *) reg ghost2_r;
    reg [2:0]type2_r;
    reg [2:0]type_t2_r;
    reg land_we2_r;
    reg next2_r;
    reg lbl_r;
    reg rule1_r;
    reg rule2_r;
    reg next_slot_r;
    reg hold_slot_r;

//    预览方块 1px 圆角: 相位按面板/槽位分别取(避免跨面板串相位)
    wire [10:0]pvx1 = (hcounter - XPN1) & 11'd31;
    wire [10:0]pvx2 = (hcounter - XPN2) & 11'd31;
    wire [10:0]pvx = (duo && (hcounter >= XPN2)) ? pvx2 : pvx1;
    wire [10:0]pvy_n = (vcounter - YNEXT) & 11'd31;
    wire [10:0]pvy_h = (vcounter - YHOLD) & 11'd31;
    wire [10:0]pvy = hold_slot_r ? pvy_h : pvy_n;
    wire pv_corner = ((pvx == 11'd0) || (pvx == 11'd29)) && ((pvy == 11'd0) || (pvy == 11'd29));

//    新配色: 场地底色 vs 外部 / P1P2 槽位底色
    wire [10:0]XR = duo ? 11'd1088 : 11'd960;
    wire in_field = (hcounter >= 11'd321) && (hcounter < XR) && (vcounter >= 11'd81);
    wire [23:0]field_bg = 24'h081018;
    wire [23:0]slot_bg = (duo && (hcounter >= XPN2)) ? 24'h1E0812 : 24'h071018;
    wire [23:0]story_outer_color;
    wire [23:0]story_inner_color;
    wire [23:0]story_menu_color;
    reg [23:0]story_outer_color_r;
    reg [23:0]story_inner_color_r;
    reg [23:0]story_menu_color_r;

    // 背景生成: 提供优先级较低的场外背景和场内背景颜色。
    frame_background background_inst(
        .hcounter(hcounter), .vcounter(vcounter), .right_edge(XR),
        .duo(duo), .in_field(in_field), .field_bg(field_bg),
        .outer_color(story_outer_color), .inner_color(story_inner_color),
        .menu_color(story_menu_color)
    );
    reg lvd_r;
    reg lb_lv_r;
    reg fin_r;
    reg result_num_r;
    reg [1:0]result_num_sel_r;
    reg result_mode_r;
    reg result_label_r;
    reg result_rule_r;
    reg [1:0]result_rule_sel_r;
    reg result_colon_r;
    reg [23:0]hint_color;
    reg hint_hit_r;
    reg [2:0]hint_type_r;
    wire hint_match = hint_valid && (hint_type == type) &&
        ((C_num == hint_c0 && R_num == hint_r0) || (C_num == hint_c1 && R_num == hint_r1) ||
         (C_num == hint_c2 && R_num == hint_r2) || (C_num == hint_c3 && R_num == hint_r3));
    wire hint_box = (((gly_r == 11'd9) || (gly_r == 11'd20)) && (glx_r > 11'd8) && (glx_r < 11'd21) && (glx_r[1:0] < 2'd2)) ||
                    (((glx_r == 11'd9) || (glx_r == 11'd20)) && (gly_r > 11'd8) && (gly_r < 11'd21) && (gly_r[1:0] < 2'd2));
    wire hint_dot = (glx_r >= 11'd14) && (glx_r <= 11'd15) && (gly_r >= 11'd14) && (gly_r <= 11'd15);
    wire [4:0]hint_r_safe = (R_num <= 5'd19) ? R_num : 5'd0;
    wire [4:0]hint_c_safe = (C_num <= 5'd23) ? C_num : 5'd0;
    wire hint_occupied_now = row_f[hint_r_safe][hint_c_safe] || Piece || Piece2;
    wire hint_cell_lit = hint_hit_r && (hint_box || hint_dot);

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    over_lit_r <= 1'b0;
    tick_r <= 1'b0;
    cn_r <= 4'd0;
    level_margin_r <= 1'b0;
    level_inner_r <= 1'b0;
    level_cap_r <= 1'b0;
    level_seg_r <= 3'd0;
    on_r <= 1'b0;
    cur_r <= 1'b0;
    hold_r <= 1'b0;
    hold_margin_r <= 1'b0;
    next_r <= 1'b0;
    next_margin_r <= 1'b0;
    score_lit_r <= 1'b0;
    time_lit_r <= 1'b0;
    margin_r <= 1'b0;
    Piece_r <= 1'b0;
    ghost_r <= 1'b0;
        ghost_edge_r <= 1'b0;
        glx_r <= 11'd0;
        gly_r <= 11'd0;
        piece_round_r <= 1'b0;
        pv_round_r <= 1'b0;
        pvx_r <= 11'd0;
        pvy_r <= 11'd0;
    land_we_r <= 1'b0;
    type_r <= 3'd0;
    type_t_r <= 3'd0;
    hold_type_r <= 3'd0;
    cell_r <= 1'b0;
    sc_r <= 3'd0;
    owner_r <= 1'b0;
    clear_t_r <= 1'b0;
    clear_shrink_r <= 1'b0;
    flash_r <= 1'b0;
    chs_margin_r <= 1'b0;
    chs_inner_r <= 1'b0;
    chs_text_r <= 1'b0;
    chs_dim_r <= 1'b0;
    chs_breath_r <= 1'b0;
    Piece2_r <= 1'b0;
    ghost2_r <= 1'b0;
    type2_r <= 3'd0;
    type_t2_r <= 3'd0;
    land_we2_r <= 1'b0;
    next2_r <= 1'b0;
    lbl_r <= 1'b0;
    rule1_r <= 1'b0;
    rule2_r <= 1'b0;
    next_slot_r <= 1'b0;
    hold_slot_r <= 1'b0;
    lvd_r <= 1'b0;
    lb_lv_r <= 1'b0;
    fin_r <= 1'b0;
    result_num_r <= 1'b0; result_num_sel_r <= 2'd0; result_mode_r <= 1'b0; result_label_r <= 1'b0;
    result_rule_r <= 1'b0; result_rule_sel_r <= 2'd0; result_colon_r <= 1'b0;
    hint_hit_r <= 1'b0; hint_type_r <= 3'd0; psel_r <= 7'd0;
    story_outer_color_r <= 24'h0; story_inner_color_r <= 24'h0; story_menu_color_r <= 24'h0;
    end
    else begin
    over_lit_r <= over_lit;
    tick_r <= tick;
    cn_r <= cn;
    level_margin_r <= level_margin;
    level_inner_r <= level_inner;
    level_cap_r <= level_cap;
    level_seg_r <= level_seg;
    on_r <= on;
    cur_r <= cur;
    hold_r <= hold;
    hold_margin_r <= hold_margin;
    next_r <= next;
    next_margin_r <= next_margin;
    score_lit_r <= score_lit;
    time_lit_r <= time_lit;
    margin_r <= margin;
    Piece_r <= Piece;
    ghost_r <= ghost;
        ghost_edge_r <= ghost_edge;
        glx_r <= glx;
        gly_r <= gly;
        piece_round_r <= piece_round;
        pv_round_r <= !pv_corner;
        pvx_r <= pvx;
        pvy_r <= pvy;
    land_we_r <= land_we;
    type_r <= type;
    type_t_r <= type_t;
    hold_type_r <= hold_type;

//    场地取色: 编号必须在场地内(哨兵 24 或 20 表示不在任何格)
    if((C_num <= 5'd23) && (R_num <= 5'd19))begin
    cell_r <= row_f[R_num][C_num];
    sc_r <= meta_pixel[2:0];
    owner_r <= meta_pixel[3];
    end
    else begin
    cell_r <= 1'b0;
    sc_r <= 3'd0;
    owner_r <= 1'b0;
    end
    clear_t_r <= clear_t;

//    消行压缩: 1~4 行只要该行参与消行就持续收缩, 不受白闪相位影响
    clear_shrink_r <= (clear_t) && (line_t[R_num]);
    flash_r <= (clear_t) && (line_t[R_num]) && (!clear_flash);
    chs_margin_r <= chs_margin;
    chs_inner_r <= chs_inner;
    chs_text_r <= chs_text;
    chs_dim_r <= chs_dim;
    chs_breath_r <= chs_breath;
    Piece2_r <= Piece2;
    ghost2_r <= ghost2;
    type2_r <= type2;
    type_t2_r <= type_t2;
    land_we2_r <= land_we2;
    next2_r <= next2;
    lbl_r <= lbl_lit || top_rule_lit;
    rule1_r <= rule1_lit;
    rule2_r <= rule2_lit;
    next_slot_r <= next_slot;
    hold_slot_r <= hold_slot;
    lvd_r <= lvd_all_lit;
    lb_lv_r <= lb_lv;
    fin_r <= Finalize;
    result_num_r <= result_num_lit; result_num_sel_r <= result_num_sel;
    result_mode_r <= lb_mode && lbl_lit; result_label_r <= lb_result_lbl && lbl_lit;
    result_rule_r <= result_score_rule || result_level_rule || result_lines_rule || result_time_rule;
    result_rule_sel_r <= result_rule_sel; result_colon_r <= result_colon_lit;
    hint_type_r <= hint_type; psel_r <= psel;
    story_outer_color_r <= story_outer_color;
    story_inner_color_r <= story_inner_color;
    story_menu_color_r <= story_menu_color;
    hint_hit_r <= hint_show && !duo && Playing && hint_match && !hint_occupied_now;
    end
    end

//    UI 特效: 60Hz 节拍 + 落锁脉冲(E1) / 升级闪白(E2)
    parameter [20:0]EFF_TICK = 21'd1_237_499;  //仿真可覆盖
    reg [20:0]eff_cnt;
    wire eff_tick = (eff_cnt == EFF_TICK);
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    eff_cnt <= 21'd0;
    else if(eff_tick)
    eff_cnt <= 21'd0;
    else
    eff_cnt <= eff_cnt + 21'd1;
    end
    reg [1:0]lf1, lf2, lvf, nf1, nf2, hf, scf;
    reg [2:0]rotf1, rotf2;
    reg [1:0]mbl1, mbl2, mbr1, mbr2;
    reg [1:0]hdf1, hdf2;
    (* DONT_TOUCH = "TRUE" *) reg [4:0]pcmin1_r, pcmax1_r, prmin1_r, prmax1_r;
    (* DONT_TOUCH = "TRUE" *) reg [4:0]pcmin2_r, pcmax2_r, prmin2_r, prmax2_r;
    reg [2:0]lvl_d;
    reg [2:0]hold_d;
    reg [19:0]score_d;
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    lf1 <= 2'd0;
    lf2 <= 2'd0;
    lvf <= 2'd0;
    nf1 <= 2'd0;
    nf2 <= 2'd0;
    hf <= 2'd0;
    scf <= 2'd0;
    rotf1 <= 3'd0;
    rotf2 <= 3'd0;
    mbl1 <= 2'd0;
    mbl2 <= 2'd0;
    mbr1 <= 2'd0;
    mbr2 <= 2'd0;
    hdf1 <= 2'd0;
    hdf2 <= 2'd0;
    lvl_d <= 3'd0;
    hold_d <= 3'd0;
    score_d <= 20'd0;
    end
    else begin
    lvl_d <= speed_level;
    hold_d <= hold_type;
    score_d <= score;
    if(blk_rot1)
    rotf1 <= 3'd6;
    else if(eff_tick && (rotf1 != 3'd0))
    rotf1 <= rotf1 - 3'd1;
    if(blk_rot2)
    rotf2 <= 3'd6;
    else if(eff_tick && (rotf2 != 3'd0))
    rotf2 <= rotf2 - 3'd1;
    if(blk_l1)
    mbl1 <= 2'd2;
    else if(eff_tick && (mbl1 != 2'd0))
    mbl1 <= mbl1 - 2'd1;
    if(blk_r1)
    mbr1 <= 2'd2;
    else if(eff_tick && (mbr1 != 2'd0))
    mbr1 <= mbr1 - 2'd1;
    if(blk_l2)
    mbl2 <= 2'd2;
    else if(eff_tick && (mbl2 != 2'd0))
    mbl2 <= mbl2 - 2'd1;
    if(blk_r2)
    mbr2 <= 2'd2;
    else if(eff_tick && (mbr2 != 2'd0))
    mbr2 <= mbr2 - 2'd1;
    if(snd_hard1)
    hdf1 <= 2'd2;
    else if(eff_tick && (hdf1 != 2'd0))
    hdf1 <= hdf1 - 2'd1;
    if(snd_hard2)
    hdf2 <= 2'd2;
    else if(eff_tick && (hdf2 != 2'd0))
    hdf2 <= hdf2 - 2'd1;
    if(lock_we)
    lf1 <= 2'd3;
    else if(eff_tick && (lf1 != 2'd0))
    lf1 <= lf1 - 2'd1;
    if(lock_we2)
    lf2 <= 2'd3;
    else if(eff_tick && (lf2 != 2'd0))
    lf2 <= lf2 - 2'd1;
    if(speed_level != lvl_d)
    lvf <= 2'd3;
    else if(eff_tick && (lvf != 2'd0))
    lvf <= lvf - 2'd1;
    if(land_we)
    nf1 <= 2'd2;
    else if(eff_tick && (nf1 != 2'd0))
    nf1 <= nf1 - 2'd1;
    if(land_we2)
    nf2 <= 2'd2;
    else if(eff_tick && (nf2 != 2'd0))
    nf2 <= nf2 - 2'd1;
    if(hold_type != hold_d)
    hf <= 2'd2;
    else if(eff_tick && (hf != 2'd0))
    hf <= hf - 2'd1;
    if(score != score_d)
    scf <= 2'd3;
    else if(eff_tick && (scf != 2'd0))
    scf <= scf - 2'd1;
    end
    end
    wire lflash1 = (lf1 != 2'd0);
    wire lflash2 = (lf2 != 2'd0);
    wire lvflash = (lvf != 2'd0);
    wire nflash1 = (nf1 != 2'd0);
    wire nflash2 = (nf2 != 2'd0);
    wire hflash = (hf != 2'd0);
    wire scflash = (scf != 2'd0);

//    预览槽 32px 点阵(只在槽位内, 优先级低于预览方块)
    wire dx1 = (((hcounter - XPN1) & 11'd31) == 11'd31);
    wire dx2 = (((hcounter - XPN2) & 11'd31) == 11'd31);
    wire dy1 = (((vcounter - YNEXT) & 11'd31) == 11'd31);
    wire dy2 = (((vcounter - YHOLD) & 11'd31) == 11'd31);
    wire slot_dot = (next_slot_r && dy1 && (dx1 || dx2)) || (hold_slot_r && dy2 && (dx1 || dx2));

    parameter CYAN = 24'h00CCFF,  //青色I
               LIGHT_CYAN = 24'h99EEFF,  //浅青色I
               PURPPLE = 24'h9933CC,  //紫色T
               LIGHT_PURPPLE = 24'hD9B3E6,  //浅紫色T
               YELLOW = 24'hFFF_F00,  //黄色O
               LIGHT_YELLOW = 24'hFFFF99,  //浅黄色O
               RED = 24'hE63946,  //红色S
               LIGHT_RED = 24'hFFB3B9,  //浅红色S
               GREEN = 24'h55A630,  //绿色Z
               LIGHT_GREEN = 24'hBDE0AA,  //浅绿色Z
               ORANGE = 24'hF77F24,  //橙色L
               LIGHT_ORANGE = 24'hFFD9B3,  //浅橙色L
               PINK = 24'hFF4DA6,  //亮粉色J
               LIGHT_PINK = 24'hFFB3D9,  //浅粉色J
               BLACK = 24'h000_000,  //黑色
               WHITE = 24'hFFF_FFF,  //白色
               DARK_I = 24'h04_63_7E,
               DARK_T = 24'h47_1F_67,
               DARK_O = 24'h74_79_0D,
               DARK_S = 24'h69_22_2C,
               DARK_Z = 24'h29_52_23,
               DARK_L = 24'h71_41_1D,
               DARK_J = 24'h74_2B_56,
               P1_SOFT = 24'h6B_F0_FF,
               P2_SOFT = 24'hFF_98_CB;

//    危险灯带与两侧供能轨
    wire [23:0]col_mask = duo ? 24'hFFFFFF : 24'h0FFFFF;
    wire row0_any = |(row_f[0] & col_mask);
    wire row1_any = |(row_f[1] & col_mask);
    wire row2_any = |(row_f[2] & col_mask);
    wire row3_any = |(row_f[3] & col_mask);
    wire row4_any = |(row_f[4] & col_mask);
    wire row5_any = |(row_f[5] & col_mask);
    wire row6_any = |(row_f[6] & col_mask);
    wire danger_state = row0_any || row1_any || row2_any || row3_any;
    wire caution_state = danger_state || row4_any || row5_any || row6_any;
    assign danger_lvl = danger_state ? 2'd2 : (caution_state ? 2'd1 : 2'd0);
    wire danger_active = (danger_lvl != 2'd0);
    wire [23:0]danger_color = (danger_lvl == 2'd2) ? RED : ORANGE;
    wire [10:0]danger_dx = hcounter - 11'd321;
    wire [10:0]danger_phase = danger_dx % 11'd24;
    wire danger_line = danger_active && (hcounter >= 11'd321) && (hcounter < XR) &&
                       (vcounter >= 11'd77) && (vcounter < 11'd81) &&
                       (danger_phase < 11'd16);
    wire danger_gap = danger_active && (hcounter >= 11'd321) && (hcounter < XR) &&
                      (vcounter >= 11'd77) && (vcounter < 11'd81) &&
                      (danger_phase >= 11'd16);
    wire danger_dot = danger_active && in_field &&
                      (((hcounter - 11'd321) & 11'd15) == 11'd0) &&
                      (((vcounter - 11'd81) & 11'd15) == 11'd0) &&
                      ((danger_lvl == 2'd2) ? (R_num <= 5'd3) : (R_num <= 5'd6));
    wire rail_l_lit = (hcounter >= 11'd313) && (hcounter <= 11'd316) &&
                      (vcounter >= 11'd81) && (vcounter < 11'd721);
    wire rail_r_lit = (hcounter >= (XR + 11'd4)) && (hcounter <= (XR + 11'd7)) &&
                      (vcounter >= 11'd81) && (vcounter < 11'd721);
    wire rail_l_white = lflash1 || danger_active || (mbl1 != 2'd0) || (mbl2 != 2'd0);
    wire rail_r_white = (duo ? lflash2 : lflash1) || danger_active || (mbr1 != 2'd0) || (mbr2 != 2'd0);
    wire level_hot = (speed_level >= 3'd5);
    wire level_critical = (speed_level == 3'd7) || danger_active;
    wire [23:0]level_frame_color = level_critical ? RED : (level_hot ? ORANGE : 24'h606060);
    wire level_alert_lit = level_hot &&
        (((hcounter >= 11'd259) && (hcounter <= 11'd262)) ||
         ((hcounter >= 11'd307) && (hcounter <= 11'd310))) &&
        (((vcounter - 11'd88) & 11'd31) < 11'd8);
    wire [23:0]level_alert_color = level_critical ? RED : ORANGE;

//    Impact Glass 边框与 SOFT 高光
    wire block_light = (glx_r == 11'd1) || (gly_r == 11'd1);
    wire block_soft = (glx_r >= 11'd6) && (glx_r <= 11'd11) && (gly_r == 11'd26);  //左下6x1柔光
    wire block_dark = (glx_r == 11'd30) || (gly_r == 11'd30);
    wire block_glint = (((gly_r == 11'd2) || (gly_r == 11'd3)) && (glx_r >= 11'd2) && (glx_r <= 11'd9)) ||
                       (((glx_r == 11'd2) || (glx_r == 11'd3)) && (gly_r >= 11'd2) && (gly_r <= 11'd9)) ||
                       ((glx_r >= 11'd3) && (glx_r <= 11'd4) && (gly_r >= 11'd3) && (gly_r <= 11'd4));
    wire pv_light = (pvx_r == 11'd1) || (pvy_r == 11'd1);
    wire pv_soft = (pvx_r >= 11'd6) && (pvx_r <= 11'd11) && (pvy_r == 11'd26);  //预览左下6x1柔光
    wire pv_dark = (pvx_r == 11'd30) || (pvy_r == 11'd30);
    wire pv_glint = (((pvy_r == 11'd2) || (pvy_r == 11'd3)) && (pvx_r >= 11'd2) && (pvx_r <= 11'd9)) ||
                    (((pvx_r == 11'd2) || (pvx_r == 11'd3)) && (pvy_r >= 11'd2) && (pvy_r <= 11'd9)) ||
                    ((pvx_r >= 11'd3) && (pvx_r <= 11'd4) && (pvy_r >= 11'd3) && (pvy_r <= 11'd4));

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    pcmin1_r <= 5'd0; pcmax1_r <= 5'd0; prmin1_r <= 5'd0; prmax1_r <= 5'd0;
    pcmin2_r <= 5'd0; pcmax2_r <= 5'd0; prmin2_r <= 5'd0; prmax2_r <= 5'd0;
    end
    else begin
    pcmin1_r <= piece_cmin1; pcmax1_r <= piece_cmax1; prmin1_r <= piece_rmin1; prmax1_r <= piece_rmax1;
    pcmin2_r <= piece_cmin2; pcmax2_r <= piece_cmax2; prmin2_r <= piece_rmin2; prmax2_r <= piece_rmax2;
    end
    end
    wire rot_pulse1 = (rotf1 == 3'd6) || (rotf1 == 3'd5) || (rotf1 == 3'd3) || (rotf1 == 3'd2) || (rotf1 == 3'd1);
    wire rot_pulse2 = (rotf2 == 3'd6) || (rotf2 == 3'd5) || (rotf2 == 3'd3) || (rotf2 == 3'd2) || (rotf2 == 3'd1);
    wire [10:0]pcl1 = 11'd321 + {pcmin1_r, 5'd0};
    wire [10:0]pcr1 = 11'd321 + {pcmax1_r, 5'd0} + 11'd31;
    wire [10:0]ptp1 = 11'd81 + {prmin1_r, 5'd0};
    wire [10:0]pbt1 = 11'd81 + {prmax1_r, 5'd0} + 11'd31;
    wire [10:0]pcl2 = 11'd321 + {pcmin2_r, 5'd0};
    wire [10:0]pcr2 = 11'd321 + {pcmax2_r, 5'd0} + 11'd31;
    wire [10:0]ptp2 = 11'd81 + {prmin2_r, 5'd0};
    wire [10:0]pbt2 = 11'd81 + {prmax2_r, 5'd0} + 11'd31;
    wire rot_corner1 = rot_pulse1 && (pcmax1_r >= pcmin1_r) &&
        (((hcounter >= pcl1) && (hcounter < pcl1 + 11'd6) && (vcounter == ptp1)) ||
         ((vcounter >= ptp1) && (vcounter < ptp1 + 11'd6) && (hcounter == pcl1)) ||
         ((hcounter >= pcr1 - 11'd5) && (hcounter <= pcr1) && (vcounter == ptp1)) ||
         ((vcounter >= ptp1) && (vcounter < ptp1 + 11'd6) && (hcounter == pcr1)) ||
         ((hcounter >= pcl1) && (hcounter < pcl1 + 11'd6) && (vcounter == pbt1)) ||
         ((vcounter >= pbt1 - 11'd5) && (vcounter <= pbt1) && (hcounter == pcl1)) ||
         ((hcounter >= pcr1 - 11'd5) && (hcounter <= pcr1) && (vcounter == pbt1)) ||
         ((vcounter >= pbt1 - 11'd5) && (vcounter <= pbt1) && (hcounter == pcr1)));
    wire rot_corner2 = duo && rot_pulse2 && (pcmax2_r >= pcmin2_r) &&
        (((hcounter >= pcl2) && (hcounter < pcl2 + 11'd6) && (vcounter == ptp2)) ||
         ((vcounter >= ptp2) && (vcounter < ptp2 + 11'd6) && (hcounter == pcl2)) ||
         ((hcounter >= pcr2 - 11'd5) && (hcounter <= pcr2) && (vcounter == ptp2)) ||
         ((vcounter >= ptp2) && (vcounter < ptp2 + 11'd6) && (hcounter == pcr2)) ||
         ((hcounter >= pcl2) && (hcounter < pcl2 + 11'd6) && (vcounter == pbt2)) ||
         ((vcounter >= pbt2 - 11'd5) && (vcounter <= pbt2) && (hcounter == pcl2)) ||
         ((hcounter >= pcr2 - 11'd5) && (hcounter <= pcr2) && (vcounter == pbt2)) ||
         ((vcounter >= pbt2 - 11'd5) && (vcounter <= pbt2) && (hcounter == pcr2)));
    wire [10:0]hdx1 = (pcl1 + pcr1) >> 1;
    wire [10:0]hdx2 = (pcl2 + pcr2) >> 1;
    wire hard_fx1 = (hdf1 != 2'd0) &&
        (hcounter >= hdx1 - 11'd6) && (hcounter <= hdx1 + 11'd6) &&
        (vcounter >= pbt1 - 11'd6) && (vcounter <= pbt1 + 11'd6) &&
        ((hcounter == hdx1 - 11'd6) || (hcounter == hdx1 + 11'd6) ||
         (vcounter == pbt1 - 11'd6) || (vcounter == pbt1 + 11'd6));
    wire hard_fx2 = duo && (hdf2 != 2'd0) &&
        (hcounter >= hdx2 - 11'd6) && (hcounter <= hdx2 + 11'd6) &&
        (vcounter >= pbt2 - 11'd6) && (vcounter <= pbt2 + 11'd6) &&
        ((hcounter == hdx2 - 11'd6) || (hcounter == hdx2 + 11'd6) ||
         (vcounter == pbt2 - 11'd6) || (vcounter == pbt2 + 11'd6));
    wire [4:0]lk_c1 = cc_t[lock_idx];
    wire [4:0]lk_r1 = rr_t[lock_idx];
    wire [4:0]lk_c2 = cc_t2[lock_idx2];
    wire [4:0]lk_r2 = rr_t2[lock_idx2];
    wire lock_rim1 = lflash1 && (C_num == lk_c1) && (R_num == lk_r1) && piece_round_r &&
        (((glx_r == 11'd1) || (glx_r == 11'd2) || (glx_r == 11'd29) || (glx_r == 11'd30)) ||
         ((gly_r == 11'd1) || (gly_r == 11'd2) || (gly_r == 11'd29) || (gly_r == 11'd30)));
    wire lock_rim2 = duo && lflash2 && (C_num == lk_c2) && (R_num == lk_r2) && piece_round_r &&
        (((glx_r == 11'd1) || (glx_r == 11'd2) || (glx_r == 11'd29) || (glx_r == 11'd30)) ||
         ((gly_r == 11'd1) || (gly_r == 11'd2) || (gly_r == 11'd29) || (gly_r == 11'd30)));
    wire [10:0]brl1 = pcl1 - 11'd9;
    wire [10:0]brr1 = pcr1 + 11'd9;
    wire [10:0]brt1 = ptp1 - 11'd9;
    wire [10:0]brb1 = pbt1 + 11'd9;
    wire [10:0]brl2 = pcl2 - 11'd9;
    wire [10:0]brr2 = pcr2 + 11'd9;
    wire [10:0]brt2 = ptp2 - 11'd9;
    wire [10:0]brb2 = pbt2 + 11'd9;
    wire bracket1 = duo && (pcmax1_r >= pcmin1_r) &&
        (((hcounter >= brl1) && (hcounter < brl1 + 11'd18) && (vcounter >= brt1) && (vcounter < brt1 + 11'd2)) ||
         ((vcounter >= brt1) && (vcounter < brt1 + 11'd18) && (hcounter >= brl1) && (hcounter < brl1 + 11'd2)) ||
         ((hcounter >= brr1 - 11'd17) && (hcounter <= brr1) && (vcounter >= brt1) && (vcounter < brt1 + 11'd2)) ||
         ((vcounter >= brt1) && (vcounter < brt1 + 11'd18) && (hcounter > brr1 - 11'd2) && (hcounter <= brr1)) ||
         ((hcounter >= brl1) && (hcounter < brl1 + 11'd18) && (vcounter > brb1 - 11'd2) && (vcounter <= brb1)) ||
         ((vcounter >= brb1 - 11'd17) && (vcounter <= brb1) && (hcounter >= brl1) && (hcounter < brl1 + 11'd2)) ||
         ((hcounter >= brr1 - 11'd17) && (hcounter <= brr1) && (vcounter > brb1 - 11'd2) && (vcounter <= brb1)) ||
         ((vcounter >= brb1 - 11'd17) && (vcounter <= brb1) && (hcounter > brr1 - 11'd2) && (hcounter <= brr1)));
    wire bracket2 = duo && (pcmax2_r >= pcmin2_r) &&
        (((hcounter >= brl2) && (hcounter < brl2 + 11'd18) && (vcounter >= brt2) && (vcounter < brt2 + 11'd2)) ||
         ((vcounter >= brt2) && (vcounter < brt2 + 11'd18) && (hcounter >= brl2) && (hcounter < brl2 + 11'd2)) ||
         ((hcounter >= brr2 - 11'd17) && (hcounter <= brr2) && (vcounter >= brt2) && (vcounter < brt2 + 11'd2)) ||
         ((vcounter >= brt2) && (vcounter < brt2 + 11'd18) && (hcounter > brr2 - 11'd2) && (hcounter <= brr2)) ||
         ((hcounter >= brl2) && (hcounter < brl2 + 11'd18) && (vcounter > brb2 - 11'd2) && (vcounter <= brb2)) ||
         ((vcounter >= brb2 - 11'd17) && (vcounter <= brb2) && (hcounter >= brl2) && (hcounter < brl2 + 11'd2)) ||
         ((hcounter >= brr2 - 11'd17) && (hcounter <= brr2) && (vcounter > brb2 - 11'd2) && (vcounter <= brb2)) ||
         ((vcounter >= brb2 - 11'd17) && (vcounter <= brb2) && (hcounter > brr2 - 11'd2) && (hcounter <= brr2)));

    always@(*)begin
    case(hint_type_r)
    0:hint_color=24'h00CCFF; 1:hint_color=24'h9933CC; 2:hint_color=24'hFFFF00;
    3:hint_color=24'hE63946; 4:hint_color=24'h55A630; 5:hint_color=24'hF77F24;
    6:hint_color=24'hFF4DA6; default:hint_color=24'h0;
    endcase
    end

    function [4:0] mf_glyph;
    input [4:0] ch;
    input [2:0] row;
    begin
        case(ch)
        5'd0: case(row) 0:mf_glyph=5'b11110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b11110; 4:mf_glyph=5'b10000; 5:mf_glyph=5'b10000; default:mf_glyph=5'b10000; endcase
        5'd1: case(row) 0:mf_glyph=5'b00100; 1:mf_glyph=5'b01100; 2:mf_glyph=5'b00100; 3:mf_glyph=5'b00100; 4:mf_glyph=5'b00100; 5:mf_glyph=5'b00100; default:mf_glyph=5'b01110; endcase
        5'd2: case(row) 0:mf_glyph=5'b01110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b00001; 3:mf_glyph=5'b00010; 4:mf_glyph=5'b00100; 5:mf_glyph=5'b01000; default:mf_glyph=5'b11111; endcase
        5'd3: case(row) 0:mf_glyph=5'b01111; 1:mf_glyph=5'b10000; 2:mf_glyph=5'b10000; 3:mf_glyph=5'b01110; 4:mf_glyph=5'b00001; 5:mf_glyph=5'b00001; default:mf_glyph=5'b11110; endcase
        5'd4: case(row) 0:mf_glyph=5'b01111; 1:mf_glyph=5'b10000; 2:mf_glyph=5'b10000; 3:mf_glyph=5'b10000; 4:mf_glyph=5'b10000; 5:mf_glyph=5'b10000; default:mf_glyph=5'b01111; endcase
        5'd5: case(row) 0:mf_glyph=5'b01110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b10001; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b01110; endcase
        5'd6: case(row) 0:mf_glyph=5'b11110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b11110; 4:mf_glyph=5'b10100; 5:mf_glyph=5'b10010; default:mf_glyph=5'b10001; endcase
        5'd7: case(row) 0:mf_glyph=5'b11111; 1:mf_glyph=5'b10000; 2:mf_glyph=5'b10000; 3:mf_glyph=5'b11110; 4:mf_glyph=5'b10000; 5:mf_glyph=5'b10000; default:mf_glyph=5'b11111; endcase
        5'd8: case(row) 0:mf_glyph=5'b11110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b10001; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b11110; endcase
        5'd9: case(row) 0:mf_glyph=5'b10001; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b10001; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b01110; endcase
        5'd10:case(row) 0:mf_glyph=5'b01110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10011; 3:mf_glyph=5'b10101; 4:mf_glyph=5'b11001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b01110; endcase
        5'd11:case(row) 0:mf_glyph=5'b11111; 1:mf_glyph=5'b00001; 2:mf_glyph=5'b00010; 3:mf_glyph=5'b00100; 4:mf_glyph=5'b01000; 5:mf_glyph=5'b01000; default:mf_glyph=5'b01000; endcase
        5'd12:case(row) 0:mf_glyph=5'b10001; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b11111; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b10001; endcase
        5'd13:case(row) 0:mf_glyph=5'b01110; 1:mf_glyph=5'b10001; 2:mf_glyph=5'b10001; 3:mf_glyph=5'b11111; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b10001; endcase
        5'd14:case(row) 0:mf_glyph=5'b10001; 1:mf_glyph=5'b11001; 2:mf_glyph=5'b10101; 3:mf_glyph=5'b10011; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b10001; endcase
        5'd15:case(row) 0:mf_glyph=5'b11111; 1:mf_glyph=5'b00100; 2:mf_glyph=5'b00100; 3:mf_glyph=5'b00100; 4:mf_glyph=5'b00100; 5:mf_glyph=5'b00100; default:mf_glyph=5'b00100; endcase
        5'd16:case(row) 0:mf_glyph=5'b11111; 1:mf_glyph=5'b00100; 2:mf_glyph=5'b00100; 3:mf_glyph=5'b00100; 4:mf_glyph=5'b00100; 5:mf_glyph=5'b00100; default:mf_glyph=5'b11111; endcase
        5'd17:case(row) 0:mf_glyph=5'b10001; 1:mf_glyph=5'b11011; 2:mf_glyph=5'b10101; 3:mf_glyph=5'b10101; 4:mf_glyph=5'b10001; 5:mf_glyph=5'b10001; default:mf_glyph=5'b10001; endcase
        default:mf_glyph=5'd0;
        endcase
    end
    endfunction

    function [4:0] mf_text_char;
    input [2:0] text_id;
    input [3:0] idx;
    begin
        mf_text_char=5'd0;
        case(text_id)
        0:case(idx) 0:mf_text_char=5'd0; 1:mf_text_char=5'd1; default:mf_text_char=5'd0; endcase
        1:case(idx) 0:mf_text_char=5'd0; 1:mf_text_char=5'd2; default:mf_text_char=5'd0; endcase
        2:case(idx) 0:mf_text_char=5'd3; 1:mf_text_char=5'd4; 2:mf_text_char=5'd5; 3:mf_text_char=5'd6; default:mf_text_char=5'd7; endcase
        3:case(idx) 0:mf_text_char=5'd8; 1:mf_text_char=5'd9; default:mf_text_char=5'd5; endcase
        4:case(idx) 0:mf_text_char=5'd4; 1:mf_text_char=5'd5; 2:mf_text_char=5'd6; 3:mf_text_char=5'd7; 4:mf_text_char=5'd10; default:mf_text_char=5'd11; endcase
        5:case(idx) 0:mf_text_char=5'd3; 1:mf_text_char=5'd12; 2:mf_text_char=5'd13; 3:mf_text_char=5'd6; 4:mf_text_char=5'd7; default:mf_text_char=5'd8; endcase
        6:case(idx)
          0:mf_text_char=5'd4; 1:mf_text_char=5'd5; 2:mf_text_char=5'd14; 3:mf_text_char=5'd15; 4:mf_text_char=5'd13; 5:mf_text_char=5'd14;
          6:mf_text_char=5'd16; 7:mf_text_char=5'd14; 8:mf_text_char=5'd17; 9:mf_text_char=5'd7; 10:mf_text_char=5'd14; default:mf_text_char=5'd15;
          endcase
        default:mf_text_char=5'd0;
        endcase
    end
    endfunction

    function mf_text_px;
    input [2:0] text_id;
    input [5:0] lx;
    input [3:0] ly;
    reg scaled;
    reg [5:0] rem;
    reg [3:0] idx;
    reg [3:0] row;
    reg [2:0] col;
    reg [4:0] pattern;
    begin
        rem=lx;
        idx=4'd0;
        scaled=(text_id<3'd4);
        if(scaled)begin
            if(lx>=6'd44)begin idx=4'd4; rem=lx-6'd44; end
            else if(lx>=6'd33)begin idx=4'd3; rem=lx-6'd33; end
            else if(lx>=6'd22)begin idx=4'd2; rem=lx-6'd22; end
            else if(lx>=6'd11)begin idx=4'd1; rem=lx-6'd11; end
            row={1'b0,ly[3:1]};
            col=rem[3:1];
            if(rem>=6'd10)col=3'd7;
            if(ly>4'd13)col=3'd7;
        end
        else begin
            if(lx>=6'd60)begin idx=4'd10; rem=lx-6'd60; end
            else if(lx>=6'd54)begin idx=4'd9; rem=lx-6'd54; end
            else if(lx>=6'd48)begin idx=4'd8; rem=lx-6'd48; end
            else if(lx>=6'd42)begin idx=4'd7; rem=lx-6'd42; end
            else if(lx>=6'd36)begin idx=4'd6; rem=lx-6'd36; end
            else if(lx>=6'd30)begin idx=4'd5; rem=lx-6'd30; end
            else if(lx>=6'd24)begin idx=4'd4; rem=lx-6'd24; end
            else if(lx>=6'd18)begin idx=4'd3; rem=lx-6'd18; end
            else if(lx>=6'd12)begin idx=4'd2; rem=lx-6'd12; end
            else if(lx>=6'd6)begin idx=4'd1; rem=lx-6'd6; end
            row={1'b0,ly[2:0]};
            col=rem[2:0];
            if(rem>=6'd5)col=3'd7;
            if(ly>4'd6)col=3'd7;
        end
        if(idx>((text_id==3'd0||text_id==3'd1)?4'd1:(text_id==3'd2)?4'd4:(text_id==3'd3)?4'd2:(text_id==3'd4||text_id==3'd5)?4'd5:4'd10))col=3'd7;
        if((col<3'd5)&&(row<4'd7))begin
            pattern=mf_glyph(mf_text_char(text_id,idx),row[2:0]);
            mf_text_px=pattern[4-col];
        end
        else
            mf_text_px=1'b0;
    end
    endfunction

    wire [5:0]p1_lx=hcounter-XP1LBL;
    wire [5:0]p2_lx=hcounter-XP2LBL;
    wire [5:0]score_lx=hcounter-XSCORELBL;
    wire [5:0]duo_lx=hcounter-11'd244;
    wire [5:0]core_lx=hcounter-11'd20;
    wire [3:0]p1_ly=vcounter-11'd44;
    wire [3:0]score_ly=vcounter-11'd24;
    wire [3:0]duo_ly=vcounter-11'd620;
    wire [3:0]core1_ly=vcounter-11'd520;
    wire [3:0]core2_ly=vcounter-11'd552;
    wire [3:0]core3_ly=vcounter-11'd584;
    wire p1_label_px = !choose && (hcounter >= XP1LBL) && (hcounter < XP1LBL + 11'd21) &&
                       (vcounter >= 11'd44) && (vcounter < 11'd58) &&
                       mf_text_px(3'd0,p1_lx,p1_ly);
    wire p2_label_px = !choose && duo && (hcounter >= XP2LBL) && (hcounter < XP2LBL + 11'd21) &&
                       (vcounter >= 11'd44) && (vcounter < 11'd58) &&
                       mf_text_px(3'd1,p2_lx,p1_ly);
    wire score_label_px = !choose && (hcounter >= XSCORELBL) && (hcounter < XSCORELBL + 11'd54) &&
                          (vcounter >= 11'd24) && (vcounter < 11'd38) &&
                          mf_text_px(3'd2,score_lx,score_ly);
    wire duo_label_px = !choose && duo && (hcounter >= 11'd244) && (hcounter < 11'd276) &&
                        (vcounter >= 11'd620) && (vcounter < 11'd634) &&
                        mf_text_px(3'd3,duo_lx,duo_ly);
    wire core1_label_px = (hcounter >= 11'd20) && (hcounter < 11'd55) &&
                          (vcounter >= 11'd520) && (vcounter < 11'd527) &&
                          mf_text_px(3'd4,core_lx,core1_ly);
    wire core2_label_px = (hcounter >= 11'd20) && (hcounter < 11'd55) &&
                          (vcounter >= 11'd552) && (vcounter < 11'd559) &&
                          mf_text_px(3'd5,core_lx,core2_ly);
    wire core3_label_px = (hcounter >= 11'd20) && (hcounter < 11'd85) &&
                          (vcounter >= 11'd584) && (vcounter < 11'd591) &&
                          mf_text_px(3'd6,core_lx,core3_ly);

//    像素命中码：只保留优先级判定，颜色在下一级一次性展开。
//    这样避免把 24 位颜色常量复制进整条优先链，降低 LUT 与关键路径级数。
    localparam [6:0]
        PS_BLACK            = 7'd0,
        PS_MENU_DARK        = 7'd1,
        PS_MENU_CYAN        = 7'd2,
        PS_MENU_TEXT_DIM    = 7'd3,
        PS_MENU_TEXT        = 7'd4,
        PS_MENU_BG          = 7'd5,
        PS_OVER_0           = 7'd6,
        PS_OVER_1           = 7'd7,
        PS_OVER_2           = 7'd8,
        PS_OVER_3           = 7'd9,
        PS_OVER_4           = 7'd10,
        PS_OVER_5           = 7'd11,
        PS_OVER_6           = 7'd12,
        PS_OVER_7           = 7'd13,
        PS_OVER_8           = 7'd14,
        PS_OVER_9_ON        = 7'd15,
        PS_OVER_9_OFF       = 7'd16,
        PS_OVER_DEFAULT     = 7'd17,
        PS_RES_MODE_SOLO    = 7'd18,
        PS_RES_MODE_DUO     = 7'd19,
        PS_RES_LABEL        = 7'd20,
        PS_RES_NUM_SCORE    = 7'd21,
        PS_RES_NUM_LEVEL    = 7'd22,
        PS_RES_NUM_LINES    = 7'd23,
        PS_RES_NUM_TIME     = 7'd24,
        PS_RES_RULE_SCORE   = 7'd25,
        PS_RES_RULE_LEVEL   = 7'd26,
        PS_RES_RULE_LINES   = 7'd27,
        PS_RES_RULE_TIME    = 7'd28,
        PS_RES_COLON        = 7'd29,
        PS_RES_DIM          = 7'd30,
        PS_RES_BG_FIELD     = 7'd31,
        PS_RES_BG_BLACK     = 7'd32,
        PS_BREACH           = 7'd33,
        PS_LVFRAME_GRAY     = 7'd34,
        PS_LVFRAME_ORANGE   = 7'd35,
        PS_LVFRAME_RED      = 7'd36,
        PS_LVALERT_ORANGE   = 7'd37,
        PS_LVALERT_RED      = 7'd38,
        PS_LBL_LV           = 7'd39,
        PS_LBL_GRAY         = 7'd40,
        PS_LBL_DIM          = 7'd41,
        PS_RULE1_CYAN       = 7'd42,
        PS_RULE1_SOLO_GRAY  = 7'd43,
        PS_RULE1_WHITE      = 7'd44,
        PS_RULE1_DIM        = 7'd45,
        PS_RULE2_PINK       = 7'd46,
        PS_RULE2_WHITE      = 7'd47,
        PS_RULE2_DIM        = 7'd48,
        PS_LV_MARGIN        = 7'd49,
        PS_LV_WHITE         = 7'd50,
        PS_LV_SEG           = 7'd51,
        PS_LV_UNLIT         = 7'd52,
        PS_LVD_COLOR        = 7'd53,
        PS_LVD_WHITE        = 7'd54,
        PS_SLOT_BG          = 7'd55,
        PS_PREVIEW_WHITE    = 7'd56,
        PS_PREVIEW_LIGHT_H  = 7'd57,
        PS_PREVIEW_DARK_H   = 7'd58,
        PS_PREVIEW_BASE_H   = 7'd59,
        PS_PREVIEW_LIGHT_N1 = 7'd60,
        PS_PREVIEW_DARK_N1  = 7'd61,
        PS_PREVIEW_BASE_N1  = 7'd62,
        PS_PREVIEW_LIGHT_N2 = 7'd63,
        PS_PREVIEW_DARK_N2  = 7'd64,
        PS_PREVIEW_BASE_N2  = 7'd65,
        PS_SLOT_DOT         = 7'd66,
        PS_HOLD_SLOT        = 7'd67,
        PS_NEXT_SLOT        = 7'd68,
        PS_SCORE_FLASH      = 7'd69,
        PS_SCORE_WHITE      = 7'd70,
        PS_TIME_WHITE       = 7'd71,
        PS_RAIL_L_CYAN      = 7'd72,
        PS_RAIL_L_WHITE     = 7'd73,
        PS_RAIL_R_PINK      = 7'd74,
        PS_RAIL_R_CYAN      = 7'd75,
        PS_RAIL_R_WHITE     = 7'd76,
        PS_DANGER           = 7'd77,
        PS_MARGIN_WHITE     = 7'd78,
        PS_ROT1             = 7'd79,
        PS_ROT2             = 7'd80,
        PS_BRACKET1         = 7'd81,
        PS_BRACKET2         = 7'd82,
        PS_PIECE_CORNER     = 7'd83,
        PS_PIECE_LAND       = 7'd84,
        PS_PIECE_GLINT      = 7'd85,
        PS_PIECE_LIGHT_DUO  = 7'd86,
        PS_PIECE_LIGHT      = 7'd87,
        PS_PIECE_DARK       = 7'd88,
        PS_PIECE_BASE       = 7'd89,
        PS_GHOST_LIGHT      = 7'd90,
        PS_GHOST_BG         = 7'd91,
        PS_HINT             = 7'd92,
        PS_RIM_WHITE        = 7'd93,
        PS_CELL_CORNER      = 7'd94,
        PS_CELL_CLEAR_BASE  = 7'd95,
        PS_CELL_SPARK       = 7'd96,
        PS_CELL_RING        = 7'd97,
        PS_CELL_FLASH       = 7'd98,
        PS_CELL_SHRINK      = 7'd99,
        PS_CELL_GLINT       = 7'd100,
        PS_CELL_LIGHT_DUO   = 7'd101,
        PS_CELL_LIGHT       = 7'd102,
        PS_CELL_DARK        = 7'd103,
        PS_CELL_BASE        = 7'd104,
        PS_PIECE2_CORNER    = 7'd105,
        PS_PIECE2_LAND      = 7'd106,
        PS_PIECE2_GLINT     = 7'd107,
        PS_PIECE2_LIGHT_DUO = 7'd108,
        PS_PIECE2_LIGHT     = 7'd109,
        PS_PIECE2_DARK      = 7'd110,
        PS_PIECE2_BASE      = 7'd111,
        PS_GHOST2_LIGHT     = 7'd112,
        PS_GHOST2_BG        = 7'd113,
        PS_STORY_INNER      = 7'd114,
        PS_STORY_OUTER      = 7'd115,
        PS_LBL_P1           = 7'd116,
        PS_LBL_P2           = 7'd117,
        PS_LBL_DUO          = 7'd118,
        PS_LBL_CORE         = 7'd119,
        PS_LBL_SCORE        = 7'd120,
        PS_DANGER_GAP       = 7'd121,
        PS_SLOT_FRAME       = 7'd122;

    function [23:0] tet_light;
    input [2:0] t;
    begin
        case(t)
        0:tet_light = LIGHT_CYAN;
        1:tet_light = LIGHT_PURPPLE;
        2:tet_light = LIGHT_YELLOW;
        3:tet_light = LIGHT_RED;
        4:tet_light = LIGHT_GREEN;
        5:tet_light = LIGHT_ORANGE;
        6:tet_light = LIGHT_PINK;
        default:tet_light = 24'h0;
        endcase
    end
    endfunction

    function [23:0] tet_dark;
    input [2:0] t;
    begin
        case(t)
        0:tet_dark = DARK_I;
        1:tet_dark = DARK_T;
        2:tet_dark = DARK_O;
        3:tet_dark = DARK_S;
        4:tet_dark = DARK_Z;
        5:tet_dark = DARK_L;
        6:tet_dark = DARK_J;
        default:tet_dark = 24'h0;
        endcase
    end
    endfunction

    function [23:0] tet_base;
    input [2:0] t;
    begin
        case(t)
        0:tet_base = CYAN;
        1:tet_base = PURPPLE;
        2:tet_base = YELLOW;
        3:tet_base = RED;
        4:tet_base = GREEN;
        5:tet_base = ORANGE;
        6:tet_base = PINK;
        default:tet_base = 24'h0;
        endcase
    end
    endfunction

    always@(*)begin
    psel = PS_BLACK;
    if(!Reset_n)
    psel = PS_BLACK;
    else if(choose)begin
        if(chs_margin_r)
        psel = chs_breath_r ? PS_MENU_DARK : PS_MENU_CYAN;
        else if(chs_text_r)
        psel = chs_dim_r ? PS_MENU_TEXT_DIM : PS_MENU_TEXT;
        else
        psel = PS_MENU_BG;
        end
    else if(over_lit_r || over_line_lit)begin
        case(cn_r)
        0:psel = PS_OVER_0;
        1:psel = PS_OVER_1;
        2:psel = PS_OVER_2;
        3:psel = PS_OVER_3;
        4:psel = PS_OVER_4;
        5:psel = PS_OVER_5;
        6:psel = PS_OVER_6;
        7:psel = PS_OVER_7;
        8:psel = PS_OVER_8;
        9:psel = tick_r ? PS_OVER_9_ON : PS_OVER_9_OFF;
        default:psel = PS_OVER_DEFAULT;
        endcase
        end
    else if(p1_label_px)
    psel = PS_LBL_P1;
    else if(p2_label_px)
    psel = PS_LBL_P2;
    else if(duo_label_px)
    psel = PS_LBL_DUO;
    else if(score_label_px)
    psel = PS_LBL_SCORE;
    else if(core1_label_px || core2_label_px || core3_label_px)
    psel = PS_LBL_CORE;
    else if(result_mode_r)
    psel = duo ? PS_RES_MODE_DUO : PS_RES_MODE_SOLO;
    else if(result_label_r)
    psel = PS_RES_LABEL;
    else if(result_num_r)begin
        case(result_num_sel_r)
        0:psel = PS_RES_NUM_SCORE;
        1:psel = PS_RES_NUM_LEVEL;
        2:psel = PS_RES_NUM_LINES;
        default:psel = PS_RES_NUM_TIME;
        endcase
        end
    else if(result_rule_r)begin
        case(result_rule_sel_r)
        0:psel = PS_RES_RULE_SCORE;
        1:psel = PS_RES_RULE_LEVEL;
        2:psel = PS_RES_RULE_LINES;
        default:psel = PS_RES_RULE_TIME;
        endcase
        end
    else if(result_colon_r)
    psel = PS_RES_COLON;
    else if(lb_breach && lbl_lit)
    psel = PS_BREACH;
    else if(result_region)begin
        if(result_dim)
        psel = PS_RES_DIM;
        else
        psel = in_field ? PS_RES_BG_FIELD : PS_RES_BG_BLACK;
        end
    else if(level_frame_lit)
    psel = level_critical ? PS_LVFRAME_RED :
           (level_hot ? PS_LVFRAME_ORANGE : PS_LVFRAME_GRAY);
    else if(level_alert_lit)
    psel = level_critical ? PS_LVALERT_RED : PS_LVALERT_ORANGE;
    else if(lbl_r)begin
        if(lb_lv_r)
        psel = PS_LBL_LV;
        else if(fin_r)
        psel = PS_LBL_DIM;
        else
        psel = PS_LBL_GRAY;
        end
    else if(rule1_r)begin
        if(fin_r)
        psel = PS_RULE1_DIM;
        else if(lflash1)
        psel = PS_RULE1_WHITE;
        else
        psel = duo ? PS_RULE1_CYAN : PS_RULE1_SOLO_GRAY;
        end
    else if(rule2_r)begin
        if(fin_r)
        psel = PS_RULE2_DIM;
        else if(lflash2)
        psel = PS_RULE2_WHITE;
        else
        psel = PS_RULE2_PINK;
        end
    else if(level_margin_r)
    psel = PS_LV_MARGIN;
    else if(level_inner_r)begin
        if(lvflash || level_cap_r)
        psel = PS_LV_WHITE;
        else if(cur_r || on_r)
        psel = PS_LV_SEG;
        else
        psel = PS_LV_UNLIT;
        end
    else if(lvd_r)
    psel = lvflash ? PS_LVD_WHITE : PS_LVD_COLOR;
    else if(slot_frame_lit)
    psel = PS_SLOT_FRAME;
    else if(hold_r)begin
        if(!pv_round_r)
        psel = PS_SLOT_BG;
        else if(hflash || pv_glint)
        psel = PS_PREVIEW_WHITE;
        else if(pv_light || pv_soft)
        psel = PS_PREVIEW_LIGHT_H;
        else if(pv_dark)
        psel = PS_PREVIEW_DARK_H;
        else
        psel = PS_PREVIEW_BASE_H;
        end
    else if(next_r)begin
        if(!pv_round_r)
        psel = PS_SLOT_BG;
        else if(nflash1 || pv_glint)
        psel = PS_PREVIEW_WHITE;
        else if(pv_light || pv_soft)
        psel = PS_PREVIEW_LIGHT_N1;
        else if(pv_dark)
        psel = PS_PREVIEW_DARK_N1;
        else
        psel = PS_PREVIEW_BASE_N1;
        end
    else if(next2_r)begin
        if(!pv_round_r)
        psel = PS_SLOT_BG;
        else if(nflash2 || pv_glint)
        psel = PS_PREVIEW_WHITE;
        else if(pv_light || pv_soft)
        psel = PS_PREVIEW_LIGHT_N2;
        else if(pv_dark)
        psel = PS_PREVIEW_DARK_N2;
        else
        psel = PS_PREVIEW_BASE_N2;
        end
    else if(slot_dot)
    psel = PS_SLOT_DOT;
    else if(hold_slot_r)
    psel = PS_HOLD_SLOT;
    else if(next_slot_r)
    psel = PS_NEXT_SLOT;
    else if(score_lit_r)
    psel = (scflash && !fin_r) ? PS_SCORE_FLASH : PS_SCORE_WHITE;
    else if(time_lit_r)
    psel = PS_TIME_WHITE;
    else if(rail_l_lit)
    psel = rail_l_white ? PS_RAIL_L_WHITE : PS_RAIL_L_CYAN;
    else if(rail_r_lit)begin
        if(rail_r_white)
        psel = PS_RAIL_R_WHITE;
        else
        psel = duo ? PS_RAIL_R_PINK : PS_RAIL_R_CYAN;
        end
    else if(danger_line)
    psel = PS_DANGER;
    else if(danger_gap)
    psel = PS_DANGER_GAP;
    else if(margin_r)
    psel = PS_MARGIN_WHITE;
    else if(rot_corner1 || hard_fx1)
    psel = PS_ROT1;
    else if(rot_corner2 || hard_fx2)
    psel = PS_ROT2;
    else if(bracket1)
    psel = PS_BRACKET1;
    else if(bracket2)
    psel = PS_BRACKET2;
    else if(Piece_r)begin
        if(!piece_round_r)
        psel = PS_PIECE_CORNER;
        else if(land_we_r)
        psel = PS_PIECE_LAND;
        else if(block_glint)
        psel = PS_PIECE_GLINT;
        else if(block_light || block_soft)
        psel = duo ? PS_PIECE_LIGHT_DUO : PS_PIECE_LIGHT;
        else if(block_dark)
        psel = PS_PIECE_DARK;
        else
        psel = PS_PIECE_BASE;
        end
    else if(ghost_r)begin
        if(ghost_tick || ghost_edge_r)
        psel = PS_GHOST_LIGHT;
        else
        psel = PS_GHOST_BG;
        end
    else if(hint_cell_lit)
    psel = PS_HINT;
    else if(lock_rim1 || lock_rim2)
    psel = PS_RIM_WHITE;
    else if(cell_r)begin
        if(!piece_round_r)
        psel = PS_CELL_CORNER;
        else if(clear_t_r)begin
            if(clear_shrink_r && !collapse_ring_r &&
               !((glx_r >= 11'd11) && (glx_r <= 11'd20) &&
                 (gly_r >= 11'd11) && (gly_r <= 11'd20)))
            psel = PS_CELL_SHRINK;
            else if(flash_r)
            psel = PS_CELL_FLASH;
            else if(collapse_spark_r)
            psel = PS_CELL_SPARK;
            else if(collapse_ring_r)
            psel = PS_CELL_RING;
            else
            psel = PS_CELL_CLEAR_BASE;
            end
        else if(block_glint)
        psel = PS_CELL_GLINT;
        else if(block_light || block_soft)
        psel = duo ? PS_CELL_LIGHT_DUO : PS_CELL_LIGHT;
        else if(block_dark)
        psel = PS_CELL_DARK;
        else
        psel = PS_CELL_BASE;
        end
    else if(Piece2_r)begin
        if(!piece_round_r)
        psel = PS_PIECE2_CORNER;
        else if(land_we2_r)
        psel = PS_PIECE2_LAND;
        else if(block_glint)
        psel = PS_PIECE2_GLINT;
        else if(block_light || block_soft)
        psel = duo ? PS_PIECE2_LIGHT_DUO : PS_PIECE2_LIGHT;
        else if(block_dark)
        psel = PS_PIECE2_DARK;
        else
        psel = PS_PIECE2_BASE;
        end
    else if(ghost2_r)begin
        if(ghost_tick || ghost_edge_r)
        psel = PS_GHOST2_LIGHT;
        else
        psel = PS_GHOST2_BG;
        end
    else if(in_field)
    psel = PS_STORY_INNER;
    else
    psel = PS_STORY_OUTER;
    end

    always@(*)begin
    case(psel_r)
    PS_MENU_DARK:       rgb_c = 24'h00697F;
    PS_MENU_CYAN:       rgb_c = 24'h00E5FF;
    PS_MENU_TEXT_DIM:   rgb_c = 24'h606060;
    PS_MENU_TEXT:       rgb_c = WHITE;
    PS_MENU_BG:         rgb_c = story_menu_color_r;
    PS_OVER_0:          rgb_c = 24'h101010;
    PS_OVER_1:          rgb_c = 24'h202020;
    PS_OVER_2:          rgb_c = 24'h404040;
    PS_OVER_3:          rgb_c = 24'h606060;
    PS_OVER_4:          rgb_c = 24'h909090;
    PS_OVER_5:          rgb_c = 24'hB0B0B0;
    PS_OVER_6:          rgb_c = 24'hD8D8D8;
    PS_OVER_7:          rgb_c = 24'hFFFFFF;
    PS_OVER_8:          rgb_c = 24'hFFFFFF;
    PS_OVER_9_ON:       rgb_c = 24'hFFFFFF;
    PS_OVER_9_OFF:      rgb_c = 24'h303030;
    PS_OVER_DEFAULT:    rgb_c = 24'hFFFFFF;
    PS_RES_MODE_SOLO:   rgb_c = 24'h00E5FF;
    PS_RES_MODE_DUO:    rgb_c = 24'hFF4DA6;
    PS_RES_LABEL:       rgb_c = 24'hB0B0B0;
    PS_RES_NUM_SCORE:   rgb_c = WHITE;
    PS_RES_NUM_LEVEL:   rgb_c = lv_color;
    PS_RES_NUM_LINES:   rgb_c = 24'hFF4DA6;
    PS_RES_NUM_TIME:    rgb_c = 24'hFFFF00;
    PS_RES_RULE_SCORE:  rgb_c = 24'h00E5FF;
    PS_RES_RULE_LEVEL:  rgb_c = lv_color;
    PS_RES_RULE_LINES:  rgb_c = 24'hFF4DA6;
    PS_RES_RULE_TIME:   rgb_c = 24'hFFFF00;
    PS_RES_COLON:       rgb_c = 24'hFFFF00;
    PS_RES_DIM:         rgb_c = 24'h101010;
    PS_RES_BG_FIELD:    rgb_c = field_bg;
    PS_RES_BG_BLACK:    rgb_c = BLACK;
    PS_BREACH:          rgb_c = 24'hE63946;
    PS_LVFRAME_GRAY:    rgb_c = 24'h606060;
    PS_LVFRAME_ORANGE:  rgb_c = ORANGE;
    PS_LVFRAME_RED:     rgb_c = RED;
    PS_LVALERT_ORANGE:  rgb_c = ORANGE;
    PS_LVALERT_RED:     rgb_c = RED;
    PS_LBL_LV:          rgb_c = lv_color;
    PS_LBL_GRAY:        rgb_c = 24'hB0B0B0;
    PS_LBL_DIM:         rgb_c = 24'h202020;
    PS_RULE1_CYAN:      rgb_c = 24'h00E5FF;
    PS_RULE1_SOLO_GRAY: rgb_c = 24'h606060;
    PS_RULE1_WHITE:     rgb_c = WHITE;
    PS_RULE1_DIM:       rgb_c = 24'h202020;
    PS_RULE2_PINK:      rgb_c = 24'hFF4DA6;
    PS_RULE2_WHITE:     rgb_c = WHITE;
    PS_RULE2_DIM:       rgb_c = 24'h202020;
    PS_LV_MARGIN:       rgb_c = 24'h202020;
    PS_LV_WHITE:        rgb_c = WHITE;
    PS_LV_SEG:          rgb_c = level_seg_color;
    PS_LV_UNLIT:        rgb_c = 24'h303030;
    PS_LVD_COLOR:       rgb_c = lv_color;
    PS_LVD_WHITE:       rgb_c = WHITE;
    PS_SLOT_FRAME:      rgb_c = 24'h29404D;
    PS_SLOT_BG:         rgb_c = slot_bg;
    PS_PREVIEW_WHITE:   rgb_c = WHITE;
    PS_PREVIEW_LIGHT_H: rgb_c = tet_light(hold_type_r);
    PS_PREVIEW_DARK_H:  rgb_c = tet_dark(hold_type_r);
    PS_PREVIEW_BASE_H:  rgb_c = tet_base(hold_type_r);
    PS_PREVIEW_LIGHT_N1:rgb_c = tet_light(type_t_r);
    PS_PREVIEW_DARK_N1: rgb_c = tet_dark(type_t_r);
    PS_PREVIEW_BASE_N1: rgb_c = tet_base(type_t_r);
    PS_PREVIEW_LIGHT_N2:rgb_c = tet_light(type_t2_r);
    PS_PREVIEW_DARK_N2: rgb_c = tet_dark(type_t2_r);
    PS_PREVIEW_BASE_N2: rgb_c = tet_base(type_t2_r);
    PS_SLOT_DOT:        rgb_c = 24'h404040;
    PS_HOLD_SLOT:       rgb_c = slot_bg;
    PS_NEXT_SLOT:       rgb_c = slot_bg;
    PS_SCORE_FLASH:     rgb_c = LV_H5;
    PS_SCORE_WHITE:     rgb_c = WHITE;
    PS_TIME_WHITE:      rgb_c = WHITE;
    PS_RAIL_L_CYAN:     rgb_c = 24'h00E5FF;
    PS_RAIL_L_WHITE:    rgb_c = WHITE;
    PS_RAIL_R_PINK:     rgb_c = PINK;
    PS_RAIL_R_CYAN:     rgb_c = 24'h00E5FF;
    PS_RAIL_R_WHITE:    rgb_c = WHITE;
    PS_DANGER:          rgb_c = danger_color;
    PS_MARGIN_WHITE:    rgb_c = 24'h536A76;
    PS_ROT1:            rgb_c = 24'h00E5FF;
    PS_ROT2:            rgb_c = PINK;
    PS_BRACKET1:        rgb_c = 24'h00E5FF;
    PS_BRACKET2:        rgb_c = PINK;
    PS_PIECE_CORNER:    rgb_c = field_bg;
    PS_PIECE_LAND:      rgb_c = 24'hEEEEEE;
    PS_PIECE_GLINT:     rgb_c = WHITE;
    PS_PIECE_LIGHT_DUO: rgb_c = P1_SOFT;
    PS_PIECE_LIGHT:     rgb_c = tet_light(type_r);
    PS_PIECE_DARK:      rgb_c = tet_dark(type_r);
    PS_PIECE_BASE:      rgb_c = tet_base(type_r);
    PS_GHOST_LIGHT:     rgb_c = tet_light(type_r);
    PS_GHOST_BG:        rgb_c = field_bg;
    PS_HINT:            rgb_c = hint_color;
    PS_RIM_WHITE:       rgb_c = WHITE;
    PS_CELL_CORNER:     rgb_c = field_bg;
    PS_CELL_CLEAR_BASE: rgb_c = tet_base(sc_r);
    PS_CELL_SPARK:      rgb_c = WHITE;
    PS_CELL_RING:       rgb_c = LV_H5;
    PS_CELL_FLASH:      rgb_c = 24'hEEEEEE;
    PS_CELL_SHRINK:     rgb_c = field_bg;
    PS_CELL_GLINT:      rgb_c = WHITE;
    PS_CELL_LIGHT_DUO:  rgb_c = owner_r ? P2_SOFT : P1_SOFT;
    PS_CELL_LIGHT:      rgb_c = tet_light(sc_r);
    PS_CELL_DARK:       rgb_c = tet_dark(sc_r);
    PS_CELL_BASE:       rgb_c = tet_base(sc_r);
    PS_PIECE2_CORNER:   rgb_c = field_bg;
    PS_PIECE2_LAND:     rgb_c = 24'hEEEEEE;
    PS_PIECE2_GLINT:    rgb_c = WHITE;
    PS_PIECE2_LIGHT_DUO:rgb_c = P2_SOFT;
    PS_PIECE2_LIGHT:    rgb_c = tet_light(type2_r);
    PS_PIECE2_DARK:     rgb_c = tet_dark(type2_r);
    PS_PIECE2_BASE:     rgb_c = tet_base(type2_r);
    PS_GHOST2_LIGHT:    rgb_c = tet_light(type2_r);
    PS_GHOST2_BG:       rgb_c = field_bg;
    PS_STORY_INNER:     rgb_c = story_inner_color_r;
    PS_STORY_OUTER:     rgb_c = story_outer_color_r;
    PS_LBL_P1:          rgb_c = 24'h00E5FF;
    PS_LBL_P2:          rgb_c = 24'hFF4DA6;
    PS_LBL_DUO:         rgb_c = 24'hFF4DA6;
    PS_LBL_CORE:        rgb_c = 24'hB0B0B0;
    PS_LBL_SCORE:       rgb_c = 24'hB0B0B0;
    PS_DANGER_GAP:      rgb_c = 24'h061017;
    default:            rgb_c = BLACK;
    endcase
    end

//    消行音效编号(只读)
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    rgb <= BLACK;
    else
    rgb <= rgb_c;
    end
    assign snd_clr_n = c_clear[2:0];

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
