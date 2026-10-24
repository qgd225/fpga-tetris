// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块：Tetris
// 作用：顶层集成：按键、游戏状态、场地、画面、音频与以太网接口。
// 时钟/复位：Clk；Reset_key
//============================================================
module Tetris(
    input Clk,
    input Reset_key,
    input left,
    input right,
    input drop,
    input rotate,
    input switch,
    input hold,

    output hdmi_clk_p,
    output hdmi_clk_n,
    output [2:0]hdmi_data_p,
    output [2:0]hdmi_data_n,
    output hdmi_oe,
    output buzz_main,
    output buzz_else,

    input         rgmii_rx_clk_i,
    input  [3:0]  rgmii_rxd,
    input         rgmii_rxdv,
    output        rgmii_tx_clk,
    output  [3:0] rgmii_txd,
    output        rgmii_txen,
    output        eth_rstn,
    output        eth_mdc,
    output        eth_mdio
    );

//上电复位
    reg [19:0]por_cnt = 20'd0;

    always@(posedge Clk)begin
    if(!por_cnt[19])
    por_cnt <= por_cnt + 1'b1;
    end

    wire por_n = por_cnt[19];
    wire rst_key_en;

    wire kb_left_p;
    wire kb_right_p;
    wire kb_left_held;
    wire kb_right_held;
    wire kb_drop_r;
    wire kb_drop_en;
    wire kb_rotate_p;
    wire kb_switch_r;
    wire kb_switch_en;
    wire kb_hold_p;
    wire kb_hold_en;
    wire kb_reset_en;
    wire kb_activity;

    wire Reset_n = (por_n) && (!rst_key_en) && (!kb_reset_en);

//    VGA转HDMI及输出分频
    wire [10:0]hcounter;
    wire [10:0]vcounter;
    wire [23:0]rgb;
    wire hdmi_de;
    wire Clk_74M;

    wire fx_active;
    wire audio_sample_ce;
    wire signed [15:0] audio_pcm;
    // 此版先传游戏音效，保留蜂鸣器用于对照。
    game_audio_pcm pcm_inst(.clk(Clk_74M), .reset_n(Reset_n),
        .fx_wave(buzz_else), .fx_active(fx_active),
        .sample_ce(audio_sample_ce), .pcm(audio_pcm));
    hdmi hdmi_inst(
    .Clk(Clk),
    .Clk_74M(Clk_74M),
    .Reset_n(por_n),
    .hdmi_clk_p(hdmi_clk_p),
    .hdmi_clk_n(hdmi_clk_n),
    .hdmi_data_p(hdmi_data_p),
    .hdmi_data_n(hdmi_data_n),
    .hdmi_oe(hdmi_oe),
    .rgb(rgb),
    .audio_sample_ce(audio_sample_ce),
    .audio_pcm(audio_pcm),

    .hcounter(hcounter),
    .vcounter(vcounter),
    .de(hdmi_de)
    );

//    按键输入及消抖
    wire switch_r_flag;
    wire switch_en;
    wire left_p_flag;
    wire right_p_flag;
    wire left_held;
    wire right_held;
    wire drop_r_flag;
    wire drop_en;
    wire rotate_p_flag;
    wire hold_p_flag;
    wire hold_held;

    Key Key_inst(
    .Clk(Clk_74M),
    .Clk_50M(Clk),
    .Reset_n(Reset_n),
    .por_n(por_n),
    .switch(switch),
    .left(left),
    .right(right),
    .drop(drop),
    .rotate(rotate),
    .reset_key(Reset_key),
    .hold(hold),

    .switch_r_flag(switch_r_flag),
    .switch_en(switch_en),
    .left_p_flag(left_p_flag),
    .right_p_flag(right_p_flag),
    .left_held(left_held),
    .right_held(right_held),
    .drop_r_flag(drop_r_flag),
    .drop_en(drop_en),
    .rotate_p_flag(rotate_p_flag),
    .rst_key_en(rst_key_en),
    .hold_p_flag(hold_p_flag),
    .hold_held(hold_held)
    );

wire p1_left, p1_right, p1_drop_r, p1_drop_en, p1_rotate, p1_hold;
wire p1_left_held, p1_right_held;
wire p2_left, p2_right, p2_drop_r, p2_drop_en, p2_rotate, p2_hold;
wire p2_left_held, p2_right_held;

wire left_p;
wire right_p;
wire p2_left_move;
wire p2_right_move;
wire left_p_menu  = left_p_flag | kb_left_p;
wire right_p_menu = right_p_flag | kb_right_p;
wire drop_r_f   = p1_drop_r;
wire drop_e     = p1_drop_en;
wire rotate_p   = p1_rotate;
wire switch_r_f = switch_r_flag | kb_switch_r;
wire switch_e   = switch_en     | kb_switch_en;
wire hold_route = p1_hold;
wire solo_hold_short;
wire solo_hold_long;

