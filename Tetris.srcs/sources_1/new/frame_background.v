// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: frame_background
// 作用: 生成场外、场内和菜单的静态背景颜色, 供 frame 合成图层。
// 时钟/复位: 组合逻辑。
//============================================================
module frame_background(
    input [10:0] hcounter,
    input [10:0] vcounter,
    input [10:0] right_edge,
    input duo,
    input in_field,
    input [23:0] field_bg,
    output reg [23:0] outer_color,
    output reg [23:0] inner_color,
    output wire [23:0] menu_color
);
    wire [10:0] field_mid = (11'd321 + right_edge) >> 1;
    wire field_node_row = (vcounter[5:0] >= 6'd47) &&
                          (vcounter[5:0] <= 6'd51);

    always @(*) begin
        outer_color = 24'h061017;
        if (vcounter < 11'd75)
            outer_color = 24'h071018;
        if ((vcounter == 11'd74) || (vcounter == 11'd82) ||
            (vcounter == 11'd306) || (vcounter == 11'd520) ||
            (vcounter == 11'd710))
            outer_color = 24'h29404D;
        if ((hcounter == 11'd12) || (hcounter == 11'd82) ||
            (hcounter == 11'd224) || (hcounter == 11'd313) ||
            (hcounter == (duo ? 11'd1117 : 11'd1024)) ||
            (hcounter == (duo ? 11'd1265 : 11'd1204)))
            outer_color = 24'h29404D;
        if (((hcounter >= 11'd22) && (hcounter <= 11'd76) &&
             (((vcounter >= 11'd112) && (vcounter <= 11'd162)) ||
              ((vcounter >= 11'd214) && (vcounter <= 11'd264)))) ||
            ((hcounter >= 11'd1230) && (hcounter <= 11'd1266) &&
             (((vcounter >= 11'd112) && (vcounter <= 11'd162)) ||
              ((vcounter >= 11'd214) && (vcounter <= 11'd264)))) )
            outer_color = 24'h02070B;
        if (((hcounter == 11'd32) &&
             ((vcounter == 11'd130) || (vcounter == 11'd232))) ||
            ((hcounter == 11'd50) &&
             ((vcounter == 11'd122) || (vcounter == 11'd242))) ||
            ((hcounter == 11'd64) &&
             ((vcounter == 11'd142) || (vcounter == 11'd224))) ||
            ((hcounter == 11'd1238) &&
             ((vcounter == 11'd128) || (vcounter == 11'd232))) ||
            ((hcounter == 11'd1254) &&
             ((vcounter == 11'd142) || (vcounter == 11'd222))))
            outer_color = 24'h536A76;
        if (((vcounter == 11'd164) || (vcounter == 11'd318) ||
             (vcounter == 11'd472) || (vcounter == 11'd626)) &&
            (((hcounter >= 11'd224) && (hcounter < 11'd321)) ||
             ((hcounter >= right_edge) &&
              (hcounter <= (right_edge + 11'd21)))) )
            outer_color = (hcounter < 11'd321) ? 24'h08798A : 24'h7B2B54;
        if ((hcounter == 11'd94) &&
            (vcounter >= 11'd84) && (vcounter < 11'd710))
            outer_color = 24'h00E5FF;
        if ((hcounter == (duo ? 11'd1249 : 11'd1188)) &&
            (vcounter >= 11'd84) && (vcounter < 11'd710))
            outer_color = duo ? 24'hFF4DA6 : 24'h00E5FF;
        if ((((hcounter >= 11'd18) && (hcounter <= 11'd24)) ||
             ((hcounter >= 11'd1244) && (hcounter <= 11'd1250))) &&
            (((vcounter >= 11'd160) && (vcounter <= 11'd168)) ||
             ((vcounter >= 11'd396) && (vcounter <= 11'd404)) ||
             ((vcounter >= 11'd686) && (vcounter <= 11'd694))))
            outer_color = 24'h80551F;
        if ((((hcounter >= 11'd15) && (hcounter <= 11'd21)) ||
             ((hcounter >= 11'd1249) && (hcounter <= 11'd1255))) &&
            (vcounter >= 11'd93) && (vcounter <= 11'd99))
            outer_color = 24'h00E5FF;

        inner_color = field_bg;
        if (in_field) begin
            if ((((hcounter - 11'd321) & 11'd31) == 11'd0) ||
                (((vcounter - 11'd81) & 11'd31) == 11'd0))
                inner_color = 24'h0D2029;
            if ((vcounter >= 11'd81) && (vcounter <= 11'd83))
                inner_color = 24'h536A76;
            if ((hcounter == 11'd343) ||
                (hcounter == (right_edge - 11'd23)))
                inner_color = (hcounter == 11'd343) ?
                              24'h08798A : 24'h7B2B54;
            if (((hcounter == 11'd343) ||
                 (hcounter == (right_edge - 11'd23))) && field_node_row)
                inner_color = (hcounter < field_mid) ?
                              24'h08798A : 24'h7B2B54;
            if ((hcounter == field_mid) && ((vcounter & 11'd63) < 11'd24))
                inner_color = 24'h17414B;
            if ((vcounter >= 11'd700) && (vcounter <= 11'd715))
                inner_color = 24'h09171C;
            if ((vcounter >= 11'd701) && (vcounter <= 11'd713) &&
                (((hcounter - 11'd321) & 11'd31) ==
                 ((vcounter - 11'd700) & 11'd31)))
                inner_color = 24'h80551F;
            if ((hcounter == 11'd326) ||
                (hcounter == (right_edge - 11'd5)))
                inner_color = 24'h536A76;
        end
    end

    assign menu_color = outer_color;
endmodule
