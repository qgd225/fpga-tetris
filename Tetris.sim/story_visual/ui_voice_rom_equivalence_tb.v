`timescale 1ns/1ps
module ui_voice_rom_equivalence_tb;
 reg clk=0;always #5 clk=~clk;
 reg [16:0] address;wire [3:0] code;
 reg [3:0] expected[0:114687];
 integer n,index;
 voice_adpcm_rom dut(.clk(clk),.address(address),.code(code));
 initial begin
  $readmemh("story_voice.mem",expected);
  for(n=0;n<131072+4096;n=n+1)begin
   @(negedge clk);
   index=n<131072?n:((n-131072)*7919+17)%131072;address=index;
   @(posedge clk);#1;
   if(code!==(index<114688?expected[index]:4'd0))begin
    $display("VOICE_PACK_FAIL address=%0d actual=%h",index,code);$finish;
   end
  end
  $display("ALL PASS VOICE_PACK_EQUIVALENCE 131072 ADDRESSES 4096 SHUFFLED");$finish;
 end
endmodule
