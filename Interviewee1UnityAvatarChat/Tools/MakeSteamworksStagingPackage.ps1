param(
    [string]$ReleasePackageRoot,
    [string]$OutputRoot,
    [string]$PackageName = "",
    [string]$AppId = "REPLACE_WITH_STEAM_APP_ID",
    [string]$DepotId = "REPLACE_WITH_WINDOWS_DEPOT_ID",
    [string]$BuildDescription = "Geot Not Equal Sok Windows QA build"
)

$ErrorActionPreference = "Stop"

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required path: $Path"
    }
}

function Copy-RequiredItem {
    param(
        [string]$Source,
        [string]$Destination
    )

    Assert-Path -Path $Source
    $item = Get-Item -LiteralPath $Source
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    if ($item.PSIsContainer) {
        $target = Join-Path $Destination $item.Name
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        $copyOutput = & robocopy $Source $target /E /NFL /NDL /NJH /NJS /NP 2>&1
        $copyCode = $LASTEXITCODE
        if ($copyCode -gt 7) {
            throw "robocopy failed for $Source -> $target with code ${copyCode}: $(($copyOutput | Select-Object -First 5) -join ' ')"
        }
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Reset-PackageDirectory {
    param(
        [string]$PackageRoot,
        [string]$OutputRoot
    )

    $outputFull = ([System.IO.Path]::GetFullPath($OutputRoot)) -replace '[\\/]+$', ''
    $packageFull = [System.IO.Path]::GetFullPath($PackageRoot)
    $expectedPrefix = $outputFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $packageFull.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset package directory outside output root: $packageFull"
    }

    if (-not (Test-Path -LiteralPath $PackageRoot)) {
        return
    }

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Remove-Item -LiteralPath (ConvertTo-LongPath -Path $PackageRoot) -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            Start-Sleep -Milliseconds 200
        }
    }

    $trashName = "{0}.delete-{1}" -f (Split-Path -Leaf $PackageRoot), (Get-Date -Format "yyyyMMddHHmmssfff")
    $trashPath = Join-Path (Split-Path -Parent $PackageRoot) $trashName
    Rename-Item -LiteralPath $PackageRoot -NewName $trashName -ErrorAction Stop
    Remove-Item -LiteralPath (ConvertTo-LongPath -Path $trashPath) -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-PackageFiles {
    param([string]$Path)

    $longPath = ConvertTo-LongPath -Path $Path
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            return @(Get-ChildItem -LiteralPath $longPath -File -Recurse -ErrorAction Stop)
        }
        catch {
            if ($attempt -eq 5) {
                throw
            }
            Start-Sleep -Milliseconds 300
        }
    }
}

function Get-FileSha256 {
    param([string]$Path)

    $longPath = ConvertTo-LongPath -Path $Path
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            return (Get-FileHash -LiteralPath $longPath -Algorithm SHA256 -ErrorAction Stop).Hash
        }
        catch {
            if ($attempt -eq 5) {
                throw
            }
            Start-Sleep -Milliseconds 300
        }
    }
}

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

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$sourceDocsRoot = Join-Path $projectRoot "Docs"
$steamworksRoot = Join-Path $projectRoot "Marketing\Steamworks"

