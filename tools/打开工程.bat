@echo off
setlocal
set "TETRIS_ROOT=%~dp0.."
if not exist "%TETRIS_ROOT%\temporary" mkdir "%TETRIS_ROOT%\temporary"
pushd "%TETRIS_ROOT%\temporary"
call "D:\xilinx\Vivado\2018.3\settings64.bat"
call vivado.bat -mode gui -log "%TETRIS_ROOT%\temporary\vivado.log" -journal "%TETRIS_ROOT%\temporary\vivado.jou" "%TETRIS_ROOT%\Tetris.xpr"
popd
endlocal
