@echo off
cd /d "%~dp0"
for %%s in (run run_hint run_metadata run_storage) do (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%%s.ps1"
  if errorlevel 1 exit /b 1
)
echo === ALL PASS: OPTIMIZATION ===
exit /b 0
