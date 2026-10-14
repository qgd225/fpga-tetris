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
    output dim
    );
    
    parameter [10:0]BX  = 11'd420,
                     BW  = 11'd440,
                     BH  = 11'd120,
                     BT  = 11'd2,
                     BY1 = 11'd210,
                     BY2 = 11'd390;
    
    parameter [10:0]TX1 = 11'd452,
                     TY1 = 11'd238,
                     TX2 = 11'd476,
                     TY2 = 11'd418;
    
    parameter [24:0]BLINK_CNT = 25'd33_412_500;
    
    reg [24:0]blink_cnt;
    reg        blink;
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    blink_cnt <= 25'd0;
    else if(!choose)
    blink_cnt <= 25'd0;
    else if(blink_cnt == BLINK_CNT)
    blink_cnt <= 25'd0;
    else
    blink_cnt <= blink_cnt + 25'd1;
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    blink <= 1'b1;
    else if(!choose)
    blink <= 1'b1;
    else if(blink_cnt == BLINK_CNT)
    blink <= ~blink;
    end
    
    wire sel1 = (choose_cnt == 4'd0);
    wire sel2 = (choose_cnt == 4'd1);
    
    wire y1 = (vcounter >= BY1) && (vcounter < (BY1 + BH));
    wire y2 = (vcounter >= BY2) && (vcounter < (BY2 + BH));
    
    wire in1 = y1 && (hcounter >= BX) && (hcounter < (BX + BW));
    wire in2 = y2 && (hcounter >= BX) && (hcounter < (BX + BW));
    
    wire ed1 = (hcounter < (BX + BT)) || (hcounter >= (BX + BW - BT)) ||
               (vcounter < (BY1 + BT)) || (vcounter >= (BY1 + BH - BT));
    wire ed2 = (hcounter < (BX + BT)) || (hcounter >= (BX + BW - BT)) ||
               (vcounter < (BY2 + BT)) || (vcounter >= (BY2 + BH - BT));
    
    wire show1 = choose && in1;
    wire show2 = choose && in2;
    
    assign margin = (show1 && ed1) || (show2 && ed2);
    assign inner  = (show1 && (!ed1)) || (show2 && (!ed2));
    assign dim    = choose && (!blink) && ((in1 && sel1) || (in2 && sel2));
    
    integer i;
    
    reg [10:0]X;
    reg [10:0]Y;
    reg ena;
    reg ena_n;
    reg [4:0]cnt;
    
    wire [10:0]hn = hcounter + 11'd1;
    
    always@(*)begin
    X = 11'd0;
    Y = 11'd0;
    ena = 1'b0;
    ena_n = 1'b0;
    cnt = 5'd26;
        if(choose)begin
            for(i = 0; i < 8; i = i + 1)begin
                if( (hcounter >= (TX1 + i*48)) && (hcounter < (TX1 + i*48 + 40)) &&
                    (vcounter >= TY1) && (vcounter < (TY1 + 64)) )begin
                    ena = 1'b1;
                    X = TX1 + i*48;
                    Y = TY1;
                end
                if( (hn >= (TX1 + i*48 - 1)) && (hn < (TX1 + i*48 + 40)) &&
                    (vcounter >= TY1) && (vcounter < (TY1 + 64)) )begin
                    ena_n = 1'b1;
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
                if( (hcounter >= (TX2 + i*48)) && (hcounter < (TX2 + i*48 + 40)) &&
                    (vcounter >= TY2) && (vcounter < (TY2 + 64)) )begin
                    ena = 1'b1;
                    X = TX2 + i*48;
                    Y = TY2;
                end
                if( (hn >= (TX2 + i*48 - 1)) && (hn < (TX2 + i*48 + 40)) &&
                    (vcounter >= TY2) && (vcounter < (TY2 + 64)) )begin
                    ena_n = 1'b1;
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
        end
    end
    
    wire [19:0]douta;
    wire [5:0]vt = (vcounter - Y) >> 1;
    wire [10:0]ht = (hcounter - X) >> 1;
    
    assign text = ena ? douta[19 - ht] : 1'b0;
    
    letter letter_inst0(
    .clka(Clk_74M),
    .ena(ena_n),
    .addra({cnt, vt}),
    .douta(douta)
    );
    
endmodule