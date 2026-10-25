// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 一路操作音：共享相位、噪声与短包络；禁止音默认选择短机械咔哒。
(* use_dsp = "no" *)
module audio_synth #(parameter BLOCK_STYLE=1)(input clk,reset_n,sample_ce,active,
    input [4:0] event_id,input [3:0] step_id,note_id,output signed [15:0] pcm);
    reg [19:0] position;
    reg [10:0] age;
    reg [4:0] event_d;reg [3:0] step_d,note_d;
    reg [11:0] noise;
    function [19:0] pitch;
        input [3:0] key;
        begin case(key)
        4'd1:pitch=20'd3208;
        4'd2:pitch=20'd8563;
        4'd3:pitch=20'd10789;
        4'd4:pitch=20'd11431;
        4'd5:pitch=20'd12830;
        4'd6:pitch=20'd14402;
        4'd7:pitch=20'd15258;
        4'd8:pitch=20'd17127;
        4'd9:pitch=20'd19224;
        4'd10:pitch=20'd21578;
        4'd11:pitch=20'd22861;
        4'd12:pitch=20'd25661;
        4'd13:pitch=20'd28803;
        4'd14:pitch=20'd34253;
        4'd15:pitch=20'd45722;
        default:pitch=0;
        endcase end
    endfunction
    wire blocked=event_id==4 || event_id==18;
    wire impact=blocked || event_id==8 || event_id==9 || event_id==16;
    wire [19:0] increment=impact?20'd3208:(event_id==5?20'd4282:pitch(note_id));
    wire [5:0] ramp=position[19]?~position[18:13]:position[18:13];
    wire signed [8:0] triangle=$signed({2'b00,ramp,1'b0})-9'sd63;
    wire signed [11:0] fundamental={{3{triangle[8]}},triangle};
    wire signed [11:0] tone=(event_id==5 || event_id==3 || event_id==2)?(fundamental<<<2):
        ((event_id>=11 && event_id<=14) || event_id==20 ? (fundamental<<<2):(fundamental<<<3));
    wire signed [11:0] hit=impact && !(blocked && BLOCK_STYLE==0) && age<96 ? (noise[0]?12'sd128:-12'sd128):12'sd0;
    wire signed [12:0] combined={tone[11],tone}+{hit[11],hit};
    wire [1:0] decay=age>=1024?2'd3:age[9:8];
    wire signed [12:0] decayed=combined>>>decay;
    wire signed [12:0] attack=age<8?13'sd0:(age<16?(decayed>>>2):(age<24?(decayed>>>1):decayed));
    wire suppressed=(blocked && BLOCK_STYLE==1 && step_id!=0) || (event_id==16 && (step_id!=0 || age>=960));
    assign pcm=(!reset_n || !active || note_id==0 || event_id==0 || suppressed)?16'sd0:
        (attack>512?16'sd512:(attack< -512?-16'sd512:attack));
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin position<=0;age<=0;event_d<=0;step_d<=0;note_d<=0;noise<=12'h6d5;end
        else if(sample_ce)begin
            event_d<=event_id;step_d<=step_id;note_d<=note_id;
            noise<={noise[10:0],noise[11]^noise[10]^noise[9]^noise[3]};
            if(!active || event_id!=event_d || step_id!=step_d || note_id!=note_d)begin position<=0;age<=0;end
            else begin position<=position+increment;if(age!=2047)age<=age+1'b1;end
        end
    end
endmodule
