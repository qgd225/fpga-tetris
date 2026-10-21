`timescale 1ns/1ps





module result_packet_tb;
reg [7:0]res_no=8'h5A;
reg mode=0;
reg [19:0]score=20'h12345;
reg [2:0]level=3'd6;
reg [15:0]lines=16'h0128;
reg [13:0]time_sec=14'h0623;
reg [3:0]idx=0;
wire [7:0]dout;
integer bad=0,i;
reg [7:0]exp [0:13];
reg [7:0]x;
result_packet dut(.res_no(res_no),.mode(mode),.score(score),.level(level),.lines(lines),.time_sec(time_sec),.idx(idx),.dout(dout));
task chk; input [8*32-1:0]n; input [7:0]g,e; begin if(g!==e)begin $display(" FAIL %0s got=%h exp=%h",n,g,e);bad=bad+1;end else $display(" ok   %0s=%h",n,g);end endtask
initial begin
$display("=== result_packet SOLO/DUO 14B ===");
x = res_no ^ {7'd0,mode} ^ {4'd0,score[19:16]} ^ score[15:8] ^ score[7:0] ^ {5'd0,level} ^ lines[15:8] ^ lines[7:0] ^ {2'd0,time_sec[13:8]} ^ time_sec[7:0];
for(i=0;i<14;i=i+1)begin
 idx=i; #1;
 case(i)
 0:chk("hdr A5",dout,8'hA5); 1:chk("hdr 5A",dout,8'h5A); 2:chk("type4",dout,8'd4);
 3:chk("seq",dout,res_no); 4:chk("mode solo",dout,8'd0); 5:chk("score hi",dout,{4'd0,score[19:16]});
 6:chk("score mid",dout,score[15:8]); 7:chk("score low",dout,score[7:0]); 8:chk("level",dout,{5'd0,level});
 9:chk("lines hi",dout,lines[15:8]); 10:chk("lines low",dout,lines[7:0]); 11:chk("time hi",dout,{2'd0,time_sec[13:8]});
 12:chk("time low",dout,time_sec[7:0]); default:chk("xor",dout,x);
 endcase
end
mode=1;
x = res_no ^ 8'd1 ^ {4'd0,score[19:16]} ^ score[15:8] ^ score[7:0] ^ {5'd0,level} ^ lines[15:8] ^ lines[7:0] ^ {2'd0,time_sec[13:8]} ^ time_sec[7:0];
idx=4; #1; chk("mode duo",dout,8'd1);
idx=13; #1; chk("duo xor",dout,x);
idx=14; #1; chk("idx14 zero",dout,8'h00);
if(bad==0)$display("=== ALL PASS ==="); else $display("=== FAILED %0d ===",bad);
$finish;
end
endmodule
