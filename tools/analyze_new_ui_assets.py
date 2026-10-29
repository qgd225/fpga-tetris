"""A1 lossless asset audit and reproducible standalone texture-ROM inputs.

Writes analysis/prototype data under temporary unless --output is given.
Does not replace frozen references, gameplay HDL, the project or the bitstream.
"""
from pathlib import Path
from collections import Counter
import argparse,hashlib,json,math,re,zlib
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
NAMES=['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']
PROTECTED=[(156,32,1064,128),(143,148,298,320),(154,332,294,506),
 (959,148,1114,354),(1124,214,1214,570),(1049,48,1155,339),
 (972,364,1108,612),(1114,618,1210,660),(466,640,880,689),
 (328,132,352,632),(928,132,952,632),(328,132,952,144),(328,624,952,632)]

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def words(path,values,bits):
    path.write_text(''.join(f'{v:0{(bits+3)//4}x}\n' for v in values),encoding='ascii')
def pow2(n):return 1<<max(1,(n-1).bit_length())

def tile_cost(images,n=8):
    tiles=set();entries=0
    for im in images:
        for y in range(0,im.height,n):
            for x in range(0,im.width,n):
                tiles.add(im.crop((x,y,x+n,y+n)).tobytes());entries+=1
    histogram=Counter();palette_bits=0
    for tile in tiles:
        count=len(set(zip(tile[::3],tile[1::3],tile[2::3])))
        bits=(count-1).bit_length();histogram[bits]+=1
        palette_bits+=bits*n*n+count*24
    map_bits=entries*(len(tiles)-1).bit_length()
    return {'tile_size':n,'unique_tiles':len(tiles),'map_entries':entries,
      'packed_map_bits':map_bits,'packed_local_palette_bits':palette_bits,
      'packed_total_bits':map_bits+palette_bits,
      'capacity_only_bram36_lower_bound':math.ceil((map_bits+palette_bits)/36864),
      'local_index_bits_histogram':dict(sorted(histogram.items())),
      'note':'algorithm cost only; BRAM port/width packing and decoder are not included'}

