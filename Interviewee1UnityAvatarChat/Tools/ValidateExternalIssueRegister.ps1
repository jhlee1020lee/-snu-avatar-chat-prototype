param(
    [string]$IssueRegisterPath,
    [string]$OutputPath,
    [switch]$Initialize,
    [switch]$RequireClosed
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

function Add-Check {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Status,
        [string]$Evidence
    )

    $script:checks.Add([pscustomobject]@{
        Area = $Area
        Item = $Item
        Status = $Status
        Evidence = $Evidence
    }) | Out-Null
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Is-Blank {
    param([string]$Value)

    return [string]::IsNullOrWhiteSpace($Value)
}

function Read-TextWithRetry {
    param([string]$Path)

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
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
$evidenceDropRoot = Join-Path $projectRoot "EvidenceDrop"

if ([string]::IsNullOrWhiteSpace($IssueRegisterPath)) {
    if (Test-Path -LiteralPath $evidenceDropRoot) {
        $IssueRegisterPath = Join-Path $evidenceDropRoot "EXTERNAL_ISSUE_REGISTER.tsv"
    }
    else {
        $IssueRegisterPath = Join-Path $buildRoot "ReleaseEvidence\EXTERNAL_ISSUE_REGISTER.tsv"
    }
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath $evidenceDropRoot) {
        $OutputPath = Join-Path $evidenceDropRoot "EXTERNAL_ISSUE_REGISTER_QA.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "EXTERNAL_ISSUE_REGISTER_QA.md"
    }
}

$requiredColumns = @(
    "issue_id",
    "status",
    "priority",
    "area",
    "source",
    "session_id",
    "build_id",
    "title",
    "repro_steps",
    "expected",
    "actual",
    "fix_summary",
    "verified_by",
    "verified_at",
    "evidence_path"
)
$allowedPriorities = @("P0", "P1", "P2", "P3")
$allowedStatuses = @("open", "in_progress", "fixed", "verified", "accepted_risk", "wont_fix")

if ($Initialize -and -not (Test-Path -LiteralPath $IssueRegisterPath)) {
    $directory = Split-Path -Parent $IssueRegisterPath
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    Set-Content -LiteralPath $IssueRegisterPath -Value ($requiredColumns -join "`t") -Encoding UTF8
}

$checks = New-Object System.Collections.Generic.List[object]
$issueRows = New-Object System.Collections.Generic.List[object]
$formatFailures = 0
$blockingOpen = 0
$p2Open = 0
$secrets = 0
$status = "증거 없음"

if (-not (Test-Path -LiteralPath $IssueRegisterPath)) {
    Add-Check -Area "이슈 레지스터" -Item "파일 존재" -Status "미완료" -Evidence "누락: $IssueRegisterPath"
}
else {
    Add-Check -Area "이슈 레지스터" -Item "파일 존재" -Status "완료" -Evidence $IssueRegisterPath

    $rawText = Read-TextWithRetry -Path $IssueRegisterPath
    $secretMatches = [regex]::Matches($rawText, $ApiKeyPattern)
    $secrets = $secretMatches.Count
    if ($secrets -gt 0) {
        Add-Check -Area "보안" -Item "비밀키 형태 문자열" -Status "실패" -Evidence "$secrets개 발견"
    }
    else {
        Add-Check -Area "보안" -Item "비밀키 형태 문자열" -Status "완료" -Evidence "발견 없음"
    }

    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $IssueRegisterPath)
    if ($rows.Count -eq 0) {
        Add-Check -Area "이슈 레지스터" -Item "이슈 행" -Status "미완료" -Evidence "등록된 외부 이슈 행 없음"
    }

    $firstLine = (Get-Content -LiteralPath $IssueRegisterPath -TotalCount 1)
    $headers = @($firstLine -split "`t")
    foreach ($column in $requiredColumns) {
        if ($headers -notcontains $column) {
            $formatFailures++
            Add-Check -Area "형식" -Item "필수 열 $column" -Status "실패" -Evidence "열 누락"
        }
    }
    if ($formatFailures -eq 0) {
        Add-Check -Area "형식" -Item "필수 열" -Status "완료" -Evidence "$($requiredColumns.Count)개 열 확인"
    }

    $seenIds = @{}
    foreach ($row in $rows) {
        $rowFailures = New-Object System.Collections.Generic.List[string]
        $issueId = [string]$row.issue_id
        $priority = ([string]$row.priority).Trim().ToUpperInvariant()
        $rowStatus = ([string]$row.status).Trim().ToLowerInvariant()

        if (Is-Blank $issueId) {
            $rowFailures.Add("issue_id 누락") | Out-Null
        }
        elseif ($seenIds.ContainsKey($issueId)) {
            $rowFailures.Add("issue_id 중복") | Out-Null
        }
        else {
            $seenIds[$issueId] = $true
        }

        if ($allowedPriorities -notcontains $priority) {
            $rowFailures.Add("priority 오류") | Out-Null
        }
        if ($allowedStatuses -notcontains $rowStatus) {
            $rowFailures.Add("status 오류") | Out-Null
        }
        foreach ($field in @("area", "source", "build_id", "title", "repro_steps", "expected", "actual")) {
            if (Is-Blank ([string]$row.$field)) {
                $rowFailures.Add("$field 누락") | Out-Null
            }
        }

        $isBlockingPriority = $priority -eq "P0" -or $priority -eq "P1"
        $isBlockingOpen = $isBlockingPriority -and $rowStatus -ne "verified"
        $isP2Open = $priority -eq "P2" -and @("open", "in_progress", "fixed") -contains $rowStatus

        if ($isBlockingOpen) {
            $blockingOpen++
        }
        if ($isP2Open) {
            $p2Open++
        }

        if ($rowStatus -eq "verified") {
            foreach ($field in @("fix_summary", "verified_by", "verified_at", "evidence_path")) {
                if (Is-Blank ([string]$row.$field)) {
                    $rowFailures.Add("verified 이슈의 $field 누락") | Out-Null
                }
            }
        }
        if ($isBlockingPriority -and ($rowStatus -eq "accepted_risk" -or $rowStatus -eq "wont_fix")) {
            $rowFailures.Add("P0/P1은 accepted_risk/wont_fix로 출시 통과 불가") | Out-Null
        }

        if ($rowFailures.Count -gt 0) {
            $formatFailures += $rowFailures.Count
        }

        $issueRows.Add([pscustomobject]@{
            IssueId = $issueId
            Priority = $priority
            Status = $rowStatus
            Area = [string]$row.area
            Title = [string]$row.title
            BuildId = [string]$row.build_id
            Result = if ($rowFailures.Count -eq 0) { "확인" } else { $rowFailures -join ", " }
        }) | Out-Null
    }

    if ($blockingOpen -gt 0) {
        Add-Check -Area "출시 차단" -Item "P0/P1 검증 완료" -Status "미완료" -Evidence "$blockingOpen개 미검증"
    }
    else {
        Add-Check -Area "출시 차단" -Item "P0/P1 검증 완료" -Status "완료" -Evidence "미검증 P0/P1 없음"
    }

    if ($p2Open -gt 0) {
        Add-Check -Area "상업 품질" -Item "P2 처리 상태" -Status "미완료" -Evidence "$p2Open개 미해결"
    }
    else {
        Add-Check -Area "상업 품질" -Item "P2 처리 상태" -Status "완료" -Evidence "미해결 P2 없음"
    }

    if ($secrets -gt 0 -or $formatFailures -gt 0) {
        $status = "실패"
    }
    elseif ($blockingOpen -gt 0) {
        $status = "출시 차단"
    }
    elseif ($p2Open -gt 0) {
        $status = "상업 리스크 있음"
    }
    elseif ($rows.Count -eq 0) {
        $status = "증거 없음"
    }
    else {
        $status = "완료"
    }
}

