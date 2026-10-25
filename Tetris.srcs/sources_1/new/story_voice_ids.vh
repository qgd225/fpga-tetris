// 与连续 ROM 一起生成；单位为四位样本。
function [16:0] voice_base;
input [2:0] id;
begin case(id)
3'd0:voice_base=17'd0;
3'd1:voice_base=17'd8028;
3'd2:voice_base=17'd27810;
3'd3:voice_base=17'd45652;
3'd4:voice_base=17'd63868;
3'd5:voice_base=17'd80968;
3'd6:voice_base=17'd101022;
default:voice_base=0;
endcase end
endfunction
function [16:0] voice_length;
input [2:0] id;
begin case(id)
3'd0:voice_length=17'd8028;
3'd1:voice_length=17'd19782;
3'd2:voice_length=17'd17842;
3'd3:voice_length=17'd18216;
3'd4:voice_length=17'd17100;
3'd5:voice_length=17'd20054;
3'd6:voice_length=17'd10550;
default:voice_length=0;
endcase end
endfunction
