"""CORE-07 exterior EVA repair study. Original pixel drawing; no RTL changes."""
from pathlib import Path
from contextlib import redirect_stdout
from io import StringIO
import importlib.util
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0,str(Path.home()/'.codex/skills/pixel-art-studio/scripts'))
from pixelstudio import Sprite
from PIL import Image

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'out'
OUT.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location('core07_pixel_helpers',ROOT.parent/'core07-rescue-v5/build.py')
old=importlib.util.module_from_spec(spec)
spec.loader.exec_module(old)
C=dict(old.C)
C.update({'space':'#22334f','hull':'#bdcfdf','hullshade':'#8da5bd','cold':'#314c67','warm':'#ffe5b5'})
old.C=C
PALETTE=list(dict.fromkeys(old.PALETTE+list(C.values())))
text,rect,line,frame,block,piece=old.text,old.rect,old.line,old.frame,old.block,old.piece
PHASES=[
    ('01 RECONNECT',3,2,'Core link established.','The housing is damaged.'),
    ('02 REBUILD',11,4,'Fragments are aligning.','Keep the bypass steady.'),
    ('03 STABILIZE',23,6,'Containment is holding.','Keep feeding the core.'),
    ('04 RECHARGE',35,8,'Final chamber charging.','Hold it steady.'),
]


def backdrop(s):
    rect(s,0,0,640,360,'space')
    for x,y in [(7,26),(129,14),(309,17),(380,53),(404,24),(454,65),(630,23),(626,145),(15,121),(470,92)]:
        rect(s,x,y,1,1,'dim')
    # One solar-system planet is a quiet far view, not a dense planet collage.
    s.polygon([(550,15),(573,15),(582,24),(582,41),(573,50),(550,50),(541,41),(541,24)],C['planet'])
    s.polygon([(550,15),(573,15),(577,19),(552,19),(546,25),(543,34),(541,34),(541,24)],C['planetlit'])
    line(s,522,44,600,24,'dim');line(s,524,47,603,27,'dim')
    # A tiny sun and orbit cue establish a solar-system navigation motif.
    rect(s,139,24,5,5,'warm');line(s,136,26,146,26,'amber');line(s,141,21,141,31,'amber')
    line(s,22,57,124,57,'dim')
    for x in [39,62,89,119]:rect(s,x,55,3,3,'planet')
    # The player is on the EXTERIOR hull: open space above, a small number of hull planes below.
    s.polygon([(0,143),(110,143),(160,177),(177,177),(177,360),(0,360)],C['hull'])
    s.polygon([(640,143),(530,143),(480,177),(463,177),(463,360),(640,360)],C['hull'])
    s.polygon([(0,335),(145,310),(495,310),(640,335),(640,360),(0,360)],C['hullshade'])
    for pts in [[(0,201),(98,201),(149,235),(169,235)],[(640,201),(542,201),(491,235),(471,235)],[(8,356),(146,332),(494,332),(632,356)]]:
        for a,b in zip(pts,pts[1:]):line(s,*a,*b,'edge')
    line(s,18,153,107,153,'light');line(s,533,153,622,153,'light')
    for x,y in [(17,215),(620,215),(23,316),(614,316)]:
        rect(s,x,y,4,2,'edge')


