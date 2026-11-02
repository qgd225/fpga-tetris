// Read-only, frame-aligned debris feedback; never changes game state.
module ui_core_feedback(
 input clk,reset_n,frame_tick,active,paused,input [2:0] ship_key,
 input [6:0] debris_left,output reg [4:0] flash_age
);
 reg valid;reg [6:0] previous;reg [2:0] previous_ship;
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin valid<=0;previous<=0;previous_ship<=0;flash_age<=0;end
  else if(!active)begin valid<=0;flash_age<=0;end
  else if(frame_tick && !paused)begin
   valid<=1;previous<=debris_left;previous_ship<=ship_key;
   if(!valid || previous_ship!=ship_key || debris_left>previous)flash_age<=0;
   else if(debris_left<previous)flash_age<=18;
   else if(flash_age!=0)flash_age<=flash_age-1'b1;
  end
 end
endmodule
