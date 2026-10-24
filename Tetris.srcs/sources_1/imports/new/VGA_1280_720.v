// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 导入模块：VGA_1280_720
// 本工程用途：生成 1280x720 显示时序和像素坐标。
//============================================================
module VGA_1280_720(
    Clk_74M,
    Reset_n,
    Data_in,
    hcounter,
    vcounter,
    VGA_HS,
    VGA_VS,
    VGA_BLK,
    VGA_CLK,
    VGA_DATA,
    raw_h,
    raw_v
    );

    input Clk_74M;
    input Reset_n;
    input [23:0]Data_in;
    output [10:0]hcounter;
    output [10:0]vcounter;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLK;
    output VGA_CLK;
    output [23:0]VGA_DATA;

    output [10:0]raw_h;
    output [10:0]raw_v;
    assign raw_h = hcounter_r;
    assign raw_v = vcounter_r;

    reg [10:0]hcounter_r;
    reg [10:0]vcounter_r;

parameter VGA_HS_End   = 39;  // 行同步结束计数
parameter hdat_begin   = 259;  // 有效像素区起始（前一个计数）
parameter hdat_end     = 1539;  // 有效像素区结束计数
parameter hpixel_end   = 1649;  // 一行总计数 - 1
parameter VGA_VS_End   = 4;  // 场同步结束计数
parameter vdat_begin   = 24;  // 有效行区起始（前一个计数）
parameter vdat_end     = 744;  // 有效行区结束计数
parameter vpixel_end   = 749;  // 一帧总行数 - 1

//    行同步脉冲
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    hcounter_r <= 1'd0;
    else if(hcounter_r == hpixel_end)
    hcounter_r <= 1'd0;
    else
    hcounter_r <= hcounter_r + 1'd1;
    end

//    场同步脉冲
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    vcounter_r <= 1'd0;
    else if(hcounter_r == hpixel_end)begin
    if(vcounter_r == vpixel_end)
    vcounter_r <= 1'd0;
    else
    vcounter_r <= vcounter_r + 1'd1;
    end
    end

//    行数据与场数据
    assign VGA_CLK = !Clk_74M;
    assign VGA_BLK = ((hcounter_r >= hdat_begin) && (hcounter_r < hdat_end) && (vcounter_r >= vdat_begin) && (vcounter_r < vdat_end))?1'b1:1'b0;

    assign hcounter = (VGA_BLK) ? (hcounter_r - hdat_begin) : 11'd0;
    assign vcounter = (VGA_BLK) ? (vcounter_r - vdat_begin) : 11'd0;

    assign VGA_HS = (hcounter_r > VGA_HS_End)?1'b1:1'b0;
    assign VGA_VS = (vcounter_r > VGA_VS_End)?1'b1:1'b0;

    assign VGA_DATA =(VGA_BLK)?(Data_in):24'h000000;

endmodule
