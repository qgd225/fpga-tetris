"""Audit generated palette consumers without importing the PC application's runtime."""
import ast,json,re
from pathlib import Path
root=Path(__file__).resolve().parents[2]
src=root/'Tetris.srcs/sources_1/new'
data=json.loads((root/'assets/story_ui.json').read_text(encoding='utf-8'))
expected=[int(c,16) for c in data['palette_rgb']]
assert len(expected)==len(set(expected))==56
net=(src/'net_screen_tx.v').read_text(encoding='gbk')
entries={int(i):int(c.replace('_',''),16) for i,c in re.findall(r"[56]'d(\d+):\s+pal_rgb\s*=\s*24'h([0-9A-Fa-f_]+)",net)}
assert entries==dict(enumerate(expected))
mapper=(src/'rgb_to_palette.v').read_text(encoding='gbk')
bits=list(map(int,re.findall(r'rgb\[(\d+)\]',mapper)))
lookup={int(h,16):int(i) for h,i in re.findall(r"rom\[8'h([0-9A-F]+)\] = 6'd(\d+)",mapper)}
assert len(bits)==8 and len(lookup)==56
for i,c in enumerate(expected):
 h=sum(((c>>b)&1)<<(7-j) for j,b in enumerate(bits))
 assert lookup[h]==i
module=ast.parse((root/'tools/net_screen_view.py').read_text(encoding='utf-8'))
pc=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='DEFAULT_PAL' for t in n.targets))
assert pc=={i:(c>>16,c>>8&255,c&255) for i,c in enumerate(expected)}
luma=lambda c: .2126*(c>>16)+.7152*(c>>8&255)+.0722*(c&255)
assert luma(expected[16])>luma(expected[52])>luma(expected[22])>luma(expected[28])>luma(expected[29])
assert luma(expected[53])>luma(expected[47])>luma(expected[46])>luma(expected[44])
for i in range(1,8):assert luma(expected[i+7])>luma(expected[i])>luma(expected[i+29])
assert len((src/'story_font.mem').read_text().split())==2048
assert len((src/'story_sprites.mem').read_text().split())==4096
print('ALL PASS UI ASSETS colors=56 projection_bits=8 font_bytes=2048 sprite_pixels=4096')

# Independently relate fixed text lengths to actual request rectangles.
ui=(src/'story_ui.v').read_text(encoding='gbk')
regions=re.findall(r'if\(box\(x,y,(\d+),(\d+),(\d+),(\d+)\)\)begin text_valid=1;text_x=\d+;text_y=\d+;text_base=TXT_(\w+);text_style=(\d+);',ui)
for x,y,w,h,name,style in regions:
 style=int(style);n=len(data['texts'][name]);w=int(w);h=int(h)
 if name=='CORE' and int(y)==320:n=4
 stride,glyph_w,glyph_h={0:(8,8,12),1:(16,16,24),2:(24,16,24),3:(32,24,36),4:(10,8,12)}[style]
 assert w>=(n-1)*stride+glyph_w and h>=glyph_h,(name,w,h,n,style)
assert len(data['texts']['RETRY'])==21
assert 'box(x,y,556,544,168,12)' in ui
print('ALL PASS UI TEXT EXTENTS static_regions='+str(len(regions)))
