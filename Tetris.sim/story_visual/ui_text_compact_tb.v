`timescale 1ns/1ps
module ui_text_compact_tb;
 `include "ui_text_templates.vh"
 reg clk=0,rst=0,en=0;always #5 clk=~clk;
 reg [6:0] tid=0;reg [255:0] data=0,expanded=0;
 reg [11:0] dx=0,dy=0;reg [5:0] pitch=12,height=14,length=32;
 reg [8:0] rows[0:UI_TEXT_WORDS-1];integer n,i,t,k;
 wire actual,golden;
 ui_text_compact dut(clk,rst,en,tid,data,dx,dy,pitch,height,length,actual);
 ui_text_raster #(.REGISTER_DESCRIPTION(1)) oracle(clk,rst,en && dx[11:10]==0 && dy[11:6]==0,expanded,dx[9:0],dy[5:0],pitch,height,length,golden);
 initial begin
  $readmemh("ui_text_templates.mem",rows);repeat(4)@(negedge clk);rst=1;
  for(n=0;n<131075;n=n+1)begin
   @(negedge clk);dx=n%1024;dy=(n/1024)%64;tid=(n*37)% (UI_TEXT_WORDS/32);en=n%29!=0;if(n%19==0)dx=4095;if(n%23==0)dy=4095;if(n%31==0)dy=64;length=(n%31)+1;
   case((n/7)%8)0:pitch=8;1:pitch=12;2:pitch=14;3:pitch=16;4:pitch=18;5:pitch=20;6:pitch=24;7:pitch=30;endcase
   case((n/11)%4)0:height=14;1:height=21;2:height=28;3:height=35;endcase
   for(i=0;i<32;i=i+1)begin
    data[255-i*8-:8]=32+(n+i*17)%96;t=rows[tid*32+i];
    expanded[255-i*8-:8]=t[8]?data[255-i*8-:8]:t[7:0];
   end
   @(posedge clk);#1;
   if(n>=3 && actual!==golden)begin $display("FAIL TEXT_COMPACT n=%0d actual=%b golden=%b",n,actual,golden);$finish;end
  end
  $display("ALL PASS TEXT_COMPACT 131072 MIXED_TEMPLATE_SCALE_DYNAMIC_CASES");$finish;
 end
endmodule
