//============================================================
// 模块：Key
// 作用：板载按键接入：同步、消抖、单拍脉冲和长按电平。
// 时钟/复位：Clk/Clk_50M；Reset_n/por_n
//============================================================
module Key(
    input Clk,
    input Clk_50M,
    input Reset_n,
    input por_n,
    
    input switch,
    input left,
    input right,
    input drop,
    input rotate,
    input reset_key,
    input hold,
    
    output switch_r_flag,
    output switch_en,
    output left_p_flag,
    output right_p_flag,
    output drop_r_flag,
    output drop_en,
    output rotate_p_flag,
    output rst_key_en,
    output hold_p_flag,
    output hold_held
    );
    
    key_filter key_filter_inst0(
    .Clk(Clk),
    .Reset_n(Reset_n),
    .key(left),
    .key_p_flag(left_p_flag)
    );
    
    key_filter key_filter_inst1(
    .Clk(Clk),
    .Reset_n(Reset_n),
    .key(right),
    .key_p_flag(right_p_flag)
    );
    
    key_filter key_filter_inst2(
    .Clk(Clk),
    .Reset_n(Reset_n),
    .key(drop),
    .key_r_flag(drop_r_flag),
    .key_en(drop_en)
    );
    
    key_filter key_filter_inst3(
    .Clk(Clk),
    .Reset_n(Reset_n),
    .key(rotate),
    .key_p_flag(rotate_p_flag)
    );
    
    key_filter key_filter_inst4(
    .Clk(Clk),
    .Reset_n(Reset_n),
    .key(switch),
    .key_r_flag(switch_r_flag),
    .key_en(switch_en)
    );
    
    key_filter #(
    .MCNT_CNT(1_000_000 - 1)
    ) key_filter_rst(
    .Clk(Clk_50M),
    .Reset_n(por_n),
    .key(reset_key),
    .key_p_flag(),
    .key_r_flag(),
    .key_en(rst_key_en)
    );
    
    key_filter key_filter_inst5(
    .Clk(Clk),
    .Reset_n(Reset_n),
    .key(hold),
    .key_r_flag(hold_p_flag),
    .key_held(hold_held)
    );

endmodule
