param(
    [string]$OutputPath,
    [string]$ReleasePackageRoot,
    [string]$SteamSubmissionPackageRoot,
    [string]$SteamworksStagingPackageRoot,
    [string]$ExternalPlaytestPackageRoot,
    [string]$CommercialReviewPackageRoot,
    [string]$EvidenceRoot,
    [string]$IssueRegisterPath,
    [decimal]$PriceTargetUsd = 5,
    [switch]$RequireLaunchReady
)

$ErrorActionPreference = "Stop"

function Add-Gate {
    param(
        [string]$Area,
        [string]$Gate,
        [string]$Status,
        [string]$Evidence,
        [string]$NextAction = ""
    )

    $script:gates.Add([pscustomobject]@{
        Area = $Area
        Gate = $Gate
        Status = $Status
        Evidence = $Evidence
        NextAction = $NextAction
    }) | Out-Null
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Read-Report {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        try {
            return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            if ($attempt -eq 8) {
                throw
            }
            Start-Sleep -Milliseconds (120 * $attempt)
        }
    }

    return ""
}

function Get-ReportNumber {
    param(
        [string]$Text,
        [string]$Label
    )

    $pattern = "-\s*$([regex]::Escape($Label)):\s*(\d+)"
    $match = [regex]::Match($Text, $pattern)
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

    $pattern = "-\s*$([regex]::Escape($Label)):\s*([^\r\n]+)"
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return ""
}

function Test-ReportLine {
    param(
        [string]$Text,
        [string]$Label,
        [string]$Expected
    )

    $pattern = "-\s*$([regex]::Escape($Label)):\s*$([regex]::Escape($Expected))"
    return [regex]::IsMatch($Text, $pattern)
}

function Invoke-ReportScript {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{}
    )

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "Missing script: $ScriptPath"
    }

    & $ScriptPath @Parameters 2>&1 | Out-Null
}

