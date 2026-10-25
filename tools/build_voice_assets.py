"""七句 ADPCM 按半字节连续打包；真实长度/起址与 ROM 一起生成。"""
import hashlib,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
m=json.loads((ROOT/'assets/story_voice.json').read_text(encoding='utf-8'))
voices=m['voices'];assert [v['id'] for v in voices]==list(range(7))
words=[];header=['// 由 tools/build_voice_assets.py 生成。','`ifndef STORY_VOICE_CONFIG_VH','`define STORY_VOICE_CONFIG_VH']
bases=[]
for v in voices:
 data=bytes.fromhex(v['payload_hex']);assert hashlib.sha256(data).hexdigest()==v['payload_sha256']
 assert v['rate_hz']==8000 and v['nibble_order']=='high_first' and v['predictor']==v['index']==0
 codes=[n for b in data for n in (b>>4,b&15)];assert len(codes)==v['samples']>0
 bases.append(len(words));words.extend(codes)
assert len(words)==m['total_samples']<=128000
depth=math.ceil(len(words)/8192)*8192
header += [f'`define STORY_VOICE_DEPTH {depth}',f'`define STORY_VOICE_TOTAL {len(words)}',f"`define VOICE_V0_SAMPLES {voices[0]['samples']}",'`endif']
target=ROOT/'Tetris.srcs/sources_1/new'
(target/'story_voice.mem').write_text(''.join(f'{n:x}\n' for n in words+[0]*(depth-len(words))),encoding='ascii',newline='\n')
(target/'story_voice_config.vh').write_text('\n'.join(header)+'\n',encoding='gbk',newline='\n')
metadata=['// 与连续 ROM 一起生成；单位为四位样本。']
for name,values in [('voice_base',bases),('voice_length',[v['samples'] for v in voices])]:
 metadata += [f'function [16:0] {name};','input [2:0] id;','begin case(id)']
 metadata += [f"3'd{i}:{name}=17'd{x};" for i,x in enumerate(values)]
 metadata += [f'default:{name}=0;','endcase end','endfunction']
(target/'story_voice_ids.vh').write_text('\n'.join(metadata)+'\n',encoding='gbk',newline='\n')
print(f'VOICE_ROM_GENERATED samples={len(words)} seconds={len(words)/8000} physical_tiles={depth//8192}')
