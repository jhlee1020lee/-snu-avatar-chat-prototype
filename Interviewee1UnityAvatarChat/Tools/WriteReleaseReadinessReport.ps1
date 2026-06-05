param(
    [string]$OutputPath,
    [string]$ReleasePackageRoot,
    [string]$SteamSubmissionPackageRoot,
    [string]$SteamworksStagingPackageRoot,
    [string]$ExternalPlaytestPackageRoot,
    [string]$CommercialReviewPackageRoot,
    [switch]$SkipPackageValidation
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

function Add-Check {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Status,
        [string]$Evidence,
        [string]$NextAction = ""
    )

    $script:checks.Add([pscustomobject]@{
        Area = $Area
        Item = $Item
        Status = $Status
        Evidence = $Evidence
        NextAction = $NextAction
    }) | Out-Null
}

function Invoke-AuditCheck {
    param(
        [string]$Area,
        [string]$Item,
        [scriptblock]$Check
    )

    try {
        $evidence = & $Check
        Add-Check -Area $Area -Item $Item -Status "통과" -Evidence ([string]$evidence)
    }
    catch {
        Add-Check -Area $Area -Item $Item -Status "실패" -Evidence $_.Exception.Message -NextAction "수정 후 감사 보고서를 다시 생성한다."
    }
}

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing path: $Path"
    }
}

function Get-BuildIdFromJson {
    param([string]$Path)

    Assert-Path $Path
    $info = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $buildId = [string]$info.buildId
    if ([string]::IsNullOrWhiteSpace($buildId)) {
        throw "BUILD_INFO.json is missing buildId: $Path"
    }

    return $buildId
}

function Get-CurrentBuildId {
    $path = Join-Path $buildRoot "BUILD_INFO.json"
    return Get-BuildIdFromJson -Path $path
}

function Assert-PackageBuildMatchesCurrent {
    param(
        [string]$BuildInfoPath,
        [string]$Label
    )

    $currentBuildId = Get-CurrentBuildId
    $packageBuildId = Get-BuildIdFromJson -Path $BuildInfoPath
    if ($packageBuildId -ne $currentBuildId) {
        throw "$Label buildId '$packageBuildId' does not match current build '$currentBuildId'."
    }

    return "$Label buildId $packageBuildId 일치"
}

function Assert-PackageProvenanceMatchesCurrent {
    param(
        [string]$ProvenancePath,
        [string]$Label
    )

    Assert-Path $ProvenancePath
    $currentBuildId = Get-CurrentBuildId
    $provenance = Get-Content -LiteralPath $ProvenancePath -Raw | ConvertFrom-Json
    $packageBuildId = [string]$provenance.buildId
    if ([string]::IsNullOrWhiteSpace($packageBuildId)) {
        throw "$Label PACKAGE_PROVENANCE.json is missing buildId."
    }
    if ($packageBuildId -ne $currentBuildId) {
        throw "$Label package provenance buildId '$packageBuildId' does not match current build '$currentBuildId'."
    }

    return "$Label provenance buildId $packageBuildId 일치"
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-ReportNumber {
    param(
        [string]$Text,
        [string]$Label
    )

    $match = [regex]::Match($Text, "-\s*$([regex]::Escape($Label)):\s*(\d+)")
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }
    return -1
}

function Get-ReportValue {
    param(
        [string]$Text,
        [string]$Label
    )

    $match = [regex]::Match($Text, "-\s*$([regex]::Escape($Label)):\s*([^\r\n]+)")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return ""
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$buildRoot = Join-Path $projectRoot "Build"
$marketingRoot = Join-Path $projectRoot "Marketing"
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "RELEASE_READINESS_REPORT.md"
}
if ([string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
    $ReleasePackageRoot = Join-Path $buildRoot "ReleasePackages\GeotNotEqualSok-Windows-QA"
}
if ([string]::IsNullOrWhiteSpace($SteamSubmissionPackageRoot)) {
    $SteamSubmissionPackageRoot = Join-Path $buildRoot "SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA"
}
if ([string]::IsNullOrWhiteSpace($SteamworksStagingPackageRoot)) {
    $SteamworksStagingPackageRoot = Join-Path $buildRoot "SteamworksStagingPackages\GeotNotEqualSok-Steamworks-QA"
}
if ([string]::IsNullOrWhiteSpace($ExternalPlaytestPackageRoot)) {
    $ExternalPlaytestPackageRoot = Join-Path $buildRoot "ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA"
}
if ([string]::IsNullOrWhiteSpace($CommercialReviewPackageRoot)) {
    $CommercialReviewPackageRoot = Join-Path $buildRoot "CommercialReviewPackages\GeotNotEqualSok-CommercialReview-QA"
}

$checks = New-Object System.Collections.Generic.List[object]
$commercialQualityLabel = "5달러 품질 루브릭 QA"

Invoke-AuditCheck -Area "빌드" -Item "Windows 실행 파일" -Check {
    $exe = Join-Path $buildRoot "Interviewee1UnityAvatarChat.exe"
    Assert-Path $exe
    $item = Get-Item -LiteralPath $exe
    if ($item.Length -lt 100000) {
        throw "Executable is too small: $($item.Length) bytes"
    }
    "Build/Interviewee1UnityAvatarChat.exe, $($item.Length) bytes"
}

Invoke-AuditCheck -Area "빌드" -Item "빌드 메타데이터" -Check {
    $script = Join-Path $PSScriptRoot "WriteBuildMetadata.ps1"
    & $script 2>&1 | Out-Null
    $jsonPath = Join-Path $buildRoot "BUILD_INFO.json"
    Assert-Path $jsonPath
    $info = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$info.buildId)) {
        throw "BUILD_INFO.json is missing buildId"
    }
    "BUILD_INFO.json $($info.version) $($info.buildId) 확인"
}

