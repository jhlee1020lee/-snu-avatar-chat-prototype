param(
    [Parameter(Mandatory = $true)]
    [string]$PackageRoot
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

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
        throw "Missing release package item: $RelativePath"
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

function Assert-TextContains {
    param(
        [string]$RelativePath,
        [string[]]$RequiredText
    )

    $path = Join-Path $rootPath $RelativePath
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($text in $RequiredText) {
        if ($content -notmatch [regex]::Escape($text)) {
            throw "$RelativePath is missing required text: $text"
        }
    }
}

Assert-Path "START_HERE.txt"
Assert-Path "RELEASE_MANIFEST.tsv"
Assert-Path "Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat"
Assert-Path "Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1"
Assert-Path "Interviewee1UnityAvatarChat\CollectSupportBundle.ps1"
Assert-Path "Interviewee1UnityAvatarChat\README.md"
Assert-Path "Interviewee1UnityAvatarChat\BUILD_INFO.json"
Assert-Path "Interviewee1UnityAvatarChat\BUILD_INFO.txt"
Assert-Path "Interviewee1UnityAvatarChat\Docs\RELEASE_CHECKLIST.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\PLAYTEST_PROTOCOL.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\PLAYTEST_MODERATOR_SCRIPT.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\PLAYTEST_PARTICIPANT_BRIEF.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\ACCESSIBILITY_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\ACCESSIBILITY_AUTOMATION_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\PRIVACY_NOTICE_DRAFT.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\STEAM_LEGAL_READINESS_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_ISSUE_REGISTER_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\TROUBLESHOOTING.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\SUPPORT_HANDOFF.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\MODEL_CONFIG_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\GENERATED_MEMORY_POLICY_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_UI_COPY_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_QUALITY_RUBRIC.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_QUALITY_REVIEW_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\RELEASE_READINESS_REPORT.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_LAUNCH_DECISION.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_LAUNCH_GATE.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\INTERNAL_QUALITY_REVIEW.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\INTERNAL_QUALITY_SCORECARD.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\INTERNAL_COMMERCIAL_REVIEW.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\INTERNAL_COMMERCIAL_BACKLOG.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_SPRINT_PLAN.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_SPRINT_BOARD.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_BRIEFS.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_BRIEFS_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_TRACKER.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_TRACKER_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_ROSTER.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_ROSTER_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_PACKETS.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_PACKETS_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_OUTREACH_QUEUE.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_OUTREACH_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\EXTERNAL_EVIDENCE_IMPORT_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_PRICE_POSITIONING.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\STEAM_MARKET_COMPARISON.md"
Assert-Path "Interviewee1UnityAvatarChat\Docs\STEAM_MARKET_COMPARISON.tsv"
Assert-Path "Interviewee1UnityAvatarChat\Docs\STEAM_MARKET_COMPARISON_QA.md"
Assert-Path "Interviewee1UnityAvatarChat\Build\Interviewee1UnityAvatarChat.exe"
Assert-Path "Interviewee1UnityAvatarChat\Build\Interviewee1UnityAvatarChat_Data"
Assert-Path "Interviewee1UnityAvatarChat\Build\UnityPlayer.dll"
Assert-Path "Interviewee1UnityAvatarChat\Build\UnityCrashHandler64.exe"
Assert-Path "Interviewee1UnityAvatarChat\Build\MonoBleedingEdge"
Assert-Path "Interviewee1CloneAI\server.js"
Assert-Path "Interviewee1CloneAI\package.json"
Assert-Path "Interviewee1CloneAI\README.md"
Assert-Path "Interviewee1CloneAI\data\persona.json"
Assert-Path "NodeRuntime\node.exe"
Assert-Path "NodeRuntime\LICENSE"
Assert-Path "NodeRuntime\README.md"
Assert-Path "NodeRuntime\NODE_RUNTIME_NOTICE.txt"

Assert-TextContains "START_HERE.txt" @(
    "API",
    "FeedbackNotes",
    "OPENAI_API_KEY"
)

$nodeExe = Join-Path $rootPath "NodeRuntime\node.exe"
$nodeVersion = (& $nodeExe --version 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $nodeVersion -notmatch '^v(\d+)') {
    throw "Bundled NodeRuntime did not report a valid version."
}
if ([int]$Matches[1] -lt 20) {
    throw "Bundled NodeRuntime must be Node.js 20 or newer, found $nodeVersion"
}

$buildInfo = Get-Content -LiteralPath (Join-Path $rootPath "Interviewee1UnityAvatarChat\BUILD_INFO.json") -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) {
    throw "Build metadata is missing buildId."
}
if ([string]::IsNullOrWhiteSpace([string]$buildInfo.version)) {
    throw "Build metadata is missing version."
}
if ([string]$buildInfo.nodeRuntimeVersion -ne $nodeVersion) {
    throw "Build metadata NodeRuntime version '$($buildInfo.nodeRuntimeVersion)' does not match packaged runtime '$nodeVersion'."
}

Assert-NoFiles "(^|\\)(release-smoke)(\\|$)|(^|\\)smoke-[^\\]+\.png$" "Release package contains smoke captures:"
Assert-NoFiles "\.log$|\.pid$|(^|\\)\.server\.pid$" "Release package contains logs or pid files:"

$secretMatches = Get-TextPackageFiles |
    Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue

if ($secretMatches) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { Get-RelativePath -FullName $_.Path }) -join ", "
    throw "Release package may contain an API key: $sample"
}

$manifest = Get-Content -LiteralPath (Join-Path $rootPath "RELEASE_MANIFEST.tsv")
if ($manifest.Count -lt 10 -or $manifest[0] -ne "path`tbytes`tsha256") {
    throw "Release manifest is missing or malformed."
}

Write-Host "Release package validation passed: $root"
