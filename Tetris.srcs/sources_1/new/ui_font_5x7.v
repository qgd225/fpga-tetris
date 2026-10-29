// Shared fixed 5x7 alphabet; A1 primitive, not yet connected to story_ui.
// Integer glyph coordinates only. No per-pixel division, font-style mux or
// separate digit renderer. Two-cycle registered output, distributed ROM.
module ui_font_5x7 #(parameter INIT_FILE="ui_font_5x7.mem", parameter REGISTER_INPUT=0)(
 input clk,reset_n,input [7:0] character,input [2:0] column,row,
 output reg lit
);
 (* rom_style="distributed" *) reg [34:0] alphabet[0:127];
 initial $readmemh(INIT_FILE,alphabet);
 generate if(REGISTER_INPUT==2)begin: prefetched_character
  // The template ROM already registers the ASCII byte and glyph coordinates.
  always @(posedge clk or negedge reset_n)begin
   if(!reset_n)lit<=0;
   else lit<=!character[7] && column<5 && row<7?alphabet[character[6:0]][34-row*5-column]:1'b0;
  end
 end else if(REGISTER_INPUT)begin: input_first
  reg [6:0] character_q;
  reg [2:0] column_q,row_q;
  reg valid_q;
  always @(posedge clk)begin
   character_q<=character[6:0];column_q<=column;row_q<=row;
  end
  always @(posedge clk or negedge reset_n)begin
   if(!reset_n)begin valid_q<=0;lit<=0;end
   else begin
    valid_q<=!character[7] && column<5 && row<7;
    lit<=valid_q?alphabet[character_q][34-row_q*5-column_q]:1'b0;
   end
  end
 end else begin: bitmap_first
  reg [34:0] bitmap_q;
  reg [2:0] column_q,row_q;
  reg valid_q;
  always @(posedge clk)begin
   bitmap_q<=alphabet[character[6:0]];column_q<=column;row_q<=row;
  end
  always @(posedge clk or negedge reset_n)begin
   if(!reset_n)begin valid_q<=0;lit<=0;end
   else begin
    valid_q<=!character[7] && column<5 && row<7;
    lit<=valid_q?bitmap_q[34-row_q*5-column_q]:1'b0;
   end
  end
 end endgenerate
endmodule
