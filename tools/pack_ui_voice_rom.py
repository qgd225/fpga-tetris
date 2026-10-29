"""Lossless physical packing: nine existing ADPCM nibbles per 36-bit word."""
from pathlib import Path
import math,json,hashlib
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'
def main():
    source=SRC/'story_voice.mem';samples=[int(v,16) for v in source.read_text('ascii').split()]
    words=[sum(v<<(4*j) for j,v in enumerate(samples[i:i+9])) for i in range(0,len(samples),9)]
    banks=math.ceil(len(words)/1024)
    assert 1<=banks<=13,"Voice pack exceeds registered physical banks; revise the ROM before building"
    for b in range(banks):
        data=words[b*1024:(b+1)*1024];
        (SRC/f'ui_voice_pack_{b:02d}.mem').write_text(''.join(f'{v:09x}\n' for v in data),'ascii')
    (SRC/'ui_voice_pack.vh').write_text(f'localparam VOICE_PACK_BANKS={banks}, VOICE_PACK_LAST_WORDS={len(words)-(banks-1)*1024};\n','ascii')
    assert all(((words[i//9]>>(4*(i%9)))&15)==v for i,v in enumerate(samples))
    print(f'VOICE_PACK_EXACT {len(samples)} NIBBLES {banks} BANKS SHA256 {hashlib.sha256(source.read_bytes()).hexdigest()}')
if __name__=='__main__':main()
