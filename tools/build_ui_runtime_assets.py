"""Deterministic hardware UI tables; public game parameters remain authoritative."""
from pathlib import Path
import re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'
def main():
    text=(SRC/'game_mode_params.vh').read_text('ascii')
    def table(name):
        rows={int(a):int(b) for a,b in re.findall(r"3'd(\d+):"+name+r"=8'd(\d+);",text)}
        assert set(rows)==set(range(8)),name
        return [rows[i] for i in range(8)]
    targets=table('mode_target');totals=table('mode_total')
    def write(name,values,digits):
        (SRC/name).write_text(''.join(f'{n:0{digits}x}\n' for n in values),'ascii')
    write('ui_charge_percent.mem',[min(100,c*100//t) for t in targets for c in range(64)],2)
    write('ui_debris_percent.mem',[c*100//t for t in totals for c in range(128)],3)
    write('ui_reserve_height.mem',[c*288//174 for c in range(256)],4)
    write('ui_reserve_percent.mem',[min(100,c*100//174) for c in range(256)],2)
    for script in ['pack_ui_voice_rom.py','build_ui_material_atlas.py','build_ui_ship_mask.py','build_ui_planet.py','build_ui_text_templates.py']:
        subprocess.run([sys.executable,str(ROOT/'tools'/script)],cwd=ROOT,check=True)
    print('UI_RUNTIME_ASSETS_READY')
if __name__=='__main__':main()
