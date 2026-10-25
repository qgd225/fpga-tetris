@echo off
cd /d "%~dp0"
if not exist logs mkdir logs
cmd /d /c call "%~dp0duo\run.bat" > "%~dp0logs\duo.log" 2>&1
cmd /d /c call "%~dp0frame_duo\run.bat" > "%~dp0logs\frame_duo.log" 2>&1
cmd /d /c call "%~dp0level\run.bat" > "%~dp0logs\level.log" 2>&1
cmd /d /c call "%~dp0sound\run.bat" > "%~dp0logs\sound.log" 2>&1
cmd /d /c call "%~dp0input_route\run.bat" > "%~dp0logs\input_route.log" 2>&1
cmd /d /c call "%~dp0net_keyboard\run.bat" > "%~dp0logs\net_keyboard.log" 2>&1
cmd /d /c call "%~dp0horizontal_repeat\run.bat" > "%~dp0logs\horizontal_repeat.log" 2>&1
cmd /d /c call "%~dp0hold_gesture\run.bat" > "%~dp0logs\hold_gesture.log" 2>&1
cmd /d /c call "%~dp0solo_hint\run.bat" > "%~dp0logs\solo_hint.log" 2>&1
cmd /d /c call "%~dp0rgb_palette\run.bat" > "%~dp0logs\rgb_palette.log" 2>&1
cmd /d /c call "%~dp0lutram\run.bat" > "%~dp0logs\lutram.log" 2>&1
cmd /d /c call "%~dp0optimization\run.bat" > "%~dp0logs\optimization.log" 2>&1
call "%~dp0hdmi_audio\run.bat" > "%~dp0logs\hdmi_audio.log" 2>&1
cmd /d /c call "%~dp0story\run.bat" > "%~dp0logs\story.log" 2>&1
cmd /d /c call "%~dp0story_layout\run.bat" > "%~dp0logs\story_layout.log" 2>&1
cmd /d /c call "%~dp0story_visual\run.bat" > "%~dp0logs\story_visual.log" 2>&1
cmd /d /c call "%~dp0story_audio\run.bat" > "%~dp0logs\story_audio.log" 2>&1
echo ===== SUMMARY =====
set failures=0
for %%f in (duo frame_duo level sound input_route net_keyboard horizontal_repeat hold_gesture solo_hint rgb_palette lutram optimization hdmi_audio story story_layout story_visual story_audio) do (
  echo --- %%f ---
  findstr /C:"ALL PASS" /C:"FAILED" "%~dp0logs\%%f.log"
  findstr /C:"ALL PASS" "%~dp0logs\%%f.log" >nul
  if errorlevel 1 set /a failures+=1 >nul
  findstr /C:"FAILED" /C:"ERROR:" /C:"XVLOG_FAIL" /C:"XELAB_FAIL" "%~dp0logs\%%f.log" >nul
  if not errorlevel 1 set /a failures+=1 >nul
)
if not "%failures%"=="0" exit /b 1
exit /b 0
