module Next_piece(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input duo,
    input [2:0]type_t,
    input [2:0]type_t2,
    
    output reg next,
    output reg next2,
    output reg next_margin
    );
    
    //    单人: 盒子 x1040-1200, y64-224, 预览内区 x1057 起, y81 起
    //    双人: 盒子 x1104-1264, y64-344, 中间一条水平虚线, 上=P1 下一块, 下=P2 下一块
    wire [10:0]XB  = duo ? 11'd1104 : 11'd1040;
    wire [10:0]XE  = duo ? 11'd1264 : 11'd1200;
    wire [10:0]YB  = 11'd64;
    wire [10:0]YE  = duo ? 11'd344  : 11'd224;
    wire [10:0]XI  = duo ? 11'd1121 : 11'd1057;
    wire [10:0]YS1 = duo ? 11'd72   : 11'd81;
    wire [10:0]YS2 = 11'd212;

    wire dash = duo && (vcounter >= 11'd202) && (vcounter < 11'd206) &&
                (hcounter >= (XB + 11'd3)) && (hcounter < (XE - 11'd3)) &&
                (hcounter[3:0] < 4'd8);

    always@(*)begin
    if(     (hcounter >= XB && hcounter < (XB + 11'd3) && vcounter >= YB && vcounter < YE) ||
            (hcounter >= (XE - 11'd3) && hcounter < XE && vcounter >= YB && vcounter < YE) ||
            (hcounter >= XB && hcounter < XE && vcounter >= YB && vcounter < (YB + 11'd3)) ||
            (hcounter >= XB && hcounter < XE && vcounter >= (YE - 11'd3) && vcounter < YE) ||
            dash)
    next_margin = 1'b1;
    else
    next_margin = 1'b0;
    end
    
    integer i;
    integer o;
    integer p;
    
    reg [1:0]C_num;
    reg [1:0]R_num;
    reg [1:0]C_num2;
    reg [1:0]R_num2;
    reg [3:0]cc;
    reg [3:0]rr;
    
    always@(*)begin : blk1
        integer o, p;
    C_num  = 2'd0;
    C_num2 = 2'd0;
    for(o = 0; o < 4; o = o + 1)
    for(p = 0; p < 4; p = p + 1)
    if(hcounter >= (XI + 32*o) && hcounter < (XI + 30 + 32*o))begin
        if(vcounter >= (YS1 + 32*p) && vcounter < (YS1 + 30 + 32*p))
        C_num = o[1:0];
        if(duo && (vcounter >= (YS2 + 32*p) && vcounter < (YS2 + 30 + 32*p)))
        C_num2 = o[1:0];
    end
    end
    
    always@(*)begin : blk2
        integer o, p;
    R_num  = 2'd0;
    R_num2 = 2'd0;
    for(p = 0; p < 4; p = p + 1)
    for(o = 0; o < 4; o = o + 1)
    if(hcounter >= (XI + 32*o) && hcounter < (XI + 30 + 32*o))begin
        if(vcounter >= (YS1 + 32*p) && vcounter < (YS1 + 30 + 32*p))
        R_num = p[1:0];
        if(duo && (vcounter >= (YS2 + 32*p) && vcounter < (YS2 + 30 + 32*p)))
        R_num2 = p[1:0];
    end
    end
    
    wire [31:0]Tetromino_dout;
    wire [31:0]Tetromino_dout2;
    reg  [4:0]Tetromino_addr;
    reg  [4:0]Tetromino_addr2;
    
    Tetromino Tetromino_inst0(
        .clka(Clk_74M),
        .addra(Tetromino_addr),
        .douta(Tetromino_dout)
    );

    Tetromino Tetromino_inst2(
        .clka(Clk_74M),
        .addra(Tetromino_addr2),
        .douta(Tetromino_dout2)
    );
    
    always@(*)begin
    if(Idle)
    next = 1'b0;
    else begin
    Tetromino_addr = {type_t[2:0],2'b0};
    next = 0;
    for(i = 0; i < 4; i = i + 1)begin
        cc = 1 + { { 7{Tetromino_dout[i*8+7]} }, Tetromino_dout[(i*8+7)-:4] };
        rr = 3 + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
        if((hcounter >= XI) && (hcounter < (XE - 11'd15)) && (vcounter >= YS1) && (vcounter < (YS1 + 11'd128)) && (C_num == cc) && (R_num == rr) && !rr[3])
        next = 1'b1;
        end
    end
    end

    integer i2;
    reg [3:0]cc2;
    reg [3:0]rr2;

    always@(*)begin
    if(Idle || !duo)
    next2 = 1'b0;
    else begin
    Tetromino_addr2 = {type_t2[2:0],2'b0};
    next2 = 0;
    for(i2 = 0; i2 < 4; i2 = i2 + 1)begin
        cc2 = 1 + { { 7{Tetromino_dout2[i2*8+7]} }, Tetromino_dout2[(i2*8+7)-:4] };
        rr2 = 3 + { { 7{Tetromino_dout2[i2*8+3]} }, Tetromino_dout2[(i2*8+3)-:4] };
        if((hcounter >= XI) && (hcounter < (XE - 11'd15)) && (vcounter >= YS2) && (vcounter < (YS2 + 11'd128)) && (C_num2 == cc2) && (R_num2 == rr2) && !rr2[3])
        next2 = 1'b1;
        end
    end
    end
    
endmodule