function Write-LinesWithRetry {
    param(
        [string]$Path,
        [object]$Lines
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        $tempPath = "$Path.tmp-$PID-$([guid]::NewGuid().ToString('N'))"
        try {
            Set-Content -LiteralPath $tempPath -Value $Lines -Encoding UTF8 -ErrorAction Stop
            Move-Item -LiteralPath $tempPath -Destination $Path -Force -ErrorAction Stop
            return
        }
        catch {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            if ($attempt -eq 8) {
                throw
            }
            Start-Sleep -Milliseconds (120 * $attempt)
        }
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "COMMERCIAL_LAUNCH_GATE.md"
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
if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($IssueRegisterPath)) {
    $IssueRegisterPath = Join-Path $EvidenceRoot "EXTERNAL_ISSUE_REGISTER.tsv"
}

$releaseReportPath = Join-Path $docsRoot "RELEASE_READINESS_REPORT.md"
$externalAuditPath = Join-Path $docsRoot "EXTERNAL_EVIDENCE_AUDIT.md"
$playtestSummaryPath = Join-Path $docsRoot "PLAYTEST_EVIDENCE_SUMMARY.md"
$issueQaPath = Join-Path $docsRoot "EXTERNAL_ISSUE_REGISTER_QA.md"
$reviewerRosterQaPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER_QA.md"
$commercialQualityPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_REVIEW_QA.md"
$commercialDecisionPath = Join-Path $docsRoot "COMMERCIAL_LAUNCH_DECISION.md"
$commercialPricePath = Join-Path $docsRoot "COMMERCIAL_PRICE_POSITIONING.md"
$steamMarketQaPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON_QA.md"

$gates = New-Object System.Collections.Generic.List[object]
$priceTargetLabel = "$PriceTargetUsd" + "달러"

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ValidateExternalEvidence.ps1") -Parameters @{
        EvidenceRoot = $EvidenceRoot
        OutputPath = $externalAuditPath
    }
}
catch {
    Add-Gate -Area "외부 증거" -Gate "외부 증거 감사 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "증거 폴더의 비밀키, 파일 접근 오류, 형식 오류를 먼저 해결한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "SummarizePlaytestEvidence.ps1") -Parameters @{
        EvidenceRoot = (Join-Path $EvidenceRoot "Playtest")
        OutputPath = $playtestSummaryPath
    }
}
catch {
    Add-Gate -Area "외부 플레이테스트" -Gate "플레이테스트 요약 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "플레이테스트 증거의 비밀키와 읽기 오류를 제거한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ValidateExternalIssueRegister.ps1") -Parameters @{
        IssueRegisterPath = $IssueRegisterPath
        OutputPath = $issueQaPath
    }
}
catch {
    Add-Gate -Area "외부 이슈" -Gate "이슈 레지스터 QA 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "외부 이슈 레지스터 형식과 비밀키 노출 여부를 수정한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "WriteExternalReviewerRosterTemplate.ps1") -Parameters @{
        EvidenceRoot = $EvidenceRoot
        OutputPath = (Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER.md")
    }
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ValidateExternalReviewerRoster.ps1") -Parameters @{
        EvidenceRoot = $EvidenceRoot
        OutputPath = $reviewerRosterQaPath
    }
}
catch {
    Add-Gate -Area "외부 리뷰어" -Gate "리뷰어 명단 QA 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "EXTERNAL_REVIEWER_ROSTER.tsv 형식, 비밀키 노출, 문서 생성을 먼저 해결한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ExportFeedbackToCommercialQualityScorecard.ps1") -Parameters @{
        FeedbackRoot = (Join-Path $EvidenceRoot "Playtest")
        OutputPath = (Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv")
        SummaryPath = (Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD_DRAFT.md")
    }
}
catch {
    Add-Gate -Area "상업 품질" -Gate "피드백 기반 점수표 초안 생성" -Status "차단" -Evidence $_.Exception.Message -NextAction "피드백 export의 비밀키, JSON 형식, 파일 접근 오류를 해결한다."
}

try {
    $smokeFeedbackRoot = Join-Path $buildRoot "release-smoke\playtest-feedback-files"
    if (Test-Path -LiteralPath $smokeFeedbackRoot) {
        Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ExportFeedbackToCommercialQualityScorecard.ps1") -Parameters @{
            FeedbackRoot = $smokeFeedbackRoot
            OutputPath = (Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD_DRAFT_SMOKE_SAMPLE.tsv")
            SummaryPath = (Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD_DRAFT_SMOKE_SAMPLE.md")
            RequireInput = $true
        }
    }
}
catch {
    Add-Gate -Area "상업 품질" -Gate "내부 스모크 점수표 초안 샘플" -Status "보류" -Evidence $_.Exception.Message -NextAction "RunReleaseSmoke.ps1 -AllowUnityWindows로 최신 feedback export를 만든 뒤 샘플 초안을 다시 생성한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ValidateCommercialQualityRubric.ps1") -Parameters @{
        OutputPath = $commercialQualityPath
    }
}
catch {
    Add-Gate -Area "상업 품질" -Gate "$priceTargetLabel 품질 루브릭 QA 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "상업 품질 점수표의 비밀키, 형식 오류, 파일 접근 오류를 해결한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "WriteReleaseReadinessReport.ps1") -Parameters @{
        ReleasePackageRoot = $ReleasePackageRoot
        SteamSubmissionPackageRoot = $SteamSubmissionPackageRoot
        SteamworksStagingPackageRoot = $SteamworksStagingPackageRoot
        ExternalPlaytestPackageRoot = $ExternalPlaytestPackageRoot
        CommercialReviewPackageRoot = $CommercialReviewPackageRoot
        OutputPath = $releaseReportPath
    }
}
catch {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "빌드, 패키지, 자동 QA 실패를 고친 뒤 다시 실행한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "WriteInternalQualityScorecard.ps1")
}
catch {
    Add-Gate -Area "내부 품질" -Gate "내부 품질 점수표 생성" -Status "차단" -Evidence $_.Exception.Message -NextAction "내부 품질 점수표 생성 오류를 해결한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "WriteCommercialLaunchDecision.ps1") -Parameters @{
        OutputPath = $commercialDecisionPath
        ReleaseReadinessReportPath = $releaseReportPath
        ExternalEvidenceAuditPath = $externalAuditPath
        PlaytestEvidenceSummaryPath = $playtestSummaryPath
        ExternalIssueRegisterQaPath = $issueQaPath
        CommercialQualityReviewQaPath = $commercialQualityPath
        PriceTargetUsd = $PriceTargetUsd
    }
}
catch {
    Add-Gate -Area "상업 판정" -Gate "상업 출시 결정 생성" -Status "차단" -Evidence $_.Exception.Message -NextAction "선행 보고서 생성 오류를 해결한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "ValidateSteamMarketComparison.ps1") -Parameters @{
        OutputPath = $steamMarketQaPath
        PriceTargetUsd = $PriceTargetUsd
    }
}
catch {
    Add-Gate -Area "시장 비교" -Gate "Steam 유사작 비교 QA 실행" -Status "차단" -Evidence $_.Exception.Message -NextAction "Steam 시장 비교 캐시의 형식, 가격, 출처를 수정한다."
}

