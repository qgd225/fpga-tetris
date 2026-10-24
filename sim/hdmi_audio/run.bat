@echo off
call "D:\xilinx\Vivado\2018.3\settings64.bat" >nul 2>&1
cd /d "%~dp0"
if not exist build mkdir build
cd build
call xvlog.bat --sv ..\hdmi_audio_tb.sv ..\..\..\Tetris.srcs\sources_1\new\game_audio_pcm.v ..\..\..\Tetris.srcs\sources_1\new\hdmi_audio_packets.sv ..\..\..\Tetris.srcs\sources_1\new\hdmi_av_encoder.sv ..\..\..\Tetris.srcs\sources_1\new\sound.v ..\..\..\third_party\hdl_util_hdmi\src\audio_info_frame.sv ..\..\..\third_party\hdl_util_hdmi\src\audio_sample_packet.sv ..\..\..\third_party\hdl_util_hdmi\src\auxiliary_video_information_info_frame.sv ..\..\..\third_party\hdl_util_hdmi\src\packet_assembler.sv ..\..\..\third_party\hdl_util_hdmi\src\tmds_channel.sv --nolog
if errorlevel 1 exit /b 1
call xelab.bat hdmi_audio_tb -s snap --timescale 1ns/1ps --nolog
if errorlevel 1 exit /b 1
call xsim.bat snap -runall --nolog > simulation.txt 2>&1
type simulation.txt
findstr /C:"ALL PASS HDMI audio" simulation.txt >nul
if errorlevel 1 exit /b 1
