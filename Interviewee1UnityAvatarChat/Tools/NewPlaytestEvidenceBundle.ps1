param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [string]$EvidenceRoot,
    [string]$FeedbackRoot,
    [string]$FeedbackPath,
    [string]$FeedbackManifestPath,
    [string]$ObservationFormPath,
    [string]$SupportBundleRoot,
    [string]$ReleasePackageRoot,
    [string]$BuildInfoPath,
    [switch]$AllowIncomplete,
    [switch]$IncludeUnityLog
)

$ErrorActionPreference = "Stop"

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

function Find-FeedbackRoots {
    param([string]$ProjectRoot)

    $roots = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($FeedbackRoot)) {
        $roots.Add($FeedbackRoot) | Out-Null
    }

    $roots.Add((Join-Path $ProjectRoot "Build\release-smoke\playtest-feedback-files")) | Out-Null
    $roots.Add((Join-Path $ProjectRoot "EvidenceDrop\Playtest")) | Out-Null
    $roots.Add((Join-Path $ProjectRoot "Build\ReleaseEvidence\Playtest")) | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $localLow = Join-Path $env:USERPROFILE "AppData\LocalLow"
        $roots.Add((Join-Path $localLow "SNU Understanding Exceptional Children Group 3\Interviewee1 Unity Avatar Chat\FeedbackNotes")) | Out-Null
        $roots.Add((Join-Path $localLow "DefaultCompany\Interviewee1UnityAvatarChat\FeedbackNotes")) | Out-Null
        $roots.Add((Join-Path $localLow "DefaultCompany\Interviewee1 Unity Avatar Chat\FeedbackNotes")) | Out-Null
    }

    return @($roots.ToArray() | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Get-FeedbackPairFromJson {
    param([System.IO.FileInfo]$JsonFile)

    try {
        $json = Get-Content -LiteralPath $JsonFile.FullName -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }

    $textPath = ""
    foreach ($property in @("feedbackTextPath", "textPath", "txtPath", "feedbackPath")) {
        if ($json.PSObject.Properties.Name -contains $property) {
            $value = [string]$json.$property
            if (-not [string]::IsNullOrWhiteSpace($value) -and (Test-Path -LiteralPath $value)) {
                $textPath = $value
                break
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($textPath)) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($JsonFile.Name)
        $sameBase = Join-Path $JsonFile.DirectoryName "$baseName.txt"
        if (Test-Path -LiteralPath $sameBase) {
            $textPath = $sameBase
        }
    }

    if ([string]::IsNullOrWhiteSpace($textPath)) {
        $nearby = Get-ChildItem -LiteralPath $JsonFile.DirectoryName -File -Filter "*.txt" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "feedback|participant|playtest" } |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        if ($nearby) {
            $textPath = $nearby.FullName
        }
    }

    if ([string]::IsNullOrWhiteSpace($textPath)) {
        return $null
    }

    return [pscustomobject]@{
        TextPath = $textPath
        ManifestPath = $JsonFile.FullName
        LastWriteTimeUtc = $JsonFile.LastWriteTimeUtc
    }
}

function Find-LatestFeedbackPair {
    param([string]$ProjectRoot)

    $pairs = New-Object System.Collections.Generic.List[object]
    foreach ($root in (Find-FeedbackRoots -ProjectRoot $ProjectRoot)) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $jsonFiles = Get-ChildItem -LiteralPath $root -File -Recurse -Filter "*.json" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "feedback|participant|playtest" -or $_.FullName -match "FeedbackNotes|playtest-feedback" }

        foreach ($jsonFile in $jsonFiles) {
            $pair = Get-FeedbackPairFromJson -JsonFile $jsonFile
            if ($pair) {
                $pairs.Add($pair) | Out-Null
            }
        }
    }

    return $pairs.ToArray() | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
}

function Resolve-BuildInfoPath {
    param([string]$ProjectRoot)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($BuildInfoPath)) {
        $candidates += $BuildInfoPath
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

function New-SupportBundle {
    param(
        [string]$ProjectRoot,
        [string]$OutputRoot
    )

    $script = ""
    if (-not [string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
        $candidate = Join-Path $ReleasePackageRoot "Interviewee1UnityAvatarChat\CollectSupportBundle.ps1"
        if (Test-Path -LiteralPath $candidate) {
            $script = $candidate
        }
    }
    if ([string]::IsNullOrWhiteSpace($script)) {
        $candidate = Join-Path $ProjectRoot "Tools\CollectSupportBundle.ps1"
        if (Test-Path -LiteralPath $candidate) {
            $script = $candidate
        }
    }
    if ([string]::IsNullOrWhiteSpace($script)) {
        $candidate = Join-Path $ProjectRoot "Game\Interviewee1UnityAvatarChat\CollectSupportBundle.ps1"
        if (Test-Path -LiteralPath $candidate) {
            $script = $candidate
        }
    }
    if ([string]::IsNullOrWhiteSpace($script)) {
        throw "CollectSupportBundle.ps1 was not found."
    }

    New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    $powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
    $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $script, "-OutputRoot", $OutputRoot)
    if ($IncludeUnityLog) {
        $args += "-IncludeUnityLog"
    }
    $output = & $powershell @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output -join " ")
    }

    $createdLine = $output | Where-Object { [string]$_ -match "Support bundle created:" } | Select-Object -Last 1
    if ($createdLine -and ([string]$createdLine) -match "Support bundle created:\s*(.+)$") {
        $path = $Matches[1].Trim()
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }

    $latest = Get-ChildItem -LiteralPath $OutputRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^SupportBundle-" } |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if ($latest) {
        return $latest.FullName
    }

    throw "Support bundle was not created in $OutputRoot."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectRootPath = $projectRoot.Path

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $projectRootPath "EvidenceDrop\Playtest"
}

