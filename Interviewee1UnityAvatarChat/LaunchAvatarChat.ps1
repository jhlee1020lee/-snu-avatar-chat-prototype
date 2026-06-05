param(
    [switch]$CheckOnly,
    [switch]$NoStartServer
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message)
    Write-Host "[겉!=속] $Message"
}

function Get-NodeVersion {
    param(
        [string]$NodePath,
        [string]$Source
    )

    if ([string]::IsNullOrWhiteSpace($NodePath) -or -not (Test-Path -LiteralPath $NodePath)) {
        return $null
    }

    $rawVersion = (& $NodePath --version 2>$null).Trim()
    $major = 0
    if ($rawVersion -match '^v(\d+)') {
        $major = [int]$Matches[1]
    }

    [pscustomobject]@{
        Path = $NodePath
        Version = $rawVersion
        Major = $major
        Source = $Source
    }
}

function Resolve-NodeRuntime {
    param([string]$AppRoot)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:CRUTCH_TO_DESK_NODE)) {
        $candidates += [pscustomobject]@{ Path = $env:CRUTCH_TO_DESK_NODE; Source = "override" }
    }

    $candidates += [pscustomobject]@{ Path = (Join-Path $AppRoot "NodeRuntime\node.exe"); Source = "bundled app runtime" }
    $candidates += [pscustomobject]@{ Path = (Join-Path $AppRoot "..\NodeRuntime\node.exe"); Source = "bundled release runtime" }
    $candidates += [pscustomobject]@{ Path = (Join-Path $AppRoot "Build\ThirdParty\NodeRuntime\node.exe"); Source = "prepared build runtime" }

    foreach ($candidate in $candidates) {
        $resolved = Resolve-Path $candidate.Path -ErrorAction SilentlyContinue
        if ($resolved) {
            $node = Get-NodeVersion -NodePath $resolved.Path -Source $candidate.Source
            if ($node) {
                return $node
            }
        }
    }

    $systemNode = Get-Command node -ErrorAction SilentlyContinue
    if ($systemNode) {
        return Get-NodeVersion -NodePath $systemNode.Source -Source "system PATH"
    }

    return $null
}

