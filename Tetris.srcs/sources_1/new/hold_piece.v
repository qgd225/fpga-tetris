//============================================================
// 模块：hold_piece
// 作用：HOLD 槽位预览：读取暂存方块并生成槽内显示坐标。
// 时钟/复位：Clk_74M；Reset_n 低有效
//============================================================
module hold_piece(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input duo,
    input [2:0]hold_type,
    input en_hold,
    input [10:0]X1,
    input [10:0]Y1,
    input [10:0]X2,
    input [10:0]Y2,

    output reg hold,
    output hold_margin,
    output reg hold_slot
    );

//    Hold 槽位与 Next 同规格(4x4 个 32px 格子), 方块第 0 格画在 (1,3)
    reg [1:0]C_num;
    reg [1:0]R_num;
    reg [1:0]C_num2;
    reg [1:0]R_num2;
    reg [3:0]cc;
    reg [3:0]rr;

//    P1 槽位行列号
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

//    P2 槽位行列号(仅双人)
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

//    槽位底色区域
    always@(*)begin
    hold_slot = 1'b0;
    if((hcounter >= X1) && (hcounter < (X1 + 11'd128)) && (vcounter >= Y1) && (vcounter < (Y1 + 11'd128)))
    hold_slot = 1'b1;
    else if(duo && (hcounter >= X2) && (hcounter < (X2 + 11'd128)) && (vcounter >= Y2) && (vcounter < (Y2 + 11'd128)))
    hold_slot = 1'b1;
    end

    wire [31:0]Tetromino_dout;
    reg  [4:0]Tetromino_addr;

    Tetromino Tetromino_inst0(
        .clka(Clk_74M),
        .addra(Tetromino_addr),
        .douta(Tetromino_dout)
    );

//    Hold 里的方块(Idle 或还没存过时不画)
    always@(*)begin : blk3
        integer i1;
    if(Idle || !en_hold)
    hold = 1'b0;
    else begin
    Tetromino_addr = {hold_type[2:0],2'b0};
    hold = 0;
    for(i1 = 0; i1 < 4; i1 = i1 + 1)begin
        cc = 1 + { { 7{Tetromino_dout[i1*8+7]} }, Tetromino_dout[(i1*8+7)-:4] };
        rr = 3 + { { 7{Tetromino_dout[i1*8+3]} }, Tetromino_dout[(i1*8+3)-:4] };
        if(((C_num == cc) && (R_num == rr) && !rr[3]) ||
           (duo && (C_num2 == cc) && (R_num2 == rr) && !rr[3]))
        hold = 1'b1;
    end
    end
    end

    assign hold_margin = 1'b0;  //外框已删

endmodule
