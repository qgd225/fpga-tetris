`timescale 1ns/1ps
module net_audio_tb;
 reg clk=0,rst=0,por=0,ce=0,grant=0,full=0,dfull=0;
 reg [15:0] pcm=0;
 wire request,write,ready,overflow;wire [31:0] word;wire [15:0] length;
 integer bad=0,words=0,packets=0,samples=0,j,k,cycle;reg [31:0] seen[0:124];
 always #5 clk=~clk;
 net_audio_packetizer dut(clk,rst,por,ce,pcm,grant,full,dfull,request,word,write,ready,length,overflow);
 always @(posedge clk)if(rst)begin
  if(write)begin seen[words]=word;words=words+1;end
  if(ready)begin
   if(words!=125 || length!=500 || seen[0]!=32'ha55a0600 || seen[4]!=32'hbb8000f0)begin bad=bad+1;$display("FAIL header/length %d",words);end
   if(seen[2]!=packets || seen[3]!=packets*240)begin bad=bad+1;$display("FAIL sequence/index");end
   for(j=0;j<120;j=j+1)begin
    k=packets*240+2*j;
    if({seen[5+j][23:16],seen[5+j][31:24]}!==(k & 65535) || {seen[5+j][7:0],seen[5+j][15:8]}!==((k+1) & 65535))begin bad=bad+1;$display("FAIL PCM %d",k);end
   end
   packets=packets+1;words=0;
  end
 end
 initial begin
  repeat(3)@(negedge clk);por=1;rst=1;
  for(samples=0;samples<480;samples=samples+1)begin
   @(negedge clk);ce=1;pcm=samples;
   @(negedge clk);ce=0;
  end
  if(!request)begin bad=bad+1;$display("FAIL queued request");end
  grant=1;
  for(cycle=0;cycle<1500;cycle=cycle+1)begin @(negedge clk);full=(cycle%7==0);dfull=(cycle%11==0);end
  if(packets!=2 || overflow)begin bad=bad+1;$display("FAIL packet count/fault %d",packets);end
  // Block the consumer until overflow. Once idle, it must discard safely and recover.
  grant=0;
  for(samples=0;samples<1100;samples=samples+1)begin
   @(negedge clk);ce=1;pcm=samples;@(negedge clk);ce=0;
  end
  repeat(3)@(negedge clk);
  if(overflow || dut.session<2)begin bad=bad+1;$display("FAIL recovery");end
  if(bad==0)$display("ALL PASS NET_AUDIO");else $display("FAILED NET_AUDIO %d",bad);
  $finish;
 end
 initial begin #100000;$display("FAILED timeout");$finish;end
endmodule
