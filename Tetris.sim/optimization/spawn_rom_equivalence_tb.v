`timescale 1ns/1ps
module spawn_rom_equivalence_tb;
localparam PITCH=24;
reg clk=0; always #5 clk=~clk;
reg reset_n=0,idle=1,duo=0,en_hold=0;
reg [2:0] p1=0,p2=0,ht=0;
reg [10:0] x=0,y=0,x1=170,y1=220,x2=990,y2=220;
wire [13:0] n_old,n_new; wire [12:0] h_old,h_new;
Next_piece_before #(.CELL_PITCH(PITCH)) old_n(clk,reset_n,x,y,idle,duo,p1,p2,x1,y1,x2,y2,n_old[0],n_old[1],n_old[2],n_old[3],n_old[8:4],n_old[13:9]);
Next_piece #(.CELL_PITCH(PITCH)) new_n(clk,reset_n,x,y,idle,duo,p1,p2,x1,y1,x2,y2,n_new[0],n_new[1],n_new[2],n_new[3],n_new[8:4],n_new[13:9]);
hold_piece_before #(.CELL_PITCH(PITCH)) old_h(clk,reset_n,x,y,idle,duo,ht,en_hold,x1,y1,x2,y2,h_old[0],h_old[1],h_old[2],h_old[7:3],h_old[12:8]);
hold_piece #(.CELL_PITCH(PITCH)) new_h(clk,reset_n,x,y,idle,duo,ht,en_hold,x1,y1,x2,y2,h_new[0],h_new[1],h_new[2],h_new[7:3],h_new[12:8]);
integer i,j,k,seed=19035,checks=0;
task check;
begin
 if(n_old!==n_new || h_old!==h_new || old_n.Tetromino_dout!==new_n.Tetromino_dout || old_n.Tetromino_dout2!==new_n.Tetromino_dout2 || old_h.Tetromino_dout!==new_h.Tetromino_dout) begin
  $display("FAIL i=%0d x=%0d y=%0d old=%h/%h new=%h/%h shape=%h/%h",i,x,y,n_old,h_old,n_new,h_new,old_n.Tetromino_dout,new_n.Tetromino_dout);$fatal;
 end
 checks=checks+1;
end endtask
initial begin
 #1; check;
 // Every valid shape, both players and HOLD, all preview pixel positions.
 for(i=0;i<7;i=i+1) begin
  @(negedge clk);p1=i;p2=6-i;ht=i;idle=0;duo=1;en_hold=1;
  @(posedge clk);#1;check;
  for(j=0;j<4*PITCH;j=j+1)for(k=0;k<4*PITCH;k=k+1)begin
   @(negedge clk);x=x1+j;y=y1+k;#1;check;
   x=x2+j;#1;check;
  end
 end
 // Changing shape each cycle checks the original one-cycle latency and controls.
 for(i=0;i<20000;i=i+1)begin
  @(negedge clk);p1=($random(seed)&32'h7fffffff)%7;p2=($random(seed)&32'h7fffffff)%7;ht=($random(seed)&32'h7fffffff)%7;
  x=$random(seed);y=$random(seed);x1=$random(seed);y1=$random(seed);x2=$random(seed);y2=$random(seed);
  idle=$random(seed);duo=$random(seed);en_hold=$random(seed);reset_n=$random(seed);#1;check;
  @(posedge clk);#1;check;
 end
 $display("ALL PASS SPAWN_ROM_EQUIVALENCE checks=%0d",checks);$finish;
end
endmodule
