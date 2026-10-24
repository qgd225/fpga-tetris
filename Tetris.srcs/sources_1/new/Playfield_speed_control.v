// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 任务控制器是唯一速度来源；仅选择八档自动下落周期。
module Playfield_speed_control #(
    parameter MCNT_Drop = 74_218_750 - 1
)(
    input Clk_74M, Reset_n,
    input [2:0] story_speed,
    output wire [2:0] speed_level,
    output reg [29:0] Drop
);
    assign speed_level = story_speed;
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) Drop <= (MCNT_Drop*64'd80)/64'd100;
        else case(story_speed)
            0:Drop <= (MCNT_Drop*64'd80)/64'd100;
            1:Drop <= (MCNT_Drop*64'd71)/64'd100;
            2:Drop <= (MCNT_Drop*64'd63)/64'd100;
            3:Drop <= (MCNT_Drop*64'd55)/64'd100;
            4:Drop <= (MCNT_Drop*64'd46)/64'd100;
            5:Drop <= (MCNT_Drop*64'd38)/64'd100;
            6:Drop <= (MCNT_Drop*64'd30)/64'd100;
            7:Drop <= (MCNT_Drop*64'd21)/64'd100;
        endcase
    end
endmodule
