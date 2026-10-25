"""CORE-07 original block studies. Regenerate artwork; never edit exports."""
from pathlib import Path
import json
import sys
from contextlib import redirect_stdout
from io import StringIO

sys.stdout.reconfigure(encoding='utf-8')

sys.path.insert(0, str(Path.home() / '.codex/skills/pixel-art-studio/scripts'))
from pixelstudio import Sprite, mix
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'out'
OUT.mkdir(parents=True, exist_ok=True)
BASE = ['#59d7ff', '#ad8bfa', '#ffda70', '#ff809c', '#7ce0b8', '#ffb078', '#729eff']
INK = '#34466a'
WHITE = '#fff8ee'
SHADOW_TARGET = '#655991'
BG = '#293c65'


def tile(style, index):
    base = BASE[index]
    light = mix(base, WHITE, .50)
    shadow = mix(base, SHADOW_TARGET, .27)
    s = Sprite(24, 24, palette=[INK, WHITE, base, light, shadow])
    if style == 'A':
        # Soft rounded energy candy, without a grey casing or recessed center.
        s.polygon([(4,1),(19,1),(22,4),(22,19),(19,22),(4,22),(1,19),(1,4)], INK)
        s.polygon([(4,2),(19,2),(21,4),(21,19),(19,21),(4,21),(2,19),(2,4)], base)
        s.polygon([(2,16),(8,17),(16,16),(21,14),(21,19),(19,21),(4,21),(2,19)], shadow)
        s.polygon([(5,3),(17,3),(14,6),(5,6),(3,8),(3,5)], light)
        s.rect(6,3,11,4,WHITE)
    elif style == 'B':
        # Broad crystalline cel facets, no concentric borders.
        s.polygon([(4,1),(19,1),(22,4),(22,19),(19,22),(4,22),(1,19),(1,4)], INK)
        s.polygon([(4,2),(19,2),(21,4),(21,19),(19,21),(4,21),(2,19),(2,4)], base)
        s.polygon([(4,2),(19,2),(16,7),(7,7),(2,12),(2,4)], light)
        s.polygon([(17,14),(21,7),(21,19),(19,21),(4,21),(8,17)], shadow)
        s.line(6,3,12,3,WHITE)
    else:
        # Minimal animation-cel tile: broad body, one directional shade, short shine.
        s.polygon([(3,1),(20,1),(22,3),(22,20),(20,22),(3,22),(1,20),(1,3)], INK)
        s.polygon([(3,2),(20,2),(21,3),(21,20),(20,21),(3,21),(2,20),(2,3)], base)
        s.polygon([(2,18),(16,18),(21,15),(21,20),(20,21),(3,21),(2,20)], shadow)
        s.rect(5,4,12,5,light)
    return s


def font(size, bold=False):
    name = 'seguisb.ttf' if bold else 'segoeui.ttf'
    return ImageFont.truetype(str(Path('C:/Windows/Fonts')/name), size)


def build():
    sprites = {}
    report = {}
    for style in 'ABC':
        atlas = Image.new('RGBA', (24*7,24))
        for i in range(7):
            s = tile(style, i)
            p = OUT / f'block_{style}_{i}.png'
            with redirect_stdout(StringIO()):
                s.save_png(str(p))
            atlas.alpha_composite(Image.open(p).convert('RGBA'), (i*24,0))
            sprites[style,i] = Image.open(p).convert('RGBA')
        atlas.save(OUT / f'blocks_{style}_1x.png')
        atlas.resize((672,96),Image.Resampling.NEAREST).save(OUT / f'blocks_{style}_4x.png')
        pixels = list(atlas.get_flattened_data())
        colors = {p for p in pixels if p[3]}
        assert len(colors) <= 24, (style,len(colors))
        assert all(p[3] in (0,255) for p in pixels)
        report[style] = {'size':[24,24], 'colors':len(colors), 'semi_alpha':0}

    sheet = Image.new('RGB',(1280,900),'#eef5ff')
    d = ImageDraw.Draw(sheet)
    d.text((40,23),'CORE-07 / BLOCK STYLE STUDIES',font=font(28,True),fill=INK)
    d.text((40,66),'Original 24px artwork / 4x nearest-neighbor preview / No metal casing',font=font(18),fill='#637493')
    names = {'A':'A / SOFT GLOW','B':'B / CRYSTAL CUT','C':'C / CEL SHADE'}
    shapes = [(0,0,0),(1,0,0),(2,0,0),(1,1,0),(4,0,2),(5,0,2),(4,1,2),(5,1,2),(7,0,4),(8,0,4),(6,1,4),(7,1,4)]
    for row,style in enumerate('ABC'):
        top = 118+row*254
        d.rounded_rectangle((24,top,1256,top+234),radius=15,fill='#ffffff')
        d.text((44,top+14),names[style],font=font(22,True),fill=INK)
        d.rounded_rectangle((40,top+56,744,top+182),radius=8,fill=BG)
        for i in range(7):
            sheet.paste(sprites[style,i].resize((96,96),Image.Resampling.NEAREST),(56+i*96,top+70),sprites[style,i].resize((96,96),Image.Resampling.NEAREST))
        d.text((44,top+193),'Seven stable colors. One light direction. Clear joins when stacked.',font=font(15),fill='#637493')
        d.rounded_rectangle((782,top+55,1234,top+215),radius=8,fill=BG)
        for x,y,i in shapes:
            im=sprites[style,i].resize((48,48),Image.Resampling.NEAREST)
            sheet.paste(im,(794+x*48,top+86+y*48),im)
    sheet.save(OUT/'block_styles.png')
    (OUT/'palette_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':
    build()
