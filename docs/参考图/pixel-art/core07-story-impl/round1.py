from pathlib import Path
import re

ROOT = Path('D:/vivado_project/Tetris')
RTL = ROOT / 'Tetris.srcs/sources_1/new'

def load(name):
    return (RTL/name).read_text(encoding='gbk')

def save(name, text):
    (RTL/name).write_text(text, encoding='gbk', newline='\n')

def replace(text, old, new, count=1):
    assert text.count(old) == count, (old[:100], text.count(old), count)
    return text.replace(old, new)

save('story_controller.v', '''// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 四段修复任务：按真实行信用累计，在整批搬移结束后更新档位和结果。
module story_controller(
    input clk, reset_n, new_run, playing, paused, duo,
    input row_credit, batch_done, engine_quiescent, over_raw,
    output reg [15:0] lines_total,
    output reg [2:0] story_speed,
    output wire [1:0] story_phase,
    output wire [3:0] core_locked,
    output reg phase_enter, charge_pulse,
    output reg finish_pending, result_valid, result_success
);
    reg mode_duo;
    reg commit_pending;
    reg [2:0] next_speed;
    wire [15:0] credited_lines = lines_total + (row_credit ? 16'd1 : 16'd0);
    wire target_reached = credited_lines >= (mode_duo ? 16'd40 : 16'd32);
    assign story_phase = story_speed[2:1];
    assign core_locked = result_success ? 4'd8 : {1'b0,story_speed};
    always @(*) begin
        if(mode_duo)
            next_speed = (credited_lines>=35) ? 7 : (credited_lines>=30) ? 6 :
                         (credited_lines>=23) ? 5 : (credited_lines>=16) ? 4 :
                         (credited_lines>=11) ? 3 : (credited_lines>=6) ? 2 :
                         (credited_lines>=3) ? 1 : 0;
        else
            next_speed = (credited_lines>=28) ? 7 : (credited_lines>=24) ? 6 :
                         (credited_lines>=18) ? 5 : (credited_lines>=12) ? 4 :
                         (credited_lines>=8) ? 3 : (credited_lines>=4) ? 2 :
                         (credited_lines>=2) ? 1 : 0;
    end
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            lines_total<=0; story_speed<=0; mode_duo<=0; commit_pending<=0;
            phase_enter<=0; charge_pulse<=0; finish_pending<=0;
            result_valid<=0; result_success<=0;
        end else if(new_run) begin
            lines_total<=0; story_speed<=0; mode_duo<=duo; commit_pending<=0;
            phase_enter<=0; charge_pulse<=0; finish_pending<=0;
            result_valid<=0; result_success<=0;
        end else begin
            phase_enter<=0; charge_pulse<=0;
            if(batch_done) commit_pending<=1;
            if(playing && !paused && !result_valid) begin
                if(row_credit) begin
                    lines_total<=credited_lines;
                    charge_pulse<=1;
                    if(target_reached) finish_pending<=1;
                end
                if((batch_done || commit_pending) && engine_quiescent) begin
                    commit_pending<=0;
                    story_speed<=next_speed;
                    phase_enter<=next_speed[2:1]!=story_speed[2:1];
                    if(target_reached) begin
                        finish_pending<=1; result_valid<=1; result_success<=1;
                    end
                end else if(over_raw && !finish_pending && !target_reached) begin
                    result_valid<=1; result_success<=0;
                end
            end
        end
    end
endmodule
''')

s=load('Playfield_speed_control.v')
save('Playfield_speed_control.v', '''// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 任务控制器是唯一速度来源；仅选择八档自动下落周期。
module Playfield_speed_control #(
    parameter MCNT_Drop = 74_218_750 - 1
)(
    input Clk_74M, Reset_n,
    input [2:0] story_speed,
    output wire [2:0] speed_level,
    output reg [29:0] Drop
);
    assign speed_level = story_speed;
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) Drop <= (MCNT_Drop*64'd80)/64'd100;
        else case(story_speed)
            0:Drop <= (MCNT_Drop*64'd80)/64'd100;
            1:Drop <= (MCNT_Drop*64'd71)/64'd100;
            2:Drop <= (MCNT_Drop*64'd63)/64'd100;
            3:Drop <= (MCNT_Drop*64'd55)/64'd100;
            4:Drop <= (MCNT_Drop*64'd46)/64'd100;
            5:Drop <= (MCNT_Drop*64'd38)/64'd100;
            6:Drop <= (MCNT_Drop*64'd30)/64'd100;
            7:Drop <= (MCNT_Drop*64'd21)/64'd100;
        endcase
    end
endmodule
''')

