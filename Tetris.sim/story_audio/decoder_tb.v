// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module decoder_tb;
    reg clk=0,rst=0,load=0,ce=0;always #5 clk=~clk;
    reg signed [15:0] initial_predictor=0;reg [6:0] initial_index=0;reg [3:0] code=0;
    wire signed [15:0] predictor;wire [6:0] step_index;wire valid,busy;
    reg [67:0] cases[0:9967];reg [3:0] codes[0:6747];reg [15:0] expected[0:6747];
    integer errors=0,checks=0,k,waits;
    ima_adpcm_decoder dut(.clk(clk),.reset_n(rst),.load(load),.initial_predictor(initial_predictor),.initial_index(initial_index),
      .decode_ce(ce),.code(code),.predictor(predictor),.step_index(step_index),.decoded_valid(valid),.busy(busy));
    task check;input condition;input [511:0] label;
      begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;if(errors<12)$display("FAIL decoder case=%0d %0s pred=%0d index=%0d",k,label,predictor,step_index);end end
    endtask
    task cycle;begin @(negedge clk);end endtask
    task initialize_state;input [15:0] pred;input [6:0] idx;
      begin load=1;initial_predictor=pred;initial_index=idx;cycle;load=0;#1;check(!busy && !valid && predictor==pred,"load initial state");end
    endtask
    task decode;input [3:0] nibble;input [15:0] pcm;
      begin
        ce=1;code=nibble;cycle;ce=0;waits=0;
        while(!valid && waits<5)begin cycle;waits=waits+1;end
        check(valid && !busy && predictor===pcm,"reference PCM, bounded response");
        cycle;check(!valid,"one clock valid pulse");
      end
    endtask
    initial begin
      $readmemh("decoder_cases.mem",cases);$readmemh("v0_codes.mem",codes);$readmemh("v0_expected.mem",expected);
      cycle;cycle;rst=1;cycle;
      for(k=0;k<9968;k=k+1)begin
        initialize_state(cases[k][65:50],cases[k][49:43]);
        decode(cases[k][42:39],cases[k][38:23]);decode(cases[k][42:39],cases[k][22:7]);
        check(step_index===cases[k][6:0],"reference final index");
      end
      initialize_state(0,0);
      for(k=0;k<6748;k=k+1)decode(codes[k],expected[k]);
      check(predictor==0 && step_index==0,"complete V0 final state");
      initialize_state(32767,88);ce=1;code=7;cycle;ce=0;check(busy,"in flight before replace");
      initialize_state(123,5);decode(0,124);check(step_index==4,"load cancels in flight code");
      initialize_state(0,127);check(step_index==88,"invalid initial index clamps");
      if(errors==0)$display("ALL PASS IMA DECODER checks=%0d cases=9968 stream_samples=6748",checks);
      else $display("FAILED IMA DECODER errors=%0d",errors);
      $finish;
    end
endmodule