function Test-ServerConfig {
    param([int]$TimeoutSec = 2)

    try {
        $config = Invoke-RestMethod -Uri "http://127.0.0.1:8765/api/config" -Method Get -TimeoutSec $TimeoutSec
        return [pscustomobject]@{
            Available = $true
            ApiAvailable = [bool]$config.apiAvailable
            ChatModelReady = [bool]$config.chatModelReady
            ChatModel = [string]$config.chatModel
            ChatModelSource = [string]$config.chatModelSource
            ChatModelNote = [string]$config.chatModelNote
            ChatModelError = [string]$config.chatModelError
            ErrorMessage = ""
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $false
            ApiAvailable = $false
            ChatModelReady = $false
            ChatModel = ""
            ChatModelSource = ""
            ChatModelNote = ""
            ChatModelError = ""
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Test-ServerReady {
    param($ServerState)

    return $ServerState -and $ServerState.Available -and $ServerState.ApiAvailable -and $ServerState.ChatModelReady
}

function Get-ServerBlockReason {
    param($ServerState)

    if (-not $ServerState -or -not $ServerState.Available) {
        $errorText = if ($ServerState -and -not [string]::IsNullOrWhiteSpace($ServerState.ErrorMessage)) { " Last error: $($ServerState.ErrorMessage)" } else { "" }
        return "Local server did not answer on http://127.0.0.1:8765/api/config.$errorText"
    }

    if (-not $ServerState.ApiAvailable) {
        return "Local server is running, but OPENAI_API_KEY is missing."
    }

    if (-not $ServerState.ChatModelReady) {
        $errorText = if (-not [string]::IsNullOrWhiteSpace($ServerState.ChatModelError)) { " $($ServerState.ChatModelError)" } else { "" }
        return "Local server is running, but the chat model health check failed.$errorText"
    }

    return ""
}

function Get-BuildInfo {
    param([string]$AppRoot)

    $candidates = @(
        (Join-Path $AppRoot "BUILD_INFO.json"),
        (Join-Path $AppRoot "Build\BUILD_INFO.json")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            try {
                return Get-Content -LiteralPath $candidate -Raw | ConvertFrom-Json
            }
            catch {
                return $null
            }
        }
    }

    return $null
}

function Start-LocalServer {
    param(
        [string]$ServerRoot,
        [string]$NodePath
    )

    Start-Process -FilePath $NodePath -ArgumentList "server.js" -WorkingDirectory $ServerRoot -WindowStyle Hidden | Out-Null

    $deadline = (Get-Date).AddSeconds(8)
    do {
        Start-Sleep -Milliseconds 250
        $state = Test-ServerConfig -TimeoutSec 2
        if ($state.Available) {
            return $state
        }
    } while ((Get-Date) -lt $deadline)

    return Test-ServerConfig -TimeoutSec 2
}

$root = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { (Get-Location).Path } else { $PSScriptRoot }
$appExe = Join-Path $root "Build\Interviewee1UnityAvatarChat.exe"
$serverRoot = Resolve-Path (Join-Path $root "..\Interviewee1CloneAI") -ErrorAction SilentlyContinue
$serverJs = if ($serverRoot) { Join-Path $serverRoot.Path "server.js" } else { "" }

if ([string]::IsNullOrWhiteSpace($env:OPENAI_CHAT_MODEL)) {
    $env:OPENAI_CHAT_MODEL = "gpt-5.4-mini"
}

Write-Status "Starting launch preflight."

if (-not (Test-Path -LiteralPath $appExe)) {
    Write-Host "Build\Interviewee1UnityAvatarChat.exe was not found."
    Write-Host "Build the Unity player first, or check that the release package is complete."
    exit 1
}

Write-Status "App executable found: $appExe"

$buildInfo = Get-BuildInfo -AppRoot $root
if ($buildInfo -and -not [string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) {
    Write-Status "Build: $($buildInfo.productName) $($buildInfo.version) ($($buildInfo.buildId))"
}
else {
    Write-Status "Build metadata was not found."
}

$node = Resolve-NodeRuntime -AppRoot $root
if ($node -and $node.Major -ge 20) {
    Write-Status "Node.js runtime ready: $($node.Version) from $($node.Source)."
}
elseif ($node) {
    Write-Status "Node.js $($node.Version) was found from $($node.Source). The recommended server version is 20 or newer."
}
else {
    Write-Status "No Node.js runtime was found. The game cannot launch unless the local server is already healthy."
}

$serverState = Test-ServerConfig
if ($serverState.Available) {
    $apiText = if ($serverState.ApiAvailable) { "API available" } else { "API key missing" }
    $healthText = if ($serverState.ChatModelReady) { "chat model ready" } else { "chat model not ready" }
    $modelText = if ([string]::IsNullOrWhiteSpace($serverState.ChatModel)) { "" } else { ", chat model $($serverState.ChatModel)" }
    Write-Status "Local server is already running: ${apiText}, ${healthText}${modelText}"
    if (-not [string]::IsNullOrWhiteSpace($serverState.ChatModelNote)) {
        Write-Status "Model config: $($serverState.ChatModelNote)"
    }
}
else {
    if (-not $serverRoot -or -not (Test-Path -LiteralPath $serverJs)) {
        Write-Status "Server files were not found. The game will not launch."
    }
    else {
        if (-not $node) {
            Write-Status "Node.js was not found. The game will not launch because the server cannot be started."
        }
        elseif ($node.Major -lt 20) {
            Write-Status "Node.js $($node.Version) was found from $($node.Source). Node.js 20 or newer is required to launch with a healthy server."
        }
        elseif ($NoStartServer) {
            Write-Status "Node.js $($node.Version) found from $($node.Source). Skipping automatic server start; the game will not launch unless the server is already healthy."
        }
        else {
            Write-Status "Starting the local conversation server with Node.js $($node.Version) from $($node.Source)."
            $serverState = Start-LocalServer -ServerRoot $serverRoot.Path -NodePath $node.Path
            if ($serverState.Available) {
                $apiText = if ($serverState.ApiAvailable) { "API available" } else { "API key missing" }
                $healthText = if ($serverState.ChatModelReady) { "chat model ready" } else { "chat model not ready" }
                $modelText = if ([string]::IsNullOrWhiteSpace($serverState.ChatModel)) { "" } else { ", chat model $($serverState.ChatModel)" }
                Write-Status "Local server responded: ${apiText}, ${healthText}${modelText}"
                if (-not [string]::IsNullOrWhiteSpace($serverState.ChatModelNote)) {
                    Write-Status "Model config: $($serverState.ChatModelNote)"
                }
            }
            else {
                Write-Status "Server response was not confirmed within 8 seconds. The game will not launch."
                if (-not [string]::IsNullOrWhiteSpace($serverState.ErrorMessage)) {
                    Write-Status "Last server check error: $($serverState.ErrorMessage)"
                }
            }
        }
    }
}

$apiKeyPresent = -not [string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)
if ($apiKeyPresent) {
    Write-Status "OPENAI_API_KEY is set in the current Windows process environment. The key value is not displayed, stored, or copied into support bundles."
}
else {
    Write-Status "OPENAI_API_KEY is not set in the current Windows process environment."
}

if (-not (Test-ServerReady $serverState)) {
    Write-Status "Launch blocked: $(Get-ServerBlockReason $serverState)"
    Write-Status "Start the server with a valid OPENAI_API_KEY and a passing chat model health check, then run this launcher again."
    exit 1
}

if ($CheckOnly) {
    Write-Status "Check-only mode complete."
    exit 0
}

Write-Status "Launching the game."
Start-Process -FilePath $appExe -ArgumentList "-force-d3d11" -WorkingDirectory (Split-Path -Parent $appExe) | Out-Null