$complete = @($checks | Where-Object { $_.Status -eq "완료" }).Count
$incomplete = @($checks | Where-Object { $_.Status -eq "미완료" }).Count
$failed = @($checks | Where-Object { $_.Status -eq "실패" }).Count

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 이슈 레지스터 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 이슈 레지스터: $IssueRegisterPath")
$lines.Add("- 상태: $status")
$lines.Add("- 등록 이슈: $($issueRows.Count)")
$lines.Add("- 미검증 P0/P1: $blockingOpen")
$lines.Add("- 미해결 P2: $p2Open")
$lines.Add("- 형식 실패: $formatFailures")
$lines.Add("- 비밀키 패턴: $secrets")
$lines.Add("")
$lines.Add("이 보고서는 외부 플레이테스트와 리뷰에서 나온 이슈가 수정, 검증, 수용 위험으로 정리됐는지 확인한다. P0/P1은 verified 상태가 아니면 최종 유료 출시 후보로 볼 수 없다.")
$lines.Add("")
$lines.Add("## 체크")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($check in $checks) {
    $lines.Add("| $(Escape-MarkdownCell $check.Area) | $(Escape-MarkdownCell $check.Item) | $(Escape-MarkdownCell $check.Status) | $(Escape-MarkdownCell $check.Evidence) |")
}
$lines.Add("")
$lines.Add("## 이슈")
$lines.Add("")
$lines.Add("| ID | 등급 | 상태 | 영역 | 제목 | Build ID | 결과 |")
$lines.Add("| --- | --- | --- | --- | --- | --- | --- |")
if ($issueRows.Count -eq 0) {
    $lines.Add("| 없음 |  |  |  | 외부 이슈 레지스터 없음 또는 빈 레지스터 |  | 증거 없음 |")
}
else {
    foreach ($issue in $issueRows) {
        $lines.Add("| $(Escape-MarkdownCell $issue.IssueId) | $(Escape-MarkdownCell $issue.Priority) | $(Escape-MarkdownCell $issue.Status) | $(Escape-MarkdownCell $issue.Area) | $(Escape-MarkdownCell $issue.Title) | $(Escape-MarkdownCell $issue.BuildId) | $(Escape-MarkdownCell $issue.Result) |")
    }
}

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "External issue register QA written: $OutputPath"
Write-Host "Status: $status, P0/P1 open: $blockingOpen, P2 open: $p2Open, format failures: $formatFailures"

if ($failed -gt 0) {
    throw "External issue register QA has $failed failed check(s)."
}
if ($RequireClosed -and ($status -ne "완료")) {
    throw "External issue register is not closed for final paid release: $status"
}
