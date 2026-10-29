"""A3 shared, lossless-to-reviewed-color material compiler.

One direct descriptor lookup, one 1/2/4/8-bpp pattern read, one local RGB
palette read. Palette sequences and patterns are shared independently.
"""
from pathlib import Path
from collections import defaultdict
import hashlib,json,math
from PIL import Image

ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'
OUT=ROOT/'assets/new_ui/materials'
VISIBLE=1<<24;FRONT=1<<25

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    camp=Image.open(ROOT/'assets/new_ui/duo_campaign_material.png').convert('RGB')
    solo_camp=Image.open(ROOT/'assets/new_ui/solo_campaign_material.png').convert('RGB')
    endless=Image.open(ROOT/'assets/new_ui/duo_endless_material.png').convert('RGB')
    mask=Image.open(ROOT/'assets/reference_ui/pipe_removal_mask.png').convert('L')
    raw=[int(v,16) for v in (SRC/'reference_ui_material.mem').read_text('ascii').split()]
    from build_ui_ship_mask import main as ship_mask_build
    from build_ui_surface_assets import main as surface_build
    ship_mask_build();surface_build()
    surface=ROOT/'assets/new_ui/surfaces'
    styled=Image.open(surface/'duo_campaign.png').convert('RGBA')
    styled_endless=Image.open(surface/'duo_endless.png').convert('RGBA')
    styled_pipe=Image.open(surface/'pipe.png').convert('RGB')
    pipe_visibility=Image.open(surface/'pipe_visibility.png').convert('L')
    sprites=[]
    def add(name,image,rect=None,flags=None):
        im=image.crop(rect) if rect else image.copy();values=[]
        for y in range(im.height):
            for x in range(im.width):
                pixel=im.getpixel((x,y));r,g,b=pixel[:3];f=VISIBLE if flags is None else flags(x,y)
                if len(pixel)==4 and pixel[3]==0:f=0
                values.append((f | (r<<16)|(g<<8)|b) if f else 0)
        sprites.append({'name':name,'size':im.size,'values':values,'origin':list(rect[:2]) if rect else None})
    add('p1_next',styled,(143,148,298,320))
    add('p2_next',styled,(959,148,1114,320))
    add('hold',styled,(154,332,294,506))
    add('p2_next_endless',styled_endless,(959,148,1114,320))
    add('header',styled,(156,32,1049,128))
    # Glass is always overwritten by the eight-cell / reserve shader. Keep
    # only visible housing data; the front-chain pixels are composed afterward.
    from PIL import ImageDraw
    core_camp=camp.copy();core_endless=endless.copy()
    for core_image in [core_camp,core_endless]:
        ImageDraw.Draw(core_image).rectangle((1157,260,1182,547),fill='#040c13')
    add('core_campaign',core_camp,(1124,214,1214,570))
    add('core_endless',core_endless,(1124,214,1214,570))
    locked=core_camp.crop((1124,214,1214,570));front=set()
    for y in range(264):
        for x in range(88):
            rgb=raw[6896+y*88+x]
            if rgb!=0xff00ff:
                px=1126+x-1124;py=274+y-214
                locked.putpixel((px,py),((rgb>>16)&255,(rgb>>8)&255,rgb&255));front.add((px,py))
    add('core_locked',locked,flags=lambda x,y:VISIBLE|(FRONT if (x,y) in front else 0))
    # Solo exposes 150 inlet-edge pixels which are covered by P2's panel in
    # duo. Use the complete pipe here; the panel has explicit render priority.
    add('pipe',styled_pipe,(1049,32,1155,342),flags=lambda x,y:VISIBLE if pipe_visibility.getpixel((1049+x,32+y)) or (x<15 and y<96) else 0)
    add('legend',camp,(972,364,1108,612))
    add('status',camp,(1114,618,1210,660))
    for name,offset in [('charge_on',6000),('charge_off',6224),('debris_on',6448),('debris_off',6672)]:
        im=Image.new('RGB',(14,16));im.putdata([((v>>16)&255,(v>>8)&255,v&255) for v in raw[offset:offset+224]])
        add(name,im)
    # Remaining functional bezels are protected while D1/D2/D3 surroundings
    # are rendered procedurally. Native pixels are never geometrically scaled.
    add('speed',camp,(972,314,1112,356))
    add('speed_endless',endless,(972,314,1112,356))
    add('header_endless_edge',styled_endless,(1049,32,1064,128))
    # Exact reviewed-color versions of the existing endless header fills.
    mapping=json.loads((ROOT/'assets/new_ui/color_mapping.json').read_text('utf-8'))
    palette=json.loads((ROOT/'assets/new_ui/palette.json').read_text('utf-8'))['palette_rgb']
    constants={name:tuple(palette[mapping[h]]) for name,h in [('MODE_BG','091925'),('STATS_BG','081925'),('ROW_LINE','344f63')]}
    rebuilt=camp.crop((156,32,1049,128));pix=rebuilt.load()
    for y in range(32,128):
        for x in range(156,1049):
            if 168<=x<296 and 38<=y<116:pix[x-156,y-32]=constants['MODE_BG']
            if 471<=x<1051 and (52<=y<83 or 88<=y<118):pix[x-156,y-32]=constants['STATS_BG']
            if 471<=x<=1050 and y in (51,86,119):pix[x-156,y-32]=constants['ROW_LINE']
    assert rebuilt.tobytes()==endless.crop((156,32,1049,128)).tobytes(),'Endless header fill model differs'
    # Independent dictionaries: identical patterns can use different local palettes.
    # High-color tiles point directly to one shared RGB palette. Keeping their
    # 17..64-color local palettes repeats too many RGB words in block RAM.
    high_colors=set()
    for sprite in sprites:
        w,h=sprite['size']
        for ty in range(0,h,8):
            for tx in range(0,w,8):
                v=tuple(sprite['values'][(ty+y)*w+tx+x] if ty+y<h and tx+x<w else 0 for y in range(8) for x in range(8))
                if len(set(v))>16:high_colors.update(v)
    high_colors=tuple(sorted(high_colors));high_ids={v:i for i,v in enumerate(high_colors)}
    high_bits=max(1,(len(high_colors)-1).bit_length())
    patterns=[[] for _ in range(6)];pattern_ids=[{} for _ in range(6)]
    tile_records=[];all_palettes=set();metadata=[];base=0
    for sprite in sprites:
        w,h=sprite['size'];pw=(w+7)//8*8;ph=(h+7)//8*8
        for ty in range(0,ph,8):
            for tx in range(0,pw,8):
                values=tuple(sprite['values'][(ty+y)*w+tx+x] if ty+y<h and tx+x<w else 0 for y in range(8) for x in range(8))
                colors=tuple(sorted(set(values)));ids={v:i for i,v in enumerate(colors)}
                pattern=tuple(ids[v] for v in values);n=len(colors)
                kind=0 if n==1 else 1 if n<=2 else 2 if n<=4 else 3 if n<=8 else 4 if n<=16 else 5
                assert n<=256
                if kind==5:
                    pattern=tuple(high_ids[v] for v in values);colors=high_colors
                if pattern not in pattern_ids[kind]:
                    pattern_ids[kind][pattern]=len(patterns[kind]);patterns[kind].append(pattern)
                tile_records.append((kind,pattern_ids[kind][pattern],colors))
                if kind!=5:all_palettes.add(colors)
        words=pw*ph//64
        metadata.append({'id':len(metadata),'name':sprite['name'],'size':[w,h],'stride':pw//8,'map_base':base,'map_words':words,'origin':sprite['origin']})
        base+=words
    # Reuse existing contiguous palette sequences; retain every source RGB bit.
    pal_values=[];pal_bases={};starts=defaultdict(list)
    for colors in sorted(all_palettes,key=lambda v:(-len(v),v)):
        found=None
        for p in starts[colors[0]]:
            if tuple(pal_values[p:p+len(colors)])==colors:found=p;break
        if found is None:
            found=len(pal_values)
            for value in colors:starts[value].append(len(pal_values));pal_values.append(value)
        pal_bases[colors]=found
    pal_bits=max(1,(len(pal_values)-1).bit_length())
    pattern_bits=max(1,(max(len(p) for p in patterns)-1).bit_length())
    desc_bits=3+pattern_bits+pal_bits
    assert len(tile_records)<=8192,"Material map exceeds the registered 13-bit address"
    assert desc_bits<=36
    descriptors=[(k<<(pattern_bits+pal_bits))|(p<<pal_bits)|(0 if k==5 else pal_bases[c]) for k,p,c in tile_records]
    def write(name,values,width):
        (SRC/name).write_text(''.join(f'{v:0{(width+3)//4}x}\n' for v in values),'ascii')
    rgb_values=sorted(set(pal_values)|set(high_colors));rgb_ids={v:i for i,v in enumerate(rgb_values)}
    rgb_bits=max(1,(len(rgb_values)-1).bit_length())
    write('ui_material_map.mem',descriptors,desc_bits)
    for k,bits in enumerate([0,1,2,3,4,high_bits]):
        if not bits:continue
        data=[(rgb_ids[high_colors[v]] if k==5 else v) for pattern in patterns[k] for v in pattern] or [0]*64
        name=f'ui_material_p{[0,1,2,3,4,8][k]}';write(name+'.mem',data,bits)
        split=1<<((len(data)-1).bit_length()-1)
        write(name+'_lo.mem',data[:split],bits);write(name+'_hi.mem',data[split:],bits)
    color_codes=[rgb_ids[v] for v in pal_values]
    write('ui_material_rgb.mem',rgb_values,26)
    write('ui_material_palette.mem',color_codes,rgb_bits)
    for name,data,width in [('ui_material_map',descriptors,desc_bits),('ui_material_palette',color_codes,rgb_bits)]:
        split=1<<((len(data)-1).bit_length()-1)
        write(name+'_lo.mem',data[:split],width);write(name+'_hi.mem',data[split:],width)
    # Geometry ROMs replace the old per-pixel multiply/divide/modulo chains.
    write('ui_charge_x.mem',[(int((d*n)%333>=313)<<4)|((d*n)%333)*14//333 for n in (10,8) for d in range(333)],5)
    write('ui_charge_y.mem',[y*16//21 for y in range(21)],4)
    write('ui_debris_x.mem',[x%14 for x in range(333)],4)
    write('ui_debris_y.mem',[y*16//19 for y in range(19)],4)
    write('ui_track_limit.mem',[(333*p+99)//100 for p in range(101)],9)
    write('ui_core_gradient.mem',[(111-3*y)<<16 | (245-46*y//31)<<8 | (255-23*y//31) for y in range(32)],24)
    write('ui_legend_circle.mem',[1 if 100<=(2*x-13)**2+(2*y-13)**2<=196 else 2 if (2*x-13)**2+(2*y-13)**2<100 else 0 for y in range(14) for x in range(14)],2)
    header=['// Generated A3 material geometry; no gameplay state.',
      f'localparam MAT_MAP_WORDS={len(descriptors)}, MAT_DESC_BITS={desc_bits};',
      f'localparam MAT_PAL_WORDS={len(pal_values)}, MAT_PAL_BITS={pal_bits}, MAT_PATTERN_BITS={pattern_bits};']
    header.append(f'localparam MAT_P8_BITS={high_bits}, MAT_RGB_BITS={rgb_bits}, MAT_RGB_WORDS={len(rgb_values)};')
    for k,bits in enumerate([0,1,2,3,4,8]):
        if bits:header.append(f'localparam MAT_P{bits}_WORDS={max(1,len(patterns[k]))*64};')
    for m in metadata:
        n=m['name'].upper();header.extend([f'localparam MAT_{n}={m["id"]};',f'localparam MAT_{n}_BASE={m["map_base"]}, MAT_{n}_STRIDE={m["stride"]};'])
    for name,rgb in constants.items():header.append(f'localparam [23:0] MAT_{name}=24\'h{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x};')
    (SRC/'ui_material_geometry.vh').write_text('\n'.join(header)+'\n','ascii')
    # Verify every reconstructed tile, including transparency and front-chain tags.
    for descriptor,(kind,pid,colors) in zip(descriptors,tile_records):
        pbase=descriptor&((1<<pal_bits)-1)
        for c in patterns[kind][pid]:
            if kind==5:assert rgb_values[rgb_ids[high_colors[c]]]==colors[c]
            else:assert pal_values[pbase+c]==colors[c]
    # Every erased fallback pixel must have a new material owner. The mast owns
    # the final four rows and last column of the pipe mask at its inlet.
    for y in range(720):
        for x in range(1280):
            if mask.getpixel((x,y)):
                assert (1049<=x<1155 and 48<=y<342) or (1124<=x<1214 and 214<=y<570)
    # Exact equivalence to the old per-pixel threshold and charge slot sampler.
    for percent in range(101):
        for dx in range(333):
            assert (dx<(333*percent+99)//100)==(dx*100<333*percent)
    names=sorted(p.name for p in SRC.glob('ui_material_*.mem') if p.name!='ui_material_map_padded.mem')
    names+=['ui_material_geometry.vh','ui_charge_x.mem','ui_charge_y.mem','ui_debris_x.mem','ui_debris_y.mem','ui_track_limit.mem','ui_core_gradient.mem','ui_legend_circle.mem']
    bits=len(descriptors)*desc_bits+len(pal_values)*rgb_bits+len(rgb_values)*26+sum(max(1,len(patterns[k]))*64*b for k,b in enumerate([0,1,2,3,4,high_bits]) if b)
    manifest={'sprites':metadata,'descriptor_bits':desc_bits,'palette_words':len(pal_values),'rgb_words':len(rgb_values),'rgb_bits':rgb_bits,'pattern_counts':[len(p) for p in patterns],
      'ROM_capacity_bits':bits,'capacity_only_bram36_lower_bound':math.ceil(bits/36864),'endless_header_fill_model_verified':True,
      'high_color_global_entries':len(high_colors),'high_color_index_bits':high_bits,
      'fallback_ownership_verified':True,'track_threshold_pairs_verified':101*333,
      'files_sha256':{n:hashlib.sha256((SRC/n).read_bytes()).hexdigest() for n in names}}
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    # Historical full-frame oracle banks remain archived; live UI owns no preview ROM.
    print('A3_MATERIALS_READY',len(descriptors),'DESCRIPTORS',len(pal_values),'PALETTE_WORDS',bits,'BITS','MIN_BRAM',math.ceil(bits/36864))

if __name__=='__main__':main()
