@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
python ..\..\prepare_nobom.py
if errorlevel 1 ( echo PREPARE_FAIL & exit /b 1 )
call xvlog.bat ..\..\_nobom\sim\input_route\input_route_tb.v ..\..\_nobom\Tetris.srcs\sources_1\new\control_route.v --nolog
if errorlevel 1 ( echo XVLOG_FAIL & exit /b 1 )
call xelab.bat input_route_tb -s snap --timescale 1ns/1ps --nolog
if errorlevel 1 ( echo XELAB_FAIL & exit /b 1 )
call xsim.bat snap -runall --nolog
