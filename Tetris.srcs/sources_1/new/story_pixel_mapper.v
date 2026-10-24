// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 故事布局候选：只转换显示坐标，未接入现有场地，冻结前须全扫描/综合/实屏验证。
module story_pixel_mapper #(
    parameter CELL_PITCH = 24,
    parameter X_SOLO = 400,
    parameter X_DUO = 352,
    parameter FIELD_Y = 144
)(
    input [10:0] hcounter, vcounter,
    input duo,
    output wire in_field, cell_visible,
    output wire [4:0] column, row,
    output wire [4:0] local_x, local_y
);
    localparam FACE = CELL_PITCH-2;
    wire [10:0] field_x = duo ? X_DUO : X_SOLO;
    wire [10:0] field_right = field_x + (duo ? 24*CELL_PITCH : 20*CELL_PITCH);
    wire [10:0] dx = hcounter-field_x;
    wire [10:0] dy = vcounter-FIELD_Y;
    wire in_x = hcounter>=field_x && hcounter<field_right;
    wire in_y = vcounter>=FIELD_Y && vcounter<FIELD_Y+20*CELL_PITCH;
    wire [4:0] cx, ry;
    wire [10:0] lx, ly;
    function [4:0] div3;
        input [6:0] value;
        begin
            case(value)
            7'd0, 7'd1, 7'd2: div3 = 5'd0;
            7'd3, 7'd4, 7'd5: div3 = 5'd1;
            7'd6, 7'd7, 7'd8: div3 = 5'd2;
            7'd9, 7'd10, 7'd11: div3 = 5'd3;
            7'd12, 7'd13, 7'd14: div3 = 5'd4;
            7'd15, 7'd16, 7'd17: div3 = 5'd5;
            7'd18, 7'd19, 7'd20: div3 = 5'd6;
            7'd21, 7'd22, 7'd23: div3 = 5'd7;
            7'd24, 7'd25, 7'd26: div3 = 5'd8;
            7'd27, 7'd28, 7'd29: div3 = 5'd9;
            7'd30, 7'd31, 7'd32: div3 = 5'd10;
            7'd33, 7'd34, 7'd35: div3 = 5'd11;
            7'd36, 7'd37, 7'd38: div3 = 5'd12;
            7'd39, 7'd40, 7'd41: div3 = 5'd13;
            7'd42, 7'd43, 7'd44: div3 = 5'd14;
            7'd45, 7'd46, 7'd47: div3 = 5'd15;
            7'd48, 7'd49, 7'd50: div3 = 5'd16;
            7'd51, 7'd52, 7'd53: div3 = 5'd17;
            7'd54, 7'd55, 7'd56: div3 = 5'd18;
            7'd57, 7'd58, 7'd59: div3 = 5'd19;
            7'd60, 7'd61, 7'd62: div3 = 5'd20;
            7'd63, 7'd64, 7'd65: div3 = 5'd21;
            7'd66, 7'd67, 7'd68: div3 = 5'd22;
            7'd69, 7'd70, 7'd71: div3 = 5'd23;
            default: div3 = 5'd24;
            endcase
        end
    endfunction
    generate if(CELL_PITCH==24) begin : pitch24
        assign cx = div3(dx[9:3]);
        assign ry = div3(dy[9:3]);
        assign lx = dx - ({6'd0,cx}<<4) - ({6'd0,cx}<<3);
        assign ly = dy - ({6'd0,ry}<<4) - ({6'd0,ry}<<3);
    end else begin : pitch32
        assign cx = dx[9:5];
        assign ry = dy[9:5];
        assign lx = {6'd0,dx[4:0]};
        assign ly = {6'd0,dy[4:0]};
    end endgenerate
    assign local_x = lx[4:0];
    assign local_y = ly[4:0];
    assign column = in_x && lx<FACE ? cx : 5'd24;
    assign row = in_y && ly<FACE ? ry : 5'd24;
    assign in_field = in_x && in_y;
    assign cell_visible = in_field && lx<FACE && ly<FACE;
endmodule
