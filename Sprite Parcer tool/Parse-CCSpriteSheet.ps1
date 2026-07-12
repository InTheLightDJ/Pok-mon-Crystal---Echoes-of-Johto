#Requires -Version 5.1
<#
.SYNOPSIS
  Parses CC-format sprite sheets (800×300) and produces game-ready outputs.

.DESCRIPTION
  Each CC_*.png contains (left to right):
    - Front Sprite  (56×56)  at crop x=153, y=93
    - Back Sprite   (48×48)  at crop x=228, y=101
    - Walking Strip (16×96)  at crop x=375, y=53
        Frame 0 – Idle Down   Frame 1 – Idle Up    Frame 2 – Idle Left
        Frame 3 – Walk Down   Frame 4 – Walk Up    Frame 5 – Walk Left

  Outputs (all in -OutDir):
    CHARNAME.png          Front battle sprite  112×112  (2× scale, transparent bg)
    CHARNAME_back.png     Back  battle sprite   96×96   (2× scale, transparent bg)
    trainer_CHARNAME.png  Walking sheet        128×160  (4×4 cells of 32×40, transparent bg)

  Walking sheet cell layout (0-indexed row, col):
    Row 0 (down): idle_d | walk_d | idle_d | H-flip(walk_d)
    Row 1 (left): idle_l | walk_l | idle_l | walk_l
    Row 2 (right): H-flip(idle_l) | H-flip(walk_l) | H-flip(idle_l) | H-flip(walk_l)
    Row 3 (up):   idle_u | walk_u | idle_u | H-flip(walk_u)
  Each 16×16 frame is 2× scaled to 32×32 and placed at y-offset 8 in a 32×40 cell
  (bottom-aligned: 8 px head-room, feet at cell bottom).

.PARAMETER InDir
  Folder containing CC_*.png files.  Default: current directory.

.PARAMETER OutDir
  Folder to write outputs.  Created if missing.  Default: InDir\characters.

.PARAMETER FilePattern
  Glob filter for input files.  Default: CC_*.png

.PARAMETER BgTolerance
  How close to white (255,255,255) a pixel must be to be made transparent.
  1 = only pure white and pixels within 1 step of white (default).
  0 = exact white only.  Higher = more aggressive removal.

