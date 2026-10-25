"""开场句离线候选：标准库编码，独立移位解码逐样本校验；未接入 FPGA。"""
import audioop
import array
import json
import math
import wave
from pathlib import Path
ROOT=Path(__file__).resolve().parent
STEPS=[7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767]
INDEX=[-1,-1,-1,-1,2,4,6,8]
with wave.open(str(ROOT/'V0_source.wav'),'rb') as w:
    assert (w.getframerate(),w.getnchannels(),w.getsampwidth())==(8000,1,2)
    source=array.array('h',w.readframes(w.getnframes()))
peak=max(abs(x) for x in source)
active=[i for i,x in enumerate(source) if abs(x)>max(32,peak//200)]
a=max(0,active[0]-640); b=min(len(source),active[-1]+801)
pcm=array.array('h',[round(x*8192/peak) for x in source[a:b]])
if len(pcm)%2: pcm.append(0)
packed,_=audioop.lin2adpcm(pcm.tobytes(),2,(0,0))
reference,_=audioop.adpcm2lin(packed,2,(0,0))
expected=array.array('h',reference)
predictor=index=0; actual=[]
for byte in packed:
    for code in (byte>>4,byte&15):
        step=STEPS[index]
        diff=(step>>3)+((step>>2) if code&1 else 0)+((step>>1) if code&2 else 0)+(step if code&4 else 0)
        predictor=max(-32768,min(32767,predictor+(-diff if code&8 else diff)))
        index=max(0,min(88,index+INDEX[code&7]));actual.append(predictor)
assert actual==list(expected)
for name,samples in [('V0_clean.wav',pcm),('V0_adpcm_preview.wav',expected)]:
    with wave.open(str(ROOT/name),'wb') as w:
        w.setparams((1,2,8000,0,'NONE','not compressed'));w.writeframes(samples.tobytes())
(ROOT/'V0.ima').write_bytes(packed)
noise=sum((a-b)**2 for a,b in zip(pcm,expected))
snr=10*math.log10(sum(x*x for x in pcm)/max(1,noise))
manifest={'id':'V0','text':'YOU CAME.','voice':'Microsoft Zira Desktop','rate_hz':8000,'predictor':0,'index':0,'nibble_order':'high_first','samples':len(pcm),'seconds':len(pcm)/8000,'payload_bytes':len(packed),'ramb36_payload_tiles':math.ceil(len(pcm)/8192),'snr_db_vs_pcm':round(snr,2),'status':'offline_candidate_not_integrated_not_audition_approved'}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(json.dumps(manifest))
