"""CORE-07 ship rescue: sparse, reproducible pixel concept, not FPGA output."""
from pathlib import Path
from contextlib import redirect_stdout
from io import StringIO
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, str(Path.home()/'.codex/skills/pixel-art-studio/scripts'))
from pixelstudio import Sprite, mix
from PIL import Image

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'out'
OUT.mkdir(parents=True,exist_ok=True)
C={
    'bg':'#bfd1df','shade':'#a6bed1','line':'#8ba4b9','ink':'#375472',
    'light':'#e5eff6','edge':'#6b8ba6','board':'#101f32','grid':'#1c3248',
    'sky':'#213b56','planet':'#7296bd','planetlit':'#a9cbdc',
    'cyan':'#58d9f1','pink':'#f68cb8','amber':'#e7a975','red':'#dd7883',
    'mint':'#83d9ba','white':'#edf6fa','dim':'#617e99',
}
BASE=['#56d4f4','#a38bef','#f3d36b','#ec819a','#83d5af','#eea56f','#719deb']
SHADOW=[mix(c,'#655991',.27) for c in BASE]
PALETTE=list(dict.fromkeys(list(C.values())+BASE+SHADOW))
PHASES=[
    ('01 LINK',3,2,'Main power is down.','Requesting rescue link.'),
    ('02 ISOLATE',11,4,'Leak isolated.','Bypass is holding.'),
    ('03 RESTART',23,6,'Engines are back.','Stabilize our attitude.'),
    ('04 ESCAPE',35,8,'Course locked.','Ready for the final burn.'),
]
SHAPES={
    'I':[(0,0),(0,1),(0,2),(0,3)],
    'T':[(0,0),(1,0),(2,0),(1,1)],
    'L':[(0,0),(0,1),(0,2),(1,2)],
    'S':[(1,0),(2,0),(0,1),(1,1)],
    'O':[(0,0),(1,0),(0,1),(1,1)],
}


GLYPHS={
 'A':['01110','10001','10001','11111','10001','10001','10001'],
 'B':['11110','10001','10001','11110','10001','10001','11110'],
 'C':['01111','10000','10000','10000','10000','10000','01111'],
 'D':['11110','10001','10001','10001','10001','10001','11110'],
 'E':['11111','10000','10000','11110','10000','10000','11111'],
 'F':['11111','10000','10000','11110','10000','10000','10000'],
 'G':['01111','10000','10000','10111','10001','10001','01111'],
 'H':['10001','10001','10001','11111','10001','10001','10001'],
 'I':['11111','00100','00100','00100','00100','00100','11111'],
 'J':['00111','00010','00010','00010','10010','10010','01100'],
 'K':['10001','10010','10100','11000','10100','10010','10001'],
 'L':['10000','10000','10000','10000','10000','10000','11111'],
 'M':['10001','11011','10101','10101','10001','10001','10001'],
 'N':['10001','11001','11001','10101','10011','10011','10001'],
 'O':['01110','10001','10001','10001','10001','10001','01110'],
 'P':['11110','10001','10001','11110','10000','10000','10000'],
 'Q':['01110','10001','10001','10001','10101','10010','01101'],
 'R':['11110','10001','10001','11110','10100','10010','10001'],
 'S':['01111','10000','10000','01110','00001','00001','11110'],
 'T':['11111','00100','00100','00100','00100','00100','00100'],
 'U':['10001','10001','10001','10001','10001','10001','01110'],
 'V':['10001','10001','10001','10001','10001','01010','00100'],
 'W':['10001','10001','10001','10101','10101','11011','10001'],
 'X':['10001','10001','01010','00100','01010','10001','10001'],
 'Y':['10001','10001','01010','00100','00100','00100','00100'],
 'Z':['11111','00001','00010','00100','01000','10000','11111'],
 '0':['01110','10001','10011','10101','11001','10001','01110'],
 '1':['00100','01100','00100','00100','00100','00100','01110'],
 '2':['01110','10001','00001','00010','00100','01000','11111'],
 '3':['11110','00001','00001','01110','00001','00001','11110'],
 '4':['00010','00110','01010','10010','11111','00010','00010'],
 '5':['11111','10000','10000','11110','00001','00001','11110'],
 '6':['01110','10000','10000','11110','10001','10001','01110'],
 '7':['11111','00001','00010','00100','01000','01000','01000'],
 '8':['01110','10001','10001','01110','10001','10001','01110'],
 '9':['01110','10001','10001','01111','00001','00001','01110'],
 '/':['00001','00001','00010','00100','01000','10000','10000'],
 ':':['00000','00100','00100','00000','00100','00100','00000'],
 '-':['00000','00000','00000','11111','00000','00000','00000'],
 '.':['00000','00000','00000','00000','00000','00110','00110'],
 ' ':['00000']*7,
}


