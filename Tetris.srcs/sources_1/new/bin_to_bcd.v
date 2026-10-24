// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 串行双 dabble，只在一个输入快照转换完后更新显示值。
module bin_to_bcd #(parameter WIDTH=16, DIGITS=5)(
 input clk, reset_n, input [WIDTH-1:0] value,
 output reg [DIGITS*4-1:0] bcd
);
 reg [WIDTH+DIGITS*4-1:0] shift;
 reg [WIDTH+DIGITS*4-1:0] fixed_value;
 reg [5:0] step;
 integer i;
 always @(*) begin
  fixed_value=shift;
  for(i=0;i<DIGITS;i=i+1)
   if(fixed_value[WIDTH+i*4 +:4]>=5)
    fixed_value[WIDTH+i*4 +:4]=fixed_value[WIDTH+i*4 +:4]+4'd3;
 end
 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin shift<=0; step<=0; bcd<=0; end
  else if(step==0) begin shift<={{(DIGITS*4){1'b0}},value}; step<=1; end
  else begin
   shift<=fixed_value<<1;
   if(step==WIDTH) begin
    bcd<=(fixed_value<<1)>>WIDTH;
    step<=0;
   end else step<=step+1'b1;
  end
 end
endmodule
