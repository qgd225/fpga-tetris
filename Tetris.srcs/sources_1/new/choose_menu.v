//============================================================
// 模块：choose_menu
// 作用：选择菜单绘制：SOLO/DUO 选项、选中标记、呼吸色和操作提示。
// 时钟/复位：Clk_74M；Reset_n 低有效
//============================================================
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

//    菜单屏: 标题 TETRIS + 两行选项(SOLO PVE / DUO PVE) + 青色选中标记 + 两行操作提示
//    全部无框; 选中的那一行左侧一条 4px 竖条, 下方一条 2px 横线
    parameter [10:0]TX  = 11'd496,  //标题 X(2x 字号)
                     TY  = 11'd96,  //标题 Y
                     OX  = 11'd452,  //选项 X(2x 字号)
                     OY1 = 11'd260,  //选项 1 Y
                     OY2 = 11'd420,  //选项 2 Y
                     MX  = 11'd424,  //选中竖条 X
                     MW  = 11'd4,  //选中竖条宽
                     UY1 = 11'd336,  //选中横线 Y(选项 1)
                     UY2 = 11'd496,  //选中横线 Y(选项 2)
                     UH  = 11'd2,  //横线高
                     LU  = 11'd376,  //横线长
                     HX1 = 11'd438,  //提示 1 X(1x 字号)
                     HY1 = 11'd560,
                     HX2 = 11'd498,  //提示 2 X
                     HY2 = 11'd604;

    wire sel1 = (choose_cnt == 4'd0);
    wire sel2 = (choose_cnt == 4'd1);

//    选中标记(仅选中的那一行)
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

//    E6: 选中标记呼吸(约 1.2s 一轮)
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

//  标题 TETRIS (2x)
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

//  选项 SOLO PVE / DUO PVE (2x)
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

//  提示 1: LEFT RIGHT SELECT (1x)
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

//  提示 2: SWITCH START (1x)
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
