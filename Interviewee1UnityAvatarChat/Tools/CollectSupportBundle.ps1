param(
    [string]$OutputRoot,
    [switch]$IncludeUnityLog,
    [switch]$Zip
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

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

function Copy-IfPresent {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        return $true
    }

    return $false
}

function Get-BuildInfo {
    param([string]$AppRoot)

    $path = Join-Path $AppRoot "BUILD_INFO.json"
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Get-ServerConfigSummary {
    try {
        $config = Invoke-RestMethod -Uri "http://127.0.0.1:8765/api/config" -Method Get -TimeoutSec 2
        return [ordered]@{
            available = $true
            apiAvailable = [bool]$config.apiAvailable
            chatModel = [string]$config.chatModel
            error = ""
        }
    }
    catch {
        return [ordered]@{
            available = $false
            apiAvailable = $false
            chatModel = ""
            error = $_.Exception.Message
        }
    }
}

function Get-FileSummary {
    param(
        [string]$Label,
        [string]$RelativePath,
        [string]$AbsolutePath
    )

    $exists = Test-Path -LiteralPath $AbsolutePath
    $bytes = ""
    $sha256 = ""
    $kind = ""

    if ($exists) {
        $item = Get-Item -LiteralPath $AbsolutePath
        $kind = if ($item.PSIsContainer) { "directory" } else { "file" }
        if (-not $item.PSIsContainer) {
            $bytes = [string]$item.Length
            $sha256 = (Get-FileHash -LiteralPath $AbsolutePath -Algorithm SHA256).Hash
        }
    }

    [pscustomobject]@{
        label = $Label
        relativePath = $RelativePath
        exists = $exists
        kind = $kind
        bytes = $bytes
        sha256 = $sha256
    }
}

function Find-UnityPlayerLog {
    $localLow = if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        Join-Path $env:USERPROFILE "AppData\LocalLow"
    }
    else {
        ""
    }

    if ([string]::IsNullOrWhiteSpace($localLow)) {
        return $null
    }

    $candidates = @(
        (Join-Path $localLow "SNU Understanding Exceptional Children Group 3\Interviewee1 Unity Avatar Chat\Player.log"),
        (Join-Path $localLow "DefaultCompany\Interviewee1UnityAvatarChat\Player.log"),
        (Join-Path $localLow "DefaultCompany\Interviewee1 Unity Avatar Chat\Player.log")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Assert-NoApiKeyPattern {
    param([string]$Path)

    $matches = Get-ChildItem -LiteralPath $Path -File -Recurse |
        Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue

    if ($matches) {
        $sample = ($matches | Select-Object -First 4 | ForEach-Object { $_.Path }) -join ", "
        throw "Support bundle may contain an API key pattern: $sample"
    }
}

$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolsParent = Split-Path -Leaf $appRoot
if ($toolsParent -eq "Tools") {
    $appRoot = Split-Path -Parent $appRoot
}
$appRoot = (Resolve-Path $appRoot).Path

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $base = if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        Join-Path $env:LOCALAPPDATA "GeotNotEqualSok\SupportBundles"
    }
    else {
        Join-Path $appRoot "SupportBundles"
    }
    $OutputRoot = $base
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bundleRoot = Join-Path $OutputRoot "SupportBundle-$timestamp"
New-Item -ItemType Directory -Force -Path $bundleRoot | Out-Null

$buildInfo = Get-BuildInfo -AppRoot $appRoot
$buildId = if ($buildInfo -and -not [string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) { [string]$buildInfo.buildId } else { "" }
$productName = if ($buildInfo -and -not [string]::IsNullOrWhiteSpace([string]$buildInfo.productName)) { [string]$buildInfo.productName } else { "Interviewee1 Unity Avatar Chat" }
$version = if ($buildInfo -and -not [string]::IsNullOrWhiteSpace([string]$buildInfo.version)) { [string]$buildInfo.version } else { "" }

Copy-IfPresent -Source (Join-Path $appRoot "BUILD_INFO.json") -Destination (Join-Path $bundleRoot "BUILD_INFO.json") | Out-Null
Copy-IfPresent -Source (Join-Path $appRoot "BUILD_INFO.txt") -Destination (Join-Path $bundleRoot "BUILD_INFO.txt") | Out-Null

$launcher = Join-Path $appRoot "LaunchAvatarChat.ps1"
$launcherOutputPath = Join-Path $bundleRoot "launcher_check.txt"
if (Test-Path -LiteralPath $launcher) {
    $powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
    $launcherOutput = & $powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -CheckOnly -NoStartServer 2>&1
    $launcherExitCode = $LASTEXITCODE
    Set-Content -LiteralPath $launcherOutputPath -Value @("exitCode: $launcherExitCode") -Encoding UTF8
    Add-Content -LiteralPath $launcherOutputPath -Value ($launcherOutput | ForEach-Object { [string]$_ }) -Encoding UTF8
}
else {
    Set-Content -LiteralPath $launcherOutputPath -Value "LaunchAvatarChat.ps1 was not found." -Encoding UTF8
}

$fileSummaries = @(
    Get-FileSummary -Label "Unity player" -RelativePath "Build\Interviewee1UnityAvatarChat.exe" -AbsolutePath (Join-Path $appRoot "Build\Interviewee1UnityAvatarChat.exe")
    Get-FileSummary -Label "Unity data" -RelativePath "Build\Interviewee1UnityAvatarChat_Data" -AbsolutePath (Join-Path $appRoot "Build\Interviewee1UnityAvatarChat_Data")
    Get-FileSummary -Label "Run batch" -RelativePath "RUN_AVATAR_CHAT.bat" -AbsolutePath (Join-Path $appRoot "RUN_AVATAR_CHAT.bat")
    Get-FileSummary -Label "Launcher" -RelativePath "LaunchAvatarChat.ps1" -AbsolutePath $launcher
    Get-FileSummary -Label "Build metadata" -RelativePath "BUILD_INFO.json" -AbsolutePath (Join-Path $appRoot "BUILD_INFO.json")
    Get-FileSummary -Label "Server" -RelativePath "..\Interviewee1CloneAI\server.js" -AbsolutePath (Join-Path $appRoot "..\Interviewee1CloneAI\server.js")
    Get-FileSummary -Label "Persona data" -RelativePath "..\Interviewee1CloneAI\data\persona.json" -AbsolutePath (Join-Path $appRoot "..\Interviewee1CloneAI\data\persona.json")
    Get-FileSummary -Label "Bundled NodeRuntime" -RelativePath "..\NodeRuntime\node.exe" -AbsolutePath (Join-Path $appRoot "..\NodeRuntime\node.exe")
)

$fileRows = @("label`tpath`texists`tkind`tbytes`tsha256")
$fileRows += $fileSummaries | ForEach-Object {
    "{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f $_.label, $_.relativePath, $_.exists, $_.kind, $_.bytes, $_.sha256
}
Set-Content -LiteralPath (Join-Path $bundleRoot "file_presence.tsv") -Value $fileRows -Encoding UTF8

$supportInfo = [ordered]@{
    generatedAt = (Get-Date).ToString("o")
    bundleSchemaVersion = "1"
    productName = $productName
    version = $version
    buildId = $buildId
    osVersion = [System.Environment]::OSVersion.VersionString
    powerShellVersion = $PSVersionTable.PSVersion.ToString()
    culture = [System.Globalization.CultureInfo]::CurrentCulture.Name
    localServer = Get-ServerConfigSummary
    includedUnityLog = [bool]$IncludeUnityLog
    notes = "No environment variable dump or API key value is intentionally collected."
}

$supportInfo | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $bundleRoot "support_info.json") -Encoding UTF8

if ($IncludeUnityLog) {
    $logPath = Find-UnityPlayerLog
    if ($logPath) {
        $logLines = Get-Content -LiteralPath $logPath -Tail 2000 -ErrorAction SilentlyContinue
        $redacted = $logLines -replace $ApiKeyPattern, "[REDACTED_API_KEY]"
        Set-Content -LiteralPath (Join-Path $bundleRoot "unity_player_log_tail.txt") -Value $redacted -Encoding UTF8
    }
    else {
        Set-Content -LiteralPath (Join-Path $bundleRoot "unity_player_log_tail.txt") -Value "Unity Player.log was not found in the known product paths." -Encoding UTF8
    }
}

$readme = @"
겉!=속 support bundle

Send this folder when reporting an issue.

Included:
- BUILD_INFO files when available
- launcher_check.txt
- support_info.json
- file_presence.tsv
- optional Unity Player.log tail only when -IncludeUnityLog is used

Not intentionally collected:
- OPENAI_API_KEY value
- full environment variable dump
- saved ending card text files
- playtest feedback notes
"@
Set-Content -LiteralPath (Join-Path $bundleRoot "README_SUPPORT_BUNDLE.txt") -Value $readme -Encoding UTF8

try {
    Assert-NoApiKeyPattern -Path $bundleRoot
}
catch {
    Remove-Item -LiteralPath $bundleRoot -Recurse -Force -ErrorAction SilentlyContinue
    throw
}

if ($Zip) {
    $zipPath = "$bundleRoot.zip"
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -LiteralPath $bundleRoot -DestinationPath $zipPath -Force
    Write-Host "Support bundle created: $zipPath"
}
else {
    Write-Host "Support bundle created: $bundleRoot"
}