def core(s,phase,success=False):
    cx=552
    # Repair aperture and a broad-footed pedestal: it reads as a real device on the hull.
    s.polygon([(508,158),(593,158),(604,169),(604,302),(593,313),(508,313),(497,302),(497,169)],C['edge'])
    s.polygon([(510,162),(590,162),(600,172),(600,300),(590,309),(510,309),(501,300),(501,172)],C['sky'])
    rect(s,507,144,96,12,'hull')
    text(s,515,146,'ENERGY CORE','ink',9)
    # Suspended stem and split external supports are more distinctive than a plain bar.
    rect(s,cx-14,174,28,118,'cold')
    rect(s,cx-18,173,3,120,'edge');rect(s,cx+16,173,3,120,'edge')
    lit=8 if success else phase*2+1
    for i in range(8):
        y=278-i*14
        col='mint' if success else ('cyan' if i<lit else 'cold')
        if i==lit and not success:col='amber' if phase==0 else 'warm'
        s.polygon([(cx-4,y),(cx+4,y),(cx+7,y+3),(cx+7,y+9),(cx+4,y+12),(cx-4,y+12),(cx-7,y+9),(cx-7,y+3)],C[col])
        if i<lit or success:rect(s,cx-1,y+3,2,6,'white')
    if phase==3 or success:
        rect(s,cx-1,176,2,113,'mint' if success else 'cyan')
    # Four broad collars make the silhouette cylindrical but articulated.
    for j,y in enumerate([181,215,249,287]):
        offset=3 if phase==0 and j<2 else 0
        closed=success or phase>=2 or (phase==1 and j>=2)
        color='mint' if success else ('cyan' if closed else 'dim')
        if closed:
            s.polygon([(cx-26,y+3),(cx-18,y-1),(cx+18,y-1),(cx+26,y+3),(cx+18,y+7),(cx-18,y+7)],C['edge'])
            line(s,cx-21,y+2,cx+21,y+2,color)
            line(s,cx-18,y+6,cx+18,y+6,'planetlit')
        else:
            line(s,cx-27-offset,y+3,cx-15-offset,y,color)
            line(s,cx-27-offset,y+3,cx-15-offset,y+7,'edge')
            line(s,cx+15+offset,y,cx+27+offset,y+3,color)
            line(s,cx+15+offset,y+7,cx+27+offset,y+3,'edge')
    # Two pairs of chamfered shell segments. Early stages show a visibly displaced panel.
    for side in [-1,1]:
        for j,y in enumerate([192,254]):
            extra=5 if phase==0 and side==-1 and j==0 else (2 if phase==1 and j==0 else 0)
            x=cx+side*(24+extra)
            p=[(x,y),(x+side*9,y+5),(x+side*9,y+23),(x,y+28),(x-side*3,y+23),(x-side*3,y+5)]
            s.polygon(p,C['hullshade'])
            line(s,x,y+1,x+side*7,y+5,'light')
    s.polygon([(cx-25,170),(cx-15,162),(cx+15,162),(cx+25,170),(cx+18,175),(cx-18,175)],C['hull'])
    s.polygon([(cx-30,299),(cx+30,299),(cx+39,308),(cx-39,308)],C['hullshade'])
    line(s,cx-32,304,cx+32,304,'light')
    if phase==0:
        line(s,cx-34,200,cx-40,207,'red');rect(s,cx-43,210,3,3,'amber')
    elif phase==1:
        line(s,cx-40,219,cx-33,226,'red');line(s,cx-33,219,cx-40,226,'red')
    if phase>=2 or success:
        # A few ordered energy connections replace decorative surface detail.
        line(s,478,321,498,321,'cyan');line(s,498,321,510,309,'cyan')
        for y in [199,233,267]:rect(s,cx+38,y,2,3,'mint' if success else 'cyan')
    text(s,515,316,'CORE ONLINE' if success else f'{lit}/8 LOCKED','ink',9)


def gloves(s):
    # First-person EVA gloves. They stay outside the field and are authored in a few planes.
    hand=[(110,359),(118,342),(133,336),(140,326),(151,318),(159,318),(163,323),(158,330),(165,337),(160,350),(153,359)]
    for mirrored in [False,True]:
        p=[(640-x if mirrored else x,y) for x,y in hand]
        s.polygon(p,C['light'])
        p2=[(110,359),(118,342),(127,344),(142,357),(145,359)]
        s.polygon([(640-x if mirrored else x,y) for x,y in p2],C['edge'])
        a,b=(640-121 if mirrored else 121),(640-144 if mirrored else 144)
        line(s,a,347,b,358,'cyan')
        a,b=(640-143 if mirrored else 143),(640-158 if mirrored else 158)
        line(s,a,334,b,340,'line')
        # Three short seams make the simplified silhouette read as a pressure glove.
        for yy,xa,xb in [(323,148,157),(328,146,153),(344,146,157)]:
            line(s,640-xa if mirrored else xa,yy,640-xb if mirrored else xb,yy+2,'line')
    # Safety tether; a single angular line is sufficient.
    for a,b in zip([(112,353),(80,350),(51,336),(18,335)],[(80,350),(51,336),(18,335),(0,342)]):line(s,*a,*b,'amber')


