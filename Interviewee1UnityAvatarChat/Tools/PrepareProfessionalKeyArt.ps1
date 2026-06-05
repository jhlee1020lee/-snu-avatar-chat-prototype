param(
    [Parameter(Mandatory = $true)]
    [string]$SourceImage,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Marketing\SteamAssets\professional_keyart_1920x1080.png"
}

if (-not (Test-Path -LiteralPath $SourceImage)) {
    throw "Source image not found: $SourceImage"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null

function Draw-CoverImage {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height,
        [System.Drawing.Imaging.ImageAttributes]$Attributes = $null
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
    if ($null -eq $Attributes) {
        $Graphics.DrawImage($Image, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    } else {
        $Graphics.DrawImage($Image, $dstRect, $srcRect.X, $srcRect.Y, $srcRect.Width, $srcRect.Height, [System.Drawing.GraphicsUnit]::Pixel, $Attributes)
    }
}

function New-KeyArtColorAttributes {
    $matrix = [System.Drawing.Imaging.ColorMatrix]::new()
    $matrix.Matrix00 = 1.08
    $matrix.Matrix11 = 1.08
    $matrix.Matrix22 = 1.04
    $matrix.Matrix33 = 1
    $matrix.Matrix44 = 1
    $matrix.Matrix40 = 0.07
    $matrix.Matrix41 = 0.06
    $matrix.Matrix42 = 0.035

    $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
    $attributes.SetColorMatrix($matrix)
    return $attributes
}

function Fill-WarmLift {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$Width,
        [int]$Height
    )

    $rect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
    $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $rect,
        [System.Drawing.Color]::FromArgb(18, 255, 249, 232),
        [System.Drawing.Color]::FromArgb(32, 255, 239, 205),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    try {
        $Graphics.FillRectangle($brush, $rect)
    } finally {
        $brush.Dispose()
    }
}

$resolvedSourceImage = (Resolve-Path $SourceImage).Path
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$savePath = $outputFullPath
$replaceAfterSave = $false
if ([System.StringComparer]::OrdinalIgnoreCase.Equals($resolvedSourceImage, $outputFullPath)) {
    $savePath = Join-Path (Split-Path -Parent $outputFullPath) ("{0}.tmp{1}" -f [System.IO.Path]::GetFileNameWithoutExtension($outputFullPath), [System.IO.Path]::GetExtension($outputFullPath))
    $replaceAfterSave = $true
}

$source = [System.Drawing.Image]::FromFile($resolvedSourceImage)
$bitmap = [System.Drawing.Bitmap]::new(1920, 1080, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$attributes = New-KeyArtColorAttributes

try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    Draw-CoverImage -Graphics $graphics -Image $source -Width 1920 -Height 1080 -Attributes $attributes
    Fill-WarmLift -Graphics $graphics -Width 1920 -Height 1080
    $bitmap.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $attributes.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    $source.Dispose()
}

if ($replaceAfterSave) {
    Move-Item -LiteralPath $savePath -Destination $outputFullPath -Force
}

Write-Host "Professional key art prepared: $OutputPath"
