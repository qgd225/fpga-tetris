// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 四阶段共用三音动机 D-A-E，仅两声部；48k 使能驱动，不储存整曲。
(* use_dsp = "no" *)
module music(input Clk_74M,Reset_n,sample_ce,active,pause,Finalize,success,quiet,
    input [1:0] phase,output signed [15:0] pcm);
    reg [1:0] mode_d,phase_d;
    wire [1:0] wanted=quiet?2'd0:(Finalize?(success?2'd2:2'd3):(active?2'd1:2'd0));
    reg [19:0] position1,position2,increment1;
    reg [13:0] step_count;
    reg [3:0] step,env1,env2;
    reg [9:0] envelope_count;
    reg [1:0] attenuation;
    reg [7:0] tap_left;
    reg [11:0] noise;
    wire [13:0] step_last=(phase==3 && mode_d==1)?14'd8999:14'd11999;
    wire [3:0] next_step=step+1'b1;
    function [2:0] note_at;
        input [1:0] mode,p;input [3:0] s;
        begin
            note_at=0;
            if(mode==2)case(s)
                0:note_at=3;2:note_at=4;4:note_at=6;6:note_at=7;default:note_at=0;
            endcase
            else if(p==0)case(s)
                0:note_at=1;8:note_at=2;default:note_at=0;
            endcase
            else if(p==3)case(s)
                0:note_at=3;2,6,10,14:note_at=4;4,12:note_at=5;8:note_at=6;default:note_at=0;
            endcase
            else case(s)
                0:note_at=3;4,12:note_at=4;8:note_at=5;default:note_at=0;
            endcase
        end
    endfunction
    function [19:0] pitch;
        input [2:0] n;
        begin case(n)
            3'd0:pitch=20'd0;
            3'd1:pitch=20'd1604;
            3'd2:pitch=20'd2403;
            3'd3:pitch=20'd3208;
            3'd4:pitch=20'd4806;
            3'd5:pitch=20'd7201;
            3'd6:pitch=20'd6415;
            default:pitch=0;
        endcase end
    endfunction
    function signed [7:0] triangle;
        input [19:0] p;reg [5:0] ramp;
        begin ramp=p[19]?~p[18:13]:p[18:13];triangle=$signed({1'b0,ramp,1'b0})-8'sd63;end
    endfunction
    function signed [11:0] shape;
        input signed [7:0] t;input [3:0] e;reg signed [11:0] w;
        begin w={{4{t[7]}},t};shape=(e[0]?w:12'sd0)+(e[1]?(w<<<1):12'sd0)+
            (e[2]?(w<<<2):12'sd0)+(e[3]?(w<<<3):12'sd0);end
    endfunction
    wire signed [11:0] lead=shape(triangle(position1),env1)>>>2;
    wire signed [11:0] bass=shape(triangle(position2),env2)>>>3;
    wire signed [11:0] tick_sound=tap_left==0?12'sd0:(noise[0]?12'sd12:-12'sd12);
    wire signed [11:0] auxiliary=(phase==1 && mode_d==1)?tick_sound:bass;
    wire signed [12:0] combined={lead[11],lead}+{auxiliary[11],auxiliary};
    assign pcm=(mode_d==0 || attenuation==3 || quiet)?16'sd0:(combined>>>attenuation);
    wire [2:0] upcoming=note_at(mode_d,phase,next_step);
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            mode_d<=0;phase_d<=0;position1<=0;position2<=0;increment1<=0;
            step_count<=0;step<=0;env1<=0;env2<=0;envelope_count<=0;attenuation<=3;tap_left<=0;noise<=12'ha37;
        end else if(sample_ce)begin
            mode_d<=wanted;phase_d<=phase;
            envelope_count<=envelope_count+1'b1;
            noise<={noise[10:0],noise[11]^noise[10]^noise[9]^noise[3]};
            if(wanted==0)begin
                position1<=0;position2<=0;increment1<=0;step_count<=0;step<=0;
                env1<=0;env2<=0;envelope_count<=0;attenuation<=3;tap_left<=0;
            end else begin
                position1<=position1+increment1;position2<=position2+pitch(1);
                if(envelope_count[5:0]==63)begin
                    if(pause || wanted==3)begin if(attenuation!=3)attenuation<=attenuation+1'b1;end
                    else if(attenuation!=0)attenuation<=attenuation-1'b1;
                end
                if(wanted!=mode_d || (wanted==1 && phase!=phase_d))begin
                    step<=0;step_count<=0;tap_left<=0;
                    if(wanted!=3)begin
                        position1<=0;position2<=0;increment1<=pitch(note_at(wanted,phase,0));env1<=8;
                        env2<=(wanted==2 || phase>=2)?4'd4:4'd0;attenuation<=3;envelope_count<=0;
                    end
                end else if(wanted!=3 && !pause)begin
                    if(&envelope_count)begin
                        if(env1>((wanted==1 && phase>=2)?2:0))env1<=env1-1'b1;
                        if(env2>((wanted==2 || phase>=2)?1:0))env2<=env2-1'b1;
                    end
                    if(tap_left!=0)tap_left<=tap_left-1'b1;
                    if(!(wanted==2 && step==15))begin
                        if(step_count==step_last)begin
                            step_count<=0;step<=next_step;
                            if(upcoming==7)begin env1<=0;increment1<=0;end
                            else if(upcoming!=0)begin increment1<=pitch(upcoming);env1<=8;end
                            if(wanted==1 && phase==1 && next_step[1:0]==2)tap_left<=128;
                            if(wanted==1 && phase>=2 && (phase==3?next_step[1:0]==0:next_step[2:0]==0))env2<=4;
                        end else step_count<=step_count+1'b1;
                    end
                end
            end
        end
    end
endmodule
