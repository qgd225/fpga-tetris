@echo off
setlocal
chcp 65001 >nul
set PYTHONIOENCODING=utf-8
python "%~dp0local_build.py" 2>nul
set "build_result=%errorlevel%"
if "%build_result%"=="9009" (
  echo 是否通过：未通过
  echo 时序指标：未取得
  echo bit 保存路径：本次未保存
  echo bin 保存路径：本次未保存
)
pause >nul
exit /b %build_result%
