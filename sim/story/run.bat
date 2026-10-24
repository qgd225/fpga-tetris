@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\story_tb.v ..\..\..\Tetris.srcs\sources_1\new\story_controller.v ..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_pixel_mapper.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_speed_control.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_hold_controller.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_ghost_scanner.v ..\..\..\Tetris.srcs\sources_1\new\solo_hint.v ..\..\..\Tetris.srcs\sources_1\new\scoring.v --nolog
if errorlevel 1 exit /b 1
call xelab.bat story_tb -s story --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat story -runall --nolog
