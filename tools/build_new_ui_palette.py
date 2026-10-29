"""Conservative perceptual color merging; preserve the original 56 colors.

Colors within a CIELAB Delta-E-76 radius share an index. If no palette color
is close enough, append the source color. Never force a fixed palette size.
Frozen references and the existing renderer assets are read-only inputs.
"""
from pathlib import Path
from collections import Counter,defaultdict
import argparse,hashlib,json,math,re
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
NAMES=['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']

def lab(c):
    r,g,b=[v/3294.6 if v<=10.31475 else ((v/255+.055)/1.055)**2.4 for v in c]
    x=(r*.4124564+g*.3575761+b*.1804375)/.95047
    y=r*.2126729+g*.7151522+b*.0721750
    z=(r*.0193339+g*.1191920+b*.9503041)/1.08883
    x,y,z=[v**(1/3) if v>(6/29)**3 else v/(3*(6/29)**2)+4/29 for v in (x,y,z)]
    return 116*y-16,500*(x-y),200*(y-z)

def main():
    p=argparse.ArgumentParser();p.add_argument('--radius',type=float,default=3.0)
    p.add_argument('--output',type=Path,default=ROOT/'assets/new_ui')
    args=p.parse_args();assert 0<args.radius<=10
    out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
    source=ROOT/'assets/reference_ui';images={n:Image.open(source/f'{n}_material.png').convert('RGB') for n in NAMES}
    counts=Counter()
    for im in images.values():counts.update(im.getdata())
    s=(ROOT/'Tetris.srcs/sources_1/new/story_palette.vh').read_bytes().decode('gbk')
    original={int(i):tuple(int(h[k:k+2],16) for k in (0,2,4)) for i,h in re.findall(r"6'd(\d+):\s*story_palette=24'h([0-9a-fA-F]{6})",s)}
    assert set(original)==set(range(56))
    palette=[];labs=[];bins=defaultdict(list);mapping={};radius=args.radius
    def key(v):return tuple(math.floor(x/radius) for x in v)
    def add(rgb):
        palette.append(rgb);v=lab(rgb);labs.append(v);bins[key(v)].append(len(palette)-1)
        return len(palette)-1
    for i in range(56):mapping[original[i]]=add(original[i])
    max_error=0.0;weighted_sum=0.0
    for rgb,n in counts.most_common():
        v=lab(rgb);k=key(v);best=None;distance=radius*radius+1
        if rgb in mapping:best=mapping[rgb];distance=0
        else:
            for a in range(-1,2):
                for b in range(-1,2):
                    for c in range(-1,2):
                        for idx in bins[(k[0]+a,k[1]+b,k[2]+c)]:
                            d=sum((t-u)**2 for t,u in zip(v,labs[idx]))
                            if d<distance:distance=d;best=idx
            if distance>radius*radius:best=add(rgb);distance=0
            mapping[rgb]=best
        max_error=max(max_error,math.sqrt(distance));weighted_sum+=math.sqrt(distance)*n
    for name,im in images.items():
        target=Image.new('RGB',im.size);target.putdata([palette[mapping[c]] for c in im.getdata()])
        target.save(out/f'{name}_material.png')
    bits=(len(palette)-1).bit_length();allocated=1<<bits
    values=[r*65536+g*256+b for r,g,b in palette]+[0]*(allocated-len(palette))
    (out/'palette.mem').write_text(''.join(f'{v:06x}\n' for v in values),'ascii')
    manifest={'date':'2026-10-28','rule':'nearest existing within radius, otherwise append original source RGB; original 56 entries unchanged',
      'metric':'CIELAB D65 Delta-E-76','radius':radius,'original_palette_count':56,
      'source_color_count':len(counts),'palette_count':len(palette),'code_bits':bits,
      'allocated_palette_words':allocated,'max_delta_e_76':max_error,
      'pixel_weighted_mean_delta_e_76':weighted_sum/sum(counts.values()),
      'palette_rgb':[list(c) for c in palette],
      'source_sha256':{n:hashlib.sha256((source/f'{n}_material.png').read_bytes()).hexdigest() for n in NAMES},
      'transport_status':'requires an extended palette/index path; current 6-bit/56-color protocol is unchanged in A1',
      'scope':'A1 candidate palette and textures; not an approved replacement of the frozen reference set'}
    (out/'palette.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    (out/'color_mapping.json').write_text(json.dumps({''.join(f'{v:02x}' for v in c):idx for c,idx in mapping.items()},sort_keys=True)+'\n','utf-8')
    print('PALETTE_READY',len(palette),'COLORS',bits,'BITS','MAX_DELTA_E_76',max_error)

if __name__=='__main__':main()
