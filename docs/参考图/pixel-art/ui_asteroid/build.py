"""Native background rock; authoring only, normal builds use the master PNG."""
from pathlib import Path
import os,sys,json,argparse
sys.path.insert(0,os.environ.get('PIXELSTUDIO_PATH','C:/Users/qiguidie/.codex/skills/pixel-art-studio/scripts'))
from pixelstudio import Sprite
HERE=Path(__file__).resolve().parent
COLORS=['#0d1b2b','#1c3045','#2c455b','#405e75','#607f94','#93acb9']
def main():
 p=argparse.ArgumentParser();p.add_argument('--pass-number',type=int,default=2);a=p.parse_args()
 s=Sprite(32,32,palette=COLORS)
 s.polygon([(5,7),(12,3),(20,4),(23,8),(27,9),(29,17),(26,24),(21,28),(13,29),(8,25),(5,24),(2,16)],COLORS[0])
 s.polygon([(6,8),(13,4),(20,5),(22,9),(26,10),(27,17),(23,21),(17,22),(8,22),(4,16)],COLORS[2])
 s.polygon([(6,8),(13,4),(20,5),(18,11),(11,14),(4,16)],COLORS[4])
 s.polygon([(13,5),(18,5),(16,8),(10,10),(7,10)],COLORS[5])
 s.polygon([(20,6),(22,10),(26,11),(26,16),(20,19),(17,15),(18,11)],COLORS[3])
 s.polygon([(5,17),(11,15),(17,16),(16,22),(12,26),(8,23)],COLORS[3])
 s.polygon([(18,18),(24,19),(24,23),(20,27),(14,27),(16,23)],COLORS[1])
 s.polygon([(10,11),(14,10),(16,12),(15,16),(11,17),(8,15)],COLORS[1])
 s.polygon([(11,11),(14,11),(14,13),(11,14),(10,13)],COLORS[0])
 s.line(9,16,11,17,COLORS[4])
 s.line(19,8,19,12,COLORS[1]);s.line(19,12,17,15,COLORS[1])
 if a.pass_number>=2:
  # Break the long bright facet into a blunt chipped ridge and deepen the
  # far-side split, avoiding a shiny metal reading on the first pass.
  s.polygon([(6,9),(9,8),(10,10),(8,12),(6,12)],COLORS[3])
  s.polygon([(21,20),(24,19),(26,18),(25,22),(23,24)],COLORS[0])
  s.line(12,23,15,21,COLORS[1])
 out=HERE/f'pass_{a.pass_number}';out.mkdir(exist_ok=True)
 s.save_png(out/'asteroid.png');s.save_png(out/'preview.png',scale=8,bg='#070d15');s.save_silhouette(out/'silhouette.png')
 (out/'stats.json').write_text(json.dumps(s.stats(print_=False),indent=2,default=str)+'\n','utf-8')
 print('ASTEROID_PASS',a.pass_number)
if __name__=='__main__':main()
