param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$RosterPath,
    [string]$DocsPath,
    [string]$OutputPath,
    [switch]$RequireReady
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

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

function Add-Result {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Evidence,
        [string]$NextAction = ""
    )

    $script:results.Add([pscustomobject]@{
        Item = $Item
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

function Get-Text {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return ""
    }
    return Get-Content -LiteralPath (ConvertTo-LongPath -Path $Path) -Raw -Encoding UTF8
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($TrackerPath)) {
    $TrackerPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_TRACKER.tsv"
}
if ([string]::IsNullOrWhiteSpace($RosterPath)) {
    $RosterPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEWER_ROSTER.tsv"
}
if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    $DocsPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER.md"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]
$requiredIds = @("PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "ACCESS-01", "ART-01", "TRAILER-01", "LEGAL-01", "QUALITY-01", "ISSUE-01")
$allowedInviteStatuses = @("not_sent", "sent", "accepted", "declined")
$textPaths = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    Add-Result -Item "추적 TSV" -Status "차단" -Evidence "파일 없음: $TrackerPath" -NextAction "WriteExternalReviewTracker.ps1를 실행한다."
    $trackerRows = @()
}
else {
    $trackerRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
    Add-Result -Item "추적 TSV" -Status "완료" -Evidence "$($trackerRows.Count)개 행 확인"
    $textPaths.Add($TrackerPath) | Out-Null
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $RosterPath))) {
    Add-Result -Item "명단 TSV" -Status "차단" -Evidence "파일 없음: $RosterPath" -NextAction "WriteExternalReviewerRosterTemplate.ps1를 실행한다."
    $rosterRows = @()
}
else {
    $rosterRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $RosterPath) -Encoding UTF8)
    $missingIds = @($requiredIds | Where-Object { $id = $_; -not ($rosterRows | Where-Object { $_.id -eq $id }) })
    if ($missingIds.Count -eq 0 -and $rosterRows.Count -ge $requiredIds.Count) {
        Add-Result -Item "명단 TSV" -Status "완료" -Evidence "$($rosterRows.Count)개 행 확인"
        $textPaths.Add($RosterPath) | Out-Null
    }
    else {
        Add-Result -Item "명단 TSV" -Status "차단" -Evidence "누락 ID: $($missingIds -join ', ')" -NextAction "WriteExternalReviewerRosterTemplate.ps1를 다시 실행한다."
    }
}

$requiredColumns = @("id", "role", "reviewer_profile", "reviewer_alias", "contact_method", "due_at", "backup_reviewer_alias", "backup_contact_method", "invite_status", "invite_sent_at", "notes")
$missingColumns = New-Object System.Collections.Generic.List[string]
if ($rosterRows.Count -gt 0) {
    foreach ($column in $requiredColumns) {
        if ($rosterRows[0].PSObject.Properties.Name -notcontains $column) {
            $missingColumns.Add($column) | Out-Null
        }
    }
}
if ($rosterRows.Count -gt 0 -and $missingColumns.Count -eq 0) {
    Add-Result -Item "명단 컬럼" -Status "완료" -Evidence "필수 컬럼 확인"
}
else {
    Add-Result -Item "명단 컬럼" -Status "차단" -Evidence "누락 컬럼: $($missingColumns -join ', ')" -NextAction "명단 TSV를 다시 생성한다."
}

$badInvite = @($rosterRows | Where-Object { $allowedInviteStatuses -notcontains $_.invite_status })
$badDates = @($rosterRows | Where-Object {
    if ([string]::IsNullOrWhiteSpace([string]$_.due_at)) {
        return $false
    }
    $date = [datetime]::MinValue
    return -not [datetime]::TryParse([string]$_.due_at, [ref]$date)
})
$today = (Get-Date).Date
$pastDueDates = @($rosterRows | Where-Object {
    if ([string]::IsNullOrWhiteSpace([string]$_.due_at)) {
        return $false
    }
    $date = [datetime]::MinValue
    if (-not [datetime]::TryParse([string]$_.due_at, [ref]$date)) {
        return $false
    }
    return $date.Date -lt $today
})
$missingProfile = @($rosterRows | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.reviewer_profile) })
if ($badInvite.Count -eq 0 -and $badDates.Count -eq 0 -and $pastDueDates.Count -eq 0 -and $missingProfile.Count -eq 0) {
    Add-Result -Item "명단 값" -Status "완료" -Evidence "프로필, invite_status, due_at 형식과 미래 일정 확인"
}
else {
    Add-Result -Item "명단 값" -Status "차단" -Evidence "invite 오류 $($badInvite.Count), 날짜 오류 $($badDates.Count), 과거 마감 $($pastDueDates.Count), 프로필 누락 $($missingProfile.Count)" -NextAction "명단 값을 수정하고 due_at은 오늘 이후 날짜로 둔다."
}

