param(
    [string]$OutputPath,
    [string]$MatrixPath,
    [string]$StorePagePath,
    [string]$StoreCopyQaPath,
    [string]$InternalQualityReviewPath,
    [string]$InternalQualityScorecardPath,
    [string]$CommercialQualityReviewQaPath,
    [string]$ExternalEvidenceAuditPath,
    [string]$CommercialSprintBoardPath,
    [string]$SteamMarketComparisonQaPath,
    [string]$SteamMarketComparisonPath,
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

function Import-TsvOrEmpty {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    return @(Import-Csv -Delimiter "`t" -LiteralPath $Path -Encoding UTF8)
}

function Test-TsvHasNoFailures {
    param(
        [string]$Path,
        [string]$StatusColumn = "status"
    )

    $rows = Import-TsvOrEmpty -Path $Path
    if ($rows.Count -eq 0) {
        return $false
    }

    $failures = @($rows | Where-Object { $_.$StatusColumn -eq "실패" -or $_.$StatusColumn -eq "fail" })
    return $failures.Count -eq 0
}

function Test-StoreContains {
    param(
        [string]$Text,
        [string]$Pattern
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return [regex]::IsMatch($Text, $Pattern)
}

function Add-Row {
    param(
        [string]$Area,
        [string]$Claim,
        [string]$Status,
        [string]$Evidence,
        [string]$Risk,
        [string]$NextAction
    )

    $script:rows.Add([pscustomobject]@{
        area = $Area
        claim = $Claim
        status = $Status
        evidence = $Evidence
        risk = $Risk
        next_action = $NextAction
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
$marketingRoot = Join-Path $projectRoot "Marketing"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "COMMERCIAL_PRICE_POSITIONING.md"
}
if ([string]::IsNullOrWhiteSpace($MatrixPath)) {
    $MatrixPath = Join-Path $docsRoot "COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv"
}
if ([string]::IsNullOrWhiteSpace($StorePagePath)) {
    $StorePagePath = Join-Path $marketingRoot "STORE_PAGE_DRAFT.md"
}
if ([string]::IsNullOrWhiteSpace($StoreCopyQaPath)) {
    $StoreCopyQaPath = Join-Path $marketingRoot "StoreCopy\STORE_COPY_QA_REPORT.tsv"
}
if ([string]::IsNullOrWhiteSpace($InternalQualityReviewPath)) {
    $InternalQualityReviewPath = Join-Path $docsRoot "INTERNAL_QUALITY_REVIEW.md"
}
if ([string]::IsNullOrWhiteSpace($InternalQualityScorecardPath)) {
    $InternalQualityScorecardPath = Join-Path $docsRoot "INTERNAL_QUALITY_SCORECARD.tsv"
}
if ([string]::IsNullOrWhiteSpace($CommercialQualityReviewQaPath)) {
    $CommercialQualityReviewQaPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_REVIEW_QA.md"
}
if ([string]::IsNullOrWhiteSpace($ExternalEvidenceAuditPath)) {
    $ExternalEvidenceAuditPath = Join-Path $docsRoot "EXTERNAL_EVIDENCE_AUDIT.md"
}
if ([string]::IsNullOrWhiteSpace($CommercialSprintBoardPath)) {
    $CommercialSprintBoardPath = Join-Path $docsRoot "COMMERCIAL_SPRINT_BOARD.tsv"
}
if ([string]::IsNullOrWhiteSpace($SteamMarketComparisonQaPath)) {
    $SteamMarketComparisonQaPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON_QA.md"
}
if ([string]::IsNullOrWhiteSpace($SteamMarketComparisonPath)) {
    $SteamMarketComparisonPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON.tsv"
}

$storeText = Read-Report -Path $StorePagePath
$internalQualityText = Read-Report -Path $InternalQualityReviewPath
$commercialQualityText = Read-Report -Path $CommercialQualityReviewQaPath
$externalText = Read-Report -Path $ExternalEvidenceAuditPath
$marketQaText = Read-Report -Path $SteamMarketComparisonQaPath
$qualityRows = Import-TsvOrEmpty -Path $InternalQualityScorecardPath
$sprintRows = Import-TsvOrEmpty -Path $CommercialSprintBoardPath

$storeCopyClean = Test-TsvHasNoFailures -Path $StoreCopyQaPath
$internalQualityStatus = Get-ReportValue -Text $internalQualityText -Label "상태"
$internalQualityAverage = Get-ReportValue -Text $internalQualityText -Label "평균 점수"
$internalQualityMinimum = Get-ReportValue -Text $internalQualityText -Label "최저 점수"
$internalBlockers = Get-ReportNumber -Text $internalQualityText -Label "내부 차단"
$externalDependencies = Get-ReportNumber -Text $internalQualityText -Label "외부 의존"
$officialQualityStatus = Get-ReportValue -Text $commercialQualityText -Label "상태"
$officialQualityAverage = Get-ReportValue -Text $commercialQualityText -Label "평균 점수"
$externalIncomplete = Get-ReportNumber -Text $externalText -Label "미완료"
$externalFailed = Get-ReportNumber -Text $externalText -Label "실패"
$p1Open = @($sprintRows | Where-Object { $_.priority -eq "P1" -and $_.status -ne "closed" }).Count
$marketStatus = Get-ReportValue -Text $marketQaText -Label "상태"
$marketRows = Get-ReportNumber -Text $marketQaText -Label "비교작 수"
$marketBlockers = Get-ReportNumber -Text $marketQaText -Label "차단"
$marketHolds = Get-ReportNumber -Text $marketQaText -Label "보류"

$rows = New-Object System.Collections.Generic.List[object]
$priceTargetLabel = "$PriceTargetUsd" + "달러"

Add-Row -Area "store_promise" -Claim "상점 문구가 짧은 체험이 아니라 정돈된 대화 세션, 기억장, 기록, 연결 상태와 관계없는 기본 텍스트 대화 가치를 설명한다." -Status $(if ($storeCopyClean -and (Test-StoreContains -Text $storeText -Pattern "기록|기억장") -and (Test-StoreContains -Text $storeText -Pattern "연결 상태|기본 텍스트 대화") -and (Test-StoreContains -Text $storeText -Pattern "다섯\s*(번의\s*)?(문답|질문)")) { "통과" } else { "보류" }) -Evidence "STORE_PAGE_DRAFT.md, STORE_COPY_QA_REPORT.tsv" -Risk "가치 제안이 흐리면 USD $PriceTargetUsd 이상 가격이 단발성 과제물처럼 보일 수 있다." -NextAction "상점 첫 문단과 스크린샷 캡션에서 대화 세션, 기억장, 기록, 연결 독립성, 개인정보 관리 요소를 유지한다."
Add-Row -Area "product_quality" -Claim "내부 자동 품질 기준에서 가격을 즉시 막는 차단 항목이 없다." -Status $(if ($internalBlockers -eq 0 -and $internalQualityStatus -ne "차단") { "통과" } else { "차단" }) -Evidence "INTERNAL_QUALITY_REVIEW.md 상태 $internalQualityStatus, 평균 $internalQualityAverage, 최저 $internalQualityMinimum, 내부 차단 $internalBlockers" -Risk "내부 차단이 있으면 외부 리뷰 전에 가격 논의를 멈춰야 한다." -NextAction "INTERNAL_QUALITY_SCORECARD.tsv의 internal_blocker=yes 항목을 먼저 닫는다."
Add-Row -Area "official_quality" -Claim "공식 $priceTargetLabel 품질 점수표가 외부 리뷰어와 증거 경로로 채워져 있다." -Status $(if ($officialQualityStatus -eq "완료") { "통과" } else { "보류" }) -Evidence "COMMERCIAL_QUALITY_REVIEW_QA.md 상태 $officialQualityStatus, 평균 $officialQualityAverage" -Risk "공식 점수표 없이 내부 점수만으로 USD $PriceTargetUsd 이상 가격을 승인하면 근거가 약하다." -NextAction "COMMERCIAL_QUALITY_SCORECARD.tsv에 reviewer, evidence, blocker, 점수를 채우고 -RequireReady를 통과시킨다."
Add-Row -Area "external_validation" -Claim "외부 플레이테스트, 접근성, 아트, 트레일러, 법무/Steam 증거가 가격 주장을 뒷받침한다." -Status $(if ($externalIncomplete -eq 0 -and $externalFailed -eq 0) { "통과" } elseif ($externalFailed -gt 0) { "차단" } else { "보류" }) -Evidence "EXTERNAL_EVIDENCE_AUDIT.md 미완료 $externalIncomplete, 실패 $externalFailed" -Risk "외부 증거가 없으면 실제 구매자가 체감하는 가치, 판독성, 신뢰를 검증하지 못한다." -NextAction "COMMERCIAL_SPRINT_BOARD.tsv의 evidence_collection 레인을 완료한다."
Add-Row -Area "price_readiness" -Claim "P1 상업 출시 백로그가 닫혀 USD $PriceTargetUsd 이상 출시 후보로 올릴 수 있다." -Status $(if ($p1Open -eq 0) { "통과" } else { "보류" }) -Evidence "COMMERCIAL_SPRINT_BOARD.tsv 열린 P1 $p1Open" -Risk "P1이 남아 있으면 가격보다 출시 신뢰 문제가 먼저다." -NextAction "열린 P1을 닫고 RunCommercialLaunchGate.ps1 -RequireLaunchReady를 실행한다."
Add-Row -Area "market_positioning" -Claim "동일 타깃의 짧은 내러티브/인터랙티브 픽션 가격, 태그, 리뷰 톤 비교가 준비되어 있다." -Status $(if ($marketStatus -eq "완료" -and $marketRows -ge 5 -and $marketBlockers -eq 0 -and $marketHolds -eq 0) { "통과" } elseif ($marketStatus -eq "차단" -or $marketBlockers -gt 0) { "차단" } else { "보류" }) -Evidence "STEAM_MARKET_COMPARISON_QA.md 상태 $marketStatus, 비교작 $marketRows, 차단 $marketBlockers, 보류 $marketHolds" -Risk "시장 비교 없이 가격을 고정하면 할인 전략, 기대 플레이타임, 태그 포지셔닝이 흔들릴 수 있다." -NextAction "WriteSteamMarketComparison.ps1로 최종 가격 회의 직전 비교표를 갱신하고 ValidateSteamMarketComparison.ps1 -RequireReady를 통과시킨다."

$blocked = @($rows | Where-Object { $_.status -eq "차단" }).Count
$held = @($rows | Where-Object { $_.status -eq "보류" }).Count
$passed = @($rows | Where-Object { $_.status -eq "통과" }).Count
$positioningStatus = if ($blocked -gt 0) {
    "차단"
}
elseif ($held -gt 0) {
    "보류"
}
else {
    "통과"
}
$priceRecommendation = if ($positioningStatus -eq "통과") {
    "USD $PriceTargetUsd 이상 가격 후보로 검토할 수 있다."
}
elseif ($blocked -gt 0) {
    "가격 논의 전에 차단 항목을 먼저 수정해야 한다."
}
else {
    "상점 제출 자료는 준비됐지만 USD $PriceTargetUsd 이상 최종 가격 승인은 외부 증거와 공식 점수표가 필요하다."
}

$matrixLines = New-Object System.Collections.Generic.List[string]
$matrixLines.Add("area`tclaim`tstatus`tevidence`trisk`tnext_action")
foreach ($row in $rows) {
    $matrixLines.Add((
        (Format-TsvCell $row.area),
        (Format-TsvCell $row.claim),
        (Format-TsvCell $row.status),
        (Format-TsvCell $row.evidence),
        (Format-TsvCell $row.risk),
        (Format-TsvCell $row.next_action)
    ) -join "`t")
}
Write-LinesWithRetry -Path $MatrixPath -Lines $matrixLines

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상업 가격 포지셔닝")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- 상태: $positioningStatus")
$lines.Add("- 통과: $passed")
$lines.Add("- 보류: $held")
$lines.Add("- 차단: $blocked")
$lines.Add("- 권고: $priceRecommendation")
$lines.Add("- 매트릭스 파일: $MatrixPath")
$lines.Add("")
$lines.Add("이 문서는 가격 판단용 내부 보조 자료다. 최신 Steam 시장 가격 비교, 외부 리뷰, 공식 품질 점수표를 대체하지 않는다.")
$lines.Add("")
$lines.Add("## 가격 논리")
$lines.Add("")
$lines.Add("- USD $PriceTargetUsd 이상 가격은 단발성 과제물이 아니라 정돈된 대화 세션, 기억장 진행, 기록 저장, 연결 상태와 관계없는 기본 텍스트 대화, 개인정보 관리, 접근성 옵션을 하나의 완성 경험으로 제시할 때만 설득력이 있다.")
$lines.Add("- 내부 자동 QA가 통과해도 실제 구매자 기대치는 외부 플레이테스트, 상점 아트 리뷰, 최종 트레일러, Steam 관리자 검증으로 확인해야 한다.")
$lines.Add("- 공식 품질 점수표가 비어 있으면 가격 승인은 보류한다.")
$lines.Add("")
$lines.Add("## 판단 매트릭스")
$lines.Add("")
$lines.Add("| 영역 | 주장 | 상태 | 근거 | 위험 | 다음 행동 |")
$lines.Add("| --- | --- | --- | --- | --- | --- |")
foreach ($row in $rows) {
    $lines.Add("| $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.claim) | $(Escape-MarkdownCell $row.status) | $(Escape-MarkdownCell $row.evidence) | $(Escape-MarkdownCell $row.risk) | $(Escape-MarkdownCell $row.next_action) |")
}
$lines.Add("")
$lines.Add("## 최종 가격 회의 조건")
$lines.Add("")
$lines.Add("- `ValidateExternalEvidence.ps1 -RequireComplete` 통과")
$lines.Add("- `SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete` 통과")
$lines.Add("- `ValidateCommercialQualityRubric.ps1 -RequireReady` 통과")
$lines.Add("- `ValidateExternalIssueRegister.ps1 -RequireClosed` 통과")
$lines.Add("- `ValidateSteamMarketComparison.ps1 -RequireReady` 통과")
$lines.Add("- `RunCommercialLaunchGate.ps1 -RequireLaunchReady` 통과")

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Commercial price positioning written: $OutputPath"
Write-Host "Commercial price positioning matrix written: $MatrixPath"
Write-Host "Price positioning status: $positioningStatus, passed: $passed, held: $held, blocked: $blocked"
