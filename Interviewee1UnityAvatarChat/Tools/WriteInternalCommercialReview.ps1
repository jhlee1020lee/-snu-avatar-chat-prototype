param(
    [string]$OutputPath,
    [string]$BacklogPath,
    [string]$ReleaseReadinessReportPath,
    [string]$ExternalEvidenceAuditPath,
    [string]$PlaytestEvidenceSummaryPath,
    [string]$ExternalIssueRegisterQaPath,
    [string]$CommercialQualityReviewQaPath,
    [string]$CommercialLaunchGatePath,
    [string]$InternalQualityReviewPath,
    [string]$InternalQualityScorecardPath,
    [decimal]$PriceTargetUsd = 5
)

$ErrorActionPreference = "Stop"

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Format-TsvCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
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

function Test-ReportContainsRow {
    param(
        [string]$Text,
        [string]$Area,
        [string]$Item,
        [string]$Status
    )

    $pattern = "\|\s*$([regex]::Escape($Area))\s*\|\s*$([regex]::Escape($Item))\s*\|\s*$([regex]::Escape($Status))\s*\|"
    return [regex]::IsMatch($Text, $pattern)
}

function Add-Backlog {
    param(
        [string]$Id,
        [string]$Priority,
        [string]$Owner,
        [string]$Area,
        [string]$Status,
        [string]$Evidence,
        [string]$NextAction,
        [string]$ExitCriteria
    )

    $script:backlog.Add([pscustomobject]@{
        id = $Id
        priority = $Priority
        owner = $Owner
        area = $Area
        status = $Status
        evidence = $Evidence
        next_action = $NextAction
        exit_criteria = $ExitCriteria
    }) | Out-Null
}