try {
    Invoke-ReportScript -ScriptPath (Join-Path $PSScriptRoot "WriteCommercialPricePositioning.ps1") -Parameters @{
        PriceTargetUsd = $PriceTargetUsd
    }
}
catch {
    Add-Gate -Area "가격 포지셔닝" -Gate "$priceTargetLabel 가격 포지셔닝 보고서 생성" -Status "차단" -Evidence $_.Exception.Message -NextAction "가격 포지셔닝 보고서 생성 오류를 해결한다."
}

$releaseText = Read-Report -Path $releaseReportPath
$externalText = Read-Report -Path $externalAuditPath
$playtestText = Read-Report -Path $playtestSummaryPath
$issueText = Read-Report -Path $issueQaPath
$reviewerRosterText = Read-Report -Path $reviewerRosterQaPath
$commercialQualityText = Read-Report -Path $commercialQualityPath
$commercialText = Read-Report -Path $commercialDecisionPath
$priceText = Read-Report -Path $commercialPricePath
$marketText = Read-Report -Path $steamMarketQaPath

$autoFailed = Get-ReportNumber -Text $releaseText -Label "자동 실패"
$pending = Get-ReportNumber -Text $releaseText -Label "보류"
$externalIncompleteInRelease = Get-ReportNumber -Text $releaseText -Label "외부 검증 미완료"
if ($releaseText -eq "") {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "차단" -Evidence "RELEASE_READINESS_REPORT.md 누락" -NextAction "WriteReleaseReadinessReport.ps1를 통과시킨다."
}
elseif ($autoFailed -eq 0 -and $pending -eq 0) {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "통과" -Evidence "자동 실패 $autoFailed, 보류 $pending, 외부 미완료 $externalIncompleteInRelease"
}
elseif ($autoFailed -eq 0) {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "보류" -Evidence "자동 실패 $autoFailed, 보류 $pending" -NextAction "Unity 런타임 동기화, 최신 접근성 캡처, 최신 피드백 export 증거를 갱신한다."
}
else {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "차단" -Evidence "자동 실패 $autoFailed, 보류 $pending" -NextAction "릴리즈 감사 보고서의 실패/보류 항목을 해결한다."
}

$externalIncomplete = Get-ReportNumber -Text $externalText -Label "미완료"
$externalFailed = Get-ReportNumber -Text $externalText -Label "실패"
if ($externalText -eq "") {
    Add-Gate -Area "외부 증거" -Gate "외부 증거 전체" -Status "차단" -Evidence "EXTERNAL_EVIDENCE_AUDIT.md 누락" -NextAction "ValidateExternalEvidence.ps1를 실행한다."
}
elseif ($externalFailed -gt 0) {
    Add-Gate -Area "외부 증거" -Gate "외부 증거 전체" -Status "차단" -Evidence "실패 $externalFailed" -NextAction "외부 증거 폴더의 비밀키나 형식 오류를 제거한다."
}
elseif ($externalIncomplete -gt 0) {
    Add-Gate -Area "외부 증거" -Gate "외부 증거 전체" -Status "보류" -Evidence "미완료 $externalIncomplete" -NextAction "Playtest, Accessibility, ArtReview, Trailer, LegalSteam 증거를 채운다."
}
else {
    Add-Gate -Area "외부 증거" -Gate "외부 증거 전체" -Status "통과" -Evidence "미완료 0, 실패 0"
}