s=load('Playfield.v')
s=replace(s,'    input Playing,','    input Playing,\n    input mission_hold,\n    input [2:0] story_speed,')
s=replace(s,'    output wire move_we,','    output wire batch_done,\n    output reg [4:0] batch_n,\n    output wire engine_quiescent,\n    output wire move_we,')
# 删除旧速度阈值参数，实际下落周期仍可由仿真覆盖。
s=re.sub(r'    parameter \[19:0\]LV1_TH.*?    parameter CLEAR_STEP', '    parameter CLEAR_STEP',s,flags=re.S)
s=re.sub(r'    parameter \[13:0\]TIME_LV1_D.*?TIME_LV7_D[^;]*;\n','',s,flags=re.S)
a=s.index('    Playfield_speed_control #(');b=s.index('    // Hold 控制:',a)
s=s[:a]+'''    Playfield_speed_control #(.MCNT_Drop(MCNT_Drop)) speed_control_inst(
        .Clk_74M(Clk_74M), .Reset_n(Reset_n), .story_speed(story_speed),
        .speed_level(speed_level), .Drop(Drop)
    );

'''+s[b:]
s=replace(s,'    reg [3:0]clear_tick;','    reg [5:0]clear_tick;')
s=replace(s,'    reg [2:0]cl_tick;','    reg [4:0]cl_tick;')
s=replace(s,'    reg [3:0]cl_stop;','    reg [5:0]cl_stop;')
s=replace(s,'    wire clear_down = (!clear_time) && (clear_d);','''    wire clear_down = (!clear_time) && (clear_d);
    wire player_stop = Stop || mission_hold;
    reg batch_active;
    assign batch_done = clear_down && batch_active;
    assign engine_quiescent = !board_busy && !lock_we && !lock_we2 &&
                              !lock_pending2 && !clear_time;
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) begin batch_active<=0; batch_n<=0; end
        else if(restart_board) begin batch_active<=0; batch_n<=0; end
        else if(clear_pulse) begin batch_active<=1; batch_n<=d_clear; end
        else if(batch_done) batch_active<=0;
    end''')
s=s.replace('.Stop(Stop),','.Stop(player_stop),')
s=s.replace('else if(Stop || board_busy)','else if(player_stop || board_busy)')
s=s.replace('else if(Playing)begin','else if(Playing && !player_stop)begin')
s=s.replace('&& Playing)','&& Playing && !player_stop)')
# 锁存前视觉计时可暂停，已经接受的四格写入和搬移保持原子收尾。
for name in ['counter_land','counter_land2','lock_counter','lock_counter2']:
    pat=r'(if\(!Reset_n\)\s*'+name+r' <= [^;]+;)'
    s,n=re.subn(pat,r'\1\n        else if(player_stop) '+name+' <= '+name+';',s,count=1)
    assert n==1,name
s=s.replace('wire land_pulse_t = (land) &&','wire land_pulse_t = Playing && !player_stop && (land) &&')
s=s.replace('wire land_pulse_t2 = (land2) &&','wire land_pulse_t2 = Playing && !player_stop && (land2) &&')
s=s.replace('assign land_pulse = (lock_counter == 5940000) ? 1:0;','assign land_pulse = Playing && !player_stop && (lock_counter == 5940000);')
s=s.replace('assign land_pulse2 = (lock_counter2 == 5940000) ? 1 : 0;','assign land_pulse2 = Playing && !player_stop && (lock_counter2 == 5940000);')
s=replace(s,'    else if(!clear_t)\n    clear_cnt <= 0;','    else if(!clear_t)\n    clear_cnt <= 0;\n    else if(Stop)\n    clear_cnt <= clear_cnt;')
s=replace(s,'assign clear_step = (clear_t) && (clear_cnt == CLEAR_STEP);','assign clear_step = !Stop && (clear_t) && (clear_cnt == CLEAR_STEP);')
s=s.replace('(d_clear << 1) - 4\'d1','({1\'b0,batch_n} << 1) - 6\'d1')
s=s.replace('cl_tick < d_clear','cl_tick < batch_n')
s=s.replace('else if(clear_t_t)\n    c_clear <= d_clear;','else if(clear_pulse)\n    c_clear <= d_clear;')
s=replace(s,'&& Playing && !board_busy && !lock_we && !(duo && lock_we2))','&& Playing && !player_stop && !clear_time && !board_busy && !lock_we && !(duo && lock_we2))')
save('Playfield.v',s)

s=load('frame.v')
s=replace(s,'    output [1:0] danger_lvl','''    output mission_win,
    output mission_hold,
    output [1:0] story_phase,
    output mission_success,
    output [1:0] danger_lvl''')
