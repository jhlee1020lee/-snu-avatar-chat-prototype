param(
    [string]$SourceRoot,
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

function Get-GameplayMarker {
    param([int]$Index)

    switch ($Index) {
        1 { return [pscustomobject]@{ X = 960; Y = 520; Label = "시작 화면" } }
        2 { return [pscustomobject]@{ X = 1290; Y = 510; Label = "질문 선택" } }
        3 { return [pscustomobject]@{ X = 1120; Y = 410; Label = "단서 확인" } }
        4 { return [pscustomobject]@{ X = 1540; Y = 720; Label = "긴 답변 읽기" } }
        5 { return [pscustomobject]@{ X = 1430; Y = 420; Label = "기억장 진행" } }
        6 { return [pscustomobject]@{ X = 980; Y = 540; Label = "마무리 선택" } }
        7 { return [pscustomobject]@{ X = 1360; Y = 570; Label = "기록 다시 보기" } }
        8 { return [pscustomobject]@{ X = 920; Y = 440; Label = "옵션 조정" } }
        9 { return [pscustomobject]@{ X = 1110; Y = 690; Label = "데이터 관리" } }
        default { return [pscustomobject]@{ X = 960; Y = 540; Label = "플레이 화면" } }
    }
}

function Draw-GameplayMarker {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$X,
        [int]$Y,
        [string]$Label,
        [System.Drawing.FontFamily]$Family
    )

    $ringPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230, 20, 184, 166), 6)
    $ringPen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Center
    $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(118, 0, 0, 0))
    $fillBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(246, 250, 247, 238))
    $outlinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 8, 18, 28), 3)
    $labelBack = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(224, 8, 18, 28))
    $labelText = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(246, 250, 247, 238))
    $labelFont = [System.Drawing.Font]::new($Family, 22, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

    try {
        $Graphics.DrawEllipse($ringPen, $X - 28, $Y - 28, 56, 56)
        $Graphics.FillEllipse($shadowBrush, $X - 18, $Y - 18, 36, 36)
        $Graphics.FillEllipse($fillBrush, $X - 13, $Y - 13, 26, 26)
        $Graphics.DrawEllipse($outlinePen, $X - 13, $Y - 13, 26, 26)

        $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        try {
            [System.Drawing.Point[]]$points = @(
                [System.Drawing.Point]::new($X + 20, $Y + 18),
                [System.Drawing.Point]::new($X + 20, $Y + 78),
                [System.Drawing.Point]::new($X + 58, $Y + 54)
            )
            $path.AddPolygon($points)
            $Graphics.FillPath($shadowBrush, $path)
            $matrix = [System.Drawing.Drawing2D.Matrix]::new()
            try {
                $matrix.Translate(-5, -6)
                $path.Transform($matrix)
                $Graphics.FillPath($fillBrush, $path)
                $Graphics.DrawPath($outlinePen, $path)
            } finally {
                $matrix.Dispose()
            }
        } finally {
            $path.Dispose()
        }

        $labelWidth = 176
        $labelHeight = 36
        $labelX = [Math]::Min([Math]::Max($X - [int]($labelWidth / 2), 72), 1920 - $labelWidth - 72)
        $labelY = [Math]::Min([Math]::Max($Y + 74, 86), 748)
        $labelBox = [System.Drawing.RectangleF]::new($labelX, $labelY, $labelWidth, $labelHeight)
        $Graphics.FillRectangle($labelBack, $labelBox)
        $Graphics.DrawString($Label, $labelFont, $labelText, $labelBox, $format)
    } finally {
        $format.Dispose()
        $labelFont.Dispose()
        $labelText.Dispose()
        $labelBack.Dispose()
        $outlinePen.Dispose()
        $fillBrush.Dispose()
        $shadowBrush.Dispose()
        $ringPen.Dispose()
    }
}

function Save-BuildCaptureFrame {
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
    $captionFont = [System.Drawing.Font]::new($family, 44, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $smallFont = [System.Drawing.Font]::new($family, 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(248, 250, 247, 238))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 226, 232, 240))
    $topShade = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(42, 5, 10, 18))
    $bottomShade = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(208, 5, 10, 18))
    $bar = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(226, 8, 18, 28))
    $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(238, 20, 184, 166))

    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

        Draw-CoverImage -Graphics $graphics -Image $image -Width 1920 -Height 1080
        $graphics.FillRectangle($topShade, 0, 0, 1920, 180)
        $graphics.FillRectangle($bottomShade, 0, 790, 1920, 290)
        $graphics.FillRectangle($bar, 0, 824, 1920, 256)
        $graphics.FillRectangle($accent, 0, 824, 1920, 8)

        $marker = Get-GameplayMarker -Index $Index
        Draw-GameplayMarker -Graphics $graphics -X $marker.X -Y $marker.Y -Label $marker.Label -Family $family

        Draw-WrappedText -Graphics $graphics -Text $Caption -Font $captionFont -Box ([System.Drawing.RectangleF]::new(130, 862, 1660, 94)) -Brush $white
        $graphics.DrawString("겉!=속", $smallFont, $muted, [System.Drawing.PointF]::new(130, 990))
        $graphics.DrawString(("GAMEPLAY CAPTURE {0:00}" -f $Index), $smallFont, $muted, [System.Drawing.PointF]::new(1504, 990))

        $bitmap.Save($FramePath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $accent.Dispose()
        $bar.Dispose()
        $bottomShade.Dispose()
        $topShade.Dispose()
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
$trailerRoot = Join-Path $projectRoot "Marketing\Trailer"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Join-Path $buildRoot "release-smoke"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $trailerRoot "trailer_build_capture_60s.mp4"
}

