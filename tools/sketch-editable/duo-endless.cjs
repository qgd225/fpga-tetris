const fs = require('node:fs');
const path = require('node:path');
const JSZip = require('jszip');
const root = path.resolve(__dirname, '../..');
const scratch = path.join(root, 'temporary/sketch-duo-endless');
fs.mkdirSync(scratch, { recursive: true });
process.env.STORAGE_DIR = path.join(scratch, `cache-${process.pid}`);
const { Sketch, Page, Artboard, Group, Rectangle, Text, TextStyle } = require('sketch-constructor');
const output = path.join(root, 'docs/参考图/Sketch');
const C = { bg:'#080E15', field:'#0C1923', metal:'#304A59', edge:'#597B8E', shadow:'#162936',
  light:'#AFC8D4', text:'#D5E6EB', muted:'#7694A5', cyan:'#39CEE1', pink:'#E76DAA', amber:'#E8AF43' };
const pieces = { I:[[0,0],[1,0],[2,0],[3,0]], T:[[1,0],[0,1],[1,1],[2,1]],
  L:[[2,0],[0,1],[1,1],[2,1]], J:[[0,0],[0,1],[1,1],[2,1]],
  S:[[1,0],[2,0],[0,1],[1,1]], Z:[[0,0],[1,0],[1,1],[2,1]], O:[[0,0],[1,0],[0,1],[1,1]] };