$readyRows = @($rosterRows | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_.reviewer_alias) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.contact_method) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.due_at)
})
if ($readyRows.Count -lt $requiredIds.Count) {
    if ($RequireReady) {
        Add-Result -Item "적용 준비" -Status "차단" -Evidence "준비 $($readyRows.Count)/$($requiredIds.Count)" -NextAction "reviewer_alias, contact_method, due_at을 모두 채운다."
    }
    else {
        Add-Result -Item "적용 준비" -Status "보류" -Evidence "준비 $($readyRows.Count)/$($requiredIds.Count)" -NextAction "reviewer_alias, contact_method, due_at을 모두 채운 뒤 ApplyExternalReviewerRoster.ps1를 실행한다."
    }
}
else {
    Add-Result -Item "적용 준비" -Status "완료" -Evidence "준비 $($readyRows.Count)/$($requiredIds.Count)"
}

$docsText = Get-Text -Path $DocsPath
if ($docsText -ne "" -and $docsText -match "외부 리뷰어 명단" -and $docsText -match "사용 순서" -and $docsText -match "검증 명령") {
    Add-Result -Item "요약 문서" -Status "완료" -Evidence $DocsPath
    $textPaths.Add($DocsPath) | Out-Null
}
else {
    Add-Result -Item "요약 문서" -Status "차단" -Evidence "문서 누락 또는 핵심 문구 누락" -NextAction "WriteExternalReviewerRosterTemplate.ps1를 다시 실행한다."
}

$secretMatches = @()
$emphasisMatches = @()
foreach ($path in $textPaths.ToArray()) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path)) {
        $secretMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue)
        $emphasisMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern "\*\*" -ErrorAction SilentlyContinue)
    }
}
if ($secretMatches.Count -eq 0) {
    Add-Result -Item "비밀키 형태 문자열" -Status "완료" -Evidence "발견 0"
}
else {
    Add-Result -Item "비밀키 형태 문자열" -Status "차단" -Evidence "$($secretMatches.Count)개 발견" -NextAction "명단과 문서에서 비밀키 형태 문자열을 제거한다."
}
if ($emphasisMatches.Count -eq 0) {
    Add-Result -Item "별표 강조 제거" -Status "완료" -Evidence "markdown 강조 없음"
}
else {
    Add-Result -Item "별표 강조 제거" -Status "차단" -Evidence "$($emphasisMatches.Count)개 발견" -NextAction "명단과 문서에서 별표 강조를 제거한다."
}

$blocked = @($results | Where-Object { $_.Status -eq "차단" }).Count
$held = @($results | Where-Object { $_.Status -eq "보류" }).Count
$completed = @($results | Where-Object { $_.Status -eq "완료" }).Count
$status = if ($blocked -gt 0) { "차단" } elseif ($held -gt 0) { "보류" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰어 명단 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $completed")
$lines.Add("- 보류: $held")
$lines.Add("- 차단: $blocked")
$lines.Add("- 명단 TSV: $RosterPath")
$lines.Add("- 준비 항목: $($readyRows.Count)/$($requiredIds.Count)")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.NextAction) |")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External reviewer roster QA written: $OutputPath"
Write-Host "Status: $status, completed: $completed, blocked: $blocked, ready: $($readyRows.Count)/$($requiredIds.Count)"

if ($blocked -gt 0) {
    throw "External reviewer roster QA has $blocked blocked item(s)."
}