def text(s,x,y,label,color='ink',size=10):
    scale=2 if size>=12 else 1
    w,h=len(label)*6*scale,7*scale
    assert x>=0 and y>=0 and x+w<=640 and y+h<=360,(label,x,y,w,h)
    col=C.get(color,color)
    for i,ch in enumerate(label.upper()):
        for yy,row in enumerate(GLYPHS[ch]):
            for xx,bit in enumerate(row):
                if bit=='1':s.rect(x+i*6*scale+xx*scale,y+yy*scale,x+i*6*scale+xx*scale+scale-1,y+yy*scale+scale-1,col)


def rect(s,x,y,w,h,color,fill=True):
    s.rect(x,y,x+w-1,y+h-1,C.get(color,color),fill=fill)


def line(s,x0,y0,x1,y1,color):
    s.line(x0,y0,x1,y1,C.get(color,color))


def frame(s,x,y,w,h,color='edge'):
    rect(s,x,y,w,h,'light')
    rect(s,x+1,y+1,w-2,h-2,'bg')
    rect(s,x,y,w,h,color,False)
    line(s,x+3,y+2,x+w-4,y+2,'light')


def block(s,x,y,i,ghost=False):
    if ghost:
        rect(s,x+2,y+2,8,8,'planetlit',False)
        return
    rect(s,x+1,y+1,10,10,BASE[i])
    rect(s,x+1,y+9,10,2,SHADOW[i])
    line(s,x+2,y+2,x+5,y+2,'white')
    line(s,x+2,y+2,x+2,y+4,'white')
    # Two connector marks retain a small mechanical accent.
    line(s,x+8,y+1,x+9,y+1,'light')
    line(s,x+8,y+10,x+9,y+10,'dim')


def piece(s,x,y,name,i,ghost=False):
    for xx,yy in SHAPES[name]:block(s,x+xx*12,y+yy*12,i,ghost)


def backdrop(s,phase):
    rect(s,0,0,640,360,'bg')
    for x in [10,150,170,470,490,630]:line(s,x,0,x,359,'line')
    for y in [64,170,262,348]:line(s,0,y,639,y,'line')
    # A handful of lines create a mechanical bulkhead, not a textured illustration.
    line(s,16,4,130,4,'light');line(s,130,4,145,19,'edge')
    line(s,16,352,145,352,'edge');line(s,145,352,156,341,'edge')
    for x,y in [(18,72),(144,254),(628,176),(18,340)]:rect(s,x,y,3,3,'cyan')
    # Small observation window with a deliberately simple pixel planet.
    rect(s,24,278,112,60,'edge');rect(s,26,280,108,56,'sky')
    for x,y in [(32,287),(48,325),(117,290),(122,316),(91,286)]:rect(s,x,y,1,1,'planet')
    planet=[(61,295),(78,295),(84,301),(84,315),(78,321),(61,321),(55,315),(55,301)]
    s.polygon(planet,C['planet'])
    s.polygon([(61,295),(78,295),(81,298),(62,298),(58,303),(56,307),(55,307),(55,301)],C['planetlit'])
    line(s,46,313,91,304,'dim');line(s,49,315,95,306,'dim')
    # Shared transfer bus around the bottom of the grid. It changes with the mission.
    route='dim' if phase==0 else 'cyan'
    line(s,164,318,164,339,route);line(s,164,339,478,339,route)
    line(s,478,339,478,314,route);line(s,478,314,492,314,route)
    if phase==0:
        rect(s,436,337,13,5,'bg')
        line(s,437,333,446,342,'red');line(s,446,333,437,342,'red')
    if phase>=1:
        line(s,164,265,152,265,'dim');line(s,152,265,152,304,'dim')
        line(s,149,275,155,281,'red');line(s,155,275,149,281,'red')
    if phase>=2:
        line(s,167,342,475,342,'light')
        for x in [228,326,424]:
            s.polygon([(x,336),(x+4,339),(x,342)],C['cyan'])
    if phase==3:
        rect(s,474,267,4,12,'amber')
        line(s,477,273,483,280,'amber')


