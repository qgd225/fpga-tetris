// Spawn-only coordinates; exact subset of shape_rom.coe, users retain the original two-clock pipeline.
function [31:0] spawn_shape;
    input [2:0] piece;
    begin
        case (piece)
            3'd0: spawn_shape = 32'h0D0E0F00;
            3'd1: spawn_shape = 32'h1FFF0F00;
            3'd2: spawn_shape = 32'h1F0F1000;
            3'd3: spawn_shape = 32'h1F0FF0FF;
            3'd4: spawn_shape = 32'h101F0FFF;
            3'd5: spawn_shape = 32'h10000FFF;
            3'd6: spawn_shape = 32'h1F000FF0;
            default: spawn_shape = 32'h00000000;
        endcase
    end
endfunction
