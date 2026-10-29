"""Current UI font/template/atlas roundtrips against independent scalar contracts."""
from pathlib import Path
import subprocess,shutil,re,json,hashlib
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new';OUT=ROOT/'temporary/ui_polish_20261029/components'
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 geometry=(SRC/'ui_material_geometry.vh').read_text('ascii')
 pb=int(re.search(r'MAT_PAL_BITS=(\d+)',geometry)[1]);ib=int(re.search(r'MAT_PATTERN_BITS=(\d+)',geometry)[1])
 def values(name):return [int(v,16) for v in (SRC/name).read_text('ascii').split()]
 desc=values('ui_material_map.mem');pal=values('ui_material_palette.mem');rgb=values('ui_material_rgb.mem')
 patterns={k:values(f'ui_material_p{b}.mem') for k,b in enumerate([0,1,2,3,4,8]) if k}
 with (OUT/'ui_material_expected.mem').open('w',encoding='ascii') as f:
  for d in desc:
   k=d>>(pb+ib);pid=(d>>pb)&((1<<ib)-1);base=d&((1<<pb)-1)
   for q in range(64):
    code=0 if k==0 else patterns[k][pid*64+q]
    f.write(f'{rgb[code if k==5 else pal[base+code]]:07x}\n')
 for f in SRC.glob('ui_*.mem'):shutil.copyfile(f,OUT/f.name)
 groups={'ui_font_5x7':['ui_font_5x7'],'ui_text_compact':['ui_font_5x7','ui_text_raster','ui_text_compact'],'ui_material_atlas':['ui_material_atlas'],'ui_mission_dynamic':['ui_material_atlas','ui_mission_layer'],'ui_layout':['ui_material_atlas','ui_mission_layer'],'ui_audio_observer':['sound'],'ui_renderer_equivalence':['ui_font_5x7','ui_text_raster','ui_text_compact','ui_material_atlas','ui_mission_layer','ui_basic_layer','ui_hull_background','reference_ui_renderer','story_ui'],'ui_basic_equivalence':['ui_font_5x7','ui_text_raster','ui_text_compact','ui_material_atlas','ui_mission_layer','ui_basic_layer','ui_hull_background','reference_ui_renderer','story_ui']}
 results=[]
 for group,modules in groups.items():
  files=[SRC/(n+'.v') for n in modules]+[ROOT/'Tetris.sim/story_visual'/(group+'_tb.v')]
  if group=='ui_renderer_equivalence':
   for name in ['reference_ui_renderer','story_ui']:
    raw=(ROOT/'assets/new_ui/verification/background_before'/(name+'.v.snapshot')).read_bytes().decode('gbk')
    raw=raw.replace('module '+name+'(','module '+name+'_bg_before(').replace('reference_ui_renderer reference_layer(','reference_ui_renderer_bg_before reference_layer(')
    p=OUT/(name+'_bg_before.v');p.write_bytes(raw.encode('gbk'));files += [p]
   scenes=(ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v').read_bytes().decode('gbk')
   block=scenes[scenes.index('story_ui dut('):];block=block[:block.index(');')+2]
   ports=re.findall(r'\.(\w+)\(',block)
   assert 'rgb' in ports
   (OUT/'ui_renderer_golden_instance.vh').write_text('story_ui_bg_before golden('+','.join('.'+n+'('+("golden_rgb" if n=='rgb' else 'scenes.dut.'+n)+')' for n in ports)+');\n','ascii')
   files += [ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v']
  if group=='ui_layout':
   golden=(ROOT/'assets/new_ui/verification/layout_before/ui_mission_layer.v.snapshot').read_text('ascii').replace('module ui_mission_layer(','module ui_mission_layer_before(')
   (OUT/'ui_mission_layer_before.v').write_text(golden,'ascii');files += [OUT/'ui_mission_layer_before.v']
  if group=='ui_audio_observer':
   top=(SRC/'Tetris.v').read_bytes().decode('gbk');start=top.index('    // Read-only audio snapshot');end=top.index('    );',start)+len('    );')
   (OUT/'ui_audio_observer_instance.vh').write_text(top[start:end].replace('sound sound_inst(','sound #(.MS_MAX(3)) sound_inst('),'ascii')
  if group=='ui_basic_equivalence':
   golden=(ROOT/'assets/new_ui/verification/before_timing/ui_basic_layer.v.snapshot').read_text('ascii').replace('module ui_basic_layer(','module ui_basic_layer_golden(')
   (OUT/'ui_basic_layer_golden.v').write_text(golden,'ascii')
   files += [OUT/'ui_basic_layer_golden.v',ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v']
  script='@echo off\ncall D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1\n'
  script+='call xvlog.bat --relax -i "'+SRC.as_posix()+'" -i "'+OUT.as_posix()+'" '+' '.join('"'+f.as_posix()+'"' for f in files)+' --nolog >'+group+'_compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
  script+='call xelab.bat '+group+'_tb -s '+group+' --timescale 1ns/1ps --nolog >'+group+'_elab.log 2>&1\nif errorlevel 1 exit /b 2\n'
  script+='call xsim.bat '+group+' -runall --nolog >'+group+'.log 2>&1\n'
  (OUT/'run.bat').write_text(script,'ascii');subprocess.run(['cmd','/d','/c','run.bat'],cwd=OUT,check=True)
  log=(OUT/(group+'.log')).read_text('utf-8',errors='replace');assert ('PASS' in log and 'FAIL' not in log),log[-1500:]
  print('PASS',group,flush=True);results.append(group)
 (OUT/'summary.json').write_text(json.dumps({'pass':True,'tests':results,'extra_source_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in [SRC/'Tetris.v',SRC/'sound.v']},'oracle_sha256':{**{('assets/new_ui/verification/background_before/'+n+'.v.snapshot'):hashlib.sha256((ROOT/'assets/new_ui/verification/background_before'/(n+'.v.snapshot')).read_bytes()).hexdigest() for n in ['reference_ui_renderer','story_ui']},'assets/new_ui/verification/layout_before/ui_mission_layer.v.snapshot':hashlib.sha256((ROOT/'assets/new_ui/verification/layout_before/ui_mission_layer.v.snapshot').read_bytes()).hexdigest(),'assets/new_ui/verification/before_timing/ui_basic_layer.v.snapshot':hashlib.sha256((ROOT/'assets/new_ui/verification/before_timing/ui_basic_layer.v.snapshot').read_bytes()).hexdigest()},'source_sha256':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in SRC.glob('ui_*') if f.suffix in {'.v','.vh','.mem'}}},indent=2),'utf-8')
if __name__=='__main__':main()
