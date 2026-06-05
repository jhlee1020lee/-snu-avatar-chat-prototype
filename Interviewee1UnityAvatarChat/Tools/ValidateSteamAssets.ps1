param(
    [string]$AssetRoot
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($AssetRoot)) {
    $AssetRoot = Join-Path $projectRoot "Marketing\SteamAssets"
}

$root = Resolve-Path $AssetRoot

$required = @(
    @{ Name = "header_capsule_920x430.png"; Width = 920; Height = 430 },
    @{ Name = "small_capsule_462x174.png"; Width = 462; Height = 174 },
    @{ Name = "main_capsule_1232x706.png"; Width = 1232; Height = 706 },
    @{ Name = "vertical_capsule_748x896.png"; Width = 748; Height = 896 },
    @{ Name = "page_background_1438x810.png"; Width = 1438; Height = 810 },
    @{ Name = "library_capsule_600x900.png"; Width = 600; Height = 900 },
    @{ Name = "library_hero_3840x1240.png"; Width = 3840; Height = 1240 },
    @{ Name = "library_header_920x430.png"; Width = 920; Height = 430 },
    @{ Name = "library_logo_1280x720.png"; Width = 1280; Height = 720 },
    @{ Name = "shortcut_icon_256x256.png"; Width = 256; Height = 256 },
    @{ Name = "source_keyart_1920x1080.png"; Width = 1920; Height = 1080 },
    @{ Name = "professional_keyart_1920x1080.png"; Width = 1920; Height = 1080 },
    @{ Name = "Audit\small_capsule_preview_184x69.png"; Width = 184; Height = 69 },
    @{ Name = "Audit\small_capsule_preview_120x45.png"; Width = 120; Height = 45 }
)

foreach ($asset in $required) {
    $path = Join-Path $root $asset.Name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Steam asset: $($asset.Name)"
    }

    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne $asset.Width -or $image.Height -ne $asset.Height) {
            throw "Invalid dimensions for $($asset.Name): $($image.Width)x$($image.Height), expected $($asset.Width)x$($asset.Height)"
        }
    } finally {
        $image.Dispose()
    }
}

$manifest = Join-Path $root "STEAM_ASSET_MANIFEST.tsv"
if (-not (Test-Path -LiteralPath $manifest)) {
    throw "Missing STEAM_ASSET_MANIFEST.tsv"
}

$screenshotsRoot = Join-Path $projectRoot "Marketing\Screenshots"
$screenshotManifest = Join-Path $screenshotsRoot "SCREENSHOT_MANIFEST.tsv"
if (-not (Test-Path -LiteralPath $screenshotManifest)) {
    throw "Missing Marketing\Screenshots\SCREENSHOT_MANIFEST.tsv"
}

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

foreach ($shotName in $requiredScreenshots) {
    $shotPath = Join-Path $screenshotsRoot $shotName
    if (-not (Test-Path -LiteralPath $shotPath)) {
        throw "Missing marketing screenshot: $shotName"
    }

    $image = [System.Drawing.Image]::FromFile($shotPath)
    try {
        if ($image.Width -ne 1920 -or $image.Height -ne 1080) {
            throw "Marketing screenshot has unexpected dimensions: $shotName $($image.Width)x$($image.Height)"
        }
    } finally {
        $image.Dispose()
    }
}

$manifest = Import-Csv -Delimiter "`t" -LiteralPath $screenshotManifest
if ($manifest.Count -ne $requiredScreenshots.Count) {
    throw "Screenshot manifest row count mismatch: $($manifest.Count), expected $($requiredScreenshots.Count)"
}

foreach ($shotName in $requiredScreenshots) {
    $row = $manifest | Where-Object { $_.path -eq $shotName }
    if (-not $row) {
        throw "Screenshot manifest is missing row for $shotName"
    }
    if ([string]::IsNullOrWhiteSpace($row.source) -or [string]::IsNullOrWhiteSpace($row.sha256)) {
        throw "Screenshot manifest row is incomplete for $shotName"
    }
}

Write-Host "Steam asset validation passed: $root"
