param(
    [Parameter(Mandatory = $true)]
    [string]$PackageRoot
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"
Add-Type -AssemblyName System.Drawing

$root = Resolve-Path $PackageRoot
$rootPath = $root.Path

function ConvertTo-LongPath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith("\\?\")) {
        return $full
    }
    if ($full.StartsWith("\\")) {
        return "\\?\UNC\" + $full.Substring(2)
    }
    return "\\?\" + $full
}

$rootLong = ConvertTo-LongPath -Path $rootPath

function Get-RelativePath {
    param([string]$FullName)

    if ($FullName.StartsWith($rootLong, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($rootLong.Length + 1)
    }
    if ($FullName.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($rootPath.Length + 1)
    }
    return $FullName
}

function Get-PackageFiles {
    @(Get-ChildItem -LiteralPath $rootLong -File -Recurse -ErrorAction Stop)
}

function Test-TextLikeFile {
    param([System.IO.FileInfo]$File)

    $textExtensions = @(
        ".bat", ".cmd", ".config", ".csv", ".css", ".htm", ".html", ".ini",
        ".js", ".json", ".log", ".manifest", ".md", ".ps1", ".psm1", ".srt",
        ".tsv", ".txt", ".vdf", ".vtt", ".xml", ".yaml", ".yml"
    )
    $textNames = @("LICENSE", "NOTICE", "README")
    $extension = $File.Extension.ToLowerInvariant()
    if ($textExtensions -contains $extension) {
        return $true
    }

    return $textNames -contains $File.Name.ToUpperInvariant()
}

function Get-TextPackageFiles {
    Get-PackageFiles | Where-Object { Test-TextLikeFile -File $_ }
}

function Assert-Path {
    param([string]$RelativePath)

    $path = Join-Path $rootPath $RelativePath
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
        throw "Missing Steam submission package item: $RelativePath"
    }
}

function Assert-ImageSize {
    param(
        [string]$RelativePath,
        [int]$Width,
        [int]$Height
    )

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne $Width -or $image.Height -ne $Height) {
            throw "Invalid dimensions for ${RelativePath}: $($image.Width)x$($image.Height), expected ${Width}x${Height}"
        }
    } finally {
        $image.Dispose()
    }
}

function Assert-NoFiles {
    param(
        [string]$Pattern,
        [string]$Message
    )

    $matches = Get-PackageFiles |
        Where-Object { $_.Name -match $Pattern -or (Get-RelativePath -FullName $_.FullName) -match $Pattern }

    if ($matches) {
        $sample = ($matches | Select-Object -First 8 | ForEach-Object { Get-RelativePath -FullName $_.FullName }) -join ", "
        throw "$Message $sample"
    }
}

function Assert-MinFile {
    param(
        [string]$RelativePath,
        [int64]$MinBytes
    )

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $item = Get-Item -LiteralPath (ConvertTo-LongPath -Path $path)
    if ($item.Length -lt $MinBytes) {
        throw "File is too small: $RelativePath ($($item.Length) bytes)"
    }
}

function Assert-TsvHasNoFailures {
    param(
        [string]$RelativePath,
        [string]$StatusColumn = "status"
    )

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $path)
    if ($rows.Count -eq 0) {
        throw "Report has no rows: $RelativePath"
    }
    $failures = @($rows | Where-Object { $_.$StatusColumn -eq "실패" -or $_.$StatusColumn -eq "fail" })
    if ($failures.Count -gt 0) {
        throw "Report has failed rows: $RelativePath"
    }
}

function Assert-Provenance {
    param([string]$RelativePath)

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $provenance = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$provenance.buildId)) {
        throw "Package provenance is missing buildId: $RelativePath"
    }
    if ([string]$provenance.packageType -ne "SteamSubmission") {
        throw "Package provenance type mismatch: $($provenance.packageType)"
    }
}

