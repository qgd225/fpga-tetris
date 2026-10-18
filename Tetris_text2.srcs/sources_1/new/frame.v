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
    output [2:0]snd_clr_n
    );
    reg [23:0]rgb_c;
    
    
//    ��Ϸ��
    wire [4:0]C_num;
    wire [4:0]R_num;
    wire [479:0]state;
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
    
    //    P2(˫��)��ʾ��
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
    wire [4:0]hint_col;

//============================================================
//    HUD ����(Ψһ��Դ): ���ê�� / ��ǩ / �ָ��� / ��λ / �ȼ��� / �ȼ�����
//============================================================
    localparam [10:0] XPNL1 = 11'd94,    //˫�� P1 ���(����)ê��
                     XPNL2 = 11'd1121,  //˫�� P2 ���(����)ê��
                     XSOLO = 11'd1057,  //�������(����)ê��
                     YNEXT = 11'd132,   //Ԥ����λ Y
                     YHOLD = 11'd348,   //Hold ��λ Y
                     YLBNX = 11'd84,    //NEXT ��ǩ Y
                     YLBHD = 11'd300,   //HOLD ��ǩ Y
                     YRLNX = 11'd122,   //NEXT �ָ��� Y
                     YRLHD = 11'd338,   //HOLD �ָ��� Y
                     XLVLB = 11'd232,   //LV ��ǩ X
                     XLDIG = 11'd283,   //�ȼ����� X(��ȼ���ͬ��)
                     YLBLV = 11'd36,    //LV ��ǩ Y(�� 44px �ߵ����ֵײ�����)
                     YDIGI = 11'd24;    //�ȼ����� Y
    wire [10:0]XPN1 = duo ? XPNL1 : XSOLO;
    wire [10:0]XPN2 = XPNL2;
//    NEXT/HOLD ��ǩ����: 4 �� x 24 ���(ʵ�� 92) �� 128 ���������߾� 18
    wire [10:0]XLBN1 = XPN1 + 11'd18;
    wire [10:0]XLBN2 = XPN2 + 11'd18;

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
    
    reg [2:0]state_color[0:479];
    reg state_owner[0:479];

