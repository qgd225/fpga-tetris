const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const JSZip = require('jszip');
const root = path.resolve(__dirname, '../..');
const scratch = path.join(root, 'temporary/sketch-editable');
fs.mkdirSync(scratch, { recursive: true });
// 生成库会清理该目录；只将本任务专用的缓存交给它。
process.env.STORAGE_DIR = path.join(scratch, `cache-${process.pid}`);
const { Sketch, Page, Artboard, Group, Rectangle, Text, TextStyle, Bitmap } = require('sketch-constructor');
const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'sample.json'), 'utf8'));
const out = process.argv[2] ? path.resolve(process.argv[2]) : path.join(root, 'docs/设计文件/Sketch编辑小样/可编辑界面小样.sketch');

function rectangle(name, x, y, width, height, color, radius = 0) {
  return new Rectangle({ name, x, y, width, height, cornerRadius: radius,
    style: { fills: [{ color }] } });
}
function text(name, string, x, y, width, height, size = 16, color = '#192138') {
  const layer = new Text({ name, string, fontName: config.font, fontSize: size, color,
    textBehaviour: 'fixed', frame: { x, y, width, height } });
  // 上游会重复构造文字样式；显式同步图层样式和字符样式，避免字号与颜色不一致。
  layer.style.textStyle = new TextStyle({ fontName: config.font, fontSize: size, color });
  return layer;
}
function group(name, x, y, width, height, layers) {
  return new Group({ name, frame: { x, y, width, height }, layers });
}
function button(name, label, x, y, width, fill, color) {
  return group(name, x, y, width, 48, [
    rectangle('按钮背景', 0, 0, width, 48, fill, 10),
    text('按钮文字', label, 20, 12, width - 40, 28, 16, color)
  ]);
}
// 本地生成简单的色块示意素材，不依赖外部图片服务。
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const b of bytes) {
    crc ^= b;
    for (let i = 0; i < 8; i++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function pngChunk(type, data) {
  const kind = Buffer.from(type);
  const size = Buffer.alloc(4); size.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([kind, data])));
  return Buffer.concat([size, kind, data, crc]);
}
function makeImage(file) {
  const width = 360, height = 160;
  const pixels = Buffer.alloc((width * 3 + 1) * height);
  const palette = [[32, 83, 79], [74, 140, 124], [161, 203, 177], [237, 218, 153]];
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const color = palette[(Math.floor(x / 60) + Math.floor(y / 40)) % palette.length];
    const i = y * (width * 3 + 1) + 1 + x * 3;
    pixels[i] = color[0]; pixels[i + 1] = color[1]; pixels[i + 2] = color[2];
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0); header.writeUInt32BE(height, 4); header[8] = 8; header[9] = 2;
  fs.writeFileSync(file, Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),
    pngChunk('IHDR', header), pngChunk('IDAT', zlib.deflateSync(pixels)), pngChunk('IEND', Buffer.alloc(0))]));
}
async function main() {
  fs.mkdirSync(path.dirname(out), { recursive: true });
  const image = path.join(scratch, '素材示意.png');
  makeImage(image);
  const board = new Artboard({ name: '01 可编辑界面小样', frame: { x: 0, y: 0, width: 1280, height: 860 }, backgroundColor: '#F4F6FA' });
  board.addLayer(group('顶部导航', 0, 0, 1280, 80, [
    rectangle('导航背景', 0, 0, 1280, 80, '#FFFFFF'),
    rectangle('标志色块', 40, 25, 30, 30, config.accent, 8),
    text('品牌名称', '设计空间', 84, 24, 180, 32, 22),
    text('当前页面', '工作台', 1000, 29, 100, 26, 16, config.accent),
    text('账户入口', '我的账户', 1130, 29, 100, 26, 16, '#687189')
  ]));
  board.addLayer(group('页面标题与操作', 64, 122, 1152, 114, [
    text('页面标题', config.title, 0, 0, 720, 52, 36),
    text('页面说明', config.subtitle, 0, 66, 850, 30, 16, '#687189'),
    button('主要按钮', config.primaryButton, 972, 0, 180, config.accent, '#FFFFFF')
  ]));
  for (let i = 0; i < config.cards.length; i++) {
    const item = config.cards[i];
    const layers = [rectangle('卡片背景', 0, 0, 560, 350, '#FFFFFF', 16),
      rectangle('封面底色', 20, 20, 520, 170, item.color, 10)];
    if (i === 0) {
      layers.push(group('封面可编辑形状', 140, 44, 280, 126, [
        rectangle('窗口背景', 0, 0, 280, 126, '#FFFFFF', 10),
        rectangle('侧栏', 14, 14, 56, 98, config.accent, 6),
        rectangle('标题条', 86, 20, 146, 12, '#B9C0FA', 4),
        rectangle('内容色块一', 86, 50, 76, 60, '#E9ECFF', 6),
        rectangle('内容色块二', 176, 50, 88, 60, '#E1E5F0', 6)
      ]));
    } else {
      layers.push(new Bitmap({ name: '可替换图片素材', filePath: image, frame: { x: 100, y: 25, width: 360, height: 160 } }));
    }
    layers.push(text('卡片标题', item.title, 24, 212, 380, 38, 24),
      text('卡片描述', item.description, 24, 260, 510, 28, 16, '#687189'),
      rectangle('标签背景', 24, 304, 136, 28, item.color, 6),
      text('标签文字', item.tag, 36, 308, 120, 22, 13, '#46516D'));
    board.addLayer(group(`内容卡片 ${i + 1} / ${item.title}`, 64 + i * 592, 264, 560, 350, layers));
  }
  board.addLayer(group('底部操作区', 64, 650, 1152, 138, [
    rectangle('操作区背景', 0, 0, 1152, 138, '#FFFFFF', 16),
    text('操作区标题', '从这里开始你的设计', 28, 24, 720, 36, 24),
    text('操作区说明', '选择任意文字、色块或分组，按你的想法继续调整。', 28, 78, 830, 28, 16, '#687189'),
    button('次要按钮', config.secondaryButton, 964, 44, 160, '#EDF0FF', config.accent)
  ]));
  const page = new Page({ name: '可编辑设计小样' });
  page.addArtboard(board);
  const sketch = new Sketch(); sketch.addPage(page);
  const intermediate = path.join(scratch, `library-output-${process.pid}.sketch`);
  await sketch.build(intermediate, 6);
  // 上游流式打包对中文字符串存在编码问题；显式写入 UTF-8 JSON，保留图片资源。
  const archive = await JSZip.loadAsync(fs.readFileSync(intermediate));
  for (const [name, value] of [['document.json', sketch.document], ['meta.json', sketch.meta], ['user.json', sketch.user],
    ...sketch.pages.map(item => [`pages/${item.do_objectID}.json`, item])]) {
    archive.file(name, Buffer.from(JSON.stringify(value), 'utf8'));
  }
  fs.writeFileSync(out, await archive.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' }));
  fs.unlinkSync(intermediate);
  const reloaded = await Sketch.fromFile(out);
  if (reloaded.pages[0].name !== page.name) throw new Error('中文页面名称回读失败');
  console.log(`已生成：${out}`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
