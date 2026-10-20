//============================================================
//    Type4 GAME OVER 成绩包编码: A5 5A 04 + 10 字节数据 + XOR
//============================================================
module result_packet(
    input [7:0]res_no,
    input mode,
    input [19:0]score,
    input [2:0]level,
    input [15:0]lines,
    input [13:0]time_sec,
    input [3:0]idx,
    output reg [7:0]dout
    );
    wire [7:0]mode_b = {7'd0,mode};
    wire [7:0]xor_res = res_no ^ mode_b ^ {4'd0,score[19:16]} ^ score[15:8] ^ score[7:0]
                      ^ {5'd0,level} ^ lines[15:8] ^ lines[7:0]
                      ^ {2'd0,time_sec[13:8]} ^ time_sec[7:0];
    always@(*)begin
    case(idx)
    4'd0: dout = 8'hA5;
    4'd1: dout = 8'h5A;
    4'd2: dout = 8'd4;
    4'd3: dout = res_no;
    4'd4: dout = mode_b;
    4'd5: dout = {4'd0,score[19:16]};
    4'd6: dout = score[15:8];
    4'd7: dout = score[7:0];
    4'd8: dout = {5'd0,level};
    4'd9: dout = lines[15:8];
    4'd10: dout = lines[7:0];
    4'd11: dout = {2'd0,time_sec[13:8]};
    4'd12: dout = time_sec[7:0];
    4'd13: dout = xor_res;
    default: dout = 8'h00;
    endcase
    end
endmodule