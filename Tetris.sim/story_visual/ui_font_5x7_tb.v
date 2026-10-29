`timescale 1ns/1ps
module ui_font_5x7_tb;
 reg clk=0,reset_n=0;always #5 clk=~clk;
 reg [7:0] character=0;reg [2:0] column=0,row=0;
 wire lit,alternate_lit,single_lit;
 ui_font_5x7 dut(clk,reset_n,character,column,row,lit);
 ui_font_5x7 #(.REGISTER_INPUT(1)) alternate(clk,reset_n,character,column,row,alternate_lit);
 ui_font_5x7 #(.REGISTER_INPUT(2)) single_cycle(clk,reset_n,character,column,row,single_lit);
 reg [34:0] expected[0:127];
 reg last_expected,current_expected;
 integer n,ch,rr,cc;
 initial begin
  $readmemh("ui_font_5x7.mem",expected);
  repeat(5)@(negedge clk);reset_n=1;
  last_expected=0;
  for(n=0;n<16385;n=n+1)begin
   @(negedge clk);
   ch=(n>>6)&255;rr=(n>>3)&7;cc=n&7;
   character=ch;row=rr;column=cc;
   current_expected=ch<128 && rr<7 && cc<5?expected[ch][34-rr*5-cc]:1'b0;
   @(posedge clk);#1;
   if(single_lit!==current_expected || (n>0 && (lit!==last_expected || alternate_lit!==last_expected)))begin
    $display("FONT_PIXEL_MISMATCH at %0d",n-1);$finish;
   end
   last_expected=current_expected;
  end
  $display("A1_SHARED_FONT_PASS 16384 ASCII_ROW_COLUMN_CASES THREE_PIPELINE_FORMS");$finish;
 end
endmodule
