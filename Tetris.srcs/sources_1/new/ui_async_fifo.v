// Gray-pointer FIFO with a synchronous block-RAM prefetch register.
// The consumer sees a stable head until pop; reset only invalidates control.
module ui_async_fifo #(
 parameter WIDTH=32,ADDR_BITS=9,STYLE="block"
)(input reset_n,wr_clk,rd_clk,input write,input [WIDTH-1:0] write_data,
 output full,input pop,output reg [WIDTH-1:0] head,output reg valid);
 localparam DEPTH=1<<ADDR_BITS;
 (* ram_style=STYLE *) reg [WIDTH-1:0] memory[0:DEPTH-1];
 reg [ADDR_BITS:0] wp,rp,wg,rg;
 (* ASYNC_REG="TRUE" *) reg [ADDR_BITS:0] rg1,rg2,wg1,wg2;
 wire empty=rg==wg2;
 assign full=wg=={~rg2[ADDR_BITS:ADDR_BITS-1],rg2[ADDR_BITS-2:0]};
 wire take_write=write && !full;
 wire fetch=(!valid || pop) && !empty;
 wire [ADDR_BITS:0] wn=wp+1'b1,rn=rp+1'b1;
 always @(posedge wr_clk)if(take_write)memory[wp[ADDR_BITS-1:0]]<=write_data;
 always @(posedge rd_clk)if(fetch)head<=memory[rp[ADDR_BITS-1:0]];
 always @(posedge wr_clk or negedge reset_n)begin
  if(!reset_n)begin wp<=0;wg<=0;rg1<=0;rg2<=0;end
  else begin
   rg1<=rg;rg2<=rg1;
   if(take_write)begin wp<=wn;wg<=(wn>>1)^wn;end
  end
 end
 always @(posedge rd_clk or negedge reset_n)begin
  if(!reset_n)begin rp<=0;rg<=0;wg1<=0;wg2<=0;valid<=0;end
  else begin
   wg1<=wg;wg2<=wg1;
   if(!valid || pop)valid<=fetch;
   if(fetch)begin rp<=rn;rg<=(rn>>1)^rn;end
  end
 end
endmodule