def ship(s,phase,x=514,y=236):
    if phase<2:
        # A tilted silhouette is authored directly on the pixel grid.
        p=[(x,y+19),(x+8,y+4),(x+33,y-7),(x+53,y+2),(x+44,y+18),(x+15,y+29)]
        s.polygon(p,C['edge'])
        s.polygon([(x+4,y+18),(x+12,y+5),(x+33,y-3),(x+47,y+3),(x+40,y+16),(x+15,y+25)],C['light'])
        s.polygon([(x+32,y-1),(x+42,y+2),(x+36,y+8),(x+29,y+8)],C['sky'])
        line(s,x+10,y+18,x+35,y+9,'line')
        if phase==0:
            rect(s,x+2,y+26,4,4,'amber');rect(s,x-3,y+33,3,3,'red')
            line(s,x+3,y+30,x-1,y+35,'red')
        else:
            # A cyan capture bracket and isolated red branch are bigger than a status dot.
            for xx,yy,dx,dy in [(x-7,y-9,9,12),(x+53,y-14,-9,12),(x-7,y+35,9,-9),(x+53,y+30,-9,-9)]:
                line(s,xx,yy,xx+dx,yy,'cyan');line(s,xx,yy,xx,yy+dy,'cyan')
            line(s,x+4,y+28,x+11,y+35,'red');line(s,x+11,y+28,x+4,y+35,'red')
    else:
        p=[(x-3,y+4),(x+11,y-2),(x+35,y-2),(x+54,y+8),(x+35,y+20),(x+11,y+20),(x-3,y+14)]
        s.polygon(p,C['edge'])
        s.polygon([(x,y+5),(x+12,y+1),(x+35,y+1),(x+49,y+8),(x+34,y+17),(x+12,y+17),(x,y+12)],C['light'])
        s.polygon([(x+29,y+2),(x+38,y+4),(x+42,y+8),(x+29,y+8)],C['sky'])
        rect(s,x-4,y+5,4,9,'cyan')
        if phase==2:
            s.polygon([(x-6,y+6),(x-13,y+9),(x-6,y+12)],C['cyan'])
        else:
            s.polygon([(x-6,y+5),(x-25,y+9),(x-6,y+14)],C['cyan'])
            s.polygon([(x-6,y+7),(x-17,y+9),(x-6,y+11)],C['white'])
            for xx,yy in [(x-26,y-1),(x-32,y+20)]:line(s,xx-6,yy,xx+6,yy,'cyan')
    if phase==3:
        # Keep the target in frame: the final departure happens only after the real win.
        s.polygon([(494,294),(500,283),(506,294)],C['amber'])
        line(s,500,286,500,290,'ink')
        for yy in range(214,281,8):line(s,502,yy,502,yy+3,'red')
        line(s,579,245,613,245,'mint')
        line(s,608,240,613,245,'mint');line(s,608,250,613,245,'mint')


def target_panel(s,phase):
    rect(s,486,182,138,148,'edge',False)
    rect(s,487,183,136,146,'sky')
    line(s,492,201,618,201,'dim')
    text(s,494,190,'TARGET 07','planetlit',9)
    # No complex exterior scenery: just a few docking/repair guide lines.
    for x,y in [(495,212),(614,219),(603,304),(492,312)]:rect(s,x,y,1,1,'planet')
    line(s,492,307,503,307,'dim');line(s,503,307,509,301,'dim')
    ship(s,phase)
    symbols=['LINK LOST','BYPASS ON','THRUST ON','BURN READY']
    text(s,494,315,symbols[phase],'amber' if phase in [0,3] else 'cyan',9)
    if phase==0:
        # Sparse warning diagonal, not an illustrated explosion.
        line(s,610,208,616,214,'red');line(s,616,208,610,214,'red')