$shotListPath = Join-Path $trailerRoot "TRAILER_BUILD_CAPTURE_SHOTLIST.tsv"
if (-not (Test-Path -LiteralPath $shotListPath)) {
    throw "Missing build capture shot list: $shotListPath"
}

$source = Resolve-Path $SourceRoot
$framesRoot = Join-Path $trailerRoot "BuildCaptureFrames"
$clipRoot = Join-Path $trailerRoot "BuildCaptureClips"
New-Item -ItemType Directory -Force -Path $framesRoot | Out-Null
New-Item -ItemType Directory -Force -Path $clipRoot | Out-Null
Get-ChildItem -LiteralPath $framesRoot -File -Filter "build_shot_*.png" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $clipRoot -File -Filter "build_clip_*.mp4" -ErrorAction SilentlyContinue | Remove-Item -Force

$shots = Import-Csv -Delimiter "`t" -LiteralPath $shotListPath
$clipConcatPath = Join-Path $trailerRoot "ffmpeg_build_capture_clips.txt"
$clipConcatLines = New-Object System.Collections.Generic.List[string]
$ffmpeg = Resolve-Tool @("ffmpeg.exe", "ffmpeg")

$index = 1
foreach ($shot in $shots) {
    $sourcePath = Join-Path $source $shot.source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing build capture source: $sourcePath"
    }

    $duration = [double]$shot.end - [double]$shot.start
    if ($duration -le 0) {
        throw "Invalid build capture shot duration: $($shot.source)"
    }

    $frame = Join-Path $framesRoot ("build_shot_{0:00}.png" -f $index)
    Save-BuildCaptureFrame -SourcePath $sourcePath -Caption $shot.caption -FramePath $frame -Index $index

    $clip = Join-Path $clipRoot ("build_clip_{0:00}.mp4" -f $index)
    $frameCount = [Math]::Max(1, [int][Math]::Round($duration * 30.0))
    $zoomDelta = 0.00022 + (($index % 3) * 0.00008)
    $zoomLimit = 1.014 + (($index % 4) * 0.002)
    $zoomDeltaText = $zoomDelta.ToString("0.00000", [System.Globalization.CultureInfo]::InvariantCulture)
    $zoomLimitText = $zoomLimit.ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
    $zoomFilter = "zoompan=z='min(zoom+$zoomDeltaText,$zoomLimitText)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frameCount}:s=hd1080:fps=30,format=yuv420p"
    $clipArgs = @(
        "-y",
        "-loop", "1",
        "-i", $frame,
        "-vf", $zoomFilter,
        "-frames:v", $frameCount,
        "-an",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-profile:v", "high",
        "-crf", "18",
        $clip
    )
    & $ffmpeg @clipArgs
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg clip generation exited with code $LASTEXITCODE"
    }

    $escapedClip = $clip.Replace("\", "/").Replace("'", "'\''")
    $clipConcatLines.Add("file '$escapedClip'")
    $index++
}

Set-Content -LiteralPath $clipConcatPath -Value $clipConcatLines -Encoding ASCII

$ambientFilter = @(
    "[1:a]volume=0.024,afade=t=in:st=0:d=3,afade=t=out:st=57:d=3[a1]",
    "[2:a]volume=0.016,afade=t=in:st=0:d=4,afade=t=out:st=57:d=3[a2]",
    "[3:a]volume=0.011,afade=t=in:st=0:d=5,afade=t=out:st=57:d=3[a3]",
    "[4:a]lowpass=f=1200,volume=0.032,afade=t=in:st=0:d=3,afade=t=out:st=57:d=3[a4]",
    "[a1][a2][a3][a4]amix=inputs=4:duration=longest,alimiter=limit=0.20,aformat=channel_layouts=stereo[aout]"
) -join ";"

$args = @(
    "-y",
    "-f", "concat",
    "-safe", "0",
    "-i", $clipConcatPath,
    "-f", "lavfi",
    "-i", "sine=frequency=196:sample_rate=48000:duration=60",
    "-f", "lavfi",
    "-i", "sine=frequency=293.66:sample_rate=48000:duration=60",
    "-f", "lavfi",
    "-i", "sine=frequency=392:sample_rate=48000:duration=60",
    "-f", "lavfi",
    "-i", "anoisesrc=color=pink:sample_rate=48000:duration=60:amplitude=0.016",
    "-filter_complex", $ambientFilter,
    "-map", "0:v",
    "-map", "[aout]",
    "-t", "60",
    "-c:v", "copy",
    "-c:a", "aac",
    "-shortest",
    $OutputPath
)

& $ffmpeg @args
if ($LASTEXITCODE -ne 0) {
    throw "ffmpeg exited with code $LASTEXITCODE"
}

Remove-Item -LiteralPath $clipConcatPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $clipRoot -Recurse -Force -ErrorAction SilentlyContinue
$paperlogyPath = Join-Path $projectRoot "Assets\Resources\Fonts\Paperlogy-7Bold.ttf"
$paperlogyHash = if (Test-Path -LiteralPath $paperlogyPath) { (Get-FileHash -LiteralPath $paperlogyPath -Algorithm SHA256).Hash } else { "missing" }
$provenancePath = Join-Path $trailerRoot "TRAILER_BUILD_CAPTURE_PROVENANCE.tsv"
Set-Content -LiteralPath $provenancePath -Value @(
    "artifact`tgenerator`tfont_path`tfont_sha256`tgenerated_at",
    ("trailer_build_capture_60s.mp4`tGenerateBuildCaptureTrailer.ps1`t{0}`t{1}`t{2}" -f $paperlogyPath, $paperlogyHash, (Get-Date -Format "yyyy-MM-dd HH:mm:ss K"))
) -Encoding UTF8
Write-Host "Build capture trailer created: $OutputPath"


