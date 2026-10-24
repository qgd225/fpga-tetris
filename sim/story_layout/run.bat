@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\mapper_tb.v ..\..\..\Tetris.srcs\sources_1\new\story_pixel_mapper.v --nolog
if errorlevel 1 exit /b 1
call xelab.bat mapper_tb -s mapper --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat mapper -runall --nolog > simulation.txt 2>&1
type simulation.txt
findstr /C:"ALL PASS STORY MAPPER" simulation.txt >nul
if errorlevel 1 exit /b 1
findstr /C:"FAILED" /C:"FAIL " simulation.txt >nul
if not errorlevel 1 exit /b 1
exit /b 0