def scene(phase,dialog=True):
    s=Sprite(640,360,palette=PALETTE)
    title,lines,spd,a,b=PHASES[phase]
    backdrop(s,phase)
    text(s,22,17,'CORE-07','ink',14)
    text(s,22,39,'RESCUE CONTROL','edge',8)
    text(s,176,19,title,'ink',12)
    text(s,176,41,f'SPD {spd}/8','ink',9)
    text(s,267,41,f'{lines:02d}/40','ink',9)
    # Exactly one shared 24-column, 20-row field.
    frame(s,172,68,296,248)
    rect(s,176,72,288,240,'board')
    for col in range(25):line(s,176+col*12,72,176+col*12,311,'grid')
    for row in range(21):line(s,176,72+row*12,463,72+row*12,'grid')
    line(s,174,72,174,311,'cyan');line(s,466,72,466,311,'pink')
    heights=[3,3,2,2,1,1,0,1,2,4,3,2,1,1,2,2,3,3,2,1,0,1,2,4]
    for col,h in enumerate(heights):
        for yy in range(h):block(s,176+col*12,72+(19-yy)*12,(col+yy*2)%7)
    piece(s,176+5*12,72+4*12,'I',0)
    piece(s,176+16*12,72+7*12,'S',4)
    piece(s,176+5*12,72+15*12,'I',0,True)
    piece(s,176+16*12,72+15*12,'S',4,True)
    # Symmetrical, compact NEXT slots. HOLD is one shared slot.
    for x,player,col,name,index in [(46,'P1','cyan','T',1),(510,'P2','pink','L',5)]:
        text(s,x,72,player,'ink',10)
        rect(s,x,82,11,1,col)
        text(s,x+59,72,'NEXT','ink',10)
        frame(s,x,86,84,64)
        rect(s,x+4,90,76,56,'board')
        coords=SHAPES[name]
        pw=(max(p[0] for p in coords)+1)*12
        ph=(max(p[1] for p in coords)+1)*12
        piece(s,x+(84-pw)//2,86+(64-ph)//2,name,index)
    text(s,46,176,'HOLD','ink',10)
    # Shared symbol instead of duplicated text-heavy operator cards.
    rect(s,81,178,5,4,'edge',False);rect(s,85,178,5,4,'edge',False)
    frame(s,46,188,84,52)
    rect(s,50,192,76,44,'board')
    piece(s,76,202,'O',2)
    text(s,176,326,'SCORE 001248','ink',9)
    text(s,321,326,'03:24','ink',9)
    target_panel(s,phase)
    if dialog:
        # Above the right-side NEXT; never covers the field or a preview.
        frame(s,420,8,212,52,'ink')
        rect(s,423,11,206,46,'light')
        text(s,430,14,'SHIP AI','edge',8)
        text(s,430,27,a,'ink',10)
        text(s,430,41,b,'ink',10)
        # Small speech-tail and signal notch; no portrait required.
        line(s,605,59,609,63,'ink');line(s,609,63,613,59,'ink')
        for i,h in enumerate([3,5,2,6,4]):rect(s,609+i*3,15-h,1,h,'cyan')
    return s


def save(s,path,scale=1):
    with redirect_stdout(StringIO()):s.save_png(str(path),scale=scale)


def build():
    frames=[]
    checks=[]
    for i in range(4):
        s=scene(i)
        master=OUT/f'phase_{i+1}_1x.png'
        save(s,master)
        save(s,OUT/f'phase_{i+1}_2x.png',2)
        save(scene(i,False),OUT/f'phase_{i+1}_no_dialog_2x.png',2)
        im=Image.open(master).convert('RGBA')
        colors={p for p in im.get_flattened_data()}
        assert len(colors)<=64,len(colors)
        assert {p[3] for p in colors}=={255}
        frames.append(im)
        checks.append({'phase':i+1,'colors':len(colors),'size':list(im.size),'alpha':'opaque'})
    overview=Image.new('RGBA',(1280,720),C['bg'])
    for i,im in enumerate(frames):overview.paste(im,((i%2)*640,(i//2)*360))
    overview.save(OUT/'four_phases_1x.png')
    overview.resize((2560,1440),Image.Resampling.NEAREST).save(OUT/'four_phases_2x.png')
    (OUT/'checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
    print(json.dumps(checks))


if __name__=='__main__':build()