$completeSessionMatch = [regex]::Match($playtestText, "-\s*완성 세션:\s*(\d+)/(\d+)")
$completeSessions = if ($completeSessionMatch.Success) { [int]$completeSessionMatch.Groups[1].Value } else { -1 }
$requiredSessions = if ($completeSessionMatch.Success) { [int]$completeSessionMatch.Groups[2].Value } else { -1 }
$p0 = Get-ReportNumber -Text $playtestText -Label "P0"
$p1 = Get-ReportNumber -Text $playtestText -Label "P1"
$secretCount = Get-ReportNumber -Text $playtestText -Label "비밀키 패턴"
if ($playtestText -eq "") {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션" -Status "차단" -Evidence "PLAYTEST_EVIDENCE_SUMMARY.md 누락" -NextAction "SummarizePlaytestEvidence.ps1를 실행한다."
}
elseif ($secretCount -gt 0) {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션" -Status "차단" -Evidence "비밀키 패턴 $secretCount" -NextAction "플레이테스트 증거에서 비밀키 형태 문자열을 제거한다."
}
elseif ($p0 -gt 0 -or $p1 -gt 0) {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션" -Status "차단" -Evidence "P0 $p0, P1 $p1" -NextAction "P0/P1 이슈를 수정하고 verified 증거를 남긴다."
}
elseif ($completeSessions -lt $requiredSessions -or $requiredSessions -le 0) {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션" -Status "보류" -Evidence "완성 $completeSessions/$requiredSessions" -NextAction "외부 참가자 5명 이상의 5문답 세션 증거를 수집한다."
}
else {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션" -Status "통과" -Evidence "완성 $completeSessions/$requiredSessions, P0 $p0, P1 $p1"
}

$qualityStatusMatch = [regex]::Match($commercialQualityText, "-\s*상태:\s*([^\r\n]+)")
$qualityStatus = if ($qualityStatusMatch.Success) { $qualityStatusMatch.Groups[1].Value.Trim() } else { "증거 없음" }
$qualityIssues = Get-ReportNumber -Text $commercialQualityText -Label "문제"
$qualityBlockers = Get-ReportNumber -Text $commercialQualityText -Label "차단 항목"
$qualityAverageMatch = [regex]::Match($commercialQualityText, "-\s*평균 점수:\s*([0-9.]+)")
$qualityAverage = if ($qualityAverageMatch.Success) { $qualityAverageMatch.Groups[1].Value } else { "0" }
if ($commercialQualityText -eq "") {
    Add-Gate -Area "상업 품질" -Gate "$priceTargetLabel 품질 루브릭" -Status "차단" -Evidence "COMMERCIAL_QUALITY_REVIEW_QA.md 누락" -NextAction "ValidateCommercialQualityRubric.ps1를 실행한다."
}
elseif ($qualityStatus -eq "완료" -and $qualityIssues -eq 0 -and $qualityBlockers -eq 0) {
    Add-Gate -Area "상업 품질" -Gate "$priceTargetLabel 품질 루브릭" -Status "통과" -Evidence "상태 $qualityStatus, 평균 $qualityAverage, 문제 $qualityIssues"
}
else {
    Add-Gate -Area "상업 품질" -Gate "$priceTargetLabel 품질 루브릭" -Status "보류" -Evidence "상태 $qualityStatus, 평균 $qualityAverage, 문제 $qualityIssues, 차단 $qualityBlockers" -NextAction "외부 리뷰 점수표를 채우고 평균 4.0 이상, 최저 3 이상, 차단 0을 만든다."
}

$issueStatusMatch = [regex]::Match($issueText, "-\s*상태:\s*([^\r\n]+)")
$issueStatus = if ($issueStatusMatch.Success) { $issueStatusMatch.Groups[1].Value.Trim() } else { "증거 없음" }
$openP0P1 = Get-ReportNumber -Text $issueText -Label "미검증 P0/P1"
$openP2 = Get-ReportNumber -Text $issueText -Label "미해결 P2"
$issueFormatFailures = Get-ReportNumber -Text $issueText -Label "형식 실패"
$issueSecretCount = Get-ReportNumber -Text $issueText -Label "비밀키 패턴"
if ($issueText -eq "") {
    Add-Gate -Area "외부 이슈" -Gate "외부 이슈 폐쇄" -Status "차단" -Evidence "EXTERNAL_ISSUE_REGISTER_QA.md 누락" -NextAction "ValidateExternalIssueRegister.ps1를 실행한다."
}
elseif ($issueFormatFailures -gt 0 -or $issueSecretCount -gt 0) {
    Add-Gate -Area "외부 이슈" -Gate "외부 이슈 폐쇄" -Status "차단" -Evidence "형식 실패 $issueFormatFailures, 비밀키 $issueSecretCount" -NextAction "외부 이슈 레지스터 형식과 비밀키 노출을 수정한다."
}
elseif ($openP0P1 -gt 0) {
    Add-Gate -Area "외부 이슈" -Gate "외부 이슈 폐쇄" -Status "차단" -Evidence "미검증 P0/P1 $openP0P1" -NextAction "P0/P1 이슈를 verified 상태로 닫는다."
}
elseif ($openP2 -gt 0 -or $issueStatus -ne "완료") {
    Add-Gate -Area "외부 이슈" -Gate "외부 이슈 폐쇄" -Status "보류" -Evidence "상태 $issueStatus, 미해결 P2 $openP2" -NextAction "외부 리뷰 이슈를 등록하고 P2 이상을 해결 또는 수용 위험으로 정리한다."
}
else {
    Add-Gate -Area "외부 이슈" -Gate "외부 이슈 폐쇄" -Status "통과" -Evidence "상태 완료, 미검증 P0/P1 0, 미해결 P2 0"
}

