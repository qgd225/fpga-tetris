"""Publish only the fully bound routed candidate plus the matching tested PC executable."""
from pathlib import Path
import argparse,hashlib,json,re,shutil,datetime,subprocess,sys
ROOT=Path(__file__).resolve().parents[1];TASK=ROOT/'temporary/ui_polish_20261029';ROUTED=TASK/'routed';REPORT=ROOT/'docs/reports/ui_polish_20261029'
PREVIEW=ROOT/'docs/参考图/预览图/RTL生成/20261029_导管背景与船板细化'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text('utf-8'))
def same(mapping,base=ROOT):
 for n,d in mapping.items():assert sha(base/n)==d,('evidence input drift',n)
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--publish',action='store_true');a=parser.parse_args()
 subprocess.run([sys.executable,str(ROOT/'tools/story_build_manifest.py'),'verify',str(ROUTED/'source-manifest.json')],check=True,cwd=ROOT)
 functional=read(TASK/'functional_release/summary.json');assert functional['pass'] and functional['groups']==15
 same(functional['hardware_inputs']);same(functional['test_inputs'])
 components=read(TASK/'components/summary.json');assert components['pass'];same(components['source_sha256'],ROOT/'Tetris.srcs/sources_1/new');same(components.get('oracle_sha256',{}));same(components.get('extra_source_sha256',{}))
 voice=read(TASK/'voice_final/summary.json');assert voice['pass'];same(voice['source_sha256'],ROOT/'Tetris.srcs/sources_1/new')
 stream=read(TASK/'stream/final_summary.json');assert stream['pass'];same(stream['final_source_sha256'])
 preview=read(PREVIEW/'manifest.json');same(preview['hardware_sha256']);assert len(preview['images'])==38
 util=(ROUTED/'utilization.rpt').read_text('utf-8');gate=(ROUTED/'gate-summary.txt').read_text('ascii')
 lut=int(re.search(r'LUT=(\d+)',gate)[1]);bram=float(re.search(r'\|\s*Block RAM Tile\s*\|\s*([\d.]+)',util)[1]);assert lut<=20000 and bram<=50
 timing={k:float(v) for k,v in re.findall(r'(WNS|WHS|TNS|THS) ([-+\d.]+)',gate)}
 assert set(timing)=={'WNS','WHS','TNS','THS'} and timing['WNS']>=0 and timing['WHS']>=0 and timing['TNS']==timing['THS']==0
 candidate=ROUTED/'Tetris.bit';assert candidate.stat().st_size>2000000
 pc_task=ROOT/'temporary/pc_package_20261028_211859';pc=read(pc_task/'package-inputs.json');same(pc['source_inputs'],ROOT/'pc')
 exe=pc_task/'dist/TetrisPC.exe';assert sha(exe)==pc['exe_sha256']
 for n in ['exe_smoke.json','exe_loopback.json']:
  assert read(TASK/'stream'/n)['passed']
 result={'pass':True,'published':a.publish,'date':datetime.datetime.now().isoformat(),'bit_sha256':sha(candidate),'pc_exe_sha256':sha(exe),'LUT':lut,'free_LUT':20800-lut,'BRAM':bram,'timing_ns':timing,'functional_groups':15,'rtl_frames':38,'priority_cuts':['沿用外围简化；本轮补一道静态流星、两颗远景小行星及连续船板接缝与嵌入通风槽'],'dynamic_cuts':[],'protected':'重点模块与现有动态沿用；修复旧面板侵入玻璃接头和橙管的残片；补流星、小行星远景和连续船板细节','board_pending':['HDMI实际显示相位与布局','核心、导管、消行与HOLD的实机反馈','PC物理网口收流与遥控','实际音频试听'],'git_commit':False,'git_push':False}
 REPORT.mkdir(parents=True,exist_ok=True)
 iterations=[]
 for stage in ['whole_synth_before_tail','whole_synth_before_declaration_order','whole_synth']:
  source=TASK/stage/'utilization.rpt'
  if source.is_file():
   text=source.read_text('utf-8');stage_lut=int(re.search(r'\|\s*Slice LUTs\*?\s*\|\s*(\d+)',text)[1]);stage_bram=float(re.search(r'\|\s*Block RAM Tile\s*\|\s*([\d.]+)',text)[1])
   dest=REPORT/'阶段综合'/stage;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest/'utilization.rpt')
   iterations.append({'stage':stage,'LUT':stage_lut,'BRAM':stage_bram,'evidence_sha256':sha(source),'scope':'阶段综合测量，仅最终布线用于交付验收'})
 (REPORT/'resource-iterations.json').write_text(json.dumps(iterations,ensure_ascii=False,indent=2)+'\n','utf-8')
 for name in ['source-manifest.json','project-at-build.xpr','rules-at-build.md','utilization.rpt','hierarchy.rpt','timing.rpt','paths.rpt','route.rpt','drc.rpt','cdc.rpt','bus_skew.rpt','lutram_pins.rpt','gate-summary.txt']:shutil.copyfile(ROUTED/name,REPORT/name)
 for name,source in [('functional.json',TASK/'functional_release/summary.json'),('components.json',TASK/'components/summary.json'),('voice.json',TASK/'voice_final/summary.json'),('stream.json',TASK/'stream/final_summary.json'),('preview.json',PREVIEW/'manifest.json'),('pc-package.json',pc_task/'package-inputs.json')]:shutil.copyfile(source,REPORT/name)
 if a.publish:
  target=ROOT/'bit/Tetris.bit';old=sha(target)
  assert old in {read(TASK/'before.json')['bit_sha256'],sha(candidate)},'published bit changed outside this task'
  stamp=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
  if old!=sha(candidate):shutil.copyfile(target,target.with_name(f'Tetris_{stamp}_{old[:12]}.bit'))
  staged=target.with_suffix('.bit.new');shutil.copyfile(candidate,staged);staged.replace(target);assert sha(target)==result['bit_sha256']
  exe_target=ROOT/'TetrisPC.exe';archive=TASK/'delivered_previous';archive.mkdir(exist_ok=True)
  if sha(exe_target)!=sha(exe):
   shutil.copyfile(exe_target,archive/f'TetrisPC_{stamp}_{sha(exe_target)[:12]}.exe')
   staged=exe_target.with_suffix('.exe.new');shutil.copyfile(exe,staged);staged.replace(exe_target)
  assert sha(exe_target)==result['pc_exe_sha256']
 (REPORT/'release.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
 (REPORT/'README.md').write_text(f"# 新UI最终硬件交付\n\n整机LUT {lut}/20800，剩余{20800-lut}；BRAM {bram}/50。WNS {timing['WNS']:+.3f}ns，WHS {timing['WHS']:+.3f}ns，TNS/THS均为0。\n\n15组功能回归、字库/文字/材质/动态组件、声音全地址与完整PCM、四帧网口CRC及本机UDP还原通过。七场景与多状态共38帧真实RTL已导出，详见预览清单。\n\n本轮移除导管玻璃接头下方的旧面板残片，恢复等宽橙管、完整接箍与连续沟道；左侧星空补一道静态流星和两颗远景小行星，随后补下部船板连续接缝、固定件及嵌入式通风槽。重点模块、布局、五拍流水线及现有动态保持不变。没有新增整屏位图。未执行E1～E4动态裁减，保留在线呼吸、充能沿管推进、核心扫光、消行火花和真实加成跳字。核心和完整飞船保留原生尺寸；边框按本轮指令统一冷钢色相，保留明暗、磨损与高光，并透明合成外角，原参考素材不改写。\n\n语音ROM仅作无损物理打包，逐样本结果不变；音效事件与取消信号整体增加一拍只读快照，5万组序列与原仲裁器逐拍对照等价，不回写游戏。新网口RGB888游程最大1292字节，不受旧56色表限制；新版PC保留旧协议兼容。\n\nbit SHA256：`{result['bit_sha256']}`。PC EXE SHA256：`{result['pc_exe_sha256']}`。源码/资产/工程登记/脚本绑定见source-manifest.json。旧bit按发布规则保留；PC程序源码和EXE未改，复用同一版本及有效验证记录。\n\n待用户上板：HDMI实际相位与显示、动态反馈与交互、PC物理网口收流、声音试听。未提交Git、未推送。\n",'utf-8')
 print('FINAL_UI_RELEASE_PASS',json.dumps(result,ensure_ascii=True))
if __name__=='__main__':main()
