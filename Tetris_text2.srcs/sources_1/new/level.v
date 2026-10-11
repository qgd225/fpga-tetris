module level(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input [2:0]speed_level,

    output margin,
    output inner,
    output on,
    output cur
    );

    parameter XL   = 300,
              YTOP = 257,
              LH   = 48,
              DW   = 12,
              BT   = 2,
              SP   = 3;

    wire [10:0]Yr = vcounter - YTOP;

    wire [3:0]lyr = (Yr >= 11'd336) ? 4'd7 :
                    (Yr >= 11'd288) ? 4'd6 :
                    (Yr >= 11'd240) ? 4'd5 :
                    (Yr >= 11'd192) ? 4'd4 :
                    (Yr >= 11'd144) ? 4'd3 :
                    (Yr >= 11'd96 ) ? 4'd2 :
                    (Yr >= 11'd48 ) ? 4'd1 : 4'd0;

    wire [10:0]Rr = Yr - (lyr * LH);
    wire [10:0]W  = (4'd8 - lyr) * DW - (Rr >> SP);
    wire [10:0]Xl = XL - W + 11'd1;
    wire [10:0]Yt = YTOP + (lyr * LH);
    wire [10:0]Yb = Yt + LH - 11'd1;

    wire in_box   = (vcounter >= YTOP) && (vcounter < (YTOP + 8*LH)) &&
                    (hcounter >= (XL - 8*DW + 1)) && (hcounter <= XL);
    wire in_layer = in_box && (hcounter >= Xl);

    wire ed_l = (hcounter <  (Xl + BT));
    wire ed_r = (hcounter >  (XL - BT));
    wire ed_t = (vcounter <  (Yt + BT));
    wire ed_b = (vcounter >  (Yb - BT));
    wire ed = ed_l || ed_r || ed_t || ed_b;

    assign margin = in_layer && ed;
    assign inner = in_layer && (!ed);
    assign on = ((7 - lyr) < (speed_level + 1));
    assign cur = ((7 - lyr) == speed_level);

endmodule
