@echo off
if not defined XILINX_VIVADO call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\rgb_palette_tb.v ..\..\..\Tetris.srcs\sources_1\new\rgb_to_palette.v --nolog
if errorlevel 1 ( echo XVLOG_FAIL & exit /b 1 )
call xelab.bat rgb_palette_tb -s snap --timescale 1ns/1ps --nolog
if errorlevel 1 ( echo XELAB_FAIL & exit /b 1 )
call xsim.bat snap -runall --nolog
