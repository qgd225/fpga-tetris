param([string]$Baseline = '0a9b368', [string]$Candidate = '')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$build = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force $build | Out-Null
if (!$Candidate) { $Candidate = Join-Path $root 'Tetris.srcs/sources_1/new/Playfield.v' }
[IO.File]::Copy((Resolve-Path $Candidate).Path, (Join-Path $build 'Candidate.v'), $true)
$encoding = [Text.Encoding]::GetEncoding(54936)
$processInfo = [Diagnostics.ProcessStartInfo]::new('git', "show ${Baseline}:Tetris.srcs/sources_1/new/Playfield.v")
$processInfo.WorkingDirectory = $root
$processInfo.UseShellExecute = $false
$processInfo.RedirectStandardOutput = $true
$processInfo.StandardOutputEncoding = $encoding
$process = [Diagnostics.Process]::Start($processInfo)
$source = $process.StandardOutput.ReadToEnd()
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw 'Cannot load reference RTL' }
$source = $source -replace '\bPlayfield\b', 'Playfield_reference' -replace '\bboard_row_replica\b', 'board_row_replica_reference'
[IO.File]::WriteAllBytes((Join-Path $build 'Playfield_reference.v'), $encoding.GetBytes($source))
foreach ($rom in @(@('shape_rom',16,8), @('offset_rom',2,2))) {
    $coe = [IO.File]::ReadAllText((Join-Path $root "Tetris.srcs/sources_1/ip/$($rom[0]).coe"))
    $vector = ($coe -split 'memory_initialization_vector\s*=')[1].Trim().TrimEnd(';')
    $values = @($vector -split ',' | ForEach-Object { [Convert]::ToUInt32($_.Trim(), $rom[1]).ToString("X$($rom[2])") })
    while ($values.Count -lt 32) { $values += '0' }
    [IO.File]::WriteAllLines((Join-Path $build "$($rom[0]).hex"), $values, [Text.Encoding]::ASCII)
}
Push-Location $build
try {
    $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && cd /d "' + (Get-Location).Path + '" && call xvlog.bat ..\playfield_equivalence_tb.v Playfield_reference.v Candidate.v ..\..\..\Tetris.srcs\sources_1\new\solo_hint.v --nolog && call xelab.bat playfield_equivalence_tb -s playfield_equivalence --timescale 1ns/1ps --nolog && call xsim.bat playfield_equivalence -runall -log equivalence.log'
    & cmd /c $command
    if ($LASTEXITCODE -ne 0) { throw 'Equivalence simulation failed to run' }
    $log = [IO.File]::ReadAllText((Join-Path $build 'equivalence.log'))
    if ($log -notmatch 'ALL PASS: PLAYFIELD EQUIVALENCE' -or $log -match 'FAILED|FAIL ') { throw 'Equivalence assertions failed' }
} finally {
    Pop-Location
}