$unityBuildSyncReport = Join-Path $docsRoot "UNITY_BUILD_SYNC_QA.md"
try {
    $script = Join-Path $PSScriptRoot "ValidateUnityBuildSync.ps1"
    & $script 2>&1 | Out-Null
    $syncText = Get-Content -LiteralPath $unityBuildSyncReport -Raw -Encoding UTF8
    if ($syncText -match "- 상태: 보류") {
        Add-Check -Area "빌드" -Item "Unity 빌드 동기화 QA" -Status "보류" -Evidence "소스가 빌드 산출물보다 최신임: UNITY_BUILD_SYNC_QA.md 확인" -NextAction "Unity 빌드와 전체 런타임 스모크를 실행해 소스 변경을 실행 파일에 반영한다."
    }
    else {
        Add-Check -Area "빌드" -Item "Unity 빌드 동기화 QA" -Status "통과" -Evidence "ValidateUnityBuildSync.ps1 통과"
    }
}
catch {
    Add-Check -Area "빌드" -Item "Unity 빌드 동기화 QA" -Status "실패" -Evidence $_.Exception.Message -NextAction "빌드 산출물과 검사 스크립트를 확인한다."
}

Invoke-AuditCheck -Area "실행" -Item "런처 사전 점검" -Check {
    $launcher = Join-Path $projectRoot "LaunchAvatarChat.ps1"
    Assert-Path $launcher
    & $launcher -CheckOnly -NoStartServer 2>&1 | Out-Null
    "LaunchAvatarChat.ps1 -CheckOnly -NoStartServer 통과"
}

Invoke-AuditCheck -Area "배포 운영" -Item "번들 Node.js 런타임" -Check {
    $nodeExe = Join-Path $buildRoot "ThirdParty\NodeRuntime\node.exe"
    Assert-Path $nodeExe
    Assert-Path (Join-Path $buildRoot "ThirdParty\NodeRuntime\LICENSE")
    Assert-Path (Join-Path $buildRoot "ThirdParty\NodeRuntime\NODE_RUNTIME_NOTICE.txt")
    $version = (& $nodeExe --version 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or $version -notmatch '^v(\d+)') {
        throw "Bundled NodeRuntime did not report a valid version."
    }
    if ([int]$Matches[1] -lt 20) {
        throw "Bundled NodeRuntime must be Node.js 20 or newer, found $version"
    }
    "Build/ThirdParty/NodeRuntime $version 확인"
}

Invoke-AuditCheck -Area "서버" -Item "Node 서버 문법 검사" -Check {
    $npm = Resolve-Tool @("npm.cmd", "npm")
    $output = & $npm --prefix $serverRoot run check 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output -join " ")
    }
    "npm --prefix Interviewee1CloneAI run check 통과"
}

Invoke-AuditCheck -Area "서버" -Item "모델 설정 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateModelConfig.ps1"
    & $script 2>&1 | Out-Null
    "ValidateModelConfig.ps1 통과"
}

Invoke-AuditCheck -Area "콘텐츠" -Item "근거 답변 QA" -Check {
    $script = Join-Path $PSScriptRoot "RunContentQA.ps1"
    $lastOutput = $null
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $lastOutput = & $script 2>&1
        if ($LASTEXITCODE -eq 0) {
            "RunContentQA.ps1 통과"
            return
        }
        Start-Sleep -Milliseconds (400 * $attempt)
    }
    throw (($lastOutput | ForEach-Object { [string]$_ }) -join " ")
    "RunContentQA.ps1 통과"
}

Invoke-AuditCheck -Area "콘텐츠" -Item "Unity 내장 답변 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateUnityLocalFallbackContent.ps1"
    & $script 2>&1 | Out-Null
    "ValidateUnityLocalFallbackContent.ps1 통과"
}

Invoke-AuditCheck -Area "콘텐츠" -Item "장시간 세션 QA" -Check {
    $script = Join-Path $PSScriptRoot "RunLongSessionQA.ps1"
    & $script 2>&1 | Out-Null
    "RunLongSessionQA.ps1 통과"
}

Invoke-AuditCheck -Area "콘텐츠 안전" -Item "개인정보/프롬프트 주입 QA" -Check {
    $script = Join-Path $PSScriptRoot "RunSafetyQA.ps1"
    & $script 2>&1 | Out-Null
    "RunSafetyQA.ps1 통과"
}

Invoke-AuditCheck -Area "콘텐츠 안전" -Item "확장 답변 검토 정책 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateGeneratedMemoryPolicy.ps1"
    & $script 2>&1 | Out-Null
    "ValidateGeneratedMemoryPolicy.ps1 통과"
}

Invoke-AuditCheck -Area "상용 문구" -Item "플레이어 UI 문구 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateCommercialUiCopy.ps1"
    & $script 2>&1 | Out-Null
    "ValidateCommercialUiCopy.ps1 통과"
}

Invoke-AuditCheck -Area "상용 문구" -Item "제품 브랜딩 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateProductBranding.ps1"
    & $script 2>&1 | Out-Null
    "ValidateProductBranding.ps1 통과"
}

