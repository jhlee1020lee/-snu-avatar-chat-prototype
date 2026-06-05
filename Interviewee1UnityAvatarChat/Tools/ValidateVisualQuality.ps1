param(
    [string]$ScreenshotsRoot,
    [string]$SteamAssetsRoot,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required path: $Path"
    }
}

function Get-ImageMetrics {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path
    $bitmap = [System.Drawing.Bitmap]::new($item.FullName)
    try {
        $sampleStep = 8
        $edgeStep = 4
        $sum = 0.0
        $sum2 = 0.0
        $count = 0
        $dark = 0
        $purple = 0
        $edge = 0
        $edgeBusy = 0

        for ($y = 0; $y -lt $bitmap.Height; $y += $sampleStep) {
            for ($x = 0; $x -lt $bitmap.Width; $x += $sampleStep) {
                $color = $bitmap.GetPixel($x, $y)
                $luminance = 0.2126 * $color.R + 0.7152 * $color.G + 0.0722 * $color.B
                $sum += $luminance
                $sum2 += $luminance * $luminance
                $count++

                if ($luminance -lt 40) {
                    $dark++
                }
                if ($color.R -gt 95 -and $color.B -gt 120 -and $color.G -lt 100 -and [math]::Abs($color.R - $color.B) -lt 90) {
                    $purple++
                }
            }
        }

        for ($y = 0; $y -lt $bitmap.Height; $y += $edgeStep) {
            for ($x = 0; $x -lt $bitmap.Width; $x += $edgeStep) {
                if ($x -lt 12 -or $x -gt ($bitmap.Width - 13) -or $y -lt 12 -or $y -gt ($bitmap.Height - 13)) {
                    $color = $bitmap.GetPixel($x, $y)
                    $luminance = 0.2126 * $color.R + 0.7152 * $color.G + 0.0722 * $color.B
                    $saturation = [math]::Max($color.R, [math]::Max($color.G, $color.B)) - [math]::Min($color.R, [math]::Min($color.G, $color.B))
                    $edge++
                    if ($luminance -lt 35 -or $luminance -gt 235 -or $saturation -gt 140) {
                        $edgeBusy++
                    }
                }
            }
        }

        $average = $sum / [math]::Max(1, $count)
        $variance = ($sum2 / [math]::Max(1, $count)) - ($average * $average)
        if ($variance -lt 0) {
            $variance = 0
        }

        [pscustomobject]@{
            Path = $item.FullName
            Name = $item.Name
            Width = $bitmap.Width
            Height = $bitmap.Height
            Bytes = $item.Length
            AverageLuminance = [math]::Round($average, 2)
            LuminanceStdDev = [math]::Round([math]::Sqrt($variance), 2)
            DarkPixelPct = [math]::Round(100 * $dark / [math]::Max(1, $count), 3)
            PurplePixelPct = [math]::Round(100 * $purple / [math]::Max(1, $count), 3)
            EdgeBusyPct = [math]::Round(100 * $edgeBusy / [math]::Max(1, $edge), 3)
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

function Assert-VisualMetrics {
    param(
        [object]$Metrics,
        [int]$Width,
        [int]$Height,
        [double]$MinAverageLuminance = 55,
        [double]$MinStdDev = 18,
        [double]$MaxDarkPixelPct = 45,
        [double]$MaxPurplePixelPct = 2,
        [double]$MaxEdgeBusyPct = 8
    )

    if ($Metrics.Width -ne $Width -or $Metrics.Height -ne $Height) {
        throw "Invalid image dimensions for $($Metrics.Name): $($Metrics.Width)x$($Metrics.Height), expected ${Width}x${Height}"
    }
    if ($Metrics.Bytes -lt 100000) {
        throw "Image is too small and may be blank: $($Metrics.Name) ($($Metrics.Bytes) bytes)"
    }
    if ($Metrics.AverageLuminance -lt $MinAverageLuminance) {
        throw "Image is too dark: $($Metrics.Name) average luminance $($Metrics.AverageLuminance), minimum $MinAverageLuminance"
    }
    if ($Metrics.LuminanceStdDev -lt $MinStdDev) {
        throw "Image has too little visual variation: $($Metrics.Name) stddev $($Metrics.LuminanceStdDev), minimum $MinStdDev"
    }
    if ($Metrics.DarkPixelPct -gt $MaxDarkPixelPct) {
        throw "Image has too much near-black area: $($Metrics.Name) $($Metrics.DarkPixelPct)%, maximum $MaxDarkPixelPct%"
    }
    if ($Metrics.PurplePixelPct -gt $MaxPurplePixelPct) {
        throw "Image has too many strong purple artifact pixels: $($Metrics.Name) $($Metrics.PurplePixelPct)%, maximum $MaxPurplePixelPct%"
    }
    if ($Metrics.EdgeBusyPct -gt $MaxEdgeBusyPct) {
        throw "Image has too much high-contrast content touching the outer edge: $($Metrics.Name) $($Metrics.EdgeBusyPct)%, maximum $MaxEdgeBusyPct%"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($ScreenshotsRoot)) {
    $ScreenshotsRoot = Join-Path $projectRoot "Marketing\Screenshots"
}
if ([string]::IsNullOrWhiteSpace($SteamAssetsRoot)) {
    $SteamAssetsRoot = Join-Path $projectRoot "Marketing\SteamAssets"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Marketing\VisualQuality\VISUAL_QUALITY_REPORT.tsv"
}

Assert-Path $ScreenshotsRoot
Assert-Path $SteamAssetsRoot

$checks = @()
$requiredScreenshots = @(
    "01-title-session-start.png",
    "02-question-phone.png",
    "03-hotspot-preview.png",
    "04-dialogue-scroll.png",
    "05-memory-complete.png",
    "06-closing-card.png",
    "07-record-archive.png",
    "08-record-delete.png",
    "09-accessibility-settings.png",
    "10-data-policy-delete.png",
    "11-title-continue.png"
)

$minimumLuminanceByScreenshot = @{
    "01-title-session-start.png" = 105
    "05-memory-complete.png" = 115
    "06-closing-card.png" = 115
    "07-record-archive.png" = 115
    "08-record-delete.png" = 115
    "09-accessibility-settings.png" = 100
    "10-data-policy-delete.png" = 100
    "11-title-continue.png" = 105
}

foreach ($name in $requiredScreenshots) {
    $path = Join-Path $ScreenshotsRoot $name
    Assert-Path $path
    $metrics = Get-ImageMetrics -Path $path
    $minAverageLuminance = if ($minimumLuminanceByScreenshot.ContainsKey($name)) { $minimumLuminanceByScreenshot[$name] } else { 70 }
    Assert-VisualMetrics -Metrics $metrics -Width 1920 -Height 1080 -MinAverageLuminance $minAverageLuminance
    $checks += $metrics
}

$steamAssetChecks = @(
    @{ Name = "source_keyart_1920x1080.png"; Width = 1920; Height = 1080; MinAverageLuminance = 110; MaxDarkPixelPct = 18; MaxEdgeBusyPct = 12 },
    @{ Name = "professional_keyart_1920x1080.png"; Width = 1920; Height = 1080; MinAverageLuminance = 110; MaxDarkPixelPct = 18; MaxEdgeBusyPct = 12 },
    @{ Name = "header_capsule_920x430.png"; Width = 920; Height = 430; MinAverageLuminance = 100; MaxDarkPixelPct = 22; MaxEdgeBusyPct = 12 },
    @{ Name = "small_capsule_462x174.png"; Width = 462; Height = 174; MinAverageLuminance = 95; MaxDarkPixelPct = 24; MaxEdgeBusyPct = 12 },
    @{ Name = "main_capsule_1232x706.png"; Width = 1232; Height = 706; MinAverageLuminance = 100; MaxDarkPixelPct = 22; MaxEdgeBusyPct = 12 },
    @{ Name = "vertical_capsule_748x896.png"; Width = 748; Height = 896; MinAverageLuminance = 95; MaxDarkPixelPct = 24; MaxEdgeBusyPct = 12 },
    @{ Name = "library_capsule_600x900.png"; Width = 600; Height = 900; MinAverageLuminance = 95; MaxDarkPixelPct = 24; MaxEdgeBusyPct = 12 },
    @{ Name = "library_header_920x430.png"; Width = 920; Height = 430; MinAverageLuminance = 100; MaxDarkPixelPct = 22; MaxEdgeBusyPct = 12 },
    @{ Name = "library_hero_3840x1240.png"; Width = 3840; Height = 1240; MinAverageLuminance = 95; MaxDarkPixelPct = 24; MaxEdgeBusyPct = 12 },
    @{ Name = "page_background_1438x810.png"; Width = 1438; Height = 810; MinAverageLuminance = 110; MaxDarkPixelPct = 18; MaxEdgeBusyPct = 12 },
    @{ Name = "shortcut_icon_256x256.png"; Width = 256; Height = 256; MinAverageLuminance = 90; MaxDarkPixelPct = 28; MaxEdgeBusyPct = 18 }
)
foreach ($asset in $steamAssetChecks) {
    $path = Join-Path $SteamAssetsRoot $asset.Name
    Assert-Path $path
    $metrics = Get-ImageMetrics -Path $path
    Assert-VisualMetrics -Metrics $metrics -Width $asset.Width -Height $asset.Height -MinAverageLuminance $asset.MinAverageLuminance -MaxDarkPixelPct $asset.MaxDarkPixelPct -MaxEdgeBusyPct $asset.MaxEdgeBusyPct
    $checks += $metrics
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$rows = @("path`twidth`theight`tbytes`taverage_luminance`tluminance_stddev`tdark_pixel_pct`tpurple_pixel_pct`tedge_busy_pct")
$rows += $checks | ForEach-Object {
    $relative = $_.Path.Substring($projectRoot.Path.Length + 1)
    "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}" -f $relative, $_.Width, $_.Height, $_.Bytes, $_.AverageLuminance, $_.LuminanceStdDev, $_.DarkPixelPct, $_.PurplePixelPct, $_.EdgeBusyPct
}
Set-Content -LiteralPath $OutputPath -Value $rows -Encoding UTF8

Write-Host "Visual quality validation passed: $OutputPath"
