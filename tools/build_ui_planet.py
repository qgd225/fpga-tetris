"""Lossless 4-bit compilation of the reviewed native pixel-art planet."""
from pathlib import Path
from PIL import Image
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]

def main():
 path=ROOT/'assets/new_ui/blue_planet.png';im=Image.open(path).convert('RGBA')
 assert im.size==(64,64)
 pixels=list(im.getdata());assert all(c[3] in (0,255) for c in pixels)
 colors=sorted({c[:3] for c in pixels if c[3]});assert len(colors)<=15
 codes={c:i+1 for i,c in enumerate(colors)};pal=[(0,0,0)]+colors
 pal += [(0,0,0)]*(16-len(pal))
 indices=[codes[c[:3]] if c[3] else 0 for c in pixels]
 src=ROOT/'Tetris.srcs/sources_1/new'
 (src/'ui_planet_pixels.mem').write_text(''.join(f'{q:x}\n' for q in indices),'ascii')
 (src/'ui_planet_palette.mem').write_text(''.join(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in pal),'ascii')
 decoded=[(*pal[q],255) if q else (0,0,0,0) for q in indices]
 assert all(d==p if p[3] else d[3]==0 for d,p in zip(decoded,pixels))
 (ROOT/'assets/new_ui/planet.json').write_text(json.dumps({'source':'blue_planet.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'size':[64,64],'display_scale':2,'display_origin':[-24,16],'visible_colors':len(colors),'index_bits':4,'ROM_bits':4096*4+16*24,'decoded_pixels_verified':4096,'storage':'distributed ROM; no new BRAM'},indent=2)+'\n','utf-8')
 print('PIXEL_PLANET_COMPILED',len(colors),'COLORS 4096 PIXELS VERIFIED')
 # A shared, tiny 3-bit rock sprite; no additional block RAM.
 rock_path=ROOT/'assets/new_ui/asteroid.png';rock=Image.open(rock_path).convert('RGBA')
 assert rock.size==(32,32)
 rp=list(rock.getdata());assert all(c[3] in (0,255) for c in rp)
 rc=sorted({c[:3] for c in rp if c[3]});assert len(rc)<=7
 table=[(0,0,0)]+rc;table += [(0,0,0)]*(8-len(table));codes={c:i+1 for i,c in enumerate(rc)}
 ids=[codes[c[:3]] if c[3] else 0 for c in rp]
 (src/'ui_asteroid_pixels.mem').write_text(''.join(f'{q:x}\n' for q in ids),'ascii')
 (src/'ui_asteroid_palette.mem').write_text(''.join(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in table),'ascii')
 assert all(((*table[q],255)==p) if p[3] else q==0 for q,p in zip(ids,rp))
 (ROOT/'assets/new_ui/asteroid.json').write_text(json.dumps({'source':'asteroid.png','sha256':hashlib.sha256(rock_path.read_bytes()).hexdigest(),'size':[32,32],'visible_colors':len(rc),'ROM_bits':1024*3+8*24,'decoded_pixels_verified':1024,'storage':'distributed ROM; no new BRAM'},indent=2)+'\n','utf-8')
 print('PIXEL_ASTEROID_COMPILED',len(rc),'COLORS 1024 PIXELS VERIFIED')

if __name__=='__main__':main()
