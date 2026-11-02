`timescale 1ns/1ps
module ui_core_chain_tb;
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 `include "game_mode_params.vh"
 integer mode,ship,n,checks=0;
 task ck;input ok;input [511:0] label;begin
  if(ok!==1)begin $display("FAIL CORE_CHAIN %0s mode=%0d ship=%0d debris=%0d",label,mode,ship,scenes.debris_left);$finish;end
  checks=checks+1;
 end endtask
 task pixel;input [10:0] x,y;begin
  @(negedge scenes.clk);scenes.set_pixel(x,y);repeat(8)@(negedge scenes.clk);
 end endtask
 task frame;begin
  @(negedge scenes.clk);scenes.set_pixel(0,0);
  @(negedge scenes.clk);scenes.set_pixel(1,0);repeat(6)@(negedge scenes.clk);
 end endtask
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  for(mode=0;mode<2;mode=mode+1)for(ship=0;ship<4;ship=ship+1)begin
   scenes.configure_scene(mode?4:3);scenes.ship=ship;scenes.charge_left=0;scenes.choose=1;frame;
   scenes.choose=0;scenes.debris_left=mode_total(mode,ship);scenes.locked=0;frame;
   pixel(1198,299);ck(scenes.dut.reference_layer.mission.material_pixel[25],"initial six-chain source");
   ck(scenes.dut.reference_layer.debris_flash==0,"entry is not a clear event");
   if(ship==0)begin
    scenes.debris_left=mode_total(mode,ship)-(mode?16:13);scenes.locked=3;frame;
    pixel(1198,299);ck(!scenes.dut.reference_layer.mission.blocked,"first row reaches HALF");
    ck(scenes.dut.reference_layer.mission.material_pixel[25],"first row must not remove chain");
    scenes.debris_left=mode_total(mode,ship);frame;
   end
   scenes.debris_left=mode_half(mode,ship);scenes.locked=3;frame;
   ck(scenes.dut.reference_layer.debris_flash==18,"debris decrease launches pulse");
   pixel(1198,299);ck(!scenes.dut.reference_layer.mission.blocked,"HALF electrical state");
   ck(scenes.dut.reference_layer.mission.material_pixel[25],"HALF still has front chain");
   pixel(1194,240);ck(scenes.dut.reference_layer.mission_rgb==24'hffc23a,"HALF amber collar");
   scenes.Stop=1;frame;ck(scenes.dut.reference_layer.debris_flash==18,"pause holds feedback");scenes.Stop=0;
   for(n=0;n<18;n=n+1)frame;
   ck(scenes.dut.reference_layer.debris_flash==0,"pulse expires");
   pixel(1194,490);ck(scenes.dut.reference_layer.mission.ink!=24'h040c13,"HALF cells lit behind chain");
   scenes.debris_left=1;frame;pixel(1198,299);ck(scenes.dut.reference_layer.mission.material_pixel[25],"last debris keeps chain");
   scenes.debris_left=0;scenes.locked=7;frame;pixel(1198,299);
   ck(!scenes.dut.reference_layer.mission.material_pixel[25],"zero debris removes chain");
   ck(scenes.dut.reference_layer.debris_flash==18,"final clear launches release flash");
   for(n=0;n<8;n=n+1)frame;
   pixel(1194,404);ck(scenes.dut.reference_layer.mission.ink==24'hb5fbff,"ONLINE release scan cyan");
   scenes.debris_left=mode_total(mode,ship);scenes.locked=0;frame;
   ck(scenes.dut.reference_layer.debris_flash==0,"restart does not trigger clear");
   scenes.debris_left=scenes.debris_left-1;frame;for(n=0;n<8;n=n+1)frame;
   pixel(1194,404);ck(scenes.dut.reference_layer.mission.ink==24'hd8442e,"LOCKED scan is red without persistent charge");
   scenes.choose=1;frame;ck(scenes.dut.reference_layer.debris_flash==0,"menu clears stale feedback");
  end
  scenes.configure_scene(6);frame;pixel(1198,299);
  ck(!scenes.dut.reference_layer.mission.material_pixel[25],"endless never uses chains");
  ck(scenes.dut.reference_layer.debris_flash==0,"endless disables debris feedback");
  $display("ALL PASS CORE_CHAIN checks=%0d",checks);$finish;
 end
endmodule
