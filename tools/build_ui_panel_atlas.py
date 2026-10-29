"""Build the A2 shared NEXT/P2/HOLD atlas from reviewed near-color material.

No resizing or redrawing. Three panels, including two P2 mode variants, share
one tile dictionary/color table. Existing frozen reference PNGs stay unchanged.
"""
from pathlib import Path
import hashlib,json
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/new_ui/panels'
SRC=ROOT/'Tetris.srcs/sources_1/new'

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    image=Image.open(ROOT/'assets/new_ui/duo_campaign_material.png').convert('RGB')
    endless=Image.open(ROOT/'assets/new_ui/duo_endless_material.png').convert('RGB')
    rectangles=[(143,148,298,320),(959,148,1114,320),(154,332,294,506),(959,148,1114,320)]
    tiles=[];tile_ids={};maps=[];colors=[];color_ids={};sprites=[]
    for name,r in zip(['p1_next','p2_next','hold','p2_next_endless'],rectangles):
        sprite=(endless if name=='p2_next_endless' else image).crop(r)
        padded=Image.new('RGB',(160,176));padded.paste(sprite,(0,0))
        sprite.save(OUT/(name+'.png'))
        used=set()
        for y in range(0,176,8):
            for x in range(0,160,8):
                values=[]
                for color in padded.crop((x,y,x+8,y+8)).getdata():
                    if color not in color_ids:color_ids[color]=len(colors);colors.append(color)
                    values.append(color_ids[color])
                key=tuple(values)
                if key not in tile_ids:tile_ids[key]=len(tiles);tiles.append(key)
                maps.append(tile_ids[key])
                used.add(tile_ids[key])
        sprites.append({'name':name,'origin':[r[0],r[1]],'size':sprite.size,
          'unique_tile_count':len(used),
          'decoded_rgb_sha256':hashlib.sha256(sprite.tobytes()).hexdigest()})
    tile_bits=max(1,(len(tiles)-1).bit_length());color_bits=max(1,(len(colors)-1).bit_length())
    palette=json.loads((ROOT/'assets/new_ui/palette.json').read_text('utf-8'))['palette_rgb']
    assert len(palette)<=2048, 'Global palette exceeds 11-bit interface; widen the interface instead of truncating colors'
    global_ids={tuple(c):i for i,c in enumerate(palette)}
    assert all(c in global_ids for c in colors)
    def write(name,values,width):
        (SRC/name).write_text(''.join(f'{v:0{(width+3)//4}x}\n' for v in values),'ascii')
    write('ui_panel_map.mem',maps,tile_bits)
    write('ui_panel_pixels.mem',[c for tile in tiles for c in tile],color_bits)
    write('ui_panel_palette.mem',[(global_ids[c]<<24)|(c[0]<<16)|(c[1]<<8)|c[2] for c in colors],35)
    header=['// A2 generated shared material atlas; visual data only.',
      f'localparam PANEL_TILES={len(tiles)}, PANEL_COLORS={len(colors)};',
      f'localparam PANEL_TILE_BITS={tile_bits}, PANEL_COLOR_BITS={color_bits};']
    (SRC/'ui_panel_geometry.vh').write_text('\n'.join(header)+'\n','ascii')
    metadata={'sprites':sprites,'padded_sprite_size':[160,176],'map_stride':20,
      'unique_tiles':len(tiles),'local_colors':len(colors),'tile_bits':tile_bits,'color_bits':color_bits,
      'global_color_code_bits':11,'map_words':len(maps),'pixel_words':len(tiles)*64,
      'rom_capacity_bits':len(maps)*tile_bits+len(tiles)*64*color_bits+len(colors)*35,
      'files_sha256':{n:hashlib.sha256((SRC/n).read_bytes()).hexdigest() for n in ['ui_panel_map.mem','ui_panel_pixels.mem','ui_panel_palette.mem','ui_panel_geometry.vh']}}
    (OUT/'manifest.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n','utf-8')
    print('A2_SHARED_PANELS_READY',len(tiles),'TILES',len(colors),'COLORS',metadata['rom_capacity_bits'],'BITS')

if __name__=='__main__':main()
