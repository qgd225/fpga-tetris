`timescale 1ns/1ps

// 1 拍读延迟的形状 ROM 仿真桩, 数据与 Tetromino.mif 完全一致
module Tetromino(input clka, input [4:0] addra, output reg [31:0] douta);
function [31:0] shape_of;
input [4:0] a;
begin
case(a)
5'd0:shape_of=32'h0D0E0F00; 5'd1:shape_of=32'h30201000;
5'd2:shape_of=32'h0D0E0F00; 5'd3:shape_of=32'h30201000;
5'd4:shape_of=32'h1FFF0F00; 5'd5:shape_of=32'h0E1F0F00;
5'd6:shape_of=32'h1F201000; 5'd7:shape_of=32'h0EFF0F00;
5'd8:shape_of=32'h1F0F1000; 5'd9:shape_of=32'h1F0F1000;
5'd10:shape_of=32'h1F0F1000;5'd11:shape_of=32'h1F0F1000;
5'd12:shape_of=32'h1F0FF0FF;5'd13:shape_of=32'h10000F0E;
5'd14:shape_of=32'h1F1E0FFF;5'd15:shape_of=32'h000F0EFE;
5'd16:shape_of=32'h101F0FFF;5'd17:shape_of=32'h1E000F0E;
5'd18:shape_of=32'h1F0FFFFE;5'd19:shape_of=32'h000F0EF0;
5'd20:shape_of=32'h10000FFF;5'd21:shape_of=32'h1F1E000F;
5'd22:shape_of=32'h1F0F0EFE;5'd23:shape_of=32'h0F0EF0FF;
5'd24:shape_of=32'h1F000FF0;5'd25:shape_of=32'h101F0F0E;
5'd26:shape_of=32'h1E0F0EFF;5'd27:shape_of=32'h000FFFFE;
default:shape_of=32'h0;
endcase
end
endfunction
always@(posedge clka)douta<=shape_of(addra);
endmodule

module solo_hint_tb;
reg Clk=0, Rst=0, start=0, duo=0, Playing=1;
reg [2:0] type=0;
reg [479:0] rows=0;
wire hint_valid;
wire [2:0] hint_type;
wire [4:0] hint_c0,hint_c1,hint_c2,hint_c3,hint_r0,hint_r1,hint_r2,hint_r3;
integer bad=0, cyc, pidx, pcol, pheight, prow;

always #5 Clk=~Clk;
solo_hint #(.HINT_SETTLE_CYCLES(23'd20)) dut(.Clk_74M(Clk),.Reset_n(Rst),.start(start),.duo(duo),.Playing(Playing),.type(type),.row_bits(rows),
.hint_valid(hint_valid),.hint_type(hint_type),
.hint_c0(hint_c0),.hint_c1(hint_c1),.hint_c2(hint_c2),.hint_c3(hint_c3),
.hint_r0(hint_r0),.hint_r1(hint_r1),.hint_r2(hint_r2),.hint_r3(hint_r3));

task chk;
input [8*44-1:0] name;
input integer got;
input integer exp;
begin
if(got!==exp)begin $display("  FAIL %0s got=%0d exp=%0d",name,got,exp);bad=bad+1;end
else $display("  ok   %0s = %0d",name,got);
end
endtask

task set_row;
input integer r;
input [19:0] mask;
begin rows[r*24 +: 20] = mask; end
endtask

task reset_dut;
begin
Rst=0;start=0;duo=0;Playing=1;rows=0;type=0;repeat(4)@(posedge Clk);Rst=1;repeat(2)@(posedge Clk);#1;
end
endtask

task run_search;
input [2:0] t;
begin
type=t;start=1;@(posedge Clk);#1;start=0;
cyc=0;
while((dut.state==0)&&(cyc<20))begin @(posedge Clk);cyc=cyc+1;end
cyc=0;
while((dut.state!=0)&&(cyc<30000))begin @(posedge Clk);cyc=cyc+1;end
if(cyc>=30000)begin $display("  FAIL search timeout");bad=bad+1;end
#1;
end
endtask

function all_in_board;
input dummy;
integer i;
begin
all_in_board=1;
for(i=0;i<4;i=i+1)begin
case(i)
0:if((hint_c0>19)||(hint_r0>19))all_in_board=0;
1:if((hint_c1>19)||(hint_r1>19))all_in_board=0;
2:if((hint_c2>19)||(hint_r2>19))all_in_board=0;
default:if((hint_c3>19)||(hint_r3>19))all_in_board=0;
endcase
end
end
endfunction

function cell_at;
input integer idx_c;
input integer idx_r;
integer i;
begin
cell_at=0;
for(i=0;i<4;i=i+1)begin
case(i)
0:if((hint_c0==idx_c)&&(hint_r0==idx_r))cell_at=1;
1:if((hint_c1==idx_c)&&(hint_r1==idx_r))cell_at=1;
2:if((hint_c2==idx_c)&&(hint_r2==idx_r))cell_at=1;
default:if((hint_c3==idx_c)&&(hint_r3==idx_r))cell_at=1;
endcase
end
end
endfunction

function no_overlap;
input dummy;
integer i;
begin
no_overlap=1;
for(i=0;i<4;i=i+1)begin
case(i)
0:if(rows[hint_r0*24+hint_c0])no_overlap=0;
1:if(rows[hint_r1*24+hint_c1])no_overlap=0;
2:if(rows[hint_r2*24+hint_c2])no_overlap=0;
default:if(rows[hint_r3*24+hint_c3])no_overlap=0;
endcase
end
end
endfunction

initial begin
$display("=== solo_hint 深度搜索 ===");
// 平场
reset_dut; run_search(3'd3);
chk("flat valid",hint_valid,1); chk("flat type",hint_type,3); chk("flat cells in board",all_in_board(0),1); chk("flat no overlap",no_overlap(0),1);
// 近消行: 底行仅 8..11 空, I 旋转 1 必须补满并消行
reset_dut; set_row(19,20'hFF0FF); run_search(3'd0);
chk("near clear valid",hint_valid,1); chk("near clear rotation",dut.best_rot,1);
chk("near clear gap0",cell_at(8,19),1); chk("near clear gap1",cell_at(9,19),1);
chk("near clear gap2",cell_at(10,19),1); chk("near clear gap3",cell_at(11,19),1);
chk("near clear score",dut.best_score,-1248);
// 搜索期间棋盘变化不影响已锁存快照
reset_dut; set_row(19,20'hFF0FF); type=3'd0;
start=1; @(posedge Clk); #1; start=0;
cyc=0; while((dut.state==18)&&(cyc<200))begin @(posedge Clk);cyc=cyc+1;end
chk("snapshot captured",dut.board_snap[19*24 +: 20],20'hFF0FF);
rows=480'd0;
cyc=0; while((dut.state!=0)&&(cyc<30000))begin @(posedge Clk);cyc=cyc+1;end
chk("snapshot search valid",hint_valid,1); chk("snapshot search score",dut.best_score,-1248);
// 贴左墙: 只有 0..3 空, 水平 I 必须贴墙补满
reset_dut; set_row(19,20'hFFFF0); run_search(3'd0);
chk("wall valid",hint_valid,1); chk("wall rotation",dut.best_rot,1);
chk("wall c0",cell_at(0,19),1); chk("wall c3",cell_at(3,19),1);
// 已有空洞: 空洞总数必须被扫描到, 且候选不覆盖已有格
reset_dut; set_row(18,20'h00001); run_search(3'd0);
chk("hole valid",hint_valid,1); chk("hole counted",(dut.holes_total>0),1); chk("hole no overlap",no_overlap(0),1);
// 贴顶无合法落点
reset_dut; set_row(0,20'hFFFFF); run_search(3'd3);
chk("top full invalid",hint_valid,0); chk("top no best",dut.best_valid,0);
// 双人强制不启动
reset_dut; duo=1; start=1; repeat(20)@(posedge Clk); start=0; repeat(4)@(posedge Clk);
chk("duo no search",dut.state,0); chk("duo keeps invalid",hint_valid,0);
// 二次搜索: 触发后能从 IDLE 正常重算
reset_dut; set_row(19,20'hFF0FF); run_search(3'd0);
chk("repeat search1",hint_valid,1);
start=1;@(posedge Clk);#1;start=0;
chk("new trigger hides old hint",hint_valid,0);
cyc=0;while((dut.state!=0)&&(cyc<30000))begin @(posedge Clk);cyc=cyc+1;end
chk("repeat search2",hint_valid,1); chk("repeat still rotated",dut.best_rot,1);
// 逐列高度全面回归: 20 组阶梯地形, 智能落点不得覆盖任何锁存格
for(pidx=0;pidx<20;pidx=pidx+1)begin
  rows=480'd0;
  for(pcol=0;pcol<20;pcol=pcol+1)begin
    pheight=(pidx+pcol)%8;
    for(prow=19;prow>=20-pheight;prow=prow-1)
      rows[prow*24+pcol]=1'b1;
  end
  run_search(pidx%7);
  chk("staggered terrain no overlap",no_overlap(0),1);
end
if(bad==0)$display("=== ALL PASS ==="); else $display("=== FAILED %0d ===",bad);
$finish;
end
endmodule
