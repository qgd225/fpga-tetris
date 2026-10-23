@echo off
chcp 936 >nul
title Tetris PC 一键启动
cd /d "%~dp0"
setlocal

if exist "%~dp0TetrisPC.exe" goto run_exe

set "PY="
for /f "delims=" %%p in ('py -3 -c "import sys; print(sys.executable)" 2^>nul') do if not defined PY set "PY=%%p"
if not defined PY (
  for /f "delims=" %%p in ('where python 2^>nul') do (
    if not defined PY (
      echo %%p | findstr /I /C:"\WindowsApps\" >nul
      if errorlevel 1 set "PY=%%p"
    )
  )
)
if not defined PY goto no_python

echo [启动] 使用 Python 开发模式...
"%PY%" -c "import PIL, tkinter, pynput" >nul 2>&1
if errorlevel 1 (
  echo [依赖] 正在安装 Pillow 和 pynput...
  "%PY%" -m pip install --disable-pip-version-check pillow pynput
  if errorlevel 1 goto dep_fail
)
"%PY%" -u tetris_pc_launcher.py
goto end

:run_exe
"%~dp0TetrisPC.exe"
if errorlevel 1 pause
goto end

:no_python
echo.
echo [错误] 未找到可用的 Python。
echo 请直接使用随包提供的 tools\TetrisPC.exe，无需安装 Python。
echo 如果 TetrisPC.exe 不存在，请重新解压完整压缩包。
pause
exit /b 1

:dep_fail
echo.
echo [错误] Python 依赖安装失败，请检查网络后重试。
pause
exit /b 1

:end
endlocal
