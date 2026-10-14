@echo off
chcp 936 >nul
cd /d "%~dp0"
title Tetris_text2 画面+按键

echo ============================================================
echo    Tetris_text2    画面显示 + 键盘按键  (PC 端)
echo ------------------------------------------------------------
echo    先确认已经跑过一次: 一次性-设置静态ARP.bat
echo    键盘: 方向键 左/右/下/上 (上=旋转)
echo          小键盘 5=开始/暂停  0=保持  9=复位 (要开 NumLock)
echo ============================================================
echo.

where python >nul 2>nul
if errorlevel 1 (
  echo [错误] 没找到 python 命令。
  echo        请先装 Python 3, 安装时勾选 "Add Python to PATH"。
  echo.
  pause
  exit /b 1
)

python -c "import PIL, pynput" >nul 2>nul
if errorlevel 1 (
  echo 正在安装依赖 pillow pynput, 请稍等 ...
  python -m pip install pillow pynput
  if errorlevel 1 (
    echo 默认源没成功, 改用清华镜像重试 ...
    python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pillow pynput
  )
  echo.
)

python net_screen_view.py
if errorlevel 1 (
  echo.
  echo [程序异常退出] 把上面的提示截图发我。
  pause
)