@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
python ..\..\prepare_nobom.py
if errorlevel 1 ( echo PREPARE_FAIL & exit /b 1 )
call xvlog.bat ..\..\_nobom\sim\level\net_level_tb.v ..\..\_nobom\Tetris.srcs\sources_1\new\frame.v ..\..\_nobom\Tetris.srcs\sources_1\new\Playfield.v ..\..\_nobom\Tetris.srcs\sources_1\new\Playfield_edge.v ..\..\_nobom\Tetris.srcs\sources_1\new\timer.v ..\..\_nobom\Tetris.srcs\sources_1\new\scoring.v ..\..\_nobom\Tetris.srcs\sources_1\new\Next_piece.v ..\..\_nobom\Tetris.srcs\sources_1\new\hold_piece.v ..\..\_nobom\Tetris.srcs\sources_1\new\level.v ..\..\_nobom\Tetris.srcs\sources_1\new\game_over.v ..\..\_nobom\Tetris.srcs\sources_1\new\choose_menu.v ..\..\_nobom\Tetris.srcs\sources_1\new\solo_hint.v --nolog
if errorlevel 1 ( echo XVLOG_FAIL & exit /b 1 )
call xelab.bat net_level_tb -s snap --timescale 1ns/1ps --nolog
if errorlevel 1 ( echo XELAB_FAIL & exit /b 1 )
call xsim.bat snap -runall --nolog
