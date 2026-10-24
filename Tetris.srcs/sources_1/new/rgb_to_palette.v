// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块：rgb_to_palette
// 作用：把画面输出的 24 位 RGB 映射为网络调色板索引。
// 说明：56 种颜色在所选 8 位上无碰撞，因此无需比较完整 24 位。
//       若调色板新增颜色，必须重新验证并补充 sim/rgb_palette。
// 时序：同步 ROM；输入来自 net_screen_tx 已寄存的 rgb_r。
//============================================================
module rgb_to_palette(
  input         Clk,
  input  [23:0] rgb,
  output reg [5:0] code
);

wire [7:0] hash = {rgb[20], rgb[18], rgb[14], rgb[12], rgb[8], rgb[7], rgb[5], rgb[2]};
(* rom_style = "block" *) reg [5:0] rom[0:255];
integer i;

initial begin
  for(i=0; i<256; i=i+1)
    rom[i] = 6'd0;
  rom[8'h00] = 6'd0;
  rom[8'h27] = 6'd1;
  rom[8'h9D] = 6'd2;
  rom[8'hF8] = 6'd3;
  rom[8'h59] = 6'd4;
  rom[8'hC2] = 6'd5;
  rom[8'hFB] = 6'd6;
  rom[8'hEF] = 6'd7;
  rom[8'hA7] = 6'd8;
  rom[8'h9F] = 6'd9;
  rom[8'hFC] = 6'd10;
  rom[8'hDE] = 6'd11;
  rom[8'hE6] = 6'd12;
  rom[8'hFE] = 6'd13;
  rom[8'hDC] = 6'd14;
  rom[8'h67] = 6'd15;
  rom[8'hFF] = 6'd16;
  rom[8'h90] = 6'd17;
  rom[8'h02] = 6'd18;
  rom[8'h20] = 6'd19;
  rom[8'h22] = 6'd20;
  rom[8'h94] = 6'd21;
  rom[8'h96] = 6'd22;
  rom[8'hB4] = 6'd23;
  rom[8'h92] = 6'd24;
  rom[8'h2F] = 6'd25;
  rom[8'h2B] = 6'd26;
  rom[8'h09] = 6'd27;
  rom[8'h11] = 6'd28;
  rom[8'hC0] = 6'd29;
  rom[8'h6B] = 6'd30;
  rom[8'h5B] = 6'd31;
  rom[8'hF9] = 6'd32;
  rom[8'h03] = 6'd33;
  rom[8'h32] = 6'd34;
  rom[8'hA9] = 6'd35;
  rom[8'hC9] = 6'd36;
  rom[8'h37] = 6'd37;
  rom[8'hD4] = 6'd38;
  rom[8'hBD] = 6'd39;
  rom[8'hB1] = 6'd40;
  rom[8'hF3] = 6'd41;
  rom[8'hD9] = 6'd42;
  rom[8'hEB] = 6'd43;
  rom[8'h10] = 6'd44;
  rom[8'h51] = 6'd45;
  rom[8'h42] = 6'd46;
  rom[8'h21] = 6'd47;
  rom[8'h3C] = 6'd48;
  rom[8'h89] = 6'd49;
  rom[8'hE8] = 6'd50;
  rom[8'h19] = 6'd51;
  rom[8'h8A] = 6'd52;
  rom[8'hA3] = 6'd53;
  rom[8'h39] = 6'd54;
  rom[8'h50] = 6'd55;
end

always@(posedge Clk)
  code <= rom[hash];

endmodule
