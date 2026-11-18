# Regenerate the config (manual functions / sizes from the ELF) and run N64Recomp.
#   powershell -File tools/run_recomp.ps1 stadium1 pokestadium-us
param([string]$Game = "stadium1", [string]$ElfName = "pokestadium-us")
$root = Split-Path $PSScriptRoot -Parent
$wslRoot = "/mnt/" + $root.Substring(0,1).ToLower() + ($root.Substring(2) -replace '\\','/')
$gen = wsl -d Ubuntu -- python3 "$wslRoot/tools/gen_manual_funcs.py" "$wslRoot/build/$Game/$ElfName.elf" "$wslRoot/recomp/$Game/us.toml" "$wslRoot/recomp/$Game/us.gen.toml"
($gen -replace "`0","" | Select-Object -First 1)
$out = Join-Path $root "build\$Game\RecompiledFuncs"
Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $out | Out-Null
Push-Location (Join-Path $root "recomp\$Game")
$log = Join-Path $root "build\$Game\recomp.log"
$t = Measure-Command { & (Join-Path $root "tools\N64Recomp\build\Release\N64Recomp.exe") us.gen.toml *> $log }
$code = $LASTEXITCODE
Pop-Location
"N64Recomp exit $code in $([int]$t.TotalSeconds)s"
Get-Content $log | Where-Object { $_ -notmatch 'Unpaired LO16|^\[Info\]' } | Select-Object -First 12
"files: $((Get-ChildItem $out).Count), functions in output: $((Select-String -Path "$out\funcs_*.c" -Pattern '^RECOMP_FUNC').Count)"
exit $code
