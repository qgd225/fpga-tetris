// Lossless RGB888 run packets. Variable spans of at most 320 RGB runs per packet.
// Payload: A5 5A 04 00 | frame16 line16 x16 width16 | (run8 R G B)*N.
// Max payload is 1292 bytes, within standard Ethernet MTU. No palette limit.
module ui_rgb_packetizer(input clk,reset_n,enable,de,input [10:0] line,
 input [23:0] rgb,input word_full,descriptor_full,
 output reg [31:0] word_data,output word_write,
 output [15:0] packet_length,output packet_ready,output reg overflow);
 reg previous_de,active_line;
 reg [10:0] line_q;reg [15:0] frame;
 reg [10:0] start_x;
 reg [10:0] position;reg [8:0] run_tokens;
 reg [7:0] run_length;reg [23:0] run_rgb;
 reg token_write,chunk_write;
 reg [31:0] token_data;reg [57:0] chunk_data;
 wire token_full,token_valid,chunk_full,chunk_valid;
 wire [31:0] token_head;wire [57:0] chunk_head;
 wire token_pop,chunk_pop;
 ui_async_fifo #(.WIDTH(32),.ADDR_BITS(10)) tokens(
  .reset_n(reset_n),.wr_clk(clk),.rd_clk(clk),.write(token_write),.write_data(token_data),
  .full(token_full),.pop(token_pop),.head(token_head),.valid(token_valid));
 ui_async_fifo #(.WIDTH(58),.ADDR_BITS(4),.STYLE("distributed")) chunks(
  .reset_n(reset_n),.wr_clk(clk),.rd_clk(clk),.write(chunk_write),.write_data(chunk_data),
  .full(chunk_full),.pop(chunk_pop),.head(chunk_head),.valid(chunk_valid));
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin
   previous_de<=0;active_line<=0;line_q<=0;frame<=0;start_x<=0;position<=0;
   run_tokens<=0;run_length<=0;run_rgb<=0;token_write<=0;chunk_write<=0;token_data<=0;chunk_data<=0;overflow<=0;
  end else begin
   previous_de<=de;token_write<=0;chunk_write<=0;
   if((token_write && token_full)||(chunk_write && chunk_full))overflow<=1;
   if(de && !previous_de)begin
    active_line<=enable;line_q<=line;start_x<=0;position<=1;run_tokens<=0;run_length<=1;run_rgb<=rgb;
   end else if(de && active_line)begin
    if(run_tokens==319 && (rgb!=run_rgb || run_length==255))begin
     token_data<={run_length,run_rgb};token_write<=1;
     chunk_data<={frame,line_q,start_x,position-start_x,run_tokens+9'd1};chunk_write<=1;
     start_x<=position;position<=position+1'b1;run_tokens<=0;run_length<=1;run_rgb<=rgb;
    end else begin
     position<=position+1'b1;
     if(rgb!=run_rgb || run_length==255)begin
      token_data<={run_length,run_rgb};token_write<=1;run_tokens<=run_tokens+1'b1;run_length<=1;run_rgb<=rgb;
     end else run_length<=run_length+1'b1;
    end
   end else if(!de && previous_de && active_line)begin
    token_data<={run_length,run_rgb};token_write<=1;
    chunk_data<={frame,line_q,start_x,position-start_x,run_tokens+9'd1};chunk_write<=1;
    active_line<=0;run_length<=0;
    if(line_q==719)frame<=frame+1'b1;
   end
  end
 end
 reg [2:0] state;
 reg [15:0] frame_send;reg [10:0] line_send;
 reg [10:0] x_send,width_send;reg [8:0] count_send,remaining;
 assign chunk_pop=state==0 && chunk_valid && !descriptor_full;
 assign token_pop=state==4 && token_valid && !word_full;
 assign word_write=((state>=1 && state<=3) || (state==4 && token_valid)) && !word_full;
 assign packet_length=16'd12+{5'd0,count_send,2'd0};
 assign packet_ready=state==5 && !descriptor_full;
 always @(*)begin
  case(state)
   1:word_data=32'ha55a0400;
   2:word_data={frame_send,5'd0,line_send};
   3:word_data={5'd0,x_send,5'd0,width_send};
   default:word_data=token_head;
  endcase
 end
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin state<=0;frame_send<=0;line_send<=0;x_send<=0;width_send<=0;count_send<=0;remaining<=0;end
  else case(state)
   0:if(chunk_pop)begin
    {frame_send,line_send,x_send,width_send,count_send}<=chunk_head;remaining<=chunk_head[8:0];state<=1;
   end
   1,2,3:if(word_write)state<=state+1'b1;
   4:if(token_pop)begin if(remaining==1)state<=5;else remaining<=remaining-1'b1;end
   5:if(packet_ready)state<=0;
   default:state<=0;
  endcase
 end
endmodule
