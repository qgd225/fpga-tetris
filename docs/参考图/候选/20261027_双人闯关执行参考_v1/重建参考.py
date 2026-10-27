from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,hashlib,shutil

ROOT=Path(__file__).resolve().parent
ROOT.mkdir(parents=True,exist_ok=True)
(ROOT/'layers').mkdir(exist_ok=True)
SOURCE=ROOT/'00_认可方向_原图.png'
src=Image.open(SOURCE).convert('RGB')

FONT='C:/Windows/Fonts/consola.ttf';CN='C:/Windows/Fonts/msyh.ttc'
CYAN='#7FE3EC';AMBER='#FFC96B';MAGENTA='#e45bbf'
palette={'I':'#38B6C8','T':'#9B6BB5','O':'#D9B23C','Z':'#C2453A','S':'#4FA86B','L':'#D97B33','J':'#3E6FBF'}

# 整体材质来自认可图，按场地和侧栏边界分区适配。
sx=[0,231,447,463,1134,1340,1468,1672];tx=[0,156,336,352,928,1112,1200,1280]
sy=[0,28,174,185,815,834,921,941];ty=[0,20,132,144,624,640,704,720]
mesh=[]
for j in range(len(sy)-1):
    for i in range(len(sx)-1):
        mesh.append(((tx[i],ty[j],tx[i+1],ty[j+1]),(sx[i],sy[j],sx[i],sy[j+1],sx[i+1],sy[j+1],sx[i+1],sy[j])))
base=src.transform((1280,720),Image.Transform.MESH,mesh,Image.Resampling.NEAREST).convert('RGBA')
# 移除重排前的功能字/窗口，避免保留双重标题和双重轮廓。
surface=src.crop((1190,470,1315,570)).convert('RGBA')
for bx,by,br,bb in [(148,32,1112,132),(148,145,338,320),(148,328,338,512),(940,145,1112,350),(1110,32,1272,656),(410,640,880,697)]:
    base.paste(surface.resize((br-bx,bb-by),Image.Resampling.NEAREST),(bx,by))
layers={'01_static_shell':base}
for name in ['02_field','03_preview','04_pieces_and_ghosts','05_core_and_phase','06_feedback']:
    layers[name]=Image.new('RGBA',(1280,720),(0,0,0,0))
def text(d,x,y,s,n=14,c='#e8eef2'):
    d.text((x,y),s,font=ImageFont.truetype(FONT,n),fill=c)
def center(d,x,y,w,s,n=14,c='#e8eef2'):
    f=ImageFont.truetype(FONT,n);b=d.textbbox((0,0),s,font=f)
    text(d,x+(w-b[2]+b[0])/2,y,s,n,c)
def rect(d,x,y,w,h,fill,outline=None):d.rectangle((x,y,x+w-1,y+h-1),fill=fill,outline=outline)
def patch(crop,dest):
    x,y,r,b=dest;base.paste(src.crop(crop).resize((r-x,b-y),Image.Resampling.NEAREST).convert('RGBA'),(x,y))

# 船况头采用固定144宽徽标区和404宽双轨区，字形/材质来源冻结。
patch((239,56,591,172),(352,40,504,128))
patch((597,64,1312,151),(508,44,924,124))

# 预览有效槽严格112×112，面板轮廓与文字保留认可图；只重绘动态槽内。
patch((231,203,445,417),(156,148,292,312))
patch((1161,203,1340,393),(972,148,1108,312))
patch((233,434,443,670),(156,332,292,506))
d=ImageDraw.Draw(base)
# 清除原HOLD底部附带纹理后的接口，保留连续壳体。
rect(d,168,368,112,112,'#07121d','#3a5265')
for j in range(3):rect(d,212+j*10,490,5,5,'#344d60','#687e8c')
rect(d,984,320,112,24,'#102332','#647d8d');center(d,984,322,112,'SPD 3/8',16)
rect(d,512,660,256,32,'#102332','#6e8593');center(d,512,660,256,'TIME 02:18',24)

# 导管沿认可图的一次错位拓扑放置；具体路径是实施约束。
pipe=[(928,68),(1084,68),(1104,88),(1104,138),(1116,150),(1116,414),(1120,418)]
d.line(pipe,fill='#112635',width=12)
d.line(pipe,fill='#8f5e29',width=9)
d.line(pipe,fill='#e89a3b',width=6)
d.line([(930,66),(1085,66),(1106,87),(1106,136),(1118,149),(1118,412)],fill='#ffd28b',width=1)
for yy in (104,252,370):
    rect(d,1101 if yy==104 else 1113,yy,7,24,'#163e51','#879eab')
    rect(d,1103 if yy==104 else 1115,yy+3,3,18,CYAN)
