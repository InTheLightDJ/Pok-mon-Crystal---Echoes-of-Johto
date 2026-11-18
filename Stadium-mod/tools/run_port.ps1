# Run Stadium1.exe for N seconds, then show its output (and the crash trace if it crashed).
#   & tools\run_port.ps1 [seconds] [exe name]
param([int]$Seconds = 20, [string]$Exe = "Stadium1")
$dir = Join-Path (Split-Path $PSScriptRoot -Parent) "port\build\Release"
Push-Location $dir
Remove-Item crash.txt, run_out.txt, run_err.txt -ErrorAction SilentlyContinue
$p = Start-Process -FilePath ".\$Exe.exe" -WorkingDirectory $dir -RedirectStandardOutput run_out.txt -RedirectStandardError run_err.txt -PassThru
$deadline = (Get-Date).AddSeconds($Seconds)
while (!$p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
if ($p.HasExited) { "exited: $($p.ExitCode) after $([int]((Get-Date) - $p.StartTime).TotalSeconds)s" } else { "still running after ${Seconds}s (stopped)"; $p | Stop-Process -Force }
"--- stdout"; Get-Content run_out.txt -Tail 25
"--- stderr"; Get-Content run_err.txt -Tail 40
Pop-Location