def scene(phase,dialog=False,success=False):
    s=Sprite(640,360,palette=PALETTE)
    backdrop(s)
    title,n,spd,a,b=PHASES[phase]
    text(s,20,17,'CORE-07','light',14)
    text(s,20,42,'EVA REPAIR','planetlit',9)
    text(s,176,25,'CORE RESTORED' if success else title,'light',12)
    text(s,176,55,f'SPD {spd}/8','planetlit',9)
    text(s,270,55,'40/40' if success else f'{n:02d}/40','light',9)
    # A suit-linked terminal held above the ship's repair surface.
    frame(s,172,80,296,248)
    rect(s,176,84,288,240,'board')
    for col in range(25):line(s,176+col*12,84,176+col*12,323,'grid')
    for row in range(21):line(s,176,84+row*12,463,84+row*12,'grid')
    line(s,174,84,174,323,'cyan');line(s,466,84,466,323,'pink')
    heights=[3,3,2,2,1,1,0,1,2,4,3,2,1,1,2,2,3,3,2,1,0,1,2,4]
    for col,h in enumerate(heights):
        for yy in range(h):block(s,176+col*12,84+(19-yy)*12,(col+yy*2)%7)
    piece(s,236,132,'I',0);piece(s,368,168,'S',4)
    piece(s,236,264,'I',0,True);piece(s,368,264,'S',4,True)
    for x,player,col,name,index in [(46,'P1','cyan','T',1),(510,'P2','pink','L',5)]:
        text(s,x,72,player,'light',10);text(s,x+59,72,'NEXT','light',10)
        frame(s,x,86,84,56);rect(s,x+4,90,76,48,'board')
        coords=old.SHAPES[name]
        pw=(max(p[0] for p in coords)+1)*12;ph=(max(p[1] for p in coords)+1)*12
        piece(s,x+(84-pw)//2,86+(56-ph)//2,name,index)
        line(s,x,82,x+10,82,col)
    text(s,46,160,'HOLD','ink',10)
    rect(s,81,162,5,4,'edge',False);rect(s,85,162,5,4,'edge',False)
    frame(s,46,172,84,52);rect(s,50,176,76,44,'board');piece(s,76,186,'O',2)
    # Exterior-panel details stay sparse and low contrast.
    text(s,38,264,'SUIT LINK','ink',9)
    for i in range(5):rect(s,40+i*13,280,8,2,'cyan' if i<=phase else 'edge')
    core(s,phase,success)
    text(s,185,335,'SCORE 001248','light',9);text(s,345,335,'03:24','light',9)
    gloves(s)
    if dialog:
        frame(s,420,8,212,52,'edge');rect(s,423,11,206,46,'light')
        text(s,430,14,'SHIP AI','edge',8)
        text(s,430,27,'Core stable.' if success else a,'ink',10)
        text(s,430,41,'Power restored.' if success else b,'ink',10)
        for i,h in enumerate([3,5,2,6,4]):rect(s,609+i*3,15-h,1,h,'cyan')
    return s


def save(s,path,scale=1):
    with redirect_stdout(StringIO()):s.save_png(str(path),scale=scale)


def build():
    images=[];checks=[]
    for phase in range(4):
        master=OUT/f'phase_{phase+1}_1x.png'
        save(scene(phase),master);save(scene(phase),OUT/f'phase_{phase+1}_2x.png',2)
        save(scene(phase,True),OUT/f'phase_{phase+1}_comms_2x.png',2)
        im=Image.open(master).convert('RGBA');images.append(im)
        colors=set(im.get_flattened_data());assert len(colors)<=64,len(colors)
        checks.append({'phase':phase+1,'colors':len(colors),'default_dialog':False})
    overview=Image.new('RGBA',(1280,720),C['space'])
    for i,im in enumerate(images):overview.paste(im,((i%2)*640,(i//2)*360))
    overview.save(OUT/'four_phases_1x.png')
    overview.resize((2560,1440),Image.Resampling.NEAREST).save(OUT/'four_phases_2x.png')
    save(scene(3,True,True),OUT/'success_comms_2x.png',2)
    (OUT/'checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
    print(json.dumps(checks))


if __name__=='__main__':build()
