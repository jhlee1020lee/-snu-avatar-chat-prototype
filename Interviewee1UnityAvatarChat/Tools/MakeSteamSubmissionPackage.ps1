param(
    [string]$OutputRoot,
    [string]$PackageName = ""
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
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "SteamSubmissionPackages"
}

if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $PackageName = "GeotNotEqualSok-SteamSubmission-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$packageRoot = Join-Path $OutputRoot $PackageName
$packageMarketingRoot = Join-Path $packageRoot "Marketing"
$packageDocsRoot = Join-Path $packageRoot "Docs"
$packageTrailerRoot = Join-Path $packageMarketingRoot "Trailer"

$storeCopyValidationScript = Join-Path $PSScriptRoot "ValidateStoreCopy.ps1"
& $storeCopyValidationScript 2>&1 | Out-Null
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
$buildMetadataScript = Join-Path $PSScriptRoot "WriteBuildMetadata.ps1"
& $buildMetadataScript 2>&1 | Out-Null
$buildInfoPath = Join-Path $buildRoot "BUILD_INFO.json"
$buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) {
    throw "BUILD_INFO.json is missing buildId."
}

Reset-PackageDirectory -PackageRoot $packageRoot -OutputRoot $OutputRoot

New-Item -ItemType Directory -Force -Path $packageMarketingRoot, $packageDocsRoot, $packageTrailerRoot | Out-Null

Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\STORE_PAGE_DRAFT.md") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\STORE_PAGE_INTERNAL_NOTES.md") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\StoreCopy") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\SCREENSHOT_PLAN.md") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\STEAM_ASSET_PLAN.md") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Steamworks") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\ArtReview") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Screenshots") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\SteamAssets") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\VisualQuality") -Destination $packageMarketingRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\TRAILER_PRODUCTION_PLAN.md") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\TRAILER_FINAL_REVIEW_FORM.md") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\TRAILER_SHOTLIST.tsv") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\TRAILER_BUILD_CAPTURE_SHOTLIST.tsv") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\TRAILER_CAPTIONS.srt") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\TRAILER_CAPTIONS.vtt") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\trailer_animatic_60s.mp4") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\trailer_build_capture_60s.mp4") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\Frames") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Marketing\Trailer\BuildCaptureFrames") -Destination $packageTrailerRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\RELEASE_CHECKLIST.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_RELEASE_REVIEW.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_EVIDENCE_REQUIREMENTS.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_EVIDENCE_AUDIT.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_EVIDENCE_SUMMARY.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\MODEL_CONFIG_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\GENERATED_MEMORY_POLICY_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_UI_COPY_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_QUALITY_RUBRIC.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\COMMERCIAL_QUALITY_REVIEW_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_PROTOCOL.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_MODERATOR_SCRIPT.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_PARTICIPANT_BRIEF.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_OBSERVATION_FORM.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PLAYTEST_ISSUE_TRIAGE.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\ACCESSIBILITY_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\ACCESSIBILITY_AUTOMATION_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\ACCESSIBILITY_OBSERVATION_FORM.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PRIVACY_NOTICE_DRAFT.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\STEAM_LEGAL_READINESS_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_ISSUE_REGISTER_QA.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\TROUBLESHOOTING.md") -Destination $packageDocsRoot
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\SUPPORT_HANDOFF.md") -Destination $packageDocsRoot
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
Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\IMPROVEMENT_PLAN.md") -Destination $packageDocsRoot

$readme = @"
겉!=속 - Steam submission package

포함:
- 상점 페이지 초안
- 상점 문구 QA 보고서
- 1920x1080 스크린샷 세트
- Steam 캡슐/라이브러리/아이콘 자산
- 시각 품질 QA 보고서
- Steamworks 업로드 계획과 AppBuild/DepotBuild VDF 템플릿
- 외부 아트 리뷰 브리프와 기록 양식
- 60초 트레일러 애니매틱, 빌드 캡처 기반 후보, 자막/컷 리스트
- 최종 트레일러 리뷰 양식
- 배포 체크리스트와 플레이테스트 프로토콜
- 외부 증거 요구사항과 최신 외부 증거 감사 보고서
- 플레이테스트 증거 요약 보고서
- 모델 설정 QA 보고서
- 외부 플레이테스트 관찰 기록 양식과 이슈 분류 기준
- 접근성 QA 메모
- 접근성 자동 QA 보고서
- 실제 접근성 QA 관찰 양식
- Steam/법무 준비 자동 QA 보고서
- 외부 이슈 레지스터 QA 보고서와 템플릿
- 개인정보 초안/최종본 템플릿/문제 해결/지원 인계 초안
- 릴리즈 준비 감사 보고서
- 상업 출시 결정 보고서
- 상업 출시 최종 게이트 보고서
- 내부 품질 점수표와 내부 품질 리뷰
- 상업 출시 스프린트 계획과 실행 보드
- 외부 리뷰어 브리프와 초대 문구 QA
- 외부 리뷰 진행 추적 보드와 QA
- 외부 리뷰어 전달 패킷과 QA
- 외부 EvidenceDrop 수입 QA
- 상업 가격 포지셔닝 보고서와 판단 매트릭스
- Steam 시장 비교 보고서와 QA
- 내부 상업 리뷰와 다음 스프린트 백로그

검증:
원본 프로젝트에서:
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateTrailerAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateStoreCopy.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamLegalReadiness.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteCommercialLaunchDecision.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamSubmissionPackage.ps1 -PackageRoot <this folder>
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamworksStagingPackage.ps1 -PackageRoot <steamworks staging folder>

주의:
- 이 패키지는 Steam 상점 등록 준비용 자산 패키지입니다.
- 실행 파일과 서버 파일은 별도 Windows release package에 있습니다.
- API 키와 로그 파일은 포함하지 않습니다.
"@

Set-Content -LiteralPath (Join-Path $packageRoot "README_STEAM_SUBMISSION.txt") -Value $readme -Encoding UTF8

$provenance = [ordered]@{
    packageType = "SteamSubmission"
    packageName = $PackageName
    displayName = "겉!=속"
    version = [string]$buildInfo.version
    buildId = [string]$buildInfo.buildId
    generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
    sourceBuildInfo = "Build\BUILD_INFO.json"
}
$provenance | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $packageRoot "PACKAGE_PROVENANCE.json") -Encoding UTF8

$manifestPath = Join-Path $packageRoot "STEAM_SUBMISSION_MANIFEST.tsv"
Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot

$releaseReadinessScript = Join-Path $PSScriptRoot "WriteReleaseReadinessReport.ps1"
if (Test-Path -LiteralPath $releaseReadinessScript) {
    try {
        & $releaseReadinessScript -SteamSubmissionPackageRoot $packageRoot 2>&1 | Out-Null
    }
    catch {
        Write-Warning "Release readiness snapshot has pending failures: $($_.Exception.Message)"
    }
    Copy-RequiredItem -Source (Join-Path $projectRoot "Docs\RELEASE_READINESS_REPORT.md") -Destination $packageDocsRoot
    Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot
}

Write-Host "Steam submission package created: $packageRoot"

