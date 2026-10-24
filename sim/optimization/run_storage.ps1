param([string]$Candidate = '')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if (!$Candidate) { $Candidate = Join-Path $root 'Tetris.srcs/sources_1/new/frame.v' }
$build=Join-Path $PSScriptRoot 'build/storage'
New-Item -ItemType Directory -Force $build | Out-Null
[IO.File]::Copy((Resolve-Path $Candidate).Path,(Join-Path $build 'Candidate.v'),$true)
Push-Location $build
try {
    foreach($top in @('frame_duo','frame_storage')) {
        $env:TETRIS_STORAGE_TB=if($top -eq 'frame_duo'){'../../../frame_duo/frame_duo_tb.v'}else{'../../../lutram/frame_storage_tb.v'}
        $env:TETRIS_STORAGE_TOP="${top}_tb"
        $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && cd /d "' + (Get-Location).Path + '" && call xvlog.bat -d SYNTHESIS ' + $env:TETRIS_STORAGE_TB + ' Candidate.v ..\..\..\..\Tetris.srcs\sources_1\new\frame_background.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_pixel_mapper.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_speed_control.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_hold_controller.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_ghost_scanner.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_edge.v ..\..\..\..\Tetris.srcs\sources_1\new\solo_hint.v ..\..\..\..\Tetris.srcs\sources_1\new\Next_piece.v ..\..\..\..\Tetris.srcs\sources_1\new\hold_piece.v ..\..\..\..\Tetris.srcs\sources_1\new\timer.v ..\..\..\..\Tetris.srcs\sources_1\new\scoring.v ..\..\..\..\Tetris.srcs\sources_1\new\level.v ..\..\..\..\Tetris.srcs\sources_1\new\game_over.v ..\..\..\..\Tetris.srcs\sources_1\new\choose_menu.v --nolog && call xelab.bat ' + $env:TETRIS_STORAGE_TOP + ' -L unisims_ver -s storage --timescale 1ns/1ps --nolog && call xsim.bat storage -runall -log storage.log'
        & cmd /c $command
        if($LASTEXITCODE -ne 0){throw "$top simulation failed to run"}
        $log=[IO.File]::ReadAllText((Join-Path $build 'storage.log'))
        if($log -notmatch 'ALL PASS' -or $log -match 'FAILED|FAIL '){throw "$top assertions failed"}
        Copy-Item -LiteralPath storage.log -Destination "${top}.log"
    }
} finally {
    Pop-Location
    Remove-Item Env:TETRIS_STORAGE_TB,Env:TETRIS_STORAGE_TOP -ErrorAction SilentlyContinue
}
