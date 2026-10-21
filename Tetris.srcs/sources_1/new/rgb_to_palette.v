






module rgb_to_palette(
  input  [23:0] rgb,
  output reg [5:0] code
);


wire [6:0] hash = {rgb[12], rgb[9], rgb[8], rgb[7], rgb[6], rgb[5], rgb[4]};

always@(*)begin
  case(hash)
  7'h00: code = 6'd0;
  7'h01: code = 6'd29;
  7'h02: code = 6'd18;
  7'h04: code = 6'd19;
  7'h06: code = 6'd20;
  7'h0A: code = 6'd12;
  7'h0F: code = 6'd1;
  7'h11: code = 6'd35;
  7'h17: code = 6'd26;
  7'h1A: code = 6'd7;
  7'h1F: code = 6'd25;
  7'h22: code = 6'd33;
  7'h23: code = 6'd5;
  7'h2E: code = 6'd15;
  7'h2F: code = 6'd8;
  7'h31: code = 6'd27;
  7'h33: code = 6'd43;
  7'h35: code = 6'd36;
  7'h37: code = 6'd30;
  7'h41: code = 6'd17;
  7'h43: code = 6'd24;
  7'h49: code = 6'd21;
  7'h4B: code = 6'd22;
  7'h4C: code = 6'd38;
  7'h4D: code = 6'd23;
  7'h4F: code = 6'd37;
  7'h50: code = 6'd32;
  7'h54: code = 6'd4;
  7'h59: code = 6'd39;
  7'h5B: code = 6'd13;
  7'h61: code = 6'd28;
  7'h62: code = 6'd34;
  7'h63: code = 6'd41;
  7'h64: code = 6'd40;
  7'h70: code = 6'd3;
  7'h71: code = 6'd42;
  7'h72: code = 6'd6;
  7'h76: code = 6'd31;
  7'h79: code = 6'd10;
  7'h7B: code = 6'd11;
  7'h7C: code = 6'd2;
  7'h7D: code = 6'd14;
  7'h7E: code = 6'd9;
  7'h7F: code = 6'd16;
  default: code = 6'd0;
  endcase
end

endmodule