//    游戏状态机
    wire Idle;
    wire Playing;
    wire Stop;
    wire Finalize;
    wire over;
    wire mission_win, mission_hold, mission_success;
    wire [1:0]story_phase;
    wire choose;
    wire [3:0]choose_cnt;
    wire duo = (choose_cnt == 4'd1);
hold_gesture hold_gesture_inst(
.Clk_74M(Clk_74M),
.Reset_n(Reset_n),
.held(hold_held | kb_hold_en),
.short_pulse(solo_hold_short),
.long_level(solo_hold_long)
);
wire hold_p = duo ? hold_route : solo_hold_short;

//    单人: PC + 板载键都控制 P1; 双人: 板载 P1, PC P2
control_route control_route_inst(
.duo(duo),
.btn_left(left_p_flag),
.btn_right(right_p_flag),
.btn_drop_r(drop_r_flag),
.btn_drop_en(drop_en),
.btn_rotate(rotate_p_flag),
.btn_hold(hold_p_flag),
.btn_left_held(left_held),
.btn_right_held(right_held),
.pc_left(kb_left_p),
.pc_right(kb_right_p),
.pc_drop_r(kb_drop_r),
.pc_drop_en(kb_drop_en),
.pc_rotate(kb_rotate_p),
.pc_hold(kb_hold_p),
.pc_left_held(kb_left_held),
.pc_right_held(kb_right_held),
.p1_left(p1_left),
.p1_right(p1_right),
.p1_drop_r(p1_drop_r),
.p1_drop_en(p1_drop_en),
.p1_rotate(p1_rotate),
.p1_hold(p1_hold),
.p1_left_held(p1_left_held),
.p1_right_held(p1_right_held),
.p2_left(p2_left),
.p2_right(p2_right),
.p2_drop_r(p2_drop_r),
.p2_drop_en(p2_drop_en),
.p2_rotate(p2_rotate),
.p2_hold(p2_hold),
.p2_left_held(p2_left_held),
.p2_right_held(p2_right_held)
);

    wire sw_short;
    wire sw_long;

    Game_state_machine Game_state_machine_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .left_p(left_p_menu),
    .right_p(right_p_menu),
    .switch_r_flag(switch_r_f),
    .switch_en(switch_e),
    .over(over | mission_win),

    .sw_short(sw_short),
    .sw_long(sw_long),

    .Choose(choose),
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize),
    .choose_cnt(choose_cnt)
    );

//    横向连发：首移直通，DAS 220ms，ARR 80ms
    horizontal_repeat p1_horizontal_repeat(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .active(Playing),
    .left_p(p1_left),
    .right_p(p1_right),
    .left_held(p1_left_held),
    .right_held(p1_right_held),
    .left_out(left_p),
    .right_out(right_p)
    );

    horizontal_repeat p2_horizontal_repeat(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .active(Playing),
    .left_p(p2_left),
    .right_p(p2_right),
    .left_held(p2_left_held),
    .right_held(p2_right_held),
    .left_out(p2_left_move),
    .right_out(p2_right_move)
    );

//    画面输出
    wire clear;
    wire [2:0]speed_level;
    wire [19:0]score;
    wire [15:0]lines;
    wire [13:0]time_sec;
    wire snd_land1;
    wire snd_land2;
    wire snd_hard1;
    wire snd_hard2;
    wire snd_soft1;
    wire snd_soft2;
    wire blk_l1;
    wire blk_r1;
    wire blk_l2;
    wire blk_r2;
    wire snd_hold1;
    wire snd_hold2;
    wire blk_rot1;
    wire blk_rot2;
    wire [2:0]snd_clr_n;
    wire [1:0] danger_lvl;
    reg [1:0] danger_d;
    reg danger1_pulse;
    reg danger2_pulse;
    reg [2:0]lvl_d;
    reg lvl_up;

//    升级检测: speed_level 变化产生 1 拍脉冲(给音效)
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    lvl_d <= 3'd0;
    lvl_up <= 1'b0;
    end
    else begin
    lvl_d <= speed_level;
    lvl_up <= Playing && (speed_level > lvl_d);
    end
    end

//    危险等级上升沿：0->1 警报，0/1->2 紧急警报
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    danger_d <= 2'd0;
    danger1_pulse <= 1'b0;
    danger2_pulse <= 1'b0;
    end
    else begin
    danger_d <= danger_lvl;
    danger1_pulse <= (danger_lvl == 2'd1) && (danger_d == 2'd0);
    danger2_pulse <= (danger_lvl == 2'd2) && (danger_d != 2'd2);
    end
    end

