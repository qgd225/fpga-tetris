from pathlib import Path
R=Path('D:/vivado_project/Tetris');P=R/'Tetris.srcs/sources_1/new'
p=P/'timer.v';s=p.read_text(encoding='gbk');s=s.replace('    wire sec_tick = Playing && !Stop && !Finalize && (counter == SECOND_CYCLES-1);\n    reg [26:0]counter;','    reg [26:0]counter;\n    wire sec_tick = Playing && !Stop && !Finalize && (counter == SECOND_CYCLES-1);');p.write_text(s,encoding='gbk',newline='\n')
p=R/'sim/duo/duo_tb.v';s=p.read_text(encoding='gbk')
s=s.replace('module duo_tb;','module duo_tb;\nreg [2:0] test_story_speed=0;')
s=s.replace(".story_speed(3'd0)",'.story_speed(test_story_speed)')
a=s.index("  time_sec = 14'd39;");b=s.index('\n  $display(',a)
s=s[:a]+'''  time_sec=14'd1200; score=20'd99999;
  repeat(4) @(posedge Clk_74M); chk("time and score cannot accelerate",speed_level,0);
  for(integer sp=0;sp<8;sp=sp+1)begin
    test_story_speed=sp; repeat(4) @(posedge Clk_74M);
    chk("mission speed forwarded",speed_level,sp);
  end
  test_story_speed=0; time_sec=0; score=0;
'''+s[b:]
# 同一旧章节剩下的单人时间等级断言改成任务速度独立性检查。
s=s.replace('chk("solo 20s", speed_level, 1)','chk("solo time does not accelerate", speed_level, 0)')
s=s.replace('chk("solo 60s", speed_level, 2)','chk("solo time does not accelerate", speed_level, 0)')
s=s.replace('chk("solo 600s", speed_level, 7)','chk("solo time does not accelerate", speed_level, 0)')
p.write_text(s,encoding='gbk',newline='\n')

