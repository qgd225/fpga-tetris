// Three synchronous reads; preview panels and mode variants share one atlas.
module ui_panel_atlas(input clk,input [1:0] panel,input [7:0] x,y,
 output reg [23:0] rgb,output reg [10:0] global_code);
 `include "ui_panel_geometry.vh"
 (* rom_style="block" *) reg [PANEL_TILE_BITS-1:0] map[0:1759];
 (* rom_style="block" *) reg [PANEL_COLOR_BITS-1:0] pixels[0:PANEL_TILES*64-1];
 (* rom_style="block" *) reg [34:0] palette[0:PANEL_COLORS-1];
 initial begin
  $readmemh("ui_panel_map.mem",map);
  $readmemh("ui_panel_pixels.mem",pixels);
  $readmemh("ui_panel_palette.mem",palette);
 end
 wire [10:0] address=(x<160 && y<176)?panel*11'd440+(y>>3)*11'd20+(x>>3):11'd0;
 reg [PANEL_TILE_BITS-1:0] tile_q;
 reg [5:0] offset_q;
 reg [PANEL_COLOR_BITS-1:0] color_q;
 always @(posedge clk)begin
  tile_q<=map[address];offset_q<={y[2:0],x[2:0]};
  color_q<=pixels[{tile_q,offset_q}];
  {global_code,rgb}<=palette[color_q];
 end
endmodule
