param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$script:privateFontCollections = @()

function Resolve-Tool {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw "Tool not found: $($Names -join ', ')"
}

function New-FontFamily {
    $paperlogyPath = Join-Path $projectRoot "Assets\Resources\Fonts\Paperlogy-7Bold.ttf"
    if (Test-Path -LiteralPath $paperlogyPath) {
        $collection = [System.Drawing.Text.PrivateFontCollection]::new()
        $collection.AddFontFile($paperlogyPath)
        $script:privateFontCollections += $collection
        if ($collection.Families.Count -gt 0) {
            return $collection.Families[0]
        }
    }

    $installed = [System.Drawing.Text.InstalledFontCollection]::new()
    foreach ($candidate in @("Paperlogy", "Malgun Gothic", "맑은 고딕", "Arial")) {
        foreach ($family in $installed.Families) {
            if ($family.Name -eq $candidate) {
                return $family
            }
        }
    }
    return [System.Drawing.FontFamily]::GenericSansSerif
}

function Draw-CoverImage {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height
    )

    $targetRatio = $Width / [float]$Height
    $sourceRatio = $Image.Width / [float]$Image.Height

    if ($sourceRatio -gt $targetRatio) {
        $cropH = $Image.Height
        $cropW = [int]($cropH * $targetRatio)
    } else {
        $cropW = $Image.Width
        $cropH = [int]($cropW / $targetRatio)
    }

    $x = [int](($Image.Width - $cropW) * 0.5)
    $y = [int](($Image.Height - $cropH) * 0.5)
    $srcRect = [System.Drawing.Rectangle]::new($x, $y, $cropW, $cropH)
    $dstRect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
    $Graphics.DrawImage($Image, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-WrappedText {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.Font]$Font,
        [System.Drawing.RectangleF]$Box,
        [System.Drawing.Brush]$Brush
    )

    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
    try {
        $Graphics.DrawString($Text, $Font, $Brush, $Box, $format)
    } finally {
        $format.Dispose()
    }
}

function Save-TrailerFrame {
    param(
        [string]$SourcePath,
        [string]$Caption,
        [string]$FramePath,
        [int]$Index
    )

    $bitmap = [System.Drawing.Bitmap]::new(1920, 1080, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $image = [System.Drawing.Image]::FromFile($SourcePath)
    $family = New-FontFamily
    $captionFont = [System.Drawing.Font]::new($family, 46, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $smallFont = [System.Drawing.Font]::new($family, 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(246, 250, 247, 238))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(214, 226, 232, 240))
    $overlay = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(154, 8, 18, 28))
    $bar = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(226, 9, 28, 38))
    $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(238, 20, 184, 166))

    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

        Draw-CoverImage -Graphics $graphics -Image $image -Width 1920 -Height 1080
        $graphics.FillRectangle($overlay, 0, 0, 1920, 1080)
        $graphics.FillRectangle($bar, 0, 802, 1920, 278)
        $graphics.FillRectangle($accent, 0, 802, 1920, 8)

        Draw-WrappedText -Graphics $graphics -Text $Caption -Font $captionFont -Box ([System.Drawing.RectangleF]::new(130, 846, 1660, 112)) -Brush $white
        $graphics.DrawString("겉!=속", $smallFont, $muted, [System.Drawing.PointF]::new(130, 990))
        $graphics.DrawString(("SHOT {0:00}" -f $Index), $smallFont, $muted, [System.Drawing.PointF]::new(1660, 990))

        $bitmap.Save($FramePath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $accent.Dispose()
        $bar.Dispose()
        $overlay.Dispose()
        $muted.Dispose()
        $white.Dispose()
        $smallFont.Dispose()
        $captionFont.Dispose()
        $image.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$marketingRoot = Join-Path $projectRoot "Marketing"
$trailerRoot = Join-Path $marketingRoot "Trailer"
$screenshotsRoot = Join-Path $marketingRoot "Screenshots"
$shotListPath = Join-Path $trailerRoot "TRAILER_SHOTLIST.tsv"
$framesRoot = Join-Path $trailerRoot "Frames"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $trailerRoot "trailer_animatic_60s.mp4"
}

if (-not (Test-Path -LiteralPath $shotListPath)) {
    throw "Missing shot list: $shotListPath"
}

