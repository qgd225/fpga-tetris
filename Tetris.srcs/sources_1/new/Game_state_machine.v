//============================================================
// 模块：Game_state_machine
// 作用：游戏状态机：菜单、游戏、暂停和结束状态转换。
// 时钟/复位：Clk_74M；Reset_n 低有效
//============================================================
module Game_state_machine(
    input Clk_74M,
    input Reset_n,

    input left_p,
    input right_p,
    input switch_r_flag,
    input switch_en,
    input over,

    output wire Choose,
    output wire Idle,
    output wire Playing,
    output wire Stop,
    output wire Finalize,
    output wire sw_short,
    output wire sw_long,
    output reg [3:0]choose_cnt
    );

    parameter MCNT = 74_250_000;
    parameter [3:0]CHOOSE_MAX = 4'd1;

//    按键信号处理
    reg [26:0]counter;
    reg short_press_ok;

    wire hold_pulse  = (counter == MCNT) && (short_press_ok);
    wire short_press = (short_press_ok) && (switch_r_flag);

    assign sw_short = short_press;
    assign sw_long = hold_pulse;

    always@(posedge Clk_74M or negedge Reset_n)
    if(!Reset_n)
    counter <= 30'd0;
    else if(!switch_en)
    counter <= 30'd0;
    else if(counter < MCNT)
    counter <= counter + 30'd1;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    short_press_ok <= 1'b1;
    else if(hold_pulse)
    short_press_ok <= 1'b0;
    else if(switch_r_flag)
    short_press_ok <= 1'b1;
    end

//    模式选择计数器
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    choose_cnt <= 4'd0;
    else if(Choose)begin
        if(left_p)
        choose_cnt <= (choose_cnt == 4'd0) ? CHOOSE_MAX : (choose_cnt - 4'd1);
        else if(right_p)
        choose_cnt <= (choose_cnt == CHOOSE_MAX) ? 4'd0 : (choose_cnt + 4'd1);
    end
    else if(Idle && hold_pulse)
    choose_cnt <= 4'd0;
    end

//    状态转换
    localparam Choose_en   = 5'b00001;
    localparam Idle_en     = 5'b00010;
    localparam Playing_en  = 5'b00100;
    localparam Stop_en     = 5'b01000;
    localparam Finalize_en = 5'b10000;

    reg [4:0]state;

    assign Choose   = state[0];
    assign Idle     = state[1];
    assign Playing  = state[2];
    assign Stop     = state[3];
    assign Finalize = state[4];

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    state <= Choose_en;
    else
    case(state)
    Choose_en:  if(short_press)
                state <= Idle_en;
    Idle_en:    if(hold_pulse)
                state <= Choose_en;
                else if(short_press)
                state <= Playing_en;
    Playing_en: if(hold_pulse)
                state <= Idle_en;
                else if(short_press)
                state <= Stop_en;
                else if(over)
                state <= Finalize_en;
    Stop_en:    if(hold_pulse)
                state <= Idle_en;
                else if(short_press)
                state <= Playing_en;
    Finalize_en:if(hold_pulse)
                state <= Idle_en;
                else if(short_press)
                state <= Playing_en;
    default:    state <= Idle_en;
    endcase
    end

endmodule
