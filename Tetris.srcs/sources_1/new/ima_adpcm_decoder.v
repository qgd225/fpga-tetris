// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// IMA ADPCM：步长查表、移位差分、饱和写回分三拍，无乘法器。
(* use_dsp = "no" *)
module ima_adpcm_decoder(
    input clk,reset_n,load,input signed [15:0] initial_predictor,input [6:0] initial_index,
    input decode_ce,input [3:0] code,
    output reg signed [15:0] predictor,output reg [6:0] step_index,
    output reg decoded_valid,output busy
);
    reg [1:0] phase;
    reg [3:0] code_r;
    reg [14:0] step_r;
    reg [16:0] diff_r;
    reg [6:0] next_index;
    function [14:0] step_value;
        input [6:0] address;
        begin case(address)
            7'd0:step_value=15'd7;
            7'd1:step_value=15'd8;
            7'd2:step_value=15'd9;
            7'd3:step_value=15'd10;
            7'd4:step_value=15'd11;
            7'd5:step_value=15'd12;
            7'd6:step_value=15'd13;
            7'd7:step_value=15'd14;
            7'd8:step_value=15'd16;
            7'd9:step_value=15'd17;
            7'd10:step_value=15'd19;
            7'd11:step_value=15'd21;
            7'd12:step_value=15'd23;
            7'd13:step_value=15'd25;
            7'd14:step_value=15'd28;
            7'd15:step_value=15'd31;
            7'd16:step_value=15'd34;
            7'd17:step_value=15'd37;
            7'd18:step_value=15'd41;
            7'd19:step_value=15'd45;
            7'd20:step_value=15'd50;
            7'd21:step_value=15'd55;
            7'd22:step_value=15'd60;
            7'd23:step_value=15'd66;
            7'd24:step_value=15'd73;
            7'd25:step_value=15'd80;
            7'd26:step_value=15'd88;
            7'd27:step_value=15'd97;
            7'd28:step_value=15'd107;
            7'd29:step_value=15'd118;
            7'd30:step_value=15'd130;
            7'd31:step_value=15'd143;
            7'd32:step_value=15'd157;
            7'd33:step_value=15'd173;
            7'd34:step_value=15'd190;
            7'd35:step_value=15'd209;
            7'd36:step_value=15'd230;
            7'd37:step_value=15'd253;
            7'd38:step_value=15'd279;
            7'd39:step_value=15'd307;
            7'd40:step_value=15'd337;
            7'd41:step_value=15'd371;
            7'd42:step_value=15'd408;
            7'd43:step_value=15'd449;
            7'd44:step_value=15'd494;
            7'd45:step_value=15'd544;
            7'd46:step_value=15'd598;
            7'd47:step_value=15'd658;
            7'd48:step_value=15'd724;
            7'd49:step_value=15'd796;
            7'd50:step_value=15'd876;
            7'd51:step_value=15'd963;
            7'd52:step_value=15'd1060;
            7'd53:step_value=15'd1166;
            7'd54:step_value=15'd1282;
            7'd55:step_value=15'd1411;
            7'd56:step_value=15'd1552;
            7'd57:step_value=15'd1707;
            7'd58:step_value=15'd1878;
            7'd59:step_value=15'd2066;
            7'd60:step_value=15'd2272;
            7'd61:step_value=15'd2499;
            7'd62:step_value=15'd2749;
            7'd63:step_value=15'd3024;
            7'd64:step_value=15'd3327;
            7'd65:step_value=15'd3660;
            7'd66:step_value=15'd4026;
            7'd67:step_value=15'd4428;
            7'd68:step_value=15'd4871;
            7'd69:step_value=15'd5358;
            7'd70:step_value=15'd5894;
            7'd71:step_value=15'd6484;
            7'd72:step_value=15'd7132;
            7'd73:step_value=15'd7845;
            7'd74:step_value=15'd8630;
            7'd75:step_value=15'd9493;
            7'd76:step_value=15'd10442;
            7'd77:step_value=15'd11487;
            7'd78:step_value=15'd12635;
            7'd79:step_value=15'd13899;
            7'd80:step_value=15'd15289;
            7'd81:step_value=15'd16818;
            7'd82:step_value=15'd18500;
            7'd83:step_value=15'd20350;
            7'd84:step_value=15'd22385;
            7'd85:step_value=15'd24623;
            7'd86:step_value=15'd27086;
            7'd87:step_value=15'd29794;
            7'd88:step_value=15'd32767;
            default:step_value=15'd32767;
        endcase end
    endfunction
    reg signed [8:0] index_sum;
    always @(*)begin
        case(code[2:0])
        0,1,2,3:index_sum=$signed({2'b00,step_index})-9'sd1;
        4:index_sum=$signed({2'b00,step_index})+9'sd2;
        5:index_sum=$signed({2'b00,step_index})+9'sd4;
        6:index_sum=$signed({2'b00,step_index})+9'sd6;
        default:index_sum=$signed({2'b00,step_index})+9'sd8;
        endcase
    end
    wire [16:0] step_wide={2'b00,step_r};
    wire signed [17:0] old_predictor={{2{predictor[15]}},predictor};
    wire signed [17:0] difference={1'b0,diff_r};
    wire signed [17:0] updated=code_r[3]?old_predictor-difference:old_predictor+difference;
    assign busy=phase!=0;
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            phase<=0;code_r<=0;step_r<=0;diff_r<=0;next_index<=0;predictor<=0;step_index<=0;decoded_valid<=0;
        end else if(load)begin
            phase<=0;predictor<=initial_predictor;step_index<=initial_index>88?7'd88:initial_index;decoded_valid<=0;
        end else begin
            decoded_valid<=0;
            case(phase)
            0:if(decode_ce)begin
                code_r<=code;step_r<=step_value(step_index);
                next_index<=index_sum<0?7'd0:(index_sum>88?7'd88:index_sum[6:0]);phase<=1;
            end
            1:begin
                diff_r<=(step_wide>>3)+(code_r[0]?(step_wide>>2):17'd0)+
                         (code_r[1]?(step_wide>>1):17'd0)+(code_r[2]?step_wide:17'd0);phase<=2;
            end
            2:begin
                predictor<=updated > 18'sd32767 ? 16'sh7fff : (updated < -18'sd32768 ? 16'sh8000 : updated[15:0]);
                step_index<=next_index;decoded_valid<=1;phase<=0;
            end
            default:phase<=0;
            endcase
        end
    end
endmodule
