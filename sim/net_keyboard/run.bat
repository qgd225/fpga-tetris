@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat ..\net_keyboard_tb.v ..\..\..\Tetris.srcs\sources_1\new\net_keyboard_receiver.v --nolog
if errorlevel 1 exit /b 1
call xelab.bat net_keyboard_tb -s keyboard --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat keyboard -runall -log keyboard.log
if errorlevel 1 exit /b 1
findstr /C:"=== ALL PASS: NET KEYBOARD ===" keyboard.log >nul
if errorlevel 1 exit /b 1
exit /b 0
