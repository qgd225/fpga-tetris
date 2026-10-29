`timescale 1ns/1ps
module ui_material_atlas_tb;
 `include "ui_material_geometry.vh"
 reg clk=0;always #5 clk=~clk;
 reg [12:0] address=0;reg [5:0] offset=0;
 wire [25:0] pixel;
 ui_material_atlas dut(.clk(clk),.address(address),.offset(offset),.pixel(pixel));
 reg [25:0] expected[0:MAT_MAP_WORDS*64-1];
 reg [25:0] e0,e1;
 integer n,index,total;
 initial begin
  $readmemh("ui_material_expected.mem",expected);total=MAT_MAP_WORDS*64+4096;
  for(n=0;n<total+2;n=n+1)begin
   @(negedge clk);
   if(n<MAT_MAP_WORDS*64)index=n;
   else index=((n-MAT_MAP_WORDS*64)*7919+2017)%(MAT_MAP_WORDS*64);
   address=index/64;offset=index%64;
   @(posedge clk);#1;
   if(n>=2 && pixel!==e1)begin
    $display("A3_ATLAS_FAIL sample=%0d actual=%h expected=%h",n-2,pixel,e1);$finish;
   end
   e1=e0;e0=expected[index];
  end
  $display("A3_ATLAS_ALL_PIXELS_PASS %0d NONSEQUENTIAL 4096",MAT_MAP_WORDS*64);$finish;
 end
endmodule
