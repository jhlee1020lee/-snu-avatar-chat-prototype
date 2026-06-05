param(
    [string]$DistChannel = "latest-v22.x",
    [string]$OutputRoot,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Assert-SafeChildPath {
    param(
        [string]$Parent,
        [string]$Child
    )

    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [System.IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside expected parent: $Child"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "ThirdParty\NodeRuntime"
}

$cacheRoot = Join-Path $buildRoot "NodeRuntimeCache"
$extractRoot = Join-Path $cacheRoot "extract"
$distBase = "https://nodejs.org/dist/$DistChannel"
$shaFile = Join-Path $cacheRoot "SHASUMS256.txt"

New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

Write-Host "[node-runtime] Reading $distBase/SHASUMS256.txt"
Invoke-WebRequest -Uri "$distBase/SHASUMS256.txt" -OutFile $shaFile

$shaLine = Get-Content -LiteralPath $shaFile |
    Where-Object { $_ -match " node-v.+-win-x64\.zip$" } |
    Select-Object -First 1

if (-not $shaLine) {
    throw "Could not find a win-x64 Node.js zip in SHASUMS256.txt"
}

$parts = $shaLine -split "\s+"
$expectedHash = $parts[0].ToUpperInvariant()
$zipName = $parts[$parts.Length - 1]
$zipPath = Join-Path $cacheRoot $zipName

if ($Force -or -not (Test-Path -LiteralPath $zipPath)) {
    Write-Host "[node-runtime] Downloading $zipName"
    Invoke-WebRequest -Uri "$distBase/$zipName" -OutFile $zipPath
}

$actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actualHash -ne $expectedHash) {
    throw "Node.js zip hash mismatch. Expected $expectedHash, got $actualHash"
}

Assert-SafeChildPath -Parent $buildRoot -Child $extractRoot
Assert-SafeChildPath -Parent $buildRoot -Child $OutputRoot

Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force

$extracted = Get-ChildItem -LiteralPath $extractRoot -Directory |
    Where-Object { $_.Name -like "node-v*-win-x64" } |
    Select-Object -First 1

if (-not $extracted) {
    throw "Extracted Node.js runtime folder was not found."
}

Remove-Item -LiteralPath $OutputRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

Copy-Item -LiteralPath (Join-Path $extracted.FullName "node.exe") -Destination $OutputRoot -Force
Copy-Item -LiteralPath (Join-Path $extracted.FullName "LICENSE") -Destination $OutputRoot -Force
Copy-Item -LiteralPath (Join-Path $extracted.FullName "README.md") -Destination $OutputRoot -Force

$nodeExe = Join-Path $OutputRoot "node.exe"
$version = (& $nodeExe --version).Trim()

$notice = @(
    "Node.js runtime for 겉!=속 local server",
    "Version: $version",
    "Source: $distBase/$zipName",
    "SHA256: $actualHash",
    "Prepared: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
    "",
    "This runtime is used only to start the local Interviewee1CloneAI server from the packaged Windows release."
)

Set-Content -LiteralPath (Join-Path $OutputRoot "NODE_RUNTIME_NOTICE.txt") -Value $notice -Encoding UTF8
Write-Host "[node-runtime] Prepared $version at $OutputRoot"

