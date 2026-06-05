param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$PacketRoot,
    [string]$QueuePath,
    [string]$DocsPath,
    [string]$OutputPath,
    [switch]$RequireNoNeedsOwner
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
if ([string]::IsNullOrWhiteSpace($PacketRoot)) {
    $PacketRoot = Join-Path $EvidenceRoot "ReviewerPackets"
}
if ([string]::IsNullOrWhiteSpace($QueuePath)) {
    $QueuePath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv"
}
if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    $DocsPath = Join-Path $docsRoot "EXTERNAL_REVIEW_OUTREACH_QUEUE.md"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_OUTREACH_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]
$requiredIds = @("PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "ACCESS-01", "ART-01", "TRAILER-01", "LEGAL-01", "QUALITY-01", "ISSUE-01")
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

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $QueuePath))) {
    Add-Result -Item "발송 큐 TSV" -Status "차단" -Evidence "파일 없음: $QueuePath" -NextAction "WriteExternalReviewOutreachQueue.ps1를 실행한다."
    $queueRows = @()
}
else {
    $queueRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $QueuePath) -Encoding UTF8)
    $missingIds = @($requiredIds | Where-Object { $id = $_; -not ($queueRows | Where-Object { $_.id -eq $id }) })
    if ($missingIds.Count -eq 0 -and $queueRows.Count -ge $requiredIds.Count) {
        Add-Result -Item "발송 큐 TSV" -Status "완료" -Evidence "$($queueRows.Count)개 행 확인"
        $textPaths.Add($QueuePath) | Out-Null
    }
    else {
        Add-Result -Item "발송 큐 TSV" -Status "차단" -Evidence "누락 ID: $($missingIds -join ', ')" -NextAction "WriteExternalReviewOutreachQueue.ps1를 다시 실행한다."
    }
}

$requiredColumns = @("queue_order", "id", "role", "wave", "priority", "gate", "current_action", "reviewer_alias", "contact_method", "invite_status", "suggested_due_at", "reminder_at", "package", "packet_path", "invite_path", "evidence_path", "evidence_status", "validation_command", "exit_criteria")
$missingColumns = New-Object System.Collections.Generic.List[string]
if ($queueRows.Count -gt 0) {
    foreach ($column in $requiredColumns) {
        if ($queueRows[0].PSObject.Properties.Name -notcontains $column) {
            $missingColumns.Add($column) | Out-Null
        }
    }
}
if ($queueRows.Count -gt 0 -and $missingColumns.Count -eq 0) {
    Add-Result -Item "큐 컬럼" -Status "완료" -Evidence "필수 컬럼 확인"
}
else {
    Add-Result -Item "큐 컬럼" -Status "차단" -Evidence "누락 컬럼: $($missingColumns -join ', ')" -NextAction "WriteExternalReviewOutreachQueue.ps1를 다시 실행한다."
}

$badRows = @($queueRows | Where-Object {
    [string]::IsNullOrWhiteSpace([string]$_.current_action) -or
    [string]::IsNullOrWhiteSpace([string]$_.wave) -or
    [string]::IsNullOrWhiteSpace([string]$_.suggested_due_at) -or
    [string]::IsNullOrWhiteSpace([string]$_.packet_path) -or
    [string]::IsNullOrWhiteSpace([string]$_.invite_path) -or
    [string]::IsNullOrWhiteSpace([string]$_.validation_command)
})
$badDates = @($queueRows | Where-Object {
    $date = [datetime]::MinValue
    -not [datetime]::TryParse([string]$_.suggested_due_at, [ref]$date)
})
if ($badRows.Count -eq 0 -and $badDates.Count -eq 0) {
    Add-Result -Item "큐 액션" -Status "완료" -Evidence "액션, 패킷 경로, 권장 마감 확인"
}
else {
    Add-Result -Item "큐 액션" -Status "차단" -Evidence "필드 누락 $($badRows.Count), 날짜 오류 $($badDates.Count)" -NextAction "큐 생성 규칙을 확인한다."
}

$packetFailures = New-Object System.Collections.Generic.List[string]
foreach ($row in $queueRows) {
    $packetPath = Join-Path $EvidenceRoot ([string]$row.packet_path)
    $invitePath = Join-Path $EvidenceRoot ([string]$row.invite_path)
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $packetPath))) {
        $packetFailures.Add("$($row.id) packet missing") | Out-Null
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $invitePath))) {
        $packetFailures.Add("$($row.id) invite missing") | Out-Null
    }
}
if ($packetFailures.Count -eq 0) {
    Add-Result -Item "패킷 연결" -Status "완료" -Evidence "큐의 패킷과 초대문 경로 확인"
}
else {
    Add-Result -Item "패킷 연결" -Status "차단" -Evidence (($packetFailures | Select-Object -First 8) -join "; ") -NextAction "WriteExternalReviewerPackets.ps1를 다시 실행한다."
}

$needsOwnerRows = @($queueRows | Where-Object { $_.current_action -eq "리뷰어 배정" })
if ($RequireNoNeedsOwner -and $needsOwnerRows.Count -gt 0) {
    Add-Result -Item "배정 완료 조건" -Status "차단" -Evidence "배정 필요 $($needsOwnerRows.Count)" -NextAction "EXTERNAL_REVIEW_TRACKER.tsv에 reviewer_alias, contact_method, due_at을 채운다."
}
else {
    Add-Result -Item "배정 완료 조건" -Status "완료" -Evidence "배정 필요 $($needsOwnerRows.Count)"
}

$docsText = Get-Text -Path $DocsPath
if ($docsText -ne "" -and $docsText -match "외부 리뷰 발송 큐" -and $docsText -match "오늘 할 일" -and $docsText -match "검증 명령") {
    Add-Result -Item "요약 문서" -Status "완료" -Evidence $DocsPath
    $textPaths.Add($DocsPath) | Out-Null
}
else {
    Add-Result -Item "요약 문서" -Status "차단" -Evidence "문서 누락 또는 핵심 문구 누락" -NextAction "WriteExternalReviewOutreachQueue.ps1를 다시 실행한다."
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
    Add-Result -Item "비밀키 형태 문자열" -Status "차단" -Evidence "$($secretMatches.Count)개 발견" -NextAction "큐와 문서에서 비밀키 형태 문자열을 제거한다."
}
if ($emphasisMatches.Count -eq 0) {
    Add-Result -Item "별표 강조 제거" -Status "완료" -Evidence "markdown 강조 없음"
}
else {
    Add-Result -Item "별표 강조 제거" -Status "차단" -Evidence "$($emphasisMatches.Count)개 발견" -NextAction "큐와 문서에서 별표 강조를 제거한다."
}

$blocked = @($results | Where-Object { $_.Status -eq "차단" }).Count
$completed = @($results | Where-Object { $_.Status -eq "완료" }).Count
$status = if ($blocked -gt 0) { "차단" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰 발송 큐 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $completed")
$lines.Add("- 차단: $blocked")
$lines.Add("- 큐 TSV: $QueuePath")
$lines.Add("- 큐 항목 수: $($queueRows.Count)")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.NextAction) |")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External review outreach queue QA written: $OutputPath"
Write-Host "Status: $status, completed: $completed, blocked: $blocked, queue rows: $($queueRows.Count)"

if ($blocked -gt 0) {
    throw "External review outreach queue QA has $blocked blocked item(s)."
}