.EXAMPLE
  .\Parse-CCSpriteSheet.ps1 -InDir "C:\Users\lemih\Downloads\sprites" `
                             -OutDir "C:\Users\lemih\Downloads\characters"
#>
param(
    [string]$InDir        = (Get-Location).Path,
    [string]$OutDir       = '',
    [string]$FilePattern  = 'CC_*.png',
    [int]   $BgTolerance  = 1
)

Add-Type -AssemblyName System.Drawing

# ── Output dir ──────────────────────────────────────────────────────────────
if (-not $OutDir) { $OutDir = Join-Path $InDir 'characters' }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }

# ── CC format crop coordinates (pixels, 0-indexed, inclusive top-left) ──────
$CC = @{
    FrontX = 153;  FrontY = 93;   FrontW = 56;  FrontH = 56
    BackX  = 228;  BackY  = 101;  BackW  = 48;  BackH  = 48
    WalkX  = 375;  WalkY  = 53;   WalkW  = 16;  WalkFrameH = 16
}
# Walking frame order in the strip (top-to-bottom, each 16 px tall)
$IDLE_DOWN = 0; $IDLE_UP = 1; $IDLE_LEFT = 2
$WALK_DOWN = 3; $WALK_UP = 4; $WALK_LEFT = 5

# ── Output sizes ─────────────────────────────────────────────────────────────
$SHEET_W      = 128;  $SHEET_H      = 160   # 4 cols × 4 rows
$CELL_W       = 32;   $CELL_H       = 40
$FRAME_SCALED = 32   # 16 × 2
$CELL_Y_PAD   = 8    # head-room inside each 40-px cell

# ── Helper functions ─────────────────────────────────────────────────────────
function Crop([System.Drawing.Bitmap]$bmp, [int]$x, [int]$y, [int]$w, [int]$h) {
    $rect = [System.Drawing.Rectangle]::new($x, $y, $w, $h)
    return $bmp.Clone($rect, $bmp.PixelFormat)
}

function Scale2x([System.Drawing.Bitmap]$src) {
    $dst = [System.Drawing.Bitmap]::new($src.Width * 2, $src.Height * 2)
    $g   = [System.Drawing.Graphics]::FromImage($dst)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($src, 0, 0, $src.Width * 2, $src.Height * 2)
    $g.Dispose()
    return $dst
}

function HFlip([System.Drawing.Bitmap]$src) {
    $dst = $src.Clone()
    $dst.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
    return $dst
}

# Removes near-white pixels by setting their alpha to 0.
# Uses LockBits + Marshal.Copy for fast bulk pixel access — no per-pixel GetPixel calls.
# Format32bppArgb byte layout in memory (little-endian): [B][G][R][A] per pixel.
function RemoveBG([System.Drawing.Bitmap]$src, [int]$tol = $BgTolerance) {
    $fmt  = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    $rect = [System.Drawing.Rectangle]::new(0, 0, $src.Width, $src.Height)

    # Clone forces conversion to 32bppArgb so we always have an alpha channel.
    $bmp  = $src.Clone($rect, $fmt)
    $src.Dispose()

    $data  = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, $fmt)
    $buf   = New-Object byte[] ($data.Stride * $bmp.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $buf.Length)

    $lo = 255 - $tol
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        $row = $y * $data.Stride
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $i = $row + $x * 4   # B at i, G at i+1, R at i+2, A at i+3
            if ($buf[$i] -ge $lo -and $buf[$i+1] -ge $lo -and $buf[$i+2] -ge $lo) {
                $buf[$i+3] = 0   # fully transparent
            }
        }
    }

    [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $data.Scan0, $buf.Length)
    $bmp.UnlockBits($data)
    return $bmp
}

function GetFrame([System.Drawing.Bitmap]$strip, [int]$idx) {
    return Crop $strip 0 ($idx * $CC.WalkFrameH) $CC.WalkW $CC.WalkFrameH
}

function PlaceFrame(
    [System.Drawing.Graphics]$g,
    [System.Drawing.Bitmap]$frame32,
    [int]$col, [int]$row
) {
    $x = $col * $CELL_W
    $y = $row * $CELL_H + $CELL_Y_PAD
    $g.DrawImage($frame32, $x, $y, $FRAME_SCALED, $FRAME_SCALED)
}

function MakeWalkingSheet([System.Drawing.Bitmap]$strip) {
    # Extract, scale, and remove backgrounds from all 6 base frames before compositing.
    # This way transparent frames composite correctly onto the transparent sheet canvas.
    $f = @{}
    foreach ($i in 0..5) {
        $raw      = GetFrame $strip $i
        $scaled   = Scale2x $raw;  $raw.Dispose()
        $clean    = RemoveBG $scaled   # disposes $scaled, returns ARGB transparent-bg bmp
        $f[$i]    = $clean
        $f["f$i"] = HFlip $clean
    }
    $strip.Dispose()

    # Sheet starts fully transparent (Format32bppArgb default: all zeros)
    $sheet = [System.Drawing.Bitmap]::new($SHEET_W, $SHEET_H,
                 [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver

    # Row 0 – facing down
    PlaceFrame $g $f[$IDLE_DOWN]    0 0
    PlaceFrame $g $f[$WALK_DOWN]    1 0
    PlaceFrame $g $f[$IDLE_DOWN]    2 0
    PlaceFrame $g $f["f$WALK_DOWN"] 3 0

    # Row 1 – facing left
    PlaceFrame $g $f[$IDLE_LEFT]    0 1
    PlaceFrame $g $f[$WALK_LEFT]    1 1
    PlaceFrame $g $f[$IDLE_LEFT]    2 1
    PlaceFrame $g $f[$WALK_LEFT]    3 1

    # Row 2 – facing right (H-flip of left frames)
    PlaceFrame $g $f["f$IDLE_LEFT"] 0 2
    PlaceFrame $g $f["f$WALK_LEFT"] 1 2
    PlaceFrame $g $f["f$IDLE_LEFT"] 2 2
    PlaceFrame $g $f["f$WALK_LEFT"] 3 2

    # Row 3 – facing up
    PlaceFrame $g $f[$IDLE_UP]      0 3
    PlaceFrame $g $f[$WALK_UP]      1 3
    PlaceFrame $g $f[$IDLE_UP]      2 3
    PlaceFrame $g $f["f$WALK_UP"]   3 3

    $g.Dispose()
    foreach ($k in @(0,1,2,3,4,5,'f0','f1','f2','f3','f4','f5')) { $f[$k].Dispose() }
    return $sheet
}

function SavePng([System.Drawing.Bitmap]$bmp, [string]$path) {
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# ── Main loop ────────────────────────────────────────────────────────────────
$files = Get-ChildItem -Path $InDir -Filter $FilePattern
if (-not $files) {
    Write-Warning "No files matching '$FilePattern' found in '$InDir'"
    exit 1
}

$ok = 0; $fail = 0
foreach ($file in $files) {
    try {
        $base  = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $sheet = [System.Drawing.Bitmap]::new($file.FullName)

        if ($sheet.Width -ne 800 -or $sheet.Height -ne 300) {
            Write-Warning "  SKIP $($file.Name): unexpected size $($sheet.Width)×$($sheet.Height)"
            $sheet.Dispose(); $fail++; continue
        }

        # Front (112×112, transparent bg)
        $front   = Crop $sheet $CC.FrontX $CC.FrontY $CC.FrontW $CC.FrontH
        $front2x = Scale2x $front;  $front.Dispose()
        SavePng (RemoveBG $front2x) (Join-Path $OutDir "$base.png")

        # Back (96×96, transparent bg)
        $back   = Crop $sheet $CC.BackX $CC.BackY $CC.BackW $CC.BackH
        $back2x = Scale2x $back;  $back.Dispose()
        SavePng (RemoveBG $back2x) (Join-Path $OutDir "${base}_back.png")

        # Walking sheet (128×160, transparent bg)
        $walkStrip = Crop $sheet $CC.WalkX $CC.WalkY $CC.WalkW ($CC.WalkFrameH * 6)
        SavePng (MakeWalkingSheet $walkStrip) (Join-Path $OutDir "trainer_$base.png")

        $sheet.Dispose()
        $ok++
        Write-Host "  OK  $base"
    }
    catch {
        Write-Warning "  ERR $($file.Name): $_"
        $fail++
    }
}

Write-Host ""
Write-Host "Done: $ok processed, $fail skipped/failed."
Write-Host "Output: $OutDir"
