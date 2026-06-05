param(
    [string]$SourceRoot,
    [string]$OutputRoot
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Assert-ImageSize {
    param(
        [string]$Path,
        [int]$Width,
        [int]$Height
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing screenshot source: $Path"
    }

    $image = [System.Drawing.Image]::FromFile($Path)
    try {
        if ($image.Width -ne $Width -or $image.Height -ne $Height) {
            throw "Invalid screenshot dimensions for ${Path}: $($image.Width)x$($image.Height), expected ${Width}x${Height}"
        }
    } finally {
        $image.Dispose()
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Join-Path $projectRoot "Build\release-smoke"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot "Marketing\Screenshots"
}

$source = Resolve-Path $SourceRoot
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$output = Resolve-Path $OutputRoot

$shots = @(
    @{ Source = "title-no-save.png"; Target = "01-title-session-start.png" },
    @{ Source = "question-phone.png"; Target = "02-question-phone.png" },
    @{ Source = "hotspot-preview.png"; Target = "03-hotspot-preview.png" },
    @{ Source = "long-dialogue.png"; Target = "04-dialogue-scroll.png" },
    @{ Source = "memory-complete.png"; Target = "05-memory-complete.png" },
    @{ Source = "closing-card.png"; Target = "06-closing-card.png" },
    @{ Source = "ending-archive.png"; Target = "07-record-archive.png" },
    @{ Source = "record-delete-confirm.png"; Target = "08-record-delete.png" },
    @{ Source = "accessibility-settings.png"; Target = "09-accessibility-settings.png" },
    @{ Source = "data-policy-delete-prompt.png"; Target = "10-data-policy-delete.png" },
    @{ Source = "title-with-save.png"; Target = "11-title-continue.png" }
)

$promotedUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$manifestRows = New-Object System.Collections.Generic.List[string]
$manifestRows.Add("path`tsource`tbytes`tsha256`tsource_last_write_utc`tpromoted_utc")

foreach ($shot in $shots) {
    $sourcePath = Join-Path $source $shot.Source
    $targetPath = Join-Path $output $shot.Target

    Assert-ImageSize -Path $sourcePath -Width 1920 -Height 1080
    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    Assert-ImageSize -Path $targetPath -Width 1920 -Height 1080

    $item = Get-Item -LiteralPath $targetPath
    $hash = Get-FileHash -LiteralPath $targetPath -Algorithm SHA256
    $sourceItem = Get-Item -LiteralPath $sourcePath
    $sourceUtc = $sourceItem.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $manifestRows.Add(("{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f $shot.Target, $shot.Source, $item.Length, $hash.Hash, $sourceUtc, $promotedUtc))
}

Set-Content -LiteralPath (Join-Path $output "SCREENSHOT_MANIFEST.tsv") -Value $manifestRows -Encoding UTF8
Write-Host "Promoted $($shots.Count) Steam screenshots: $output"
