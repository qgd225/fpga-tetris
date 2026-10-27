// One elapsed-time source for TIME and endless speed.
module run_clock(input clk,reset_n,new_run,playing,paused,finished,tick,
 output reg [18:0] elapsed_ticks,output reg [13:0] seconds,
 output reg [15:0] time_bcd,output reg [2:0] speed);
 `include "rhythm_params.vh"
 reg [5:0] fraction;
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin elapsed_ticks<=0;seconds<=0;time_bcd<=0;fraction<=0;speed<=0;end
  else if(new_run)begin elapsed_ticks<=0;seconds<=0;time_bcd<=0;fraction<=0;speed<=0;end
  else if(playing && !paused && !finished && tick && elapsed_ticks<RHYTHM_TIME_TICKS)begin
   elapsed_ticks<=elapsed_ticks+1'b1;
   if(elapsed_ticks==1*RHYTHM_SPEED_TICKS-1 || elapsed_ticks==2*RHYTHM_SPEED_TICKS-1 || elapsed_ticks==3*RHYTHM_SPEED_TICKS-1 || elapsed_ticks==4*RHYTHM_SPEED_TICKS-1 || elapsed_ticks==5*RHYTHM_SPEED_TICKS-1 || elapsed_ticks==6*RHYTHM_SPEED_TICKS-1 || elapsed_ticks==7*RHYTHM_SPEED_TICKS-1)speed<=speed+1'b1;
   if(fraction==59)begin
    fraction<=0;seconds<=seconds+1'b1;
    if(time_bcd[3:0]!=9)time_bcd[3:0]<=time_bcd[3:0]+1'b1;
    else begin time_bcd[3:0]<=0;
     if(time_bcd[7:4]!=5)time_bcd[7:4]<=time_bcd[7:4]+1'b1;
     else begin time_bcd[7:4]<=0;
      if(time_bcd[11:8]!=9)time_bcd[11:8]<=time_bcd[11:8]+1'b1;
      else begin time_bcd[11:8]<=0;time_bcd[15:12]<=time_bcd[15:12]+1'b1;end
     end
    end
   end else fraction<=fraction+1'b1;
  end
 end
endmodule
