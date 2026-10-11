module Next_piece(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input [2:0]type_t,
    
    output reg next,
    output reg next_margin
    );
    
    integer i;
    
    reg [1:0]C_num;
    reg [1:0]R_num;
    reg [3:0]cc;
    reg [3:0]rr;
    
    always@(*)begin
    if(     (hcounter >= 1040 && hcounter < 1043 &&  vcounter >= 64 && vcounter < 224) ||
            (hcounter >= 1197 && hcounter < 1200 &&  vcounter >= 64 && vcounter < 224) ||
            (hcounter >= 1040 && hcounter < 1200 &&  vcounter >= 64 && vcounter < 67) ||
            (hcounter >= 1040 && hcounter < 1200 &&  vcounter >= 221 && vcounter < 224))
    next_margin = 1'b1;
    else
    next_margin = 1'b0;
    end
    
    integer o;
    integer p;
    
    always@(*)begin
    C_num = 11'd0;
    for(o = 0; o < 4; o = o + 1)
    for(p = 0; p < 4; p = p + 1)
    if(hcounter >= (1057 + 32*o) && hcounter < (1087 + 32*o) && vcounter >= (81 + 32*p) && vcounter < (111 + 32*p))
    C_num = o;
    end
    
    always@(*)begin
    R_num = 11'd0;
    for(p = 0; p < 4; p = p + 1)
    for(o = 0; o < 4; o = o + 1)
    if(hcounter >= (1057 + 32*o) && hcounter < (1087 + 32*o) && vcounter >= (81 + 32*p) && vcounter < (111 + 32*p))
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
    next = 1'b0;
    else begin
    Tetromino_addr = {type_t[2:0],2'b0};
    next = 0;
    for(i = 0; i < 4; i = i + 1)begin
        cc = 1 + { { 7{Tetromino_dout[i*8+7]} }, Tetromino_dout[(i*8+7)-:4] };
        rr = 3 + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
        if((hcounter >= 1040) && (hcounter < 1200) && (vcounter >= 64) && (vcounter < 224) && (C_num == cc) && (R_num == rr) && !rr[3]) 
        next = 1'b1;
        end
    end
    end
    
endmodule