//    长按开关提示: 第一次长按常亮, 再次长按收起
reg solo_hint_latched;
reg solo_hold_long_d;
always@(posedge Clk_74M or negedge Reset_n)begin
if(!Reset_n)begin
solo_hint_latched <= 1'b0;
solo_hold_long_d <= 1'b0;
end
else begin
solo_hold_long_d <= solo_hold_long;
if(duo || !Playing)
solo_hint_latched <= 1'b0;
else if(solo_hold_long && !solo_hold_long_d)
solo_hint_latched <= ~solo_hint_latched;
end
end
wire solo_hint_show = !duo && solo_hint_latched;

//    像素合成：场地/HUD/菜单/结算页/UI 特效与调色板
   frame frame_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .left_p_flag(left_p),
    .right_p_flag(right_p),
    .drop_r_flag(drop_r_f),
    .drop_en(drop_e),
    .rotate_p_flag(rotate_p),
    .switch_r_flag(switch_r_f),
    .hold_p_flag(hold_p),
    .hint_show(solo_hint_show),
    .Idle(Idle),
    .choose(choose),
    .choose_cnt(choose_cnt),
    .duo(duo),
    .left_p_flag2(p2_left_move),
    .right_p_flag2(p2_right_move),
    .drop_r_flag2(p2_drop_r),
    .drop_en2(p2_drop_en),
    .rotate_p_flag2(p2_rotate),
    .hold_p_flag2(p2_hold),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize),

    .over(over),
    .rgb(rgb),
    .clear(clear),
    .speed_level(speed_level),
    .score(score),
    .lines(lines),
    .time_sec(time_sec),
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
    .snd_clr_n(snd_clr_n),
    .danger_lvl(danger_lvl),
    .mission_win(mission_win), .mission_hold(mission_hold),
    .story_phase(story_phase), .mission_success(mission_success)
    );

    music music_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .Idle(Idle | choose),
    .speed_level(speed_level),

    .buzz_main(buzz_main)
    );

    sound sound_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .over(over),
    .clear(clear),
    .clr_n(snd_clr_n),
    .lvl_up(lvl_up),
    .sw_short(sw_short),
    .sw_long(sw_long),
    .menu_l(choose && left_p_menu),
    .menu_r(choose && right_p_menu),
    .land1(snd_land1),
    .land2(snd_land2),
    .lft1(p1_left && !blk_l1),
    .rgt1(p1_right && !blk_r1),
    .rot1(rotate_p && !blk_rot1),
    .hard1(snd_hard1),
    .soft1(snd_soft1),
    .hold1(snd_hold1),
    .blk1(blk_l1 || blk_r1),
    .lft2(p2_left && !blk_l2),
    .rgt2(p2_right && !blk_r2),
    .rot2(p2_rotate && !blk_rot2),
    .hard2(snd_hard2),
    .soft2(snd_soft2),
    .hold2(snd_hold2),
    .blk2(blk_l2 || blk_r2),
    .blk_rot1(blk_rot1),
    .blk_rot2(blk_rot2),
    .danger1(danger1_pulse),
    .danger2(danger2_pulse),

    .buzz_else(buzz_else),
    .fx_active(fx_active)
    );

//    以太网：UDP 画面/调色板与 PC 键盘输入
    net_screen_tx net_screen_tx_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .por_n(por_n),
    .de(hdmi_de),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .rgb(rgb),

    .rgmii_rx_clk_i(rgmii_rx_clk_i),
    .rgmii_rxd(rgmii_rxd),
    .rgmii_rxdv(rgmii_rxdv),
    .rgmii_tx_clk(rgmii_tx_clk),
    .rgmii_txd(rgmii_txd),
    .rgmii_txen(rgmii_txen),
    .eth_rstn(eth_rstn),
    .eth_mdc(eth_mdc),
    .eth_mdio(eth_mdio),

    .kb_left_p(kb_left_p),
    .kb_right_p(kb_right_p),
    .kb_left_held(kb_left_held),
    .kb_right_held(kb_right_held),
    .kb_drop_r(kb_drop_r),
    .kb_drop_en(kb_drop_en),
    .kb_rotate_p(kb_rotate_p),
    .kb_switch_r(kb_switch_r),
    .kb_switch_en(kb_switch_en),
    .kb_hold_p(kb_hold_p),
    .kb_hold_en(kb_hold_en),
    .kb_reset_en(kb_reset_en),
    .kb_activity(kb_activity)
    );

endmodule
