`timescale 1ns/1ps
module ui_finish_tb #(parameter QUICK=0);
 ui_scenes_tb #(.EXTERNAL_DRIVER(1)) scenes();
 reg [23:0] expected[0:921599];
 reg pipe_mask[0:921599];
 reg corner_clear[0:921599];
 initial $readmemh("corner_clear.mem",corner_clear);
 initial $readmemh("pipe_mask.mem",pipe_mask);
 integer fd,n,count,px,py,checks,changes;
 reg protected_pixel;
 task capture;
  input [511:0] name,golden;
  input integer x0,y0,width,height,compare;
  begin
   count=width*height;checks=0;changes=0;
   if(compare)$readmemh(golden,expected,0,count-1);
   repeat(8)@(negedge scenes.clk);
   fd=$fopen(name,"wb");$fwrite(fd,"P6\n%0d %0d\n255\n",width,height);
   for(n=0;n<count+4;n=n+1)begin
    @(negedge scenes.clk);
    if(n<count)scenes.set_pixel(x0+n%width,y0+n/width);else scenes.set_pixel(0,0);
    @(posedge scenes.clk);#1;
    if(n>=4)begin
     px=x0+(n-4)%width;py=y0+(n-4)/width;
     protected_pixel=(px>=156 && px<1064 && py>=32 && py<128) ||
      (px>=143 && px<298 && py>=148 && py<320) ||
      (px>=154 && px<294 && py>=332 && py<506) ||
      (scenes.duo && px>=959 && px<1114 && py>=148 && py<320) ||
      (px>=1148 && px<1238 && py>=214 && py<570) ||
      (px>=972 && px<1108 && py>=364 && py<612) ||
      
      (px>=972 && px<1112 && py>=314 && py<356) ||
      (scenes.campaign && pipe_mask[py*1280+px]) ||
      (px>=(scenes.duo?352:400) && px<(scenes.duo?928:880) && py>=144 && py<624);
     if(corner_clear[py*1280+px])protected_pixel=0;
     if(!scenes.campaign && px>=168 && px<440 && py>=38 && py<128)protected_pixel=0;
     if(px>=1037 && px<=1043 && ((py>=368 && py<=376)||(py>=422 && py<=430)||(py>=476 && py<=484)||(py>=530 && py<=538)))protected_pixel=0;
     // The pipe's transparent neighborhood is a D2 shell area; use the
     // reference mask rather than excusing any opaque pipe pixel.
     if(^scenes.rgb===1'bx)begin $display("FINAL_UI_FAIL UNKNOWN %0s %0d %0d",name,px,py);$finish;end
     if(compare && scenes.rgb!==expected[n-4])begin
      changes=changes+1;
      if(protected_pixel)begin
       $display("FINAL_UI_FAIL PROTECTED %0s x=%0d y=%0d actual=%h golden=%h",name,px,py,scenes.rgb,expected[n-4]);$finish;
      end
     end
     if(compare && protected_pixel)checks=checks+1;
     $fwrite(fd,"%c%c%c",scenes.rgb[23:16],scenes.rgb[15:8],scenes.rgb[7:0]);
    end
   end
   $fclose(fd);$display("FINAL_UI_FRAME %0s SIZE %0d %0d ORIGIN %0d %0d PROTECTED %0d D123_CHANGES %0d",name,width,height,x0,y0,checks,changes);
  end
 endtask
 integer id;
 initial begin
  repeat(8)@(negedge scenes.clk);scenes.rst=1;
  if(QUICK)begin
   scenes.configure_scene(4);capture("duo_campaign.ppm","",0,0,1280,720,0);
   if(QUICK==2)begin $display("FINAL_UI_ALL_FRAMES_PASS");$finish;end
   scenes.configure_scene(5);capture("solo_endless.ppm","",0,0,1280,720,0);
   scenes.configure_scene(2);capture("duo_select.ppm","",0,0,1280,720,0);
   scenes.configure_scene(4);scenes.comms_visible=1;scenes.comms_id=1;capture("duo_comms.ppm","",0,0,1280,720,0);
   scenes.configure_scene(3);scenes.comms_visible=1;scenes.comms_id=0;capture("solo_comms.ppm","",0,0,1280,720,0);
   $display("FINAL_UI_ALL_FRAMES_PASS");$finish;
  end
  scenes.configure_scene(4);capture("duo_campaign.ppm","duo_campaign_expected.mem",0,0,1280,720,1);
  scenes.configure_scene(3);capture("solo_campaign.ppm","solo_campaign_expected.mem",0,0,1280,720,1);
  scenes.configure_scene(6);capture("duo_endless.ppm","duo_endless_expected.mem",0,0,1280,720,1);
  scenes.configure_scene(5);capture("solo_endless.ppm","solo_endless_expected.mem",0,0,1280,720,1);
  scenes.configure_scene(0);capture("main_menu.ppm","",0,0,1280,720,0);
  scenes.configure_scene(1);capture("solo_select.ppm","",0,0,1280,720,0);
  scenes.configure_scene(2);capture("duo_select.ppm","",0,0,1280,720,0);
  scenes.configure_scene(4);scenes.debris_left=39;scenes.locked=0;
  capture("core_locked.ppm","core_locked_expected.mem",1144,208,100,370,1);
  scenes.debris_left=18;scenes.locked=3;capture("core_half.ppm","core_half_expected.mem",1144,208,100,370,1);
  scenes.debris_left=0;scenes.locked=7;scenes.animation=16;capture("core_online7.ppm","core_online7_expected.mem",1144,208,100,370,1);
  scenes.locked=8;scenes.lines_bcd=24'h000035;scenes.success=1;capture("core_success8.ppm","core_success8_expected.mem",1144,208,100,370,1);
  scenes.configure_scene(4);scenes.Stop=1;capture("pause.ppm","",480,244,320,140,0);
  scenes.Stop=0;scenes.Finalize=1;scenes.result_ready=1;scenes.success=1;scenes.locked=8;scenes.debris_left=0;
  scenes.result_choice=1;capture("result_success.ppm","",400,216,480,392,0);
  scenes.success=0;scenes.result_choice=0;capture("result_failure.ppm","",400,216,480,392,0);
  scenes.configure_scene(5);scenes.Finalize=1;scenes.result_ready=1;scenes.success=0;
  capture("result_endless.ppm","",400,216,480,392,0);
  scenes.configure_scene(3);scenes.comms_visible=1;
  scenes.comms_id=0;capture("comms_0.ppm","",488,144,392,136,0);
  scenes.comms_id=1;capture("comms_1.ppm","",488,144,392,136,0);
  scenes.comms_id=2;capture("comms_2.ppm","",488,144,392,136,0);
  scenes.comms_id=3;capture("comms_3.ppm","",488,144,392,136,0);
  scenes.comms_id=4;capture("comms_4.ppm","",488,144,392,136,0);
  scenes.comms_id=5;capture("comms_5.ppm","",488,144,392,136,0);
  scenes.comms_id=6;capture("comms_6.ppm","",488,144,392,136,0);
  scenes.configure_scene(2);scenes.ship=3;scenes.menu_offset=1;
  capture("duo_select_ship4.ppm","",0,0,1280,720,0);
  scenes.configure_scene(5);scenes.reserve_alert=2;scenes.reserve_pixels=9;scenes.reserve_pulse=1;
  capture("reserve_critical_on.ppm","",972,208,244,452,0);
  scenes.reserve_pulse=0;capture("reserve_critical_off.ppm","",972,208,244,452,0);
  scenes.reserve_alert=0;scenes.reserve_pixels=174;scenes.popup_age=48;scenes.popup_units=96;scenes.popup_cap=1;
  capture("recharge_clipped.ppm","",704,504,128,80,0);
  scenes.popup_no_gain=1;capture("recharge_full.ppm","",704,504,128,80,0);
  scenes.configure_scene(3);scenes.debris_left=80;scenes.locked=0;
  capture("solo_locked_layout.ppm","",0,0,1280,720,0);
  for(id=0;id<4;id=id+1)begin
   scenes.configure_scene(4);scenes.locked=id==0?0:id==1?3:id==2?5:7;
   scenes.debris_left=id==0?39:id==1?18:id==2?9:0;
   case(id)
    0:capture("phase_0.ppm","",972,364,136,248,0);
    1:capture("phase_1.ppm","",972,364,136,248,0);
    2:capture("phase_2.ppm","",972,364,136,248,0);
    3:capture("phase_3.ppm","",972,364,136,248,0);
   endcase
  end
  scenes.configure_scene(1);scenes.ship=0;capture("solo_select_ship1.ppm","",0,0,1280,720,0);
  scenes.ship=2;capture("solo_select_ship3.ppm","",0,0,1280,720,0);
  scenes.ship=3;scenes.menu_offset=1;capture("solo_select_ship4.ppm","",0,0,1280,720,0);
  scenes.configure_scene(2);scenes.ship=0;capture("duo_select_ship1.ppm","",0,0,1280,720,0);
  scenes.ship=2;capture("duo_select_ship3.ppm","",0,0,1280,720,0);
  scenes.configure_scene(4);scenes.comms_visible=1;scenes.comms_id=1;capture("duo_comms.ppm","",0,0,1280,720,0);
  $display("FINAL_UI_ALL_FRAMES_PASS");$finish;
 end
endmodule
