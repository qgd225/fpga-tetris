@echo off
chcp 936 >nul
title Tetris 一键启动（自动设置静态ARP + 画面和按键）
cd /d "%~dp0"
setlocal

set "PY="
for /f "delims=" %%p in ('where python 2^>nul') do if not defined PY set "PY=%%p"
set "TETRIS_ARP_PS1=%CD%\set_static_arp.py"

echo ============================================================
echo    Tetris   PC 端一键启动
echo    FPGA: 192.168.0.2    本脚本会自动: 选网卡 -^> 设静态ARP -^> 开画面和按键
echo ============================================================
echo.

if not defined PY (
  echo [错误] 没找到 python。请装 Python 3 并在安装时勾选 "Add Python to PATH"。
  echo.
  pause
  exit /b 1
)

echo [1/3] 检查当前静态 ARP / 路由 ...
"%PY%" set_static_arp.py --check
set ARP_CHECK=%ERRORLEVEL%
echo.
if "%ARP_CHECK%"=="0" goto arp_ok

echo [2/3] 设置静态 ARP（会弹 UAC 提权窗口，点 "是"）...
powershell -NoProfile -Command "$p = Start-Process -Verb RunAs -Wait -PassThru -FilePath '%PY%' -ArgumentList $env:TETRIS_ARP_PS1; exit $p.ExitCode"
set RC=%ERRORLEVEL%
if exist "%TEMP%\tetris_static_arp.log" (
  echo ---- 设置结果 ----
  type "%TEMP%\tetris_static_arp.log"
  echo ------------------
)
if "%RC%"=="0" goto arp_done
echo.
echo [注意] 静态 ARP 没设置成功 ^(返回码 %RC%^)。
echo        画面仍能显示（FPGA 用广播发画面，不依赖 ARP），但 PC 按键可能无效。
echo.
goto arp_done

:arp_ok
echo [2/3] 静态 ARP 已正常，跳过 UAC 提权。
echo.

:arp_done
echo [3/3] 检查依赖并启动 画面 + 按键 程序 ...
"%PY%" -c "import PIL, tkinter" >nul 2>&1
if errorlevel 1 (
  echo [依赖] 正在安装 pillow ...
  "%PY%" -m pip install --disable-pip-version-check pillow
  if errorlevel 1 goto dep_fail
)
"%PY%" -c "import pynput" >nul 2>&1
if errorlevel 1 (
  echo [依赖] 正在安装 pynput ...
  "%PY%" -m pip install --disable-pip-version-check pynput
  if errorlevel 1 goto dep_fail
)

echo.
"%PY%" -u net_screen_view.py
set VIEW_RC=%ERRORLEVEL%
if not "%VIEW_RC%"=="0" (
  echo.
  echo [程序异常退出] 请查看 tools\startup_error.log，并把报错截图给我。
  pause
)
goto end
:dep_fail
echo.
echo [依赖安装失败] 请检查网络，或在命令行运行:
echo   "%PY%" -m pip install pillow pynput
pause
:end
endlocal
