# Start the port, save screenshots of its window at the given seconds, then stop it.
#   & tools\shot_port.ps1 -At 10,20,30 [-Exe Stadium1] [-Buttons "32:start,40:a,43:left"]
# -Buttons goes to the port as STADIUM_INPUT (port/src/input.cpp): the port presses the
# buttons itself, nothing is sent through Windows, and the window doesn't take focus,
# so whatever the user is doing isn't touched. Screenshots use PrintWindow with
# PW_RENDERFULLCONTENT, which works while the window is behind others.
param([int[]]$At = @(10, 20), [string]$Exe = "Stadium1", [string]$Buttons = "")
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
"@
# the port is DPI-aware; without this, display scaling shrinks the client rect and crops shots
[Win]::SetProcessDPIAware() | Out-Null
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root "port\build\Release"
$shots = Join-Path $root "port\build\shots"
New-Item -ItemType Directory -Force $shots | Out-Null
Push-Location $dir
$env:STADIUM_INPUT = if ($Buttons) { $Buttons } else { "0:none" }
$p = Start-Process -FilePath ".\$Exe.exe" -WorkingDirectory $dir -RedirectStandardOutput run_out.txt -RedirectStandardError run_err.txt -PassThru
Remove-Item env:STADIUM_INPUT
$start = Get-Date
foreach ($t in $At) {
    while (((Get-Date) - $start).TotalSeconds -lt $t -and !$p.HasExited) { Start-Sleep -Milliseconds 100 }
    if ($p.HasExited) { "exited early: $($p.ExitCode)"; break }
    $p.Refresh()
    $h = $p.MainWindowHandle
    if ($h -eq [IntPtr]::Zero) { "no window at ${t}s"; continue }
    $r = New-Object Win+RECT
    [Win]::GetClientRect($h, [ref]$r) | Out-Null
    $w = [Math]::Max(1, $r.R - $r.L); $hgt = [Math]::Max(1, $r.B - $r.T)
    $bmp = New-Object System.Drawing.Bitmap $w, $hgt
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [Win]::PrintWindow($h, $hdc, 3) | Out-Null     # PW_CLIENTONLY | PW_RENDERFULLCONTENT
    $g.ReleaseHdc($hdc)
    $file = Join-Path $shots ("{0}_{1:D3}s.png" -f $Exe, [int]$t)
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    "shot ${t}s -> $file ($w x $hgt)"
}
if (!$p.HasExited) { $p | Stop-Process -Force }
# a crashed run can linger (crash handler / WER); make sure nothing of this exe is left
Get-Process $Exe -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
$p.WaitForExit(5000) | Out-Null
Pop-Location
"--- stderr (last lines)"; Get-Content (Join-Path $dir run_err.txt) -Tail 8
