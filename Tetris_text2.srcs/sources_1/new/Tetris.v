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
    output buzz_else
    );
    
    //上电复位
    reg [19:0]por_cnt = 20'd0;
    
    always@(posedge Clk)begin
    if(!por_cnt[19])
    por_cnt <= por_cnt + 1'b1;
    end
    
    wire por_n = por_cnt[19];
    wire rst_key_en;
    
    wire Reset_n = (por_n) && (!rst_key_en);
    
 
    
//    VGA转HDMI及输出分频
    wire [10:0]hcounter;
    wire [10:0]vcounter;
    wire [23:0]rgb;
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
    .vcounter(vcounter)
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
    
//    游戏状态机
    wire Idle;  
    wire Playing;
    wire Stop;
    wire Finalize;
    wire over;
    
    Game_state_machine Game_state_machine_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .switch_r_flag(switch_r_flag),
    .switch_en(switch_en),
    .over(over),
    
    .Idle(Idle),
    .Playing(Playing),
    .Stop(Stop),
    .Finalize(Finalize)
    );

    
//    画面输出
    wire clear;
    wire [2:0]speed_level;
   
   frame frame_inst(
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
    
    .over(over),
    .rgb(rgb),
    .clear(clear),
    .speed_level(speed_level)
    );
    
//   音频输出
    
    
    music music_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .Idle(Idle),
    .speed_level(speed_level),
    
    .buzz_main(buzz_main)
    );
    
    sound sound_inst(
    .Clk_74M(Clk_74M),
    .Reset_n(Reset_n),
    .over(over),
    .clear(clear),
    .drop(drop_r_flag),
    .rotate(rotate_p_flag),
    .right(right_p_flag),
    .left(left_p_flag),
    
    .buzz_else(buzz_else)
    );
    
endmodule
