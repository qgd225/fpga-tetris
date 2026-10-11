module Playfield_margin(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    
    output reg margin
    );
    
    always@(*)begin
    if(     (hcounter >= 317 && hcounter < 320 &&  vcounter >= 80) ||
            (hcounter >= 317 && hcounter < 963 &&  vcounter < 80 && vcounter >= 77) ||
            (hcounter >= 960 && hcounter < 963 &&  vcounter >= 80))
    margin = 1'b1;
    else
    margin = 1'b0;
    end
    
endmodule
