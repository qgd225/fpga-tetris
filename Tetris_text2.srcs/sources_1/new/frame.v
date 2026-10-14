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
    wire [399:0]state;
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
    wire land_we;
    wire [19:0]line_t;
    wire clear_flash;
    
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
    
    reg [2:0]state_color[0:399];
    
    integer c;
    integer m;
    integer y;
    
    always @(posedge Clk_74M) begin
    if(lock_we)begin
        if((cc_t[lock_idx] <= 19) && (rr_t[lock_idx] <= 19))
        state_color[cc_t[lock_idx]*20 + rr_t[lock_idx]] <= type_d;
    end
    else if(clear_time && !clear_t && !clear_pulse)begin 
        for(c = 0; c < 20; c = c + 1)
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
    .hold_type(hold_type),
    .speed_level(speed_level),
    .land_we(land_we),
    .line_t(line_t),
    .clear_flash(clear_flash)
    );
    
    
    wire margin;
    
    Playfield_margin Playfield_margin_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    
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
    .type_t(type_t),
    
    .next(next),
    .next_margin(next_margin)
    );
    
    wire hold;
    wire hold_margin;
    
    hold_piece hold_piece_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .Idle(Idle),
    .en_hold(en_hold),
    .hold_type(hold_type),
    
    .hold(hold),
    .hold_margin(hold_margin)
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
    reg land_we_r;
    reg [2:0]type_r;
    reg [2:0]type_t_r;
    reg [2:0]hold_type_r;
    reg cell_r;
    reg [2:0]sc_r;
    reg clear_t_r;
    reg flash_r;

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
    land_we_r <= 1'b0;
    type_r <= 3'd0;
    type_t_r <= 3'd0;
    hold_type_r <= 3'd0;
    cell_r <= 1'b0;
    sc_r <= 3'd0;
    clear_t_r <= 1'b0;
    flash_r <= 1'b0;
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
    land_we_r <= land_we;
    type_r <= type;
    type_t_r <= type_t;
    hold_type_r <= hold_type;
    cell_r <= state[(C_num*20) + R_num];
    sc_r <= state_color[(C_num*20) + R_num];
    clear_t_r <= clear_t;
    flash_r <= (clear_t) && (line_t[R_num]) && (!clear_flash);
    end
    end
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
    else if(over_lit_r)
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
    else if(level_margin_r)begin
        if(on_r)
        rgb = 24'h00E5FF;
        else
        rgb = 24'h303030;
        end
    else if(level_inner_r)begin
        if(cur_r)
        rgb = 24'hFFF_F00;
        else if(on_r)
        rgb = 24'h00697F;
        else
        rgb = 24'h101010;
        end
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
    else if(hold_margin_r)
    rgb = WHITE;
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
    else if(next_margin_r)
    rgb = WHITE;
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
    else
    rgb = BLACK;
    end
    
endmodule
