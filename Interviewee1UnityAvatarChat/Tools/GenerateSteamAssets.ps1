param(
    [string]$SourceImage,
    [string]$OutputRoot
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$script:privateFontCollections = @()
if ([string]::IsNullOrWhiteSpace($SourceImage)) {
    $professionalKeyArtSource = Join-Path $projectRoot "Marketing\SteamAssets\professional_keyart_1920x1080.png"
    $keyArtSource = Join-Path $projectRoot "Marketing\SteamAssets\source_keyart_1920x1080.png"
    if (Test-Path -LiteralPath $professionalKeyArtSource) {
        $SourceImage = $professionalKeyArtSource
    } elseif (Test-Path -LiteralPath $keyArtSource) {
        $SourceImage = $keyArtSource
    } else {
        $SourceImage = Join-Path $projectRoot "Marketing\Screenshots\04-dialogue-scroll.png"
    }
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot "Marketing\SteamAssets"
}

if (-not (Test-Path -LiteralPath $SourceImage)) {
    throw "Source image not found: $SourceImage"
}

$out = New-Item -ItemType Directory -Force -Path $OutputRoot
$auditDir = New-Item -ItemType Directory -Force -Path (Join-Path $out.FullName "Audit")

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
        [int]$Height,
        [float]$FocusX = 0.52,
        [float]$FocusY = 0.44
    )

    $baseX = 0
    $baseY = 0
    $baseW = $Image.Width
    $baseH = $Image.Height
    $targetRatio = $Width / [float]$Height
    if ($targetRatio -gt 1.15) {
        $baseY = [int]($Image.Height * 0.08)
        $baseH = [int]($Image.Height * 0.55)
    } elseif ($targetRatio -lt 0.95) {
        $baseX = [int]($Image.Width * 0.18)
        $baseY = [int]($Image.Height * 0.04)
        $baseW = [int]($Image.Width * 0.64)
        $baseH = [int]($Image.Height * 0.60)
    }

    $sourceRatio = $baseW / [float]$baseH

    if ($sourceRatio -gt $targetRatio) {
        $cropH = $baseH
        $cropW = [int]($cropH * $targetRatio)
    } else {
        $cropW = $baseW
        $cropH = [int]($cropW / $targetRatio)
    }

    $x = $baseX + [int](($baseW - $cropW) * $FocusX)
    $y = $baseY + [int](($baseH - $cropH) * $FocusY)
    $x = [Math]::Max($baseX, [Math]::Min($x, $baseX + $baseW - $cropW))
    $y = [Math]::Max($baseY, [Math]::Min($y, $baseY + $baseH - $cropH))

    $srcRect = [System.Drawing.Rectangle]::new($x, $y, $cropW, $cropH)
    $dstRect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
    $Graphics.DrawImage($Image, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
}

function Fill-VerticalShade {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$Width,
        [int]$Height,
        [int]$TopAlpha,
        [int]$BottomAlpha
    )

    $rect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
    $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $rect,
        [System.Drawing.Color]::FromArgb($TopAlpha, 255, 249, 231),
        [System.Drawing.Color]::FromArgb($BottomAlpha, 24, 34, 38),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    try {
        $Graphics.FillRectangle($brush, $rect)
    } finally {
        $brush.Dispose()
    }
}

function Draw-Title {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.RectangleF]$Box,
        [float]$MaxSize,
        [System.Drawing.FontFamily]$Family,
        [System.Drawing.StringAlignment]$Alignment = [System.Drawing.StringAlignment]::Near,
        [System.Drawing.StringAlignment]$LineAlignment = [System.Drawing.StringAlignment]::Center
    )

    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = $Alignment
    $format.LineAlignment = $LineAlignment
    $format.Trimming = [System.Drawing.StringTrimming]::None

    $size = $MaxSize
    while ($size -gt 10) {
        $font = [System.Drawing.Font]::new($Family, $size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        try {
            $measured = $Graphics.MeasureString($Text, $font, [System.Drawing.SizeF]::new($Box.Width, 2000), $format)
            if ($measured.Width -le ($Box.Width + 1) -and $measured.Height -le ($Box.Height + 1)) {
                break
            }
        } finally {
            $font.Dispose()
        }
        $size -= 2
    }

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $outline = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 8, 16, 24), [Math]::Max(2, $size * 0.07))
    $fill = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 250, 247, 238))
    try {
        $path.AddString($Text, $Family, [int][System.Drawing.FontStyle]::Bold, $size, $Box, $format)
        $Graphics.DrawPath($outline, $path)
        $Graphics.FillPath($fill, $path)
    } finally {
        $fill.Dispose()
        $outline.Dispose()
        $path.Dispose()
        $format.Dispose()
    }
}

