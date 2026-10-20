//============================================================
// 模块：rgb_to_palette
// 作用：把画面输出的 24 位 RGB 映射为网络调色板索引。
// 说明：现有 39 种颜色在所选 7 位上无碰撞，因此无需比较完整 24 位。
//       若调色板新增颜色，必须重新验证并补充 sim/rgb_palette。
// 时序：纯组合；输入来自 net_screen_tx 已寄存的 rgb_r。
//============================================================
module rgb_to_palette(
  input  [23:0] rgb,
  output reg [5:0] code
);

// 位序：{rgb[15],rgb[12],rgb[11],rgb[9],rgb[6],rgb[5],rgb[0]}
wire [6:0] hash = {rgb[15], rgb[12], rgb[11], rgb[9], rgb[6], rgb[5], rgb[0]};

always@(*)begin
  case(hash)
  7'h00: code = 6'd0;  // 000000 空/黑
  7'h01: code = 6'd35; // 71411D
  7'h02: code = 6'd18; // 202020
  7'h04: code = 6'd19; // 404040
  7'h06: code = 6'd20; // 606060
  7'h0A: code = 6'd33; // 69222C
  7'h0E: code = 6'd30; // 04637E
  7'h10: code = 6'd29; // 1E0812
  7'h12: code = 6'd7;  // FF4DA6
  7'h17: code = 6'd26; // 00697F
  7'h18: code = 6'd27; // 0A0F16
  7'h1C: code = 6'd36; // 742B56
  7'h20: code = 6'd17; // 101010
  7'h22: code = 6'd24; // 303030
  7'h2B: code = 6'd34; // 295223
  7'h2C: code = 6'd2;  // 9933CC
  7'h31: code = 6'd32; // 74790D
  7'h34: code = 6'd4;  // E63946
  7'h38: code = 6'd28; // 081A1E
  7'h3A: code = 6'd6;  // F77F24
  7'h3F: code = 6'd31; // 471F67
  7'h42: code = 6'd12; // BDE0AA
  7'h47: code = 6'd25; // 00E5FF
  7'h4A: code = 6'd5;  // 55A630
  7'h57: code = 6'd1;  // 00CCFF
  7'h5E: code = 6'd15; // EEEEEE
  7'h5F: code = 6'd8;  // 99EEFF
  7'h60: code = 6'd21; // 909090
  7'h62: code = 6'd22; // B0B0B0
  7'h67: code = 6'd37; // 6BF0FF
  7'h6B: code = 6'd11; // FFB3B9
  7'h6D: code = 6'd14; // FFB3D9
  7'h6E: code = 6'd9;  // D9B3E6
  7'h73: code = 6'd13; // FFD9B3
  7'h74: code = 6'd23; // D8D8D8
  7'h75: code = 6'd38; // FF98CB
  7'h78: code = 6'd3;  // FFFF00
  7'h79: code = 6'd10; // FFFF99
  7'h7F: code = 6'd16; // FFFFFF
  default: code = 6'd0;
  endcase
end

endmodule
