"""Compare preview ROM optimization against the original Xilinx IP simulation model."""
from pathlib import Path
import subprocess, shutil, hashlib, json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'temporary/rom_opt_20261029/equivalence'
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 src=ROOT/'Tetris.srcs/sources_1/new';ip=ROOT/'Tetris.srcs/sources_1/ip/Tetromino'
 files=[ip/'simulation/blk_mem_gen_v8_4.v',ip/'sim/Tetromino.v']
 for name in ['Next_piece','hold_piece']:
  ref=ROOT/'assets/rom_optimization'/(name+'.v.snapshot');target=OUT/(name+'_before.v');shutil.copyfile(ref,target);files += [target,src/(name+'.v')]
 files += [ROOT/'Tetris.sim/optimization/spawn_rom_equivalence_tb.v']
 shutil.copyfile(ip/'Tetromino.mif',OUT/'Tetromino.mif')
 commands=['@echo off','call D:\\xilinx\\Vivado\\2018.3\\settings64.bat >nul 2>&1', 'call xvlog.bat '+ ' '.join('"'+str(p)+'"' for p in files)+' -i "'+str(src)+'" --nolog', 'if errorlevel 1 exit /b 1','call xelab.bat spawn_rom_equivalence_tb -s spawn_eq --timescale 1ns/1ps -L unisims_ver --nolog','if errorlevel 1 exit /b 1','call xsim.bat spawn_eq -runall --nolog','if errorlevel 1 exit /b 1']
 bat=OUT/'run.bat';bat.write_text('\n'.join(commands)+'\n','ascii')
 with (OUT/'console.log').open('w') as log:result=subprocess.run(['cmd.exe','/d','/c',str(bat)],cwd=OUT,stdout=log,stderr=subprocess.STDOUT)
 content=(OUT/'console.log').read_text(errors='replace');passed=result.returncode==0 and 'ALL PASS SPAWN_ROM_EQUIVALENCE' in content and 'FAIL i=' not in content
 inputs=files+[src/'spawn_shape.vh',ROOT/'assets/rom_optimization/Next_piece.v.snapshot',ROOT/'assets/rom_optimization/hold_piece.v.snapshot',ip/'Tetromino.mif',ROOT/'Tetris.srcs/sources_1/ip/shape_rom.coe']
 (OUT/'summary.json').write_text(json.dumps({'pass':passed,'inputs':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs},'markers':[line for line in content.splitlines() if 'ALL PASS' in line]},indent=2)+'\n')
 print('SPAWN_ROM_EQUIVALENCE '+('PASS' if passed else 'FAIL')+' '+str(OUT/'console.log'))
 return 0 if passed else 1
if __name__=='__main__':raise SystemExit(main())
