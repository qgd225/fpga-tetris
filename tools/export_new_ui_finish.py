"""Export real RTL outputs without rescaling or repainting their pixels."""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];RUN=ROOT/'temporary/ui_polish_20261029/render';OUT=ROOT/'docs/参考图/预览图/RTL生成/20261029_导管背景与船板细化'
def main():
 log=(RUN/'render.log').read_text('utf-8',errors='replace');assert 'FINAL_UI_ALL_FRAMES_PASS' in log and 'FINAL_UI_FAIL' not in log
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'局部状态').mkdir(exist_ok=True)
 names={'duo_campaign':'双人闯关','solo_campaign':'单人闯关','duo_endless':'双人无尽','solo_endless':'单人无尽','main_menu':'主菜单','solo_select':'单人选关','duo_select':'双人选关'}
 parts={'core_locked':'核心_LOCKED六圈锁链','core_half':'核心_HALF','core_online7':'核心_ONLINE七段','core_success8':'核心_成功八段','pause':'暂停','result_success':'闯关成功结算','result_failure':'闯关失败结算','result_endless':'无尽结算'}
 parts.update({'duo_select_ship4':'双人选关_SHIP04','reserve_critical_on':'储备危急_亮','reserve_critical_off':'储备危急_暗','recharge_clipped':'回充截断_MAX','recharge_full':'已满_MAX'})
 parts.update({f'comms_{i}':f'对白_{i}' for i in range(7)})
 parts.update({'duo_comms':'双人右上角对白'})
 parts.update({'solo_locked_layout':'单人闯关_LOCKED布局'})
 parts.update({f'phase_{i}':f'阶段_{i+1}_向上箭头' for i in range(4)})
 parts.update({f'{mode}_select_ship{i}':f'{label}选关_SHIP0{i}' for mode,label in [('solo','单人'),('duo','双人')] for i in [1,3,4] if not (mode=='duo' and i==4)})
 records={}
 for group,folder in [(names,OUT),(parts,OUT/'局部状态')]:
  for key,label in group.items():
   im=Image.open(RUN/(key+'.ppm')).convert('RGB');dest=folder/f'20261029_{label}_RTL.png';im.save(dest)
   records[dest.relative_to(OUT).as_posix()]={'size':im.size,'rgb_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'png_sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
 # Review index: only index thumbnails are scaled; native scene files stay 1280x720.
 font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',20)
 sheet=Image.new('RGB',(1320,4*412),(9,16,24));draw=ImageDraw.Draw(sheet)
 for i,(key,label) in enumerate(names.items()):
  x=10+(i%2)*660;y=10+(i//2)*412;draw.text((x,y),label,font=font,fill='#c9e7ed')
  im=Image.open(RUN/(key+'.ppm')).convert('RGB');im.thumbnail((640,360),Image.Resampling.NEAREST);sheet.paste(im,(x,y+36))
 sheet.save(OUT/'00_七场景审核索引.png')
 manifest={'source':'真实RTL仿真输出；原尺寸PNG无重绘无后期改色','resolution':[1280,720],'images':records,'renderer_sha256':hashlib.sha256((ROOT/'Tetris.srcs/sources_1/new/reference_ui_renderer.v').read_bytes()).hexdigest()}
 manifest['hardware_sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'Tetris.srcs').rglob('*') if p.is_file() and p.suffix in {'.v','.sv','.vh','.mem','.xci','.xdc'}}
 (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
 (OUT/'README.md').write_text('# 新UI最终硬件实现审核图\n\n七种场景与核心、暂停、结算、七段对白共38帧，均来自当前RTL。原尺寸PNG未经重绘。像素指纹见manifest.json，完整源码及bit绑定见最终报告。\n\n核心原材质按新坐标平移比对，导管保持出口并延长横段，四行选关及完整飞船有独立检查；背景采用静态坐标流星及共享32×32六色小行星，船板补连续接缝与嵌入通风槽。画面、操作与声音效果仍待用户上板确认。\n','utf-8')
 print('FINAL_UI_EXPORTED',len(records),str(OUT))
if __name__=='__main__':main()
