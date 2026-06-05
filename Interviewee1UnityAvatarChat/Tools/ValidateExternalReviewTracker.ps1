param(
    [string]$TrackerPath,
    [string]$OutputPath,
    [switch]$RequireComplete
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

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($TrackerPath)) {
    $TrackerPath = Join-Path $buildRoot "ReleaseEvidence\EXTERNAL_REVIEW_TRACKER.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_TRACKER_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]
$requiredIds = @("PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "ACCESS-01", "ART-01", "TRAILER-01", "LEGAL-01", "QUALITY-01", "ISSUE-01")
$allowedInviteStatuses = @("not_sent", "sent", "accepted", "declined")
$allowedEvidenceStatuses = @("missing", "partial", "complete")

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    Add-Result -Item "추적 TSV" -Status "차단" -Evidence "파일 없음: $TrackerPath" -NextAction "WriteExternalReviewTracker.ps1를 실행한다."
    $rows = @()
}
else {
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
    $missingIds = @($requiredIds | Where-Object { $id = $_; -not ($rows | Where-Object { $_.id -eq $id }) })
    if ($missingIds.Count -eq 0 -and $rows.Count -ge $requiredIds.Count) {
        Add-Result -Item "추적 TSV" -Status "완료" -Evidence "$($rows.Count)개 행 확인"
    }
    else {
        Add-Result -Item "추적 TSV" -Status "차단" -Evidence "누락 ID: $($missingIds -join ', ')" -NextAction "WriteExternalReviewTracker.ps1를 다시 실행한다."
    }
}

$badInvite = @($rows | Where-Object { $allowedInviteStatuses -notcontains $_.invite_status })
$badEvidence = @($rows | Where-Object { $allowedEvidenceStatuses -notcontains $_.evidence_status })
$missingBriefs = @($rows | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.brief_file) -or [string]::IsNullOrWhiteSpace([string]$_.validation_command) })
if ($badInvite.Count -eq 0 -and $badEvidence.Count -eq 0 -and $missingBriefs.Count -eq 0) {
    Add-Result -Item "상태값과 검증 명령" -Status "완료" -Evidence "invite/evidence 상태값과 validation_command 확인"
}
else {
    Add-Result -Item "상태값과 검증 명령" -Status "차단" -Evidence "invite 오류 $($badInvite.Count), evidence 오류 $($badEvidence.Count), 명령 누락 $($missingBriefs.Count)" -NextAction "TSV 상태값과 검증 명령을 수정한다."
}

$completeRows = @($rows | Where-Object { $_.evidence_status -eq "complete" }).Count
$partialRows = @($rows | Where-Object { $_.evidence_status -eq "partial" }).Count
$missingRows = @($rows | Where-Object { $_.evidence_status -eq "missing" }).Count
$assignedRows = @($rows | Where-Object { $_.assignment_status -ne "needs_owner" }).Count
if ($RequireComplete -and $completeRows -lt $requiredIds.Count) {
    Add-Result -Item "외부 리뷰 완료 상태" -Status "차단" -Evidence "완료 $completeRows/$($requiredIds.Count)" -NextAction "모든 외부 리뷰 증거를 수집하고 검증 명령을 통과시킨다."
}
else {
    Add-Result -Item "외부 리뷰 완료 상태" -Status "완료" -Evidence "완료 $completeRows, 일부 $partialRows, 없음 $missingRows, 배정 $assignedRows"
}

$secretMatches = @()
$emphasisMatches = @()
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath)) {
    $secretMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue)
    $emphasisMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Pattern "\*\*" -ErrorAction SilentlyContinue)
}
if ($secretMatches.Count -eq 0) {
    Add-Result -Item "비밀키 형태 문자열" -Status "완료" -Evidence "발견 0"
}
else {
    Add-Result -Item "비밀키 형태 문자열" -Status "차단" -Evidence "$($secretMatches.Count)개 발견" -NextAction "추적 TSV에서 비밀키 형태 문자열을 제거한다."
}
if ($emphasisMatches.Count -eq 0) {
    Add-Result -Item "별표 강조 제거" -Status "완료" -Evidence "markdown 강조 없음"
}
else {
    Add-Result -Item "별표 강조 제거" -Status "차단" -Evidence "$($emphasisMatches.Count)개 발견" -NextAction "추적 TSV에서 별표 강조를 제거한다."
}

$blocked = @($results | Where-Object { $_.Status -eq "차단" }).Count
$completed = @($results | Where-Object { $_.Status -eq "완료" }).Count
$status = if ($blocked -gt 0) { "차단" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰 진행 추적 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $completed")
$lines.Add("- 차단: $blocked")
$lines.Add("- 추적 TSV: $TrackerPath")
$lines.Add("- 추적 항목: $($rows.Count)")
$lines.Add("- 담당 배정: $assignedRows")
$lines.Add("- 증거 완료: $completeRows")
$lines.Add("- 증거 일부: $partialRows")
$lines.Add("- 증거 없음: $missingRows")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.NextAction) |")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External review tracker QA written: $OutputPath"
Write-Host "Status: $status, completed: $completed, blocked: $blocked"

if ($blocked -gt 0) {
    throw "External review tracker QA has $blocked blocked item(s)."
}
