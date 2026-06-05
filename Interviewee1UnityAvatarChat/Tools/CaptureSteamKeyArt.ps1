param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Assert-File {
    param(
        [string]$Path,
        [int64]$MinBytes = 1
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing expected file: $Path"
    }

    $item = Get-Item -LiteralPath $Path
    if ($item.Length -lt $MinBytes) {
        throw "File is too small: $Path ($($item.Length) bytes)"
    }
}

function Stop-KeyArtProcesses {
    Get-Process -Name "Interviewee1UnityAvatarChat", "UnityCrashHandler64" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildDir = Join-Path $projectRoot "Build"
$appExe = Join-Path $buildDir "Interviewee1UnityAvatarChat.exe"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Marketing\SteamAssets\source_keyart_1920x1080.png"
}

if (-not (Test-Path -LiteralPath $appExe)) {
    throw "Build executable not found: $appExe"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null

Stop-KeyArtProcesses
Start-Sleep -Milliseconds 250

$args = @(
    "-force-d3d11",
    "--smoke-skip-start",
    "--smoke-key-art",
    "--smoke-capture", $OutputPath,
    "--smoke-capture-delay", "0.5"
)

$process = Start-Process -FilePath $appExe -ArgumentList $args -WorkingDirectory $buildDir -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    Stop-KeyArtProcesses
    throw "$appExe exited with code $($process.ExitCode)"
}

Assert-File -Path $OutputPath -MinBytes 100000
Write-Host "Steam key art source captured: $OutputPath"
