param(
  [string]$CharactersDir = "$PSScriptRoot\characters",
  [string]$GameDir       = (Split-Path $PSScriptRoot -Parent)
)

$TrainerTypesPath = "$GameDir\PBS\trainer_types.txt"
$MetadataPath     = "$GameDir\PBS\metadata.txt"
$TrainersGfxDir   = "$GameDir\Graphics\Trainers"
$CharsGfxDir      = "$GameDir\Graphics\Characters"
$ManifestPath     = "$PSScriptRoot\imported_manifest.txt"
$ConfigPath       = "$PSScriptRoot\characters_config.csv"

function Get-NextTrainerNumber {
  $content = Get-Content $TrainerTypesPath -Raw
  $m = [regex]::Matches($content, '\[POKEMONTRAINER_(\d+)\]')
  if ($m.Count -eq 0) { return 1 }
  return (($m | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum) + 1
}

function Get-LastMetadataId {
  $content = Get-Content $MetadataPath -Raw
  $m = [regex]::Matches($content, '^\[(\d+)\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if ($m.Count -eq 0) { return 2 }
  return ($m | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
}

function Get-AllCCNames {
  Get-ChildItem $CharactersDir -Filter "CC_*.png" |
    Where-Object { $_.Name -notmatch '_back\.png$' } |
    ForEach-Object { $_.BaseName } |
    Sort-Object
}

function Read-Manifest {
  $list = [System.Collections.Generic.List[string]]::new()
  if (Test-Path $ManifestPath) {
    Get-Content $ManifestPath | Where-Object { $_ -match '\S' } | ForEach-Object { $list.Add($_) }
  }
  return ,$list  # comma prevents PowerShell unrolling the list into a fixed array on return
}

function Save-Manifest ($list) {
  $list | Set-Content $ManifestPath -Encoding UTF8
}

function Read-Config {
  if (-not (Test-Path $ConfigPath)) { return @{} }
  $table = @{}
  Import-Csv $ConfigPath | ForEach-Object { $table[$_.CCName] = $_ }
  return $table
}

# ── main ──────────────────────────────────────────────────────────────────────

Write-Host "=== Add-Characters Tool ==="
Write-Host "Game dir: $GameDir"
Write-Host ""

if (-not (Test-Path $TrainerTypesPath)) {
  Write-Host "ERROR: Cannot find PBS\trainer_types.txt"
  Write-Host "Expected game folder: $GameDir"
  Write-Host "Make sure this tool folder is directly inside the game folder."
  Read-Host "Press Enter to exit"
  exit 1
}

if (-not (Test-Path $CharactersDir)) {
  Write-Host "ERROR: Characters folder not found: $CharactersDir"
  Read-Host "Press Enter to exit"
  exit 1
}

$allCC = Get-AllCCNames
if ($allCC.Count -eq 0) {
  Write-Host "No CC_*.png files found in: $CharactersDir"
  Read-Host "Press Enter to exit"
  exit
}
Write-Host "Characters folder: $($allCC.Count) CC_ sprite(s) found."

$imported = Read-Manifest
Write-Host "Manifest: $($imported.Count) already imported."

$newCC = @($allCC | Where-Object { $_ -notin $imported })
if ($newCC.Count -eq 0) {
  Write-Host ""
  Write-Host "Nothing to import -- all characters are already in the game."
  Read-Host "Press Enter to exit"
  exit
}
Write-Host "New characters to import: $($newCC.Count)"

$config = Read-Config
$missingConfig = @($newCC | Where-Object { -not $config.ContainsKey($_) })

if ($missingConfig.Count -gt 0) {
  Write-Host ""
  Write-Host "These characters have no display name/gender in characters_config.csv:"
  $missingConfig | ForEach-Object { Write-Host "  $_" }
  Write-Host ""

  if (-not (Test-Path $ConfigPath)) {
    "CCName,DisplayName,Gender" | Set-Content $ConfigPath -Encoding UTF8
  }

  foreach ($cc in $missingConfig) {
    $guess = ($cc -replace '^CC_', '') -replace '_', ' '
    Add-Content $ConfigPath -Value "$cc,$guess,Male" -Encoding UTF8
  }

  Write-Host "Template rows written to: $ConfigPath"
  Write-Host "Edit DisplayName and Gender (Male / Female / Unknown), then re-run."
  Read-Host "Press Enter to exit"
  exit
}

$nextTrainer = Get-NextTrainerNumber
$lastMeta    = Get-LastMetadataId
$n           = $nextTrainer
$metaId      = $lastMeta + 1

Write-Host ""
Write-Host "Importing from POKEMONTRAINER_$n (metadata [$metaId])..."
Write-Host ""

$ttLines = [System.Text.StringBuilder]::new()
$mdLines = [System.Text.StringBuilder]::new()

foreach ($cc in $newCC) {
  $row    = $config[$cc]
  $name   = $row.DisplayName.Trim()
  $gender = $row.Gender.Trim()
  $tag    = "POKEMONTRAINER_$n"
  $bike   = if ($gender -eq "Female") { "girl_bike" } else { "boy_bike" }
  $fish   = if ($gender -eq "Female") { "girl_fish_offset" } else { "boy_fish_offset" }

  $missingSrc = @()
  if (-not (Test-Path "$CharactersDir\$cc.png"))         { $missingSrc += "$cc.png" }
  if (-not (Test-Path "$CharactersDir\${cc}_back.png"))  { $missingSrc += "${cc}_back.png" }
  if (-not (Test-Path "$CharactersDir\trainer_$cc.png")) { $missingSrc += "trainer_$cc.png" }
  if ($missingSrc.Count -gt 0) {
    Write-Host "  SKIP $cc -- missing: $($missingSrc -join ', ')"
    $n++
    $metaId++
    continue
  }

  Copy-Item "$CharactersDir\$cc.png"         "$TrainersGfxDir\$tag.png"             -Force
  Copy-Item "$CharactersDir\${cc}_back.png"  "$TrainersGfxDir\${tag}_back.png"      -Force
  Copy-Item "$CharactersDir\trainer_$cc.png" "$CharsGfxDir\trainer_$tag.png"        -Force
  Copy-Item "$CharactersDir\trainer_$cc.png" "$CharsGfxDir\trainer_${tag}_surf.png" -Force

  [void]$ttLines.AppendLine("#-------------------------------")
  [void]$ttLines.AppendLine("[$tag]")
  [void]$ttLines.AppendLine("Name = $name")
  [void]$ttLines.AppendLine("Gender = $gender")
  [void]$ttLines.AppendLine("BaseMoney = 60")
  [void]$ttLines.AppendLine("BattleBGM = sactuaray")
  [void]$ttLines.AppendLine("VictoryBGM = Victory Fanfare")

  [void]$mdLines.AppendLine("#-------------------------------")
  [void]$mdLines.AppendLine("[$metaId]")
  [void]$mdLines.AppendLine("TrainerType = $tag")
  [void]$mdLines.AppendLine("WalkCharset = trainer_$tag")
  [void]$mdLines.AppendLine("RunCharset = trainer_$tag")
  [void]$mdLines.AppendLine("CycleCharset = $bike")
  [void]$mdLines.AppendLine("SurfCharset = trainer_${tag}_surf")
  [void]$mdLines.AppendLine("DiveCharset = trainer_${tag}_surf")
  [void]$mdLines.AppendLine("FishCharset = $fish")
  [void]$mdLines.AppendLine("SurfFishCharset = trainer_${tag}_surf")

  $imported.Add($cc)
  Write-Host "  $tag  $name ($gender) [from $cc]"
  $n++
  $metaId++
}

Add-Content $TrainerTypesPath -Value $ttLines.ToString().TrimEnd() -Encoding UTF8
Add-Content $MetadataPath     -Value $mdLines.ToString().TrimEnd() -Encoding UTF8

Save-Manifest $imported

Write-Host ""
Write-Host "Done! Imported $($newCC.Count) character(s)."
Write-Host "trainer_types.txt: $((Get-Content $TrainerTypesPath).Count) lines"
Write-Host "metadata.txt:      $((Get-Content $MetadataPath).Count) lines"
Read-Host "Press Enter to exit"
