// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module music_tb;
 reg clk=0,rst=0,ce=1,active=1,pause=0,Finalize=0,success=0,quiet=0;
 reg [1:0] phase=0;always #5 clk=~clk;
 wire signed [15:0] pcm;
 integer errors=0,checks=0,p,n,h,nz[0:3],saves,savec;reg [255:0] name;
 music dut(.Clk_74M(clk),.Reset_n(rst),.sample_ce(ce),.active(active),.pause(pause),.Finalize(Finalize),.success(success),.quiet(quiet),.phase(phase),.pcm(pcm));
 task check;input condition;input [511:0] label;
 begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;if(errors<8)$display("FAIL music %0s p=%0d n=%0d pcm=%0d",label,p,n,pcm);end end endtask
 task cycle;begin @(negedge clk);#1;end endtask
 initial begin
  cycle;cycle;rst=1;
  for(p=0;p<4;p=p+1)begin
   phase=p;cycle;cycle;nz[p]=0;$sformat(name,"bgm_phase%0d.mem",p);h=$fopen(name,"w");
   for(n=0;n<192000;n=n+1)begin
    cycle;check(pcm>= -160 && pcm<=160,"bounded two voice peak");
    if(pcm!=0)nz[p]=nz[p]+1;$fwrite(h,"%04x\n",pcm);
    if(n==1000)check(dut.increment1==(p==0?20'd1604:20'd3208),"same motif tonic and octave");
   end
   $fclose(h);
  end
  check(nz[0]>1000 && nz[0]<nz[1] && nz[1]<nz[2],"sparse to complete to stable structure");
  pause=1;saves=dut.step;savec=dut.step_count;repeat(256)cycle;
  check(pcm==0 && dut.step==saves && dut.step_count==savec,"pause fades and freezes sequence");
  pause=0;repeat(256)cycle;check(dut.attenuation==0,"resume gently restores gain");
  quiet=1;cycle;check(pcm==0,"success presentation hard silence");
  Finalize=1;success=1;quiet=0;active=0;repeat(200)cycle;
  check(dut.mode_d==2 && dut.increment1==3208,"post presentation resolution begins once");
  repeat(78000)cycle;check(dut.env1==0 && dut.env2<=4,"resolution leaves low device tone");
  Finalize=0;active=1;phase=2;repeat(300)cycle;Finalize=1;success=0;active=0;repeat(256)cycle;
  check(pcm==0,"failure fades out");
  Finalize=0;repeat(5)cycle;check(pcm==0,"menu and idle are silent");
  $display("MUSIC_NONZERO p0=%0d p1=%0d p2=%0d p3=%0d",nz[0],nz[1],nz[2],nz[3]);
  if(errors==0)$display("ALL PASS STORY MUSIC checks=%0d",checks);else $display("FAILED STORY MUSIC errors=%0d",errors);
  $finish;
 end
endmodule
