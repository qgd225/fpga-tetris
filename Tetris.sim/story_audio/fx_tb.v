// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module fx_tb;
 reg clk=0,rst=0,ce=1,active=0;always #5 clk=~clk;
 reg [4:0] id=0;reg [3:0] step=0,key=0;
 wire signed [15:0] click,double_pulse;
 integer errors=0,checks=0,n,e,h1,h2,count1,count2;
 audio_synth #(.BLOCK_STYLE(1)) a(.clk(clk),.reset_n(rst),.sample_ce(ce),.active(active),.event_id(id),.step_id(step),.note_id(key),.pcm(click));
 audio_synth #(.BLOCK_STYLE(0)) b(.clk(clk),.reset_n(rst),.sample_ce(ce),.active(active),.event_id(id),.step_id(step),.note_id(key),.pcm(double_pulse));
 task cycle;begin @(negedge clk);#1;end endtask
 task check;input c;input[511:0]label;begin checks=checks+1;if(c!==1'b1)begin errors=errors+1;if(errors<8)$display("FAIL FX %0s id=%0d step=%0d",label,id,step);end end endtask
 initial begin
  cycle;cycle;rst=1;active=1;id=4;key=1;
  h1=$fopen("blocked_click.mem","w");h2=$fopen("blocked_double.mem","w");count1=0;count2=0;
  for(n=0;n<4000;n=n+1)begin
   if(n==576)begin key=0;step=1;end
   if(n==960)begin key=1;step=2;end
   if(n==1824)active=0;
   cycle;$fwrite(h1,"%04x\n",click);$fwrite(h2,"%04x\n",double_pulse);
   if(n>=960 && n<1824)begin if(click!=0)count1=count1+1;if(double_pulse!=0)count2=count2+1;end
   check(click>= -512 && click<=512 && double_pulse>= -512 && double_pulse<=512,"bounded mechanical candidates");
  end
  $fclose(h1);$fclose(h2);check(count1==0 && count2>500,"short click chosen, double pulse retained only as test comparison");
  for(e=2;e<=23;e=e+1)begin
   id=e;step=0;key=8;active=1;
   for(n=0;n<2500;n=n+1)begin cycle;check(click>= -512 && click<=512,"every FX peak bounded");end
  end
  id=16;step=1;cycle;cycle;check(click==0,"failure is short impact, not old repeating melody");
  key=0;cycle;check(click==0,"rest silence");active=0;cycle;check(click==0,"inactive silence");
  if(errors==0)$display("ALL PASS STORY FX checks=%0d",checks);else $display("FAILED STORY FX errors=%0d",errors);
  $finish;
 end
endmodule