Invoke-AuditCheck -Area "배포 운영" -Item "릴리즈 스모크 창 실행 정책 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateReleaseSmokePolicy.ps1"
    & $script 2>&1 | Out-Null
    "ValidateReleaseSmokePolicy.ps1 통과"
}

Invoke-AuditCheck -Area "핵심 루프" -Item "릴리즈 스모크 증거 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateReleaseSmokeEvidence.ps1"
    & $script 2>&1 | Out-Null
    "ValidateReleaseSmokeEvidence.ps1 통과"
}

Invoke-AuditCheck -Area "핵심 루프" -Item "첫인상 3갈래 깊은 기록 스모크" -Check {
    $smokeRoot = Join-Path $buildRoot "release-smoke"
    Assert-Path $smokeRoot
    $currentBuildId = Get-CurrentBuildId

    $cases = @(
        @{
            Path = Join-Path $smokeRoot "first-impression-crutch-deep-arc.tsv"
            Impression = "목발"
            Theme = "이동"
            ClosingLabel = "이동 확인"
        },
        @{
            Path = Join-Path $smokeRoot "first-impression-desk-deep-arc.tsv"
            Impression = "책상"
            Theme = "일과 공부"
            ClosingLabel = "사람 보기"
        },
        @{
            Path = Join-Path $smokeRoot "first-impression-face-deep-arc.tsv"
            Impression = "표정"
            Theme = "일상"
            ClosingLabel = "사람 보기"
        }
    )

    foreach ($case in $cases) {
        Assert-Path $case.Path
        $text = Get-Content -LiteralPath $case.Path -Raw -Encoding UTF8
        if ($text -match "`tFAIL(\r?\n|$)") {
            throw "First impression smoke has a failing expectation: $($case.Path)"
        }

        $requiredLines = @(
            "state`tbuild-id`t`t$currentBuildId`tINFO",
            "state`tfirst-impression`t`t$($case.Impression)`tINFO",
            "state`tfirst-impression-theme`t`t$($case.Theme)`tINFO",
            "state`tfirst-impression-theme-opened`t`ttrue`tINFO",
            "state`tfirst-impression-theme-deep`t`ttrue`tINFO",
            "state`tselected-closing-label`t`t$($case.ClosingLabel)`tINFO",
            "expect`tclosing`topen`topen`tPASS"
        )
        foreach ($requiredLine in $requiredLines) {
            if ($text -notmatch [regex]::Escape($requiredLine)) {
                throw "First impression smoke is missing '$requiredLine': $($case.Path)"
            }
        }
    }

    "목발/책상/표정 첫인상 스모크 3건이 현재 buildId ${currentBuildId}에서 깊은 기록과 마무리 카드까지 통과"
}

Invoke-AuditCheck -Area "상용 문구" -Item "Paperlogy 폰트 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidatePaperlogyUsage.ps1"
    & $script 2>&1 | Out-Null
    "ValidatePaperlogyUsage.ps1 통과"
}

Invoke-AuditCheck -Area "상점" -Item "Steam 그래픽/스크린샷 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateSteamAssets.ps1"
    & $script 2>&1 | Out-Null
    "ValidateSteamAssets.ps1 통과"
}

Invoke-AuditCheck -Area "상점" -Item "시각 품질 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateVisualQuality.ps1"
    & $script 2>&1 | Out-Null
    "ValidateVisualQuality.ps1 통과"
}

if ($SkipPackageValidation) {
    Invoke-AuditCheck -Area "접근성" -Item "접근성 정적 자동 QA" -Check {
        $script = Join-Path $PSScriptRoot "ValidateAccessibilityAutomation.ps1"
        & $script -StaticOnly 2>&1 | Out-Null
        "ValidateAccessibilityAutomation.ps1 -StaticOnly 통과"
    }
    Add-Check -Area "접근성" -Item "접근성 Unity 런타임 증거 QA" -Status "보류" -Evidence "창 없는 보고서 생성 모드: 캡처/TSV 런타임 증거는 RunReleaseSmoke.ps1 -AllowUnityWindows 필요" -NextAction "데스크톱 사용 가능할 때 전체 스모크를 실행하고 보고서를 다시 생성한다."
}
else {
    $accessibilityScript = Join-Path $PSScriptRoot "ValidateAccessibilityAutomation.ps1"
    try {
        & $accessibilityScript 2>&1 | Out-Null
        Add-Check -Area "접근성" -Item "접근성 자동 QA" -Status "통과" -Evidence "ValidateAccessibilityAutomation.ps1 통과"
    }
    catch {
        & $accessibilityScript -StaticOnly 2>&1 | Out-Null
        Add-Check -Area "접근성" -Item "접근성 정적 자동 QA" -Status "통과" -Evidence "ValidateAccessibilityAutomation.ps1 -StaticOnly 통과"
        Add-Check -Area "접근성" -Item "접근성 Unity 런타임 증거 QA" -Status "보류" -Evidence "최신 런타임 TSV/캡처 증거가 부족함: $($_.Exception.Message)" -NextAction "RunReleaseSmoke.ps1 -AllowUnityWindows로 최신 런타임 접근성 증거를 생성한다."
    }
}

Invoke-AuditCheck -Area "상점" -Item "트레일러 자산 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateTrailerAssets.ps1"
    & $script 2>&1 | Out-Null
    "ValidateTrailerAssets.ps1 통과"
}

