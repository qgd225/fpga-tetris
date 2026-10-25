"""CORE-07 restrained technology profiles. Pixel concept only; no RTL changes."""
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
spec=importlib.util.spec_from_file_location('core07_eva_helpers',ROOT.parent/'core07-eva-v6/build.py')
eva=importlib.util.module_from_spec(spec);spec.loader.exec_module(eva)
C=eva.C
text,rect,line=eva.text,eva.rect,eva.line
SELECTED='C'


def render_core(s,phase,success=False,variant=None,cx=552,feed=True):
    variant=variant or SELECTED
    lit=8 if success else phase*2+1
    rect(s,cx-24,145,68,11,'hull')
    text(s,cx-12,147,'CORE','ink',9)
    # A narrow common energy channel and tiny contact pads anchor it to the hull.
    rect(s,cx-4,166,8,136,'sky')
    for i in range(8):
        y=284-i*16
        rect(s,cx-2,y,4,13,'mint' if success else ('cyan' if i<lit else 'cold'))
        if i<lit or success:rect(s,cx,y+1,1,11,'white')
        if i==lit and not success:rect(s,cx-2,y,4,3,'amber' if phase==0 else 'warm')
    for y in [160,302]:
        s.polygon([(cx-7,y+2),(cx-5,y),(cx+5,y),(cx+7,y+2),(cx+7,y+5),(cx-7,y+5)],C['edge'])
        line(s,cx-5,y+1,cx+4,y+1,'light')
    if variant=='A':
        # Candidate only: short repeated teeth, not a compulsory final motif.
        for side in [-1,1]:
            for i in range(17):
                y=168+i*8
                x=cx+side*9
                s.polygon([(x,y),(x+side*8,y+2),(x+side*3,y+5),(x,y+5)],C['edge'])
                if phase>=2:line(s,x,y,x+side*5,y+1,'planetlit')
    elif variant=='B':
        # Detached narrow guide scales, with deliberately open space between them.
        for side in [-1,1]:
            for i in range(8):
                y=168+i*16
                shift=3 if phase==0 and i<3 and side==-1 else 0
                x=cx+side*(10+shift)
                line(s,x,y+2,x,y+11,'edge')
                line(s,x,y+2,x+side*4,y-1,'planetlit')
                if i>=8-lit:rect(s,x+side*5,y+7,2,1,'cyan' if not success else 'mint')
    else:
        # Selected: two broken guide rails, thin energy spine and three offset couplers.
        for side in [-1,1]:
            for i in range(4):
                y=169+i*33
                shift=3 if phase==0 and side==-1 and i==0 else 0
                x=cx+side*(11+shift)
                line(s,x,y+3,x,y+27,'edge')
                line(s,x,y+3,x-side*3,y,'edge')
                line(s,x,y+27,x-side*3,y+30,'edge')
                if phase>=2 or i>=3-phase:line(s,x-side,y+9,x-side,y+18,'planetlit')
        for i,y in enumerate([182,231,280]):
            closed=success or phase>=2 or (phase==1 and i>=1)
            x=cx+(13 if i%2 else -13)
            rect(s,x-2,y,5,3,'edge')
            if closed:line(s,min(x,cx)-1,y+1,max(x,cx)+1,y+1,'cyan' if not success else 'mint')
        # A restrained lateral interface notch gives the core an engineered silhouette.
        line(s,cx+17,217,cx+23,217,'edge');line(s,cx+23,217,cx+23,232,'edge')
        rect(s,cx+21,223,3,3,'cyan' if phase>=2 else 'dim')
    if phase==0:
        line(s,cx-21,193,cx-17,197,'red')
        line(s,cx-17,193,cx-21,197,'red')
    if phase==3 or success:rect(s,cx,170,1,129,'mint' if success else 'white')
    if feed and phase>=2:
        line(s,480,315,cx-12,315,'edge');line(s,cx-12,315,cx-6,308,'edge')
        line(s,cx-4,310,cx-2,308,'cyan')
    label='ONLINE' if success else f'{lit}/8'
    text(s,cx-len(label)*3,315,label,'ink',9)


eva.core=render_core


def save(s,path,scale=1):
    with redirect_stdout(StringIO()):s.save_png(str(path),scale=scale)


def build():
    images=[];report=[]
    for phase in range(4):
        p=OUT/f'phase_{phase+1}_1x.png'
        save(eva.scene(phase),p)
        save(eva.scene(phase),OUT/f'phase_{phase+1}_2x.png',2)
        save(eva.scene(phase,True),OUT/f'phase_{phase+1}_comms_2x.png',2)
        im=Image.open(p).convert('RGBA');images.append(im)
        count=len(set(im.get_flattened_data()));assert count<=64
        report.append({'phase':phase+1,'colors':count,'default_dialog':False})
    overview=Image.new('RGBA',(1280,720),C['space'])
    for i,im in enumerate(images):overview.paste(im,((i%2)*640,(i//2)*360))
    overview.save(OUT/'four_phases_1x.png')
    overview.resize((2560,1440),Image.Resampling.NEAREST).save(OUT/'four_phases_2x.png')
    sheet=Sprite(640,360,palette=eva.PALETTE)
    rect(sheet,0,0,640,360,'hull')
    text(sheet,24,20,'CORE PROFILES','ink',14)
    text(sheet,24,45,'SAME CHARGE / 5 OF 8','edge',9)
    labels=[('A','FIN EDGE'),('B','FLOATING RAIL'),('C','DUAL SPINE')]
    for i,(variant,label) in enumerate(labels):
        x=120+i*200
        text(sheet,x-65,89,f'{variant} / {label}','ink',9)
        line(sheet,x-76,106,x+76,106,'line')
        render_core(sheet,2,variant=variant,cx=x,feed=False)
    save(sheet,OUT/'core_profiles_1x.png')
    save(sheet,OUT/'core_profiles_2x.png',2)
    save(eva.scene(3,True,True),OUT/'success_comms_2x.png',2)
    (OUT/'checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':build()
