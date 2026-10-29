`timescale 1ns/1ps
// Full-pixel and nonsequential-address verification of the A1 ROM primitive.
// Probe wrappers and test vectors are generated in temporary/new_ui_a1.
module ui_exact_tile_rom_tb;
 reg clk=0,reset_n=0;
 reg [10:0] x=2047,y=2047;
 always #5 clk=~clk;
 wire [23:0] rgb0,rgb1,rgb2,rgb3;
 wire valid0,valid1,valid2,valid3;
 ui_a1_next_raw d0(clk,reset_n,x,y,rgb0,valid0);
 ui_a1_next_near d1(clk,reset_n,x,y,rgb1,valid1);
 ui_a1_core_raw d2(clk,reset_n,x,y,rgb2,valid2);
 ui_a1_core_near d3(clk,reset_n,x,y,rgb3,valid3);
 integer which,fd,pixel,width,height,count,addr,sample;
 reg [23:0] expected[0:32039],result,queue[0:2];
 reg valid;
 task outputs;
  begin
   case(which)
    0:begin result=rgb0;valid=valid0;end
    1:begin result=rgb1;valid=valid1;end
    2:begin result=rgb2;valid=valid2;end
    default:begin result=rgb3;valid=valid3;end
   endcase
  end
 endtask
 task capture;
  input integer id,w,h;
  input [2047:0] expected_file;
  input [511:0] output_file;
  begin
   which=id;width=w;height=h;count=w*h;x=2047;y=2047;
   repeat(5)@(negedge clk);
   $readmemh(expected_file,expected,0,count-1);
   fd=$fopen(output_file,"wb");$fwrite(fd,"P6\n%0d %0d\n255\n",w,h);
   for(pixel=0;pixel<count+2;pixel=pixel+1)begin
    @(negedge clk);
    if(pixel<count)begin x=pixel%w;y=pixel/w;end
    else begin x=2047;y=2047;end
    @(posedge clk);#1;outputs;
    if(pixel>=2)begin
     if(valid!==1 || result!==expected[pixel-2])begin
      $display("A1_PIXEL_FAIL probe=%0d pixel=%0d actual=%h expected=%h valid=%b",which,pixel-2,result,expected[pixel-2],valid);
      $fatal(1);
     end
     $fwrite(fd,"%c%c%c",result[23:16],result[15:8],result[7:0]);
    end
   end
   $fclose(fd);
   @(negedge clk);x=2047;y=2047;@(posedge clk);#1;outputs;
   if(valid!==0)$fatal(1,"INVALID_COORDINATE_NOT_MASKED");
   $display("A1_RTL_TEXTURE_DONE %0s %0d %0d ZERO_PIXEL_MISMATCHES",output_file,w,h);
   // Address jumps catch hidden dependencies on raster order/tile boundaries.
   for(sample=0;sample<514;sample=sample+1)begin
    @(negedge clk);
    addr=(sample*7919+17)%count;x=addr%w;y=addr/w;
    queue[2]=queue[1];queue[1]=queue[0];queue[0]=expected[addr];
    @(posedge clk);#1;outputs;
    if(sample>=2 && (valid!==1 || result!==queue[2]))$fatal(1,"RANDOM_ACCESS_FAIL");
   end
   $display("A1_NONRASTER_PASS probe=%0d samples=512",which);
  end
 endtask
 initial begin
  repeat(5)@(negedge clk);reset_n=1;
  `include "ui_a1_capture_calls.vh"
  $display("A1_ALL_FOUR_ROM_PROBES_PASS");$finish;
 end
endmodule
