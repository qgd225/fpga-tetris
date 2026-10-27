"""核对双人无尽 Sketch 的图层结构，并绘制辅助预览，不代表 Pixso 实际渲染。"""
import hashlib
import io
import json
from collections import Counter
from pathlib import Path
import zipfile

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/参考图/Sketch'
STEM = '20261027_双人无尽UI_v1'
SOURCE = OUT / f'{STEM}.sketch'
COUNTS = Counter()
IDS = set()
NAMES = []
TEXTS = {}
WARNINGS = []


def rgba(color):
    return tuple(round(color.get(k, default) * 255) for k, default in
                 [('red', 0), ('green', 0), ('blue', 0), ('alpha', 1)])


def visit(layer, draw, px=0, py=0, parent=None):
    kind = layer['_class']
    COUNTS[kind] += 1
    ident = layer['do_objectID']
    assert ident not in IDS, f'重复标识：{ident}'
    IDS.add(ident)
    NAMES.append(layer['name'])
    assert not layer.get('isLocked', False)
    f = layer['frame']
    assert all(isinstance(f[k], (int, float)) for k in ['x', 'y', 'width', 'height'])
    assert f['width'] > 0 and f['height'] > 0, layer['name']
    if parent:
        assert f['x'] >= 0 and f['y'] >= 0, layer['name']
        assert f['x'] + f['width'] <= parent['width'], f'横向越界：{layer["name"]}'
        assert f['y'] + f['height'] <= parent['height'], f'纵向越界：{layer["name"]}'
    x, y, w, h = px + f['x'], py + f['y'], f['width'], f['height']
    if kind == 'rectangle':
        fill = layer['style']['fills'][0]
        assert fill['isEnabled']
        draw.rectangle((x, y, x+w-1, y+h-1), fill=rgba(fill['color']))
    elif kind == 'text':
        string = layer['attributedString']['string']
        TEXTS[layer['name']] = string
        style = layer['style']['textStyle']['encodedAttributes']
        for item in layer['attributedString']['attributes']:
            for key in ['MSAttributedStringFontAttribute', 'MSAttributedStringColorAttribute']:
                assert item['attributes'][key] == style[key], layer['name']
        descriptor = style['MSAttributedStringFontAttribute']['attributes']
        assert descriptor['name'] == 'Consolas'
        font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', round(descriptor['size']))
        spacing = style.get('kerning', 0)
        length = draw.textlength(string, font=font) + max(0, len(string)-1)*spacing
        if length > w:
            WARNINGS.append(f'文字可能超出文本框：{layer["name"]}，文字宽 {length:.1f}，框宽 {w}')
        for char in string:
            draw.text((x, y), char, font=font, fill=rgba(style['MSAttributedStringColorAttribute']), anchor='lt')
            x += draw.textlength(char, font=font) + spacing
    else:
        assert kind in ('artboard', 'group'), kind
    for child in layer.get('layers', []):
        visit(child, draw, px+f['x'], py+f['y'], f)


with zipfile.ZipFile(SOURCE) as archive:
    assert archive.testzip() is None
    payloads = {n: archive.read(n) for n in archive.namelist() if not n.endswith('/')}
    # 严格解码所有 JSON，检查中文图层名没有编码损坏。
    for name, data in payloads.items():
        if name.endswith('.json'):
            json.loads(data.decode('utf-8'))
    document = json.loads(payloads['document.json'])
    meta = json.loads(payloads['meta.json'])
    assert len(document['pages']) == 1
    page = json.loads(payloads[document['pages'][0]['_ref'] + '.json'])
    assert page['do_objectID'] in meta['pagesAndArtboards']
    assert len(page['layers']) == 1
    board = page['layers'][0]
    assert (board['frame']['width'], board['frame']['height']) == (1280, 720)
    canvas = Image.new('RGBA', (1280, 720), rgba(board['backgroundColor']))
    visit(board, ImageDraw.Draw(canvas))
    assert COUNTS['bitmap'] == 0, '设计内容不应被栅格化'
    assert 'P1 NEXT' in NAMES and 'P2 NEXT' in NAMES
    assert '网格 24列×20行' in NAMES and sum(n.startswith('格点 ') for n in NAMES) == 480
    assert sum(n.startswith('速度第') for n in NAMES) == 8
    assert sum(n.startswith('存入条件 ') for n in NAMES) == 3
    assert TEXTS['模式标题'] == 'DUO ENDLESS'
    assert TEXTS['储备标签'] == 'RESERVE'
    assert 'HINT' not in TEXTS.values()
    seconds = sum(int(t)*m for t, m in zip(TEXTS['时间数值'].split(':'), (60, 1)))
    assert TEXTS['速度数值'] == f'{min(7, seconds//45)+1}/8'
    field = next(n for n in board['layers'] if n['name'].startswith('07 '))
    pile = next(n for n in field['layers'] if n['name'] == '已落定方块')
    occupied = {(n['frame']['x']//24, n['frame']['y']//24) for n in pile['layers']}
    for ghost in (n for n in field['layers'] if '幽灵落点' in n['name']):
        cells = {((ghost['frame']['x']-8+n['frame']['x'])//24,
                  (ghost['frame']['y']-8+n['frame']['y'])//24) for n in ghost['layers']}
        assert not cells & occupied, f'幽灵与落定块重叠：{ghost["name"]}'
        assert any((x, y+1) in occupied or y+1 == 20 for x, y in cells), f'幽灵未落到底：{ghost["name"]}'
    assert not WARNINGS, '\n'.join(WARNINGS)

preview = canvas.convert('RGB')
preview.save(OUT / f'{STEM}_辅助预览.png')
buffer = io.BytesIO()
preview.save(buffer, format='PNG')
payloads['previews/preview.png'] = buffer.getvalue()
scratch = ROOT / 'temporary/sketch-duo-endless/verified.sketch'
with zipfile.ZipFile(scratch, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name, data in payloads.items():
        archive.writestr(name, data)
SOURCE.write_bytes(scratch.read_bytes())
scratch.unlink()
report = {
    '文件': str(SOURCE), 'SHA256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    '画布': [1280, 720], '图层统计': dict(COUNTS), '全部未锁定': True,
    '检查': 'ZIP/UTF-8/页面引用/图层唯一性/图层边界/字体样式一致性/文字宽度/双NEXT/480格点/8段速度/3格HOLD/无HINT/TIME与SPD一致/幽灵落点：通过',
    '视觉来源': '现行总览风格与 story_layout.vh 布局；设计稿，不是 RTL 截图。',
    '预览': '由 Sketch 内的图层数据辅助绘制，不代表 Pixso 或 Sketch 的实际渲染。',
    'Pixso导入验证': '待用户手动导入检查。',
    'Git提交': False, 'GitHub推送': False,
}
(OUT / f'{STEM}_检查.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
