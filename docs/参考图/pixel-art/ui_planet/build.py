"""Authoring source; normal FPGA builds compile the checked-in master PNG.

This authoring script uses the local pixel-art-studio skill, not a runtime or
FPGA-build dependency. Set PIXELSTUDIO_PATH on another authoring machine.
"""
from pathlib import Path
import os,sys,math,json,argparse
sys.path.insert(0,os.environ.get('PIXELSTUDIO_PATH','C:/Users/qiguidie/.codex/skills/pixel-art-studio/scripts'))
from pixelstudio import Sprite
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
DARK='#091425'
SEA=['#0d233d','#163e60','#256087','#4488a6']
LAND=['#0e3537','#234b53','#397377','#6ba49d']
CLOUD=['#20354c','#3e596f','#608195','#91b2bf','#c2dade']
ATM='#66b2ca'
COLORS=[DARK]+SEA+LAND+CLOUD+[ATM]

def main():
 p=argparse.ArgumentParser();p.add_argument('--pass-number',type=int,default=2);a=p.parse_args()
 land=Sprite(128,64,palette=['#ffffff'])
 land.polygon([(35,8),(49,5),(61,12),(59,19),(64,24),(60,30),(68,34),(63,40),(56,39),(53,30),(45,25),(39,18)],'#ffffff')
 land.polygon([(83,26),(94,21),(105,27),(110,37),(99,44),(90,42),(88,33),(80,32)],'#ffffff')
 land.polygon([(55,48),(68,45),(77,51),(80,60),(68,63),(57,59),(50,55)],'#ffffff')
 for x,y in [(71,30),(74,33),(70,38),(78,40)]:land.rect(x,y,x+2,y+1,'#ffffff')
 land.polygon([(53,21),(58,22),(59,26),(55,27),(53,25)],None)
 land.polygon([(61,32),(66,33),(64,37),(61,35)],None)
 clouds=Sprite(128,64,palette=['#ffffff'])
 clouds.polygon([(28,16),(38,14),(45,16),(51,15),(55,18),(52,20),(43,19),(36,21),(28,20)],'#ffffff')
 clouds.polygon([(55,16),(62,17),(68,20),(74,22),(72,24),(64,22),(59,21)],'#ffffff')
 clouds.polygon([(39,37),(46,34),(51,35),(55,39),(62,41),(60,43),(51,41),(44,41)],'#ffffff')
 clouds.polygon([(65,42),(74,40),(84,43),(82,45),(73,44),(68,45)],'#ffffff')
 clouds.polygon([(78,8),(91,9),(96,13),(89,16),(82,13)],'#ffffff')
 planet=Sprite(64,64,palette=COLORS)
 for y in range(64):
  for x in range(64):
   nx=(x-31.5)/30;ny=(y-31.5)/30;r2=nx*nx+ny*ny
   if r2>1:continue
   nz=math.sqrt(1-r2);light=max(0,-.58*nx-.38*ny+.58*nz)
   u=int(64+math.atan2(nx,nz)*128/(2*math.pi));v=int(32+math.asin(ny)*64/math.pi)
   u=max(0,min(127,u));v=max(0,min(63,v))
   if light<.11:color=DARK
   elif clouds.get(u,v):color=CLOUD[min(4,int((light-.11)*5.2))]
   elif land.get(u,v):color=LAND[min(3,int((light-.11)*4.8))]
   else:color=SEA[min(3,int((light-.11)*4.8))]
   if r2>.94:
    color=ATM if light>.28 else SEA[0] if light>.09 else DARK
   planet.px(x,y,color)
 out=HERE/f'pass_{a.pass_number}';out.mkdir(exist_ok=True)
 planet.save_png(out/'planet.png');planet.save_png(out/'preview.png',scale=6,bg='#070d15')
 planet.save_silhouette(out/'silhouette.png')
 stats=planet.stats(print_=False)
 (out/'stats.json').write_text(json.dumps(stats,ensure_ascii=False,indent=2,default=str)+'\n','utf-8')
 print('PLANET_ART_PASS',a.pass_number)
if __name__=='__main__':main()
