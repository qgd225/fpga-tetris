"""检查 Sketch 小样结构，并按图层数据生成辅助预览（不是 Pixso 截图）。"""
import hashlib
import io
import json
from collections import Counter
from pathlib import Path
import zipfile

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'docs/设计文件/Sketch编辑小样'
SOURCE = OUTPUT / '可编辑界面小样.sketch'
COUNTS = Counter()
IDS = set()
WARNINGS = []


def rgba(color):
    return tuple(round(color.get(k, default) * 255) for k, default in
                 [('red', 0), ('green', 0), ('blue', 0), ('alpha', 1)])


def visit(layer, archive, draw, canvas, parent_x=0, parent_y=0, parent_frame=None):
    kind = layer['_class']
    COUNTS[kind] += 1
    ident = layer['do_objectID']
    assert ident not in IDS, f'重复图层标识：{ident}'
    IDS.add(ident)
    assert not layer.get('isLocked', False), layer['name']
    frame = layer['frame']
    assert all(isinstance(frame[k], (int, float)) for k in ['x', 'y', 'width', 'height'])
    assert frame['width'] > 0 and frame['height'] > 0, layer['name']
    if parent_frame:
        assert frame['x'] >= 0 and frame['y'] >= 0, layer['name']
        assert frame['x'] + frame['width'] <= parent_frame['width'], layer['name']
        assert frame['y'] + frame['height'] <= parent_frame['height'], layer['name']
    x, y = parent_x + frame['x'], parent_y + frame['y']
    w, h = frame['width'], frame['height']
    if kind == 'rectangle':
        fills = layer['style']['fills']
        assert fills and fills[0]['isEnabled'], layer['name']
        radius = layer.get('points', [{}])[0].get('cornerRadius', 0)
        draw.rounded_rectangle((x, y, x + w - 1, y + h - 1), radius=radius, fill=rgba(fills[0]['color']))
    elif kind == 'text':
        content = layer['attributedString']['string']
        assert content, layer['name']
        attributes = layer['attributedString']['attributes']
        assert sum(item['length'] for item in attributes) == len(content.encode('utf-16-le')) // 2
        style = layer['style']['textStyle']['encodedAttributes']
        for item in attributes:
            for key in ['MSAttributedStringFontAttribute', 'MSAttributedStringColorAttribute']:
                assert item['attributes'][key] == style[key], f'文字样式不一致：{layer["name"]}'
        font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', round(style['MSAttributedStringFontAttribute']['attributes']['size']))
        if draw.textlength(content, font=font) > w:
            WARNINGS.append(f'文字宽度可能超出文本框：{layer["name"]}')
        draw.text((x, y), content, font=font, fill=rgba(style['MSAttributedStringColorAttribute']), anchor='lt')
    elif kind == 'bitmap':
        ref = layer['image']['_ref']
        assert ref in archive.namelist(), ref
        image = Image.open(io.BytesIO(archive.read(ref))).convert('RGBA').resize((round(w), round(h)))
        canvas.alpha_composite(image, (round(x), round(y)))
    for child in layer.get('layers', []):
        visit(child, archive, draw, canvas, x, y, frame)


with zipfile.ZipFile(SOURCE) as archive:
    assert archive.testzip() is None
    document = json.loads(archive.read('document.json'))
    meta = json.loads(archive.read('meta.json'))
    assert len(document['pages']) == 1
    page_ref = document['pages'][0]['_ref'] + '.json'
    page = json.loads(archive.read(page_ref))
    assert page['do_objectID'] in meta['pagesAndArtboards']
    assert len(page['layers']) == 1
    board = page['layers'][0]
    canvas = Image.new('RGBA', (1280, 860), rgba(board['backgroundColor']))
    visit(board, archive, ImageDraw.Draw(canvas), canvas)
    assert COUNTS['text'] >= 10 and COUNTS['rectangle'] >= 10 and COUNTS['bitmap'] == 1
    canvas.convert('RGB').save(OUTPUT / '辅助预览.png')

report = {
    '文件': str(SOURCE),
    'SHA256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    '文件字节数': SOURCE.stat().st_size,
    '结构检查': '通过：ZIP 完整性、页面引用、唯一图层标识、独立文字、图片引用、未锁定状态和边界',
    '图层统计': dict(COUNTS),
    '提示': WARNINGS,
    '预览说明': '按 Sketch 图层数据辅助绘制，非 Sketch 或 Pixso 的实际渲染截图。',
    'Pixso导入验证': '待用户手动导入；尚未验证字体替换、圆角和文字排版兼容性。',
    'Git提交': False,
    'GitHub推送': False,
}
(OUTPUT / '结构检查.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