dest=R/'sim/story';dest.mkdir(exist_ok=True)
tb=r'''// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module Tetromino(input clka,input [4:0]addra,output [31:0]douta);
 assign douta=32'h00102030;
endmodule
module weiyibiao(input clka,input [4:0]addra,output [7:0]douta);
 assign douta=0;
endmodule
module number(input clka,input ena,input [9:0]addra,output [19:0]douta);
 assign douta=0;
endmodule
module story_tb;
 reg clk=0,rst=0,restart=1,playing=1,paused=0,duo=0,manual=1;
 reg unit_credit=0,unit_done=0,unit_quiet=1,unit_over=0;
 reg pf_idle=1,left=0,right=0,rot=0,drop=0,hold=0;
 wire pf_credit,pf_done,pf_quiet,pf_over,pf_clear_time;
 wire [4:0]pf_n;wire [2:0]pf_speed;
 wire [479:0]board;
 wire [15:0]lines;
 wire [2:0]speed;
 wire [1:0]phase;
 wire [3:0]locked;
 wire phase_enter,charge,commit,finish_pending,valid,success;
 wire frozen=finish_pending||valid;
 wire credit=manual?unit_credit:pf_credit;
 wire done=manual?unit_done:pf_done;
 wire quiet=manual?unit_quiet:pf_quiet;
 wire over=manual?unit_over:pf_over;
 wire [19:0]score;
 wire [23:0]bcd;
 reg [4:0]score_n=1;
 reg [2:0]score_speed=0;
 integer bad=0,checks=0,k,j,timeout,prev_speed;
 reg [4:0]wr_row;
 reg [23:0]wr_data;
 reg wr_en=0;
 reg [479:0]snapshot;
 integer saved_lines,saved_counter;
 always #5 clk=~clk;
 story_controller controller(.clk(clk),.reset_n(rst),.new_run(restart),
  .playing(playing),.paused(paused),.duo(duo),.row_credit(credit),
  .batch_done(done),.engine_quiescent(quiet),.over_raw(over),
  .lines_total(lines),.story_speed(speed),.story_phase(phase),.core_locked(locked),
  .phase_enter(phase_enter),.charge_pulse(charge),.batch_commit(commit),
  .finish_pending(finish_pending),.result_valid(valid),.result_success(success));
 Playfield #(.CLEAR_STEP(3),.MCNT_LAND(10000000),.MCNT_Drop(10000000)) pf(
  .Clk_74M(clk),.Reset_n(rst),.hcounter(0),.vcounter(0),
  .left_p_flag(left),.right_p_flag(right),.rotate_p_flag(rot),
  .drop_r_flag(drop),.drop_en(drop),.hold_p_flag(hold),.switch_r_flag(0),
  .Idle(pf_idle),.Playing(playing),.Stop(paused),.Finalize(valid),
  .mission_hold(frozen),.story_speed(speed),.hint_enable(0),.score(0),.time_sec(0),
  .duo(duo),.left_p_flag2(left),.right_p_flag2(right),.rotate_p_flag2(rot),
  .drop_r_flag2(drop),.drop_en2(drop),.hold_p_flag2(hold),
  .state(board),.clear_t_t(pf_credit),.batch_done(pf_done),.batch_n(pf_n),
  .batch_speed(pf_speed),.engine_quiescent(pf_quiet),.over(pf_over),
  .clear_time(pf_clear_time));
 scoring score_unit(.Clk_74M(clk),.Reset_n(rst),.hcounter(0),.vcounter(0),
  .Idle(restart),.Playing(playing),.Stop(paused),.Finalize(0),.switch_r_flag(0),
  .clear_t_t(commit),.c_clear(manual?score_n:pf_n),
  .speed_level(manual?score_speed:pf_speed),.duo(duo),.counter(score),.bcd(bcd));
 task tick;begin @(posedge clk);#1;end endtask
 task check;input [8*80-1:0]label;input integer got,expected;
 begin checks=checks+1;if(got!==expected)begin bad=bad+1;
  $display("FAIL %0s got=%0d expected=%0d",label,got,expected);end end endtask
 task fresh;input mode;
 begin
  @(negedge clk);restart=1;duo=mode;paused=0;unit_over=0;unit_credit=0;
  unit_done=0;unit_quiet=1;left=0;right=0;rot=0;drop=0;hold=0;pf_idle=1;
  repeat(25)tick;
  @(negedge clk);restart=0;if(!manual)pf_idle=0;
  tick;check("reset progress",lines,0);check("reset result",valid,0);
 end endtask
 function integer expected_speed;input integer n;input mode;
 begin
  if(mode) expected_speed=n>=35?7:n>=30?6:n>=23?5:n>=16?4:n>=11?3:n>=6?2:n>=3?1:0;
  else expected_speed=n>=28?7:n>=24?6:n>=18?5:n>=12?4:n>=8?3:n>=4?2:n>=2?1:0;
 end endfunction
 task credit_batch;input integer n;
 begin
  score_n=n;score_speed=speed;
  for(j=0;j<n;j=j+1)begin
   @(negedge clk);unit_credit=1;tick;@(negedge clk);unit_credit=0;tick;
  end
  @(negedge clk);unit_done=1;tick;@(negedge clk);unit_done=0;repeat(2)tick;
 end endtask
 task rows;input integer count;
 begin
  @(negedge clk);
  force pf.board_busy=1;
  force pf.row_we=wr_en;force pf.row_addr=wr_row;force pf.row_data=wr_data;
  for(j=0;j<count;j=j+1)begin
   wr_en=1;wr_row=19-j;wr_data=duo?24'hffffff:24'h0fffff;
   tick;@(negedge clk);
  end
  wr_en=0;release pf.row_we;release pf.row_addr;release pf.row_data;
  release pf.board_busy;tick;
 end endtask
 task wait_batch;
 begin
  timeout=0;
  while(!pf_done && timeout<4000)begin tick;timeout=timeout+1;end
  check("batch finishes without deadlock",timeout<4000,1);
  repeat(4)tick;
 end endtask
 initial begin
  #2;rst=0;#13;rst=1;
  for(k=0;k<2;k=k+1)begin
   manual=1;fresh(k);
   for(integer line=1;line<=(k?40:32);line=line+1)begin
    credit_batch(1);
    check("exact mission credit",lines,line);
    check("exact speed threshold",speed,expected_speed(line,k));
    check("phase is speed pair",phase,expected_speed(line,k)/2);
    check("finish only at target",valid,line==(k?40:32));
   end
   check("eight core units on success",locked,8);
   check("success flag",success,1);
  end
  fresh(0);credit_batch(20);credit_batch(11);
  check("one line before success",lines,31);
  @(negedge clk);unit_credit=1;paused=1;tick;
  @(negedge clk);unit_credit=0;repeat(4)tick;
  check("pause defers in-flight credit",lines,31);
  @(negedge clk);paused=0;tick;
  check("resume applies in-flight credit once",lines,32);
  check("success freezes before compaction ends",finish_pending,1);
  @(negedge clk);unit_done=1;unit_quiet=0;unit_over=1;tick;
  @(negedge clk);unit_done=0;repeat(3)tick;
  check("success waits for accepted writes",valid,0);
  @(negedge clk);unit_quiet=1;tick;
  check("committed success beats late top alarm",success,1);
  fresh(0);@(negedge clk);unit_over=1;tick;
  check("real failure retained",valid,1);check("failure not success",success,0);
  fresh(1);credit_batch(20);credit_batch(20);
  check("large cross-threshold batch retained",lines,40);
  check("duo large batch success",success,1);
  manual=0;fresh(0);rows(8);
  timeout=0;while(lines<3 && timeout<400)begin tick;timeout=timeout+1;end
  @(negedge clk);paused=1;tick;saved_lines=lines;saved_counter=pf.clear_cnt;
  repeat(20)tick;
  check("real clear pauses without progress",lines,saved_lines);
  check("real clear timer freezes",pf.clear_cnt,saved_counter);
  @(negedge clk);paused=0;wait_batch;
  check("eight-row batch credits exactly eight",lines,8);
  check("eight-row batch score once",score,128);
  rows(20);wait_batch;
  check("twenty-row batch no counter wrap",lines,28);
  check("twenty-row batch captured old speed",score,3328);
  rows(4);wait_batch;
  check("real solo succeeds at32",success,1);
  check("real solo final score",score,3584);
  snapshot=board;@(negedge clk);left=1;right=1;rot=1;drop=1;hold=1;
  repeat(50)tick;
  check("success rejects new board writes",board===snapshot,1);
  check("success retains progress",lines,32);
  fresh(1);rows(20);wait_batch;rows(20);wait_batch;
  check("real duo succeeds at40",success,1);
  fresh(0);rows(4);repeat(8)tick;
  @(negedge clk);restart=1;pf_idle=1;repeat(30)tick;
  @(negedge clk);restart=0;pf_idle=0;repeat(100)tick;
  check("restart cancels pending old clear credits",lines,0);
  check("restart clears old board",board==0,1);
  if(bad==0)$display("ALL PASS STORY: %0d checks",checks);
  else $display("FAILED STORY: %0d / %0d",bad,checks);
  $finish;
 end
 initial begin #2000000;$display("FAILED STORY TIMEOUT");$finish;end
endmodule
'''
(dest/'story_tb.v').write_text(tb,encoding='gbk',newline='\n')
rtl=['story_controller','Playfield','Playfield_pixel_mapper','Playfield_speed_control','Playfield_hold_controller','Playfield_ghost_scanner','solo_hint','scoring']
bat='''@echo off
call "D:\\xilinx\\Vivado\\2018.3\\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\\story_tb.v '''+' '.join('..\\..\\..\\Tetris.srcs\\sources_1\\new\\'+n+'.v' for n in rtl)+''' --nolog
if errorlevel 1 exit /b 1
call xelab.bat story_tb -s story --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat story -runall --nolog
'''
(dest/'run.bat').write_text(bat,encoding='utf-8',newline='\r\n')
print('Story controller and real Playfield integration regression written.')
