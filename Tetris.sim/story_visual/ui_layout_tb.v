`timescale 1ns/1ps
module ui_layout_tb;
 reg clk=0,rst=0,choose=0,campaign=1,blocked=0;
 reg [10:0] x=0,y=0,gx=0,gy=0;
 reg [3:0] locked=3;
 wire [23:0] rgb,grgb,panel,gpanel;wire hit,ghit;
 integer px,py,state,checks=0;reg [10:0] cy;
 always #5 clk=~clk;
 ui_mission_layer dut(.clk(clk),.reset_n(rst),.enable(1'b1),.duo(1'b1),.campaign(campaign),.blocked(blocked),.chain_present(blocked),.choose(choose),.x(x),.y(y),.locked(locked),.reserve_alarm(2'd0),.reserve_pulse(1'b0),.reserve_fill(8'd104),.animation(8'd0),.charge_left(5'd0),.charge_percent(7'd42),.debris_percent(7'd37),.lit_top(10'd440),.panel_rgb(panel),.rgb(rgb),.hit(hit));
 ui_mission_layer_before golden(.clk(clk),.reset_n(rst),.enable(1'b1),.duo(1'b0),.campaign(campaign),.blocked(blocked),.choose(1'b0),.x(gx),.y(gy),.locked(locked),.reserve_alarm(2'd0),.reserve_pulse(1'b0),.reserve_fill(8'd104),.animation(8'd0),.charge_left(5'd0),.charge_percent(7'd42),.debris_percent(7'd37),.lit_top(10'd440),.panel_rgb(gpanel),.rgb(grgb),.hit(ghit));
 task compare;begin
  repeat(5)@(negedge clk);
  if(hit!==ghit || (hit && rgb!==grgb))begin $display("FAIL LAYOUT_PIXEL x=%0d y=%0d golden_x=%0d rgb=%h expected=%h",x,y,gx,rgb,grgb);$finish;end
  checks=checks+1;
 end endtask
 task ck;input good;input [511:0] label;begin if(good!==1)begin $display("FAIL LAYOUT %0s state=%0d x=%0d y=%0d phase=%0d arrow=%0d native=%b ink=%h rgb=%h",label,state,x,y,dut.phase,dut.arrow_y,dut.native,dut.ink,rgb);$finish;end end endtask
 initial begin
  repeat(4)@(negedge clk);rst=1;
  // All eight cells, front/back chain composition and four states translate exactly.
  for(state=0;state<4;state=state+1)begin
   blocked=state==0;locked=state==0?0:state==1?3:state==2?7:8;
   for(py=214;py<570;py=py+1)for(px=1148;px<1238;px=px+1)begin x=px;y=py;gx=px-24;gy=py;compare;end
  end
  blocked=0;locked=3;
  for(py=32;py<342;py=py+1)for(px=1049;px<1179;px=px+1)begin
   gx=px<1080?px:px<1104?1080:px-24;gy=py;
   if((gx>=1049 && gx<1155) && !(gx>=1124 && py>=214))begin
    x=px;y=py;
    // A side-panel pixel is not a pipe pixel in the reference.
    repeat(5)@(negedge clk);
    if(golden.base==golden.MAT_PIPE_BASE && ghit)begin
     ck(!(px<1122 && py>=148),"complete pipe/groove leaves eight-pixel panel gap");
     ck(hit && rgb==grgb,"stretched inlet preserves native pipe material");checks=checks+1;
    end
   end
  end
  for(py=148;py<310;py=py+1)begin
   x=1127;y=py;repeat(5)@(negedge clk);ck(hit,"left groove rail is continuous below old panel overlap");
  end
  // Independent regression for the former P2 chamfer baked into the joint.
  for(py=157;py<184;py=py+1)begin
   x=1136;y=py;repeat(5)@(negedge clk);
   ck(hit && rgb==24'hffde8a,"orange left bevel has no old panel fragment");checks=checks+1;
  end
  x=1137;y=149;repeat(5)@(negedge clk);
  ck(hit && rgb==24'h66edf6,"glass remains full width above the coupling");checks=checks+1;
  for(state=0;state<4;state=state+1)begin
   locked=state==0?0:state==1?3:state==2?5:7;cy=550-state*54;
   x=1040;y=cy-18;repeat(5)@(negedge clk);ck(rgb==24'hf5a21f,"up-arrow tip");
   x=1037;repeat(5)@(negedge clk);ck(rgb!=24'hf5a21f,"up-arrow narrow top");
   y=cy-12;repeat(5)@(negedge clk);ck(rgb==24'hf5a21f,"up-arrow wide bottom");
  end
  // The header must retain the full original ship in endless mode, too.
  campaign=0;x=240;y=94;gx=240;gy=94;repeat(5)@(negedge clk);
  ck(hit && rgb!=24'h0a1622,"endless header nose is not covered by mode plaque");
  choose=1;
  for(py=0;py<80;py=py+1)for(px=0;px<208;px=px+1)begin
   x=336+px;y=288+py;gx=232+px;gy=48+py;
   repeat(5)@(negedge clk);
   if(dut.ship_mask[py*208+px])begin ck(hit && rgb==gpanel,"complete ship reuses header RGB");checks=checks+1;end
   else ck(!hit,"ship exterior stays transparent");
  end
  $display("ALL PASS UI_LAYOUT NATIVE_CORE_PIPE_SHIP_ARROW checks=%0d",checks);$finish;
 end
endmodule