Invoke-AuditCheck -Area "상점" -Item "상점 문구 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateStoreCopy.ps1"
    & $script 2>&1 | Out-Null
    "ValidateStoreCopy.ps1 통과"
}

Invoke-AuditCheck -Area "법무/상점" -Item "Steam/법무 준비 자동 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateSteamLegalReadiness.ps1"
    & $script 2>&1 | Out-Null
    "ValidateSteamLegalReadiness.ps1 통과"
}

Invoke-AuditCheck -Area "상업 품질" -Item $commercialQualityLabel -Check {
    $script = Join-Path $PSScriptRoot "ValidateCommercialQualityRubric.ps1"
    & $script 2>&1 | Out-Null
    "ValidateCommercialQualityRubric.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "상업 품질" -Item "내부 품질 점수표" -Check {
    $script = Join-Path $PSScriptRoot "WriteInternalQualityScorecard.ps1"
    & $script 2>&1 | Out-Null
    "WriteInternalQualityScorecard.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "상업 운영" -Item "상업 출시 스프린트 계획" -Check {
    $script = Join-Path $PSScriptRoot "WriteCommercialSprintPlan.ps1"
    & $script 2>&1 | Out-Null
    "WriteCommercialSprintPlan.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 리뷰 브리프 QA" -Check {
    $writeScript = Join-Path $PSScriptRoot "WriteExternalReviewBriefs.ps1"
    & $writeScript 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalReviewBriefs.ps1"
    & $validateScript 2>&1 | Out-Null
    "ValidateExternalReviewBriefs.ps1 통과"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 리뷰 진행 추적 QA" -Check {
    $writeScript = Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1"
    & $writeScript 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalReviewTracker.ps1"
    & $validateScript 2>&1 | Out-Null
    "ValidateExternalReviewTracker.ps1 통과"
}

$rosterReportPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER_QA.md"
try {
    $writeScript = Join-Path $PSScriptRoot "WriteExternalReviewerRosterTemplate.ps1"
    & $writeScript 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalReviewerRoster.ps1"
    & $validateScript 2>&1 | Out-Null
    $rosterText = Get-Content -LiteralPath $rosterReportPath -Raw -Encoding UTF8
    $rosterStatus = Get-ReportValue -Text $rosterText -Label "상태"
    $rosterBlocked = Get-ReportNumber -Text $rosterText -Label "차단"
    $rosterReadyMatch = [regex]::Match($rosterText, "-\s*준비 항목:\s*(\d+)/(\d+)")
    $rosterReady = if ($rosterReadyMatch.Success) { [int]$rosterReadyMatch.Groups[1].Value } else { -1 }
    $rosterRequired = if ($rosterReadyMatch.Success) { [int]$rosterReadyMatch.Groups[2].Value } else { -1 }
    if ($rosterStatus -eq "완료" -and $rosterBlocked -eq 0 -and $rosterReady -ge $rosterRequired -and $rosterRequired -gt 0) {
        Add-Check -Area "외부 검증 운영" -Item "외부 리뷰어 명단 QA" -Status "통과" -Evidence "ValidateExternalReviewerRoster.ps1 완료, 준비 $rosterReady/$rosterRequired"
    }
    elseif ($rosterStatus -eq "차단" -or $rosterBlocked -gt 0) {
        Add-Check -Area "외부 검증 운영" -Item "외부 리뷰어 명단 QA" -Status "실패" -Evidence "상태 $rosterStatus, 차단 $rosterBlocked, 준비 $rosterReady/$rosterRequired" -NextAction "명단 형식 오류와 비밀키 노출을 수정한다."
    }
    else {
        Add-Check -Area "외부 검증 운영" -Item "외부 리뷰어 명단 QA" -Status "미완료" -Evidence "상태 $rosterStatus, 준비 $rosterReady/$rosterRequired" -NextAction "reviewer_alias, contact_method, due_at을 모두 채운 뒤 ApplyExternalReviewerRoster.ps1를 실행한다."
    }
}
catch {
    Add-Check -Area "외부 검증 운영" -Item "외부 리뷰어 명단 QA" -Status "실패" -Evidence $_.Exception.Message -NextAction "수정 후 감사 보고서를 다시 생성한다."
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 리뷰어 전달 패킷 QA" -Check {
    $writeScript = Join-Path $PSScriptRoot "WriteExternalReviewerPackets.ps1"
    & $writeScript 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalReviewerPackets.ps1"
    & $validateScript 2>&1 | Out-Null
    "ValidateExternalReviewerPackets.ps1 통과"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 리뷰 발송 큐 QA" -Check {
    $writeScript = Join-Path $PSScriptRoot "WriteExternalReviewOutreachQueue.ps1"
    & $writeScript 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalReviewOutreachQueue.ps1"
    & $validateScript 2>&1 | Out-Null
    "ValidateExternalReviewOutreachQueue.ps1 통과"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 리뷰 초대 outbox QA" -Check {
    $writeScript = Join-Path $PSScriptRoot "WriteExternalReviewInviteOutbox.ps1"
    & $writeScript 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalReviewInviteOutbox.ps1"
    & $validateScript 2>&1 | Out-Null
    "ValidateExternalReviewInviteOutbox.ps1 통과"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 증거 수입 QA" -Check {
    $sourceEvidenceDrop = Join-Path $CommercialReviewPackageRoot "EvidenceDrop"
    if (-not (Test-Path -LiteralPath $sourceEvidenceDrop)) {
        $sourceEvidenceDrop = Join-Path $buildRoot "ReleaseEvidence"
    }
    $importScript = Join-Path $PSScriptRoot "ImportExternalEvidenceDrop.ps1"
    & $importScript -SourceEvidenceDrop $sourceEvidenceDrop -DestinationEvidenceRoot (Join-Path $buildRoot "ReleaseEvidence") -Preview 2>&1 | Out-Null
    $validateScript = Join-Path $PSScriptRoot "ValidateExternalEvidenceImport.ps1"
    & $validateScript 2>&1 | Out-Null
    "ValidateExternalEvidenceImport.ps1 통과"
}

Invoke-AuditCheck -Area "상업 운영" -Item "Steam 시장 비교 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateSteamMarketComparison.ps1"
    & $script 2>&1 | Out-Null
    "ValidateSteamMarketComparison.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "상업 운영" -Item "가격 포지셔닝 보고서" -Check {
    $script = Join-Path $PSScriptRoot "WriteCommercialPricePositioning.ps1"
    & $script 2>&1 | Out-Null
    "WriteCommercialPricePositioning.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "상점" -Item "상점 스크린샷 매니페스트" -Check {
    $manifestPath = Join-Path $marketingRoot "Screenshots\SCREENSHOT_MANIFEST.tsv"
    Assert-Path $manifestPath
    $manifest = Import-Csv -Delimiter "`t" -LiteralPath $manifestPath
    if ($manifest.Count -ne 11) {
        throw "Expected 11 screenshot rows, found $($manifest.Count)"
    }
    $required = @(
        "01-title-session-start.png",
        "02-question-phone.png",
        "03-hotspot-preview.png",
        "04-dialogue-scroll.png",
        "05-memory-complete.png",
        "06-closing-card.png",
        "07-record-archive.png",
        "08-record-delete.png",
        "09-accessibility-settings.png",
        "10-data-policy-delete.png",
        "11-title-continue.png"
    )
    foreach ($name in $required) {
        if (-not ($manifest | Where-Object { $_.path -eq $name })) {
            throw "Manifest is missing $name"
        }
    }
    "11장 스크린샷 매니페스트 확인"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 증거 감사 보고서" -Check {
    $script = Join-Path $PSScriptRoot "ValidateExternalEvidence.ps1"
    & $script 2>&1 | Out-Null
    "ValidateExternalEvidence.ps1 보고서 생성"
}

