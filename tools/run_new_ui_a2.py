"""Reproduce the connected A2 common layer and its pre-A2 RGB parity checks.

Generated runs/logs go to temporary/new_ui_a2. No formal run is reset, no bit
is generated, and frozen reference PNGs are never rewritten.
"""
from pathlib import Path
import argparse,hashlib,json,re,shutil,subprocess,sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'
OUT=ROOT/'temporary/new_ui_a2'

def main():
    # A2 writes its full-frame initialization bank. Do not let this historical
    # entry restore that bank over A3's diagnostic holes or test the new ports
    # with A2's old dependency list. The frozen A2 oracle is used by A3 instead.
    if 'ui_mission_layer mission(' in (SRC/'reference_ui_renderer.v').read_bytes().decode('gbk'):
        raise SystemExit('当前已进入A3，请运行 tools/run_new_ui_a3.py；A2独立对照快照已冻结保留。')
    parser=argparse.ArgumentParser();parser.add_argument('--prepare-only',action='store_true')
    args=parser.parse_args();OUT.mkdir(parents=True,exist_ok=True);(OUT/'os_tmp').mkdir(exist_ok=True)
    subprocess.run([sys.executable,str(ROOT/'tools/build_ui_panel_atlas.py')],cwd=ROOT,check=True)
    oracle=ROOT/'assets/new_ui/verification/reference_ui_renderer_a1.v.snapshot'
    meta=json.loads((oracle.parent/'manifest.json').read_text('utf-8'))
    assert hashlib.sha256(oracle.read_bytes()).hexdigest()==meta['sha256']
    (OUT/'reference_ui_renderer_a1.v').write_bytes(oracle.read_bytes())
    run=OUT/'render';run.mkdir(exist_ok=True)
    source=oracle.read_bytes().decode('gbk');header=source[source.index('(')+1:source.index(');')]
    names=[]
    for token in header.split(','):
        token=re.sub(r'\[[^]]*\]','',token);token=re.sub(r'\b(input|output|reg|wire)\b','',token).strip()
        if token and token!='rgb':names.append(token)
    (run/'ui_a2_golden_instance.vh').write_text('reference_ui_renderer_a1 golden(\n'+',\n'.join(' .'+n+'(scenes.dut.reference_layer.'+n+')' for n in names)+',\n .rgb(golden_renderer));\n','ascii')
    with (run/'reference_ui_skin.mem').open('w',encoding='ascii',newline='\n') as f:
        for name in ['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']:
            f.writelines(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in Image.open(ROOT/'assets/new_ui'/f'{name}_material.png').convert('RGB').getdata())
    # Keep the formal initialization input identical to the reviewed run.
    # This wide preview ROM still has to be replaced by A3/A4's hardware path.
    shutil.copyfile(run/'reference_ui_skin.mem',SRC/'reference_ui_skin.mem')
    for name in ['story_font.mem','story_sprites.mem','reference_ui_material.mem','reference_ui_digits.mem','ui_panel_map.mem','ui_panel_pixels.mem','ui_panel_palette.mem','ui_font_5x7.mem']:
        shutil.copyfile(SRC/name,run/name)
    for name in ['ui_panel_map.mem','ui_panel_pixels.mem','ui_panel_palette.mem','ui_font_5x7.mem']:shutil.copyfile(SRC/name,OUT/name)
    setup=('@echo off\nset "TEMP='+str(OUT/'os_tmp')+'"\nset "TMP='+str(OUT/'os_tmp')+'"\n'
      'set "HOMEDRIVE=C:"\nset "HOMEPATH=\\Users\\qiguidie"\n'
      'call D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1\n')
    modules=['ui_font_5x7','ui_text_raster','ui_panel_atlas','ui_basic_layer','hud_font_rom','hud_text','scene_sprite_rom','story_scene','core_renderer','reference_ui_renderer','story_ui']
    files=[SRC/(name+'.v') for name in modules]+[OUT/'reference_ui_renderer_a1.v',ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v',ROOT/'Tetris.sim/story_visual/ui_a2_integration_tb.v']
    bat=setup+'call xvlog.bat --relax -i "'+SRC.as_posix()+'" -i "'+run.as_posix()+'" '+' '.join('"'+f.as_posix()+'"' for f in files)+' --nolog >compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
    bat+='call xelab.bat ui_a2_integration_tb -s ui_a2_integration --timescale 1ns/1ps --nolog >elaborate.log 2>&1\nif errorlevel 1 exit /b 2\n'
    bat+='call xsim.bat ui_a2_integration -runall --nolog >render.log 2>&1\nif errorlevel 1 exit /b 3\ntype render.log\n'
    (run/'run.bat').write_text(bat,'ascii')
    (OUT/'measure.bat').write_text(setup+'call vivado.bat -mode batch -notrace -nojournal -log "'+(OUT/'synthesis.log').as_posix()+'" -source "'+(ROOT/'tools/measure_new_ui_a2.tcl').as_posix()+'" >measurement_console.log 2>&1\n','ascii')
    font_run=OUT/'font_render';font_run.mkdir(exist_ok=True)
    shutil.copyfile(SRC/'ui_font_5x7.mem',font_run/'ui_font_5x7.mem')
    font_bat=setup+'call xvlog.bat --relax "'+(SRC/'ui_font_5x7.v').as_posix()+'" "'+(ROOT/'Tetris.sim/story_visual/ui_font_5x7_tb.v').as_posix()+'" --nolog >compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
    font_bat+='call xelab.bat ui_font_5x7_tb -s ui_a2_font --timescale 1ns/1ps --nolog >elaborate.log 2>&1\nif errorlevel 1 exit /b 2\ncall xsim.bat ui_a2_font -runall --nolog >render.log 2>&1\nif errorlevel 1 exit /b 3\ntype render.log\n'
    (font_run/'run.bat').write_text(font_bat,'ascii')
    print('A2_INPUTS_PREPARED',flush=True)
    if args.prepare_only:return
    subprocess.run(['cmd','/d','/c','run.bat'],cwd=font_run,check=True)
    font_log=(font_run/'render.log').read_text('utf-8',errors='replace')
    assert 'BOTH_PIPELINE_FORMS' in font_log and 'FONT_PIXEL_MISMATCH' not in font_log
    subprocess.run(['cmd','/d','/c','measure.bat'],cwd=OUT,check=True)
    subprocess.run(['cmd','/d','/c','run.bat'],cwd=run,check=True)
    log=(run/'render.log').read_text('utf-8',errors='replace')
    assert 'A2_ALL_INTEGRATION_FRAMES_PASS' in log and 'A2_PARITY_FAIL' not in log
    print('A2_ALL_RUNS_PASS',flush=True)

if __name__=='__main__':main()
