// Lossless 8x8 dictionary texture ROM. A1 standalone prototype, not yet wired
// into story_ui. Palette RGB values are exact; no quantization or resampling.
module ui_exact_tile_rom #(
 parameter WIDTH=160, HEIGHT=176, TILE_COUNT=256, COLOR_COUNT=4096,
 parameter TILE_BITS=$clog2(TILE_COUNT), COLOR_BITS=$clog2(COLOR_COUNT),
 parameter MAP_FILE="ui_tile_map.mem", PIXEL_FILE="ui_tile_pixels.mem",
 parameter PALETTE_FILE="ui_tile_palette.mem"
)(
 input clk,reset_n,input [10:0] x,y,
 output reg [23:0] rgb,output valid
);
 localparam MAP_WIDTH=(WIDTH+7)/8, MAP_HEIGHT=(HEIGHT+7)/8;
 localparam MAP_WORDS=MAP_WIDTH*MAP_HEIGHT;
 (* rom_style="block" *) reg [TILE_BITS-1:0] tile_map[0:MAP_WORDS-1];
 (* rom_style="block" *) reg [COLOR_BITS-1:0] tile_pixels[0:TILE_COUNT*64-1];
 (* rom_style="block" *) reg [23:0] palette[0:COLOR_COUNT-1];
 initial begin
  $readmemh(MAP_FILE,tile_map);
  $readmemh(PIXEL_FILE,tile_pixels);
  $readmemh(PALETTE_FILE,palette);
 end
 wire inside=x<WIDTH && y<HEIGHT;
 wire [21:0] map_address=inside?(y>>3)*MAP_WIDTH+(x>>3):22'd0;
 reg [TILE_BITS-1:0] tile_q;
 reg [5:0] offset_q;
 reg [COLOR_BITS-1:0] color_q;
 reg [2:0] valid_q;
 // Three synchronous memory reads. Reset only the validity pipeline; ROM
 // read registers remain reset-free so Vivado can use BRAM output registers.
 always @(posedge clk)begin
  tile_q<=tile_map[map_address];
  offset_q<={y[2:0],x[2:0]};
  color_q<=tile_pixels[{tile_q,offset_q}];
  rgb<=palette[color_q];
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)valid_q<=0;
  else valid_q<={valid_q[1:0],inside};
 end
 assign valid=valid_q[2];
endmodule
