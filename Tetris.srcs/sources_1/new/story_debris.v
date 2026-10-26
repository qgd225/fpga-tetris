// Deterministic template loading; one selection per accepted new run.
module story_debris(
 input clk,reset_n,start,campaign,duo,
 input [1:0] level_id,input [15:0] seed,
 output reg ready,output reg [479:0] initial_mask,
 output reg [15:0] debris_seed,output reg [2:0] layout_id
);
 (* rom_style="block" *) reg [23:0] rows[0:1279];
 initial $readmemh("D:/vivado_project/Tetris/Tetris.srcs/sources_1/new/story_debris.mem",rows);
 reg active,valid_q;
 reg [4:0] request_row,row_q;
 reg [10:0] base;
 reg [23:0] data_q;
 wire [15:0] nonzero_seed=seed==0?16'hACE1:seed;
 wire [15:0] next_seed=(nonzero_seed>>1) ^ (nonzero_seed[0]?16'hB400:16'd0);
 integer c;
 always @(posedge clk) if(active) data_q<=rows[base+request_row];
 always @(posedge clk or negedge reset_n) begin
  if(!reset_n)begin ready<=0;initial_mask<=0;debris_seed<=0;layout_id<=0;active<=0;valid_q<=0;request_row<=0;row_q<=0;base<=0;end
  else if(start)begin
   initial_mask<=0;debris_seed<=nonzero_seed;layout_id<=next_seed[2:0];
   base<=({duo,level_id,3'b000}+next_seed[2:0])*11'd20;
   request_row<=0;row_q<=0;valid_q<=0;active<=campaign;ready<=0;
  end else if(active)begin
   valid_q<=1;row_q<=request_row;
   if(request_row<19)request_row<=request_row+1'b1;
   if(valid_q)begin
    for(c=0;c<24;c=c+1)initial_mask[c*20+row_q]<=data_q[c];
    if(row_q==19)begin active<=0;ready<=1;valid_q<=0;end
   end
  end else if(!ready)ready<=1;
 end
endmodule
