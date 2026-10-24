// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module rgb_palette_tb;
  reg Clk;
  reg  [23:0] rgb;
  wire [5:0]  code;
  integer errors;
  integer checks;

  rgb_to_palette dut(.Clk(Clk), .rgb(rgb), .code(code));

  initial Clk = 1'b0;
  always #5 Clk = ~Clk;

  task check;
    input [23:0] c;
    input [5:0]  k;
    begin
      rgb = c;
      @(posedge Clk);
      #1;
      checks = checks + 1;
      if(code !== k)begin
        errors = errors + 1;
        $display("FAIL rgb=%06X got=%0d exp=%0d", c, code, k);
      end
      else
        $display("  ok   rgb=%06X -> %0d", c, code);
    end
  endtask

  initial begin
    errors = 0;
    checks = 0;
    check(24'h000000, 6'd0);
    check(24'h00CCFF, 6'd1);
    check(24'h9933CC, 6'd2);
    check(24'hFFFF00, 6'd3);
    check(24'hE63946, 6'd4);
    check(24'h55A630, 6'd5);
    check(24'hF77F24, 6'd6);
    check(24'hFF4DA6, 6'd7);
    check(24'h99EEFF, 6'd8);
    check(24'hD9B3E6, 6'd9);
    check(24'hFFFF99, 6'd10);
    check(24'hFFB3B9, 6'd11);
    check(24'hBDE0AA, 6'd12);
    check(24'hFFD9B3, 6'd13);
    check(24'hFFB3D9, 6'd14);
    check(24'hEEEEEE, 6'd15);
    check(24'hFFFFFF, 6'd16);
    check(24'h101010, 6'd17);
    check(24'h202020, 6'd18);
    check(24'h404040, 6'd19);
    check(24'h606060, 6'd20);
    check(24'h909090, 6'd21);
    check(24'hB0B0B0, 6'd22);
    check(24'hD8D8D8, 6'd23);
    check(24'h303030, 6'd24);
    check(24'h00E5FF, 6'd25);
    check(24'h00697F, 6'd26);
    check(24'h0A0F16, 6'd27);
    check(24'h081A1E, 6'd28);
    check(24'h1E0812, 6'd29);
    check(24'h04637E, 6'd30);
    check(24'h471F67, 6'd31);
    check(24'h74790D, 6'd32);
    check(24'h69222C, 6'd33);
    check(24'h295223, 6'd34);
    check(24'h71411D, 6'd35);
    check(24'h742B56, 6'd36);
    check(24'h6BF0FF, 6'd37);
    check(24'hFF98CB, 6'd38);
    check(24'h38D996, 6'd39);
    check(24'h9BD64D, 6'd40);
    check(24'hFFD23F, 6'd41);
    check(24'hFF9F1C, 6'd42);
    check(24'hFF6B35, 6'd43);
    check(24'h081018, 6'd44);
    check(24'h061017, 6'd45);
    check(24'h0D2029, 6'd46);
    check(24'h29404D, 6'd47);
    check(24'h08798A, 6'd48);
    check(24'h7B2B54, 6'd49);
    check(24'h17414B, 6'd50);
    check(24'h09171C, 6'd51);
    check(24'h10252B, 6'd52);
    check(24'h536A76, 6'd53);
    check(24'h80551F, 6'd54);
    check(24'h071018, 6'd55);
    if(errors != 0)begin
      $display("=== FAILED: %0d / %0d ===", errors, checks);
      $fatal;
    end
    $display("=== ALL PASS: %0d checks ===", checks);
    $finish;
  end
endmodule
