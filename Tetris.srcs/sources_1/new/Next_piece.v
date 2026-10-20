module Next_piece(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input duo,
    input [2:0]type_t,
    input [2:0]type_t2,
    input [10:0]X1,
    input [10:0]Y1,
    input [10:0]X2,
    input [10:0]Y2,

    output reg next,
    output reg next2,
    output next_margin,
    output reg next_slot
    );

//    无框面板: 预览区是 4x4 个 32px 格子组成的槽位(底色由 frame 画)
//    格子编号从槽位左上角算起, 方块第 0 格画在 (1,3) 的位置, 与原来一致
    reg [1:0]C_num;
    reg [1:0]R_num;
    reg [1:0]C_num2;
    reg [1:0]R_num2;
    reg [3:0]cc;
    reg [3:0]rr;

//    P1 预览槽位的行列号
    always@(*)begin : blk1
        integer o1, p1;
    C_num = 2'd0;
    R_num = 2'd0;
    for(o1 = 0; o1 < 4; o1 = o1 + 1)
    for(p1 = 0; p1 < 4; p1 = p1 + 1)
    if((hcounter >= (X1 + 32*o1)) && (hcounter < (X1 + 30 + 32*o1)) &&
       (vcounter >= (Y1 + 32*p1)) && (vcounter < (Y1 + 30 + 32*p1)))begin
        C_num = o1[1:0];
        R_num = p1[1:0];
    end
    end

//    P2 预览槽位的行列号(仅双人)
    always@(*)begin : blk2
        integer o2, p2;
    C_num2 = 2'd0;
    R_num2 = 2'd0;
    for(o2 = 0; o2 < 4; o2 = o2 + 1)
    for(p2 = 0; p2 < 4; p2 = p2 + 1)
    if(duo && (hcounter >= (X2 + 32*o2)) && (hcounter < (X2 + 30 + 32*o2)) &&
       (vcounter >= (Y2 + 32*p2)) && (vcounter < (Y2 + 30 + 32*p2)))begin
        C_num2 = o2[1:0];
        R_num2 = p2[1:0];
    end
    end

//    槽位底色区域: 双人两块, 单人一块
    always@(*)begin
    next_slot = 1'b0;
    if((hcounter >= X1) && (hcounter < (X1 + 11'd128)) && (vcounter >= Y1) && (vcounter < (Y1 + 11'd128)))
    next_slot = 1'b1;
    else if(duo && (hcounter >= X2) && (hcounter < (X2 + 11'd128)) && (vcounter >= Y2) && (vcounter < (Y2 + 11'd128)))
    next_slot = 1'b1;
    end

    wire [31:0]Tetromino_dout;
    reg  [4:0]Tetromino_addr;
    wire [31:0]Tetromino_dout2;
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

//    P1 下一块预览
    always@(*)begin : blk3
        integer i1;
    if(Idle)
    next = 1'b0;
    else begin
    Tetromino_addr = {type_t[2:0],2'b0};
    next = 0;
    for(i1 = 0; i1 < 4; i1 = i1 + 1)begin
        cc = 1 + { { 7{Tetromino_dout[i1*8+7]} }, Tetromino_dout[(i1*8+7)-:4] };
        rr = 3 + { { 7{Tetromino_dout[i1*8+3]} }, Tetromino_dout[(i1*8+3)-:4] };
        if((C_num == cc) && (R_num == rr) && !rr[3])
        next = 1'b1;
    end
    end
    end

//    P2 下一块预览(仅双人)
    always@(*)begin : blk4
        integer i2;
    if(Idle || !duo)
    next2 = 1'b0;
    else begin
    Tetromino_addr2 = {type_t2[2:0],2'b0};
    next2 = 0;
    for(i2 = 0; i2 < 4; i2 = i2 + 1)begin
        cc = 1 + { { 7{Tetromino_dout2[i2*8+7]} }, Tetromino_dout2[(i2*8+7)-:4] };
        rr = 3 + { { 7{Tetromino_dout2[i2*8+3]} }, Tetromino_dout2[(i2*8+3)-:4] };
        if((C_num2 == cc) && (R_num2 == rr) && !rr[3])
        next2 = 1'b1;
    end
    end
    end

    assign next_margin = 1'b0;//外框与虚线已删, 改为 frame 里的文字标签 + 2px 分隔线

endmodule