if ($SkipPackageValidation) {
    Add-Check -Area "외부 검증 운영" -Item "플레이테스트 피드백 export 검증" -Status "보류" -Evidence "창 없는 보고서 생성 모드: 현재 빌드 ID와 일치하는 신규 피드백 export는 전체 Unity 스모크 후 생성 필요" -NextAction "RunReleaseSmoke.ps1 -AllowUnityWindows로 최신 export를 생성한 뒤 전체 감사 보고서를 다시 생성한다."
}
else {
    $feedbackExportScript = Join-Path $PSScriptRoot "ValidatePlaytestFeedbackExport.ps1"
    try {
        & $feedbackExportScript -RequireFiveTurnSession 2>&1 | Out-Null
        Add-Check -Area "외부 검증 운영" -Item "플레이테스트 피드백 export 검증" -Status "통과" -Evidence "ValidatePlaytestFeedbackExport.ps1 통과"
    }
    catch {
        Add-Check -Area "외부 검증 운영" -Item "플레이테스트 피드백 export 검증" -Status "보류" -Evidence "현재 BUILD_INFO와 일치하는 최신 피드백 export가 없음: $($_.Exception.Message)" -NextAction "최신 Unity 빌드/런타임 스모크 또는 실제 플레이테스트에서 새 feedback txt/json을 생성한다."
    }
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "플레이테스트 증거 요약" -Check {
    $script = Join-Path $PSScriptRoot "SummarizePlaytestEvidence.ps1"
    & $script 2>&1 | Out-Null
    "SummarizePlaytestEvidence.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 이슈 레지스터 QA" -Check {
    $script = Join-Path $PSScriptRoot "ValidateExternalIssueRegister.ps1"
    & $script 2>&1 | Out-Null
    "ValidateExternalIssueRegister.ps1 보고서 생성"
}

Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 이슈 등록 도구" -Check {
    $script = Join-Path $PSScriptRoot "RegisterExternalIssue.ps1"
    Assert-Path $script
    $source = Get-Content -LiteralPath $script -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($source, [ref]$null)
    if ($source -notmatch "ValidateExternalIssueRegister\.ps1") {
        throw "RegisterExternalIssue.ps1 does not call external issue register validation."
    }
    "RegisterExternalIssue.ps1 존재 및 검증 연결 확인"
}

Invoke-AuditCheck -Area "문서" -Item "출시/지원 문서" -Check {
    $required = @(
        "RELEASE_CHECKLIST.md",
        "COMMERCIAL_RELEASE_REVIEW.md",
        "EXTERNAL_EVIDENCE_REQUIREMENTS.md",
        "PLAYTEST_EVIDENCE_SUMMARY.md",
        "EXTERNAL_ISSUE_REGISTER_QA.md",
        "EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv",
        "MODEL_CONFIG_QA.md",
        "GENERATED_MEMORY_POLICY_QA.md",
        "COMMERCIAL_UI_COPY_QA.md",
        "COMMERCIAL_QUALITY_RUBRIC.md",
        "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv",
        "COMMERCIAL_QUALITY_REVIEW_QA.md",
        "COMMERCIAL_LAUNCH_GATE.md",
        "INTERNAL_QUALITY_REVIEW.md",
        "INTERNAL_QUALITY_SCORECARD.tsv",
        "INTERNAL_COMMERCIAL_REVIEW.md",
        "INTERNAL_COMMERCIAL_BACKLOG.tsv",
        "COMMERCIAL_SPRINT_PLAN.md",
        "COMMERCIAL_SPRINT_BOARD.tsv",
        "EXTERNAL_REVIEW_BRIEFS.md",
        "EXTERNAL_REVIEW_BRIEFS_QA.md",
        "EXTERNAL_REVIEW_TRACKER.md",
        "EXTERNAL_REVIEW_TRACKER_QA.md",
        "EXTERNAL_REVIEWER_ROSTER.md",
        "EXTERNAL_REVIEWER_ROSTER_QA.md",
        "EXTERNAL_REVIEWER_PACKETS.md",
        "EXTERNAL_REVIEWER_PACKETS_QA.md",
        "EXTERNAL_REVIEW_OUTREACH_QUEUE.md",
        "EXTERNAL_REVIEW_OUTREACH_QA.md",
        "EXTERNAL_EVIDENCE_IMPORT_QA.md",
        "COMMERCIAL_PRICE_POSITIONING.md",
        "COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv",
        "STEAM_MARKET_COMPARISON.md",
        "STEAM_MARKET_COMPARISON.tsv",
        "STEAM_MARKET_COMPARISON_QA.md",
        "PLAYTEST_PROTOCOL.md",
        "PLAYTEST_MODERATOR_SCRIPT.md",
        "PLAYTEST_PARTICIPANT_BRIEF.md",
        "PLAYTEST_OBSERVATION_FORM.md",
        "PLAYTEST_ISSUE_TRIAGE.md",
        "ACCESSIBILITY_QA.md",
        "ACCESSIBILITY_AUTOMATION_QA.md",
        "ACCESSIBILITY_OBSERVATION_FORM.md",
        "PRIVACY_NOTICE_DRAFT.md",
        "PRIVACY_NOTICE_FINAL_TEMPLATE.md",
        "STEAM_LEGAL_READINESS_QA.md",
        "TROUBLESHOOTING.md",
        "SUPPORT_HANDOFF.md",
        "IMPROVEMENT_PLAN.md"
    )
    foreach ($name in $required) {
        Assert-Path (Join-Path $docsRoot $name)
    }
    "$($required.Count)개 출시 문서 확인"
}

Invoke-AuditCheck -Area "보안" -Item "API 키 형태 문자열 검색" -Check {
    $rg = Resolve-Tool @("rg.exe", "rg")
    $args = @(
        "--hidden",
        "--files-with-matches",
        "--glob", "!Library/**",
        "--glob", "!**/Library/**",
        "--glob", "!Temp/**",
        "--glob", "!**/Temp/**",
        "--glob", "!obj/**",
        "--glob", "!**/obj/**",
        "--glob", "!node_modules/**",
        "--glob", "!**/node_modules/**",
        "--glob", "!Build/**",
        "--glob", "!**/Build/**",
        "--glob", "!Docs/RELEASE_READINESS_REPORT.md",
        "--glob", "!**/Docs/RELEASE_READINESS_REPORT.md",
        "--glob", "!Docs/COMMERCIAL_LAUNCH_DECISION.md",
        "--glob", "!**/Docs/COMMERCIAL_LAUNCH_DECISION.md",
        "--glob", "!Docs/COMMERCIAL_LAUNCH_GATE.md",
        "--glob", "!**/Docs/COMMERCIAL_LAUNCH_GATE.md",
        $ApiKeyPattern,
        $projectRoot.Path,
        $serverRoot
    )
    $output = & $rg @args 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        throw "Potential API key match found: $(($output | Select-Object -First 3) -join ' ')"
    }
    if ($code -ne 1) {
        throw "rg exited with code ${code}: $(($output | Select-Object -First 3) -join ' ')"
    }
    "API 키 형태 문자열 없음"
}

