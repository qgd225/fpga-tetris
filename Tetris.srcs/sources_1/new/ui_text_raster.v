// Shared fixed-pitch text lookup. All divisions have constant denominators.
// Output latency is the two clocks of the common font, including glyph edges.
module ui_text_raster #(parameter REGISTER_DESCRIPTION=0)(input clk,reset_n,input enable,
 input [255:0] message,input [9:0] dx,input [5:0] dy,
 input [5:0] pitch,height,length,output lit);
 reg [9:0] column,remainder;
 reg [2:0] glyph_x,glyph_y;
 reg [7:0] character;
 always @(*)begin
  column=0;remainder=0;glyph_x=7;glyph_y=7;character=0;
  case(pitch)
   8:begin column=dx/8;remainder=dx%8;glyph_x=remainder*3/4;end
   12:begin column=dx/12;remainder=dx%12;glyph_x=remainder/2;end
   14:begin column=dx/14;remainder=dx%14;glyph_x=remainder*3/7;end
   16:begin column=dx/16;remainder=dx%16;glyph_x=remainder*3/8;end
   18:begin column=dx/18;remainder=dx%18;glyph_x=remainder/3;end
   20:begin column=dx/20;remainder=dx%20;glyph_x=remainder*3/10;end
   24:begin column=dx/24;remainder=dx%24;glyph_x=remainder/4;end
   30:begin column=dx/30;remainder=dx%30;glyph_x=remainder/5;end
   default:begin column=1023;remainder=0;glyph_x=7;end
  endcase
  case(height)
   14:glyph_y=dy/2;
   21:glyph_y=dy/3;
   28:glyph_y=dy/4;
   35:glyph_y=dy/5;
   default:glyph_y=7;
  endcase
  if(enable && column<length && column<32 && dy<height)
   character=message[255-column*8-:8];
 end
 generate if(REGISTER_DESCRIPTION)begin: registered_description
  // Separate region/value formatting from character selection. This prevents
  // the character mux from duplicating every numerical formatting path.
  (* keep="true" *) reg [255:0] message_q;
  reg [4:0] column_q;
  reg [2:0] glyph_x_q,glyph_y_q;reg enabled_q;
  wire [7:0] character_q=enabled_q?message_q[255-column_q*8-:8]:8'd0;
  always @(posedge clk)begin
   message_q<=message;column_q<=column[4:0];glyph_x_q<=glyph_x;glyph_y_q<=glyph_y;
  end
  always @(posedge clk or negedge reset_n)begin
   if(!reset_n)enabled_q<=0;
   else enabled_q<=enable && column<length && column<32 && dy<height;
  end
  ui_font_5x7 #(.REGISTER_INPUT(1)) font(.clk(clk),.reset_n(reset_n),.character(character_q),.column(glyph_x_q),.row(glyph_y_q),.lit(lit));
 end else begin: original_description
  ui_font_5x7 #(.REGISTER_INPUT(1)) font(.clk(clk),.reset_n(reset_n),.character(character),.column(glyph_x),.row(glyph_y),.lit(lit));
 end endgenerate
endmodule