$rosterStatus = Get-ReportValue -Text $reviewerRosterText -Label "상태"
$rosterBlocked = Get-ReportNumber -Text $reviewerRosterText -Label "차단"
$rosterReadyMatch = [regex]::Match($reviewerRosterText, "-\s*준비 항목:\s*(\d+)/(\d+)")
$rosterReady = if ($rosterReadyMatch.Success) { [int]$rosterReadyMatch.Groups[1].Value } else { -1 }
$rosterRequired = if ($rosterReadyMatch.Success) { [int]$rosterReadyMatch.Groups[2].Value } else { -1 }
if ($reviewerRosterText -eq "") {
    Add-Gate -Area "외부 리뷰어" -Gate "리뷰어 배정" -Status "차단" -Evidence "EXTERNAL_REVIEWER_ROSTER_QA.md 누락" -NextAction "WriteExternalReviewerRosterTemplate.ps1와 ValidateExternalReviewerRoster.ps1를 실행한다."
}
elseif ($rosterStatus -eq "차단" -or $rosterBlocked -gt 0) {
    Add-Gate -Area "외부 리뷰어" -Gate "리뷰어 배정" -Status "차단" -Evidence "상태 $rosterStatus, 차단 $rosterBlocked, 준비 $rosterReady/$rosterRequired" -NextAction "명단 TSV의 형식 오류와 비밀키 노출을 수정한다."
}
elseif ($rosterStatus -ne "완료" -or $rosterReady -lt $rosterRequired -or $rosterRequired -le 0) {
    Add-Gate -Area "외부 리뷰어" -Gate "리뷰어 배정" -Status "보류" -Evidence "준비 $rosterReady/$rosterRequired" -NextAction "EXTERNAL_REVIEWER_ROSTER.tsv에 reviewer_alias, contact_method, due_at을 채우고 ApplyExternalReviewerRoster.ps1를 실행한다."
}
else {
    Add-Gate -Area "외부 리뷰어" -Gate "리뷰어 배정" -Status "통과" -Evidence "준비 $rosterReady/$rosterRequired"
}

$marketStatus = Get-ReportValue -Text $marketText -Label "상태"
$marketRows = Get-ReportNumber -Text $marketText -Label "비교작 수"
$marketBlockers = Get-ReportNumber -Text $marketText -Label "차단"
$marketHolds = Get-ReportNumber -Text $marketText -Label "보류"
if ($marketText -eq "") {
    Add-Gate -Area "시장 비교" -Gate "Steam 유사작 가격/태그/리뷰 톤" -Status "차단" -Evidence "STEAM_MARKET_COMPARISON_QA.md 누락" -NextAction "WriteSteamMarketComparison.ps1와 ValidateSteamMarketComparison.ps1를 실행한다."
}
elseif ($marketStatus -eq "완료" -and $marketRows -ge 5 -and $marketBlockers -eq 0 -and $marketHolds -eq 0) {
    Add-Gate -Area "시장 비교" -Gate "Steam 유사작 가격/태그/리뷰 톤" -Status "통과" -Evidence "상태 $marketStatus, 비교작 $marketRows, 차단 $marketBlockers, 보류 $marketHolds"
}
elseif ($marketStatus -eq "차단" -or $marketBlockers -gt 0) {
    Add-Gate -Area "시장 비교" -Gate "Steam 유사작 가격/태그/리뷰 톤" -Status "차단" -Evidence "상태 $marketStatus, 비교작 $marketRows, 차단 $marketBlockers, 보류 $marketHolds" -NextAction "시장 비교 캐시의 차단 항목을 수정한다."
}
else {
    Add-Gate -Area "시장 비교" -Gate "Steam 유사작 가격/태그/리뷰 톤" -Status "보류" -Evidence "상태 $marketStatus, 비교작 $marketRows, 차단 $marketBlockers, 보류 $marketHolds" -NextAction "Steam 유사작 5개 이상 가격/태그/리뷰 톤 비교를 최신화한다."
}

