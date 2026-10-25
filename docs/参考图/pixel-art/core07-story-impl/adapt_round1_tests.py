from pathlib import Path
R=Path('D:/vivado_project/Tetris')
for rel in ['sim/frame_duo/frame_duo_tb.v','sim/level/net_level_tb.v']:
 p=R/rel;s=p.read_text(encoding='gbk')
 s=s.replace('dut.Playfield_inst.speed_level','dut.story_inst.story_speed')
 s=s.replace('initial begin\n','initial begin\n  // 视觉/数值单元测试隔离顶出；真实终局由 sim/story 联合验证。\n  force dut.over_raw=0;\n',1)
 if 'level/' in rel:
  s=s.replace('force dut.Playfield_inst.c_clear = k;','force dut.batch_n = k;\n  force dut.batch_speed = dut.story_inst.story_speed;')
  s=s.replace('force dut.Playfield_inst.clear_t_t', 'force dut.batch_commit')
  s=s.replace('release dut.Playfield_inst.clear_t_t','release dut.batch_commit')
  s=s.replace('release dut.Playfield_inst.c_clear;','release dut.batch_n; release dut.batch_speed;')
  # 在负边沿驱动事件，避免与同步计分采样竞争。
  s=s.replace('    @(posedge Clk_74M);\n    force dut.batch_commit','    @(negedge Clk_74M);\n    force dut.batch_commit')
  s=s.replace('    @(posedge Clk_74M);\n    release dut.batch_commit','    @(negedge Clk_74M);\n    release dut.batch_commit')
  a=s.index('  $display("=== 1)');b=s.index('  $display("=== 7)',a)
  s=s[:a]+'''  $display("=== batch scoring and mission-only speed ===");
  set_score(20'd0); rel_score;add_clear(1,1);chk("one line batch",score,2);
  set_score(20'd0); rel_score;add_clear(1,2);chk("two separate batches",score,4);
  set_score(20'd0); rel_score;add_clear(4,1);chk("four-line batch once",score,32);
  force dut.story_inst.story_speed=3'd3;
  set_score(20'd0);rel_score;add_clear(2,1);chk("captured batch multiplier",score,32);
  release dut.story_inst.story_speed;
  set_score(20'd999999);set_time(999);
  chk("time and score cannot override mission",speed_level,0);
  rel_score;rel_time;
  for(integer sp=0;sp<8;sp=sp+1)begin
    force dut.story_inst.story_speed=sp[2:0];repeat(4)@(negedge Clk_74M);
    case(sp)
      0:chk("Drop0",dut.Playfield_inst.Drop,(64'd74218749*80)/100);
      1:chk("Drop1",dut.Playfield_inst.Drop,(64'd74218749*71)/100);
      2:chk("Drop2",dut.Playfield_inst.Drop,(64'd74218749*63)/100);
      3:chk("Drop3",dut.Playfield_inst.Drop,(64'd74218749*55)/100);
      4:chk("Drop4",dut.Playfield_inst.Drop,(64'd74218749*46)/100);
      5:chk("Drop5",dut.Playfield_inst.Drop,(64'd74218749*38)/100);
      6:chk("Drop6",dut.Playfield_inst.Drop,(64'd74218749*30)/100);
      7:chk("Drop7",dut.Playfield_inst.Drop,(64'd74218749*21)/100);
    endcase
  end
  release dut.story_inst.story_speed;
  @(negedge Clk_74M);Stop=1;
  dut.timer_inst.counter=74218749;
  dut.timer_inst.counter0=0;dut.timer_inst.counter1=0;
  dut.timer_inst.counter2=0;dut.timer_inst.counter3=0;
  repeat(4)@(negedge Clk_74M);chk("pause at exact second does not carry",time_sec,0);
  Stop=0;@(negedge Clk_74M);chk("resume carries once",time_sec,1);
  repeat(4)@(negedge Clk_74M);chk("second boundary not repeated",time_sec,1);

'''+s[b:]
 p.write_text(s,encoding='gbk',newline='\n')
# 将新任务联合测试纳入总入口。
p=R/'sim/run_all.bat';s=p.read_text(encoding='utf-8')
s=s.replace('echo ===== SUMMARY =====','cmd /d /c call "%~dp0story\\run.bat" > "%~dp0logs\\story.log" 2>&1\necho ===== SUMMARY =====')
s=s.replace('optimization hdmi_audio) do','optimization hdmi_audio story) do')
p.write_text(s,encoding='utf-8',newline='\r\n')
print('Legacy expectations migrated; visual checks retained; story suite added to full runner.')
