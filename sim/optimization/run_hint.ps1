param([string]$Baseline = '0a9b368', [string]$Candidate = '')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$build = Join-Path $PSScriptRoot 'build/hint'
New-Item -ItemType Directory -Force $build | Out-Null
if (!$Candidate) { $Candidate = Join-Path $root 'Tetris.srcs/sources_1/new/solo_hint.v' }
[IO.File]::Copy((Resolve-Path $Candidate).Path, (Join-Path $build 'Candidate.v'), $true)
$encoding = [Text.Encoding]::GetEncoding(54936)
$processInfo = [Diagnostics.ProcessStartInfo]::new('git', "show ${Baseline}:Tetris.srcs/sources_1/new/solo_hint.v")
$processInfo.WorkingDirectory = $root
$processInfo.UseShellExecute = $false
$processInfo.RedirectStandardOutput = $true
$processInfo.StandardOutputEncoding = $encoding
$process = [Diagnostics.Process]::Start($processInfo)
$source = $process.StandardOutput.ReadToEnd()
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw 'Cannot load reference RTL' }
$source = $source -replace '\bsolo_hint\b', 'solo_hint_reference'
[IO.File]::WriteAllBytes((Join-Path $build 'reference.v'), $encoding.GetBytes($source))
Push-Location $build
try {
    $command = 'call D:\xilinx\Vivado\2018.3\settings64.bat >nul 2>&1 && cd /d "' + (Get-Location).Path + '" && call xvlog.bat ..\..\hint_equivalence_tb.v ..\..\..\solo_hint\solo_hint_tb.v reference.v Candidate.v --nolog && call xelab.bat hint_equivalence_tb -s hint_equivalence --timescale 1ns/1ps --nolog && call xsim.bat hint_equivalence -runall -log equivalence.log'
    & cmd /c $command
    if ($LASTEXITCODE -ne 0) { throw 'Hint simulation failed to run' }
    $log = [IO.File]::ReadAllText((Join-Path $build 'equivalence.log'))
    if ($log -notmatch 'ALL PASS: HINT EQUIVALENCE' -or $log -match 'FAILED|FAIL ') { throw 'Hint equivalence assertions failed' }
} finally { Pop-Location }
