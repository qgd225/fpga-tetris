@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\board_lutram_tb.v ..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\Tetris.srcs\sources_1\new\solo_hint.v --nolog
if errorlevel 1 exit /b 1
call xelab.bat board_lutram_tb -s lutram_rtl --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat lutram_rtl -runall -log lutram_rtl.log
if errorlevel 1 exit /b 1
findstr /C:"=== ALL PASS: LUTRAM ===" lutram_rtl.log >nul
if errorlevel 1 exit /b 1
call xvlog.bat -d SYNTHESIS ..\board_lutram_tb.v ..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\Tetris.srcs\sources_1\new\solo_hint.v --nolog
if errorlevel 1 exit /b 1
call xelab.bat board_lutram_tb -L unisims_ver -s lutram_primitive --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat lutram_primitive -runall -log lutram_primitive.log
if errorlevel 1 exit /b 1
findstr /C:"=== ALL PASS: LUTRAM ===" lutram_primitive.log >nul
if errorlevel 1 exit /b 1
call xvlog.bat -d SYNTHESIS ..\frame_storage_tb.v ..\..\..\Tetris.srcs\sources_1\new\frame.v ..\..\..\Tetris.srcs\sources_1\new\Playfield_edge.v ..\..\..\Tetris.srcs\sources_1\new\timer.v ..\..\..\Tetris.srcs\sources_1\new\scoring.v ..\..\..\Tetris.srcs\sources_1\new\Next_piece.v ..\..\..\Tetris.srcs\sources_1\new\hold_piece.v ..\..\..\Tetris.srcs\sources_1\new\level.v ..\..\..\Tetris.srcs\sources_1\new\game_over.v ..\..\..\Tetris.srcs\sources_1\new\choose_menu.v --nolog
if errorlevel 1 exit /b 1
call xelab.bat frame_storage_tb -L unisims_ver -s lutram_frame --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat lutram_frame -runall -log lutram_frame.log
if errorlevel 1 exit /b 1
findstr /C:"=== ALL PASS: LUTRAM FRAME ===" lutram_frame.log >nul
if errorlevel 1 exit /b 1
exit /b 0
