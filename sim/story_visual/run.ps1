param([switch]$Render)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$build = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force $build | Out-Null
$source = Join-Path $root 'Tetris.srcs/sources_1/new'
foreach ($name in @('story_font.mem', 'story_sprites.mem')) {
    Copy-Item -LiteralPath (Join-Path $source $name) -Destination (Join-Path $build $name)
}
# 颜色参考来自未改的网络调色板，独立于新画面的资产生成文件。
$network = [IO.File]::ReadAllText((Join-Path $source 'net_screen_tx.v'), [Text.Encoding]::GetEncoding(936))
$colors = @{}
foreach ($m in [regex]::Matches($network, "[56]'d(\d+):\s+pal_rgb\s*=\s*24'h([0-9A-Fa-f_]+)")) {
    $colors[[int]$m.Groups[1].Value] = $m.Groups[2].Value.Replace('_', '')
}
if ($colors.Count -ne 56) { throw 'Missing reference palette colors' }
$rows = 0..55 | ForEach-Object { $colors[$_] }
[IO.File]::WriteAllLines((Join-Path $build 'palette_reference.mem'), $rows, [Text.Encoding]::ASCII)
$files = @('hud_font_rom', 'hud_text', 'scene_sprite_rom', 'story_scene', 'core_renderer', 'story_ui', 'story_pixel_mapper', 'story_pixel_frontend', 'story_feedback') |
    ForEach-Object { '"' + (Join-Path $source ($_.ToString() + '.v')) + '"' }
$tests = @('font_tb.v', 'render_tb.v', 'phase_tb.v', 'feedback_tb.v') | ForEach-Object { '"' + (Join-Path $PSScriptRoot $_) + '"' }
$vga = Join-Path $root 'Tetris.srcs/sources_1/imports/new/VGA_1280_720.v'
Push-Location $build
try {
    $compile = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xvlog.bat --relax "' + $vga + '" --nolog && call xvlog.bat -i "' + $source + '" -i "' + $PSScriptRoot + '" ' + ($files -join ' ') + ' ' + ($tests -join ' ') + ' --nolog'
    & cmd /d /c $compile
    if ($LASTEXITCODE -ne 0) { throw 'Story visual compile failed' }
    foreach ($top in @('font_tb', 'render_tb', 'phase_tb', 'feedback_tb')) {
        & cmd /d /c ('call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xelab.bat ' + $top + ' -s ' + $top + ' --timescale 1ns/1ps --nolog && call xsim.bat ' + $top + ' -runall --nolog > ' + $top + '.log 2>&1')
        $log = [IO.File]::ReadAllText((Join-Path $build ($top + '.log')))
        Write-Output $log
        if ($LASTEXITCODE -ne 0 -or $log -notmatch 'ALL PASS' -or $log -match 'FAILED|FAIL ') { throw "$top failed" }
    }
    if ($Render) {
        $cases = @('phase=0 duo=1 state=0', 'phase=1 duo=1 state=0', 'phase=2 duo=1 state=0', 'phase=3 duo=1 state=0',
                   'phase=0 duo=0 state=0', 'phase=0 duo=1 state=1', 'phase=0 duo=1 state=2',
                   'phase=3 duo=1 state=3', 'phase=3 duo=1 state=4', 'phase=3 duo=1 state=5')
        foreach ($case in $cases) {
            $argsText = ($case.Split(' ') | ForEach-Object { '-testplusarg "' + $_ + '"' }) -join ' '
            & cmd /d /c ('call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && call xsim.bat render_tb -runall --nolog -testplusarg render ' + $argsText + ' > render.log 2>&1')
            $log = [IO.File]::ReadAllText((Join-Path $build 'render.log'))
            if ($LASTEXITCODE -ne 0 -or $log -notmatch 'ALL PASS' -or $log -match 'FAILED|FAIL ') { throw "Render failed: $case" }
            Write-Output "STORY_RENDER_PASS $case"
        }
    }
    Write-Output 'ALL PASS STORY VISUAL'
} finally {
    Pop-Location
}
