"""Extract the existing complete ship silhouette, without repainting RGB pixels."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]

def main():
 im=Image.open(ROOT/'assets/new_ui/duo_campaign_material.png').convert('RGB')
 bg={(10,22,34),(13,27,42)}
 points={(x,y) for y in range(48,128) for x in range(232,440) if im.getpixel((x,y)) not in bg}
 groups=[]
 while points:
  p=points.pop();pending=[p];group={p}
  while pending:
   x,y=pending.pop()
   for dx,dy in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
    q=(x+dx,y+dy)
    if q in points:points.remove(q);group.add(q);pending.append(q)
  groups.append(group)
 ship=max(groups,key=len)
 # Retain isolated ship contour pixels; exclude separate plaque-edge pieces.
 for group in groups:
  if len(group)<20 and all(232<x<439 and 48<y<127 for x,y in group):ship.update(group)
 assert len(ship)>7000 and min(x for x,y in ship)<240 and max(x for x,y in ship)>430
 (ROOT/'Tetris.srcs/sources_1/new/ui_ship_mask.mem').write_text(''.join('1\n' if (x,y) in ship else '0\n' for y in range(48,128) for x in range(232,440)),'ascii')
 (ROOT/'assets/new_ui/ship_mask.json').write_text(json.dumps({'source':'duo_campaign_material.png','source_rect':[232,48,440,128],'destination':[336,288],'visible_pixels':len(ship),'rgb':'unchanged header atlas lookup'},indent=2)+'\n','utf-8')
 print('COMPLETE_SHIP_MASK_READY',len(ship))
if __name__=='__main__':main()
