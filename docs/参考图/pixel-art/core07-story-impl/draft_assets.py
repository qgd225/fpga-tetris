"""准备小型图块和字模；本脚本不修改正在构建的 FPGA 源码。"""
from pathlib import Path
import sys, ast, json
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, 'C:/Users/qiguidie/.codex/skills/pixel-art-studio/scripts')
from pixelstudio import Sprite
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
OUT=HERE/'draft_assets';OUT.mkdir(exist_ok=True)
prior=HERE.parent/'core07-rescue-v5/build.py'
module=ast.parse(prior.read_text(encoding='utf-8'))
glyph_expr=next(n.value for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='GLYPHS' for t in n.targets))
# 旧字模只包含常量列表、乘法，限制在空内置环境读取。
glyphs=eval(compile(ast.Expression(glyph_expr),str(prior),'eval'),{'__builtins__':{}})
glyphs['!']=['00100']*5+['00000','00100']
glyphs['?']=['01110','10001','00001','00010','00100','00000','00100']
chars=' ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-:/.!?'
rows=[None,0,1,1,2,3,4,4,5,5,6,None]
font=[0]*1024
for c,ch in enumerate(chars):
 for y,r in enumerate(rows):
  if r is not None:font[c*16+y]=int('0'+glyphs[ch][r]+'00',2)
font_preview=Image.new('RGB',(512,132),'#081018');draw=ImageDraw.Draw(font_preview)
for c,ch in enumerate(chars):
 ox=(c%16)*32;oy=(c//16)*44
 for y in range(12):
  for x in range(8):
   if font[c*16+y]&(1<<(7-x)):draw.rectangle((ox+x*3,oy+y*3,ox+x*3+2,oy+y*3+2),fill='#D8D8D8')
font_preview.save(OUT/'font.png')
colors=['#29404D','#536A76','#909090']
planet=Sprite(64,32,palette=colors)
planet.polygon([(3,23),(10,19),(25,13),(44,7),(58,5),(62,7),(61,9),(49,15),(27,23),(8,27),(3,26)],colors[0])
planet.polygon([(27,7),(33,5),(40,6),(45,10),(46,18),(43,24),(37,27),(29,26),(24,22),(23,14)],colors[1])
planet.polygon([(27,7),(33,5),(34,9),(30,15),(29,23),(31,26),(29,26),(24,22),(23,14)],colors[0])
planet.line(5,25,61,7,colors[2]);planet.line(6,26,60,9,colors[1])
planet.save_png(str(OUT/'planet_1x.png'))
planet.preview(str(OUT/'planet_preview.png'),scale=6,labels=False)

planet_colors=colors[:]
colors=['#29404D','#B0B0B0','#D8D8D8']
hand=Sprite(64,32,palette=colors)
hand.polygon([(0,31),(8,17),(28,4),(42,3),(62,15),(63,31)],colors[0])
hand.polygon([(7,31),(12,19),(30,7),(41,7),(56,17),(58,31)],colors[1])
hand.polygon([(13,18),(24,10),(30,14),(19,23)],colors[2])
hand.polygon([(18,24),(27,18),(33,23),(24,31),(18,31)],colors[2])
hand.polygon([(28,8),(32,5),(40,5),(46,9),(43,13),(36,9)],colors[2])
hand.line(40,15,53,22,colors[0]);hand.line(38,19,51,26,colors[0])
hand.save_png(str(OUT/'hand_1x.png'));hand.preview(str(OUT/'hand_preview.png'),scale=6,labels=False)
hand.save_silhouette(str(OUT/'hand_silhouette.png'))
atlas=[]
for sprite,pal in [(planet,planet_colors),(hand,colors)]:
 for y in range(32):
  for x in range(64):
   rgb=sprite.get(x,y)
   atlas.append(0 if rgb is None else pal.index('#%02X%02X%02X'%rgb[:3])+1)
assert max(atlas)<=3 and len(atlas)==4096
(OUT/'assets.json').write_text(json.dumps({'chars':chars,'glyphs':glyphs,'font':font,'sprites':atlas},ensure_ascii=False),encoding='utf-8')
print('Font bytes:',len(font),'Sprite bits:',len(atlas)*2)
print('Planet:',planet.stats(print_=False))
print('Hand:',hand.stats(print_=False))
