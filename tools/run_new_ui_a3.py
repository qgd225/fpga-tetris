"""Prepare/run A3 RGB equivalence and standalone timing; never generate a bit."""
from pathlib import Path
import argparse,hashlib,json,re,shutil,subprocess,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'
OUT=ROOT/'temporary/new_ui_a3'

def main():
    if (SRC/"ui_text_compact.v").exists():
        raise SystemExit("Historical A3 runner: use tools/run_new_ui_finish.py for the current UI.")
    p=argparse.ArgumentParser();p.add_argument('--prepare-only',action='store_true')
    p.add_argument('--measure-only',action='store_true');p.add_argument('--smoke',action='store_true')
    a=p.parse_args();OUT.mkdir(exist_ok=True);(OUT/'os_tmp').mkdir(exist_ok=True)
    subprocess.run([sys.executable,str(ROOT/'tools/build_ui_material_atlas.py')],cwd=ROOT,check=True)
    run=OUT/'render';run.mkdir(exist_ok=True)
    oracle=ROOT/'assets/new_ui/verification/a2'
    checks=json.loads((oracle/'manifest.json').read_text('utf-8'))
    for name,sha in checks.items():
        f=oracle/name;assert hashlib.sha256(f.read_bytes()).hexdigest()==sha
        shutil.copyfile(f,run/name.removesuffix('.snapshot'))
    source=(oracle/'reference_ui_renderer_a2.v.snapshot').read_bytes().decode('gbk')
    header=source[source.index('(')+1:source.index(');')];names=[]
    for token in header.split(','):
        token=re.sub(r'\[[^]]*\]','',token);token=re.sub(r'\b(input|output|reg|wire)\b','',token).strip()
        if token and token!='rgb':names.append(token)
    (run/'ui_a3_golden_instance.vh').write_text('reference_ui_renderer_a2 golden(\n'+',\n'.join(' .'+n+'(scenes.dut.reference_layer.'+n+')' for n in names)+',\n .rgb(golden_renderer));\n','ascii')
    with (run/'a2_reference_ui_skin.mem').open('w',encoding='ascii',newline='\n') as f:
        for name in ['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']:
            f.writelines(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in Image.open(ROOT/'assets/new_ui'/f'{name}_material.png').convert('RGB').getdata())
    mems=['story_font.mem','story_sprites.mem','reference_ui_skin.mem','reference_ui_material.mem','reference_ui_digits.mem','ui_panel_map.mem','ui_panel_pixels.mem','ui_panel_palette.mem','ui_font_5x7.mem']
    mems+= [f.name for f in SRC.glob('ui_material_*.mem')]
    mems+= ['ui_charge_x.mem','ui_charge_y.mem','ui_debris_x.mem','ui_debris_y.mem','ui_track_limit.mem','ui_core_gradient.mem','ui_legend_circle.mem']
    for n in mems:shutil.copyfile(SRC/n,run/n);shutil.copyfile(SRC/n,OUT/n)
    setup=('@echo off\nset "TEMP='+str(OUT/'os_tmp')+'"\nset "TMP='+str(OUT/'os_tmp')+'"\n'
      'set "HOMEDRIVE=C:"\nset "HOMEPATH=\\Users\\qiguidie"\n'
      'call D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1\n')
    modules=['ui_font_5x7','ui_text_raster','ui_material_atlas','ui_mission_layer','ui_basic_layer','hud_font_rom','hud_text','scene_sprite_rom','story_scene','core_renderer','reference_ui_renderer','story_ui']
    files=[SRC/(n+'.v') for n in modules]+[run/(n+'_a2.v') for n in ['reference_ui_renderer','ui_basic_layer','ui_panel_atlas']]+[ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v',ROOT/'Tetris.sim/story_visual/ui_a3_integration_tb.v']
    bat=setup+'call xvlog.bat --relax -i "'+SRC.as_posix()+'" -i "'+run.as_posix()+'" '+' '.join('"'+f.as_posix()+'"' for f in files)+' --nolog >compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
    bat+='call xelab.bat ui_a3_integration_tb '+('-generic_top "SMOKE=1" ' if a.smoke else '')+'-s ui_a3_integration --timescale 1ns/1ps --nolog >elaborate.log 2>&1\nif errorlevel 1 exit /b 2\n'
    bat+='call xsim.bat ui_a3_integration -runall --nolog >render.log 2>&1\nif errorlevel 1 exit /b 3\ntype render.log\n'
    (run/'run.bat').write_text(bat,'ascii')
    (OUT/'measure.bat').write_text(setup+'call vivado.bat -mode batch -notrace -nojournal -log "'+(OUT/'synthesis.log').as_posix()+'" -source "'+(ROOT/'tools/measure_new_ui_a3.tcl').as_posix()+'" >measurement_console.log 2>&1\n','ascii')
    # Compare all padded tile pixels and shuffled addresses against the compiler
    # contract. Full-frame checks below use a separate pre-A3 renderer/ROM.
    atlas=OUT/'atlas_test';atlas.mkdir(exist_ok=True)
    geometry=(SRC/'ui_material_geometry.vh').read_text('ascii')
    pb=int(re.search(r'MAT_PAL_BITS=(\d+)',geometry)[1]);ib=int(re.search(r'MAT_PATTERN_BITS=(\d+)',geometry)[1])
    desc=[int(v,16) for v in (SRC/'ui_material_map.mem').read_text('ascii').split()]
    palette=[int(v,16) for v in (SRC/'ui_material_palette.mem').read_text('ascii').split()]
    patterns={b:[int(v,16) for v in (SRC/f'ui_material_p{b}.mem').read_text('ascii').split()] for b in [1,2,4,8]}
    with (atlas/'ui_material_expected.mem').open('w',encoding='ascii') as f:
        for d in desc:
            k=d>>(pb+ib);pid=(d>>pb)&((1<<ib)-1);base=d&((1<<pb)-1)
            for q in range(64):
                index=0 if k==0 else patterns[[0,1,2,4,8][k]][pid*64+q]
                f.write(f'{palette[base+index]:07x}\n')
    for f in SRC.glob('ui_material_*.mem'):shutil.copyfile(f,atlas/f.name)
    atlas_bat=setup+'call xvlog.bat --relax -i "'+SRC.as_posix()+'" "'+(SRC/'ui_material_atlas.v').as_posix()+'" "'+(ROOT/'Tetris.sim/story_visual/ui_material_atlas_tb.v').as_posix()+'" --nolog >compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
    atlas_bat+='call xelab.bat ui_material_atlas_tb --timescale 1ns/1ps -s ui_material_roundtrip --nolog >elaborate.log 2>&1\nif errorlevel 1 exit /b 2\ncall xsim.bat ui_material_roundtrip -runall --nolog >test.log 2>&1\nif errorlevel 1 exit /b 3\ntype test.log\n'
    (atlas/'run.bat').write_text(atlas_bat,'ascii')
    print('A3_INPUTS_PREPARED',flush=True)
    if a.prepare_only:return
    if a.measure_only:
        subprocess.run(['cmd','/d','/c','measure.bat'],cwd=OUT,check=True);return
    subprocess.run(['cmd','/d','/c','run.bat'],cwd=atlas,check=True)
    atlas_log=(atlas/'test.log').read_text('utf-8',errors='replace')
    assert 'A3_ATLAS_ALL_PIXELS_PASS' in atlas_log and 'A3_ATLAS_FAIL' not in atlas_log
    subprocess.run(['cmd','/d','/c','run.bat'],cwd=run,check=True)
    log=(run/'render.log').read_text('utf-8',errors='replace')
    assert 'A3_ALL_INTEGRATION_FRAMES_PASS' in log and 'A3_PARITY_FAIL' not in log
    print('A3_RGB_RUN_PASS',flush=True)

if __name__=='__main__':main()
