$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$build = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force $build | Out-Null
& python (Join-Path $PSScriptRoot 'reference_vectors.py')
if ($LASTEXITCODE -ne 0) { throw 'Independent reference generation failed' }
$source = Join-Path $root 'Tetris.srcs/sources_1/new'
Copy-Item -LiteralPath (Join-Path $source 'story_voice.mem') -Destination (Join-Path $build 'story_voice.mem')
Push-Location $build
try {
    $compile = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xvlog.bat "' + (Join-Path $source 'ima_adpcm_decoder.v') + '" "' + (Join-Path $PSScriptRoot 'decoder_tb.v') + '" --nolog && call xelab.bat decoder_tb -s decoder_tb --timescale 1ns/1ps --nolog && call xsim.bat decoder_tb -runall --nolog > decoder_tb.log 2>&1'
    & cmd /d /c $compile
    if ($LASTEXITCODE -ne 0) { throw 'IMA compile or simulation failed' }
    $log = [IO.File]::ReadAllText((Join-Path $build 'decoder_tb.log'))
    Write-Output $log
    if ($LASTEXITCODE -ne 0 -or $log -notmatch 'ALL PASS IMA DECODER' -or $log -match 'FAILED|FAIL ') { throw 'IMA decoder verification failed' }
    $files = @('ima_adpcm_decoder.v', 'voice_adpcm_rom.v', 'voice_player.v', 'story_comms.v', 'audio_mixer.v', 'audio_synth.v') | ForEach-Object { '"' + (Join-Path $source $_) + '"' }
    $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xvlog.bat -i "' + $build + '" -i "' + $source + '" ' + ($files -join ' ') + ' "' + (Join-Path $PSScriptRoot 'player_tb.v') + '" --nolog && call xelab.bat player_tb -s player_tb --timescale 1ns/1ps --nolog && call xsim.bat player_tb -runall --nolog > player_tb.log 2>&1'
    & cmd /d /c $command
    if ($LASTEXITCODE -ne 0) { throw 'Voice player compile or simulation failed' }
    $log = [IO.File]::ReadAllText((Join-Path $build 'player_tb.log'))
    Write-Output $log
    if ($log -notmatch 'ALL PASS VOICE PLAYER' -or $log -match 'FAILED|FAIL ') { throw 'Voice player verification failed' }
    foreach ($top in @('voice_pack_tb', 'comms_tb', 'fx_tb')) {
      $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xvlog.bat -i "' + $build + '" -i "' + $source + '" ' + ($files -join ' ') + ' "' + (Join-Path $PSScriptRoot ($top + '.v')) + '" --nolog && call xelab.bat ' + $top + ' -s ' + $top + ' --timescale 1ns/1ps --nolog && call xsim.bat ' + $top + ' -runall --nolog > ' + $top + '.log 2>&1'
      & cmd /d /c $command
      if ($LASTEXITCODE -ne 0) { throw "$top compile or simulation failed" }
      $log = [IO.File]::ReadAllText((Join-Path $build ($top + '.log')));Write-Output $log
      if ($log -notmatch 'ALL PASS' -or $log -match 'FAILED|FAIL ') { throw "$top verification failed" }
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run_music.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Story music verification failed' }
    Write-Output 'ALL PASS STORY AUDIO'
} finally { Pop-Location }