//    ȡ������: 20 ��, ÿ�� 24 ��(state) / 24x3 λ(��ɫ��) / owner; ������, 0 LUT
    wire [23:0]row_f[0:19];
    wire [71:0]scw[0:19];
    wire [23:0]row_ow[0:19];
    genvar gr, gc;
    generate for(gr = 0; gr < 20; gr = gr + 1)begin : gen_rowf
        for(gc = 0; gc < 24; gc = gc + 1)begin : gen_colf
            assign row_f[gr][gc] = state[gc*20+gr];
            assign scw[gr][gc*3 +: 3] = state_color[gc*20+gr];
            assign row_ow[gr][gc] = state_owner[gc*20+gr];
        end
    end endgenerate
    
    integer c;
    integer m;
    integer y;
    
    always @(posedge Clk_74M) begin
    if(lock_we || (duo && lock_we2))begin
        if(lock_we && (cc_t[lock_idx] <= (duo ? 5'd23 : 5'd19)) && (rr_t[lock_idx] <= 5'd19))begin
        state_color[cc_t[lock_idx]*20 + rr_t[lock_idx]] <= type_d;
        state_owner[cc_t[lock_idx]*20 + rr_t[lock_idx]] <= 1'b0;
        end
        if(duo && lock_we2 && (cc_t2[lock_idx2] <= 5'd23) && (rr_t2[lock_idx2] <= 5'd19))begin
        state_color[cc_t2[lock_idx2]*20 + rr_t2[lock_idx2]] <= type_d2;
        state_owner[cc_t2[lock_idx2]*20 + rr_t2[lock_idx2]] <= 1'b1;
        end
    end
    else if(clear_time && !clear_t && !clear_pulse)begin 
        for(c = 0; c < 24; c = c + 1)
            for(m = 1; m < 20; m = m + 1)
                if(m <= clear_row)begin
                state_color[c*20 + m] <= state_color[c*20 + m - 1];
                state_owner[c*20 + m] <= state_owner[c*20 + m - 1];
                end
        end
    end
    
    Playfield Playfield_inst(
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
    .hint_r0(hint_r0), .hint_r1(hint_r1), .hint_r2(hint_r2), .hint_r3(hint_r3), .hint_col(hint_col)
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
    .seconds(time_sec)
    );
    
    wire score_lit;
    
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
    .cap(level_cap)
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
    

//    ���ֱ�ǩ NEXT/HOLD/LV: 1x �ֺ�(20x32), �־� 24
//    ��ַ�� BRAM ʹ����ǰ 1 ����(ena_n �� lb_hn, ��߽��� 1): ����ÿ�ֵ� 1 �лᴮ��һ�ֵ� 1 ��
    reg [10:0]lb_X;
    reg [10:0]lb_Y;
    reg [4:0] lb_g;
    reg       lb_ena;
    reg       lb_ena_n;
    reg       lb_lv;
    integer   li;
    wire [10:0]lb_hn = hcounter + 11'd1;
    always@(*)begin
    lb_X = 11'd0;
    lb_Y = 11'd0;
    lb_g = 5'd26;
    lb_ena = 1'b0;
    lb_ena_n = 1'b0;
    lb_lv = 1'b0;
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
//    ������˿��(ʱ��/��������) �� ���������»���: ���߱�ǩ��
    wire top_rule_lit = (hcounter >= 11'd470) && (hcounter <= 11'd470) &&
                        (vcounter >= 11'd24) && (vcounter < 11'd68);
    wire over_line_lit = Finalize && (hcounter >= 11'd449) && (hcounter <= 11'd825) &&
                         (vcounter >= 11'd444) && (vcounter <= 11'd446);

//    ���ָ���: 2px, λ�ڱ�ǩ�·�
    wire rule1_lit = ((vcounter >= YRLNX) && (vcounter < (YRLNX + 11'd2)) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128))) ||
                     ((vcounter >= YRLHD) && (vcounter < (YRLHD + 11'd2)) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128))) ||
                     ((vcounter >= 11'd717) && (vcounter < 11'd721) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128)));
    wire level_frame_lit = (((hcounter == 11'd277) || (hcounter == 11'd310)) && (vcounter >= 11'd86) && (vcounter <= 11'd713)) ||
                           (((vcounter == 11'd86) || (vcounter == 11'd713)) && (hcounter >= 11'd277) && (hcounter <= 11'd310));
    wire rule2_lit = duo && (((vcounter >= YRLNX) && (vcounter < (YRLNX + 11'd2)) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))) ||
                             ((vcounter >= YRLHD) && (vcounter < (YRLHD + 11'd2)) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))) ||
                             ((vcounter >= 11'd717) && (vcounter < 11'd721) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))));

//    �ȼ�����: 1 λ, ��ȼ���ͬ��
    wire [3:0] lv_dig = {1'b0, speed_level};
    wire [10:0]vdv = vcounter - YDIGI;
    wire lvd_ena = (hcounter >= XLDIG) && (hcounter < (XLDIG + 11'd20)) &&
                   (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd44));
//    ȡ��ʹ����ǰ 1 ����(number Ҳ�� READ_LATENCY=1): ����ÿ�е� 1 �лᴮ��һ��
    wire lvd_ena_n = (lb_hn >= (XLDIG - 11'd1)) && (lb_hn < (XLDIG + 11'd20)) &&
                     (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd44));
    wire [19:0]lvd_dout;
    number number_lv_inst(
    .clka(Clk_74M),
    .ena(lvd_ena_n),
    .addra({lv_dig, vdv[5:0]}),
    .douta(lvd_dout)
    );
    wire lvd_lit = lvd_ena ? lvd_dout[19 - (hcounter - XLDIG)] : 1'b0;
//    �ȼ�ɫ: 8 ����������(��->��->��->��->��->��->��->��)
    reg [23:0]lv_color;
    always@(*)begin
    case(speed_level)
    0:lv_color = 24'h00E5FF;
    1:lv_color = 24'h55A630;
    2:lv_color = 24'hFFF_F00;
    3:lv_color = 24'hF77F24;
    4:lv_color = 24'hE63946;
    5:lv_color = 24'hFF4DA6;
    6:lv_color = 24'h9933CC;
    7:lv_color = 24'hFFF_FFF;
    default:lv_color = 24'h00E5FF;
    endcase
    end

//    LV ���·� 2px �ȼ�ɫ����: ����ȼ����ַ�֧(ͬɫ)
    wire lv_rule_lit = (hcounter >= 11'd232) && (hcounter < 11'd306) &&
                       (vcounter >= 11'd72) && (vcounter < 11'd74);
    wire lvd_all_lit = lvd_lit || lv_rule_lit;

//    �����: 2px �ߴ� + �ĽǸ��� 1x1(�ڲ�����, ��ʵ�����䷽������)
//    �ж������� ghost_r ͬ�ļĴ�: ghost_r �� hcounter �� 1 ��, ��������խ�ҿ�
    wire [10:0]glx = (hcounter - 11'd321) & 11'd31;
    wire [10:0]gly = (vcounter - 11'd81) & 11'd31;
    wire glx_bd = (glx < 11'd2) || (glx > 11'd27);
    wire gly_bd = (gly < 11'd2) || (gly > 11'd27);
    wire glx_cn = (glx < 11'd1) || (glx > 11'd28);
    wire gly_cn = (gly < 11'd1) || (gly > 11'd28);
    wire ghost_edge = (glx_bd || gly_bd) && !(glx_cn && gly_cn);
//    ʵ�ķ��� 1px Բ��: �ĽǸ��� 1x1(�������н�ͬһ�ж�)
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
    //    ghost inner ticks / dash ring: registered local coordinates, aligned with ghost_r
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
//    Ԥ������ 1px Բ��: ��λ�����/��λ�ֱ�ȡ(�������崮��λ)
    wire [10:0]pvx1 = (hcounter - XPN1) & 11'd31;
    wire [10:0]pvx2 = (hcounter - XPN2) & 11'd31;
    wire [10:0]pvx = (duo && (hcounter >= XPN2)) ? pvx2 : pvx1;
    wire [10:0]pvy_n = (vcounter - YNEXT) & 11'd31;
    wire [10:0]pvy_h = (vcounter - YHOLD) & 11'd31;
    wire [10:0]pvy = hold_slot_r ? pvy_h : pvy_n;
    wire pv_corner = ((pvx == 11'd0) || (pvx == 11'd29)) && ((pvy == 11'd0) || (pvy == 11'd29));
//    ����ɫ: ���ص�ɫ vs �ⲿ / P1P2 ��λ��ɫ
    wire [10:0]XR = duo ? 11'd1088 : 11'd960;
    wire in_field = (hcounter >= 11'd321) && (hcounter < XR) && (vcounter >= 11'd81);
    wire [23:0]field_bg = 24'h0A0F16;
    wire [23:0]slot_bg = (duo && (hcounter >= XPN2)) ? 24'h1E0812 : 24'h081A1E;
    reg lvd_r;
    reg lb_lv_r;
    reg fin_r;
    reg [23:0]hint_color;
    reg hint_show_r, hint_valid_r, hint_hit_r;
    reg [2:0]hint_type_r;
    reg [4:0]hint_c0_r, hint_c1_r, hint_c2_r, hint_c3_r;
    reg [4:0]hint_r0_r, hint_r1_r, hint_r2_r, hint_r3_r;
    reg [4:0]hint_col_r;
    wire hint_match = hint_valid && (hint_type == type) &&
        ((C_num == hint_c0 && R_num == hint_r0) || (C_num == hint_c1 && R_num == hint_r1) ||
         (C_num == hint_c2 && R_num == hint_r2) || (C_num == hint_c3 && R_num == hint_r3));
    wire hint_box = (((gly_r == 11'd3) || (gly_r == 11'd26)) && (glx_r > 11'd2) && (glx_r < 11'd27) && (glx_r[2:0] < 3'd4)) ||
                    (((glx_r == 11'd3) || (glx_r == 11'd26)) && (gly_r > 11'd2) && (gly_r < 11'd27) && (gly_r[2:0] < 3'd4));
    wire hint_dot = (glx_r >= 11'd14) && (glx_r <= 11'd15) && (gly_r >= 11'd14) && (gly_r <= 11'd15);
    wire hint_cell_lit = hint_hit_r && (hint_box || hint_dot);
    wire hint_mark_lit = hint_show_r && hint_valid_r && (hint_type_r == type_r) && (vcounter >= 11'd714) && (vcounter <= 11'd720) &&
                         (hcounter >= (11'd335 + (hint_col_r << 5))) && (hcounter < (11'd339 + (hint_col_r << 5)));

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    over_lit_r <= 1'b0;
    tick_r <= 1'b0;
    cn_r <= 4'd0;
    level_margin_r <= 1'b0;
    level_inner_r <= 1'b0;
    level_cap_r <= 1'b0;
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
    hint_show_r <= 1'b0; hint_valid_r <= 1'b0; hint_hit_r <= 1'b0; hint_type_r <= 3'd0;
    hint_c0_r <= 0; hint_c1_r <= 0; hint_c2_r <= 0; hint_c3_r <= 0;
    hint_r0_r <= 0; hint_r1_r <= 0; hint_r2_r <= 0; hint_r3_r <= 0; hint_col_r <= 0;
    end
    else begin
    over_lit_r <= over_lit;
    tick_r <= tick;
    cn_r <= cn;
    level_margin_r <= level_margin;
    level_inner_r <= level_inner;
    level_cap_r <= level_cap;
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
    //    ����ȡɫ: ��ű����ڳ�����(�ڱ� 24 �� 20 ��ʾ�����κθ�)
    if((C_num <= 5'd23) && (R_num <= 5'd19))begin
    cell_r <= row_f[R_num][C_num];
    sc_r <= scw[R_num][C_num*3 +: 3];
    owner_r <= row_ow[R_num][C_num];
    end
    else begin
    cell_r <= 1'b0;
    sc_r <= 3'd0;
    owner_r <= 1'b0;
    end
    clear_t_r <= clear_t;
    //    ����ѹ��: 1~4 ��ֻҪ���в������оͳ�������, ���ܰ�����λӰ��
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
    hint_show_r <= hint_show && !duo && Playing; hint_valid_r <= hint_valid;
    hint_type_r <= hint_type; hint_c0_r <= hint_c0; hint_c1_r <= hint_c1; hint_c2_r <= hint_c2; hint_c3_r <= hint_c3;
    hint_r0_r <= hint_r0; hint_r1_r <= hint_r1; hint_r2_r <= hint_r2; hint_r3_r <= hint_r3; hint_col_r <= hint_col;
    hint_hit_r <= hint_show && !duo && Playing && hint_match;
    end
    end
//    UI ��Ч: 60Hz ���� + ��������(E1) / ��������(E2)
    parameter [20:0]EFF_TICK = 21'd1_237_499;//����ɸ���
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
//    Ԥ���� 32px ����(ֻ�ڲ�λ��, ���ȼ�����Ԥ������)
    wire dx1 = (((hcounter - XPN1) & 11'd31) == 11'd31);
    wire dx2 = (((hcounter - XPN2) & 11'd31) == 11'd31);
    wire dy1 = (((vcounter - YNEXT) & 11'd31) == 11'd31);
    wire dy2 = (((vcounter - YHOLD) & 11'd31) == 11'd31);
    wire slot_dot = (next_slot_r && dy1 && (dx1 || dx2)) || (hold_slot_r && dy2 && (dx1 || dx2));
//    ˫�� P1/P2 ����ձ�: �ֻ� 7 ��(2x, �� number ����ͬ���), ������ ROM ʱ��
    wire bd1 = duo && (hcounter >= 11'd138) && (hcounter < 11'd178) && (vcounter >= 11'd621) && (vcounter < 11'd709);
    wire bd2 = duo && (hcounter >= 11'd1165) && (hcounter < 11'd1205) && (vcounter >= 11'd621) && (vcounter < 11'd709);
    wire [10:0]bx = bd2 ? (hcounter - 11'd1165) : (hcounter - 11'd138);
    wire [10:0]by = vcounter - 11'd621;
    wire seg_a = (bx >= 11'd4) && (bx < 11'd36) && (by >= 11'd2) && (by < 11'd6);
    wire seg_d = (bx >= 11'd4) && (bx < 11'd36) && (by >= 11'd82) && (by < 11'd86);
    wire seg_g = (bx >= 11'd4) && (bx < 11'd36) && (by >= 11'd42) && (by < 11'd46);
    wire seg_b = (bx >= 11'd32) && (bx < 11'd36) && (by >= 11'd6) && (by < 11'd42);
    wire seg_c = (bx >= 11'd32) && (bx < 11'd36) && (by >= 11'd46) && (by < 11'd82);
    wire seg_e = (bx >= 11'd4) && (bx < 11'd8) && (by >= 11'd46) && (by < 11'd82);
    wire badge_lit = bd1 ? (seg_b || seg_c) : (bd2 ? (seg_a || seg_b || seg_g || seg_e || seg_d) : 1'b0);

    parameter CYAN = 24'h00CCFF,//��ɫI
               LIGHT_CYAN = 24'h99EEFF,//ǳ��ɫI
               PURPPLE = 24'h9933CC,//��ɫT
               LIGHT_PURPPLE = 24'hD9B3E6,//ǳ��ɫT
               YELLOW = 24'hFFF_F00,//��ɫO
               LIGHT_YELLOW = 24'hFFFF99,//ǳ��ɫO
               RED = 24'hE63946,//��ɫS
               LIGHT_RED = 24'hFFB3B9,//ǳ��ɫS
               GREEN = 24'h55A630,//��ɫZ
               LIGHT_GREEN = 24'hBDE0AA,//ǳ��ɫZ
               ORANGE = 24'hF77F24,//��ɫL
               LIGHT_ORANGE = 24'hFFD9B3,//ǳ��ɫL
               PINK = 24'hFF4DA6,//����ɫJ
               LIGHT_PINK = 24'hFFB3D9,//ǳ��ɫJ
               BLACK = 24'h000_000,//��ɫ
               WHITE = 24'hFFF_FFF,//��ɫ
               DARK_I = 24'h04_63_7E,
               DARK_T = 24'h47_1F_67,
               DARK_O = 24'h74_79_0D,
               DARK_S = 24'h69_22_2C,
               DARK_Z = 24'h29_52_23,
               DARK_L = 24'h71_41_1D,
               DARK_J = 24'h74_2B_56,
               P1_SOFT = 24'h6B_F0_FF,
               P2_SOFT = 24'hFF_98_CB;
    
    // danger band and side rails
    wire [23:0]col_mask = duo ? 24'hFFFFFF : 24'h0FFFFF;
    wire row0_any = |(row_f[0] & col_mask);
    wire row1_any = |(row_f[1] & col_mask);
    wire row2_any = |(row_f[2] & col_mask);
    wire row3_any = |(row_f[3] & col_mask);
    wire danger_state = row0_any || row1_any;
    wire caution_state = danger_state || row2_any || row3_any;
    wire [1:0]danger_lvl = danger_state ? 2'd2 : (caution_state ? 2'd1 : 2'd0);
    wire danger_active = (danger_lvl != 2'd0);
    wire [23:0]danger_color = (danger_lvl == 2'd2) ? RED : ORANGE;
    wire danger_line = danger_active && (hcounter >= 11'd321) && (hcounter < XR) &&
                       (vcounter >= 11'd77) && (vcounter < 11'd81);
    wire danger_dot = danger_active && in_field &&
                      (((hcounter - 11'd321) & 11'd15) == 11'd0) &&
                      (((vcounter - 11'd81) & 11'd15) == 11'd0) &&
                      ((danger_lvl == 2'd2) ? (R_num <= 5'd1) : (R_num <= 5'd3));
    wire rail_l_lit = (hcounter >= 11'd313) && (hcounter <= 11'd316) &&
                      (vcounter >= 11'd81) && (vcounter < 11'd721);
    wire rail_r_lit = (hcounter >= (XR + 11'd4)) && (hcounter <= (XR + 11'd7)) &&
                      (vcounter >= 11'd81) && (vcounter < 11'd721);
    wire rail_l_white = lflash1 || danger_active || (mbl1 != 2'd0) || (mbl2 != 2'd0);
    wire rail_r_white = (duo ? lflash2 : lflash1) || danger_active || (mbr1 != 2'd0) || (mbr2 != 2'd0);

    //    Impact Glass edges and 8px SOFT white L glint
    wire block_light = (glx_r == 11'd1) || (gly_r == 11'd1);
    wire block_soft = (glx_r >= 11'd6) && (glx_r <= 11'd11) && (gly_r == 11'd26);//����6x1���
    wire block_dark = (glx_r == 11'd30) || (gly_r == 11'd30);
    wire block_glint = (((gly_r == 11'd2) || (gly_r == 11'd3)) && (glx_r >= 11'd2) && (glx_r <= 11'd9)) ||
                       (((glx_r == 11'd2) || (glx_r == 11'd3)) && (gly_r >= 11'd2) && (gly_r <= 11'd9)) ||
                       ((glx_r >= 11'd3) && (glx_r <= 11'd4) && (gly_r >= 11'd3) && (gly_r <= 11'd4));
    wire pv_light = (pvx_r == 11'd1) || (pvy_r == 11'd1);
    wire pv_soft = (pvx_r >= 11'd6) && (pvx_r <= 11'd11) && (pvy_r == 11'd26);//Ԥ������6x1���
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

    always@(*)begin
    if(!Reset_n)
    rgb_c = BLACK;
    else if(choose)begin
        if(chs_margin_r)
        rgb_c = chs_breath_r ? 24'h00697F : 24'h00E5FF;//ѡ�б��(������)
        else if(chs_text_r)
        rgb_c = chs_dim_r ? 24'h606060 : WHITE;
        else
        rgb_c = BLACK;
        end
    else if(over_lit_r || over_line_lit)
        case(cn_r)
        0:rgb_c = 24'h101010;
        1:rgb_c = 24'h202020;
        2:rgb_c = 24'h404040;
        3:rgb_c = 24'h606060;
        4:rgb_c = 24'h909090;
        5:rgb_c = 24'hB0B0B0;
        6:rgb_c = 24'hD8D8D8;
        7:rgb_c = 24'hFFF_FFF;
        8:rgb_c = 24'hFFF_FFF;
        9:if(tick_r)
          rgb_c = 24'hFFF_FFF;
          else
          rgb_c = 24'h303030;
        default:rgb_c = 24'hFFF_FFF;
        endcase
    else if(Finalize && (hcounter >= 11'd432) && (hcounter <= 11'd847) &&
            (vcounter >= 11'd348) && (vcounter <= 11'd451) && (hcounter[0] ^ vcounter[0]))
    rgb_c = 24'h101010;//��������������������ѹ��
    else if(level_frame_lit)
    rgb_c = 24'h606060;
    else if(lbl_r)
    rgb_c = lb_lv_r ? lv_color : (fin_r ? 24'h202020 : 24'hB0B0B0);//NEXT/HOLD ��ǩ��, LV �õȼ�ɫ
    else if(rule1_r)
    rgb_c = fin_r ? 24'h202020 : (lflash1 ? WHITE : (duo ? 24'h00E5FF : 24'h606060));//���ָ���(P1/����)
    else if(rule2_r)
    rgb_c = fin_r ? 24'h202020 : (lflash2 ? WHITE : 24'hFF4DA6);//P2 ���ָ���
    else if(level_margin_r)begin
        rgb_c = 24'h202020;//�����֮��ķ�
        end
    else if(level_inner_r)begin
        if(lvflash)
        rgb_c = WHITE;
        else if(level_cap_r)
        rgb_c = WHITE;
        else if(cur_r)
        rgb_c = lv_color;
        else if(on_r)
        rgb_c = lv_color;
        else
        rgb_c = 24'h303030;
        end
    else if(lvd_r)
    rgb_c = lvflash ? WHITE : lv_color;//�ȼ�����(�� LV ͬɫ)
    else if(hold_r)begin
        if(!pv_round_r)
        rgb_c = slot_bg;
        else if(hflash)
        rgb_c = WHITE;
        else if(pv_glint)
        rgb_c = WHITE;
        else if(pv_light || pv_soft)
        case(hold_type_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        else if(pv_dark)
        case(hold_type_r)
        0:rgb_c = DARK_I;
        1:rgb_c = DARK_T;
        2:rgb_c = DARK_O;
        3:rgb_c = DARK_S;
        4:rgb_c = DARK_Z;
        5:rgb_c = DARK_L;
        6:rgb_c = DARK_J;
        default:rgb_c = 0;
        endcase
        else
        case(hold_type_r)
        0:rgb_c = CYAN;
        1:rgb_c = PURPPLE;
        2:rgb_c = YELLOW;
        3:rgb_c = RED;
        4:rgb_c = GREEN;
        5:rgb_c = ORANGE;
        6:rgb_c = PINK;
        default:rgb_c = 0;
        endcase
        end
    else if(next_r)begin
        if(!pv_round_r)
        rgb_c = slot_bg;
        else if(nflash1)
        rgb_c = WHITE;
        else if(pv_glint)
        rgb_c = WHITE;
        else if(pv_light || pv_soft)
        case(type_t_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        else if(pv_dark)
        case(type_t_r)
        0:rgb_c = DARK_I;
        1:rgb_c = DARK_T;
        2:rgb_c = DARK_O;
        3:rgb_c = DARK_S;
        4:rgb_c = DARK_Z;
        5:rgb_c = DARK_L;
        6:rgb_c = DARK_J;
        default:rgb_c = 0;
        endcase
        else
        case(type_t_r)
        0:rgb_c = CYAN;
        1:rgb_c = PURPPLE;
        2:rgb_c = YELLOW;
        3:rgb_c = RED;
        4:rgb_c = GREEN;
        5:rgb_c = ORANGE;
        6:rgb_c = PINK;
        default:rgb_c = 0;
        endcase
        end
    else if(next2_r)begin
        if(!pv_round_r)
        rgb_c = slot_bg;
        else if(nflash2)
        rgb_c = WHITE;
        else if(pv_glint)
        rgb_c = WHITE;
        else if(pv_light || pv_soft)
        case(type_t2_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        else if(pv_dark)
        case(type_t2_r)
        0:rgb_c = DARK_I;
        1:rgb_c = DARK_T;
        2:rgb_c = DARK_O;
        3:rgb_c = DARK_S;
        4:rgb_c = DARK_Z;
        5:rgb_c = DARK_L;
        6:rgb_c = DARK_J;
        default:rgb_c = 0;
        endcase
        else
        case(type_t2_r)
        0:rgb_c = CYAN;
        1:rgb_c = PURPPLE;
        2:rgb_c = YELLOW;
        3:rgb_c = RED;
        4:rgb_c = GREEN;
        5:rgb_c = ORANGE;
        6:rgb_c = PINK;
        default:rgb_c = 0;
        endcase
        end
    else if(slot_dot)
    rgb_c = 24'h404040;//Ԥ���۵���
    else if(hold_slot_r)
    rgb_c = slot_bg;//Hold ��λ��ɫ
    else if(next_slot_r)
    rgb_c = slot_bg;//Next ��λ��ɫ
    else if(badge_lit)
    rgb_c = bd2 ? 24'hFF4DA6 : 24'h00E5FF;//P1/P2 ����ձ�
    else if(score_lit_r)
    rgb_c = (scflash && (!fin_r)) ? 24'h00E5FF : WHITE;
    else if(time_lit_r)
    rgb_c = WHITE;
    else if(rail_l_lit)
    rgb_c = rail_l_white ? WHITE : 24'h00E5FF;
    else if(rail_r_lit)
    rgb_c = rail_r_white ? WHITE : (duo ? PINK : 24'h00E5FF);
    else if(danger_line)
    rgb_c = danger_color;
    else if(hint_mark_lit)
    rgb_c = hint_color;
    else if(margin_r)
    rgb_c = WHITE;
    else if(danger_dot && !cell_r && !Piece_r && !ghost_r && !Piece2_r && !ghost2_r)
    rgb_c = danger_color;
    else if(rot_corner1 || hard_fx1)
    rgb_c = 24'h00E5FF;
    else if(rot_corner2 || hard_fx2)
    rgb_c = PINK;
    else if(bracket1)
    rgb_c = 24'h00E5FF;
    else if(bracket2)
    rgb_c = PINK;
    else if(Piece_r)begin
        if(!piece_round_r)
        rgb_c = field_bg;
        else if(land_we_r)
        rgb_c = 24'hEEEEEE;
        else if(block_glint)
        rgb_c = WHITE;
        else if(block_light || block_soft)begin
        if(duo)
        rgb_c = P1_SOFT;
        else
        case(type_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else if(block_dark)
        case(type_r)
        0:rgb_c = DARK_I;
        1:rgb_c = DARK_T;
        2:rgb_c = DARK_O;
        3:rgb_c = DARK_S;
        4:rgb_c = DARK_Z;
        5:rgb_c = DARK_L;
        6:rgb_c = DARK_J;
        default:rgb_c = 0;
        endcase
        else
        case(type_r)
        0:rgb_c = CYAN;
        1:rgb_c = PURPPLE;
        2:rgb_c = YELLOW;
        3:rgb_c = RED;
        4:rgb_c = GREEN;
        5:rgb_c = ORANGE;
        6:rgb_c = PINK;
        default:rgb_c = 0;
        endcase
        end
    else if(ghost_r)begin
        if(ghost_tick || ghost_edge_r)begin
        case(type_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else if(ghost_edge_r)begin
        case(type_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else
        rgb_c = field_bg;
        end
    else if(hint_cell_lit)
    rgb_c = hint_color;
    else if(lock_rim1)
    rgb_c = WHITE;
    else if(lock_rim2)
    rgb_c = WHITE;
    else if(cell_r)begin
        if(!piece_round_r)
        rgb_c = field_bg;
        else if(clear_t_r)begin
            case(sc_r)
            0:rgb_c = CYAN;
            1:rgb_c = PURPPLE;
            2:rgb_c = YELLOW;
            3:rgb_c = RED;
            4:rgb_c = GREEN;
            5:rgb_c = ORANGE;
            6:rgb_c = PINK;
            default:rgb_c = 0;
            endcase
            if(flash_r)
            rgb_c = 24'hEEEEEE;
            if(clear_shrink_r && !((glx_r >= 11'd11) && (glx_r <= 11'd20) && (gly_r >= 11'd11) && (gly_r <= 11'd20)))
            rgb_c = field_bg;
        end
        else if(block_glint)
        rgb_c = WHITE;
        else if(block_light || block_soft)begin
        if(duo)
        rgb_c = owner_r ? P2_SOFT : P1_SOFT;
        else
        case(sc_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else if(block_dark)
        case(sc_r)
        0:rgb_c = DARK_I;
        1:rgb_c = DARK_T;
        2:rgb_c = DARK_O;
        3:rgb_c = DARK_S;
        4:rgb_c = DARK_Z;
        5:rgb_c = DARK_L;
        6:rgb_c = DARK_J;
        default:rgb_c = 0;
        endcase
        else
        case(sc_r)
        0:rgb_c = CYAN;
        1:rgb_c = PURPPLE;
        2:rgb_c = YELLOW;
        3:rgb_c = RED;
        4:rgb_c = GREEN;
        5:rgb_c = ORANGE;
        6:rgb_c = PINK;
        default:rgb_c = 0;
        endcase
    end
    else if(Piece2_r)begin
        if(!piece_round_r)
        rgb_c = field_bg;
        else if(land_we2_r)
        rgb_c = 24'hEEEEEE;
        else if(block_glint)
        rgb_c = WHITE;
        else if(block_light || block_soft)begin
        if(duo)
        rgb_c = P2_SOFT;
        else
        case(type2_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else if(block_dark)
        case(type2_r)
        0:rgb_c = DARK_I;
        1:rgb_c = DARK_T;
        2:rgb_c = DARK_O;
        3:rgb_c = DARK_S;
        4:rgb_c = DARK_Z;
        5:rgb_c = DARK_L;
        6:rgb_c = DARK_J;
        default:rgb_c = 0;
        endcase
        else
        case(type2_r)
        0:rgb_c = CYAN;
        1:rgb_c = PURPPLE;
        2:rgb_c = YELLOW;
        3:rgb_c = RED;
        4:rgb_c = GREEN;
        5:rgb_c = ORANGE;
        6:rgb_c = PINK;
        default:rgb_c = 0;
        endcase
        end
    else if(ghost2_r)begin
        if(ghost_tick || ghost_edge_r)begin
        case(type2_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else if(ghost_edge_r)begin
        case(type2_r)
        0:rgb_c = LIGHT_CYAN;
        1:rgb_c = LIGHT_PURPPLE;
        2:rgb_c = LIGHT_YELLOW;
        3:rgb_c = LIGHT_RED;
        4:rgb_c = LIGHT_GREEN;
        5:rgb_c = LIGHT_ORANGE;
        6:rgb_c = LIGHT_PINK;
        default:rgb_c = 0;
        endcase
        end
        else
        rgb_c = field_bg;
        end
    else
    rgb_c = in_field ? field_bg : BLACK;
    end
    
//    ������Ч���(ֻ��)
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    rgb <= BLACK;
    else
    rgb <= rgb_c;
    end
    assign snd_clr_n = c_clear[2:0];

endmodule