Assert-Path "README_STEAM_SUBMISSION.txt"
Assert-Path "STEAM_SUBMISSION_MANIFEST.tsv"
Assert-Provenance -RelativePath "PACKAGE_PROVENANCE.json"
Assert-Path "Marketing\STORE_PAGE_DRAFT.md"
Assert-Path "Marketing\STORE_PAGE_INTERNAL_NOTES.md"
Assert-TsvHasNoFailures -RelativePath "Marketing\StoreCopy\STORE_COPY_QA_REPORT.tsv"
Assert-Path "Marketing\SCREENSHOT_PLAN.md"
Assert-Path "Marketing\STEAM_ASSET_PLAN.md"
Assert-Path "Marketing\Steamworks\STEAMWORKS_UPLOAD_PLAN.md"
Assert-Path "Marketing\Steamworks\STEAM_ADMIN_CHECKLIST.md"
Assert-Path "Marketing\Steamworks\app_build_windows_template.vdf"
Assert-Path "Marketing\Steamworks\depot_build_windows_template.vdf"
Assert-Path "Marketing\ArtReview\ART_REVIEW_BRIEF.md"
Assert-Path "Marketing\ArtReview\ART_REVIEW_FORM.md"
Assert-Path "Marketing\VisualQuality\VISUAL_QUALITY_REPORT.tsv"
Assert-Path "Marketing\Trailer\TRAILER_PRODUCTION_PLAN.md"
Assert-Path "Marketing\Trailer\TRAILER_FINAL_REVIEW_FORM.md"
Assert-Path "Marketing\Trailer\TRAILER_SHOTLIST.tsv"
Assert-Path "Marketing\Trailer\TRAILER_BUILD_CAPTURE_SHOTLIST.tsv"
Assert-Path "Marketing\Trailer\TRAILER_CAPTIONS.srt"
Assert-Path "Marketing\Trailer\TRAILER_CAPTIONS.vtt"
Assert-MinFile -RelativePath "Marketing\Trailer\trailer_animatic_60s.mp4" -MinBytes 100000
Assert-MinFile -RelativePath "Marketing\Trailer\trailer_build_capture_60s.mp4" -MinBytes 100000
Assert-Path "Marketing\Trailer\Frames"
Assert-Path "Marketing\Trailer\BuildCaptureFrames"
Assert-Path "Docs\RELEASE_CHECKLIST.md"
Assert-Path "Docs\COMMERCIAL_RELEASE_REVIEW.md"
Assert-Path "Docs\EXTERNAL_EVIDENCE_REQUIREMENTS.md"
Assert-Path "Docs\EXTERNAL_EVIDENCE_AUDIT.md"
Assert-Path "Docs\PLAYTEST_EVIDENCE_SUMMARY.md"
Assert-Path "Docs\MODEL_CONFIG_QA.md"
Assert-Path "Docs\GENERATED_MEMORY_POLICY_QA.md"
Assert-Path "Docs\COMMERCIAL_UI_COPY_QA.md"
Assert-Path "Docs\COMMERCIAL_QUALITY_RUBRIC.md"
Assert-Path "Docs\COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv"
Assert-Path "Docs\COMMERCIAL_QUALITY_REVIEW_QA.md"
Assert-Path "Docs\PLAYTEST_PROTOCOL.md"
Assert-Path "Docs\PLAYTEST_MODERATOR_SCRIPT.md"
Assert-Path "Docs\PLAYTEST_PARTICIPANT_BRIEF.md"
Assert-Path "Docs\PLAYTEST_OBSERVATION_FORM.md"
Assert-Path "Docs\PLAYTEST_ISSUE_TRIAGE.md"
Assert-Path "Docs\ACCESSIBILITY_QA.md"
Assert-Path "Docs\ACCESSIBILITY_AUTOMATION_QA.md"
Assert-Path "Docs\ACCESSIBILITY_OBSERVATION_FORM.md"
Assert-Path "Docs\PRIVACY_NOTICE_DRAFT.md"
Assert-Path "Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md"
Assert-Path "Docs\STEAM_LEGAL_READINESS_QA.md"
Assert-Path "Docs\EXTERNAL_ISSUE_REGISTER_QA.md"
Assert-Path "Docs\EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv"
Assert-Path "Docs\TROUBLESHOOTING.md"
Assert-Path "Docs\SUPPORT_HANDOFF.md"
Assert-Path "Docs\RELEASE_READINESS_REPORT.md"
Assert-Path "Docs\COMMERCIAL_LAUNCH_DECISION.md"
Assert-Path "Docs\COMMERCIAL_LAUNCH_GATE.md"
Assert-Path "Docs\INTERNAL_QUALITY_REVIEW.md"
Assert-Path "Docs\INTERNAL_QUALITY_SCORECARD.tsv"
Assert-Path "Docs\INTERNAL_COMMERCIAL_REVIEW.md"
Assert-Path "Docs\INTERNAL_COMMERCIAL_BACKLOG.tsv"
Assert-Path "Docs\COMMERCIAL_SPRINT_PLAN.md"
Assert-Path "Docs\COMMERCIAL_SPRINT_BOARD.tsv"
Assert-Path "Docs\EXTERNAL_REVIEW_BRIEFS.md"
Assert-Path "Docs\EXTERNAL_REVIEW_BRIEFS_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEW_TRACKER.md"
Assert-Path "Docs\EXTERNAL_REVIEW_TRACKER_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_ROSTER.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_ROSTER_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_PACKETS.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_PACKETS_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEW_OUTREACH_QUEUE.md"
Assert-Path "Docs\EXTERNAL_REVIEW_OUTREACH_QA.md"
Assert-Path "Docs\EXTERNAL_EVIDENCE_IMPORT_QA.md"
Assert-Path "Docs\COMMERCIAL_PRICE_POSITIONING.md"
Assert-Path "Docs\COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv"
Assert-Path "Docs\STEAM_MARKET_COMPARISON.md"
Assert-Path "Docs\STEAM_MARKET_COMPARISON.tsv"
Assert-Path "Docs\STEAM_MARKET_COMPARISON_QA.md"
Assert-Path "Docs\IMPROVEMENT_PLAN.md"

