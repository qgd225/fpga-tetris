"""Reproduce A1 standalone prototypes, measurements and palette review frames.

Does not open/reset the formal project or generate a bitstream. --prepare-only
only writes run inputs; --reuse-assets preserves already measured asset inputs.
"""
from pathlib import Path
import argparse,json,re,shutil,subprocess,sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'temporary/new_ui_a1'
SRC=ROOT/'Tetris.srcs/sources_1/new'

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare-only',action='store_true')
    p.add_argument('--reuse-assets',action='store_true');args=p.parse_args()
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'os_tmp').mkdir(exist_ok=True)
    if not args.reuse_assets:
        for command in [
          ['analyze_new_ui_assets.py'],['build_new_ui_palette.py'],
          ['analyze_new_ui_assets.py','--input-materials',str(ROOT/'assets/new_ui'),'--output',str(OUT/'near')]]:
            subprocess.run([sys.executable,str(ROOT/'tools'/command[0]),*command[1:]],cwd=ROOT,check=True)
    setup=('@echo off\nset "TEMP='+str(OUT/'os_tmp')+'"\nset "TMP='+str(OUT/'os_tmp')+'"\n'
      'set "HOMEDRIVE=C:"\nset "HOMEPATH=\\Users\\qiguidie"\n'
      'call D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1\n')
    def simrun(folder,top,files,include=None):
        folder.mkdir(exist_ok=True)
        inc=' -i "'+str(include)+'"' if include else ''
        body=setup+'call xvlog.bat --relax'+inc+' '+' '.join('"'+str(f)+'"' for f in files)+' --nolog >compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
        body+='call xelab.bat '+top+' -s '+top+'_snapshot --timescale 1ns/1ps --nolog >elaborate.log 2>&1\nif errorlevel 1 exit /b 2\n'
        body+='call xsim.bat '+top+'_snapshot -runall --nolog >render.log 2>&1\nif errorlevel 1 exit /b 3\ntype render.log\n'
        (folder/'run.bat').write_text(body,'ascii')
    wrappers=[];probes=[];calls=[]
    for name in ['next','core']:
        for flavor in ['raw','near']:
            folder=(OUT if flavor=='raw' else OUT/'near')/name
            meta=json.loads((folder/'metadata.json').read_text('utf-8'))
            top=f'ui_a1_{name}_{flavor}';target=OUT/(top+'.v')
            target.write_text((folder/'measure.v').read_text('ascii').replace(f'ui_a1_{name}_measure',top),'ascii')
            wrappers.append(target);probes.append(f'{{{top} {{{target.as_posix()}}}}}')
            w,h=meta['size'];calls.append(f'capture({len(calls)},{w},{h},"{(folder/"expected.mem").as_posix()}","{name}_{flavor}.ppm");')
    render=OUT/'render';render.mkdir(exist_ok=True)
    (render/'ui_a1_capture_calls.vh').write_text('\n'.join(calls)+'\n','ascii')
    simrun(render,'ui_exact_tile_rom_tb',[SRC/'ui_exact_tile_rom.v',*wrappers,ROOT/'Tetris.sim/story_visual/ui_exact_tile_rom_tb.v'],render)
    # Font stays tied to the currently frozen renderer alphabet.
    source=(SRC/'reference_ui_renderer.v').read_bytes().decode('gbk')
    rows={int(ch):int(bits,2) for ch,bits in re.findall(r"8'd(\d+):bitmap=35'b([01]{35})",source)}
    (SRC/'ui_font_5x7.mem').write_text(''.join(f'{rows.get(i,0):09x}\n' for i in range(128)),'ascii')
    font_wrapper=OUT/'ui_a1_font_measure.v'
    font_wrapper.write_text('module ui_a1_font_measure(input clk,reset_n,input [7:0] character,input [2:0] column,row,output lit);\nui_font_5x7 #(.INIT_FILE("'+(SRC/'ui_font_5x7.mem').as_posix()+'")) font(clk,reset_n,character,column,row,lit);\nendmodule\n','ascii')
    probes.append('{ui_a1_font_measure {'+font_wrapper.as_posix()+'}}')
    (OUT/'probes.tcl').write_text('set ui_a1_probes {\n'+'\n'.join(probes)+'\n}\n','ascii')
    font_render=OUT/'font_render';font_render.mkdir(exist_ok=True)
    shutil.copyfile(SRC/'ui_font_5x7.mem',font_render/'ui_font_5x7.mem')
    simrun(font_render,'ui_font_5x7_tb',[SRC/'ui_font_5x7.v',ROOT/'Tetris.sim/story_visual/ui_font_5x7_tb.v'])
    (OUT/'measure.bat').write_text(setup+'call vivado.bat -mode batch -notrace -nojournal -log "'+str(OUT/'synthesis.log')+'" -source "'+str(ROOT/'tools/measure_new_ui_a1.tcl')+'" >measurement_console.log 2>&1\n','ascii')
    # Appearance uses the existing full-frame preview path. Never label this
    # as proof that the full compressed renderer has been integrated.
    frames=OUT/'palette_render';frames.mkdir(exist_ok=True)
    with (frames/'reference_ui_skin.mem').open('w',encoding='ascii',newline='\n') as f:
        for name in ['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']:
            f.writelines(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in Image.open(ROOT/'assets/new_ui'/f'{name}_material.png').convert('RGB').getdata())
    for name in ['story_font.mem','story_sprites.mem','reference_ui_material.mem','reference_ui_digits.mem']:
        shutil.copyfile(SRC/name,frames/name)
    # A2 dependency compatibility: the current preview now uses common panels/font.
    if 'ui_basic_layer basic(' in (SRC/'reference_ui_renderer.v').read_bytes().decode('gbk'):
        for name in ['ui_font_5x7.mem','ui_panel_map.mem','ui_panel_pixels.mem','ui_panel_palette.mem']:
            shutil.copyfile(SRC/name,frames/name)
    sources=[SRC/(name+'.v') for name in ['hud_font_rom','hud_text','scene_sprite_rom','story_scene','core_renderer','reference_ui_renderer','story_ui']]
    if 'ui_basic_layer basic(' in (SRC/'reference_ui_renderer.v').read_bytes().decode('gbk'):
        sources[:0]=[SRC/(name+'.v') for name in ['ui_font_5x7','ui_text_raster','ui_panel_atlas','ui_basic_layer']]
    if 'ui_mission_layer mission(' in (SRC/'reference_ui_renderer.v').read_bytes().decode('gbk'):
        sources[:0]=[SRC/'ui_material_atlas.v',SRC/'ui_mission_layer.v']
        for path in list(SRC.glob('ui_material_*.mem'))+[SRC/n for n in ['ui_charge_x.mem','ui_charge_y.mem','ui_debris_x.mem','ui_debris_y.mem','ui_track_limit.mem','ui_core_gradient.mem','ui_legend_circle.mem']]:
            shutil.copyfile(path,frames/path.name)
    sources.extend(ROOT/'Tetris.sim/story_visual'/name for name in ['ui_scenes_tb.v','ui_a1_palette_frame_tb.v'])
    simrun(frames,'ui_a1_palette_frame_tb',sources,SRC)
    print('A1_INPUTS_PREPARED',flush=True)
    if args.prepare_only:return
    for directory,script in [(render,'run.bat'),(font_render,'run.bat'),(OUT,'measure.bat'),(frames,'run.bat')]:
        subprocess.run(['cmd','/d','/c',script],cwd=directory,check=True)
    print('A1_RUN_COMPLETE',flush=True)

if __name__=='__main__':main()
