@echo off
cd /d "%~dp0"
if not exist logs mkdir logs
call "%~dp0duo\run.bat" > "%~dp0logs\duo.log" 2>&1
call "%~dp0frame_duo\run.bat" > "%~dp0logs\frame_duo.log" 2>&1
call "%~dp0level\run.bat" > "%~dp0logs\level.log" 2>&1
call "%~dp0sound\run.bat" > "%~dp0logs\sound.log" 2>&1
call "%~dp0input_route\run.bat" > "%~dp0logs\input_route.log" 2>&1
call "%~dp0horizontal_repeat\run.bat" > "%~dp0logs\horizontal_repeat.log" 2>&1
call "%~dp0hold_gesture\run.bat" > "%~dp0logs\hold_gesture.log" 2>&1
call "%~dp0solo_hint\run.bat" > "%~dp0logs\solo_hint.log" 2>&1
call "%~dp0rgb_palette\run.bat" > "%~dp0logs\rgb_palette.log" 2>&1
call "%~dp0hdmi_audio\run.bat" > "%~dp0logs\hdmi_audio.log" 2>&1
echo ===== SUMMARY =====
for %%f in (duo frame_duo level sound input_route horizontal_repeat hold_gesture solo_hint rgb_palette hdmi_audio) do (
  echo --- %%f ---
  findstr /C:"ALL PASS" /C:"FAILED" "%~dp0logs\%%f.log"
)
