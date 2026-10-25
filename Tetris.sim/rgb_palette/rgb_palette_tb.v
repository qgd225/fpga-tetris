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
    check(24'h38B6C8, 6'd1);
    check(24'h9B6BB5, 6'd2);
    check(24'hD9B23C, 6'd3);
    check(24'hC2453A, 6'd4);
    check(24'h4FA86B, 6'd5);
    check(24'hD97B33, 6'd6);
    check(24'h3E6FBF, 6'd7);
    check(24'h74CCD8, 6'd8);
    check(24'hB997CB, 6'd9);
    check(24'hE4C976, 6'd10);
    check(24'hD47D75, 6'd11);
    check(24'h84C297, 6'd12);
    check(24'hE4A370, 6'd13);
    check(24'h789AD2, 6'd14);
    check(24'hEEEEEE, 6'd15);
    check(24'hE8EEF2, 6'd16);
    check(24'h101010, 6'd17);
    check(24'h202020, 6'd18);
    check(24'h404040, 6'd19);
    check(24'h606060, 6'd20);
    check(24'h3A4A58, 6'd21);
    check(24'h5B6E7E, 6'd22);
    check(24'h243240, 6'd23);
    check(24'h303030, 6'd24);
    check(24'h2FA8B8, 6'd25);
    check(24'h7A2418, 6'd26);
    check(24'h0A1118, 6'd27);
    check(24'h2A3644, 6'd28);
    check(24'h1C2836, 6'd29);
    check(24'h1F646E, 6'd30);
    check(24'h553B64, 6'd31);
    check(24'h776221, 6'd32);
    check(24'h6B2620, 6'd33);
    check(24'h2B5C3B, 6'd34);
    check(24'h77441C, 6'd35);
    check(24'h223D69, 6'd36);
    check(24'h7FE3EC, 6'd37);
    check(24'hC4527A, 6'd38);
    check(24'h1B6B76, 6'd39);
    check(24'h7E2E4A, 6'd40);
    check(24'hE8A23C, 6'd41);
    check(24'hFFC96B, 6'd42);
    check(24'h8A5A18, 6'd43);
    check(24'h070A10, 6'd44);
    check(24'h050A0E, 6'd45);
    check(24'h131D26, 6'd46);
    check(24'h334650, 6'd47);
    check(24'h22303D, 6'd48);
    check(24'h16212B, 6'd49);
    check(24'h0C161E, 6'd50);
    check(24'hA8B6C0, 6'd51);
    check(24'hC9D2D8, 6'd52);
    check(24'h526774, 6'd53);
    check(24'hD8442E, 6'd54);
    check(24'h0E151C, 6'd55);
    if(errors != 0)begin
      $display("=== FAILED: %0d / %0d ===", errors, checks);
      $fatal;
    end
    $display("=== ALL PASS: %0d checks ===", checks);
    $finish;
  end
endmodule