function New-Canvas {
    param([int]$Width, [int]$Height)

    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return @($bitmap, $graphics)
}

function Save-Png {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path
    )

    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-Asset {
    param(
        [string]$Name,
        [int]$Width,
        [int]$Height,
        [string]$Title,
        [float]$TitleSize,
        [System.Drawing.RectangleF]$TitleBox,
        [System.Drawing.StringAlignment]$Alignment,
        [float]$FocusX = 0.52,
        [float]$FocusY = 0.44,
        [int]$TopShade = 44,
        [int]$BottomShade = 178
    )

    $canvas = New-Canvas -Width $Width -Height $Height
    $bitmap = $canvas[0]
    $graphics = $canvas[1]
    try {
        Draw-CoverImage -Graphics $graphics -Image $source -Width $Width -Height $Height -FocusX $FocusX -FocusY $FocusY
        Fill-VerticalShade -Graphics $graphics -Width $Width -Height $Height -TopAlpha $TopShade -BottomAlpha $BottomShade
        Draw-Title -Graphics $graphics -Text $Title -Box $TitleBox -MaxSize $TitleSize -Family $family -Alignment $Alignment
        Save-Png -Bitmap $bitmap -Path (Join-Path $out.FullName $Name)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$source = [System.Drawing.Image]::FromFile((Resolve-Path $SourceImage))
$family = New-FontFamily

try {
    New-Asset -Name "header_capsule_920x430.png" -Width 920 -Height 430 -Title "겉!=속" -TitleSize 96 -TitleBox ([System.Drawing.RectangleF]::new(58, 242, 805, 126)) -Alignment ([System.Drawing.StringAlignment]::Near) -FocusX 0.52 -FocusY 0.36 -TopShade 14 -BottomShade 108
    New-Asset -Name "small_capsule_462x174.png" -Width 462 -Height 174 -Title "겉!=속" -TitleSize 54 -TitleBox ([System.Drawing.RectangleF]::new(22, 96, 418, 56)) -Alignment ([System.Drawing.StringAlignment]::Center) -FocusX 0.50 -FocusY 0.36 -TopShade 18 -BottomShade 116
    New-Asset -Name "main_capsule_1232x706.png" -Width 1232 -Height 706 -Title "겉!=속" -TitleSize 124 -TitleBox ([System.Drawing.RectangleF]::new(82, 78, 1072, 150)) -Alignment ([System.Drawing.StringAlignment]::Near) -FocusX 0.52 -FocusY 0.38 -TopShade 40 -BottomShade 96
    New-Asset -Name "vertical_capsule_748x896.png" -Width 748 -Height 896 -Title "겉!=속" -TitleSize 118 -TitleBox ([System.Drawing.RectangleF]::new(66, 606, 616, 178)) -Alignment ([System.Drawing.StringAlignment]::Center) -FocusX 0.50 -FocusY 0.48 -TopShade 10 -BottomShade 124
    New-Asset -Name "library_capsule_600x900.png" -Width 600 -Height 900 -Title "겉!=속" -TitleSize 104 -TitleBox ([System.Drawing.RectangleF]::new(50, 616, 500, 170)) -Alignment ([System.Drawing.StringAlignment]::Center) -FocusX 0.50 -FocusY 0.48 -TopShade 10 -BottomShade 124
    New-Asset -Name "library_header_920x430.png" -Width 920 -Height 430 -Title "겉!=속" -TitleSize 96 -TitleBox ([System.Drawing.RectangleF]::new(58, 242, 805, 126)) -Alignment ([System.Drawing.StringAlignment]::Near) -FocusX 0.52 -FocusY 0.36 -TopShade 14 -BottomShade 108
    New-Asset -Name "library_hero_3840x1240.png" -Width 3840 -Height 1240 -Title "겉!=속" -TitleSize 250 -TitleBox ([System.Drawing.RectangleF]::new(250, 790, 2780, 250)) -Alignment ([System.Drawing.StringAlignment]::Near) -FocusX 0.52 -FocusY 0.35 -TopShade 10 -BottomShade 104
    New-Asset -Name "page_background_1438x810.png" -Width 1438 -Height 810 -Title "겉!=속" -TitleSize 1 -TitleBox ([System.Drawing.RectangleF]::new(0, 0, 1, 1)) -Alignment ([System.Drawing.StringAlignment]::Near) -FocusX 0.52 -FocusY 0.35 -TopShade 28 -BottomShade 44

    $logoCanvas = New-Canvas -Width 1280 -Height 720
    $logoBitmap = $logoCanvas[0]
    $logoGraphics = $logoCanvas[1]
    try {
        $logoGraphics.Clear([System.Drawing.Color]::Transparent)
        Draw-Title -Graphics $logoGraphics -Text "겉!=속" -Box ([System.Drawing.RectangleF]::new(90, 236, 1100, 220)) -MaxSize 180 -Family $family -Alignment ([System.Drawing.StringAlignment]::Center)
        Save-Png -Bitmap $logoBitmap -Path (Join-Path $out.FullName "library_logo_1280x720.png")
    } finally {
        $logoGraphics.Dispose()
        $logoBitmap.Dispose()
    }

    New-Asset -Name "shortcut_icon_256x256.png" -Width 256 -Height 256 -Title "겉!=`n속" -TitleSize 54 -TitleBox ([System.Drawing.RectangleF]::new(28, 86, 200, 88)) -Alignment ([System.Drawing.StringAlignment]::Center) -FocusX 0.50 -FocusY 0.45 -TopShade 18 -BottomShade 104

    $small = [System.Drawing.Image]::FromFile((Join-Path $out.FullName "small_capsule_462x174.png"))
    try {
        foreach ($preview in @(
            @{ Name = "small_capsule_preview_184x69.png"; Width = 184; Height = 69 },
            @{ Name = "small_capsule_preview_120x45.png"; Width = 120; Height = 45 }
        )) {
            $canvas = New-Canvas -Width $preview.Width -Height $preview.Height
            $bitmap = $canvas[0]
            $graphics = $canvas[1]
            try {
                $graphics.DrawImage($small, 0, 0, $preview.Width, $preview.Height)
                Save-Png -Bitmap $bitmap -Path (Join-Path $auditDir.FullName $preview.Name)
            } finally {
                $graphics.Dispose()
                $bitmap.Dispose()
            }
        }
    } finally {
        $small.Dispose()
    }
} finally {
    $source.Dispose()
}

$manifest = Get-ChildItem -LiteralPath $out.FullName -File -Recurse -Filter "*.png" |
    Sort-Object FullName |
    ForEach-Object {
        $image = [System.Drawing.Image]::FromFile($_.FullName)
        try {
            $relative = $_.FullName.Substring($out.FullName.Length + 1)
            "{0}`t{1}x{2}`t{3}" -f $relative, $image.Width, $image.Height, $_.Length
        } finally {
            $image.Dispose()
        }
    }

Set-Content -LiteralPath (Join-Path $out.FullName "STEAM_ASSET_MANIFEST.tsv") -Value @("path`tdimensions`tbytes") -Encoding UTF8
Add-Content -LiteralPath (Join-Path $out.FullName "STEAM_ASSET_MANIFEST.tsv") -Value $manifest -Encoding UTF8

$paperlogyPath = Join-Path $projectRoot "Assets\Resources\Fonts\Paperlogy-7Bold.ttf"
$paperlogyHash = if (Test-Path -LiteralPath $paperlogyPath) { (Get-FileHash -LiteralPath $paperlogyPath -Algorithm SHA256).Hash } else { "missing" }
$provenancePath = Join-Path $out.FullName "ASSET_PROVENANCE.tsv"
Set-Content -LiteralPath $provenancePath -Value @(
    "artifact`tgenerator`tfont_path`tfont_sha256`tgenerated_at",
    ("SteamAssets`tGenerateSteamAssets.ps1`t{0}`t{1}`t{2}" -f $paperlogyPath, $paperlogyHash, (Get-Date -Format "yyyy-MM-dd HH:mm:ss K"))
) -Encoding UTF8

Write-Host "Steam asset drafts created: $($out.FullName)"

