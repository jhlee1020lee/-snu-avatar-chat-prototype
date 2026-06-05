param(
    [string]$OutputPath,
    [string]$ReleaseReadinessReportPath,
    [string]$ExternalEvidenceAuditPath,
    [string]$PlaytestEvidenceSummaryPath,
    [string]$ExternalIssueRegisterQaPath,
    [string]$SteamLegalReadinessQaPath,
    [string]$CommercialQualityReviewQaPath,
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
            return Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        }
        catch {
            if ($attempt -eq 8) {
                throw
            }
            Start-Sleep -Milliseconds (100 * $attempt)
        }
    }

    return ""
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

function Test-ReportRowPassed {
    param(
        [string]$Text,
        [string]$Item
    )

    $pattern = "\|\s*[^|]*\|\s*$([regex]::Escape($Item))\s*\|\s*통과\s*\|"
    return [regex]::IsMatch($Text, $pattern)
}

function Get-PlaytestMetric {
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

function Get-PlaytestCompletion {
    param([string]$Text)

    $match = [regex]::Match($Text, "-\s*완성 세션:\s*(\d+)/(\d+)")
    if ($match.Success) {
        return [pscustomobject]@{
            Complete = [int]$match.Groups[1].Value
            Required = [int]$match.Groups[2].Value
        }
    }

    return [pscustomobject]@{
        Complete = -1
        Required = -1
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "COMMERCIAL_LAUNCH_DECISION.md"
}
if ([string]::IsNullOrWhiteSpace($ReleaseReadinessReportPath)) {
    $ReleaseReadinessReportPath = Join-Path $docsRoot "RELEASE_READINESS_REPORT.md"
}
if ([string]::IsNullOrWhiteSpace($ExternalEvidenceAuditPath)) {
    $ExternalEvidenceAuditPath = Join-Path $docsRoot "EXTERNAL_EVIDENCE_AUDIT.md"
}
if ([string]::IsNullOrWhiteSpace($PlaytestEvidenceSummaryPath)) {
    $PlaytestEvidenceSummaryPath = Join-Path $docsRoot "PLAYTEST_EVIDENCE_SUMMARY.md"
}
if ([string]::IsNullOrWhiteSpace($ExternalIssueRegisterQaPath)) {
    $ExternalIssueRegisterQaPath = Join-Path $docsRoot "EXTERNAL_ISSUE_REGISTER_QA.md"
}
if ([string]::IsNullOrWhiteSpace($SteamLegalReadinessQaPath)) {
    $SteamLegalReadinessQaPath = Join-Path $docsRoot "STEAM_LEGAL_READINESS_QA.md"
}
if ([string]::IsNullOrWhiteSpace($CommercialQualityReviewQaPath)) {
    $CommercialQualityReviewQaPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_REVIEW_QA.md"
}

$externalAuditScript = Join-Path $PSScriptRoot "ValidateExternalEvidence.ps1"
$playtestSummaryScript = Join-Path $PSScriptRoot "SummarizePlaytestEvidence.ps1"
$issueRegisterScript = Join-Path $PSScriptRoot "ValidateExternalIssueRegister.ps1"
$steamLegalScript = Join-Path $PSScriptRoot "ValidateSteamLegalReadiness.ps1"
$commercialQualityScript = Join-Path $PSScriptRoot "ValidateCommercialQualityRubric.ps1"

if (Test-Path -LiteralPath $externalAuditScript) {
    & $externalAuditScript 2>&1 | Out-Null
}
if (Test-Path -LiteralPath $playtestSummaryScript) {
    & $playtestSummaryScript 2>&1 | Out-Null
}
if (Test-Path -LiteralPath $issueRegisterScript) {
    & $issueRegisterScript 2>&1 | Out-Null
}
if (Test-Path -LiteralPath $steamLegalScript) {
    & $steamLegalScript 2>&1 | Out-Null
}
if (Test-Path -LiteralPath $commercialQualityScript) {
    & $commercialQualityScript 2>&1 | Out-Null
}

$releaseText = Read-Report -Path $ReleaseReadinessReportPath
$externalText = Read-Report -Path $ExternalEvidenceAuditPath
$playtestText = Read-Report -Path $PlaytestEvidenceSummaryPath
$issueRegisterText = Read-Report -Path $ExternalIssueRegisterQaPath
$steamLegalText = Read-Report -Path $SteamLegalReadinessQaPath
$commercialQualityText = Read-Report -Path $CommercialQualityReviewQaPath

$gates = New-Object System.Collections.Generic.List[object]
$priceTargetLabel = "$PriceTargetUsd" + "달러"

$autoPassed = Get-ReportNumber -Text $releaseText -Label "자동 통과"
$autoFailed = Get-ReportNumber -Text $releaseText -Label "자동 실패"
$pending = Get-ReportNumber -Text $releaseText -Label "보류"
$externalIncompleteInRelease = Get-ReportNumber -Text $releaseText -Label "외부 검증 미완료"
$automatedReady = $autoFailed -eq 0 -and $pending -eq 0 -and $autoPassed -gt 0
if ($automatedReady) {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "통과" -Evidence "통과 $autoPassed, 실패 $autoFailed, 보류 $pending"
}
elseif ($autoFailed -eq 0 -and $autoPassed -gt 0) {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "보류" -Evidence "통과 $autoPassed, 실패 $autoFailed, 보류 $pending" -NextAction "Unity 런타임 동기화, 최신 접근성 캡처, 최신 피드백 export 증거를 갱신한다."
}
else {
    Add-Gate -Area "자동 QA" -Gate "릴리즈 감사" -Status "차단" -Evidence "통과 $autoPassed, 실패 $autoFailed, 보류 $pending" -NextAction "RELEASE_READINESS_REPORT.md의 실패/보류 항목을 먼저 해결한다."
}

$packageChecks = @(
    @{ Area = "패키지"; Gate = "Windows 실행 패키지"; Item = "Windows 실행 패키지 검증" },
    @{ Area = "패키지"; Gate = "패키지 서버 실행"; Item = "패키지 서버 실행 QA" },
    @{ Area = "상점"; Gate = "Steam 제출 패키지"; Item = "Steam 제출 패키지 검증" },
    @{ Area = "Steamworks"; Gate = "SteamPipe 스테이징"; Item = "SteamPipe 스테이징 패키지 검증" },
    @{ Area = "상업 검토"; Gate = "상업 검토 패키지"; Item = "상업 검토 패키지 검증" },
    @{ Area = "외부 검증 운영"; Gate = "외부 플레이테스트 패키지"; Item = "외부 플레이테스트 패키지 검증" }
)

foreach ($check in $packageChecks) {
    if (Test-ReportRowPassed -Text $releaseText -Item $check.Item) {
        Add-Gate -Area $check.Area -Gate $check.Gate -Status "통과" -Evidence "$($check.Item) 통과"
    }
    else {
        Add-Gate -Area $check.Area -Gate $check.Gate -Status "차단" -Evidence "$($check.Item) 통과 근거 없음" -NextAction "패키지를 다시 생성하고 검증 스크립트를 통과시킨다."
    }
}

$steamLegalFailed = Get-ReportNumber -Text $steamLegalText -Label "자동 실패"
if ($steamLegalFailed -eq 0 -and $steamLegalText -ne "") {
    Add-Gate -Area "법무/상점" -Gate "Steam/법무 로컬 준비" -Status "통과" -Evidence "STEAM_LEGAL_READINESS_QA.md 실패 $steamLegalFailed"
}
else {
    Add-Gate -Area "법무/상점" -Gate "Steam/법무 로컬 준비" -Status "차단" -Evidence "STEAM_LEGAL_READINESS_QA.md 실패 $steamLegalFailed" -NextAction "개인정보 초안, 상점 고지, Steamworks 문서와 VDF 템플릿을 보완한다."
}

$externalIncomplete = Get-ReportNumber -Text $externalText -Label "미완료"
$externalFailed = Get-ReportNumber -Text $externalText -Label "실패"
$externalReady = $externalIncomplete -eq 0 -and $externalFailed -eq 0 -and $externalText -ne ""
if ($externalReady) {
    Add-Gate -Area "외부 증거" -Gate "외부 검증 전체" -Status "통과" -Evidence "미완료 $externalIncomplete, 실패 $externalFailed"
}
else {
    Add-Gate -Area "외부 증거" -Gate "외부 검증 전체" -Status "보류" -Evidence "미완료 $externalIncomplete, 실패 $externalFailed" -NextAction "ReleaseEvidence의 Playtest, Accessibility, ArtReview, Trailer, LegalSteam 증거를 채운다."
}

$playtestCompletion = Get-PlaytestCompletion -Text $playtestText
$p0 = Get-PlaytestMetric -Text $playtestText -Label "P0"
$p1 = Get-PlaytestMetric -Text $playtestText -Label "P1"
$secretCount = Get-PlaytestMetric -Text $playtestText -Label "비밀키 패턴"
$playtestReady = $playtestCompletion.Complete -ge $playtestCompletion.Required -and $playtestCompletion.Required -gt 0 -and $p0 -eq 0 -and $p1 -eq 0 -and $secretCount -eq 0
if ($playtestReady) {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션과 P0/P1 없음" -Status "통과" -Evidence "완성 $($playtestCompletion.Complete)/$($playtestCompletion.Required), P0 $p0, P1 $p1"
}
else {
    Add-Gate -Area "외부 플레이테스트" -Gate "5명 이상 완성 세션과 P0/P1 없음" -Status "보류" -Evidence "완성 $($playtestCompletion.Complete)/$($playtestCompletion.Required), P0 $p0, P1 $p1, 비밀키 $secretCount" -NextAction "외부 참가자 5명 세션을 수집하고 P0/P1 이슈가 있으면 수정 후 재검증한다."
}

$qualityStatusMatch = [regex]::Match($commercialQualityText, "-\s*상태:\s*([^\r\n]+)")
$qualityStatus = if ($qualityStatusMatch.Success) { $qualityStatusMatch.Groups[1].Value.Trim() } else { "증거 없음" }
$qualityIssues = Get-ReportNumber -Text $commercialQualityText -Label "문제"
$qualityBlockers = Get-ReportNumber -Text $commercialQualityText -Label "차단 항목"
$qualityAverageMatch = [regex]::Match($commercialQualityText, "-\s*평균 점수:\s*([0-9.]+)")
$qualityAverage = if ($qualityAverageMatch.Success) { $qualityAverageMatch.Groups[1].Value } else { "0" }
$qualityReady = $qualityStatus -eq "완료" -and $qualityIssues -eq 0 -and $qualityBlockers -eq 0
if ($qualityReady) {
    Add-Gate -Area "상업 품질" -Gate "$priceTargetLabel 품질 루브릭" -Status "통과" -Evidence "상태 $qualityStatus, 평균 $qualityAverage, 문제 $qualityIssues"
}
else {
    Add-Gate -Area "상업 품질" -Gate "$priceTargetLabel 품질 루브릭" -Status "보류" -Evidence "상태 $qualityStatus, 평균 $qualityAverage, 문제 $qualityIssues, 차단 $qualityBlockers" -NextAction "COMMERCIAL_QUALITY_SCORECARD.tsv를 외부 리뷰 증거로 채우고 평균 4.0 이상, 최저 3 이상, 차단 0을 만든다."
}

$issueStatusMatch = [regex]::Match($issueRegisterText, "-\s*상태:\s*([^\r\n]+)")
$issueStatus = if ($issueStatusMatch.Success) { $issueStatusMatch.Groups[1].Value.Trim() } else { "증거 없음" }
$openP0P1 = Get-ReportNumber -Text $issueRegisterText -Label "미검증 P0/P1"
$openP2 = Get-ReportNumber -Text $issueRegisterText -Label "미해결 P2"
$issueFormatFailures = Get-ReportNumber -Text $issueRegisterText -Label "형식 실패"
$issueSecretCount = Get-ReportNumber -Text $issueRegisterText -Label "비밀키 패턴"
$issueClosureReady = $issueStatus -eq "완료" -and $openP0P1 -eq 0 -and $openP2 -eq 0 -and $issueFormatFailures -eq 0 -and $issueSecretCount -eq 0
if ($issueClosureReady) {
    Add-Gate -Area "외부 이슈" -Gate "외부 리뷰 이슈 폐쇄" -Status "통과" -Evidence "상태 $issueStatus, 미검증 P0/P1 $openP0P1, 미해결 P2 $openP2"
}
else {
    Add-Gate -Area "외부 이슈" -Gate "외부 리뷰 이슈 폐쇄" -Status "보류" -Evidence "상태 $issueStatus, 미검증 P0/P1 $openP0P1, 미해결 P2 $openP2, 형식 실패 $issueFormatFailures" -NextAction "EXTERNAL_ISSUE_REGISTER.tsv에 외부 리뷰 이슈와 수정/검증 결과를 기록한다."
}

$blocking = @($gates | Where-Object { $_.Status -eq "차단" }).Count
$held = @($gates | Where-Object { $_.Status -eq "보류" }).Count
$passed = @($gates | Where-Object { $_.Status -eq "통과" }).Count
$storeSubmissionAutomatedReady = $autoFailed -eq 0 -and $autoPassed -gt 0
$storeSubmissionReady = $storeSubmissionAutomatedReady -and $steamLegalFailed -eq 0 -and
    (Test-ReportRowPassed -Text $releaseText -Item "Steam 제출 패키지 검증") -and
    (Test-ReportRowPassed -Text $releaseText -Item "SteamPipe 스테이징 패키지 검증") -and
    $blocking -eq 0
$launchReady = $storeSubmissionReady -and $externalReady -and $playtestReady -and $qualityReady -and $issueClosureReady -and $externalIncompleteInRelease -eq 0

$storeStatus = if ($storeSubmissionReady) { "준비됨" } else { "보류" }
$launchStatus = if ($launchReady) { "통과" } else { "보류" }
$decision = if ($launchReady) {
    "$priceTargetLabel 이상 최종 유료 출시 후보로 볼 수 있다."
}
elseif ($storeSubmissionReady) {
    "Steam 상점 제출 자료는 준비됐지만, 외부 검증 증거가 부족해 $priceTargetLabel 이상 최종 유료 출시는 보류한다."
}
else {
    "자동 QA 또는 패키지 게이트가 남아 있어 Steam 상점 제출 전 단계로 보류한다."
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상업 출시 결정 보고서")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- Steam 상점 제출 자료: $storeStatus")
$lines.Add("- $priceTargetLabel 이상 최종 출시 후보: $launchStatus")
$lines.Add("- 통과 게이트: $passed")
$lines.Add("- 보류 게이트: $held")
$lines.Add("- 차단 게이트: $blocking")
$lines.Add("")
$lines.Add("## 결정")
$lines.Add("")
$lines.Add($decision)
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
$lines.Add("## 다음 회의 안건")
$lines.Add("")
if ($openActions.Count -eq 0) {
    $lines.Add("- 남은 보류/차단 게이트가 없다. 최종 스토어 등록과 배포 일정을 확정한다.")
}
else {
    foreach ($action in $openActions) {
        $lines.Add("- $($action.Area): $($action.NextAction)")
    }
}

$lines.Add("")
$lines.Add("## 판정 원칙")
$lines.Add("")
$lines.Add("- 자동 감사와 패키지 검증은 상점 제출 준비의 기본 조건이다.")
$lines.Add("- 외부 플레이테스트, 실제 접근성 QA, 외부 아트 리뷰, 최종 트레일러, Steam 관리자/법무 증거, $priceTargetLabel 품질 루브릭 완료 증거가 없으면 최종 유료 출시 후보로 완료 처리하지 않는다.")
$lines.Add("- P0/P1 이슈가 verified로 닫히지 않았거나 비밀키 형태 문자열이 발견되면 가격과 무관하게 출시 차단으로 본다.")

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Commercial launch decision written: $OutputPath"
Write-Host "Store submission: $storeStatus, launch candidate: $launchStatus"

if ($RequireLaunchReady -and -not $launchReady) {
    throw "Commercial launch decision is not ready for final paid release."
}
