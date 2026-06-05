param(
    [string]$BuildId = "",
    [string]$OutputRoot
)

$ErrorActionPreference = "Stop"

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required path: $Path"
    }
}

function Get-FirstMatch {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Default = ""
    )

    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $match = [regex]::Match($text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($match.Success -and $match.Groups.Count -gt 1) {
        return $match.Groups[1].Value.Trim()
    }

    return $Default
}

function Get-FileEvidence {
    param([string]$Path)

    Assert-Path $Path
    $item = Get-Item -LiteralPath $Path
    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
    [pscustomobject]@{
        path = $item.Name
        bytes = $item.Length
        sha256 = $hash.Hash
    }
}

function Get-DirectoryEvidence {
    param(
        [string]$Path,
        [string]$EvidencePath
    )

    Assert-Path $Path
    $rootFull = [System.IO.Path]::GetFullPath($Path)
    $files = @(Get-ChildItem -LiteralPath $Path -File -Recurse | Sort-Object FullName)
    $rows = New-Object System.Collections.Generic.List[string]
    [int64]$bytes = 0

    foreach ($file in $files) {
        $fileFull = [System.IO.Path]::GetFullPath($file.FullName)
        $relative = $fileFull.Substring($rootFull.Length).TrimStart('\', '/')
        $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
        $bytes += $file.Length
        $rows.Add(("{0}`t{1}`t{2}" -f $relative, $file.Length, $hash.Hash)) | Out-Null
    }

    $text = $rows -join "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))
    }
    finally {
        $sha.Dispose()
    }

    [pscustomobject]@{
        path = $EvidencePath
        files = $files.Count
        bytes = $bytes
        sha256 = ([System.BitConverter]::ToString($digest) -replace "-", "")
    }
}

function Resolve-NodeExecutable {
    param([string]$BuildRoot)

    $candidates = @(
        (Join-Path $BuildRoot "ThirdParty\NodeRuntime\node.exe"),
        (Join-Path $projectRoot "NodeRuntime\node.exe"),
        (Join-Path $projectRoot "..\NodeRuntime\node.exe")
    )

    foreach ($candidate in $candidates) {
        $resolved = Resolve-Path $candidate -ErrorAction SilentlyContinue
        if ($resolved) {
            return $resolved.Path
        }
    }

    $systemNode = Get-Command node.exe, node -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($systemNode) {
        return $systemNode.Source
    }

    throw "Missing required Node runtime. Run Tools\PrepareNodeRuntime.ps1 or install Node.js on PATH."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = $buildRoot
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$projectSettings = Join-Path $projectRoot "ProjectSettings\ProjectSettings.asset"
$projectVersion = Join-Path $projectRoot "ProjectSettings\ProjectVersion.txt"
$appExe = Join-Path $buildRoot "Interviewee1UnityAvatarChat.exe"
$appData = Join-Path $buildRoot "Interviewee1UnityAvatarChat_Data"
$nodeExe = Resolve-NodeExecutable -BuildRoot $buildRoot
$serverJs = Join-Path $serverRoot "server.js"
$personaJson = Join-Path $serverRoot "data\persona.json"

Assert-Path $projectSettings
Assert-Path $projectVersion
Assert-Path $appExe
Assert-Path $appData
Assert-Path $serverJs
Assert-Path $personaJson

$productName = Get-FirstMatch -Path $projectSettings -Pattern '^\s*productName:\s*(.+)$' -Default "겉!=속"
$bundleVersion = Get-FirstMatch -Path $projectSettings -Pattern '^\s*bundleVersion:\s*(.+)$' -Default "1.0"
$unityVersion = Get-FirstMatch -Path $projectVersion -Pattern '^m_EditorVersion:\s*(.+)$' -Default ""
$nodeVersion = (& $nodeExe --version 2>$null).Trim()
$playerEvidence = Get-FileEvidence -Path $appExe
$playerDataEvidence = Get-DirectoryEvidence -Path $appData -EvidencePath "Interviewee1UnityAvatarChat_Data"
$nodeEvidence = Get-FileEvidence -Path $nodeExe
$serverEvidence = Get-FileEvidence -Path $serverJs
$personaEvidence = Get-FileEvidence -Path $personaJson

if ([string]::IsNullOrWhiteSpace($BuildId)) {
    $BuildId = "geot-not-equal-sok-$($bundleVersion)-$($playerDataEvidence.sha256.Substring(0, 8).ToLowerInvariant())-$($serverEvidence.sha256.Substring(0, 8).ToLowerInvariant())-$($personaEvidence.sha256.Substring(0, 8).ToLowerInvariant())"
}

$metadata = [ordered]@{
    productName = $productName
    displayName = "겉!=속"
    version = $bundleVersion
    buildId = $BuildId
    generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss K")
    unityEditorVersion = $unityVersion
    nodeRuntimeVersion = $nodeVersion
    platform = "Windows x64"
    evidence = [ordered]@{
        player = $playerEvidence
        playerData = $playerDataEvidence
        nodeRuntime = $nodeEvidence
        server = $serverEvidence
        persona = $personaEvidence
    }
}

$jsonPath = Join-Path $OutputRoot "BUILD_INFO.json"
$txtPath = Join-Path $OutputRoot "BUILD_INFO.txt"

$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "겉!=속 - Build Info",
    "",
    "Product: $productName",
    "Version: $bundleVersion",
    "Build ID: $BuildId",
    "Generated: $($metadata.generatedAt)",
    "Unity: $unityVersion",
    "NodeRuntime: $nodeVersion",
    "Platform: Windows x64",
    "",
    "Hashes:",
    "- Player: $($metadata.evidence.player.sha256)",
    "- PlayerData: $($metadata.evidence.playerData.sha256)",
    "- NodeRuntime: $($metadata.evidence.nodeRuntime.sha256)",
    "- Server: $($metadata.evidence.server.sha256)",
    "- Persona: $($metadata.evidence.persona.sha256)"
)

Set-Content -LiteralPath $txtPath -Value $lines -Encoding UTF8
Write-Host "Build metadata written: $jsonPath"

