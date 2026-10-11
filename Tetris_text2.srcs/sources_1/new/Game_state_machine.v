module Game_state_machine(
    input Clk_74M,
    input Reset_n,
    
    input switch_r_flag,
    input switch_en,
    input over,
    
    output wire Idle,
    output wire Playing,
    output wire Stop,
    output wire Finalize
    );
    
    
//    按键信号处理
    reg [26:0]counter;
    reg short_press_ok;
    
    parameter MCNT = 74_250_000;
    
    wire hold_pulse  = (counter == MCNT) && (short_press_ok); 
    wire short_press = (short_press_ok) && (switch_r_flag);
    
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
    
//    状态转换
    localparam Idle_en = 4'b0001;
    localparam Playing_en = 4'b0010;
    localparam Stop_en = 4'b0100;
    localparam Finalize_en = 4'b1000;
    
    reg [3:0]state;
    
    
    assign Idle = state[0];
    assign Playing = state[1];
    assign Stop = state[2];
    assign Finalize = state[3];
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    state <= Idle_en;
    else 
    case(state)
    Idle_en:    if(short_press)
                state <= Playing_en;
    Playing_en:if(hold_pulse)
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
    default:    state <= Playing_en;
    endcase
    end
      
endmodule
