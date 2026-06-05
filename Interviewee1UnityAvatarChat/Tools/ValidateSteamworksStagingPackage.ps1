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
        throw "Missing Steamworks staging package item: $RelativePath"
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

Assert-Path "README_STEAMWORKS_STAGING.txt"
Assert-Path "STEAMWORKS_STAGING_MANIFEST.tsv"
Assert-Path "content\START_HERE.txt"
Assert-Path "content\Interviewee1UnityAvatarChat\BUILD_INFO.json"
Assert-Path "content\Interviewee1UnityAvatarChat\BUILD_INFO.txt"
Assert-Path "content\Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat"
Assert-Path "content\Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1"
Assert-Path "content\Interviewee1UnityAvatarChat\Build\Interviewee1UnityAvatarChat.exe"
Assert-Path "content\Interviewee1CloneAI\server.js"
Assert-Path "content\Interviewee1CloneAI\data\persona.json"
Assert-Path "content\NodeRuntime\node.exe"
Assert-Path "content\NodeRuntime\LICENSE"
Assert-Path "scripts\app_build_windows.vdf"
Assert-Path "scripts\depot_build_windows.vdf"
Assert-Path "docs\STEAMWORKS_UPLOAD_PLAN.md"
Assert-Path "docs\STEAM_ADMIN_CHECKLIST.md"
Assert-Path "docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md"
Assert-Path "docs\STEAM_LEGAL_READINESS_QA.md"
Assert-Path "docs\COMMERCIAL_UI_COPY_QA.md"
Assert-Path "docs\GENERATED_MEMORY_POLICY_QA.md"
Assert-Path "docs\COMMERCIAL_LAUNCH_DECISION.md"
Assert-Path "docs\COMMERCIAL_LAUNCH_GATE.md"
Assert-Path "docs\EXTERNAL_ISSUE_REGISTER_QA.md"
Assert-Path "output"

Assert-TextContains "content\START_HERE.txt" @(
    "설정에서 로컬만을 켜면 텍스트 질문은 서버로 보내지지 않습니다.",
    "FeedbackNotes",
    "마이크 전사는 OPENAI_API_KEY가 서버 실행 환경에 있을 때만 동작하며, 로컬만을 켜면 꺼집니다."
)

$nodeVersion = (& (Join-Path $rootPath "content\NodeRuntime\node.exe") --version 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $nodeVersion -notmatch '^v(\d+)') {
    throw "Staged NodeRuntime did not report a valid version."
}
if ([int]$Matches[1] -lt 20) {
    throw "Staged NodeRuntime must be Node.js 20 or newer, found $nodeVersion"
}

$buildInfo = Get-Content -LiteralPath (Join-Path $rootPath "content\Interviewee1UnityAvatarChat\BUILD_INFO.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) {
    throw "Staged build metadata is missing buildId."
}
if ([string]$buildInfo.nodeRuntimeVersion -ne $nodeVersion) {
    throw "Staged build metadata NodeRuntime version '$($buildInfo.nodeRuntimeVersion)' does not match staged runtime '$nodeVersion'."
}

$appBuild = Get-Content -LiteralPath (Join-Path $rootPath "scripts\app_build_windows.vdf") -Raw -Encoding UTF8
$depotBuild = Get-Content -LiteralPath (Join-Path $rootPath "scripts\depot_build_windows.vdf") -Raw -Encoding UTF8

foreach ($required in @('"AppBuild"', '"AppID"', '"BuildOutput"', '"ContentRoot"', '"Depots"')) {
    if ($appBuild -notmatch [regex]::Escape($required)) {
        throw "app_build_windows.vdf is missing $required"
    }
}
foreach ($required in @('"DepotBuild"', '"DepotID"', '"FileMapping"', '"LocalPath"', '"DepotPath"', '"Recursive"')) {
    if ($depotBuild -notmatch [regex]::Escape($required)) {
        throw "depot_build_windows.vdf is missing $required"
    }
}
if ($appBuild -notmatch '\.\.\\content' -or $depotBuild -notmatch '\.\.\\content') {
    throw "Steamworks VDF scripts must use ..\content as ContentRoot."
}

Assert-NoFiles "(^|\\)(release-smoke)(\\|$)|(^|\\)smoke-[^\\]+\.png$" "Steamworks staging package contains smoke captures:"
Assert-NoFiles "\.log$|\.pid$|(^|\\)\.server\.pid$" "Steamworks staging package contains logs or pid files:"

$secretMatches = Get-TextPackageFiles |
    Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue

if ($secretMatches) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { Get-RelativePath -FullName $_.Path }) -join ", "
    throw "Steamworks staging package may contain an API key: $sample"
}

$manifest = Get-Content -LiteralPath (Join-Path $rootPath "STEAMWORKS_STAGING_MANIFEST.tsv")
if ($manifest.Count -lt 20 -or $manifest[0] -ne "path`tbytes`tsha256") {
    throw "Steamworks staging manifest is missing or malformed."
}

Write-Host "Steamworks staging package validation passed: $root"
