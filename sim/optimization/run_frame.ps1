param([string]$Baseline = '0a9b368', [string]$Candidate = '', [switch]$FullFrame, [switch]$EmitLabels)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$build = Join-Path $PSScriptRoot $(if ($FullFrame) { 'build/frame_full' } else { 'build/frame_quick' })
New-Item -ItemType Directory -Force $build | Out-Null
if (!$Candidate) { $Candidate = Join-Path $root 'Tetris.srcs/sources_1/new/frame.v' }
$candidateSource = [IO.File]::ReadAllText($Candidate, [Text.Encoding]::GetEncoding(936))
if ($candidateSource -match 'story_ui story_ui_inst') {
    if ($EmitLabels) { throw '新UI不使用旧标签函数；导出历史标签时请显式指定历史Candidate。' }
    Write-Output '新UI按故事绘制合同验收，不执行旧画面逐像素相等断言。'
    & cmd /d /c (Join-Path $root 'sim/frame_duo/run.bat')
    if ($LASTEXITCODE -ne 0) { throw 'Story frame integration failed' }
    if ($FullFrame) { & (Join-Path $root 'sim/story_visual/run.ps1') -Render }
    else { & (Join-Path $root 'sim/story_visual/run.ps1') }
    return
}
[IO.File]::Copy((Resolve-Path $Candidate).Path, (Join-Path $build 'Candidate.v'), $true)
$encoding = [Text.Encoding]::GetEncoding(54936)
$processInfo = [Diagnostics.ProcessStartInfo]::new('git', "show ${Baseline}:Tetris.srcs/sources_1/new/frame.v")
$processInfo.WorkingDirectory = $root
$processInfo.UseShellExecute = $false
$processInfo.RedirectStandardOutput = $true
$processInfo.StandardOutputEncoding = $encoding
$process = [Diagnostics.Process]::Start($processInfo)
$source = $process.StandardOutput.ReadToEnd()
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw 'Cannot load reference RTL' }
$source = $source -replace '\bframe\b', 'frame_reference'
# 旧画面参考仅隔离其缺少的新任务端口；R1 参考保留完整任务/存储接口。
if ($source -match 'story_controller story_inst') {
    $source = $source -replace '\bcell_metadata_bank\b', 'cell_metadata_bank_reference'
} else {
    $source = $source -replace 'Playfield Playfield_inst\(', 'Playfield Playfield_inst(.mission_hold(1''b0),.story_speed(3''d0),'
    $source = $source -replace 'game_over game_over_inst\(', 'game_over game_over_inst(.success(1''b0),'
}

[IO.File]::WriteAllBytes((Join-Path $build 'frame_reference.v'), $encoding.GetBytes($source))
$env:TETRIS_FRAME_EXTRA = if ($FullFrame) { '-testplusarg full_frame' } else { '' }
if ($source -match 'story_controller story_inst') { $env:TETRIS_FRAME_EXTRA += ' -testplusarg r1_reference' }
if ($EmitLabels) { $env:TETRIS_FRAME_EXTRA += ' -testplusarg emit_labels' }
Copy-Item -LiteralPath (Join-Path $root 'Tetris.srcs/sources_1/new/story_font.mem') -Destination (Join-Path $build 'story_font.mem')
Copy-Item -LiteralPath (Join-Path $root 'Tetris.srcs/sources_1/new/story_sprites.mem') -Destination (Join-Path $build 'story_sprites.mem')
Push-Location $build
try {
    $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && cd /d "' + (Get-Location).Path + '" && call xvlog.bat ..\..\frame_equivalence_tb.v ..\..\..\frame_duo\frame_duo_tb.v frame_reference.v Candidate.v ..\..\..\..\Tetris.srcs\sources_1\new\frame_background.v ..\..\..\..\Tetris.srcs\sources_1\new\story_pixel_mapper.v ..\..\..\..\Tetris.srcs\sources_1\new\story_pixel_frontend.v ..\..\..\..\Tetris.srcs\sources_1\new\hud_font_rom.v ..\..\..\..\Tetris.srcs\sources_1\new\hud_text.v ..\..\..\..\Tetris.srcs\sources_1\new\scene_sprite_rom.v ..\..\..\..\Tetris.srcs\sources_1\new\story_scene.v ..\..\..\..\Tetris.srcs\sources_1\new\core_renderer.v ..\..\..\..\Tetris.srcs\sources_1\new\story_presentation.v ..\..\..\..\Tetris.srcs\sources_1\new\story_feedback.v ..\..\..\..\Tetris.srcs\sources_1\new\story_ui.v -i ..\..\..\..\Tetris.srcs\sources_1\new\ ..\..\..\..\Tetris.srcs\sources_1\new\story_controller.v ..\..\..\..\Tetris.srcs\sources_1\new\bin_to_bcd.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_pixel_mapper.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_speed_control.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_hold_controller.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_ghost_scanner.v ..\..\..\..\Tetris.srcs\sources_1\new\Playfield_edge.v ..\..\..\..\Tetris.srcs\sources_1\new\solo_hint.v ..\..\..\..\Tetris.srcs\sources_1\new\Next_piece.v ..\..\..\..\Tetris.srcs\sources_1\new\hold_piece.v ..\..\..\..\Tetris.srcs\sources_1\new\timer.v ..\..\..\..\Tetris.srcs\sources_1\new\scoring.v ..\..\..\..\Tetris.srcs\sources_1\new\level.v ..\..\..\..\Tetris.srcs\sources_1\new\game_over.v ..\..\..\..\Tetris.srcs\sources_1\new\choose_menu.v --nolog && call xelab.bat frame_equivalence_tb -s frame_equivalence --timescale 1ns/1ps --nolog && call xsim.bat frame_equivalence -runall -log equivalence.log %TETRIS_FRAME_EXTRA%'
    & cmd /c $command
    if ($LASTEXITCODE -ne 0) { throw 'Frame simulation failed to run' }
    $log = [IO.File]::ReadAllText((Join-Path $build 'equivalence.log'))
    if ($log -notmatch 'ALL PASS: FRAME EQUIVALENCE' -or $log -match 'FAILED|FAIL ') { throw 'Frame equivalence assertions failed' }
} finally {
    Pop-Location
    Remove-Item Env:TETRIS_FRAME_EXTRA -ErrorAction SilentlyContinue
}
