"""准备已批准七句通信；沿用 V0 原始候选，保留源文件，连续打包前记录真实样本。"""
import array, hashlib, json, math, random, wave, warnings
with warnings.catch_warnings():
    warnings.simplefilter("ignore", DeprecationWarning)
    import audioop
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
first=json.loads((ROOT/'assets/voice_sources/V0.json').read_text(encoding='utf-8'))
first['id']=0;first['name']='V0'
voices=[first]
texts=['YOU CAME.','LINK RESTORED. THERE YOU ARE.','THAT IS IT. KEEP GOING.','STEADY. ALMOST THERE.','CLEAR THE ARRAY. NOW.','POWER RESTORED. THANK YOU.','NOT... YET.']
for i in range(1,7):
 source=ROOT/f'assets/voice_sources/V{i}_source.wav'
 with wave.open(str(source),'rb') as w:
  assert (w.getframerate(),w.getnchannels(),w.getsampwidth())==(8000,1,2)
  original=array.array('h',w.readframes(w.getnframes()))
 peak=max(abs(x) for x in original)
 active=[k for k,x in enumerate(original) if abs(x)>max(32,peak//200)]
 assert active
 a=max(0,active[0]-640);b=min(len(original),active[-1]+801)
 pcm=[round(x*8192/peak) for x in original[a:b]]
 rng=random.Random(7+i);filtered=0
 for k in range(len(pcm)):
  amplitude=48 if i==1 else (64 if i==6 and k>=len(pcm)-400 else 0)
  filtered=0.75*filtered+0.25*rng.uniform(-amplitude,amplitude)
  fade=min(1,k/40,(len(pcm)-1-k)/40)
  pcm[k]+=round(filtered*fade)
 if len(pcm)%2:pcm.append(0)
 raw_pcm=array.array('h',pcm);packed,_=audioop.lin2adpcm(raw_pcm.tobytes(),2,(0,0))
 raw,_=audioop.adpcm2lin(packed,2,(0,0));decoded=array.array('h',raw)
 assert len(decoded)==len(pcm)
 noise=sum((x-y)**2 for x,y in zip(pcm,decoded))
 profile='lowpass +/-48 seed8' if i==1 else ('tail disconnect noise, intact syllables' if i==6 else 'clean stable communication')
 voices.append({'id':i,'name':f'V{i}','text':texts[i],'voice':'Microsoft Zira Desktop','rate_hz':8000,'predictor':0,'index':0,'nibble_order':'high_first','samples':len(pcm),'seconds':len(pcm)/8000,'payload_bytes':len(packed),'payload_hex':packed.hex(),'payload_sha256':hashlib.sha256(packed).hexdigest(),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'noise_profile':profile,'pause_markers':[],'word_count':len(texts[i].replace('...',' ').split()),'peak':max(abs(x) for x in decoded),'snr_db_vs_precompression':round(10*math.log10(sum(x*x for x in pcm)/max(1,noise)),2)})
 out=ROOT/f'docs/assets/story_audio/V{i}_adpcm_preview.wav'
 with wave.open(str(out),'wb') as w:
  w.setparams((1,2,8000,0,'NONE','not compressed'));w.writeframes(raw)
total=sum(v['samples'] for v in voices)
assert 0<total<=128000, f'Voice pack exceeds 16 seconds: {total/8000}'
result={'status':'software_and_rtl_validation_required_no_hardware_audition_claim','rate_hz':8000,'total_samples':total,'seconds':total/8000,'ramb36_payload_tiles':math.ceil(total/8192),'voices':voices}
(ROOT/'assets/story_voice.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('VOICE_PACK',total,'samples',total/8000,'seconds',math.ceil(total/8192),'BRAM')
for v in voices:print(v['name'],v['samples'],v['seconds'],v['noise_profile'])