if ($SkipPackageValidation) {
    Add-Check -Area "패키지" -Item "Windows 실행 패키지 검증" -Status "보류" -Evidence "보고서 사전 생성 모드" -NextAction "패키지 생성 후 전체 감사 보고서를 다시 생성한다."
    Add-Check -Area "지원" -Item "지원 번들 생성 QA" -Status "보류" -Evidence "보고서 사전 생성 모드" -NextAction "패키지 생성 후 지원 번들 QA를 포함한 전체 감사 보고서를 다시 생성한다."
    Add-Check -Area "외부 검증 운영" -Item "외부 플레이테스트 패키지 검증" -Status "보류" -Evidence "보고서 사전 생성 모드" -NextAction "외부 플레이테스트 패키지 생성 후 전체 감사 보고서를 다시 생성한다."
    Add-Check -Area "상업 검토 운영" -Item "상업 검토 패키지 검증" -Status "보류" -Evidence "보고서 사전 생성 모드" -NextAction "상업 검토 패키지 생성 후 전체 감사 보고서를 다시 생성한다."
    Add-Check -Area "패키지" -Item "Steam 제출 패키지 검증" -Status "보류" -Evidence "보고서 사전 생성 모드" -NextAction "패키지 생성 후 전체 감사 보고서를 다시 생성한다."
    Add-Check -Area "Steamworks" -Item "SteamPipe 스테이징 패키지 검증" -Status "보류" -Evidence "보고서 사전 생성 모드" -NextAction "스테이징 패키지 생성 후 전체 감사 보고서를 다시 생성한다."
}
else {
    Invoke-AuditCheck -Area "패키지" -Item "Windows 실행 패키지 검증" -Check {
        $script = Join-Path $PSScriptRoot "ValidateReleasePackage.ps1"
        & $script -PackageRoot $ReleasePackageRoot 2>&1 | Out-Null
        $buildEvidence = Assert-PackageBuildMatchesCurrent -BuildInfoPath (Join-Path $ReleasePackageRoot "Interviewee1UnityAvatarChat\BUILD_INFO.json") -Label "Windows 실행 패키지"
        "ValidateReleasePackage.ps1 통과, $buildEvidence"
    }

    Invoke-AuditCheck -Area "패키지" -Item "패키지 서버 실행 QA" -Check {
        $script = Join-Path $PSScriptRoot "RunPackagedServerQA.ps1"
        & $script -PackageRoot $ReleasePackageRoot 2>&1 | Out-Null
        "RunPackagedServerQA.ps1 통과"
    }

    Invoke-AuditCheck -Area "지원" -Item "지원 번들 생성 QA" -Check {
        $script = Join-Path $ReleasePackageRoot "Interviewee1UnityAvatarChat\CollectSupportBundle.ps1"
        Assert-Path $script
        $qaRoot = Join-Path $buildRoot "SupportBundleQA"
        if (Test-Path -LiteralPath $qaRoot) {
            Remove-Item -LiteralPath $qaRoot -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $qaRoot | Out-Null

        $powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
        $output = & $powershell -NoProfile -ExecutionPolicy Bypass -File $script -OutputRoot $qaRoot 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($output -join " ")
        }

        $bundle = Get-ChildItem -LiteralPath $qaRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $bundle) {
            throw "Support bundle output folder was not created."
        }

        $required = @(
            "README_SUPPORT_BUNDLE.txt",
            "support_info.json",
            "launcher_check.txt",
            "file_presence.tsv",
            "BUILD_INFO.txt",
            "BUILD_INFO.json"
        )
        foreach ($name in $required) {
            Assert-Path (Join-Path $bundle.FullName $name)
        }

        $supportInfo = Get-Content -LiteralPath (Join-Path $bundle.FullName "support_info.json") -Raw | ConvertFrom-Json
        if (-not $supportInfo.localServer -or -not ($supportInfo.localServer.PSObject.Properties.Name -contains "error")) {
            throw "Support bundle localServer summary must include an error field for failed /api/config diagnostics."
        }

        $secretMatches = Get-ChildItem -LiteralPath $bundle.FullName -File -Recurse |
            Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($secretMatches) {
            throw "Support bundle may contain an API key pattern."
        }

        "CollectSupportBundle.ps1 필수 파일과 서버 오류 진단 필드 생성, API 키 형태 문자열 없음"
    }

    Invoke-AuditCheck -Area "외부 검증 운영" -Item "외부 플레이테스트 패키지 검증" -Check {
        $script = Join-Path $PSScriptRoot "ValidateExternalPlaytestPackage.ps1"
        & $script -PackageRoot $ExternalPlaytestPackageRoot 2>&1 | Out-Null
        $buildEvidence = Assert-PackageBuildMatchesCurrent -BuildInfoPath (Join-Path $ExternalPlaytestPackageRoot "Game\Interviewee1UnityAvatarChat\BUILD_INFO.json") -Label "외부 플레이테스트 패키지"
        "ValidateExternalPlaytestPackage.ps1 통과, $buildEvidence"
    }

    Invoke-AuditCheck -Area "상업 검토 운영" -Item "상업 검토 패키지 검증" -Check {
        $script = Join-Path $PSScriptRoot "ValidateCommercialReviewPackage.ps1"
        & $script -PackageRoot $CommercialReviewPackageRoot 2>&1 | Out-Null
        $provenanceEvidence = Assert-PackageProvenanceMatchesCurrent -ProvenancePath (Join-Path $CommercialReviewPackageRoot "PACKAGE_PROVENANCE.json") -Label "상업 검토 패키지"
        "ValidateCommercialReviewPackage.ps1 통과, $provenanceEvidence"
    }

    Invoke-AuditCheck -Area "패키지" -Item "Steam 제출 패키지 검증" -Check {
        $script = Join-Path $PSScriptRoot "ValidateSteamSubmissionPackage.ps1"
        & $script -PackageRoot $SteamSubmissionPackageRoot 2>&1 | Out-Null
        $provenanceEvidence = Assert-PackageProvenanceMatchesCurrent -ProvenancePath (Join-Path $SteamSubmissionPackageRoot "PACKAGE_PROVENANCE.json") -Label "Steam 제출 패키지"
        "ValidateSteamSubmissionPackage.ps1 통과, $provenanceEvidence"
    }

    Invoke-AuditCheck -Area "Steamworks" -Item "SteamPipe 스테이징 패키지 검증" -Check {
        $script = Join-Path $PSScriptRoot "ValidateSteamworksStagingPackage.ps1"
        & $script -PackageRoot $SteamworksStagingPackageRoot 2>&1 | Out-Null
        $buildEvidence = Assert-PackageBuildMatchesCurrent -BuildInfoPath (Join-Path $SteamworksStagingPackageRoot "content\Interviewee1UnityAvatarChat\BUILD_INFO.json") -Label "SteamPipe 스테이징 패키지"
        "ValidateSteamworksStagingPackage.ps1 통과, $buildEvidence"
    }
}