if ([string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
    $ReleasePackageRoot = Join-Path $buildRoot "ReleasePackages\GeotNotEqualSok-Windows-QA"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "SteamworksStagingPackages"
}
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $PackageName = "GeotNotEqualSok-Steamworks-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$releaseRoot = Resolve-Path $ReleasePackageRoot
$packageRoot = Join-Path $OutputRoot $PackageName
$contentRoot = Join-Path $packageRoot "content"
$scriptsRoot = Join-Path $packageRoot "scripts"
$outputBuildRoot = Join-Path $packageRoot "output"
$docsRoot = Join-Path $packageRoot "docs"

$steamLegalValidationScript = Join-Path $PSScriptRoot "ValidateSteamLegalReadiness.ps1"
& $steamLegalValidationScript 2>&1 | Out-Null
$commercialUiCopyValidationScript = Join-Path $PSScriptRoot "ValidateCommercialUiCopy.ps1"
& $commercialUiCopyValidationScript 2>&1 | Out-Null
$commercialDecisionScript = Join-Path $PSScriptRoot "WriteCommercialLaunchDecision.ps1"
& $commercialDecisionScript 2>&1 | Out-Null

Reset-PackageDirectory -PackageRoot $packageRoot -OutputRoot $OutputRoot

New-Item -ItemType Directory -Force -Path $contentRoot, $scriptsRoot, $outputBuildRoot, $docsRoot | Out-Null

Copy-RequiredItem -Source (Join-Path $releaseRoot "START_HERE.txt") -Destination $contentRoot
Copy-RequiredItem -Source (Join-Path $releaseRoot "Interviewee1UnityAvatarChat") -Destination $contentRoot
Copy-RequiredItem -Source (Join-Path $releaseRoot "Interviewee1CloneAI") -Destination $contentRoot
Copy-RequiredItem -Source (Join-Path $releaseRoot "NodeRuntime") -Destination $contentRoot
Copy-RequiredItem -Source (Join-Path $steamworksRoot "STEAMWORKS_UPLOAD_PLAN.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $steamworksRoot "STEAM_ADMIN_CHECKLIST.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "PRIVACY_NOTICE_FINAL_TEMPLATE.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "STEAM_LEGAL_READINESS_QA.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "COMMERCIAL_UI_COPY_QA.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "GENERATED_MEMORY_POLICY_QA.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "COMMERCIAL_LAUNCH_DECISION.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "COMMERCIAL_LAUNCH_GATE.md") -Destination $docsRoot
Copy-RequiredItem -Source (Join-Path $sourceDocsRoot "EXTERNAL_ISSUE_REGISTER_QA.md") -Destination $docsRoot

$appTemplate = Get-Content -LiteralPath (Join-Path $steamworksRoot "app_build_windows_template.vdf") -Raw
$depotTemplate = Get-Content -LiteralPath (Join-Path $steamworksRoot "depot_build_windows_template.vdf") -Raw

$appBuild = $appTemplate.
    Replace("REPLACE_WITH_STEAM_APP_ID", $AppId).
    Replace("REPLACE_WITH_WINDOWS_DEPOT_ID", $DepotId).
    Replace("Geot Not Equal Sok Windows QA build", $BuildDescription)
$depotBuild = $depotTemplate.Replace("REPLACE_WITH_WINDOWS_DEPOT_ID", $DepotId)

Set-Content -LiteralPath (Join-Path $scriptsRoot "app_build_windows.vdf") -Value $appBuild -Encoding UTF8
Set-Content -LiteralPath (Join-Path $scriptsRoot "depot_build_windows.vdf") -Value $depotBuild -Encoding UTF8

$readme = @"
겉!=속 - Steamworks staging package

Content:
- content: Windows release package contents prepared for SteamPipe.
- scripts: AppBuild and DepotBuild VDF scripts.
- output: SteamPipe build output directory.
- docs: Steamworks upload plan, admin checklist, privacy final template, Steam/legal readiness QA, issue register QA, commercial launch decision, and final commercial launch gate.

Required external values:
- Steam AppID
- Windows DepotID
- Steamworks SDK path
- Steam build account

Upload example:
<SteamworksSDK>\tools\ContentBuilder\builder\steamcmd.exe +login <account_name> +run_app_build scripts\app_build_windows.vdf +quit

Do not store Steam credentials, API keys, or private account notes in this package.
"@

Set-Content -LiteralPath (Join-Path $packageRoot "README_STEAMWORKS_STAGING.txt") -Value $readme -Encoding UTF8

$manifestPath = Join-Path $packageRoot "STEAMWORKS_STAGING_MANIFEST.tsv"
$manifestRoot = ConvertTo-LongPath -Path $packageRoot
$manifestRows = Get-PackageFiles -Path $packageRoot |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($manifestRoot.Length + 1)
        $hash = Get-FileSha256 -Path $_.FullName
        "{0}`t{1}`t{2}" -f $relative, $_.Length, $hash
    }

Set-Content -LiteralPath $manifestPath -Value @("path`tbytes`tsha256") -Encoding UTF8
Add-Content -LiteralPath $manifestPath -Value $manifestRows -Encoding UTF8

Write-Host "Steamworks staging package created: $packageRoot"


