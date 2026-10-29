// Three clocks: raw description -> character ROM/dynamic byte -> public glyph.
module ui_text_compact(input clk,reset_n,enable,input [6:0] text_id,
 input [255:0] message,input [11:0] dx,dy,input [5:0] pitch,height,length,output lit);
 reg [6:0] id_q;reg [255:0] data_q;reg [11:0] dx_q,dy_q;
 reg [5:0] pitch_q,height_q,length_q;reg enable_q;
 always @(posedge clk)begin
  id_q<=text_id;data_q<=message;dx_q<=dx;dy_q<=dy;pitch_q<=pitch;height_q<=height;length_q<=length;
 end
 always @(posedge clk or negedge reset_n)begin if(!reset_n)enable_q<=0;else enable_q<=enable;end
 reg [9:0] column;reg [4:0] remainder;
 reg [2:0] glyph_x,glyph_y;
 always @(*)begin
  column=1023;remainder=0;glyph_x=7;glyph_y=7;
  case(pitch_q)
   8:begin column=dx_q[9:0]/8;remainder=dx_q[9:0]%8;glyph_x=remainder<5'd2 ? 3'd0:remainder<5'd3 ? 3'd1:remainder<5'd4 ? 3'd2:remainder<5'd6 ? 3'd3:remainder<5'd7 ? 3'd4:3'd5;end
   12:begin column=dx_q[9:0]/12;remainder=dx_q[9:0]%12;glyph_x=remainder<5'd2 ? 3'd0:remainder<5'd4 ? 3'd1:remainder<5'd6 ? 3'd2:remainder<5'd8 ? 3'd3:remainder<5'd10 ? 3'd4:3'd5;end
   14:begin column=dx_q[9:0]/14;remainder=dx_q[9:0]%14;glyph_x=remainder<5'd3 ? 3'd0:remainder<5'd5 ? 3'd1:remainder<5'd7 ? 3'd2:remainder<5'd10 ? 3'd3:remainder<5'd12 ? 3'd4:3'd5;end
   16:begin column=dx_q[9:0]/16;remainder=dx_q[9:0]%16;glyph_x=remainder<5'd3 ? 3'd0:remainder<5'd6 ? 3'd1:remainder<5'd8 ? 3'd2:remainder<5'd11 ? 3'd3:remainder<5'd14 ? 3'd4:3'd5;end
   18:begin column=dx_q[9:0]/18;remainder=dx_q[9:0]%18;glyph_x=remainder<5'd3 ? 3'd0:remainder<5'd6 ? 3'd1:remainder<5'd9 ? 3'd2:remainder<5'd12 ? 3'd3:remainder<5'd15 ? 3'd4:3'd5;end
   20:begin column=dx_q[9:0]/20;remainder=dx_q[9:0]%20;glyph_x=remainder<5'd4 ? 3'd0:remainder<5'd7 ? 3'd1:remainder<5'd10 ? 3'd2:remainder<5'd14 ? 3'd3:remainder<5'd17 ? 3'd4:3'd5;end
   24:begin column=dx_q[9:0]/24;remainder=dx_q[9:0]%24;glyph_x=remainder<5'd4 ? 3'd0:remainder<5'd8 ? 3'd1:remainder<5'd12 ? 3'd2:remainder<5'd16 ? 3'd3:remainder<5'd20 ? 3'd4:3'd5;end
   30:begin column=dx_q[9:0]/30;remainder=dx_q[9:0]%30;glyph_x=remainder<5'd5 ? 3'd0:remainder<5'd10 ? 3'd1:remainder<5'd15 ? 3'd2:remainder<5'd20 ? 3'd3:remainder<5'd25 ? 3'd4:3'd5;end
  endcase
  case(height_q)
   14:glyph_y=dy_q[5:0]/2;21:glyph_y=dy_q[5:0]/3;28:glyph_y=dy_q[5:0]/4;35:glyph_y=dy_q[5:0]/5;
  endcase
 end
 wire valid=enable_q && dx_q[11:10]==0 && dy_q[11:6]==0 && column<length_q && column<32 && dy_q[5:0]<height_q;
 wire [8:0] template_word;
 ui_text_template_rom templates(.clk(clk),.address({id_q,column[4:0]}),.word(template_word));
 reg [7:0] dynamic_q;reg [2:0] gx_q,gy_q;reg valid_q;
 always @(posedge clk)begin dynamic_q<=data_q[255-column[4:0]*8-:8];gx_q<=glyph_x;gy_q<=glyph_y;end
 always @(posedge clk or negedge reset_n)begin if(!reset_n)valid_q<=0;else valid_q<=valid;end
 wire [7:0] character=valid_q ? (template_word[8] ? dynamic_q:template_word[7:0]):8'd0;
 ui_font_5x7 #(.REGISTER_INPUT(2)) font(.clk(clk),.reset_n(reset_n),.character(character),.column(gx_q),.row(gy_q),.lit(lit));
endmodule
(* keep_hierarchy="yes" *)
module ui_text_template_rom(input clk,input [11:0] address,output reg [8:0] word);
 `include "ui_text_templates.vh"
 (* rom_style="block" *) reg [8:0] chars[0:UI_TEXT_WORDS-1];
 initial $readmemh("ui_text_templates.mem",chars);
 always @(posedge clk)word<=chars[address];
endmodule