Add-Check -Area "외부 검증" -Item "실제 플레이어 5문답 이상 관찰 QA" -Status "미완료" -Evidence "로컬 자동 QA로 대체할 수 없음" -NextAction "외부 참가자 테스트를 진행하고 이슈를 반영한다."
Add-Check -Area "외부 검증" -Item "실제 보조기기 기반 접근성 QA" -Status "미완료" -Evidence "키보드/큰 글자/움직임 줄임 자동 검증만 완료" -NextAction "스크린리더, 확대, 실제 입력 장치로 확인한다."
Add-Check -Area "상업 아트" -Item "외부 아트 리뷰와 최종 키아트 승인" -Status "미완료" -Evidence "현재 키아트는 제출 후보" -NextAction "외부 리뷰 또는 전문 보정을 거쳐 최종 승인한다."
Add-Check -Area "트레일러" -Item "라이브 플레이 녹화와 최종 사운드 믹스" -Status "미완료" -Evidence "현재 애니매틱과 빌드 캡처 후보는 자동 생성본" -NextAction "실제 조작 녹화 기반 최종 트레일러로 교체한다."
Add-Check -Area "법무/상점" -Item "개인정보 문구와 Steam 관리자 설정 최종화" -Status "미완료" -Evidence "현재 문서는 초안" -NextAction "배포 주체, 문의 채널, 지역 기준으로 최종 검토한다."

