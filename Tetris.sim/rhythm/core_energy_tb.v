`timescale 1ns/1ps
`include "story_layout.vh"
module core_energy_tb;
 reg [10:0] x=0,y=0;reg reserve=1,blocked=0,half=0;reg [7:0] fill=0;
 wire hit;wire [5:0] color;integer bad=0,cy,count;
 core_renderer dut(.x(x),.y(y),.phase(2'd0),.danger(2'd0),.locked(4'd0),.success(1'b0),.failed(1'b0),
 .charging(1'b0),.blocked(blocked),.half_power(half),.reserve_mode(reserve),.reserve_pulse(1'b0),
 .reserve_fill(fill),.reserve_alarm(2'd0),.animation(8'd0),.hit(hit),.color_index(color));
 task ck;input pass;input [8*100-1:0] label;begin if(pass!==1)begin bad=bad+1;$display("FAIL CORE_ENERGY %0s",label);end end endtask
 task count_energy;begin count=0;for(cy=0;cy<256;cy=cy+1)begin y=`STORY_CORE_Y+cy;#1;if(color==37)count=count+1;end end endtask
 initial begin
  x=`STORY_CORE_X+40;fill=0;count_energy;ck(count==0,"empty reservoir has no lit fill");
  fill=1;count_energy;ck(count==1,"last nonzero supply remains visible above socket");y=`STORY_CORE_Y+243;#1;ck(color==37,"last pixel at visible bottom, not behind cap");
  fill=174;count_energy;ck(count==174,"full reservoir fills all visible channel rows");
  fill=92;count_energy;ck(count==92,"initial reservoir maps to actual visible fill");
  reserve=0;blocked=1;y=`STORY_CORE_Y+16;#1;ck(color==21,"locked mechanical crossbar visible");
  blocked=0;half=1;#1;ck(color==21,"half leaves upper shutters closed");y=`STORY_CORE_Y+208;#1;ck(color==50,"half opens lower empty channels without gifting energy");
  half=0;y=`STORY_CORE_Y+16;#1;ck(color!=21,"online empty channel differs from locked crossbar");
  if(bad==0)$display("ALL PASS CORE_ENERGY visible_rows=174");else $display("FAILED CORE_ENERGY %0d",bad);$finish;
 end
endmodule