$steamAssets = @(
    @{ Path = "Marketing\SteamAssets\header_capsule_920x430.png"; Width = 920; Height = 430 },
    @{ Path = "Marketing\SteamAssets\small_capsule_462x174.png"; Width = 462; Height = 174 },
    @{ Path = "Marketing\SteamAssets\main_capsule_1232x706.png"; Width = 1232; Height = 706 },
    @{ Path = "Marketing\SteamAssets\vertical_capsule_748x896.png"; Width = 748; Height = 896 },
    @{ Path = "Marketing\SteamAssets\page_background_1438x810.png"; Width = 1438; Height = 810 },
    @{ Path = "Marketing\SteamAssets\library_capsule_600x900.png"; Width = 600; Height = 900 },
    @{ Path = "Marketing\SteamAssets\library_hero_3840x1240.png"; Width = 3840; Height = 1240 },
    @{ Path = "Marketing\SteamAssets\library_header_920x430.png"; Width = 920; Height = 430 },
    @{ Path = "Marketing\SteamAssets\library_logo_1280x720.png"; Width = 1280; Height = 720 },
    @{ Path = "Marketing\SteamAssets\shortcut_icon_256x256.png"; Width = 256; Height = 256 },
    @{ Path = "Marketing\SteamAssets\professional_keyart_1920x1080.png"; Width = 1920; Height = 1080 },
    @{ Path = "Marketing\SteamAssets\source_keyart_1920x1080.png"; Width = 1920; Height = 1080 }
)

foreach ($asset in $steamAssets) {
    Assert-ImageSize -RelativePath $asset.Path -Width $asset.Width -Height $asset.Height
}

$screenshotsRoot = Join-Path $rootPath "Marketing\Screenshots"
Assert-Path "Marketing\Screenshots\SCREENSHOT_MANIFEST.tsv"
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
    $relative = "Marketing\Screenshots\$shotName"
    $shotPath = Join-Path $screenshotsRoot $shotName
    Assert-Path -RelativePath $relative
    $image = [System.Drawing.Image]::FromFile($shotPath)
    try {
        if ($image.Width -ne 1920 -or $image.Height -ne 1080) {
            throw "Marketing screenshot has unexpected dimensions: $relative $($image.Width)x$($image.Height)"
        }
    } finally {
        $image.Dispose()
    }
}

$screenshotManifest = Import-Csv -Delimiter "`t" -LiteralPath (Join-Path $screenshotsRoot "SCREENSHOT_MANIFEST.tsv")
if ($screenshotManifest.Count -ne $requiredScreenshots.Count) {
    throw "Screenshot manifest row count mismatch: $($screenshotManifest.Count), expected $($requiredScreenshots.Count)"
}

Assert-NoFiles "\.log$|\.pid$|(^|\\)\.server\.pid$" "Steam submission package contains logs or pid files:"

$secretMatches = Get-TextPackageFiles |
    Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue

if ($secretMatches) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { Get-RelativePath -FullName $_.Path }) -join ", "
    throw "Steam submission package may contain an API key: $sample"
}

$manifest = Get-Content -LiteralPath (Join-Path $rootPath "STEAM_SUBMISSION_MANIFEST.tsv")
if ($manifest.Count -lt 20 -or $manifest[0] -ne "path`tbytes`tsha256") {
    throw "Steam submission manifest is missing or malformed."
}

Write-Host "Steam submission package validation passed: $root"