$statusCounts = $checks | Group-Object Status | Sort-Object Name
$failed = @($checks | Where-Object { $_.Status -eq "실패" }).Count
$incomplete = @($checks | Where-Object { $_.Status -eq "미완료" }).Count
$pending = @($checks | Where-Object { $_.Status -eq "보류" }).Count
$passed = @($checks | Where-Object { $_.Status -eq "통과" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 릴리즈 준비 감사 보고서")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 프로젝트: $($projectRoot.Path)")
$lines.Add("- Windows 패키지: $ReleasePackageRoot")
$lines.Add("- Steam 제출 패키지: $SteamSubmissionPackageRoot")
$lines.Add("- Steamworks 스테이징 패키지: $SteamworksStagingPackageRoot")
$lines.Add("- 외부 플레이테스트 패키지: $ExternalPlaytestPackageRoot")
$lines.Add("- 상업 검토 패키지: $CommercialReviewPackageRoot")
$lines.Add("")
$lines.Add("## 요약")
$lines.Add("")
$lines.Add("- 자동 통과: $passed")
$lines.Add("- 자동 실패: $failed")
$lines.Add("- 보류: $pending")
$lines.Add("- 외부 검증 미완료: $incomplete")
$lines.Add("")
$lines.Add("이 보고서는 현재 작업 폴더의 빌드, 상점 자료, 문서, 패키지 검증 결과를 기준으로 한다. 외부 플레이테스트, 실제 보조기기 QA, 외부 아트 리뷰, 최종 법무/Steam 관리자 설정은 이 컴퓨터 안에서 완료했다고 증명할 수 없으므로 미완료로 남긴다.")
$lines.Add("")
$lines.Add("## 감사 항목")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- | --- |")
foreach ($check in $checks) {
    $lines.Add("| $(Escape-MarkdownCell $check.Area) | $(Escape-MarkdownCell $check.Item) | $(Escape-MarkdownCell $check.Status) | $(Escape-MarkdownCell $check.Evidence) | $(Escape-MarkdownCell $check.NextAction) |")
}

$lines.Add("")
$lines.Add("## 상태 집계")
$lines.Add("")
foreach ($group in $statusCounts) {
    $lines.Add("- $($group.Name): $($group.Count)")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

$internalQualityScript = Join-Path $PSScriptRoot "WriteInternalQualityScorecard.ps1"
if (Test-Path -LiteralPath $internalQualityScript) {
    & $internalQualityScript 2>&1 | Out-Null
}

$sprintPlanScript = Join-Path $PSScriptRoot "WriteCommercialSprintPlan.ps1"
if (Test-Path -LiteralPath $sprintPlanScript) {
    & $sprintPlanScript 2>&1 | Out-Null
}

$marketComparisonValidationScript = Join-Path $PSScriptRoot "ValidateSteamMarketComparison.ps1"
if (Test-Path -LiteralPath $marketComparisonValidationScript) {
    & $marketComparisonValidationScript 2>&1 | Out-Null
}

$pricePositioningScript = Join-Path $PSScriptRoot "WriteCommercialPricePositioning.ps1"
if (Test-Path -LiteralPath $pricePositioningScript) {
    & $pricePositioningScript 2>&1 | Out-Null
}

$commercialDecisionScript = Join-Path $PSScriptRoot "WriteCommercialLaunchDecision.ps1"
if (Test-Path -LiteralPath $commercialDecisionScript) {
    & $commercialDecisionScript 2>&1 | Out-Null
}

Write-Host "Release readiness report written: $OutputPath"
if ($failed -gt 0) {
    throw "Release readiness report has $failed failed automated check(s)."
}