New-Item -ItemType Directory -Force -Path $framesRoot | Out-Null
Get-ChildItem -LiteralPath $framesRoot -File -Filter "shot_*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

$shots = Import-Csv -Delimiter "`t" -LiteralPath $shotListPath
$concatPath = Join-Path $trailerRoot "ffmpeg_concat.txt"
$concatLines = New-Object System.Collections.Generic.List[string]

$index = 1
foreach ($shot in $shots) {
    $source = Join-Path $screenshotsRoot $shot.source
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Missing trailer screenshot: $source"
    }

    $duration = [double]$shot.end - [double]$shot.start
    if ($duration -le 0) {
        throw "Invalid trailer shot duration: $($shot.source)"
    }

    $frame = Join-Path $framesRoot ("shot_{0:00}.png" -f $index)
    Save-TrailerFrame -SourcePath $source -Caption $shot.caption -FramePath $frame -Index $index

    $escaped = $frame.Replace("\", "/").Replace("'", "'\''")
    $concatLines.Add("file '$escaped'")
    $concatLines.Add(("duration {0:0.###}" -f $duration))
    $index++
}

$lastFrame = Join-Path $framesRoot ("shot_{0:00}.png" -f ($index - 1))
$concatLines.Add("file '$($lastFrame.Replace("\", "/").Replace("'", "'\''"))'")
Set-Content -LiteralPath $concatPath -Value $concatLines -Encoding ASCII

$ffmpeg = Resolve-Tool @("ffmpeg.exe", "ffmpeg")
$ambientFilter = @(
    "[1:a]volume=0.025,afade=t=in:st=0:d=3,afade=t=out:st=57:d=3[a1]",
    "[2:a]volume=0.018,afade=t=in:st=0:d=4,afade=t=out:st=57:d=3[a2]",
    "[3:a]volume=0.012,afade=t=in:st=0:d=5,afade=t=out:st=57:d=3[a3]",
    "[4:a]lowpass=f=1100,volume=0.035,afade=t=in:st=0:d=3,afade=t=out:st=57:d=3[a4]",
    "[a1][a2][a3][a4]amix=inputs=4:duration=longest,alimiter=limit=0.20,aformat=channel_layouts=stereo[aout]"
) -join ";"
$args = @(
    "-y",
    "-f", "concat",
    "-safe", "0",
    "-i", $concatPath,
    "-f", "lavfi",
    "-i", "sine=frequency=196:sample_rate=48000:duration=60",
    "-f", "lavfi",
    "-i", "sine=frequency=293.66:sample_rate=48000:duration=60",
    "-f", "lavfi",
    "-i", "sine=frequency=392:sample_rate=48000:duration=60",
    "-f", "lavfi",
    "-i", "anoisesrc=color=pink:sample_rate=48000:duration=60:amplitude=0.018",
    "-filter_complex", $ambientFilter,
    "-map", "0:v",
    "-map", "[aout]",
    "-t", "60",
    "-r", "30",
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    "-profile:v", "high",
    "-crf", "18",
    "-c:a", "aac",
    "-shortest",
    $OutputPath
)

$process = Start-Process -FilePath $ffmpeg -ArgumentList $args -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    throw "ffmpeg exited with code $($process.ExitCode)"
}

$paperlogyPath = Join-Path $projectRoot "Assets\Resources\Fonts\Paperlogy-7Bold.ttf"
$paperlogyHash = if (Test-Path -LiteralPath $paperlogyPath) { (Get-FileHash -LiteralPath $paperlogyPath -Algorithm SHA256).Hash } else { "missing" }
$provenancePath = Join-Path $trailerRoot "TRAILER_ANIMATIC_PROVENANCE.tsv"
Set-Content -LiteralPath $provenancePath -Value @(
    "artifact`tgenerator`tfont_path`tfont_sha256`tgenerated_at",
    ("trailer_animatic_60s.mp4`tGenerateTrailerAnimatic.ps1`t{0}`t{1}`t{2}" -f $paperlogyPath, $paperlogyHash, (Get-Date -Format "yyyy-MM-dd HH:mm:ss K"))
) -Encoding UTF8

Write-Host "Trailer animatic created: $OutputPath"


