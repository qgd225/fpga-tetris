@echo off
cd /d "%~dp0"
if not exist logs mkdir logs
call "%~dp0duo\run.bat" > "%~dp0logs\duo.log" 2>&1
call "%~dp0frame_duo\run.bat" > "%~dp0logs\frame_duo.log" 2>&1
call "%~dp0level\run.bat" > "%~dp0logs\level.log" 2>&1
call "%~dp0sound\run.bat" > "%~dp0logs\sound.log" 2>&1
echo ===== SUMMARY =====
for %%f in (duo frame_duo level sound) do (
  echo --- %%f ---
  findstr /C:"ALL PASS" /C:"FAILED" "%~dp0logs\%%f.log"
)
