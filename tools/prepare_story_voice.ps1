$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$folder = Join-Path $root 'assets/voice_sources'
New-Item -ItemType Directory -Force $folder | Out-Null
$speaker = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speaker.SelectVoice('Microsoft Zira Desktop')
$speaker.Rate = 0
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(8000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$lines = @('YOU CAME.', 'Link restored. There you are.', 'That is it. Keep going.', 'Steady. Almost there.', 'Clear the array. Now.', 'Power restored. Thank you.', 'Not... yet.')
try {
 for ($i=1; $i -lt $lines.Count; $i++) {
  $target = Join-Path $folder ('V' + $i + '_source.wav')
  if (!(Test-Path -LiteralPath $target)) {
   $speaker.SetOutputToWaveFile($target, $format)
   $speaker.Speak($lines[$i])
   $speaker.SetOutputToNull()
  }
  Write-Output ('VOICE_SOURCE_READY V' + $i)
 }
} finally { $speaker.Dispose() }
