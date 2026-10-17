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
    
    output reg [23:0]rgb,
    output over,
    output clear,
    output [2:0]speed_level,
    output [19:0]score,
    output [15:0]lines,
    output [13:0]time_sec
    );
    
    
//    游戏区
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

//============================================================
//    HUD 布局(唯一来源): 面板锚点 / 标签 / 分隔线 / 槽位 / 等级条 / 等级数字
//============================================================
    localparam [10:0] XPNL1 = 11'd94,    //双人 P1 面板(左栏)锚点
                     XPNL2 = 11'd1121,  //双人 P2 面板(右栏)锚点
                     XSOLO = 11'd1057,  //单人面板(右栏)锚点
                     YNEXT = 11'd132,   //预览槽位 Y
                     YHOLD = 11'd348,   //Hold 槽位 Y
                     YLBNX = 11'd84,    //NEXT 标签 Y
                     YLBHD = 11'd300,   //HOLD 标签 Y
                     YRLNX = 11'd122,   //NEXT 分隔线 Y
                     YRLHD = 11'd338,   //HOLD 分隔线 Y
                     XLVLB = 11'd236,   //LV 标签 X
                     XLDIG = 11'd284,   //等级数字 X(与等级条同轴)
                     YDIGI = 11'd24;    //标签/数字 Y
    wire [10:0]XPN1 = duo ? XPNL1 : XSOLO;
    wire [10:0]XPN2 = XPNL2;

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
    
    integer c;
    integer m;
    integer y;
    
    always @(posedge Clk_74M) begin
    if(lock_we || (duo && lock_we2))begin
        if(lock_we && (cc_t[lock_idx] <= (duo ? 5'd23 : 5'd19)) && (rr_t[lock_idx] <= 5'd19))
        state_color[cc_t[lock_idx]*20 + rr_t[lock_idx]] <= type_d;
        if(duo && lock_we2 && (cc_t2[lock_idx2] <= 5'd23) && (rr_t2[lock_idx2] <= 5'd19))
        state_color[cc_t2[lock_idx2]*20 + rr_t2[lock_idx2]] <= type_d2;
    end
    else if(clear_time && !clear_t && !clear_pulse)begin 
        for(c = 0; c < 24; c = c + 1)
            for(m = 1; m < 20; m = m + 1)
                if(m <= clear_row)
                state_color[c*20 + m] <= state_color[c*20 + m - 1];
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
    .land_we2(land_we2)
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
    .cur(cur)
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
    .dim(chs_dim)
    );
    

//    文字标签 NEXT/HOLD/LV: 1x 字号(20x32), 字距 24
//    地址与 BRAM 使能提前 1 像素(ena_n 用 lb_hn, 左边界多减 1): 否则每字第 1 列会串上一字第 1 列
    reg [10:0]lb_X;
    reg [10:0]lb_Y;
    reg [4:0] lb_g;
    reg       lb_ena;
    reg       lb_ena_n;
    integer   li;
    wire [10:0]lb_hn = hcounter + 11'd1;
    always@(*)begin
    lb_X = 11'd0;
    lb_Y = 11'd0;
    lb_g = 5'd26;
    lb_ena = 1'b0;
    lb_ena_n = 1'b0;
    for(li = 0; li < 4; li = li + 1)begin
        if((hcounter >= (XPN1 + li*24)) && (hcounter < (XPN1 + li*24 + 11'd20)) &&
           (vcounter >= YLBNX) && (vcounter < (YLBNX + 11'd32)))begin
            lb_ena = 1'b1;
            lb_X = XPN1 + li*24;
            lb_Y = YLBNX;
        end
        if((lb_hn >= (XPN1 + li*24 - 11'd1)) && (lb_hn < (XPN1 + li*24 + 11'd20)) &&
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
        if((hcounter >= (XPN1 + li*24)) && (hcounter < (XPN1 + li*24 + 11'd20)) &&
           (vcounter >= YLBHD) && (vcounter < (YLBHD + 11'd32)))begin
            lb_ena = 1'b1;
            lb_X = XPN1 + li*24;
            lb_Y = YLBHD;
        end
        if((lb_hn >= (XPN1 + li*24 - 11'd1)) && (lb_hn < (XPN1 + li*24 + 11'd20)) &&
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
            if((hcounter >= (XPN2 + li*24)) && (hcounter < (XPN2 + li*24 + 11'd20)) &&
               (vcounter >= YLBNX) && (vcounter < (YLBNX + 11'd32)))begin
                lb_ena = 1'b1;
                lb_X = XPN2 + li*24;
                lb_Y = YLBNX;
            end
            if((lb_hn >= (XPN2 + li*24 - 11'd1)) && (lb_hn < (XPN2 + li*24 + 11'd20)) &&
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
            if((hcounter >= (XPN2 + li*24)) && (hcounter < (XPN2 + li*24 + 11'd20)) &&
               (vcounter >= YLBHD) && (vcounter < (YLBHD + 11'd32)))begin
                lb_ena = 1'b1;
                lb_X = XPN2 + li*24;
                lb_Y = YLBHD;
            end
            if((lb_hn >= (XPN2 + li*24 - 11'd1)) && (lb_hn < (XPN2 + li*24 + 11'd20)) &&
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
           (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd32)))begin
            lb_ena = 1'b1;
            lb_X = XLVLB + li*24;
            lb_Y = YDIGI;
        end
        if((lb_hn >= (XLVLB + li*24 - 11'd1)) && (lb_hn < (XLVLB + li*24 + 11'd20)) &&
           (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd32)))begin
            lb_ena_n = 1'b1;
            lb_Y = YDIGI;
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
//    顶栏发丝线(时间/分数分组) 与 结束画面下划线: 都走标签灰
    wire top_rule_lit = (hcounter >= 11'd470) && (hcounter <= 11'd470) &&
                        (vcounter >= 11'd24) && (vcounter < 11'd68);
    wire over_line_lit = Finalize && (hcounter >= 11'd449) && (hcounter <= 11'd825) &&
                         (vcounter >= 11'd444) && (vcounter <= 11'd446);

//    面板分隔线: 2px, 位于标签下方
    wire rule1_lit = ((vcounter >= YRLNX) && (vcounter < (YRLNX + 11'd2)) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128))) ||
                     ((vcounter >= YRLHD) && (vcounter < (YRLHD + 11'd2)) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128))) ||
                     ((vcounter >= 11'd717) && (vcounter < 11'd721) && (hcounter >= XPN1) && (hcounter < (XPN1 + 11'd128)));
    wire rule2_lit = duo && (((vcounter >= YRLNX) && (vcounter < (YRLNX + 11'd2)) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))) ||
                             ((vcounter >= YRLHD) && (vcounter < (YRLHD + 11'd2)) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))) ||
                             ((vcounter >= 11'd717) && (vcounter < 11'd721) && (hcounter >= XPN2) && (hcounter < (XPN2 + 11'd128))));

//    等级数字: 1 位, 与等级条同轴
    wire [3:0] lv_dig = {1'b0, speed_level};
    wire [10:0]vdv = vcounter - YDIGI;
    wire lvd_ena = (hcounter >= XLDIG) && (hcounter < (XLDIG + 11'd20)) &&
                   (vcounter >= YDIGI) && (vcounter < (YDIGI + 11'd44));
//    取字使能提前 1 像素(number 也是 READ_LATENCY=1): 否则每行第 1 列会串上一行
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

//    幽灵框: 2px 边带 + 四角各切 1x1(内部纯黑, 与实心下落方块区分)
//    判定必须与 ghost_r 同拍寄存: ghost_r 比 hcounter 晚 1 拍, 否则框会左窄右宽
    wire [10:0]glx = (hcounter - 11'd321) & 11'd31;
    wire [10:0]gly = (vcounter - 11'd81) & 11'd31;
    wire glx_bd = (glx < 11'd2) || (glx > 11'd27);
    wire gly_bd = (gly < 11'd2) || (gly > 11'd27);
    wire glx_cn = (glx < 11'd1) || (glx > 11'd28);
    wire gly_cn = (gly < 11'd1) || (gly > 11'd28);
    wire ghost_edge = (glx_bd || gly_bd) && !(glx_cn && gly_cn);

    reg over_lit_r;
    reg tick_r;
    reg [3:0]cn_r;
    reg level_margin_r;
    reg level_inner_r;
    reg on_r;
    reg cur_r;
    reg hold_r;
    reg hold_margin_r;
    reg next_r;
    reg next_margin_r;
    reg score_lit_r;
    reg time_lit_r;
    reg margin_r;
    reg Piece_r;
    reg ghost_r;
    reg ghost_edge_r;
    reg land_we_r;
    reg [2:0]type_r;
    reg [2:0]type_t_r;
    reg [2:0]hold_type_r;
    reg cell_r;
    reg [2:0]sc_r;
    reg clear_t_r;
    reg flash_r;
    reg chs_margin_r;
    reg chs_inner_r;
    reg chs_text_r;
    reg chs_dim_r;
    reg Piece2_r;
    reg ghost2_r;
    reg [2:0]type2_r;
    reg [2:0]type_t2_r;
    reg land_we2_r;
    reg next2_r;
    reg lbl_r;
    reg rule1_r;
    reg rule2_r;
    reg next_slot_r;
    reg hold_slot_r;
    reg lvd_r;
    reg fin_r;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    over_lit_r <= 1'b0;
    tick_r <= 1'b0;
    cn_r <= 4'd0;
    level_margin_r <= 1'b0;
    level_inner_r <= 1'b0;
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
    land_we_r <= 1'b0;
    type_r <= 3'd0;
    type_t_r <= 3'd0;
    hold_type_r <= 3'd0;
    cell_r <= 1'b0;
    sc_r <= 3'd0;
    clear_t_r <= 1'b0;
    flash_r <= 1'b0;
    chs_margin_r <= 1'b0;
    chs_inner_r <= 1'b0;
    chs_text_r <= 1'b0;
    chs_dim_r <= 1'b0;
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
    fin_r <= 1'b0;
    end
    else begin
    over_lit_r <= over_lit;
    tick_r <= tick;
    cn_r <= cn;
    level_margin_r <= level_margin;
    level_inner_r <= level_inner;
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
    land_we_r <= land_we;
    type_r <= type;
    type_t_r <= type_t;
    hold_type_r <= hold_type;
    //    场地取色: 编号必须在场地内(哨兵 24 或 20 表示不在任何格)
    if((C_num <= 5'd23) && (R_num <= 5'd19))begin
    cell_r <= state[(C_num*20) + R_num];
    sc_r <= state_color[(C_num*20) + R_num];
    end
    else begin
    cell_r <= 1'b0;
    sc_r <= 3'd0;
    end
    clear_t_r <= clear_t;
    flash_r <= (clear_t) && (line_t[R_num]) && (!clear_flash);
    chs_margin_r <= chs_margin;
    chs_inner_r <= chs_inner;
    chs_text_r <= chs_text;
    chs_dim_r <= chs_dim;
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
    lvd_r <= lvd_lit;
    fin_r <= Finalize;
    end
    end
//    UI 特效: 60Hz 节拍 + 落锁脉冲(E1) / 升级闪白(E2)
    parameter [20:0]EFF_TICK = 21'd1_237_499;//仿真可覆盖
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
    reg [1:0]lf1, lf2, lvf;
    reg [2:0]lvl_d;
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    lf1 <= 2'd0;
    lf2 <= 2'd0;
    lvf <= 2'd0;
    lvl_d <= 3'd0;
    end
    else begin
    lvl_d <= speed_level;
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
    end
    end
    wire lflash1 = (lf1 != 2'd0);
    wire lflash2 = (lf2 != 2'd0);
    wire lvflash = (lvf != 2'd0);

    parameter CYAN = 24'h00CCFF,//青色I
               LIGHT_CYAN = 24'h99EEFF,//浅青色I
               PURPPLE = 24'h9933CC,//紫色T
               LIGHT_PURPPLE = 24'hD9B3E6,//浅紫色T
               YELLOW = 24'hFFF_F00,//黄色O
               LIGHT_YELLOW = 24'hFFFF99,//浅黄色O
               RED = 24'hE63946,//红色S
               LIGHT_RED = 24'hFFB3B9,//浅红色S
               GREEN = 24'h55A630,//绿色Z
               LIGHT_GREEN = 24'hBDE0AA,//浅绿色Z
               ORANGE = 24'hF77F24,//橙色L
               LIGHT_ORANGE = 24'hFFD9B3,//浅橙色L
               PINK = 24'hFF4DA6,//亮粉色J
               LIGHT_PINK = 24'hFFB3D9,//浅粉色J
               BLACK = 24'h000_000,//黑色
               WHITE = 24'hFFF_FFF;//白色
    
    always@(*)begin
    if(!Reset_n)
    rgb = BLACK;
    else if(choose)begin
        if(chs_margin_r)
        rgb = 24'h00E5FF;//选中标记(左侧竖条 + 下方横线)
        else if(chs_text_r)
        rgb = chs_dim_r ? 24'h606060 : WHITE;
        else
        rgb = BLACK;
        end
    else if(over_lit_r || over_line_lit)
        case(cn_r)
        0:rgb = 24'h101010;
        1:rgb = 24'h202020;
        2:rgb = 24'h404040;
        3:rgb = 24'h606060;
        4:rgb = 24'h909090;
        5:rgb = 24'hB0B0B0;
        6:rgb = 24'hD8D8D8;
        7:rgb = 24'hFFF_FFF;
        8:rgb = 24'hFFF_FFF;
        9:if(tick_r)
          rgb = 24'hFFF_FFF;
          else
          rgb = 24'h303030;
        default:rgb = 24'hFFF_FFF;
        endcase
    else if(lbl_r)
    rgb = fin_r ? 24'h202020 : 24'hB0B0B0;//NEXT/HOLD/LV 文字标签
    else if(rule1_r)
    rgb = fin_r ? 24'h202020 : (lflash1 ? WHITE : (duo ? 24'h00E5FF : 24'h606060));//面板分隔线(P1/单人)
    else if(rule2_r)
    rgb = fin_r ? 24'h202020 : (lflash2 ? WHITE : 24'hFF4DA6);//P2 面板分隔线
    else if(level_margin_r)begin
        rgb = 24'h202020;//段与段之间的缝
        end
    else if(level_inner_r)begin
        if(fin_r)
        rgb = 24'h202020;
        else if(lvflash)
        rgb = WHITE;
        else if(cur_r)
        rgb = 24'h00E5FF;
        else if(on_r)
        rgb = 24'h606060;
        else
        rgb = 24'h202020;
        end
    else if(lvd_r)
    rgb = fin_r ? 24'h202020 : WHITE;//等级数字
    else if(hold_r)begin
        case(hold_type_r)
        0:rgb = CYAN;
        1:rgb = PURPPLE;
        2:rgb = YELLOW;
        3:rgb = RED;
        4:rgb = GREEN;
        5:rgb = ORANGE;
        6:rgb = PINK;
        default:rgb = 0;
        endcase
        end
    else if(next_r)begin
        case(type_t_r)
        0:rgb = CYAN;
        1:rgb = PURPPLE;
        2:rgb = YELLOW;
        3:rgb = RED;
        4:rgb = GREEN;
        5:rgb = ORANGE;
        6:rgb = PINK;
        default:rgb = 0;
        endcase
        end
    else if(next2_r)begin
        case(type_t2_r)
        0:rgb = CYAN;
        1:rgb = PURPPLE;
        2:rgb = YELLOW;
        3:rgb = RED;
        4:rgb = GREEN;
        5:rgb = ORANGE;
        6:rgb = PINK;
        default:rgb = 0;
        endcase
        end
    else if(hold_slot_r)
    rgb = 24'h202020;//Hold 槽位底色
    else if(next_slot_r)
    rgb = 24'h202020;//Next 槽位底色
    else if(score_lit_r)
    rgb = WHITE;
    else if(time_lit_r)
    rgb = WHITE;
    else if(margin_r)
    rgb = WHITE;
    else if(Piece_r)begin
        if(land_we_r)
        rgb = 24'hEEEEEE;
        else
        case(type_r)
        0:rgb = CYAN;
        1:rgb = PURPPLE;
        2:rgb = YELLOW;
        3:rgb = RED;
        4:rgb = GREEN;
        5:rgb = ORANGE;
        6:rgb = PINK;
        default:rgb = 0;
        endcase
        end
    else if(ghost_r)begin
        if(ghost_edge_r)begin
        case(type_r)
        0:rgb = LIGHT_CYAN;
        1:rgb = LIGHT_PURPPLE;
        2:rgb = LIGHT_YELLOW;
        3:rgb = LIGHT_RED;
        4:rgb = LIGHT_GREEN;
        5:rgb = LIGHT_ORANGE;
        6:rgb = LIGHT_PINK;
        default:rgb = 0;
        endcase
        end
        else
        rgb = BLACK;
        end
    else if(cell_r)begin
        if(clear_t_r)begin
            case(sc_r)
            0:rgb = CYAN;
            1:rgb = PURPPLE;
            2:rgb = YELLOW;
            3:rgb = RED;
            4:rgb = GREEN;
            5:rgb = ORANGE;
            6:rgb = PINK;
            default:rgb = 0;
            endcase
            if(flash_r)
            rgb = 24'hEEEEEE;
        end
        else
        case(sc_r)
        0:rgb = CYAN;
        1:rgb = PURPPLE;
        2:rgb = YELLOW;
        3:rgb = RED;
        4:rgb = GREEN;
        5:rgb = ORANGE;
        6:rgb = PINK;
        default:rgb = 0;
        endcase
    end
    else if(Piece2_r)begin
        if(land_we2_r)
        rgb = 24'hEEEEEE;
        else
        case(type2_r)
        0:rgb = CYAN;
        1:rgb = PURPPLE;
        2:rgb = YELLOW;
        3:rgb = RED;
        4:rgb = GREEN;
        5:rgb = ORANGE;
        6:rgb = PINK;
        default:rgb = 0;
        endcase
        end
    else if(ghost2_r)begin
        if(ghost_edge_r)begin
        case(type2_r)
        0:rgb = LIGHT_CYAN;
        1:rgb = LIGHT_PURPPLE;
        2:rgb = LIGHT_YELLOW;
        3:rgb = LIGHT_RED;
        4:rgb = LIGHT_GREEN;
        5:rgb = LIGHT_ORANGE;
        6:rgb = LIGHT_PINK;
        default:rgb = 0;
        endcase
        end
        else
        rgb = BLACK;
        end
    else
    rgb = BLACK;
    end
    
endmodule
