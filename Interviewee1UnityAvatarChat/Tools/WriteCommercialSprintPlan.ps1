param(
    [string]$OutputPath,
    [string]$BoardPath,
    [string]$BacklogPath,
    [string]$InternalQualityScorecardPath,
    [string]$EvidencePlanPath,
    [string]$CommercialLaunchGatePath,
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

function Get-QualityLinks {
    param(
        [string]$BacklogId,
        [object[]]$QualityRows
    )

    $areaMap = @{
        "INT-PLAYTEST-001" = @("core_loop", "writing")
        "INT-ACCESS-001" = @("readability", "controls")
        "INT-ART-001" = @("art_presentation")
        "INT-TRAILER-001" = @("trailer_store")
        "INT-LEGAL-001" = @("trust_privacy")
        "INT-QUALITY-001" = @("core_loop", "writing", "readability", "controls", "trust_privacy", "art_presentation", "trailer_store", "stability_package")
        "INT-ISSUE-001" = @("core_loop", "readability", "controls", "trust_privacy", "art_presentation", "trailer_store")
    }

    if (-not $areaMap.ContainsKey($BacklogId)) {
        return ""
    }

    $areas = $areaMap[$BacklogId]
    $links = New-Object System.Collections.Generic.List[string]
    foreach ($area in $areas) {
        $row = $QualityRows | Where-Object { $_.area -eq $area } | Select-Object -First 1
        if ($row) {
            $links.Add("$area $($row.score)/$($row.status)") | Out-Null
        }
        else {
            $links.Add($area) | Out-Null
        }
    }

    return ($links -join ", ")
}

function Get-VerificationCommand {
    param([string]$BacklogId)

    switch ($BacklogId) {
        "INT-PLAYTEST-001" { return "Tools\SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete" }
        "INT-ACCESS-001" { return "Tools\ValidateExternalEvidence.ps1 -RequireComplete" }
        "INT-ART-001" { return "Tools\ValidateExternalEvidence.ps1 -RequireComplete" }
        "INT-TRAILER-001" { return "Tools\ValidateExternalEvidence.ps1 -RequireComplete" }
        "INT-LEGAL-001" { return "Tools\ValidateExternalEvidence.ps1 -RequireComplete" }
        "INT-QUALITY-001" { return "Tools\ValidateCommercialQualityRubric.ps1 -RequireReady" }
        "INT-ISSUE-001" { return "Tools\ValidateExternalIssueRegister.ps1 -RequireClosed" }
        default { return "Tools\RunCommercialLaunchGate.ps1" }
    }
}

function Get-Lane {
    param(
        [string]$Priority,
        [string]$BacklogId
    )

    if ($Priority -eq "P0") {
        return "fix_now"
    }

    switch ($BacklogId) {
        "INT-PLAYTEST-001" { return "evidence_collection" }
        "INT-ACCESS-001" { return "evidence_collection" }
        "INT-ART-001" { return "evidence_collection" }
        "INT-TRAILER-001" { return "evidence_collection" }
        "INT-LEGAL-001" { return "evidence_collection" }
        "INT-QUALITY-001" { return "review_decision" }
        "INT-ISSUE-001" { return "triage_verification" }
        default { return "triage_verification" }
    }
}

function Get-BlockerRule {
    param([string]$BacklogId)

    switch ($BacklogId) {
        "INT-PLAYTEST-001" { return "P0/P1 발견 시 개발 수정 스프린트로 되돌리고 verified 증거를 남긴다." }
        "INT-ACCESS-001" { return "키보드만 조작, 확대, 고대비, 실제 입력 장치 중 하나라도 실패하면 출시 후보에서 내린다." }
        "INT-ART-001" { return "작은 캡슐 제목 판독, 키아트 잘림, 보라색 잔상 지적이 있으면 상점 자산을 다시 만든다." }
        "INT-TRAILER-001" { return "10초 안에 플레이 목적이 전달되지 않거나 자막/사운드가 빠지면 최종 트레일러로 보지 않는다." }
        "INT-LEGAL-001" { return "AppID/DepotID, 문의 채널, 개인정보 최종 문구, 테스트 브랜치 실행 증거가 없으면 제출하지 않는다." }
        "INT-QUALITY-001" { return "평균 4.0 미만, 최저 3 미만, 차단 항목, reviewer/evidence 누락 중 하나라도 있으면 보류한다." }
        "INT-ISSUE-001" { return "P0/P1 미검증 또는 P2 미해결이 남으면 최종 게이트를 통과시키지 않는다." }
        default { return "해당 항목의 완료 기준을 증거로 확인할 때까지 보류한다." }
    }
}

function Get-Handoff {
    param([string]$BacklogId)

    switch ($BacklogId) {
        "INT-PLAYTEST-001" { return "ExternalPlaytestPackage와 EvidenceDrop\Playtest" }
        "INT-ACCESS-001" { return "CommercialReviewPackage EvidenceDrop\Accessibility" }
        "INT-ART-001" { return "SteamSubmissionPackage Marketing, CommercialReviewPackage EvidenceDrop\ArtReview" }
        "INT-TRAILER-001" { return "SteamSubmissionPackage Marketing\Trailer, CommercialReviewPackage EvidenceDrop\Trailer" }
        "INT-LEGAL-001" { return "SteamSubmissionPackage Marketing\Steamworks, CommercialReviewPackage EvidenceDrop\LegalSteam" }
        "INT-QUALITY-001" { return "CommercialReviewPackage EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" }
        "INT-ISSUE-001" { return "Build\ReleaseEvidence\EXTERNAL_ISSUE_REGISTER.tsv" }
        default { return "Docs와 EvidenceDrop" }
    }
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
$evidenceRoot = Join-Path $projectRoot "Build\ReleaseEvidence"
$backlogPathProvided = -not [string]::IsNullOrWhiteSpace($BacklogPath)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "COMMERCIAL_SPRINT_PLAN.md"
}
if ([string]::IsNullOrWhiteSpace($BoardPath)) {
    $BoardPath = Join-Path $docsRoot "COMMERCIAL_SPRINT_BOARD.tsv"
}
if ([string]::IsNullOrWhiteSpace($BacklogPath)) {
    $BacklogPath = Join-Path $docsRoot "INTERNAL_COMMERCIAL_BACKLOG.tsv"
}
if ([string]::IsNullOrWhiteSpace($InternalQualityScorecardPath)) {
    $InternalQualityScorecardPath = Join-Path $docsRoot "INTERNAL_QUALITY_SCORECARD.tsv"
}
if ([string]::IsNullOrWhiteSpace($EvidencePlanPath)) {
    $EvidencePlanPath = Join-Path $evidenceRoot "EVIDENCE_COLLECTION_PLAN.tsv"
}
if ([string]::IsNullOrWhiteSpace($CommercialLaunchGatePath)) {
    $CommercialLaunchGatePath = Join-Path $docsRoot "COMMERCIAL_LAUNCH_GATE.md"
}

if (-not $backlogPathProvided) {
    $internalCommercialReviewScript = Join-Path $PSScriptRoot "WriteInternalCommercialReview.ps1"
    if (Test-Path -LiteralPath $internalCommercialReviewScript) {
        & $internalCommercialReviewScript 2>&1 | Out-Null
    }
}

$backlogRows = Import-TsvOrEmpty -Path $BacklogPath
$qualityRows = Import-TsvOrEmpty -Path $InternalQualityScorecardPath
$evidenceRows = Import-TsvOrEmpty -Path $EvidencePlanPath
$gateText = Read-Report -Path $CommercialLaunchGatePath
$priceTargetLabel = "$PriceTargetUsd" + "달러"

$finalStatus = Get-ReportValue -Text $gateText -Label "최종 판정"
$passedGates = Get-ReportNumber -Text $gateText -Label "통과 게이트"
$heldGates = Get-ReportNumber -Text $gateText -Label "보류 게이트"
$blockedGates = Get-ReportNumber -Text $gateText -Label "차단 게이트"
$storeStatus = Get-ReportValue -Text $gateText -Label "Steam 상점 제출 자료"
$launchCandidate = Get-ReportValue -Text $gateText -Label "$priceTargetLabel 이상 최종 출시 후보"

$boardRows = New-Object System.Collections.Generic.List[object]
foreach ($backlog in $backlogRows) {
    $evidence = $evidenceRows | Where-Object { $_.backlog_id -eq $backlog.id } | Select-Object -First 1
    $expectedFiles = if ($evidence) { $evidence.expected_files } else { "" }
    $collectionCommand = if ($evidence) { $evidence.collection_command } else { "" }
    $folder = if ($evidence) { $evidence.evidence_folder } else { "." }

    $boardRows.Add([pscustomobject]@{
        id = $backlog.id
        lane = Get-Lane -Priority $backlog.priority -BacklogId $backlog.id
        priority = $backlog.priority
        owner = $backlog.owner
        area = $backlog.area
        status = $backlog.status
        linked_quality = Get-QualityLinks -BacklogId $backlog.id -QualityRows $qualityRows
        evidence_folder = $folder
        deliverables = $expectedFiles
        collection_command = $collectionCommand
        verification_command = Get-VerificationCommand -BacklogId $backlog.id
        blocker_rule = Get-BlockerRule -BacklogId $backlog.id
        handoff_package = Get-Handoff -BacklogId $backlog.id
        exit_criteria = $backlog.exit_criteria
    }) | Out-Null
}

$boardLines = New-Object System.Collections.Generic.List[string]
$boardLines.Add("id`tlane`tpriority`towner`tarea`tstatus`tlinked_quality`tevidence_folder`tdeliverables`tcollection_command`tverification_command`tblocker_rule`thandoff_package`texit_criteria")
foreach ($row in $boardRows) {
    $boardLines.Add((
        (Format-TsvCell $row.id),
        (Format-TsvCell $row.lane),
        (Format-TsvCell $row.priority),
        (Format-TsvCell $row.owner),
        (Format-TsvCell $row.area),
        (Format-TsvCell $row.status),
        (Format-TsvCell $row.linked_quality),
        (Format-TsvCell $row.evidence_folder),
        (Format-TsvCell $row.deliverables),
        (Format-TsvCell $row.collection_command),
        (Format-TsvCell $row.verification_command),
        (Format-TsvCell $row.blocker_rule),
        (Format-TsvCell $row.handoff_package),
        (Format-TsvCell $row.exit_criteria)
    ) -join "`t")
}
Write-LinesWithRetry -Path $BoardPath -Lines $boardLines

$p0Count = @($boardRows | Where-Object { $_.priority -eq "P0" }).Count
$p1Count = @($boardRows | Where-Object { $_.priority -eq "P1" }).Count
$p2Count = @($boardRows | Where-Object { $_.priority -eq "P2" }).Count
$fixNowCount = @($boardRows | Where-Object { $_.lane -eq "fix_now" }).Count
$evidenceCount = @($boardRows | Where-Object { $_.lane -eq "evidence_collection" }).Count
$decisionCount = @($boardRows | Where-Object { $_.lane -eq "review_decision" }).Count
$triageCount = @($boardRows | Where-Object { $_.lane -eq "triage_verification" }).Count
$sprintStatus = if ($p0Count -gt 0 -or $blockedGates -gt 0) {
    "차단 대응"
}
elseif ($p1Count -gt 0 -or $heldGates -gt 0) {
    "외부 증거 스프린트"
}
else {
    "최종 게이트 준비"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상업 출시 스프린트 계획")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- 스프린트 상태: $sprintStatus")
$lines.Add("- 최종 게이트: $finalStatus")
$lines.Add("- Steam 상점 제출 자료: $storeStatus")
$lines.Add("- $priceTargetLabel 이상 최종 출시 후보: $launchCandidate")
$lines.Add("- 게이트: 통과 $passedGates, 보류 $heldGates, 차단 $blockedGates")
$lines.Add("- 백로그: P0 $p0Count, P1 $p1Count, P2 $p2Count")
$lines.Add("- 보드 파일: $BoardPath")
$lines.Add("")
$lines.Add("이 계획은 내부 실행 계획이다. 외부 플레이테스트, 접근성 검토, 아트 리뷰, 최종 트레일러 리뷰, Steam 관리자/법무 증거, 공식 품질 점수표를 대체하지 않는다.")
$lines.Add("")
$lines.Add("## 운영 원칙")
$lines.Add("")
$lines.Add("- P0가 하나라도 생기면 상점 제출 후보에서 내리고 수정 스프린트를 먼저 연다.")
$lines.Add("- P1이 남아 있으면 $priceTargetLabel 이상 최종 유료 출시 후보로 보지 않는다.")
$lines.Add("- 템플릿은 증거가 아니며, 채워진 양식과 원본 파일, 화면 또는 영상 근거가 있어야 완료로 본다.")
$lines.Add("- 공식 품질 점수표는 내부 점수가 아니라 외부 리뷰어, 증거 경로, 차단 여부를 기준으로 채운다.")
$lines.Add("")
$lines.Add("## 회의 흐름")
$lines.Add("")
$lines.Add("| 순서 | 회의 | 입력 | 산출물 | 종료 조건 |")
$lines.Add("| ---: | --- | --- | --- | --- |")
$lines.Add("| 1 | 출시 스프린트 킥오프 | 상업 게이트, 내부 상업 리뷰, 내부 품질 점수표 | 담당자별 증거 수집 일정 | 모든 P1 담당자와 제출 폴더 확정 |")
$lines.Add("| 2 | 외부 검증 수집 | 외부 플레이테스트/접근성/아트/트레일러/법무 패키지 | EvidenceDrop 파일과 이슈 후보 | 필수 증거 파일 누락 0 |")
$lines.Add("| 3 | 이슈 분류 | 관찰 기록, 리뷰 양식, 피드백 export | EXTERNAL_ISSUE_REGISTER.tsv | P0/P1 재현 경로와 수정 담당 확정 |")
$lines.Add("| 4 | 품질 판정 | 공식 점수표, 외부 증거, 이슈 레지스터 | COMMERCIAL_QUALITY_SCORECARD.tsv | 평균 4.0 이상, 최저 3 이상, 차단 0 |")
$lines.Add("| 5 | 최종 게이트 | 모든 보고서와 패키지 | 출시 후보 판정 | RunCommercialLaunchGate.ps1 -RequireLaunchReady 통과 |")
$lines.Add("")
$lines.Add("## 실행 보드")
$lines.Add("")
$lines.Add("| ID | 레인 | 우선순위 | 담당 | 영역 | 연결 품질 | 제출 위치 | 산출물 | 검증 명령 | 중단 규칙 | 완료 기준 |")
$lines.Add("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
if ($boardRows.Count -eq 0) {
    $lines.Add("| 없음 |  |  |  |  |  |  |  |  |  |  |")
}
else {
    foreach ($row in $boardRows) {
        $lines.Add("| $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.lane) | $(Escape-MarkdownCell $row.priority) | $(Escape-MarkdownCell $row.owner) | $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.linked_quality) | $(Escape-MarkdownCell $row.handoff_package) | $(Escape-MarkdownCell $row.deliverables) | $(Escape-MarkdownCell $row.verification_command) | $(Escape-MarkdownCell $row.blocker_rule) | $(Escape-MarkdownCell $row.exit_criteria) |")
    }
}
$lines.Add("")
$lines.Add("## 패키지 인계")
$lines.Add("")
$lines.Add("- 외부 플레이테스트: Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA")
$lines.Add("- 상업 검토: Build\CommercialReviewPackages\GeotNotEqualSok-CommercialReview-QA")
$lines.Add("- Steam 제출: Build\SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA")
$lines.Add("- 최종 증거 원본: Build\ReleaseEvidence")
$lines.Add("")
$lines.Add("## 검증 명령")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1 -RequireClosed")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady")
$lines.Add('```')

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Commercial sprint plan written: $OutputPath"
Write-Host "Commercial sprint board written: $BoardPath"
Write-Host "Sprint status: $sprintStatus, P0: $p0Count, P1: $p1Count, P2: $p2Count, lanes evidence/review/triage/fix: $evidenceCount/$decisionCount/$triageCount/$fixNowCount"