const colors = { I:'#30B3CA', O:'#D5AC36', T:'#9A62B5', S:'#46A56C', Z:'#BE5146', J:'#3F72BA', L:'#D88338' };
function rect(name,x,y,w,h,color) {
  return new Rectangle({name,x,y,width:w,height:h,style:{fills:[{color}]}});
}
function txt(name,string,x,y,w,h,size=20,color=C.text,spacing=0) {
  const options={fontName:'Consolas',fontSize:size,color,kerning:spacing};
  const t=new Text({name,string,...options,textBehaviour:'fixed',frame:{x,y,width:w,height:h}});
  t.style.textStyle=new TextStyle(options);
  t.attributedString.attributes[0].attributes.kerning=spacing;
  return t;
}
function group(name,x,y,w,h,layers=[]) {return new Group({name,frame:{x,y,width:w,height:h},layers});}
function outline(name,x,y,w,h,color,thick=2) {
  return group(name,x,y,w,h,[rect('上边',0,0,w,thick,color),rect('下边',0,h-thick,w,thick,color),
    rect('左边',0,thick,thick,h-thick*2,color),rect('右边',w-thick,thick,thick,h-thick*2,color)]);
}
function screw(x,y) {return group('装甲铆钉',x,y,8,8,[rect('底座',0,0,8,8,C.shadow),rect('金属面',1,1,6,6,C.edge),rect('槽口',2,3,4,2,C.shadow)]);}
function panel(name,x,y,w,h) {
  const g=group(name,x,y,w,h,[rect('面板阴影',0,0,w,h,C.shadow),rect('装甲面',2,2,w-4,h-4,C.metal),
    rect('顶部高光',2,2,w-4,2,C.edge),rect('侧缘高光',2,4,2,h-6,'#405E6D')]);
  for(const sx of [8,w-16])for(const sy of [8,h-16])g.addLayer(screw(sx,sy));
  return g;
}
function tile(name,x,y,color,ghost=false) {
  const g=group(name,x,y,24,24);
  if(ghost) {
    for(const [xx,yy,ww,hh] of [[1,1,6,1],[11,1,6,1],[1,22,6,1],[11,22,6,1],[1,2,1,5],[1,12,1,6],[22,2,1,5],[22,12,1,6]])
      g.addLayer(rect('虚线边缘',xx,yy,ww,hh,color));
  } else {
    g.addLayer(rect('方块暗边',1,1,22,22,'#172938'));
    g.addLayer(rect('可改色块面',1,1,21,21,color));
    g.addLayer(rect('顶部高光',2,1,19,1,'#B5D8D3'));
    g.addLayer(rect('底部阴影',2,21,20,1,'#28414D'));
  }
  return g;
}
function piece(name,type,x,y,ghost=false,vertical=false) {
  const cells=pieces[type].map(([a,b])=>vertical?[b,a]:[a,b]);
  return group(name,x,y,(Math.max(...cells.map(c=>c[0]))+1)*24,(Math.max(...cells.map(c=>c[1]))+1)*24,
    cells.map(([a,b],i)=>tile(`第${i+1}格`,a*24,b*24,colors[type],ghost)));
}
function brackets(name,x,y,w,h,color) {
  const lines=[];for(const sx of [0,w-10])for(const sy of [0,h-2])lines.push(rect('水平角标',sx,sy,10,2,color));
  for(const sx of [0,w-2])for(const sy of [0,h-10])lines.push(rect('垂直角标',sx,sy,2,10,color));
  return group(name,x,y,w,h,lines);
}
function next(player,type,x,color) {
  const g=group(`${player} NEXT`,x,118,120,188,[rect('玩家识别灯',0,28,8,8,color),
    txt('玩家身份',player,6,0,90,18,12,color,2),txt('NEXT 标签','NEXT',16,36,104,30,26,C.text,6),
    rect('标签下划线',8,65,112,1,C.shadow),rect('预览窗外框',8,74,112,112,'#071018'),rect('预览窗底色',10,76,108,108,C.field)]);
  for(let a=0;a<5;a++)for(let b=0;b<5;b++)g.addLayer(rect('窗内网点',20+a*20,88+b*20,1,1,'#254353'));
  const width = Math.max(...pieces[type].map(c=>c[0])) + 1;
  g.addLayer(piece('下一块',type,16+(4-width)*12,106));
  return g;
}
function glove(name,x,y,mirror=false) {
  const g=group(name,x,y,124,76);
  const r=(n,xx,yy,w,h,c)=>g.addLayer(rect(n,mirror?124-xx-w:xx,yy,w,h,c));
  r('腕部暗边',0,40,54,36,'#101E2B');r('腕部装甲',4,42,50,30,'#405C6E');
  r('腕部高光',5,42,46,3,'#6C8997');r('腕部警示',26,48,12,5,C.amber);
  for(let i=0;i<3;i++){r('护腕分节',4+i*15,61,4,13,'#1D3546');}
  r('掌部暗边',42,22,62,44,'#101E2B');r('掌部装甲',46,24,54,38,'#3A5668');
  r('掌部高光',48,25,48,3,'#708B99');r('掌部接缝',47,48,53,3,'#142D3D');
  for(let i=0;i<4;i++){r('指节暗边',58+i*14,4+(i%2)*4,14,30,'#101E2B');r('指节钢板',60+i*14,6+(i%2)*4,10,24,'#4B687B');r('指节亮边',61+i*14,7+(i%2)*4,8,2,'#7B99A7');}
  r('拇指暗边',96,32,26,24,'#101E2B');r('拇指钢板',98,34,20,18,'#4C687A');return g;
}
async function main(){
  fs.mkdirSync(output,{recursive:true});
  const board=new Artboard({name:'双人无尽 UI / 1280×720',frame:{x:0,y:0,width:1280,height:720},backgroundColor:C.bg});
  const stars=group('01 星空背景',0,0,1280,720);
  for(let i=0;i<100;i++){const x=(i*193+67)%1240+20,y=(i*107+31)%690+10;stars.addLayer(rect('星点',x,y,i%8===0?2:1,i%8===0?2:1,i%8===0?'#99B1BE':'#344E61'));}board.addLayer(stars);
  const shell=group('02 船壳与机械装甲',0,140,1280,564,[rect('主船壳',32,0,1216,564,'#304651'),rect('上沿亮边',32,0,1216,2,'#4B6878'),
    rect('左侧背板',34,2,310,558,'#324C59'),rect('右侧背板',936,2,310,558,'#324C59'),rect('底部装甲带',32,490,1216,72,'#344E5B')]);
  for(const x of [48,1144]){
    const side=panel('侧舷装甲',x,32,88,448);
    side.addLayer(rect('装甲内凹',10,20,68,398,'#203542'));
    side.addLayer(rect('纵向接缝',36,80,2,232,'#0C1F2B'));
    for(const y of [48,188,328]){side.addLayer(rect('警示灯底座',12,y,16,16,C.shadow));side.addLayer(rect('琥珀灯',17,y+4,5,8,'#B88932'));}
    for(const y of [344,360,376])side.addLayer(rect('散热槽',40,y,22,5,'#091722'));
    shell.addLayer(side);
    const vent=panel('底部散热盖',x+8,492,76,34);
    for(const y of [9,18])vent.addLayer(rect('散热横槽',10,y,56,4,'#10212E'));shell.addLayer(vent);
  }
  for(const x of [146,1120])for(let i=0;i<6;i++)shell.addLayer(rect('船壳刻线',x,76+i*61,2,30,'#253E4B'));
  shell.addLayer(glove('左机械手',194,488));shell.addLayer(glove('右机械手',962,488,true));board.addLayer(shell);
  const top=group('03 顶部模式与速度',344,50,592,80,[txt('模式标题','DUO ENDLESS',8,18,330,38,28,C.text,4),
    txt('速度标签','SPD',312,30,32,20,12,C.muted),txt('速度数值','4/8',344,20,78,30,26),
    rect('速度仪表外壳',0,50,592,16,'#506C7B')]);
  for(let i=0;i<8;i++){const x=10+i*72;top.addLayer(group(`速度第${i+1}段`,x,52,68,12,[rect('仪表凹槽',0,0,68,12,'#08141F'),
    rect('段内亮边',2,1,64,1,'#698594'),rect('状态填充',8,4,52,5,i<4?'#31AABF':'#152936'),rect('左端铆钉',2,4,2,4,C.light),rect('右端铆钉',64,4,2,4,C.light)]));}
  top.addLayer(txt('累计消行标签','LINES',8,67,55,13,12,C.muted));top.addLayer(txt('累计消行数值','000005',66,67,90,13,12,C.text));board.addLayer(top);
  const identity=group('04 飞船标识',52,36,228,96,[txt('飞船编号','CORE-07',12,0,200,32,26,C.text,1)]);
  const planet=group('行星与星环',0,42,128,52);
  for(let i=0;i<15;i++){const dx=Math.abs(i-7);planet.addLayer(rect('行星像素轮廓',47+dx,4+i*3,44-dx*2,3,i<7?'#517583':'#375B6D'));}
  for(let i=0;i<22;i++)planet.addLayer(rect('斜向星环',i*5,40-i,16,3,i%4===0?'#6A8B99':'#3E6074'));
  identity.addLayer(planet);board.addLayer(identity);
  board.addLayer(next('P1','T',160,C.cyan));board.addLayer(next('P2','J',976,C.pink));
  const hold=group('06 共享 HOLD',160,328,136,244,[rect('共享识别灯',0,0,8,8,C.pink),
    txt('HOLD 标签','HOLD',16,0,120,34,26,C.text,6),rect('标签下划线',8,28,112,1,C.shadow),
    rect('HOLD 窗底',8,40,112,112,C.field),outline('预约青色边框',8,40,112,112,C.cyan),
    txt('预约玩家','P1',92,25,38,15,12,C.cyan),piece('暂存 L 块','L',16,48),
    txt('船舱说明一','CORE-07',8,190,128,16,13,C.muted,2),txt('船舱说明二','PWR 4200V',8,210,128,16,13,C.muted,2),
    txt('船舱说明三','EVA ONLY',8,230,128,14,12,C.muted,2)]);
  for(let i=0;i<3;i++)hold.addLayer(group(`存入条件 ${i+1}`,16+i*18,32,14,5,[rect('条件槽',0,0,14,5,C.shadow),rect('就绪灯',1,1,12,3,C.cyan)]));
  hold.addLayer(rect('预约箭头竖线',124,86,2,12,C.cyan));hold.addLayer(rect('预约箭头横线',120,90,6,4,C.cyan));board.addLayer(hold);
  const field=group('07 共享场地 24×20',344,136,592,496,[rect('外框阴影',0,0,592,496,'#06101A'),rect('框体',2,2,588,492,'#3E5869'),
    rect('上方凹槽',4,4,584,4,'#172936'),rect('场地底色',8,8,576,480,C.field)]);
  const grid=group('网格 24列×20行',8,8,576,480);
  for(let row=0;row<20;row++)for(let col=0;col<24;col++)grid.addLayer(rect(`格点 ${col+1},${row+1}`,col*24+11,row*24+11,1,1,'#254151'));
  for(let x=0;x<25;x++)if(x<24)grid.addLayer(rect('竖向网格线',x*24,0,1,480,'#102330'));
  for(let y=0;y<20;y++)grid.addLayer(rect('横向网格线',0,y*24,576,1,'#102330'));field.addLayer(grid);
  const pile=group('已落定方块',8,8,576,480);
  const rows=[
    {r:19,s:'IIIIOOLLLSSTTTIOOJJJZZZZ'},
    {r:18,s:'....OO..L.S..TIOOJ...Z..'},
    {r:17,s:'..............I.........'},
    {r:16,s:'..............I.........'}];
  for(const {r,s} of rows){if(s.length!==24)throw new Error('场地行宽错误');[...s].forEach((type,col)=>{if(type!=='.')pile.addLayer(tile(`落定 ${col+1},${r+1} / ${type}`,col*24,r*24,colors[type]));});}field.addLayer(pile);
  field.addLayer(piece('P1 活动 I 块','I',8+4*24,8+3*24));field.addLayer(brackets('P1 青色身份框',8+4*24-3,8+3*24-3,102,30,C.cyan));
  field.addLayer(piece('P2 活动 S 块','S',8+17*24,8+4*24));field.addLayer(brackets('P2 品红身份框',8+17*24-3,8+4*24-3,78,54,C.pink));
  field.addLayer(piece('P1 幽灵落点','I',8+4*24,8+17*24,true));field.addLayer(piece('P2 幽灵落点','S',8+17*24,8+16*24,true));
  for(const x of [2,584])for(const y of [10,120,240,360,478])field.addLayer(rect('框架紧固件',x,y,6,4,'#152C3C'));
  board.addLayer(field);
  const reserve=group('08 共享 RESERVE 储备',936,320,168,292,[txt('储备标签','RESERVE',48,0,120,32,24,C.text),
    rect('仪表顶部盖',82,30,44,8,C.edge),rect('仪表外壳阴影',70,42,66,242,'#112531'),
    rect('左侧钢轨',72,44,8,236,'#638193'),rect('右侧钢轨',126,44,8,236,'#638193'),
    rect('连续储备槽',84,46,38,230,'#07121C'),rect('储备填充 92/150',86,135,34,141,C.cyan),
    rect('填充反光',87,136,3,139,'#8BE9E9'),rect('底部端盖',78,280,52,6,C.edge)]);
  for(let i=0;i<4;i++){const y=56+i*60;reserve.addLayer(rect('输入导管暗边',0,y,72,6,'#10222F'));reserve.addLayer(rect('输入导管亮边',2,y,70,2,'#587888'));reserve.addLayer(rect('管口',0,y-5,10,16,C.shadow));reserve.addLayer(rect('管口高光',2,y-3,5,12,C.edge));}
  for(let i=0;i<5;i++){const y=48+i*52;reserve.addLayer(rect('左侧固定箍',66,y,18,9,'#385668'));reserve.addLayer(rect('右侧固定箍',122,y,18,9,'#385668'));reserve.addLayer(rect('箍上螺栓',70,y+2,4,4,'#8BA6B3'));}
  board.addLayer(reserve);
  const bottom=group('09 共享成绩与时间',336,648,608,48,[rect('上分隔线',0,3,608,1,'#536D7C'),
    txt('分数标签','SCORE',64,16,96,30,26,C.text),txt('分数数值','000018',160,16,112,30,26,C.text),
    txt('时间标签','TIME',288,16,80,30,26,C.text),txt('时间数值','02:15',384,16,112,30,26,C.text)]);board.addLayer(bottom);
  const page=new Page({name:'双人无尽 / 可编辑 UI'});page.addArtboard(board);
  const sketch=new Sketch();sketch.addPage(page);
  // 显式 UTF-8 打包，避免上游流式打包损坏中文图层名。
  const zip=new JSZip();for(const [name,value] of [['document.json',sketch.document],['meta.json',sketch.meta],['user.json',sketch.user],
    ...sketch.pages.map(p=>[`pages/${p.do_objectID}.json`,p])])zip.file(name,Buffer.from(JSON.stringify(value),'utf8'));
  const file=path.join(output,'20261027_双人无尽UI_v1.sketch');fs.writeFileSync(file,await zip.generateAsync({type:'nodebuffer',compression:'DEFLATE'}));
  const reloaded=await Sketch.fromFile(file);if(reloaded.pages[0].name!==page.name)throw new Error('中文页面回读失败');
  console.log(`已生成：${file}`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
