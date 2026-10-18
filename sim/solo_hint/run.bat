@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\solo_hint_tb.v ..\..\..\Tetris_text2.srcs\sources_1\new\solo_hint.v --nolog
if errorlevel 1 ( echo XVLOG_FAIL & exit /b 1 )
call xelab.bat solo_hint_tb -s snap --timescale 1ns/1ps --nolog
if errorlevel 1 ( echo XELAB_FAIL & exit /b 1 )
call xsim.bat snap -runall --nolog
