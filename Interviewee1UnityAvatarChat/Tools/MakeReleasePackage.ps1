param(
    [string]$OutputRoot,
    [string]$PackageName = "",
    [switch]$Zip
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

function Copy-OptionalItem {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Source) {
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

function Write-PackageManifest {
    param(
        [string]$ManifestPath,
        [string]$PackageRoot
    )

    $manifestRoot = ConvertTo-LongPath -Path $PackageRoot
    $manifestRows = Get-PackageFiles -Path $PackageRoot |
        Sort-Object FullName |
        ForEach-Object {
            $relative = $_.FullName.Substring($manifestRoot.Length + 1)
            $hash = Get-FileSha256 -Path $_.FullName
            "{0}`t{1}`t{2}" -f $relative, $_.Length, $hash
        }

    Set-Content -LiteralPath $ManifestPath -Value @("path`tbytes`tsha256") -Encoding UTF8
    Add-Content -LiteralPath $ManifestPath -Value $manifestRows -Encoding UTF8
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
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$buildRoot = Join-Path $projectRoot "Build"

$buildMetadataScript = Join-Path $PSScriptRoot "WriteBuildMetadata.ps1"
& $buildMetadataScript | Out-Null

$steamLegalValidationScript = Join-Path $PSScriptRoot "ValidateSteamLegalReadiness.ps1"
& $steamLegalValidationScript 2>&1 | Out-Null
$commercialUiCopyValidationScript = Join-Path $PSScriptRoot "ValidateCommercialUiCopy.ps1"
& $commercialUiCopyValidationScript 2>&1 | Out-Null
$commercialDecisionScript = Join-Path $PSScriptRoot "WriteCommercialLaunchDecision.ps1"
& $commercialDecisionScript 2>&1 | Out-Null
$internalQualityScript = Join-Path $PSScriptRoot "WriteInternalQualityScorecard.ps1"
& $internalQualityScript 2>&1 | Out-Null
$internalReviewScript = Join-Path $PSScriptRoot "WriteInternalCommercialReview.ps1"
& $internalReviewScript 2>&1 | Out-Null
$sprintPlanScript = Join-Path $PSScriptRoot "WriteCommercialSprintPlan.ps1"
& $sprintPlanScript 2>&1 | Out-Null
$externalReviewBriefsScript = Join-Path $PSScriptRoot "WriteExternalReviewBriefs.ps1"
& $externalReviewBriefsScript 2>&1 | Out-Null
$externalReviewBriefsValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewBriefs.ps1"
& $externalReviewBriefsValidationScript 2>&1 | Out-Null
$externalReviewTrackerScript = Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1"
& $externalReviewTrackerScript 2>&1 | Out-Null
$externalReviewTrackerValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewTracker.ps1"
& $externalReviewTrackerValidationScript 2>&1 | Out-Null
$externalReviewerRosterScript = Join-Path $PSScriptRoot "WriteExternalReviewerRosterTemplate.ps1"
& $externalReviewerRosterScript 2>&1 | Out-Null
$externalReviewerRosterValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewerRoster.ps1"
& $externalReviewerRosterValidationScript 2>&1 | Out-Null
$externalReviewerPacketsScript = Join-Path $PSScriptRoot "WriteExternalReviewerPackets.ps1"
& $externalReviewerPacketsScript 2>&1 | Out-Null
$externalReviewerPacketsValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewerPackets.ps1"
& $externalReviewerPacketsValidationScript 2>&1 | Out-Null
$externalReviewOutreachScript = Join-Path $PSScriptRoot "WriteExternalReviewOutreachQueue.ps1"
& $externalReviewOutreachScript 2>&1 | Out-Null
$externalReviewOutreachValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewOutreachQueue.ps1"
& $externalReviewOutreachValidationScript 2>&1 | Out-Null
$externalEvidenceImportScript = Join-Path $PSScriptRoot "ImportExternalEvidenceDrop.ps1"
& $externalEvidenceImportScript -SourceEvidenceDrop (Join-Path $buildRoot "ReleaseEvidence") -DestinationEvidenceRoot (Join-Path $buildRoot "ReleaseEvidence") -Preview 2>&1 | Out-Null
$externalEvidenceImportValidationScript = Join-Path $PSScriptRoot "ValidateExternalEvidenceImport.ps1"
& $externalEvidenceImportValidationScript 2>&1 | Out-Null
$marketComparisonValidationScript = Join-Path $PSScriptRoot "ValidateSteamMarketComparison.ps1"
& $marketComparisonValidationScript 2>&1 | Out-Null
$pricePositioningScript = Join-Path $PSScriptRoot "WriteCommercialPricePositioning.ps1"
& $pricePositioningScript 2>&1 | Out-Null

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "ReleasePackages"
}

if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $PackageName = "GeotNotEqualSok-Windows-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$packageRoot = Join-Path $OutputRoot $PackageName
$packageUnityRoot = Join-Path $packageRoot "Interviewee1UnityAvatarChat"
$packageBuildRoot = Join-Path $packageUnityRoot "Build"
$packageServerRoot = Join-Path $packageRoot "Interviewee1CloneAI"
$packageNodeRuntimeRoot = Join-Path $packageRoot "NodeRuntime"
$packageDocsRoot = Join-Path $packageUnityRoot "Docs"

Reset-PackageDirectory -PackageRoot $packageRoot -OutputRoot $OutputRoot

New-Item -ItemType Directory -Force -Path $packageBuildRoot, $packageServerRoot, $packageNodeRuntimeRoot, $packageDocsRoot | Out-Null

$requiredBuildItems = @(
    "Interviewee1UnityAvatarChat.exe",
    "Interviewee1UnityAvatarChat_Data",
    "UnityPlayer.dll",
    "UnityCrashHandler64.exe",
    "MonoBleedingEdge"
)

foreach ($item in $requiredBuildItems) {
    Copy-RequiredItem -Source (Join-Path $buildRoot $item) -Destination $packageBuildRoot
}

Copy-OptionalItem -Source (Join-Path $buildRoot "D3D12") -Destination $packageBuildRoot
Copy-OptionalItem -Source (Join-Path $buildRoot "dstorage.dll") -Destination $packageBuildRoot
Copy-OptionalItem -Source (Join-Path $buildRoot "dstoragecore.dll") -Destination $packageBuildRoot

Copy-RequiredItem -Source (Join-Path $projectRoot "RUN_AVATAR_CHAT.bat") -Destination $packageUnityRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "LaunchAvatarChat.ps1") -Destination $packageUnityRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Tools\CollectSupportBundle.ps1") -Destination $packageUnityRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "README.md") -Destination $packageUnityRoot
Copy-RequiredItem -Source (Join-Path $buildRoot "BUILD_INFO.json") -Destination $packageUnityRoot
Copy-RequiredItem -Source (Join-Path $buildRoot "BUILD_INFO.txt") -Destination $packageUnityRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\RELEASE_CHECKLIST.md") -Destination $packageDocsRoot
Copy-OptionalItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_PROTOCOL.md") -Destination $packageDocsRoot
Copy-OptionalItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_MODERATOR_SCRIPT.md") -Destination $packageDocsRoot
Copy-OptionalItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_PARTICIPANT_BRIEF.md") -Destination $packageDocsRoot
Copy-OptionalItem -Source (Join-Path $projectRoot "Docs\ACCESSIBILITY_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\ACCESSIBILITY_AUTOMATION_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PRIVACY_NOTICE_DRAFT.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\STEAM_LEGAL_READINESS_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_ISSUE_REGISTER_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\TROUBLESHOOTING.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\SUPPORT_HANDOFF.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\MODEL_CONFIG_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\GENERATED_MEMORY_POLICY_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_UI_COPY_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_QUALITY_RUBRIC.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_QUALITY_REVIEW_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\RELEASE_READINESS_REPORT.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_LAUNCH_DECISION.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_LAUNCH_GATE.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\INTERNAL_QUALITY_REVIEW.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\INTERNAL_QUALITY_SCORECARD.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\INTERNAL_COMMERCIAL_REVIEW.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\INTERNAL_COMMERCIAL_BACKLOG.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_SPRINT_PLAN.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_SPRINT_BOARD.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEW_BRIEFS.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEW_BRIEFS_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEW_TRACKER.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEW_TRACKER_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEWER_ROSTER.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEWER_ROSTER_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEWER_PACKETS.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEWER_PACKETS_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEW_OUTREACH_QUEUE.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_REVIEW_OUTREACH_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_EVIDENCE_IMPORT_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_PRICE_POSITIONING.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\STEAM_MARKET_COMPARISON.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\STEAM_MARKET_COMPARISON.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\STEAM_MARKET_COMPARISON_QA.md") -Destination $packageDocsRoot

Copy-RequiredItem -Source (Join-Path $serverRoot "server.js") -Destination $packageServerRoot
Copy-RequiredItem -Source (Join-Path $serverRoot "package.json") -Destination $packageServerRoot
Copy-RequiredItem -Source (Join-Path $serverRoot "README.md") -Destination $packageServerRoot
Copy-RequiredItem -Source (Join-Path $serverRoot "data") -Destination $packageServerRoot
Copy-RequiredItem -Source (Join-Path $buildRoot "ThirdParty\NodeRuntime\node.exe") -Destination $packageNodeRuntimeRoot
Copy-RequiredItem -Source (Join-Path $buildRoot "ThirdParty\NodeRuntime\LICENSE") -Destination $packageNodeRuntimeRoot
Copy-RequiredItem -Source (Join-Path $buildRoot "ThirdParty\NodeRuntime\README.md") -Destination $packageNodeRuntimeRoot
Copy-RequiredItem -Source (Join-Path $buildRoot "ThirdParty\NodeRuntime\NODE_RUNTIME_NOTICE.txt") -Destination $packageNodeRuntimeRoot

$startHere = @"
겉!=속 - Windows release package

실행:
1. Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat 실행
2. 런처가 앱 파일, 포함된 NodeRuntime, 로컬 서버, API 환경 변수를 점검합니다.
3. 포함된 NodeRuntime으로 로컬 대화 서버가 함께 켜집니다.
4. API 키가 없어도 텍스트 대화는 앱 내장 근거 답변으로 이어집니다.
5. 설정에서 로컬만을 켜면 텍스트 질문은 서버로 보내지지 않습니다.
6. 채팅 모델명은 OPENAI_CHAT_MODEL로 설정하고, 짧은 모델명은 서버가 gpt-... 형식으로 정규화합니다.

저장 데이터:
- 이어하기 데이터는 Unity PlayerPrefs에 저장됩니다.
- 마무리 기록은 로컬 사용자 데이터 폴더의 EndingCards에 저장됩니다.
- 의견 메모는 로컬 사용자 데이터 폴더의 FeedbackNotes에 저장됩니다.
- 앱의 정보 화면에서 저장 데이터와 기록을 삭제할 수 있습니다.

지원 문서:
- Interviewee1UnityAvatarChat\BUILD_INFO.txt
- Interviewee1UnityAvatarChat\CollectSupportBundle.ps1
- Interviewee1UnityAvatarChat\Docs\PRIVACY_NOTICE_DRAFT.md
- Interviewee1UnityAvatarChat\Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md
- Interviewee1UnityAvatarChat\Docs\ACCESSIBILITY_AUTOMATION_QA.md
- Interviewee1UnityAvatarChat\Docs\STEAM_LEGAL_READINESS_QA.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_ISSUE_REGISTER_QA.md
- Interviewee1UnityAvatarChat\Docs\TROUBLESHOOTING.md
- Interviewee1UnityAvatarChat\Docs\SUPPORT_HANDOFF.md
- Interviewee1UnityAvatarChat\Docs\MODEL_CONFIG_QA.md
- Interviewee1UnityAvatarChat\Docs\GENERATED_MEMORY_POLICY_QA.md
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_UI_COPY_QA.md
- Interviewee1UnityAvatarChat\Docs\RELEASE_READINESS_REPORT.md
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_LAUNCH_DECISION.md
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_LAUNCH_GATE.md
- Interviewee1UnityAvatarChat\Docs\INTERNAL_QUALITY_REVIEW.md
- Interviewee1UnityAvatarChat\Docs\INTERNAL_QUALITY_SCORECARD.tsv
- Interviewee1UnityAvatarChat\Docs\INTERNAL_COMMERCIAL_REVIEW.md
- Interviewee1UnityAvatarChat\Docs\INTERNAL_COMMERCIAL_BACKLOG.tsv
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_SPRINT_PLAN.md
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_SPRINT_BOARD.tsv
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_BRIEFS.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_BRIEFS_QA.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_TRACKER.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_TRACKER_QA.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_ROSTER.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_ROSTER_QA.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_PACKETS.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEWER_PACKETS_QA.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_OUTREACH_QUEUE.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_REVIEW_OUTREACH_QA.md
- Interviewee1UnityAvatarChat\Docs\EXTERNAL_EVIDENCE_IMPORT_QA.md
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_PRICE_POSITIONING.md
- Interviewee1UnityAvatarChat\Docs\COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv
- Interviewee1UnityAvatarChat\Docs\STEAM_MARKET_COMPARISON.md
- Interviewee1UnityAvatarChat\Docs\STEAM_MARKET_COMPARISON.tsv
- Interviewee1UnityAvatarChat\Docs\STEAM_MARKET_COMPARISON_QA.md

점검:
- Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1 -CheckOnly
- Interviewee1UnityAvatarChat\CollectSupportBundle.ps1

주의:
- API 키는 이 패키지에 포함하지 않습니다.
- NodeRuntime은 로컬 서버 실행용으로만 사용됩니다.
- 마이크 전사는 OPENAI_API_KEY가 서버 실행 환경에 있을 때만 동작하며, 로컬만을 켜면 꺼집니다.
- 모델명이 형식에 맞지 않거나 실제 API에서 사용할 수 없으면 텍스트 대화는 로컬 근거 답변으로 이어집니다.
"@

Set-Content -LiteralPath (Join-Path $packageRoot "START_HERE.txt") -Value $startHere -Encoding UTF8

$manifestPath = Join-Path $packageRoot "RELEASE_MANIFEST.tsv"
Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot

$releaseReadinessScript = Join-Path $PSScriptRoot "WriteReleaseReadinessReport.ps1"
if (Test-Path -LiteralPath $releaseReadinessScript) {
    try {
        & $releaseReadinessScript -ReleasePackageRoot $packageRoot 2>&1 | Out-Null
    }
    catch {
        Write-Warning "Release readiness snapshot has pending failures: $($_.Exception.Message)"
    }
    Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\RELEASE_READINESS_REPORT.md") -Destination $packageDocsRoot
    Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot
}

if ($Zip) {
    $zipPath = "$packageRoot.zip"
    Compress-Archive -LiteralPath $packageRoot -DestinationPath $zipPath -Force
    Write-Host "Release package created: $zipPath"
} else {
    Write-Host "Release package created: $packageRoot"
}

