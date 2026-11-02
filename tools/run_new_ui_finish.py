"""Continuous final UI verification/build preparation; all work data is temporary."""
from pathlib import Path
import argparse,shutil,subprocess,sys,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new';OUT=ROOT/'temporary/ui_polish_20261029'
MODULES=['ui_font_5x7','ui_text_raster','ui_text_compact','ui_material_atlas','ui_mission_layer','ui_basic_layer','ui_hull_background','ui_core_feedback','reference_ui_renderer','story_ui']
def setup():
    return ('@echo off\nset "TEMP='+str(OUT/'os_tmp')+'"\nset "TMP='+str(OUT/'os_tmp')+'"\nset "HOMEDRIVE=C:"\nset "HOMEPATH=\\Users\\qiguidie"\ncall D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1\n')
def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare-only',action='store_true');p.add_argument('--quick',action='store_true');p.add_argument('--planet-review',action='store_true');a=p.parse_args()
    OUT.mkdir(exist_ok=True);(OUT/'os_tmp').mkdir(exist_ok=True);run=OUT/('planet_review' if a.planet_review else 'quick' if a.quick else 'render');run.mkdir(exist_ok=True)
    for f in SRC.glob('ui_*.mem'):shutil.copyfile(f,run/f.name);shutil.copyfile(f,OUT/f.name)
    old=ROOT/'docs/参考图/预览图/RTL生成/20261028_新UI_A3_重点模块接入'
    full={'duo_campaign':'双人闯关','solo_campaign':'单人闯关','duo_endless':'双人无尽','solo_endless':'单人无尽'}
    core={'core_locked':'LOCKED六圈锁链','core_half':'HALF','core_online7':'ONLINE七段','core_success8':'成功八段'}
    original_mask=Image.open(ROOT/'assets/new_ui/surfaces/pipe_visibility.png').convert('L')
    transformed_mask=Image.new('L',(1280,720))
    for y in range(32,342):
        for x in range(1049,1179):
            sx=x if x<1080 else 1080 if x<1104 else x-24
            if original_mask.getpixel((sx,y)):transformed_mask.putpixel((x,y),255)
    pipe_source=Image.open(ROOT/'assets/new_ui/surfaces/pipe.png').convert('RGB')
    style=json.loads((ROOT/'assets/new_ui/surfaces/changes.json').read_text('utf-8'))
    clear=Image.new('1',(1280,720))
    for xx,yy in style['transparent_corners']:clear.putpixel((xx,yy),1)
    (run/'corner_clear.mem').write_text(''.join('1\n' if q else '0\n' for q in clear.getdata()),'ascii')
    for name,label in full.items():
        im=Image.open(old/f'20261028_{label}_RTL.png').convert('RGB');before=im.copy()
        style_key='duo_endless' if 'endless' in name else name
        if style_key=='solo_endless':style_key='duo_endless'
        for xx,yy,old_rgb,new_rgb in style['rgb_changes'][style_key]:
            if name.startswith('solo') and 959<=xx<1114 and 148<=yy<320:continue
            if im.getpixel((xx,yy))==tuple(old_rgb):im.putpixel((xx,yy),tuple(new_rgb))
        if 'campaign' in name:
            for y in range(32,342):
                for x in range(1049,1179):
                    if transformed_mask.getpixel((x,y)):
                        sx=x if x<1080 else 1080 if x<1104 else x-24
                        im.putpixel((x,y),pipe_source.getpixel((sx,y)))
        im.paste(before.crop((1124,214,1214,570)),(1148,214))
        (run/f'{name}_expected.mem').write_text(''.join(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in im.getdata()),'ascii')
    for name,label in core.items():
        im=Image.open(old/'局部状态'/f'20261028_核心_{label}_RTL.png').convert('RGB')
        for vv in range(370):
            for uu in range(100):
                xx=1144+uu;yy=208+vv
                if 1148<=xx<1238 and 214<=yy<570:continue
                if transformed_mask.getpixel((xx,yy)):im.putpixel((uu,vv),pipe_source.getpixel((xx-24,yy)))
        (run/f'{name}_expected.mem').write_text(''.join(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in im.getdata()),'ascii')
    (run/'pipe_mask.mem').write_text(''.join('1\n' if p else '0\n' for p in transformed_mask.getdata()),'ascii')
    files=[SRC/(n+'.v') for n in MODULES]+[ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v',ROOT/'Tetris.sim/story_visual/ui_finish_tb.v',ROOT/'Tetris.sim/story_visual/ui_layout_quick_tb.v',ROOT/'Tetris.sim/story_visual/ui_planet_quick_tb.v']
    bat=setup()+'call xvlog.bat --relax -i "'+SRC.as_posix()+'" '+' '.join('"'+f.as_posix()+'"' for f in files)+' --nolog >compile.log 2>&1\nif errorlevel 1 exit /b 1\n'
    top='ui_planet_quick_tb' if a.planet_review else 'ui_layout_quick_tb' if a.quick else 'ui_finish_tb'
    bat+='call xelab.bat '+top+' -s ui_finish --timescale 1ns/1ps --nolog >elaborate.log 2>&1\nif errorlevel 1 exit /b 2\ncall xsim.bat ui_finish -runall --nolog >render.log 2>&1\nif errorlevel 1 exit /b 3\ntype render.log\n'
    (run/'run.bat').write_text(bat,'ascii');print('FINAL_UI_INPUTS_PREPARED',flush=True)
    if a.prepare_only:return
    subprocess.run(['cmd','/d','/c','run.bat'],cwd=run,check=True)
    log=(run/'render.log').read_text('utf-8',errors='replace')
    assert 'FINAL_UI_ALL_FRAMES_PASS' in log and 'FINAL_UI_FAIL' not in log
    print('FINAL_UI_RENDER_PASS',flush=True)
if __name__=='__main__':main()