$priceStatus = Get-ReportValue -Text $priceText -Label "상태"
$priceHeld = Get-ReportNumber -Text $priceText -Label "보류"
$priceBlocked = Get-ReportNumber -Text $priceText -Label "차단"
if ($priceText -eq "") {
    Add-Gate -Area "가격 포지셔닝" -Gate "$priceTargetLabel 이상 가격 근거" -Status "차단" -Evidence "COMMERCIAL_PRICE_POSITIONING.md 누락" -NextAction "WriteCommercialPricePositioning.ps1를 실행한다."
}
elseif ($priceStatus -eq "통과" -and $priceBlocked -eq 0 -and $priceHeld -eq 0) {
    Add-Gate -Area "가격 포지셔닝" -Gate "$priceTargetLabel 이상 가격 근거" -Status "통과" -Evidence "상태 $priceStatus, 보류 $priceHeld, 차단 $priceBlocked"
}
elseif ($priceStatus -eq "차단" -or $priceBlocked -gt 0) {
    Add-Gate -Area "가격 포지셔닝" -Gate "$priceTargetLabel 이상 가격 근거" -Status "차단" -Evidence "상태 $priceStatus, 보류 $priceHeld, 차단 $priceBlocked" -NextAction "가격 포지셔닝 차단 항목을 먼저 수정한다."
}
else {
    Add-Gate -Area "가격 포지셔닝" -Gate "$priceTargetLabel 이상 가격 근거" -Status "보류" -Evidence "상태 $priceStatus, 보류 $priceHeld, 차단 $priceBlocked" -NextAction "외부 증거, 공식 품질 점수표, 최신 Steam 유사작 가격 비교를 채운다."
}

$storeSubmissionReady = Test-ReportLine -Text $commercialText -Label "Steam 상점 제출 자료" -Expected "준비됨"
$launchReady = Test-ReportLine -Text $commercialText -Label "$priceTargetLabel 이상 최종 출시 후보" -Expected "통과"
$commercialDecisionBlocked = (Get-ReportNumber -Text $commercialText -Label "차단 게이트") -gt 0
if ($commercialText -eq "") {
    Add-Gate -Area "상업 판정" -Gate "상업 출시 결정" -Status "차단" -Evidence "COMMERCIAL_LAUNCH_DECISION.md 누락" -NextAction "WriteCommercialLaunchDecision.ps1를 실행한다."
}
elseif (-not $storeSubmissionReady -and $commercialDecisionBlocked) {
    Add-Gate -Area "상업 판정" -Gate "상업 출시 결정" -Status "차단" -Evidence "Steam 상점 제출 자료 미준비" -NextAction "패키지와 상점 자산 게이트를 먼저 통과시킨다."
}
elseif (-not $storeSubmissionReady) {
    Add-Gate -Area "상업 판정" -Gate "상업 출시 결정" -Status "보류" -Evidence "Steam 상점 제출 자료 보류" -NextAction "Unity 런타임 동기화와 외부 증거를 갱신한 뒤 상점 제출 판정을 다시 확인한다."
}
elseif (-not $launchReady) {
    Add-Gate -Area "상업 판정" -Gate "상업 출시 결정" -Status "보류" -Evidence "Steam 제출 준비, 최종 출시 후보 보류" -NextAction "외부 증거와 외부 이슈 폐쇄 게이트를 통과시킨다."
}
else {
    Add-Gate -Area "상업 판정" -Gate "상업 출시 결정" -Status "통과" -Evidence "Steam 제출 준비, $priceTargetLabel 이상 출시 후보 통과"
}