if ([string]::IsNullOrWhiteSpace($FeedbackPath) -or [string]::IsNullOrWhiteSpace($FeedbackManifestPath)) {
    $pair = Find-LatestFeedbackPair -ProjectRoot $projectRootPath
    if (-not $pair) {
        throw "No feedback txt/json pair found. Pass -FeedbackPath and -FeedbackManifestPath, or run the app feedback save first."
    }
    if ([string]::IsNullOrWhiteSpace($FeedbackPath)) {
        $FeedbackPath = $pair.TextPath
    }
    if ([string]::IsNullOrWhiteSpace($FeedbackManifestPath)) {
        $FeedbackManifestPath = $pair.ManifestPath
    }
}

if (-not (Test-Path -LiteralPath $FeedbackPath)) {
    throw "Missing feedback text file: $FeedbackPath"
}
if (-not (Test-Path -LiteralPath $FeedbackManifestPath)) {
    throw "Missing feedback manifest file: $FeedbackManifestPath"
}

if ([string]::IsNullOrWhiteSpace($SupportBundleRoot)) {
    $supportOutputRoot = Join-Path ([System.IO.Path]::GetTempPath()) "GeotNotEqualSokSupportBundles"
    $SupportBundleRoot = New-SupportBundle -ProjectRoot $projectRootPath -OutputRoot $supportOutputRoot
}
elseif (-not (Test-Path -LiteralPath $SupportBundleRoot)) {
    throw "Missing support bundle: $SupportBundleRoot"
}

$collectScript = Join-Path $projectRootPath "Tools\CollectExternalEvidenceSession.ps1"
if (-not (Test-Path -LiteralPath $collectScript)) {
    throw "Missing collection script: $collectScript"
}

$resolvedBuildInfoPath = Resolve-BuildInfoPath -ProjectRoot $projectRootPath
$powershellPath = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
$collectArgs = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $collectScript,
    "-SessionId", $SessionId,
    "-EvidenceRoot", $EvidenceRoot,
    "-FeedbackPath", $FeedbackPath,
    "-FeedbackManifestPath", $FeedbackManifestPath,
    "-SupportBundleRoot", $SupportBundleRoot
)
if (-not [string]::IsNullOrWhiteSpace($ObservationFormPath)) {
    $collectArgs += @("-ObservationFormPath", $ObservationFormPath)
}
if (-not [string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
    $collectArgs += @("-ReleasePackageRoot", $ReleasePackageRoot)
}
if (-not [string]::IsNullOrWhiteSpace($resolvedBuildInfoPath)) {
    $collectArgs += @("-BuildInfoPath", $resolvedBuildInfoPath)
}
if ($AllowIncomplete) {
    $collectArgs += "-AllowIncomplete"
}

$collectOutput = & $powershellPath @collectArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    throw ($collectOutput -join " ")
}

$safeSessionId = ($SessionId -replace '[^\w.-]+', '-').Trim('-')
$sessionRoot = Join-Path $EvidenceRoot $safeSessionId

$summary = [ordered]@{
    schemaVersion = "1"
    sessionId = $safeSessionId
    createdAt = (Get-Date).ToString("o")
    sessionRoot = $sessionRoot
    feedbackPath = $FeedbackPath
    feedbackManifestPath = $FeedbackManifestPath
    supportBundleRoot = $SupportBundleRoot
    observationFormPath = $ObservationFormPath
    allowIncomplete = [bool]$AllowIncomplete
}
$summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $sessionRoot "PLAYTEST_EVIDENCE_BUNDLE.json") -Encoding UTF8

Write-Host "Playtest evidence bundle prepared: $sessionRoot"
Write-Host "Feedback: $FeedbackPath"
Write-Host "Feedback manifest: $FeedbackManifestPath"
Write-Host "Support bundle: $SupportBundleRoot"

