@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\frame_duo_tb.v ..\..\..\Tetris.srcs\sources_1\new\frame.v ..\..\..\Tetris.srcs\sources_1\new\frame_background.v ..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_pixel_mapper.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_speed_control.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_hold_controller.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_ghost_scanner.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_edge.v ..\..\..\Tetris.srcs\sources_1\new\timer.v ..\..\..\Tetris.srcs\sources_1\new\scoring.v ..\..\..\Tetris.srcs\sources_1\new\Next_piece.v ..\..\..\Tetris.srcs\sources_1\new\hold_piece.v ..\..\..\Tetris.srcs\sources_1\new\level.v ..\..\..\Tetris.srcs\sources_1\new\game_over.v ..\..\..\Tetris.srcs\sources_1\new\choose_menu.v ..\..\..\Tetris.srcs\sources_1\new\solo_hint.v --nolog
if errorlevel 1 ( echo XVLOG_FAIL & exit /b 1 )
call xelab.bat frame_duo_tb -s snap --timescale 1ns/1ps --nolog
if errorlevel 1 ( echo XELAB_FAIL & exit /b 1 )
call xsim.bat snap -runall --nolog
