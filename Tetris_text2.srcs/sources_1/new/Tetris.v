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
    wire kb_drop_r;
    wire kb_drop_en;
    wire kb_rotate_p;
    wire kb_switch_r;
    wire kb_switch_en;
    wire kb_hold_p;
    wire kb_reset_en;
    wire kb_activity;

    wire Reset_n = (por_n) && (!rst_key_en) && (!kb_reset_en);
    
 
    
//    VGA转HDMI及输出分频
    wire [10:0]hcounter;
    wire [10:0]vcounter;
    wire [23:0]rgb;
    wire hdmi_de;
    wire Clk_74M;
    
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
    
    .hcounter(hcounter),
    .vcounter(vcounter),
    .de(hdmi_de)
    );
    
//    按键输入及消抖
    wire switch_r_flag;
    wire switch_en;
    wire left_p_flag;
    wire right_p_flag;
    wire drop_r_flag;
    wire drop_en;
    wire rotate_p_flag;
    wire hold_p_flag;
    
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
    .drop_r_flag(drop_r_flag),
    .drop_en(drop_en),
    .rotate_p_flag(rotate_p_flag),
    .rst_key_en(rst_key_en),
    .hold_p_flag(hold_p_flag)
    );

wire left_p     = left_p_flag   | kb_left_p;
wire right_p    = right_p_flag  | kb_right_p;
wire drop_r_f   = drop_r_flag   | kb_drop_r;
wire drop_e     = drop_en       | kb_drop_en;
wire rotate_p   = rotate_p_flag | kb_rotate_p;
wire switch_r_f = switch_r_flag | kb_switch_r;
wire switch_e   = switch_en     | kb_switch_en;
wire hold_p     = hold_p_flag   | kb_hold_p;
    
//    游戏状态机
    wire Idle;  
    wire Playing;
    wire Stop;
    wire Finalize;
    wire over;
    wire choose;
    wire [3:0]choose_cnt;
    
    Game_state_machine Game_state_machine_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .left_p(left_p),
    .right_p(right_p),
    .switch_r_flag(switch_r_f),
    .switch_en(switch_e),
    .over(over),
    
    .Choose(choose),
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize),
    .choose_cnt(choose_cnt)
    );

    
//    画面输出
    wire clear;
    wire [2:0]speed_level;
    wire [19:0]score;
    wire [15:0]lines;
    wire [13:0]time_sec;
   
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
    .Idle(Idle),
    .choose(choose),
    .choose_cnt(choose_cnt),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize),
    
    .over(over),
    .rgb(rgb),
    .clear(clear),
    .speed_level(speed_level),
    .score(score),
    .lines(lines),
    .time_sec(time_sec)
    );
    
//   音频输出
    
    
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
    .drop(drop_r_f),
    .rotate(rotate_p),
    .right(right_p),
    .left(left_p),
    
    .buzz_else(buzz_else)
    );
    

//    以太网画面输出（逐像素颜色标号 -> UDP，一行一包）
    net_screen_tx net_screen_tx_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .por_n(por_n),
    .de(hdmi_de),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .rgb(rgb),
    .Finalize(Finalize),
    .res_score(score),
    .res_level(speed_level),
    .res_lines(lines),
    .res_time(time_sec),
    
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
    .kb_drop_r(kb_drop_r),
    .kb_drop_en(kb_drop_en),
    .kb_rotate_p(kb_rotate_p),
    .kb_switch_r(kb_switch_r),
    .kb_switch_en(kb_switch_en),
    .kb_hold_p(kb_hold_p),
    .kb_reset_en(kb_reset_en),
    .kb_activity(kb_activity)
    );

endmodule
