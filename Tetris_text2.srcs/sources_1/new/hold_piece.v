module hold_piece(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input duo,
    input [2:0]hold_type,
    input en_hold,
    
    output reg hold,
    output reg hold_margin
    );
    
    //    单人: 盒子 x1040-1200, y264-424; 双人: 右移下移到 x1104-1264, y360-520
    wire [10:0]XB = duo ? 11'd1104 : 11'd1040;
    wire [10:0]XE = duo ? 11'd1264 : 11'd1200;
    wire [10:0]YB = duo ? 11'd360  : 11'd264;
    wire [10:0]YE = duo ? 11'd520  : 11'd424;
    wire [10:0]XI = duo ? 11'd1121 : 11'd1057;
    wire [10:0]Y1 = duo ? 11'd377  : 11'd281;

    integer i;
    
    reg [1:0]C_num;
    reg [1:0]R_num;
    reg [3:0]cc;
    reg [3:0]rr;
    
    always@(*)begin
    if(     (hcounter >= XB && hcounter < (XB + 11'd3) && vcounter >= YB && vcounter < YE) ||
            (hcounter >= (XE - 11'd3) && hcounter < XE && vcounter >= YB && vcounter < YE) ||
            (hcounter >= XB && hcounter < XE && vcounter >= YB && vcounter < (YB + 11'd3)) ||
            (hcounter >= XB && hcounter < XE && vcounter >= (YE - 11'd3) && vcounter < YE))
    hold_margin = 1'b1;
    else
    hold_margin = 1'b0;
    end
    
    integer o;
    integer p;
    
    always@(*)begin : blk1
        integer o, p;
    C_num = 11'd0;
    for(o = 0; o < 4; o = o + 1)
    for(p = 0; p < 4; p = p + 1)
    if(hcounter >= (XI + 32*o) && hcounter < (XI + 30 + 32*o) && vcounter >= (Y1 + 32*p) && vcounter < (Y1 + 30 + 32*p))
    C_num = o;
    end
    
    always@(*)begin : blk2
        integer o, p;
    R_num = 11'd0;
    for(p = 0; p < 4; p = p + 1)
    for(o = 0; o < 4; o = o + 1)
    if(hcounter >= (XI + 32*o) && hcounter < (XI + 30 + 32*o) && vcounter >= (Y1 + 32*p) && vcounter < (Y1 + 30 + 32*p))
    R_num = p;
    end
    
    wire [31:0]Tetromino_dout;
    reg  [4:0]Tetromino_addr; 
    
    Tetromino Tetromino_inst0(
        .clka(Clk_74M),
        .addra(Tetromino_addr),
        .douta(Tetromino_dout) 
    );
    
    always@(*)begin
    if(Idle)
    hold = 1'b0;
    else if(!en_hold)
    hold = 1'b0;
    else begin
    Tetromino_addr = {hold_type[2:0],2'b0};
    hold = 0;
    for(i = 0; i < 4; i = i + 1)begin
        cc = 1 + { { 7{Tetromino_dout[i*8+7]} }, Tetromino_dout[(i*8+7)-:4] };
        rr = 3 + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
        if((C_num == cc) && (R_num == rr) && !rr[3]) 
        hold = 1'b1;
        end
    end
    end
    
endmodule

