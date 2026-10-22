module hold_gesture(
    input Clk_74M,
    input Reset_n,
    input held,
    output reg short_pulse,
    output reg long_level
    );
    parameter [24:0] HOLD_LONG_CNT = 25'd22_275_000;
    reg held_d;
    reg long_seen;
    reg [24:0] hold_cnt;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    held_d <= 1'b0;
    long_seen <= 1'b0;
    hold_cnt <= 25'd0;
    short_pulse <= 1'b0;
    long_level <= 1'b0;
    end
    else begin
    short_pulse <= 1'b0;
    if(!held)begin
        if(held_d && !long_seen)
        short_pulse <= 1'b1;
        hold_cnt <= 25'd0;
        long_seen <= 1'b0;
        long_level <= 1'b0;
    end
    else if(!held_d)begin
        hold_cnt <= 25'd1;
        long_seen <= 1'b0;
        long_level <= 1'b0;
    end
    else if(!long_seen)begin
        if(hold_cnt >= (HOLD_LONG_CNT - 25'd1))begin
        long_seen <= 1'b1;
        long_level <= 1'b1;
        end
        else
        hold_cnt <= hold_cnt + 25'd1;
    end
    held_d <= held;
    end
    end
endmodule