function Add-Decision {
    param(
        [string]$Role,
        [string]$Decision,
        [string]$Evidence,
        [string]$Action
    )

    $script:decisions.Add([pscustomobject]@{
        role = $Role
        decision = $Decision
        evidence = $Evidence
        action = $Action
    }) | Out-Null
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
        $tempPath = "$Path.tmp-$PID-$attempt"
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

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "INTERNAL_COMMERCIAL_REVIEW.md"
}
if ([string]::IsNullOrWhiteSpace($BacklogPath)) {
    $BacklogPath = Join-Path $docsRoot "INTERNAL_COMMERCIAL_BACKLOG.tsv"
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
if ([string]::IsNullOrWhiteSpace($CommercialQualityReviewQaPath)) {
    $CommercialQualityReviewQaPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_REVIEW_QA.md"
}
if ([string]::IsNullOrWhiteSpace($CommercialLaunchGatePath)) {
    $CommercialLaunchGatePath = Join-Path $docsRoot "COMMERCIAL_LAUNCH_GATE.md"
}
if ([string]::IsNullOrWhiteSpace($InternalQualityReviewPath)) {
    $InternalQualityReviewPath = Join-Path $docsRoot "INTERNAL_QUALITY_REVIEW.md"
}
if ([string]::IsNullOrWhiteSpace($InternalQualityScorecardPath)) {
    $InternalQualityScorecardPath = Join-Path $docsRoot "INTERNAL_QUALITY_SCORECARD.tsv"
}

$releaseText = Read-Report -Path $ReleaseReadinessReportPath
$externalText = Read-Report -Path $ExternalEvidenceAuditPath
$playtestText = Read-Report -Path $PlaytestEvidenceSummaryPath
$issueText = Read-Report -Path $ExternalIssueRegisterQaPath
$qualityText = Read-Report -Path $CommercialQualityReviewQaPath
$gateText = Read-Report -Path $CommercialLaunchGatePath
$priceTargetLabel = "$PriceTargetUsd" + "달러"
$internalQualityText = Read-Report -Path $InternalQualityReviewPath

$autoPassed = Get-ReportNumber -Text $releaseText -Label "자동 통과"
$autoFailed = Get-ReportNumber -Text $releaseText -Label "자동 실패"
$pending = Get-ReportNumber -Text $releaseText -Label "보류"
$externalIncomplete = Get-ReportNumber -Text $externalText -Label "미완료"
$externalFailed = Get-ReportNumber -Text $externalText -Label "실패"
$completeSessionsText = Get-ReportValue -Text $playtestText -Label "완성 세션"
$p0 = Get-ReportNumber -Text $playtestText -Label "P0"
$p1 = Get-ReportNumber -Text $playtestText -Label "P1"
$qualityStatus = Get-ReportValue -Text $qualityText -Label "상태"
$qualityAverage = Get-ReportValue -Text $qualityText -Label "평균 점수"
$qualityIssues = Get-ReportNumber -Text $qualityText -Label "문제"
$issueStatus = Get-ReportValue -Text $issueText -Label "상태"
$finalStatus = Get-ReportValue -Text $gateText -Label "최종 판정"
$storeStatus = Get-ReportValue -Text $gateText -Label "Steam 상점 제출 자료"
$paidCandidateStatus = Get-ReportValue -Text $gateText -Label "$priceTargetLabel 이상 최종 출시 후보"
$internalQualityStatus = Get-ReportValue -Text $internalQualityText -Label "상태"
$internalQualityAverage = Get-ReportValue -Text $internalQualityText -Label "평균 점수"
$internalQualityMinimum = Get-ReportValue -Text $internalQualityText -Label "최저 점수"
$internalQualityBlockers = Get-ReportNumber -Text $internalQualityText -Label "내부 차단"
$internalQualityExternal = Get-ReportNumber -Text $internalQualityText -Label "외부 의존"

$backlog = New-Object System.Collections.Generic.List[object]
$decisions = New-Object System.Collections.Generic.List[object]

if ($autoFailed -eq 0 -and $pending -eq 0 -and $autoPassed -gt 0) {
    Add-Decision -Role "프로듀서/QA" -Decision "자동 QA와 패키지 기준은 상점 제출 준비 수준" -Evidence "자동 통과 $autoPassed, 자동 실패 $autoFailed, 보류 $pending" -Action "외부 증거 스프린트로 넘어간다."
}
elseif ($autoFailed -eq 0 -and $autoPassed -gt 0) {
    Add-Decision -Role "프로듀서/QA" -Decision "자동 QA는 실패 없이 보류" -Evidence "자동 통과 $autoPassed, 자동 실패 $autoFailed, 보류 $pending" -Action "Unity 런타임 동기화, 최신 접근성 캡처, 최신 피드백 export 증거를 갱신한다."
    Add-Backlog -Id "INT-AUTO-001" -Priority "P1" -Owner "QA" -Area "자동 QA" -Status "open" -Evidence "RELEASE_READINESS_REPORT.md" -NextAction "Unity 런타임 동기화, 접근성 런타임 증거, 최신 피드백 export 보류 항목을 갱신한다." -ExitCriteria "RELEASE_READINESS_REPORT.md 자동 실패 0, 보류 0"
}
else {
    Add-Decision -Role "프로듀서/QA" -Decision "자동 QA 차단" -Evidence "자동 통과 $autoPassed, 자동 실패 $autoFailed, 보류 $pending" -Action "릴리즈 감사 실패를 먼저 수정한다."
    Add-Backlog -Id "INT-AUTO-001" -Priority "P0" -Owner "QA" -Area "자동 QA" -Status "open" -Evidence "RELEASE_READINESS_REPORT.md" -NextAction "자동 실패와 보류 항목을 재현하고 수정한다." -ExitCriteria "RELEASE_READINESS_REPORT.md 자동 실패 0, 보류 0"
}

if ($storeStatus -eq "준비됨") {
    Add-Decision -Role "상점 운영" -Decision "Steam 상점 제출 자료는 패키징 가능" -Evidence "COMMERCIAL_LAUNCH_GATE.md Steam 상점 제출 자료 준비됨" -Action "최종 출시 전까지 외부 증거와 품질 점수표를 채운다."
}
else {
    Add-Decision -Role "상점 운영" -Decision "상점 제출 자료 보류" -Evidence "COMMERCIAL_LAUNCH_GATE.md Steam 상점 제출 자료 $storeStatus" -Action "Steam 제출 패키지, Steamworks 스테이징, 상점 자산 QA를 재실행한다."
    $storePriority = if ($finalStatus -eq "차단") { "P0" } else { "P1" }
    Add-Backlog -Id "INT-STORE-001" -Priority $storePriority -Owner "상점 운영" -Area "Steam 제출" -Status "open" -Evidence "COMMERCIAL_LAUNCH_GATE.md" -NextAction "상점 제출 자료 게이트를 통과시킨다." -ExitCriteria "Steam 상점 제출 자료 준비됨"
}

if ($externalFailed -gt 0) {
    Add-Decision -Role "프로듀서" -Decision "외부 증거 폴더에 실패가 있어 출시 차단" -Evidence "외부 증거 실패 $externalFailed" -Action "비밀키나 형식 오류를 먼저 제거한다."
    Add-Backlog -Id "INT-EVIDENCE-000" -Priority "P0" -Owner "프로듀서" -Area "외부 증거" -Status "open" -Evidence "EXTERNAL_EVIDENCE_AUDIT.md" -NextAction "실패 증거 폴더를 정리한다." -ExitCriteria "외부 증거 실패 0"
}

if ($externalIncomplete -gt 0) {
    Add-Decision -Role "프로듀서" -Decision "최종 유료 출시는 외부 증거 부족으로 보류" -Evidence "외부 증거 미완료 $externalIncomplete" -Action "외부 증거 수집 스프린트를 진행한다."
}

if (Test-ReportContainsRow -Text $externalText -Area "외부 플레이테스트" -Item "5명 이상 세션 증거" -Status "미완료") {
    Add-Backlog -Id "INT-PLAYTEST-001" -Priority "P1" -Owner "기획/QA" -Area "외부 플레이테스트" -Status "open" -Evidence "PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 $completeSessionsText, P0 $p0, P1 $p1" -NextAction "외부 참가자 5명으로 5문답 세션, 관찰 양식, 피드백 export, 지원 번들을 수집한다." -ExitCriteria "완성 세션 5/5, P0 0, P1 0"
}
if (Test-ReportContainsRow -Text $externalText -Area "접근성" -Item "실제 접근성 QA 증거" -Status "미완료") {
    Add-Backlog -Id "INT-ACCESS-001" -Priority "P1" -Owner "접근성 검토자" -Area "접근성" -Status "open" -Evidence "EXTERNAL_EVIDENCE_AUDIT.md 실제 접근성 QA 증거 미완료" -NextAction "화면 배율, 키보드만 조작, 고대비 또는 실제 입력 장치 테스트 양식과 화면 증거를 수집한다." -ExitCriteria "ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록"
}
if (Test-ReportContainsRow -Text $externalText -Area "상업 아트" -Item "외부 아트 리뷰 증거" -Status "미완료") {
    Add-Backlog -Id "INT-ART-001" -Priority "P1" -Owner "아트 리뷰어" -Area "아트/상점 첫인상" -Status "open" -Evidence "EXTERNAL_EVIDENCE_AUDIT.md 외부 아트 리뷰 증거 미완료" -NextAction "작은 캡슐, 키아트, 실제 스크린샷에 대한 외부 아트 리뷰 양식을 수집한다." -ExitCriteria "ART_REVIEW_FORM.md와 이미지/PDF 근거 등록"
}
if (Test-ReportContainsRow -Text $externalText -Area "트레일러" -Item "최종 트레일러 증거" -Status "미완료") {
    Add-Backlog -Id "INT-TRAILER-001" -Priority "P1" -Owner "트레일러 편집자" -Area "트레일러" -Status "open" -Evidence "EXTERNAL_EVIDENCE_AUDIT.md 최종 트레일러 증거 미완료" -NextAction "라이브 플레이 기반 최종 MP4, 리뷰 양식, 자막 또는 캡션 증거를 수집한다." -ExitCriteria "TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록"
}
if (Test-ReportContainsRow -Text $externalText -Area "법무/상점" -Item "Steam 관리자와 개인정보 최종 증거" -Status "미완료") {
    Add-Backlog -Id "INT-LEGAL-001" -Priority "P1" -Owner "상점 운영/법무" -Area "Steam 관리자/법무" -Status "open" -Evidence "EXTERNAL_EVIDENCE_AUDIT.md Steam 관리자와 개인정보 최종 증거 미완료" -NextAction "Steam 관리자 체크리스트, 최종 개인정보 문구, 테스트 브랜치 실행 증거를 수집한다." -ExitCriteria "Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록"
}

if ($qualityStatus -ne "완료") {
    Add-Decision -Role "기획/프로듀서" -Decision "$priceTargetLabel 품질 판정은 아직 확정 불가" -Evidence "품질 루브릭 상태 $qualityStatus, 평균 $qualityAverage, 문제 $qualityIssues" -Action "공식 점수표를 외부 증거 기준으로 채운다."
    Add-Backlog -Id "INT-QUALITY-001" -Priority "P1" -Owner "기획/프로듀서" -Area "$priceTargetLabel 품질 루브릭" -Status "open" -Evidence "COMMERCIAL_QUALITY_REVIEW_QA.md 상태 $qualityStatus" -NextAction "COMMERCIAL_QUALITY_SCORECARD.tsv를 리뷰어/evidence 포함으로 채운다." -ExitCriteria "상태 완료, 평균 4.0 이상, 최저 3 이상, 차단 0"
}
else {
    Add-Decision -Role "기획/프로듀서" -Decision "$priceTargetLabel 품질 루브릭 통과" -Evidence "평균 $qualityAverage, 문제 $qualityIssues" -Action "외부 이슈 폐쇄와 출시 게이트를 확인한다."
}

if ($internalQualityText -eq "") {
    Add-Decision -Role "기획/프로듀서" -Decision "내부 품질 점수표 누락" -Evidence "INTERNAL_QUALITY_REVIEW.md 없음" -Action "WriteInternalQualityScorecard.ps1를 실행한다."
    Add-Backlog -Id "INT-QUALITY-AUTO-000" -Priority "P1" -Owner "기획/프로듀서" -Area "내부 품질 점수표" -Status "open" -Evidence "INTERNAL_QUALITY_REVIEW.md 누락" -NextAction "내부 품질 점수표를 생성한다." -ExitCriteria "INTERNAL_QUALITY_REVIEW.md 생성, 내부 차단 0"
}
elseif ($internalQualityBlockers -gt 0 -or $internalQualityStatus -eq "차단") {
    Add-Decision -Role "기획/프로듀서" -Decision "내부 품질 기준 차단" -Evidence "상태 $internalQualityStatus, 평균 $internalQualityAverage, 최저 $internalQualityMinimum, 내부 차단 $internalQualityBlockers" -Action "내부 점수표의 차단 영역을 먼저 수정한다."
    Add-Backlog -Id "INT-QUALITY-AUTO-001" -Priority "P0" -Owner "기획/프로듀서" -Area "내부 품질 점수표" -Status "open" -Evidence "INTERNAL_QUALITY_REVIEW.md 내부 차단 $internalQualityBlockers" -NextAction "INTERNAL_QUALITY_SCORECARD.tsv에서 internal_blocker=yes 영역을 수정한다." -ExitCriteria "내부 품질 점수표 내부 차단 0"
}
elseif ($internalQualityStatus -eq "보류") {
    Add-Decision -Role "기획/프로듀서" -Decision "내부 자동 품질은 보류" -Evidence "평균 $internalQualityAverage, 최저 $internalQualityMinimum, 외부 의존 $internalQualityExternal" -Action "내부 차단은 없지만 외부 증거와 공식 점수표를 채워야 한다."
}
elseif ($internalQualityStatus -eq "통과") {
    Add-Decision -Role "기획/프로듀서" -Decision "내부 자동 품질 기준 통과" -Evidence "평균 $internalQualityAverage, 최저 $internalQualityMinimum, 내부 차단 $internalQualityBlockers" -Action "공식 외부 점수표와 최종 게이트를 확인한다."
}

if ($issueStatus -ne "완료") {
    Add-Backlog -Id "INT-ISSUE-001" -Priority "P2" -Owner "QA" -Area "외부 이슈 폐쇄" -Status "open" -Evidence "EXTERNAL_ISSUE_REGISTER_QA.md 상태 $issueStatus" -NextAction "외부 리뷰에서 발견된 이슈를 등록하고 P2 이상은 verified 또는 수용 위험으로 정리한다." -ExitCriteria "이슈 레지스터 상태 완료"
}

if ($paidCandidateStatus -eq "통과" -and $finalStatus -eq "통과") {
    Add-Decision -Role "전체 팀" -Decision "$priceTargetLabel 이상 최종 출시 후보" -Evidence "COMMERCIAL_LAUNCH_GATE.md 최종 판정 통과" -Action "Steam 관리자 최종 릴리즈 절차를 진행한다."
}
else {
    Add-Decision -Role "전체 팀" -Decision "$priceTargetLabel 이상 최종 출시는 보류" -Evidence "최종 판정 $finalStatus, 최종 출시 후보 $paidCandidateStatus" -Action "백로그의 P1 항목을 완료하고 게이트를 재실행한다."
}

$backlogLines = New-Object System.Collections.Generic.List[string]
$backlogLines.Add("id`tpriority`towner`tarea`tstatus`tevidence`tnext_action`texit_criteria")
foreach ($item in $backlog) {
    $backlogLines.Add((
        (Format-TsvCell $item.id),
        (Format-TsvCell $item.priority),
        (Format-TsvCell $item.owner),
        (Format-TsvCell $item.area),
        (Format-TsvCell $item.status),
        (Format-TsvCell $item.evidence),
        (Format-TsvCell $item.next_action),
        (Format-TsvCell $item.exit_criteria)
    ) -join "`t")
}
Write-LinesWithRetry -Path $BacklogPath -Lines $backlogLines

$p0Backlog = @($backlog | Where-Object { $_.priority -eq "P0" }).Count
$p1Backlog = @($backlog | Where-Object { $_.priority -eq "P1" }).Count
$p2Backlog = @($backlog | Where-Object { $_.priority -eq "P2" }).Count
$reviewStatus = if ($p0Backlog -gt 0) {
    "차단"
}
elseif ($p1Backlog -gt 0 -or $paidCandidateStatus -ne "통과") {
    "보류"
}
else {
    "통과"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 내부 상업 리뷰")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- 리뷰 상태: $reviewStatus")
$lines.Add("- 자동 QA: 통과 $autoPassed, 실패 $autoFailed, 보류 $pending")
$lines.Add("- 외부 증거: 미완료 $externalIncomplete, 실패 $externalFailed")
$lines.Add("- 플레이테스트: 완성 세션 $completeSessionsText, P0 $p0, P1 $p1")
$lines.Add("- 품질 루브릭: 상태 $qualityStatus, 평균 $qualityAverage")
$lines.Add("- 내부 품질 점수표: 상태 $internalQualityStatus, 평균 $internalQualityAverage, 최저 $internalQualityMinimum, 내부 차단 $internalQualityBlockers, 외부 의존 $internalQualityExternal")
$lines.Add("- 최종 게이트: $finalStatus")
$lines.Add("- 백로그: P0 $p0Backlog, P1 $p1Backlog, P2 $p2Backlog")
$lines.Add("- 백로그 파일: $BacklogPath")
$lines.Add("- 내부 품질 리뷰 파일: $InternalQualityReviewPath")
$lines.Add("")
$lines.Add("이 리뷰는 내부 회의용이다. 외부 플레이테스트, 접근성 검토, 아트 리뷰, 최종 트레일러 리뷰, Steam 관리자 증거를 대체하지 않는다.")
$lines.Add("")
$lines.Add("## 역할별 판단")
$lines.Add("")
$lines.Add("| 역할 | 판단 | 근거 | 다음 행동 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($decision in $decisions) {
    $lines.Add("| $(Escape-MarkdownCell $decision.role) | $(Escape-MarkdownCell $decision.decision) | $(Escape-MarkdownCell $decision.evidence) | $(Escape-MarkdownCell $decision.action) |")
}
$lines.Add("")
$lines.Add("## 다음 스프린트 백로그")
$lines.Add("")
$lines.Add("| ID | 우선순위 | 담당 | 영역 | 상태 | 근거 | 다음 행동 | 완료 기준 |")
$lines.Add("| --- | --- | --- | --- | --- | --- | --- | --- |")
if ($backlog.Count -eq 0) {
    $lines.Add("| 없음 |  |  |  |  |  |  |  |")
}
else {
    foreach ($item in $backlog) {
        $lines.Add("| $(Escape-MarkdownCell $item.id) | $(Escape-MarkdownCell $item.priority) | $(Escape-MarkdownCell $item.owner) | $(Escape-MarkdownCell $item.area) | $(Escape-MarkdownCell $item.status) | $(Escape-MarkdownCell $item.evidence) | $(Escape-MarkdownCell $item.next_action) | $(Escape-MarkdownCell $item.exit_criteria) |")
    }
}
$lines.Add("")
$lines.Add("## 회의 종료 조건")
$lines.Add("")
$lines.Add("- P0 백로그가 있으면 상점 제출 후보로도 보지 않는다.")
$lines.Add("- P1 백로그가 남아 있으면 $priceTargetLabel 이상 최종 유료 출시 후보로 보지 않는다.")
$lines.Add("- 모든 외부 증거와 품질 점수표가 완료된 뒤 `RunCommercialLaunchGate.ps1 -RequireLaunchReady`를 통과해야 출시 후보로 본다.")

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Internal commercial review written: $OutputPath"
Write-Host "Internal commercial backlog written: $BacklogPath"
Write-Host "Review status: $reviewStatus, backlog P0: $p0Backlog, P1: $p1Backlog, P2: $p2Backlog"