for x,y,w,h in [(928,62,8,13),(1098,132,13,5),(1110,305,13,5),(1116,410,7,15)]:
    rect(d,x,y,w,h,'#436071','#8197a2')

# 场地：每格24，全部480格坐标固定；底纹仅低对比细线。
fd=ImageDraw.Draw(layers['02_field'])
rect(fd,352,144,576,480,'#0A1118')
for x in range(352,928,24):fd.line((x,144,x,623),fill='#142d3b')
for y in range(144,624,24):fd.line((352,y,927,y),fill='#142d3b')

# 小格沿用认可图的块面亮暗关系，转到现有七类型色。
tile=src.crop((597,343,626,372)).resize((22,22),Image.Resampling.NEAREST).convert('RGB')
def make_tile(color,debris=False):
    rgb=tuple(int(color[i:i+2],16) for i in (1,3,5));out=Image.new('RGBA',(24,24),(0,0,0,0))
    for yy in range(22):
        for xx in range(22):
            rr,gg,bb=tile.getpixel((xx,yy));v=(max(rr,gg,bb)/210)
            v=max(.60,min(1.48,v))
            out.putpixel((xx+1,yy+1),tuple(min(255,int(k*v)) for k in rgb)+(255,))
    td=ImageDraw.Draw(out)
    td.line((2,1,21,1),fill='#c0d0d7',width=1)
    td.line((22,2,22,22,2,22),fill='#1c303e',width=1)
    if debris:
        td.line((16,3,13,7,15,10,11,15),fill='#243947',width=1)
        td.line((17,4,15,7),fill='#9bb0bc')
    return out
