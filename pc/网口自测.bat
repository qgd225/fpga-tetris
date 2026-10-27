@echo off
setlocal
chcp 936 >nul
cd /d "%~dp0"
if exist "%~dp0..\TetrisPC.exe" (
  if "%~1"=="" (
    "%~dp0..\TetrisPC.exe" --self-test --interactive
  ) else (
    "%~dp0..\TetrisPC.exe" --self-test %*
  )
) else (
  if "%~1"=="" (
    py -3 "%~dp0network_selftest.py" --interactive
  ) else (
    py -3 "%~dp0network_selftest.py" %*
  )
)
set "result=%errorlevel%"
echo.
pause
exit /b %result%
