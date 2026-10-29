// A3 lossless decoder: descriptor -> local/direct-color pattern -> RGB/flags.
// Three synchronous reads, no frame buffer or gameplay state.
module ui_material_atlas(input clk,input [12:0] address,input [5:0] offset,
 output [25:0] pixel);
 `include "ui_material_geometry.vh"
 wire [MAT_DESC_BITS-1:0] desc;
 ui_material_bank #(.WIDTH(MAT_DESC_BITS),.WORDS(MAT_MAP_WORDS),
  .LO_FILE("ui_material_map_lo.mem"),.HI_FILE("ui_material_map_hi.mem"))
  descriptors(.clk(clk),.address(address),.data(desc));
 reg [5:0] sub;
 wire [MAT_PATTERN_BITS+5:0] pa={desc[MAT_PAL_BITS+:MAT_PATTERN_BITS],sub};
 wire a;wire [1:0] b;wire [2:0] c3;wire [3:0] c;wire [MAT_P8_BITS-1:0] d;
 ui_material_bank #(.WIDTH(1),.WORDS(MAT_P1_WORDS),.LO_FILE("ui_material_p1_lo.mem"),.HI_FILE("ui_material_p1_hi.mem"))
  bank1(.clk(clk),.address(pa[$clog2(MAT_P1_WORDS)-1:0]),.data(a));
 ui_material_bank #(.WIDTH(2),.WORDS(MAT_P2_WORDS),.LO_FILE("ui_material_p2_lo.mem"),.HI_FILE("ui_material_p2_hi.mem"))
  bank2(.clk(clk),.address(pa[$clog2(MAT_P2_WORDS)-1:0]),.data(b));
 ui_material_bank #(.WIDTH(3),.WORDS(MAT_P3_WORDS),.LO_FILE("ui_material_p3_lo.mem"),.HI_FILE("ui_material_p3_hi.mem"))
  bank3(.clk(clk),.address(pa[$clog2(MAT_P3_WORDS)-1:0]),.data(c3));
 ui_material_bank #(.WIDTH(4),.WORDS(MAT_P4_WORDS),.LO_FILE("ui_material_p4_lo.mem"),.HI_FILE("ui_material_p4_hi.mem"))
  bank4(.clk(clk),.address(pa[$clog2(MAT_P4_WORDS)-1:0]),.data(c));
 ui_material_bank #(.WIDTH(MAT_P8_BITS),.WORDS(MAT_P8_WORDS),.LO_FILE("ui_material_p8_lo.mem"),.HI_FILE("ui_material_p8_hi.mem"))
  bank8(.clk(clk),.address(pa[$clog2(MAT_P8_WORDS)-1:0]),.data(d));
 reg [2:0] kind;reg [MAT_PAL_BITS-1:0] base;
 wire [MAT_P8_BITS-1:0] index=kind==1?a:kind==2?b:kind==3?c3:kind==4?c:kind==5?d:0;
 wire [MAT_PAL_BITS-1:0] color_address=base+index;
 wire [MAT_RGB_BITS-1:0] color_code,palette_code;
 reg [MAT_RGB_BITS-1:0] direct_code;reg direct_valid;
 always @(posedge clk)begin direct_code<=d;direct_valid<=kind==5;end
 assign color_code=direct_valid?direct_code:palette_code;
 ui_material_bank #(.WIDTH(MAT_RGB_BITS),.WORDS(MAT_PAL_WORDS),.LO_FILE("ui_material_palette_lo.mem"),.HI_FILE("ui_material_palette_hi.mem"))
  colors(.clk(clk),.address(color_address),.data(palette_code));
 (* rom_style="distributed" *) reg [25:0] rgb_table[0:MAT_RGB_WORDS-1];
 initial $readmemh("ui_material_rgb.mem",rgb_table);
 assign pixel=rgb_table[color_code];
 always @(posedge clk)begin
  sub<=offset;kind<=desc[MAT_DESC_BITS-1-:3];base<=desc[MAT_PAL_BITS-1:0];
 end
endmodule

// Preserve the registered ROM boundary on Vivado 2018.3. Split a short tail
// from the main power-of-two bank instead of padding both to full depth.
(* keep_hierarchy="yes" *)
module ui_material_bank #(
 parameter WIDTH=8,WORDS=100,LO_FILE="",HI_FILE="",
 parameter ADDR_BITS=$clog2(WORDS),SPLIT=1<<(ADDR_BITS-1)
)(input clk,input [ADDR_BITS-1:0] address,output [WIDTH-1:0] data);
 localparam LO_STYLE=WIDTH*SPLIT<=16384?"distributed":"block";
 localparam HI_STYLE=WIDTH*(WORDS-SPLIT)<=24576?"distributed":"block";
 (* rom_style=LO_STYLE *) reg [WIDTH-1:0] lo[0:SPLIT-1];
 (* rom_style=HI_STYLE *) reg [WIDTH-1:0] hi[0:WORDS-SPLIT-1];
 reg [WIDTH-1:0] lo_q,hi_q;reg bank_q;
 initial begin $readmemh(LO_FILE,lo);$readmemh(HI_FILE,hi);end
 always @(posedge clk)begin
  lo_q<=lo[address[ADDR_BITS-2:0]];hi_q<=hi[address[ADDR_BITS-2:0]];
  bank_q<=address[ADDR_BITS-1];
 end
 assign data=bank_q?hi_q:lo_q;
endmodule
