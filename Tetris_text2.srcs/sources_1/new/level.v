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

//    等级: 场地左侧 8 段竖条(x 284..302, y 88..712), 每段 78px, 段顶部 2px 是缝
//    margin=缝(画暗色)  inner=段体  on=已达段  cur=当前段
    parameter [10:0]BX = 11'd280,
                     BY = 11'd88,
                     BW = 11'd26,
                     SH = 11'd78;

    wire [10:0]Yr = vcounter - BY;
    wire [3:0] si = (Yr >= 11'd546) ? 4'd7 :
                    (Yr >= 11'd468) ? 4'd6 :
                    (Yr >= 11'd390) ? 4'd5 :
                    (Yr >= 11'd312) ? 4'd4 :
                    (Yr >= 11'd234) ? 4'd3 :
                    (Yr >= 11'd156) ? 4'd2 :
                    (Yr >= 11'd78 ) ? 4'd1 : 4'd0;
    wire [10:0]Rr = Yr - (si * SH);
    wire [3:0] sib = 4'd7 - si;//从下往上的段号: 0 在最底
    wire in_bar = (vcounter >= BY) && (vcounter < (BY + 11'd624)) &&
                  (hcounter >= BX) && (hcounter < (BX + BW));

    assign margin = in_bar && (Rr < 11'd2);
    assign inner  = in_bar && (Rr >= 11'd2);
    assign on     = (sib <= {1'b0, speed_level});
    assign cur    = (sib == {1'b0, speed_level});

endmodule
