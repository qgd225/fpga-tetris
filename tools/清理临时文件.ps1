[CmdletBinding(SupportsShouldProcess)]
param()
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'temporary'))
if (-not $temporaryRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw '临时目录不在工程内'
}
if (Get-Process vivado,xsim,xelab,xvlog -ErrorAction SilentlyContinue) {
    throw 'Vivado 或仿真进程仍在运行，暂不清理'
}
if (-not (Test-Path -LiteralPath $temporaryRoot)) { return }
# 正式工程的 Tetris.runs 不在临时目录内，绝不触及。
$targets = @(Get-ChildItem -LiteralPath $temporaryRoot -Force | Where-Object Name -ne 'sim')
$simulationRoot = Join-Path $temporaryRoot 'sim'
if (Test-Path -LiteralPath $simulationRoot) {
    $targets += @(Get-ChildItem -LiteralPath $simulationRoot -Directory -Recurse | Where-Object { $_.Name -in @('build','build_music','logs','__pycache__') -and $_.Parent.Name -notin @('build','build_music') })
}
foreach ($entry in $targets) {
    $resolvedTarget = [IO.Path]::GetFullPath($entry.FullName)
    if (-not $resolvedTarget.StartsWith($temporaryRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "清理路径越界：$resolvedTarget"
    }
    if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "发现额外目录联接，需人工核对：$resolvedTarget"
    }
}
foreach ($entry in $targets) {
    if ($PSCmdlet.ShouldProcess($entry.FullName, '删除已使用完的临时产物')) {
        Remove-Item -LiteralPath $entry.FullName -Recurse -Force -ErrorAction Stop
    }
}