$blocked = @($gates | Where-Object { $_.Status -eq "차단" }).Count
$held = @($gates | Where-Object { $_.Status -eq "보류" }).Count
$passed = @($gates | Where-Object { $_.Status -eq "통과" }).Count
$finalStatus = if ($blocked -gt 0) { "차단" } elseif ($held -gt 0) { "보류" } else { "통과" }
$storeSubmissionText = if ($storeSubmissionReady) { "준비됨" } else { "보류" }
$launchReadyText = if ($launchReady) { "통과" } else { "보류" }
$finalDecision = if ($finalStatus -eq "통과") {
    "$priceTargetLabel 이상 최종 유료 출시 후보로 볼 수 있다."
}
elseif ($storeSubmissionReady -and $blocked -eq 0) {
    "Steam 상점 제출 자료는 준비됐지만, 외부 증거가 부족해 최종 유료 출시는 보류한다."
}
elseif ($blocked -eq 0) {
    "차단 게이트는 없지만, Unity 런타임 동기화와 외부 증거가 부족해 최종 유료 출시는 보류한다."
}
else {
    "최종 유료 출시 전에 차단 게이트를 먼저 해결해야 한다."
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상업 출시 최종 게이트")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- 최종 판정: $finalStatus")
$lines.Add("- 통과 게이트: $passed")
$lines.Add("- 보류 게이트: $held")
$lines.Add("- 차단 게이트: $blocked")
$lines.Add("- Steam 상점 제출 자료: $storeSubmissionText")
$lines.Add("- $priceTargetLabel 이상 최종 출시 후보: $launchReadyText")
$lines.Add("")
$lines.Add("## 결정")
$lines.Add("")
$lines.Add($finalDecision)
$lines.Add("")
$lines.Add("## 게이트")
$lines.Add("")
$lines.Add("| 영역 | 게이트 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- | --- |")
foreach ($gate in $gates) {
    $lines.Add("| $(Escape-MarkdownCell $gate.Area) | $(Escape-MarkdownCell $gate.Gate) | $(Escape-MarkdownCell $gate.Status) | $(Escape-MarkdownCell $gate.Evidence) | $(Escape-MarkdownCell $gate.NextAction) |")
}

$openActions = @($gates | Where-Object { $_.Status -ne "통과" -and -not [string]::IsNullOrWhiteSpace([string]$_.NextAction) })
$lines.Add("")
$lines.Add("## 남은 조치")
$lines.Add("")
if ($openActions.Count -eq 0) {
    $lines.Add("- 남은 보류/차단 게이트가 없다. Steam 관리자 최종 등록과 배포 일정을 확정한다.")
}
else {
    foreach ($action in $openActions) {
        $lines.Add("- $($action.Area): $($action.NextAction)")
    }
}

$lines.Add("")
$lines.Add("## 검증 명령")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady")
$lines.Add('```')

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Commercial launch gate written: $OutputPath"
Write-Host "Final status: $finalStatus, passed: $passed, held: $held, blocked: $blocked"

$internalQualityScript = Join-Path $PSScriptRoot "WriteInternalQualityScorecard.ps1"
if (Test-Path -LiteralPath $internalQualityScript) {
    & $internalQualityScript 2>&1 | Out-Null
}

$internalReviewScript = Join-Path $PSScriptRoot "WriteInternalCommercialReview.ps1"
if (Test-Path -LiteralPath $internalReviewScript) {
    & $internalReviewScript 2>&1 | Out-Null
}

$prepareEvidenceScript = Join-Path $PSScriptRoot "PrepareCommercialEvidenceWorkspace.ps1"
if (Test-Path -LiteralPath $prepareEvidenceScript) {
    & $prepareEvidenceScript -EvidenceRoot $EvidenceRoot -Force 2>&1 | Out-Null
}

$externalReviewBriefsValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewBriefs.ps1"
if (Test-Path -LiteralPath $externalReviewBriefsValidationScript) {
    & $externalReviewBriefsValidationScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$externalReviewTrackerValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewTracker.ps1"
if (Test-Path -LiteralPath $externalReviewTrackerValidationScript) {
    & $externalReviewTrackerValidationScript -TrackerPath (Join-Path $EvidenceRoot "EXTERNAL_REVIEW_TRACKER.tsv") 2>&1 | Out-Null
}

$sprintPlanScript = Join-Path $PSScriptRoot "WriteCommercialSprintPlan.ps1"
if (Test-Path -LiteralPath $sprintPlanScript) {
    & $sprintPlanScript 2>&1 | Out-Null
}

$pricePositioningScript = Join-Path $PSScriptRoot "WriteCommercialPricePositioning.ps1"
if (Test-Path -LiteralPath $pricePositioningScript) {
    & $pricePositioningScript -PriceTargetUsd $PriceTargetUsd 2>&1 | Out-Null
}

if ($RequireLaunchReady -and $finalStatus -ne "통과") {
    throw "Commercial launch gate is not ready for final paid release: $finalStatus"
}


