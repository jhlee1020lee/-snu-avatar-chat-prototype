param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [string]$EvidenceRoot,
    [string]$FeedbackPath,
    [string]$FeedbackManifestPath,
    [string]$ObservationFormPath,
    [string]$SupportBundleRoot,
    [string]$ReleasePackageRoot,
    [string]$BuildInfoPath,
    [switch]$AllowIncomplete
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing path: $Path"
    }
}

function Copy-ItemSafe {
    param(
        [string]$Source,
        [string]$DestinationRoot
    )

    Assert-Path -Path $Source
    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    $item = Get-Item -LiteralPath $Source
    if ($item.PSIsContainer) {
        $target = Join-Path $DestinationRoot $item.Name
        Copy-Item -LiteralPath $Source -Destination $target -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $DestinationRoot -Force
    }
}

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

function Find-BuildInfoPath {
    param(
        [string]$ProjectRoot,
        [string]$ReleasePackageRoot
    )

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($BuildInfoPath)) {
        $candidates += $BuildInfoPath
    }
    if (-not [string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
        $candidates += (Join-Path $ReleasePackageRoot "Interviewee1UnityAvatarChat\BUILD_INFO.json")
        $candidates += (Join-Path $ReleasePackageRoot "Game\Interviewee1UnityAvatarChat\BUILD_INFO.json")
    }
    $candidates += (Join-Path $ProjectRoot "Build\BUILD_INFO.json")
    $candidates += (Join-Path $ProjectRoot "Game\Interviewee1UnityAvatarChat\BUILD_INFO.json")
    $candidates += (Join-Path $ProjectRoot "BUILD_INFO.json")

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return ""
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

function Assert-NoApiKeyPattern {
    param([string]$Path)

    $matches = Get-ChildItem -LiteralPath $Path -File -Recurse |
        Where-Object { Test-TextLikeFile -File $_ } |
        Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue

    if ($matches) {
        $sample = ($matches | Select-Object -First 4 | ForEach-Object { $_.Path }) -join ", "
        throw "Evidence session contains an API key pattern: $sample"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$evidenceDropRoot = Join-Path $projectRoot "EvidenceDrop"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath $evidenceDropRoot) {
        $EvidenceRoot = Join-Path $evidenceDropRoot "Playtest"
    }
    else {
        $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence\Playtest"
    }
}

if ([string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
    $defaultReleasePackage = Join-Path $buildRoot "ReleasePackages\GeotNotEqualSok-Windows-QA"
    if (Test-Path -LiteralPath $defaultReleasePackage) {
        $ReleasePackageRoot = $defaultReleasePackage
    }
}

$safeSessionId = ($SessionId -replace '[^\w.-]+', '-').Trim('-')
if ([string]::IsNullOrWhiteSpace($safeSessionId)) {
    throw "SessionId must contain at least one safe filename character."
}

$sessionRoot = Join-Path $EvidenceRoot $safeSessionId
New-Item -ItemType Directory -Force -Path $sessionRoot | Out-Null

$feedbackRoot = Join-Path $sessionRoot "Feedback"
$supportRoot = Join-Path $sessionRoot "SupportBundle"
$formsRoot = Join-Path $sessionRoot "Forms"
New-Item -ItemType Directory -Force -Path $feedbackRoot, $supportRoot, $formsRoot | Out-Null

if (-not [string]::IsNullOrWhiteSpace($FeedbackPath)) {
    Copy-ItemSafe -Source $FeedbackPath -DestinationRoot $feedbackRoot
}
if (-not [string]::IsNullOrWhiteSpace($FeedbackManifestPath)) {
    Copy-ItemSafe -Source $FeedbackManifestPath -DestinationRoot $feedbackRoot
}
if (-not [string]::IsNullOrWhiteSpace($ObservationFormPath)) {
    Copy-ItemSafe -Source $ObservationFormPath -DestinationRoot $formsRoot
}

if (-not [string]::IsNullOrWhiteSpace($SupportBundleRoot)) {
    Copy-ItemSafe -Source $SupportBundleRoot -DestinationRoot $supportRoot
}
else {
    $collectScript = ""
    if (-not [string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
        $candidate = Join-Path $ReleasePackageRoot "Interviewee1UnityAvatarChat\CollectSupportBundle.ps1"
        if (Test-Path -LiteralPath $candidate) {
            $collectScript = $candidate
        }
    }
    if ([string]::IsNullOrWhiteSpace($collectScript)) {
        $candidate = Join-Path $projectRoot "Tools\CollectSupportBundle.ps1"
        if (Test-Path -LiteralPath $candidate) {
            $collectScript = $candidate
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($collectScript)) {
        $powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
        $output = & $powershell -NoProfile -ExecutionPolicy Bypass -File $collectScript -OutputRoot $supportRoot 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($output -join " ")
        }
    }
}

$manifest = [ordered]@{
    schemaVersion = "1"
    sessionId = $safeSessionId
    createdAt = (Get-Date).ToString("o")
    evidenceRoot = $sessionRoot
    feedbackProvided = -not [string]::IsNullOrWhiteSpace($FeedbackPath)
    feedbackManifestProvided = -not [string]::IsNullOrWhiteSpace($FeedbackManifestPath)
    observationFormProvided = -not [string]::IsNullOrWhiteSpace($ObservationFormPath)
    supportBundleProvidedOrGenerated = [bool](Get-ChildItem -LiteralPath $supportRoot -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
    note = "Keep filled observation forms, original feedback files, support bundle, screenshots, and recordings in this session folder."
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $sessionRoot "SESSION_MANIFEST.json") -Encoding UTF8

$readme = @"
External evidence session: $safeSessionId

Required before this session can count toward the final release gate:
- filled observation form
- original participant feedback txt/json from the app
- support bundle folder or zip
- screenshots or recordings for any P0/P1 issue

Do not store API keys, Steam credentials, account passwords, or private account notes here.
"@
Set-Content -LiteralPath (Join-Path $sessionRoot "README_SESSION.txt") -Value $readme -Encoding UTF8

Assert-NoApiKeyPattern -Path $sessionRoot

$sessionQaScript = Join-Path $projectRoot "Tools\ValidateExternalEvidenceSession.ps1"
if (Test-Path -LiteralPath $sessionQaScript) {
    $resolvedBuildInfoPath = Find-BuildInfoPath -ProjectRoot $projectRoot -ReleasePackageRoot $ReleasePackageRoot
    $sessionQaArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $sessionQaScript, "-SessionRoot", $sessionRoot)
    if (-not [string]::IsNullOrWhiteSpace($resolvedBuildInfoPath)) {
        $sessionQaArgs += @("-BuildInfoPath", $resolvedBuildInfoPath)
    }
    if (-not $AllowIncomplete) {
        $sessionQaArgs += "-RequireComplete"
    }

    $powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
    $qaOutput = & $powershell @sessionQaArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($qaOutput -join " ")
    }
}

Write-Host "External evidence session prepared: $sessionRoot"