a=s.index('    reg [15:0]lines_total;');b=s.index('    assign lines = lines_total;',a)
s=s[:a]+'''    wire [15:0]lines_total;
    wire over_raw, batch_done, engine_quiescent;
    wire [4:0]batch_n;
    wire finish_pending, result_valid;
    wire [3:0]core_locked;
    wire phase_enter, charge_pulse;
    wire new_run = Idle || choose || (Finalize && switch_r_flag);
    assign mission_hold = finish_pending || result_valid;
    assign mission_win = result_valid && mission_success;
    assign over = result_valid && !mission_success && !Finalize;
    story_controller story_inst(
        .clk(Clk_74M),.reset_n(Reset_n),.new_run(new_run),
        .playing(Playing),.paused(Stop),.duo(duo),
        .row_credit(clear_t_t),.batch_done(batch_done),
        .engine_quiescent(engine_quiescent),.over_raw(over_raw),
        .lines_total(lines_total),.story_speed(speed_level),
        .story_phase(story_phase),.core_locked(core_locked),
        .phase_enter(phase_enter),.charge_pulse(charge_pulse),
        .finish_pending(finish_pending),.result_valid(result_valid),
        .result_success(mission_success)
    );

'''+s[b:]
s=replace(s,'    .lock_commit1(lock_commit1), .lock_commit2(lock_commit2),','''    .lock_commit1(lock_commit1), .lock_commit2(lock_commit2),
    .mission_hold(mission_hold), .story_speed(speed_level),
    .batch_done(batch_done), .batch_n(batch_n), .engine_quiescent(engine_quiescent),''')
s=replace(s,'    .over(over),','    .over(over_raw),')
s=replace(s,'    .speed_level(speed_level),\n    .land_we(land_we),','    .speed_level(),\n    .land_we(land_we),')
s=replace(s,'    timer timer_inst(','    timer timer_inst(')
# 仅对计时与计分实例增加独立接口，避免污染其他同名端口。
a=s.index('    timer timer_inst(');b=s.index('    wire score_lit;',a)
part=s[a:b].replace('.Stop(Stop),','.Stop(Stop || mission_hold),')
s=s[:a]+part+s[b:]
a=s.index('    scoring scoring_inst(');b=s.index('    wire next;',a)
part=s[a:b].replace('.clear_t_t(clear_t_t),','.clear_t_t(batch_done),').replace('.c_clear(c_clear),','.c_clear(batch_n),')
s=s[:a]+part+s[b:]
save('frame.v',s)

s=load('Tetris.v')
s=replace(s,'    wire over;','    wire over;\n    wire mission_win, mission_hold, mission_success;\n    wire [1:0]story_phase;')
s=replace(s,'    .over(over),\n\n    .sw_short','    .over(over | mission_win),\n\n    .sw_short')
s=replace(s,'    frame frame_inst(', '    frame frame_inst(') if '    frame frame_inst(' in s else s
s=replace(s,'    .danger_lvl(danger_lvl)\n    );','    .danger_lvl(danger_lvl),\n    .mission_win(mission_win), .mission_hold(mission_hold),\n    .story_phase(story_phase), .mission_success(mission_success)\n    );')
save('Tetris.v',s)

s=load('Game_state_machine.v')
s=replace(s,'''    Playing_en: if(hold_pulse)
                state <= Idle_en;
                else if(short_press)
                state <= Stop_en;
                else if(over)
                state <= Finalize_en;''','''    Playing_en: if(over)
                state <= Finalize_en;
                else if(hold_pulse)
                state <= Idle_en;
                else if(short_press)
                state <= Stop_en;''')
save('Game_state_machine.v',s)

s=load('timer.v')
s=replace(s,'    reg [26:0]counter;','    parameter SECOND_CYCLES = 74_218_750;\n    wire sec_tick = Playing && !Stop && !Finalize && (counter == SECOND_CYCLES-1);\n    reg [26:0]counter;')
s=s.replace('counter == 74_250_000 - 1','sec_tick')
# 计数器内部用周期条件，数字进位全部由真正运行时的 sec_tick 驱动。
s=replace(s,'    if(sec_tick)\n    counter <= 0;','    if(counter == SECOND_CYCLES-1)\n    counter <= 0;')
save('timer.v',s)

s=load('scoring.v')
a=s.index('        case(c_clear)');b=s.index('        endcase',a)+len('        endcase')
s=s[:a]+'''        counter <= counter + (({17'd0,speed_level}+20'd1)*SCORE_UNIT)*c_clear*c_clear;'''+s[b:]
save('scoring.v',s)

# 所有直接实例化 Playfield 的测试，明确给定任务速度/冻结，杜绝悬空输入。
for f in (ROOT/'sim').rglob('*_tb.v'):
    s=f.read_text(encoding='gbk')
    s,n=re.subn(r'(Playfield\s*(?:#\([\s\S]*?\)\s*)?\w+\s*\()',r'\1\n  .mission_hold(1\'b0), .story_speed(3\'d0),',s)
    if n: f.write_text(s,encoding='gbk',newline='\n')

# 引入 frame 新依赖，原测试仍使用真实模块，不绕开任务控制器。
for f in list((ROOT/'sim').rglob('*.bat'))+list((ROOT/'sim').rglob('*.ps1')):
    s=f.read_text(encoding='utf-8')
    def dep(m): return m[0]+' '+m[1]+'story_controller.v'
    t=re.sub(r'([^\s\x27\x22]*new[\\/])frame_background\.v',dep,s)
    if t!=s:f.write_text(t,encoding='utf-8',newline='\r\n' if f.suffix=='.bat' else '\n')
print('Round 1 sources written in GBK; tests now explicitly drive mission inputs.')
