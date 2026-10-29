localparam UI_TEXT_WORDS=2560;
function [6:0] ui_comms_template;
input [2:0] id;input second;
begin case({id,second})
4'd0:ui_comms_template=7'd1;
4'd1:ui_comms_template=7'd0;
4'd2:ui_comms_template=7'd2;
4'd3:ui_comms_template=7'd3;
4'd4:ui_comms_template=7'd4;
4'd5:ui_comms_template=7'd5;
4'd6:ui_comms_template=7'd6;
4'd7:ui_comms_template=7'd0;
4'd8:ui_comms_template=7'd7;
4'd9:ui_comms_template=7'd0;
4'd10:ui_comms_template=7'd8;
4'd11:ui_comms_template=7'd9;
4'd12:ui_comms_template=7'd10;
4'd13:ui_comms_template=7'd0;
4'd14:ui_comms_template=7'd0;
4'd15:ui_comms_template=7'd0;
default:ui_comms_template=0;
endcase end endfunction
