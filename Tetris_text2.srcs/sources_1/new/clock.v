module clock(
    input Clk,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input [3:0]num,
    
    output reg lit
    );

    parameter HSTART = 0,
               VSTART = 0,
               MIN = 2;//18*36

    parameter L = 6*MIN,
               W = 2*MIN,
               H = 2*MIN;

    parameter T = H + L + H,
               V = 5*W + 2*L,
               M = V/2,
               G = MIN/2;

    wire [10:0]X = hcounter - HSTART;
    wire [10:0]Y = vcounter - VSTART;

    reg [6:0]section;

    always@(*)begin
    section = 7'd0;
    if( (X < T) && (Y < V) )begin
        if( (Y < W) && (X >= (Y + G)) && ((T - 1 - X) >= (Y + G)) )//ÉÏºá¸Ü
        section[0] = 1'b1;
        else if( (X >= (T - W)) && (Y >= ((T - 1 - X) + G)) && (Y <= (M - 1 - (T - 1 - X) - G)) )//ÓÒÉÏÊú¸Ü
        section[1] = 1'b1;
        else if( (X >= (T - W)) && (Y >= (M + (T - 1 - X) + G)) && (Y <= (V - 1 - (T - 1 - X) - G)) )//ÓÒÏÂÊú¸Ü
        section[2] = 1'b1;
        else if( (Y >= (V - W)) && (X >= ((V - 1 - Y) + G)) && ((T - 1 - X) >= ((V - 1 - Y) + G)) )//ÏÂºá¸Ü
        section[3] = 1'b1;
        else if( (X < W) && (Y >= (M + X + G)) && (Y <= (V - 1 - X - G)) )//×óÏÂÊú¸Ü
        section[4] = 1'b1;
        else if( (X < W) && (Y >= (X + G)) && (Y <= (M - 1 - X - G)) )//×óÉÏÊú¸Ü
        section[5] = 1'b1;
        else if( (Y >= (M - W/2)) && (Y <= (M + W/2 - 1)) && (Y >= (M - 1 - X + G)) && (Y <= (M + X - G)) &&
                 (Y >= (M - 1 - (T - 1 - X) + G)) && (Y <= (M + (T - 1 - X) - G)) )//ÖÐºá¸Ü
        section[6] = 1'b1;
        end
    end
    
    
    always@(*)
    case(num)
    4'd0: lit = |(section[6:0] & 7'b011_1111);
    4'd1: lit = |(section[6:0] & 7'b000_0110);
    4'd2: lit = |(section[6:0] & 7'b101_1011);
    4'd3: lit = |(section[6:0] & 7'b100_1111);
    4'd4: lit = |(section[6:0] & 7'b110_0110);
    4'd5: lit = |(section[6:0] & 7'b110_1101);
    4'd6: lit = |(section[6:0] & 7'b111_1101);
    4'd7: lit = |(section[6:0] & 7'b000_0111);
    4'd8: lit = |(section[6:0] & 7'b111_1111);
    4'd9: lit = |(section[6:0] & 7'b110_1111);
    default: lit = 1'b0;
    endcase

endmodule
