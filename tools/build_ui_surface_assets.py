"""Shared cool-steel frame finish and a continuous native-size pipe groove."""
from pathlib import Path
from PIL import Image
import json,math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/new_ui/surfaces'
RAMP=[(20,37,52),(49,75,95),(58,80,100),(82,108,128),(96,125,145),(179,200,216)]
PANELS=[(143,148,298,320),(959,148,1114,320),(154,332,294,506)]

def steel(c):
 r,g,b=c[:3]
 if not(18<=r<=150 and 0<g-r<50 and 3<b-g<60 and g<180):return tuple(c[:3])
 anchors=[(22,(10,22,34))]+[(c[1],c) for c in RAMP]
 for (g0,c0),(g1,c1) in zip(anchors,anchors[1:]):
  if g<=g1:
   return tuple(max(0,min(255,c0[i]+(c1[i]-c0[i])*(g-g0)//(g1-g0))) for i in range(3))
 return tuple(c[:3])

def main():
 OUT.mkdir(parents=True,exist_ok=True)
 original_mask=Image.open(ROOT/'assets/reference_ui/pipe_removal_mask.png').convert('L')
 original={n:Image.open(ROOT/f'assets/new_ui/{n}_material.png').convert('RGB') for n in ['duo_campaign','solo_campaign','duo_endless']}
 ship=[int(v,16) for v in (ROOT/'Tetris.srcs/sources_1/new/ui_ship_mask.mem').read_text('ascii').split()]
 changes={};transparent=[]
 for name,base in original.items():
  im=base.convert('RGBA')
  if name=='duo_campaign':
   for y in range(148,320):
    for x in range(959,1114):
     if original_mask.getpixel((x,y)):im.putpixel((x,y),(*original['duo_endless'].getpixel((x,y)),255))
  for x0,y0,x1,y1 in PANELS+[(156,32,1049,128)]:
   header=y0==32
   for y in range(y0,y1):
    for x in range(x0,x1):
     dx=min(x-x0,x1-1-x);dy=min(y-y0,y1-1-y)
     if dx+dy<16:
      im.putpixel((x,y),(0,0,0,0))
      if name=='duo_campaign':transparent.append([x,y])
     elif not header or dx<14 or dy<9:
      if header and 232<=x<440 and 48<=y<128 and ship[(y-48)*208+x-232]:continue
      im.putpixel((x,y),(*steel(im.getpixel((x,y))),255))
  # Inlet collar matches the header finish, without recoloring orange/glass.
  for y in range(32,128):
   for x in range(1049,1064):im.putpixel((x,y),(*steel(im.getpixel((x,y))),255))
  changes[name]=[[x,y,list(base.getpixel((x,y))),list(im.getpixel((x,y))[:3])] for y in range(32,506) for x in range(143,1114) if im.getpixel((x,y))[3] and im.getpixel((x,y))[:3]!=base.getpixel((x,y))]
  im.save(OUT/(name+'.png'))
 # The old source was itself covered by the side panel. Clone an intact
 # seven-pixel groove profile; continue it around the lower quarter elbow.
 pipe=original['solo_campaign'].copy();visibility=original_mask.copy()
 profile=[steel(pipe.getpixel((x,140))) for x in range(1103,1110)]
 repaired=[]
 for y in range(148,342):
  for x in range(1103,1155):
   if original_mask.getpixel((x,y)):continue
   offset=None
   if y<310 and x<1110:offset=x-1103
   elif y>=310 and x<=1133:
    radius=math.isqrt((x-1133)**2+(y-310)**2)
    if 24<=radius<=30:offset=30-radius
   elif x>1133 and 333<=y<340:offset=339-y
   if offset is not None:
    pipe.putpixel((x,y),profile[max(0,min(6,offset))]);visibility.putpixel((x,y),255);repaired.append([x,y])
 for y in range(32,342):
  for x in range(1049,1155):
   if visibility.getpixel((x,y)) or (x<1064 and y<128):pipe.putpixel((x,y),steel(pipe.getpixel((x,y))))
 # Restore the complete axis-aligned glass coupling and tube cross-section.
 # The baked P2 chamfer had overwritten x1110..1113, including the bright
 # left pipe edge, from y148 down to y183. Never clone a panel fragment.
 glass=[pipe.getpixel((x,145)) for x in range(1110,1129)]
 orange=[pipe.getpixel((x,220)) for x in range(1110,1129)]
 collar=[pipe.getpixel((1114,y)) for y in range(151,157)]
 for y in range(148,184):
  for x in range(1110,1129):
   if y<151:c=glass[x-1110]
   elif y<157:
    c=collar[y-151]
    if x in (1110,1128):c=(10,17,24)
    elif x in (1111,1127):c=steel((47,73,92))
   else:c=orange[x-1110]
   pipe.putpixel((x,y),c);visibility.putpixel((x,y),255)
   repaired.append([x,y])
 pipe.save(OUT/'pipe.png');visibility.save(OUT/'pipe_visibility.png')
 (OUT/'changes.json').write_text(json.dumps({'rgb_changes':changes,'transparent_corners':transparent,'repaired_groove_pixels':repaired,'steel_ramp':RAMP},separators=(',',':'))+'\n','utf-8')
 for name,radius in [('large',96),('moon',40)]:
  (ROOT/f'Tetris.srcs/sources_1/new/ui_planet_{name}.mem').write_text(''.join(f'{math.isqrt(radius*radius-y*y):02x}\n' for y in range(radius+1)),'ascii')
 print('SURFACE_STYLE_READY','groove',len(repaired),'corners',len(transparent))
if __name__=='__main__':main()
