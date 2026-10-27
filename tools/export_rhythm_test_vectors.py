"""Export test-only vectors from the recorded layouts and the real shape ROM."""
import json,re,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
manifest=json.loads((root/'Tetris.srcs/sources_1/new/game_mode_manifest.json').read_text())
columns=[];remaining=[];lengths=[]
for layout in manifest['layouts']:
    proof=layout['witness'];n=len(proof['columns']);assert n<=180
    lengths.append(n);columns.extend(proof['columns']+[31]*(180-n));remaining.extend([h['remaining'] for h in proof['history']]+[0]*(180-n))
for name,values in [('witness_columns',columns),('witness_remaining',remaining),('witness_lengths',lengths)]:
    (out/(name+'.mem')).write_text(''.join(f'{v:02x}\n' for v in values),encoding='ascii')
for name,source in [('shape_reference','shape_rom'),('offset_reference','offset_rom')]:
    text=(root/'Tetris.srcs/sources_1/ip'/(source+'.coe')).read_text();radix=int(re.search(r'radix=(\d+)',text)[1]);words=re.split('[,;\s]+',text.split('vector=')[1].strip());values=[int(w,radix) for w in words if w]
    (out/(name+'.mem')).write_text(''.join(f'{v:08x}\n' for v in values),encoding='ascii')
print('RHYTHM_VECTORS layouts=64 template_version='+str(manifest['template_version']))
