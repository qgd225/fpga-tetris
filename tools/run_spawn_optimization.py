"""Build the spawn ROM change against frozen checked-in assets; validate before publishing."""
from pathlib import Path
import subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'temporary/rom_opt_20261029/build'
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 text=(ROOT/'tools/build_story.tcl').read_text('utf-8')
 text=text.replace('set root [file normalize [file join [file dirname [info script]] ..]]','set root {'+ROOT.as_posix()+'}')
 start=text.index('puts [exec python [file join $root tools build_story_assets.py]]')
 end=text.index('open_project [file join $root Tetris.xpr]',start)
 text=text[:start]+'# This optimization changes no asset; use frozen source-controlled memories.\n'+text[end:]
 text=text.replace('foreach name {rhythm_params.vh','foreach name {spawn_shape.vh rhythm_params.vh')
 tcl=OUT/'build.tcl';tcl.write_text(text,'utf-8')
 log=OUT/'console.log'
 with log.open('w') as stream:
  result=subprocess.run(['D:/xilinx/Vivado/2018.3/bin/vivado.bat','-mode','batch','-notrace','-log',str(OUT/'vivado.log'),'-journal',str(OUT/'vivado.jou'),'-source',str(tcl),'-tclargs','story_rom_opt_20261029','local'],cwd=OUT,stdout=stream,stderr=subprocess.STDOUT)
 content=log.read_text(errors='replace');passed=result.returncode==0 and 'STORY_BUILD_PASS story_rom_opt_20261029' in content
 print('SPAWN_OPT_BUILD '+('PASS' if passed else 'FAIL')+' '+str(log))
 return 0 if passed else 1
if __name__=='__main__':raise SystemExit(main())
