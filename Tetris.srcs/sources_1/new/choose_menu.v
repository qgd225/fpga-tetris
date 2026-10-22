module choose_menu(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input choose,
    input [3:0]choose_cnt,

    output margin,
    output inner,
    output text,
    output dim,
    output reg breath
    );

    parameter [10:0]TX  = 11'd496,
                     TY  = 11'd96,
                     OX  = 11'd452,
                     OY1 = 11'd260,
                     OY2 = 11'd420,
                     MX  = 11'd424,
                     MW  = 11'd4,
                     UY1 = 11'd336,
                     UY2 = 11'd496,
                     UH  = 11'd2,
                     LU  = 11'd376,
                     HX1 = 11'd438,
                     HY1 = 11'd560,
                     HX2 = 11'd498,
                     HY2 = 11'd604;

    wire sel1 = (choose_cnt == 4'd0);
    wire sel2 = (choose_cnt == 4'd1);

    wire bar1 = choose && sel1 && (hcounter >= MX) && (hcounter < (MX + MW)) &&
                (vcounter >= OY1) && (vcounter < (OY1 + 11'd64));
    wire lin1 = choose && sel1 && (hcounter >= OX) && (hcounter < (OX + LU)) &&
                (vcounter >= UY1) && (vcounter < (UY1 + UH));
    wire bar2 = choose && sel2 && (hcounter >= MX) && (hcounter < (MX + MW)) &&
                (vcounter >= OY2) && (vcounter < (OY2 + 11'd64));
    wire lin2 = choose && sel2 && (hcounter >= OX) && (hcounter < (OX + LU)) &&
                (vcounter >= UY2) && (vcounter < (UY2 + UH));

    wire rule_t = choose && (hcounter >= 11'd496) && (hcounter < 11'd784) &&
                  (vcounter >= 11'd180) && (vcounter < 11'd182);
    assign margin = bar1 || lin1 || bar2 || lin2 || rule_t;
    assign inner  = 1'b0;

    integer i;

    reg [10:0]X;
    reg [10:0]Y;
    reg ena;
    reg ena_n;
    reg [4:0]cnt;
    reg big;
    reg in1;
    reg in2;

    wire [10:0]hn = hcounter + 11'd1;

    reg [26:0]br_cnt;
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    br_cnt <= 27'd0;
    breath <= 1'b0;
    end
    else if(br_cnt == 27'd44_550_000)begin
    br_cnt <= 27'd0;
    breath <= !breath;
    end
    else
    br_cnt <= br_cnt + 27'd1;
    end

    always@(*)begin
    X = 11'd0;
    Y = 11'd0;
    ena = 1'b0;
    ena_n = 1'b0;
    cnt = 5'd26;
    big = 1'b1;
    in1 = 1'b0;
    in2 = 1'b0;
        if(choose)begin

            for(i = 0; i < 6; i = i + 1)begin
                if( (hcounter >= (TX + i*48)) && (hcounter < (TX + i*48 + 40)) &&
                    (vcounter >= TY) && (vcounter < (TY + 64)) )begin
                    ena = 1'b1;
                    X = TX + i*48;
                    Y = TY;
                end
                if( (hn >= (TX + i*48 - 1)) && (hn < (TX + i*48 + 40)) &&
                    (vcounter >= TY) && (vcounter < (TY + 64)) )begin
                    ena_n = 1'b1;
                    Y = TY;
                    case(i)
                    0:cnt = 5'd19;
                    1:cnt = 5'd4;
                    2:cnt = 5'd19;
                    3:cnt = 5'd17;
                    4:cnt = 5'd8;
                    5:cnt = 5'd18;
                    default:cnt = 5'd26;
                    endcase
                end
            end

            for(i = 0; i < 8; i = i + 1)begin
                if( (hcounter >= (OX + i*48)) && (hcounter < (OX + i*48 + 40)) &&
                    (vcounter >= OY1) && (vcounter < (OY1 + 64)) )begin
                    ena = 1'b1;
                    X = OX + i*48;
                    Y = OY1;
                    in1 = 1'b1;
                end
                if( (hn >= (OX + i*48 - 1)) && (hn < (OX + i*48 + 40)) &&
                    (vcounter >= OY1) && (vcounter < (OY1 + 64)) )begin
                    ena_n = 1'b1;
                    Y = OY1;
                    case(i)
                    0:cnt = 5'd18;
                    1:cnt = 5'd14;
                    2:cnt = 5'd11;
                    3:cnt = 5'd14;
                    4:cnt = 5'd26;
                    5:cnt = 5'd15;
                    6:cnt = 5'd21;
                    7:cnt = 5'd4;
                    default:cnt = 5'd26;
                    endcase
                end
                if( (hcounter >= (OX + i*48)) && (hcounter < (OX + i*48 + 40)) &&
                    (vcounter >= OY2) && (vcounter < (OY2 + 64)) )begin
                    ena = 1'b1;
                    X = OX + i*48;
                    Y = OY2;
                    in2 = 1'b1;
                end
                if( (hn >= (OX + i*48 - 1)) && (hn < (OX + i*48 + 40)) &&
                    (vcounter >= OY2) && (vcounter < (OY2 + 64)) )begin
                    ena_n = 1'b1;
                    Y = OY2;
                    case(i)
                    0:cnt = 5'd3;
                    1:cnt = 5'd20;
                    2:cnt = 5'd14;
                    3:cnt = 5'd26;
                    4:cnt = 5'd15;
                    5:cnt = 5'd21;
                    6:cnt = 5'd4;
                    7:cnt = 5'd26;
                    default:cnt = 5'd26;
                    endcase
                end
            end

            for(i = 0; i < 17; i = i + 1)begin
                if( (hcounter >= (HX1 + i*24)) && (hcounter < (HX1 + i*24 + 20)) &&
                    (vcounter >= HY1) && (vcounter < (HY1 + 32)) )begin
                    ena = 1'b1;
                    X = HX1 + i*24;
                    Y = HY1;
                    big = 1'b0;
                end
                if( (hn >= (HX1 + i*24 - 1)) && (hn < (HX1 + i*24 + 20)) &&
                    (vcounter >= HY1) && (vcounter < (HY1 + 32)) )begin
                    ena_n = 1'b1;
                    Y = HY1;
                    big = 1'b0;
                    case(i)
                    0:cnt = 5'd11;
                    1:cnt = 5'd4;
                    2:cnt = 5'd5;
                    3:cnt = 5'd19;
                    4:cnt = 5'd26;
                    5:cnt = 5'd17;
                    6:cnt = 5'd8;
                    7:cnt = 5'd6;
                    8:cnt = 5'd7;
                    9:cnt = 5'd19;
                    10:cnt = 5'd26;
                    11:cnt = 5'd18;
                    12:cnt = 5'd4;
                    13:cnt = 5'd11;
                    14:cnt = 5'd4;
                    15:cnt = 5'd2;
                    16:cnt = 5'd19;
                    default:cnt = 5'd26;
                    endcase
                end
            end

            for(i = 0; i < 12; i = i + 1)begin
                if( (hcounter >= (HX2 + i*24)) && (hcounter < (HX2 + i*24 + 20)) &&
                    (vcounter >= HY2) && (vcounter < (HY2 + 32)) )begin
                    ena = 1'b1;
                    X = HX2 + i*24;
                    Y = HY2;
                    big = 1'b0;
                end
                if( (hn >= (HX2 + i*24 - 1)) && (hn < (HX2 + i*24 + 20)) &&
                    (vcounter >= HY2) && (vcounter < (HY2 + 32)) )begin
                    ena_n = 1'b1;
                    Y = HY2;
                    big = 1'b0;
                    case(i)
                    0:cnt = 5'd18;
                    1:cnt = 5'd22;
                    2:cnt = 5'd8;
                    3:cnt = 5'd19;
                    4:cnt = 5'd2;
                    5:cnt = 5'd7;
                    6:cnt = 5'd26;
                    7:cnt = 5'd18;
                    8:cnt = 5'd19;
                    9:cnt = 5'd0;
                    10:cnt = 5'd17;
                    11:cnt = 5'd19;
                    default:cnt = 5'd26;
                    endcase
                end
            end
        end
    end

    wire [19:0]douta;
    wire [10:0]dv = vcounter - Y;
    wire [5:0]vt = big ? dv[6:1] : dv[5:0];
    wire [10:0]ht = big ? ((hcounter - X) >> 1) : (hcounter - X);

    assign text = ena ? douta[19 - ht] : 1'b0;
    assign dim  = choose && ((in1 && sel2) || (in2 && sel1));

    letter letter_inst0(
    .clka(Clk_74M),
    .ena(ena_n),
    .addra({cnt, vt}),
    .douta(douta)
    );

endmodule
