from pathlib import Path
import re
R=Path('D:/vivado_project/Tetris');P=R/'Tetris.srcs/sources_1/new'
def get(n):return (P/n).read_text(encoding='gbk')
def put(n,s):(P/n).write_text(s,encoding='gbk',newline='\n')
for f in (R/'sim').rglob('*_tb.v'):
 s=f.read_text(encoding='gbk');t=s.replace("1\\'b0","1'b0").replace("3\\'d0","3'd0")
 if t!=s:f.write_text(t,encoding='gbk',newline='\n')
s=get('Playfield.v').replace('parameter MCNT_Drop = 74_250_000 - 1','parameter MCNT_Drop = 74_218_750 - 1')
s=s.replace('    output reg [4:0] batch_n,','    output reg [4:0] batch_n,\n    output reg [2:0] batch_speed,')
s=s.replace('begin batch_active<=0; batch_n<=0; end','begin batch_active<=0; batch_n<=0; batch_speed<=0; end')
s=s.replace('begin batch_active<=1; batch_n<=d_clear; end','begin batch_active<=1; batch_n<=d_clear; batch_speed<=story_speed; end')
s=s.replace('    reg batch_active;','    reg batch_active;\n    wire clear_cancel = Idle || restart_board;')
for name,val in [('cl_stop',"6'd0"),('clear_cnt','0'),('clear_t',"1'b0"),('clear_tick',"6'd0"),('cl_tick',"5'd0"),('clear_t_t',"1'b0"),('clear_flash',"1'b1"),('line_t',"20'd0"),('clear_d',"1'b0"),('c_clear',"5'd0")]:
 pat=r'(if\(!Reset_n\)\s*'+name+r' <= [^;]+;)'
 s,n=re.subn(pat,r'\1\n    else if(clear_cancel)\n    '+name+' <= '+val+';',s,count=1)
 assert n==1,name
put('Playfield.v',s)
s=get('story_controller.v')
s=s.replace('    output reg phase_enter, charge_pulse,','    output reg phase_enter, charge_pulse, batch_commit,')
s=s.replace('    reg commit_pending;','    reg commit_pending;\n    reg credit_pending;')
s=s.replace("    wire [15:0] credited_lines = lines_total + (row_credit ? 16'd1 : 16'd0);","    wire [1:0] credit_delta = {1'b0,row_credit} + {1'b0,credit_pending};\n    wire [15:0] credited_lines = lines_total + credit_delta;")
s=s.replace('phase_enter<=0; charge_pulse<=0; finish_pending<=0;','phase_enter<=0; charge_pulse<=0; batch_commit<=0; credit_pending<=0; finish_pending<=0;')
s=s.replace('            phase_enter<=0; charge_pulse<=0;\n','            phase_enter<=0; charge_pulse<=0; batch_commit<=0;\n            if(row_credit && paused) credit_pending<=1;\n')
s=s.replace('                if(row_credit) begin','                credit_pending<=0;\n                if(credit_delta!=0) begin')
s=s.replace('                    commit_pending<=0;\n','                    commit_pending<=0; batch_commit<=1;\n')
put('story_controller.v',s)

put('bin_to_bcd.v', '''// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 串行双 dabble，只在一个输入快照转换完后更新显示值。
module bin_to_bcd #(parameter WIDTH=16, DIGITS=5)(
 input clk, reset_n, input [WIDTH-1:0] value,
 output reg [DIGITS*4-1:0] bcd
);
 reg [WIDTH+DIGITS*4-1:0] shift;
 reg [WIDTH+DIGITS*4-1:0] fixed_value;
 reg [5:0] step;
 integer i;
 always @(*) begin
  fixed_value=shift;
  for(i=0;i<DIGITS;i=i+1)
   if(fixed_value[WIDTH+i*4 +:4]>=5)
    fixed_value[WIDTH+i*4 +:4]=fixed_value[WIDTH+i*4 +:4]+4'd3;
 end
 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin shift<=0; step<=0; bcd<=0; end
  else if(step==0) begin shift<={{(DIGITS*4){1'b0}},value}; step<=1; end
  else begin
   shift<=fixed_value<<1;
   if(step==WIDTH) begin
    bcd<=(fixed_value<<1)>>WIDTH;
    step<=0;
   end else step<=step+1'b1;
  end
 end
endmodule
''')
s=get('frame.v').replace('    wire [4:0]batch_n;','    wire [4:0]batch_n;\n    wire [2:0]batch_speed;\n    wire batch_commit;')
s=s.replace('.phase_enter(phase_enter),.charge_pulse(charge_pulse),','.phase_enter(phase_enter),.charge_pulse(charge_pulse),.batch_commit(batch_commit),')
s=s.replace('.batch_done(batch_done), .batch_n(batch_n), .engine_quiescent(engine_quiescent),','.batch_done(batch_done), .batch_n(batch_n), .batch_speed(batch_speed), .engine_quiescent(engine_quiescent),')
a=s.index('    reg [19:0]lines_bcd;');b=s.index('    wire [4:0]cc_t [0:3];',a)
s=s[:a]+'''    wire [19:0]lines_bcd;
    bin_to_bcd line_digits(.clk(Clk_74M),.reset_n(Reset_n),
                          .value(lines_total),.bcd(lines_bcd));

'''+s[b:]
a=s.index('    scoring scoring_inst(');b=s.index('    wire next;',a)
part=s[a:b].replace('.clear_t_t(batch_done),','.clear_t_t(batch_commit),').replace('.speed_level(speed_level),','.speed_level(batch_speed),')
s=s[:a]+part+s[b:];put('frame.v',s)

s=get('scoring.v')
s=s.replace('    integer i;','''    integer i;
    function [8:0] square_lines;
    input [4:0] n;
    begin
      case(n)
'''+''.join(f"        5'd{n}:square_lines=9'd{n*n};\n" for n in range(21))+'''        default:square_lines=9'd0;
      endcase
    end
    endfunction
    wire [19:0] score_base = square_lines(c_clear)*SCORE_UNIT;
    wire [19:0] score_gain = score_base + (speed_level[0] ? score_base : 20'd0) +
                            (speed_level[1] ? score_base<<1 : 20'd0) +
                            (speed_level[2] ? score_base<<2 : 20'd0);
''')
s=s.replace("counter <= counter + (({17'd0,speed_level}+20'd1)*SCORE_UNIT)*c_clear*c_clear;",'counter <= counter + score_gain;')
put('scoring.v',s)
for f in list((R/'sim').rglob('*.bat'))+list((R/'sim').rglob('*.ps1')):
 s=f.read_text(encoding='utf-8');t=re.sub(r'([^\s\x27\x22]*new[\\/])story_controller\.v',lambda m:m[0]+' '+m[1]+'bin_to_bcd.v',s)
 if t!=s:f.write_text(t,encoding='utf-8',newline='\r\n' if f.suffix=='.bat' else '\n')
print('Pause boundary credits, captured scoring speed, clear cancellation, and full-width BCD integrated.')
