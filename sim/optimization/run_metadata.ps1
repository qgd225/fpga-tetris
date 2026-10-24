param([string]$Candidate = '')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if (!$Candidate) { $Candidate = Join-Path $root 'Tetris.srcs/sources_1/new/frame.v' }
$build=Join-Path $PSScriptRoot 'build/metadata'
New-Item -ItemType Directory -Force $build | Out-Null
[IO.File]::Copy((Resolve-Path $Candidate).Path,(Join-Path $build 'Candidate.v'),$true)
Push-Location $build
try {
    foreach($model in @('rtl','primitive')) {
        $env:TETRIS_METADATA_DEFINE=if($model -eq 'primitive'){'-d SYNTHESIS'}else{''}
        $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && cd /d "' + (Get-Location).Path + '" && call xvlog.bat ' + $env:TETRIS_METADATA_DEFINE + ' ..\..\metadata_tb.v Candidate.v ..\..\..\..\Tetris.srcs\sources_1\new\frame_background.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_pixel_mapper.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_speed_control.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_hold_controller.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_ghost_scanner.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_edge.v ..\..\..\..\Tetris.srcs\sources_1\new\solo_hint.v ..\..\..\..\Tetris.srcs\sources_1\new\Next_piece.v ..\..\..\..\Tetris.srcs\sources_1\new\hold_piece.v ..\..\..\..\Tetris.srcs\sources_1\new\timer.v ..\..\..\..\Tetris.srcs\sources_1\new\scoring.v ..\..\..\..\Tetris.srcs\sources_1\new\level.v ..\..\..\..\Tetris.srcs\sources_1\new\game_over.v ..\..\..\..\Tetris.srcs\sources_1\new\choose_menu.v --nolog && call xelab.bat metadata_tb -L unisims_ver -s metadata --timescale 1ns/1ps --nolog && call xsim.bat metadata -runall -log metadata.log'
        & cmd /c $command
        if($LASTEXITCODE -ne 0){throw "Metadata $model simulation failed to run"}
        $log=[IO.File]::ReadAllText((Join-Path $build 'metadata.log'))
        if($log -notmatch 'ALL PASS: METADATA' -or $log -match 'FAILED|FAIL '){throw "Metadata $model assertions failed"}
        Copy-Item -LiteralPath metadata.log -Destination "metadata_$model.log"
    }
} finally {
    Pop-Location
    Remove-Item Env:TETRIS_METADATA_DEFINE -ErrorAction SilentlyContinue
}
