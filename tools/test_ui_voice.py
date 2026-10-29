"""Physical ROM packing plus real player PCM against independently decoded ADPCM."""
from pathlib import Path
import subprocess,shutil,sys,json,audioop,array,hashlib
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new';OUT=ROOT/'temporary/new_ui_finish/voice_final'
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 pack=json.loads((ROOT/'assets/story_voice.json').read_text('utf-8'));pcm=[];lengths=[]
 for voice in pack['voices']:
  payload=bytes.fromhex(voice['payload_hex']);assert hashlib.sha256(payload).hexdigest()==voice['payload_sha256']
  raw,_=audioop.adpcm2lin(payload,2,(voice['predictor'],voice['index']));samples=array.array('h',raw);assert len(samples)==voice['samples']
  pcm.extend(samples);lengths.append(len(samples))
 (OUT/'voice_pack_expected.mem').write_text(''.join(f'{x&65535:04x}\n' for x in pcm),'ascii')
 (OUT/'voice_pack_lengths.mem').write_text(''.join(f'{x:05x}\n' for x in lengths),'ascii')
 (OUT/'voice_pack_count.vh').write_text(f'localparam integer PACK_SAMPLES={len(pcm)};\n','ascii')
 for f in list(SRC.glob('ui_voice_pack_*.mem'))+[SRC/'story_voice.mem']:shutil.copyfile(f,OUT/f.name)
 modules=[SRC/(n+'.v') for n in ['voice_adpcm_rom','ima_adpcm_decoder','voice_player']]
 for tb in [ROOT/'Tetris.sim/story_visual/ui_voice_rom_equivalence_tb.v',ROOT/'Tetris.sim/story_audio/voice_pack_tb.v']:
  top=tb.stem;script='@echo off\ncall D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1\n'
  script+='call xvlog.bat --relax -i "'+SRC.as_posix()+'" -i "'+OUT.as_posix()+'" '+' '.join('"'+p.as_posix()+'"' for p in modules+[tb])+' --nolog >'+top+'_compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
  script+='call xelab.bat '+top+' -s '+top+' --timescale 1ns/1ps --nolog >'+top+'_elab.log 2>&1\nif errorlevel 1 exit /b 2\ncall xsim.bat '+top+' -runall --nolog >'+top+'.log 2>&1\n'
  (OUT/'run.bat').write_text(script,'ascii');subprocess.run(['cmd','/d','/c','run.bat'],cwd=OUT,check=True)
  log=(OUT/(top+'.log')).read_text('utf-8',errors='replace');assert 'ALL PASS' in log and 'FAIL ' not in log,log[-2000:];print('PASS',top,flush=True)
 (OUT/'summary.json').write_text(json.dumps({'pass':True,'samples':len(pcm),'voices':len(lengths),'source_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in modules+list(SRC.glob('ui_voice_pack*'))}},indent=2),'utf-8')
if __name__=='__main__':main()