def encode_texture(im,folder,name,origin):
    folder.mkdir(parents=True,exist_ok=True)
    w,h=im.size;pw=(w+7)//8*8;ph=(h+7)//8*8
    padded=Image.new('RGB',(pw,ph));padded.paste(im,(0,0))
    colors=sorted(set(padded.getdata()));color_ids={c:i for i,c in enumerate(colors)}
    tiles=[];ids={};tilemap=[]
    for y in range(0,ph,8):
        for x in range(0,pw,8):
            tile=tuple(color_ids[c] for c in padded.crop((x,y,x+8,y+8)).getdata())
            if tile not in ids:ids[tile]=len(tiles);tiles.append(tile)
            tilemap.append(ids[tile])
    tile_count=pow2(len(tiles));color_count=pow2(len(colors))
    tile_bits=(tile_count-1).bit_length();color_bits=(color_count-1).bit_length()
    pixels=[v for tile in tiles for v in tile]+[0]*((tile_count-len(tiles))*64)
    palette=[r*65536+g*256+b for r,g,b in colors]+[0]*(color_count-len(colors))
    words(folder/'map.mem',tilemap,tile_bits);words(folder/'pixels.mem',pixels,color_bits)
    words(folder/'palette.mem',palette,24)
    # Software decoder is an encoder sanity check, separate from RTL verification.
    decoded=Image.new('RGB',(w,h));q=decoded.load()
    for y in range(h):
        for x in range(w):
            tid=tilemap[(y//8)*(pw//8)+x//8]
            q[x,y]=colors[pixels[tid*64+(y%8)*8+x%8]]
    assert decoded.tobytes()==im.tobytes()
    words(folder/'expected.mem',[r*65536+g*256+b for r,g,b in im.getdata()],24)
    im.save(folder/'expected.png')
    info={'name':name,'size':[w,h],'origin':origin,'unique_tiles':len(tiles),
      'unique_colors':len(colors),'tile_words':tile_count,'palette_words':color_count,
      'tile_bits':tile_bits,'color_bits':color_bits,'map_words':len(tilemap),
      'allocated_rom_bits':len(tilemap)*tile_bits+len(pixels)*color_bits+len(palette)*24,
      'software_roundtrip_mismatches':0,'expected_rgb_sha256':hashlib.sha256(im.tobytes()).hexdigest(),
      'files_sha256':{f.name:sha(f) for f in folder.glob('*.mem')}}
    (folder/'metadata.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n','utf-8')
    wrapper=f'''module ui_a1_{name}_measure(input clk,reset_n,input [10:0] x,y,output [23:0] rgb,output valid);
ui_exact_tile_rom #(.WIDTH({w}),.HEIGHT({h}),.TILE_COUNT({tile_count}),.COLOR_COUNT({color_count}),
 .MAP_FILE("{(folder/'map.mem').as_posix()}"),.PIXEL_FILE("{(folder/'pixels.mem').as_posix()}"),
 .PALETTE_FILE("{(folder/'palette.mem').as_posix()}")) decoder(.clk(clk),.reset_n(reset_n),.x(x),.y(y),.rgb(rgb),.valid(valid));
endmodule
'''
    (folder/'measure.v').write_text(wrapper,'ascii')
    return info

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=ROOT/'temporary/new_ui_a1')
    parser.add_argument('--input-materials',type=Path,default=ROOT/'assets/reference_ui')
    args=parser.parse_args();source=args.input_materials.resolve();out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
    images=[Image.open(source/f'{n}_material.png').convert('RGB') for n in NAMES]
    summary={'date':'2026-10-28','scope':'A1 asset/transport audit and standalone lossless texture prototype; not an integrated UI build',
      'source_sha256':{str((source/f'{n}_material.png').relative_to(ROOT)):sha(source/f'{n}_material.png') for n in NAMES},
      'scene_statistics':[],'lossless_schemes':[],'protected_probe':{'rectangles':PROTECTED,'note':'capacity probe only, not an approved cut UI or proof of optimal compression'}}
    for name,im in zip(NAMES,images):
        colors=Counter(im.getdata());data=list(im.getdata())
        runs=sum(x==0 or data[y*1280+x]!=data[y*1280+x-1] for y in range(720) for x in range(1280))
        summary['scene_statistics'].append({'name':name,'colors':len(colors),'row_runs':runs,
          'deflate_rgb_bytes':len(zlib.compress(im.tobytes(),9)),
          'note':'software DEFLATE is a comparison, not a hardware memory/throughput claim'})
    for n in [4,8,16,32]:summary['lossless_schemes'].append(tile_cost(images,n))
    probe=[]
    for im in images:
        c=Image.new('RGB',im.size,'#091722')
        for r in PROTECTED:c.paste(im.crop(r),(r[0],r[1]))
        probe.append(c)
    summary['protected_probe']['cost']=tile_cost(probe,8)
    # Exercise the same generic ROM with noisy source texture and clean mechanical art.
    summary['prototypes']=[encode_texture(images[0].crop(r),out/name,name,[r[0],r[1]])
      for name,r in [('next',(143,148,298,320)),('core',(1124,214,1214,570))]]
    paltext=(ROOT/'Tetris.srcs/sources_1/new/story_palette.vh').read_bytes().decode('gbk')
    palette={int(i):int(v,16) for i,v in re.findall(r"6'd(\d+):\s*story_palette=24'h([0-9a-fA-F]{6})",paltext)}
    transport=(ROOT/'Tetris.srcs/sources_1/new/rgb_to_palette.v').read_bytes().decode('gbk')
    rom=[0]*256
    for h,c in re.findall(r"rom\[8'h([0-9a-fA-F]+)\]\s*=\s*6'd(\d+)",transport):rom[int(h,16)]=int(c)
    bits=[22,21,20,19,17,9,2,0]
    pcstats=[]
    for name,im in zip(NAMES,images):
        cache={};mismatches=0
        for rgb,n in Counter(im.getdata()).items():
            v=rgb[0]*65536+rgb[1]*256+rgb[2]
            index=sum(((v>>b)&1)<<(7-i) for i,b in enumerate(bits))
            mapped=palette[rom[index]]
            if mapped!=v:mismatches+=n
        pcstats.append({'name':name,'pixels':1280*720,'rgb_mismatches':mismatches,
          'exact_ratio':(1280*720-mismatches)/(1280*720)})
    summary['transport_audit']={'protocol_palette_size':56,'code_bits':6,
      'mapper':'current generated bit projection; collision-free only for original palette',
      'source_files':{'rgb_to_palette.v':sha(ROOT/'Tetris.srcs/sources_1/new/rgb_to_palette.v'),
        'net_screen_tx.v':sha(ROOT/'Tetris.srcs/sources_1/new/net_screen_tx.v')},
      'rgb_comparison':pcstats,'protocol_changed':False}
    (out/'analysis.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n','utf-8')
    print('A1_ASSET_AUDIT_READY')
    for p in summary['prototypes']:print('PROTOTYPE',p['name'],p['unique_tiles'],p['unique_colors'],p['allocated_rom_bits'])
    for item in pcstats:print('CURRENT_PC_RGB_MISMATCHES',item['name'],item['rgb_mismatches'])

if __name__=='__main__':main()
