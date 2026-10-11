module key_filter(
    Clk,
    Reset_n,
    key,
    key_p_flag,
    key_r_flag,
    key_en
    );
    
    input key;
    input Clk;
    input Reset_n;
    
    output wire key_p_flag;
    output wire key_r_flag;
    output reg key_en;
    
    reg [19:0]counter_cnt;
    reg en_cnt;
    reg sync_d0_key;
    reg sync_d1_key;
    reg r_key;
    reg key_en_tx;
    
    wire key_down;
    wire key_up;
    
    parameter MCNT_CNT = 1_000_000 - 1;
    
//    20ms计时
    always@(posedge Clk or negedge Reset_n)begin
    if(!Reset_n)
    counter_cnt <= 0;
    else if(!en_cnt)
    counter_cnt <= 0;
    else if(en_cnt)
    counter_cnt <= counter_cnt + 1;
    end
    
//    去亚稳态和记录下降沿和上升沿
    always@(posedge Clk or negedge Reset_n)
    if(!Reset_n)
    sync_d0_key <= 1'b1;
    else
    sync_d0_key <= key;
    
    always@(posedge Clk or negedge Reset_n)
    if(!Reset_n)
    sync_d1_key <= 1'b1;
    else
    sync_d1_key <= sync_d0_key;
    
    always@(posedge Clk or negedge Reset_n)
    if(!Reset_n)
    r_key <= 1'b1;
    else
    r_key  <= sync_d1_key;
    
    assign key_down = (!sync_d1_key) && (r_key);
    assign key_up = (sync_d1_key) && (!r_key);
    
//    计数使能开关与是否按下开关
    always@(posedge Clk or negedge Reset_n)begin
    if(!Reset_n)begin
    en_cnt <= 0;
    key_en <= 0;
    end
    else if(!key_en)begin
    if(key_down)
    en_cnt <= 1;
    else if(key_up)
    en_cnt <= 0;
    else if(counter_cnt == MCNT_CNT)begin
    en_cnt <= 0;
    key_en <= 1;
    end
    end
    else if(key_en)begin
    if(key_up)
    en_cnt <= 1;
    else if(key_down)
    en_cnt <= 0;
    else if(counter_cnt == MCNT_CNT)begin
    en_cnt <= 0;
    key_en <= 0;
    end
    end
    end
    
//    输出按下与松开信号
    always@(posedge Clk or negedge Reset_n)
    if(!Reset_n)
    key_en_tx <= 1'b0;
    else
    key_en_tx <= key_en;
    
    assign key_p_flag = (key_en) && (!key_en_tx);
    assign key_r_flag = (!key_en) && (key_en_tx);
    
endmodule
