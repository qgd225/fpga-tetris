"""导出真实 RTL 的配乐/音效/语音，保留硬件增益，不归一化。"""
import hashlib,json,struct,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/assets/story_audio';OUT.mkdir(parents=True,exist_ok=True)
pack=json.loads((ROOT/'assets/story_voice.json').read_text(encoding='utf-8'))
result={"status":"RTL_verified_hardware_audition_not_performed","voices":[]}
def export(source,target,count=None):
 words=[int(x,16) for x in source.read_text().split()]
 pcm=[x-65536 if x>=32768 else x for x in words]
 if count is not None:assert len(pcm)==count
 with wave.open(str(target),'wb') as w:
  w.setparams((1,2,48000,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(pcm),*pcm))
 return {"file":target.name,"samples":len(pcm),"peak":max(abs(x) for x in pcm),"sha256":hashlib.sha256(target.read_bytes()).hexdigest()}
for v in pack['voices']:
 item=export(ROOT/f"sim/story_audio/build/voice{v['id']}_pcm_48k.mem",OUT/f"V{v['id']}_rtl_48k.wav",v['samples']*6)
 item.update(id=v['id'],text=v['text'],payload_sha256=v['payload_sha256']);result['voices'].append(item)
for i in range(4):export(ROOT/f'sim/story_audio/build_music/bgm_phase{i}.mem',OUT/f'BGM_phase{i}.wav',192000)
for kind in ['click','double']:export(ROOT/f'sim/story_audio/build/blocked_{kind}.mem',OUT/f'blocked_{kind}.wav',4000)
(OUT/'audio-preview-manifest.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('RTL_AUDIO_PREVIEWS_EXPORTED seven voices, four phases, two mechanical comparisons')
