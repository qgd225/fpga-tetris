// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 两次同步读取：字符编号 -> 字形行；直出字符用于已有 BCD 数字。
// 只处理一个已选择的文字像素，不为每个标签复制 ROM。
module hud_text #(parameter INIT_FILE="story_font.mem")(
    input clk,reset_n,
    input request_valid,use_direct,
    input [9:0] text_address,
    input [5:0] direct_char,ink,
    input [3:0] glyph_row,
    input [2:0] glyph_column,
    output pixel_valid,pixel_lit,
    output [5:0] pixel_ink
);
    wire [7:0] char_data,glyph_data;
    reg direct_d,valid_d,valid_q;
    reg [5:0] char_d,ink_d,ink_q;
    reg [3:0] row_d;
    reg [2:0] column_d,column_q;
    wire [5:0] character=direct_d?char_d:char_data[5:0];
    hud_font_rom #(.INIT_FILE(INIT_FILE)) storage(
        .clk(clk),.address_a({1'b1,text_address}),.address_b({1'b0,character,row_d}),
        .data_a(char_data),.data_b(glyph_data));
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            direct_d<=0;valid_d<=0;valid_q<=0;char_d<=0;
            ink_d<=0;ink_q<=0;row_d<=0;column_d<=0;column_q<=0;
        end else begin
            direct_d<=use_direct;char_d<=direct_char;row_d<=glyph_row;
            column_d<=glyph_column;column_q<=column_d;
            valid_d<=request_valid;valid_q<=valid_d;
            ink_d<=ink;ink_q<=ink_d;
        end
    end
    assign pixel_valid=valid_q;
    assign pixel_lit=valid_q && glyph_data[7-column_q];
    assign pixel_ink=ink_q;
endmodule