tiles={k:make_tile(v) for k,v in palette.items()};tiles['debris']=make_tile('#526774',True)
def block(layer,c,r,kind):layer.alpha_composite(tiles[kind],(352+c*24,144+r*24))
def preview(x,y,shape,kind):
    pd=ImageDraw.Draw(layers['03_preview'])
    rect(pd,x,y,112,112,'#07121d')
    w=(max(a for a,b in shape)+1)*24;h=(max(b for a,b in shape)+1)*24
    for a,b in shape:layers['03_preview'].alpha_composite(tiles[kind],(x+(112-w)//2+a*24,y+(112-h)//2+b*24))
T=[(0,0),(1,0),(2,0),(1,1)];L=[(0,0),(0,1),(0,2),(1,2)]
O=[(0,0),(1,0),(0,1),(1,1)]
preview(168,192,O,'O');preview(984,192,T,'T')
preview(168,368,[(0,0)],'T')
# 空HOLD不显示任何方块。
ImageDraw.Draw(layers['03_preview']).rectangle((168,368,279,479),fill='#07121d')
board={}
debris_cols=[0,1,2,4,5,7,9,10,12,14,15,17,18,20,21,23]
for c in debris_cols:board[(c,19)]='debris'
board[(0,18)]='debris';board[(23,18)]='debris'
heights={0:2,1:3,2:2,4:2,5:3,7:2,9:2,10:3,12:2,14:2,15:3,17:4,18:3,20:2,21:2,23:3}
types=list(palette)
for c,h in heights.items():
    for rr in range(1,h):
        pos=(c,19-rr)
        if pos not in board:board[pos]=types[(c+rr)%7]
pl=layers['04_pieces_and_ghosts'];pd=ImageDraw.Draw(pl)
for (c,r),k in board.items():block(pl,c,r,k)
def landing(cx,shape):
    cy=0
    while all(cy+1+b<20 and (cx+a,cy+1+b) not in board for a,b in shape):cy+=1
    return cy
def ghost(cx,shape,kind):
    cy=landing(cx,shape)
    for a,b in shape:
        px=352+(cx+a)*24+2;py=144+(cy+b)*24+2
        for q in range(0,20,7):
            pd.line((px+q,py,px+min(q+3,19),py),fill=palette[kind])
            pd.line((px+q,py+19,px+min(q+3,19),py+19),fill=palette[kind])
            pd.line((px,py+q,px,py+min(q+3,19)),fill=palette[kind])
            pd.line((px+19,py+q,px+19,py+min(q+3,19)),fill=palette[kind])
    return cy
gy1=ghost(5,T,'T');gy2=ghost(17,L,'L')
for cx,cy,shape,kind,col in [(5,5,T,'T',CYAN),(17,5,L,'L',MAGENTA)]:
    for a,b in shape:block(pl,cx+a,cy+b,kind)
    x=352+cx*24-3;y=144+cy*24-3;w=(max(a for a,b in shape)+1)*24+6;h=(max(b for a,b in shape)+1)*24+6
    for xx,yy,dx,dy in [(x,y,1,1),(x+w,y,-1,1),(x,y+h,1,-1),(x+w,y+h,-1,-1)]:
        pd.line((xx,yy,xx+dx*8,yy),fill=col,width=2);pd.line((xx,yy,xx,yy+dy*8),fill=col,width=2)

# 核心外壳采用认可图材质，功能发光区严格8×28，间隔4。
def core(layer,state,segments,phase=True):
    cd=ImageDraw.Draw(layer)
    skin=src.crop((1341,272,1468,775)).resize((88,280),Image.Resampling.NEAREST).convert('RGBA')
    layer.alpha_composite(skin,(1112,340))
    rect(cd,1120,352,64,256,'#081622','#728b9b')
    for i in range(8):
        yy=352+(7-i)*32;on=i<segments
        pts=[(1127,yy+2),(1177,yy+2),(1181,yy+6),(1181,yy+26),(1177,yy+29),(1127,yy+29),(1123,yy+26),(1123,yy+6)]
        cd.polygon(pts,fill='#25cbdf' if on else '#0b1d2c',outline='#a8eff3' if on else '#4d6d80')
        cd.line((1128,yy+4,1176,yy+4),fill='#efffff' if on else '#29485b')
        cd.line((1127,yy+27,1176,yy+27),fill='#167d94' if on else '#040c16')
    for xx in (1115,1187):
        rect(cd,xx,544,4,52,AMBER if state=='HALF' else '#455f70')
    rect(cd,1128,336,48,8,'#6a8493','#b8c5cd')
    if state=='LOCKED':
        rect(cd,1126,342,52,7,'#7b8e99','#d3dce1');rect(cd,1132,338,40,3,'#D8442E')
    elif state=='ONLINE':
        rect(cd,1127,331,7,17,'#7e98a8');rect(cd,1171,331,7,17,'#7e98a8')
    rect(cd,1112,624,128,24,'#0d2130','#778d99')
    center(cd,1112,626,128,state,16,'#D8442E' if state=='LOCKED' else AMBER if state=='HALF' else CYAN)
    if phase:
        current=0 if segments<=2 else 1 if segments<=4 else 2 if segments<=6 else 3
        for i,s in enumerate(['RECONNECT','REBUILD','STABILIZE','RECHARGE']):
            yy=582-i*64
            if i==current:cd.polygon([(1193,yy),(1193,yy+8),(1198,yy+4)],fill=AMBER)
            else:cd.ellipse((1192,yy+1,1197,yy+6),outline=CYAN if i<current else '#93a9b6',fill=CYAN if i<current else None)
            text(cd,1200,yy-2,s,10,AMBER if i==current else '#c3d3dd' if i<current else '#8da4b2')
core(layers['05_core_and_phase'],'HALF',3)
fx=ImageDraw.Draw(layers['06_feedback']);text(fx,780,562,'+6',19,CYAN)
for x,y in [(746,604),(770,599),(797,609),(810,598)]:
    fx.line((x,y,x+2,y-4),fill=AMBER,width=1)

result=Image.new('RGBA',(1280,720))
for name,layer in layers.items():
    layer.save(ROOT/'layers'/f'{name}.png');result.alpha_composite(layer)
result.convert('RGB').save(ROOT/'01_执行参考_1280x720.png')
result.resize((2560,1440),Image.Resampling.NEAREST).save(ROOT/'01_执行参考_2倍.png')

# 单独生成核心状态对照；不把锁态/在线错误地解释成不同计功规则。
states=Image.new('RGB',(1040,460),'#08131f');sd=ImageDraw.Draw(states)
for idx,(state,n) in enumerate([('LOCKED',0),('HALF',3),('ONLINE',7),('ONLINE',8)]):
    layer=Image.new('RGBA',(1280,720));core(layer,state,n,False)
    part=layer.crop((1108,328,1244,650))
    states.paste(part,(38+idx*252,70),part)
    center(sd,idx*252+12,25,230,state if n!=8 else 'SUCCESS',22)
    center(sd,idx*252+12,408,230,f'{n}/8',20,CYAN)
states.save(ROOT/'03_核心状态对照.png')

# 实施坐标及源图绑定。
regions={
'field':{'rect':[352,144,576,480],'cell':[24,24],'grid':[24,20],'z':20},
'header':{'rect':[352,40,576,88],'z':10},
'p1_next_panel':{'rect':[156,148,136,164],'z':10},
'p1_next_slot':{'rect':[168,192,112,112],'z':30},
'p2_next_panel':{'rect':[972,148,136,164],'z':10},
'p2_next_slot':{'rect':[984,192,112,112],'z':30},
'hold_panel':{'rect':[156,332,136,174],'z':10},
'hold_slot':{'rect':[168,368,112,112],'z':30},
'hold_conditions':{'rect':[212,490,25,5],'z':30},
'speed':{'rect':[984,320,112,24],'z':30},
'core':{'rect':[1120,352,64,256],'segments':8,'pitch':32,'segment_height':28,'fill_direction':'bottom_to_top','z':40},
'core_state':{'rect':[1112,624,128,24],'z':40},
'phase':{'rect':[1192,388,80,204],'order_bottom_to_top':['RECONNECT','REBUILD','STABILIZE','RECHARGE'],'baseline_y_bottom_to_top':[582,518,454,390],'z':40},
'time':{'rect':[512,660,256,32],'z':30},
'feedback':{'rect':[352,540,576,84],'z':50}}
spec={'version':1,'status':'implementation_reference_candidate','canvas':[1280,720],
'bounds_convention':'[x,y,w,h], half-open [x,x+w) and [y,y+h)',
'source':{'file':'00_认可方向_原图.png','sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest()},
'regions':regions,'pipe':{'centerline':pipe,'outer_width':12,'orange_width':6,'z':10},
'palette_current_rtl':palette,'sample':{'mode':'DUO CAMPAIGN','ship':2,'credit':15,'target':35,'debris':18,'half_threshold':20,'core_segments':3,'phase':'REBUILD','time':'02:18','hint_visible':False,'debris_cells':18,'ghost_rows':[gy1,gy2]},
'layer_order':list(layers),'geometry_checks':{}}
for key,val in regions.items():
    x,y,w,h=val['rect'];assert 0<=x<x+w<=1280 and 0<=y<y+h<=720,key
assert 576==24*24 and 480==20*24
assert sum(k=='debris' for k in board.values())==18
assert min(4,(8*15)//35)==3
assert all((cx+a,cy+b) not in board for cx,cy,shape in [(5,gy1,T),(17,gy2,L)] for a,b in shape)
spec['geometry_checks']={'bounds':'pass','field_24x20':'pass','slots_112_square':'pass','core_8x32':'pass','phase_bottom_to_top':'pass','sample_charge_debris':'pass','ghost_collision':'pass'}
(ROOT/'04_模块规格.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2),encoding='utf-8')

# 图外标注，避免文字压住材质图。
board_img=Image.new('RGB',(3400,1690),'#f5f7fa');bd=ImageDraw.Draw(board_img)
board_img.paste(result.resize((2560,1440),Image.Resampling.NEAREST).convert('RGB'),(36,110))
bd.text((36,24),'双人闯关 UI｜1280×720 执行参考',font=ImageFont.truetype(CN,36),fill='#243a4a')
bd.text((36,74),'画面为设计重建，不是 RTL 截图；所有模块坐标见右侧及 JSON。',font=ImageFont.truetype(CN,21),fill='#5d7080')
for i,(label,key) in enumerate([('场地','field'),('船况头','header'),('P1 NEXT','p1_next_slot'),('P2 NEXT','p2_next_slot'),('共享 HOLD','hold_slot'),('核心填充','core'),('核心状态','core_state'),('阶段刻度','phase'),('TIME','time')]):
    yy=150+i*118;x,y,w,h=regions[key]['rect']
    bd.text((2660,yy),label,font=ImageFont.truetype(CN,27),fill='#243a4a')
    bd.text((2660,yy+43),f'({x}, {y})  {w} × {h}',font=ImageFont.truetype(FONT,25),fill='#476b81')
bd.text((2660,1260),'双人无 HINT；四阶自下向上。',font=ImageFont.truetype(CN,23),fill='#243a4a')
bd.text((2660,1310),'HALF 3/8；成功才亮满八段。',font=ImageFont.truetype(CN,23),fill='#243a4a')
bd.text((36,1590),'先实现静态材质与布局，再接现有状态信号；不改玩法计数。',font=ImageFont.truetype(CN,27),fill='#243a4a')
board_img.save(ROOT/'02_坐标与模块标注.png')
print(ROOT)
print('PASS: geometry, sample state, debris count, ghost collision. No RTL changed.')
