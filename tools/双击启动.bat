@echo off
chcp 936 >nul
title Tetris_text2 一键启动（自动设置静态ARP + 画面和按键）
cd /d "%~dp0"
setlocal

set "PY="
for /f "delims=" %%p in ('where python 2^>nul') do if not defined PY set "PY=%%p"
set "TETRIS_ARP_PS1=%CD%\set_static_arp.py"

echo ============================================================
echo    Tetris_text2   PC 端一键启动
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
echo.

echo [2/3] 设置静态 ARP（会弹 UAC 提权窗口，点 "是"）...
powershell -NoProfile -Command "$p = Start-Process -Verb RunAs -Wait -PassThru -FilePath '%PY%' -ArgumentList $env:TETRIS_ARP_PS1; exit $p.ExitCode"
set RC=%ERRORLEVEL%
if exist "%TEMP%\tetris_static_arp.log" (
  echo ---- 设置结果 ----
  type "%TEMP%\tetris_static_arp.log"
  echo ------------------
)
if not "%RC%"=="0" (
  echo.
  echo [注意] 静态 ARP 没设置成功 ^(返回码 %RC%^)。
  echo        画面仍能显示（FPGA 用广播发画面，不依赖 ARP），但 PC 按键可能无效。
  echo.
)

echo [3/3] 启动 画面 + 按键 程序 ...
echo.
"%PY%" net_screen_view.py
if errorlevel 1 (
  echo.
  echo [程序异常退出] 把上面的报错截图给我。
  pause
)
endlocal
