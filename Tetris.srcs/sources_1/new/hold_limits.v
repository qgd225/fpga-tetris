// Shared cooldown/lifetime and per-player one-use locks.
module hold_limits(input clk,reset_n,new_run,playing,paused,busy,finished,duo,tick,
 input request1,request2,land1,land2,hold_valid,
 output accept1,accept2,output reg expired,rejected,
 output reg [1:0] blocks_left,output reg [6:0] cooldown_ticks,
 output reg [10:0] life_ticks,output ready,output allow_block1,allow_block2);
 `include "rhythm_params.vh"
 reg used1,used2,priority2;
 assign allow_block1=!used1;assign allow_block2=!used2;
 wire runnable=playing && !paused && !busy && !finished;
 wire allow=runnable && blocks_left==0 && cooldown_ticks==0 && !expired && !(tick && hold_valid && life_ticks==1) && !land1 && !land2;
 wire req1=request1 && !used1,req2=request2 && duo && !used2;
 assign accept1=allow && req1 && (!req2 || !priority2);
 assign accept2=allow && req2 && (!req1 || priority2);
 assign ready=blocks_left==0 && cooldown_ticks==0;
 wire [1:0] lands={1'b0,land1}+{1'b0,(land2 && duo)};
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin used1<=0;used2<=0;priority2<=0;expired<=0;rejected<=0;blocks_left<=0;cooldown_ticks<=0;life_ticks<=0;end
  else if(new_run || finished)begin used1<=0;used2<=0;priority2<=0;expired<=0;rejected<=0;blocks_left<=0;cooldown_ticks<=0;life_ticks<=0;end
  else begin
   expired<=0;rejected<=0;
   if(playing && !paused)begin
    if(land1)used1<=0;if(land2)used2<=0;
    if(lands!=0)blocks_left<=lands>=blocks_left?0:blocks_left-lands;
    if(tick)begin
     if(cooldown_ticks!=0)cooldown_ticks<=cooldown_ticks-1'b1;
     if(hold_valid && life_ticks!=0)begin life_ticks<=life_ticks-1'b1;if(life_ticks==1)expired<=1;end
    end
    if(accept1 || accept2)begin
     if(accept1)used1<=1;else used2<=1;
     priority2<=accept1;blocks_left<=duo?2:3;cooldown_ticks<=RHYTHM_HOLD_COOLDOWN;life_ticks<=RHYTHM_HOLD_LIFE;
    end
    if(runnable && ((request1 && !accept1) || (duo && request2 && !accept2)))rejected<=1;
   end
  end
 end
endmodule
