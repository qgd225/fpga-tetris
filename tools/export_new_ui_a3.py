"""Export only completed XSim P6 frames; indexes add labels outside pixels."""
from pathlib import Path
import hashlib,json,re,shutil,xml.etree.ElementTree as ET
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'
RUN=ROOT/'temporary/new_ui_a3';RENDER=RUN/'render'
REPORT=ROOT/'docs/reports/new_ui_a3_20261028'
PREVIEW=ROOT/'docs/参考图/预览图/RTL生成/20261028_新UI_A3_重点模块接入'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    log=(RENDER/'render.log').read_text('utf-8',errors='replace')
    assert 'A3_ALL_INTEGRATION_FRAMES_PASS' in log and 'A3_PARITY_FAIL' not in log
    atlas_log=(RUN/'atlas_test/test.log').read_text('utf-8',errors='replace')
    assert 'A3_ATLAS_ALL_PIXELS_PASS' in atlas_log and 'A3_ATLAS_FAIL' not in atlas_log
    REPORT.mkdir(exist_ok=True);PREVIEW.mkdir(exist_ok=True);(PREVIEW/'局部状态').mkdir(exist_ok=True)
    before=json.loads((RUN/'before.json').read_text('utf-8'))
    for name in ['Tetris.srcs/sources_1/new/story_ui.v','bit/Tetris.bit']:assert sha(ROOT/name)==before[name]
    frozen=ROOT/'docs/参考图/最新参考图/新UI'
    for rec in json.loads((frozen/'manifest.json').read_text('utf-8'))['records']:
        assert sha(frozen/rec['file'])==rec['sha256']
    ET.parse(ROOT/'Tetris.xpr')
    full={'duo_campaign':'双人闯关','solo_campaign':'单人闯关','duo_endless':'双人无尽','solo_endless':'单人无尽','menu_unchanged':'主菜单'}
    local={'mission_joints':'船况头与导管接缝','core_half':'核心_HALF','legend_rebuild':'刻度_REBUILD',
        'core_locked':'核心_LOCKED六圈锁链','legend_reconnect':'刻度_RECONNECT','core_five':'核心_五段',
        'legend_stabilize':'刻度_STABILIZE','core_online7':'核心_ONLINE七段','legend_recharge':'刻度_RECHARGE',
        'core_success8':'核心_成功八段','header_complete':'任务完成船况头','reserve_empty':'储备_空',
        'reserve_full':'储备_满','reserve_low':'储备_低量','reserve_critical':'储备_危急','comms_overlay':'对白覆盖'}
    outputs=[];frames=[];total=0
    for name,w,h,x,y in re.findall(r'A3_RTL_FRAME_DONE (\S+) (\d+) (\d+) ORIGIN (\d+) (\d+) ZERO_MISMATCHES',log):
        stem=Path(name).stem;w,h,x,y=map(int,(w,h,x,y));im=Image.open(RENDER/name).convert('RGB');assert im.size==(w,h)
        target=PREVIEW if stem in full else PREVIEW/'局部状态';label=(full|local)[stem]
        file=target/f'20261028_{label}_RTL.png';im.save(file)
        record={'file':file.relative_to(PREVIEW).as_posix(),'sha256':sha(file),'decoded_rgb_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'size':[w,h],'origin':[x,y],'mismatches':0}
        outputs.append(record);frames.append((stem,record));total+=w*h
    font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',21)
    # Integer enlargement only: frame pixels are never repainted or retouched.
    states=[('core_locked','锁定：六圈锁链'),('core_half','充能：三段'),('core_online7','运行：七段'),('core_success8','成功：八段')]
    canvas=Image.new('RGB',(1000,820),'#0a1622');draw=ImageDraw.Draw(canvas)
    for i,(stem,label) in enumerate(states):
        im=Image.open(RENDER/(stem+'.ppm')).convert('RGB').resize((200,740),Image.Resampling.NEAREST)
        canvas.paste(im,(i*250+25,60));draw.text((i*250+20,20),label,font=font,fill='#dceaf1')
    index=PREVIEW/'20261028_核心四状态_RTL索引.png';canvas.save(index)
    outputs.append({'file':index.name,'sha256':sha(index),'size':list(canvas.size),'kind':'integer_enlargement_index'})
    resources={}
    for n in ['ui_material_atlas','ui_mission_layer','ui_basic_layer']:
        u=(RUN/'synthesis'/f'{n}_utilization.rpt').read_text();t=(RUN/'synthesis'/f'{n}_timing.rpt').read_text()
        def value(label):return float(re.search(r'\| '+re.escape(label)+r'\s*\|\s*([\d.]+)',u)[1])
        timing_row=re.search(r'WNS\(ns\).*?\n\s*-+[^\n]*\n([^\n]+)',t,re.S)[1].split()
        wns,tns,whs,ths=map(float,(timing_row[0],timing_row[1],timing_row[4],timing_row[5]))
        assert wns>=0
        resources[n]={'LUT':int(value('Slice LUTs*')),'FF':int(value('Slice Registers')),'BRAM36':value('Block RAM Tile'),'DSP':int(value('DSPs')),
            'estimated_WNS_ns':wns,'estimated_TNS_ns':tns,'estimated_WHS_ns':whs,'estimated_THS_ns':ths}
        for suffix in ['utilization','timing','paths']:shutil.copyfile(RUN/'synthesis'/f'{n}_{suffix}.rpt',REPORT/f'{n}_{suffix}.rpt')
    for src,name in [(RENDER/'render.log','rgb_parity.log'),(RUN/'atlas_test/test.log','atlas_roundtrip.log')]:shutil.copyfile(src,REPORT/name)
    # The failed initial architecture is kept as an explicitly superseded result.
    for suffix in ['utilization','paths']:shutil.copyfile(RUN/'synthesis_attempt1'/f'ui_mission_layer_{suffix}.rpt',REPORT/f'initial_failed_mission_{suffix}.rpt')
    paths=[ROOT/'Tetris.xpr',ROOT/'Tetris.sim/story_visual/ui_a3_integration_tb.v',ROOT/'Tetris.sim/story_visual/ui_material_atlas_tb.v',ROOT/'Tetris.sim/story_visual/ui_scenes_tb.v']
    paths += [SRC/(n+'.v') for n in ['reference_ui_renderer','story_ui','ui_basic_layer','ui_mission_layer','ui_material_atlas','ui_text_raster','ui_font_5x7','hud_font_rom','hud_text','scene_sprite_rom','story_scene','core_renderer']]
    paths += [SRC/n for n in ['game_mode_params.vh','reference_ui_geometry.vh','story_palette.vh','reference_ui_skin.mem','reference_ui_material.mem','ui_font_5x7.mem','ui_panel_geometry.vh','ui_panel_map.mem','ui_panel_pixels.mem','ui_panel_palette.mem','story_font.mem','story_sprites.mem']]
    mat=json.loads((ROOT/'assets/new_ui/materials/manifest.json').read_text('utf-8'))
    paths += [SRC/n for n in mat['files_sha256']]
    paths += [ROOT/'tools'/n for n in ['build_ui_material_atlas.py','run_new_ui_a3.py','measure_new_ui_a3.tcl','export_new_ui_a3.py','run_new_ui_a1.py','run_new_ui_a2.py']]
    paths += list((ROOT/'assets/new_ui/verification/a2').glob('*'))
    paths += [ROOT/'assets/new_ui'/f'{n}_material.png' for n in ['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']]
    paths += [ROOT/'assets/reference_ui/pipe_removal_mask.png',ROOT/'assets/new_ui/materials/manifest.json']
    sources={p.relative_to(ROOT).as_posix():sha(p) for p in paths}
    # Verify the copied XSim ROMs still match the formal inputs reported here.
    for f in RENDER.glob('*.mem'):
        if (SRC/f.name).is_file():assert sha(f)==sha(SRC/f.name),(f.name,'run/formal mismatch')
    manifest={'date':'2026-10-28','phase':'A3重点模块接入，待用户审核','frame_count':len(frames),'compared_pixels':total,'mismatches':0,
        'atlas_pixels':372032,'atlas_nonsequential':4096,'latency_clocks':{'reference_ui_renderer':4,'story_ui':5},
        'resources_OOC_only':resources,'source_sha256':sources,'outputs':outputs,'bit_sha256_unchanged':sha(ROOT/'bit/Tetris.bit'),
        'frozen_PNGs_unchanged':True,'whole_design_validated':False,'decorations_cut':False,'dynamic_effects_cut':False}
    for d in [REPORT,PREVIEW]:(d/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({'frames':len(frames),'pixels':total,'resources':resources,'preview':str(PREVIEW)},ensure_ascii=False))

if __name__=='__main__':main()
