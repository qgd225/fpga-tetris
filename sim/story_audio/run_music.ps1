$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$build = Join-Path $PSScriptRoot 'build_music'
New-Item -ItemType Directory -Force $build | Out-Null
Push-Location $build
try {
 $cmdline = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xvlog.bat "' + (Join-Path $root 'Tetris.srcs/sources_1/new/music.v') + '" "' + (Join-Path $PSScriptRoot 'music_tb.v') + '" --nolog && call xelab.bat music_tb -s music_tb --timescale 1ns/1ps --nolog && call xsim.bat music_tb -runall --nolog > music_tb.log 2>&1'
 & cmd /d /c $cmdline
 if ($LASTEXITCODE -ne 0) { throw 'Music compile or simulation failed' }
 $log = [IO.File]::ReadAllText((Join-Path $build 'music_tb.log'));Write-Output $log
 if ($log -notmatch 'ALL PASS STORY MUSIC' -or $log -match 'FAILED|FAIL ') { throw 'Music regression failed' }
} finally { Pop-Location }
