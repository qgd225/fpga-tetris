// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module voice_pack_tb;
 reg clk=0,rst=0,ce=0,start=0,cancel=0,pause=0;always #5 clk=~clk;
 reg [3:0] divider=0;always @(negedge clk)begin divider=divider+1'b1;ce=divider==0;end
 reg [2:0] id=0;wire busy,done;wire signed [15:0] pcm;wire [16:0] index;wire [2:0] repetition;
 `include "voice_pack_count.vh"
 reg [15:0] expected[0:PACK_SAMPLES-1];reg [16:0] lengths[0:6];integer bases[0:6];integer order[0:6];
 integer errors=0,checks=0,k,n,seen,offset,limit,handle;reg monitor=0;
 reg [255:0] filename;
 voice_player dut(.clk(clk),.reset_n(rst),.sample_ce(ce),.start(start),.cancel(cancel),.pause(pause),.voice_id(id),
  .busy(busy),.done(done),.pcm(pcm),.sample_index(index),.repeat_index(repetition));
 task check;input condition;input [511:0] label;
 begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;if(errors<10)$display("FAIL voice pack id=%0d %0s seen=%0d index=%0d",id,label,seen,index);end end endtask
 task cycle;begin @(negedge clk);#1;end endtask
 always @(posedge clk)begin
  if(rst && ce && busy && monitor)begin
   check(index==seen/6 && repetition==seen%6,"all phrase sample ordinals");
   check(dut.current===expected[offset+seen/6],"independent full-pack PCM");
   check(pcm>= -600 && pcm<=600,"voice peak bounded");
   $fwrite(handle,"%04x\n",pcm);seen=seen+1;
  end
 end
 initial begin
  $readmemh("voice_pack_expected.mem",expected);$readmemh("voice_pack_lengths.mem",lengths);
  bases[0]=0;for(k=1;k<7;k=k+1)bases[k]=bases[k-1]+lengths[k-1];
  order[0]=0;order[1]=3;order[2]=1;order[3]=6;order[4]=2;order[5]=5;order[6]=4;
  cycle;cycle;rst=1;cycle;
  for(k=0;k<7;k=k+1)begin
   id=order[k];offset=bases[id];seen=0;$sformat(filename,"voice%0d_pcm_48k.mem",id);handle=$fopen(filename,"w");
   start=1;cycle;start=0;monitor=1;limit=0;
   while(!busy && limit<30)begin cycle;limit=limit+1;end check(busy,"all phrases start");
   while(busy)cycle;
   monitor=0;$fclose(handle);check(seen==lengths[id]*6,"phrase length and no block-alignment padding");
   check(pcm==0 && done,"end silence and completion");cycle;
  end
  id=7;start=1;cycle;start=0;repeat(30)cycle;check(!busy && pcm==0,"invalid ID is silent");
  if(errors==0)$display("ALL PASS VOICE PACK checks=%0d source_samples=%0d",checks,PACK_SAMPLES);else $display("FAILED VOICE PACK errors=%0d",errors);
  $finish;
 end
 initial begin #150000000;$display("FAILED VOICE PACK timeout");$finish;end
endmodule
