@echo off
setlocal
chcp 65001 >nul
python "%~dp0publish_bitstream.py" "%~dp0..\bit\Tetris.bit" --root "%~dp0.."
if errorlevel 1 exit /b 1
