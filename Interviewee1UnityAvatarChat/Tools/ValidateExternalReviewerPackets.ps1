param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$PacketRoot,
    [string]$DocsPath,
    [string]$OutputPath,
    [switch]$RequireAssigned
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
if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    $DocsPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_PACKETS.md"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_PACKETS_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]
$requiredIds = @("PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "ACCESS-01", "ART-01", "TRAILER-01", "LEGAL-01", "QUALITY-01", "ISSUE-01")
$textPaths = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    Add-Result -Item "추적 TSV" -Status "차단" -Evidence "파일 없음: $TrackerPath" -NextAction "WriteExternalReviewTracker.ps1를 실행한다."
    $rows = @()
}
else {
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
    Add-Result -Item "추적 TSV" -Status "완료" -Evidence "$($rows.Count)개 행 확인"
    $textPaths.Add($TrackerPath) | Out-Null
}

$docsText = Get-Text -Path $DocsPath
if ($docsText -ne "" -and $docsText -match "외부 리뷰어 전달 패킷" -and $docsText -match "ReviewerPackets" -and $docsText -match "검증 명령") {
    Add-Result -Item "요약 문서" -Status "완료" -Evidence $DocsPath
    $textPaths.Add($DocsPath) | Out-Null
}
else {
    Add-Result -Item "요약 문서" -Status "차단" -Evidence "문서 누락 또는 핵심 문구 누락" -NextAction "WriteExternalReviewerPackets.ps1를 다시 실행한다."
}

$missingIds = @($requiredIds | Where-Object { $id = $_; -not ($rows | Where-Object { $_.id -eq $id }) })
$packetFailures = New-Object System.Collections.Generic.List[string]
$packetCount = 0
foreach ($row in $rows) {
    $id = [string]$row.id
    if ([string]::IsNullOrWhiteSpace($id)) {
        continue
    }

    $packetPath = Join-Path $PacketRoot $id
    $readmePath = Join-Path $packetPath "README.md"
    $invitePath = Join-Path $packetPath "INVITE.txt"
    $checklistPath = Join-Path $packetPath "ACCEPTANCE_CHECKLIST.tsv"
    $returnChecklistPath = Join-Path $packetPath "RETURN_CHECKLIST.tsv"
    $sourceBriefPath = Join-Path $packetPath "SOURCE_BRIEF.md"
    $calibrationPath = Join-Path $packetPath "DECISION_CALIBRATION.tsv"
    foreach ($path in @($readmePath, $invitePath, $checklistPath, $returnChecklistPath, $sourceBriefPath, $calibrationPath)) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            $packetFailures.Add("$id missing $(Split-Path -Leaf $path)") | Out-Null
        }
        else {
            $textPaths.Add($path) | Out-Null
        }
    }

    $readme = Get-Text -Path $readmePath
    foreach ($phrase in @($id, [string]$row.role, "제출 위치", "검증 명령", "금지 자료")) {
        if ($readme -notmatch [regex]::Escape($phrase)) {
            $packetFailures.Add("$id README missing $phrase") | Out-Null
        }
    }
    if ($readme -notmatch [regex]::Escape("DECISION_CALIBRATION.tsv")) {
        $packetFailures.Add("$id README missing DECISION_CALIBRATION.tsv") | Out-Null
    }
    if ($readme -notmatch [regex]::Escape("RETURN_CHECKLIST.tsv")) {
        $packetFailures.Add("$id README missing RETURN_CHECKLIST.tsv") | Out-Null
    }
    if ($id -match "^PT-" -and $readme -notmatch [regex]::Escape("NewPlaytestEvidenceBundle.ps1")) {
        $packetFailures.Add("$id README missing NewPlaytestEvidenceBundle.ps1") | Out-Null
    }

    $invite = Get-Text -Path $invitePath
    foreach ($phrase in @("겉!=속", [string]$row.role, "API 키", "DECISION_CALIBRATION.tsv", "RETURN_CHECKLIST.tsv")) {
        if ($invite -notmatch [regex]::Escape($phrase)) {
            $packetFailures.Add("$id INVITE missing $phrase") | Out-Null
        }
    }
    if ($id -match "^PT-" -and $invite -notmatch [regex]::Escape("NewPlaytestEvidenceBundle.ps1")) {
        $packetFailures.Add("$id INVITE missing NewPlaytestEvidenceBundle.ps1") | Out-Null
    }

    $calibration = Get-Text -Path $calibrationPath
    foreach ($phrase in @("price_ready_4_or_5", "borderline_3", "blocker_or_2_or_less", "required_evidence")) {
        if ($calibration -notmatch [regex]::Escape($phrase)) {
            $packetFailures.Add("$id calibration missing $phrase") | Out-Null
        }
    }

    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $checklistPath)) {
        $checklist = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $checklistPath) -Encoding UTF8)
        $requiredItems = @("reviewer_confirmed", "package_opened", "brief_read", "calibration_read", "evidence_added", "validation_ran", "issues_registered", "no_secrets", "ready_for_import")
        foreach ($item in $requiredItems) {
            if (-not ($checklist | Where-Object { $_.item -eq $item })) {
                $packetFailures.Add("$id checklist missing $item") | Out-Null
            }
        }
        if ($id -match "^PT-" -and -not ($checklist | Where-Object { $_.item -eq "evidence_bundle_created" })) {
            $packetFailures.Add("$id checklist missing evidence_bundle_created") | Out-Null
        }
    }

    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $returnChecklistPath)) {
        $returnChecklist = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $returnChecklistPath) -Encoding UTF8)
        $requiredReturnItems = @("required_evidence_present", "filled_forms_renamed", "quality_index_checked", "raw_feedback_or_media_present", "quality_scorecard_updated", "issue_register_updated", "validation_report_saved", "secret_scan_clean", "return_scope_clean", "ready_to_return")
        foreach ($item in $requiredReturnItems) {
            if (-not ($returnChecklist | Where-Object { $_.item -eq $item })) {
                $packetFailures.Add("$id return checklist missing $item") | Out-Null
            }
        }
        if ($id -match "^PT-" -and -not ($returnChecklist | Where-Object { $_.item -eq "evidence_bundle_created" })) {
            $packetFailures.Add("$id return checklist missing evidence_bundle_created") | Out-Null
        }
    }

    $packetCount += 1
}

if ($missingIds.Count -eq 0 -and $packetFailures.Count -eq 0 -and $packetCount -ge $requiredIds.Count) {
    Add-Result -Item "리뷰어 패킷 파일" -Status "완료" -Evidence "${packetCount}개 패킷 확인"
}
elseif ($missingIds.Count -gt 0) {
    Add-Result -Item "리뷰어 패킷 파일" -Status "차단" -Evidence "누락 ID: $($missingIds -join ', ')" -NextAction "WriteExternalReviewTracker.ps1와 WriteExternalReviewerPackets.ps1를 다시 실행한다."
}
else {
    $sample = ($packetFailures | Select-Object -First 8) -join "; "
    Add-Result -Item "리뷰어 패킷 파일" -Status "차단" -Evidence $sample -NextAction "WriteExternalReviewerPackets.ps1를 다시 실행한다."
}

$manifestPath = Join-Path $PacketRoot "REVIEWER_PACKET_MANIFEST.tsv"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $manifestPath)) {
    $manifestRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $manifestPath) -Encoding UTF8)
    if ($manifestRows.Count -ge $requiredIds.Count) {
        Add-Result -Item "패킷 manifest" -Status "완료" -Evidence "$($manifestRows.Count)개 행 확인"
        $textPaths.Add($manifestPath) | Out-Null
    }
    else {
        Add-Result -Item "패킷 manifest" -Status "차단" -Evidence "행 부족: $($manifestRows.Count)" -NextAction "WriteExternalReviewerPackets.ps1를 다시 실행한다."
    }
}
else {
    Add-Result -Item "패킷 manifest" -Status "차단" -Evidence "파일 없음: $manifestPath" -NextAction "WriteExternalReviewerPackets.ps1를 다시 실행한다."
}

$assignedRows = @($rows | Where-Object { $_.assignment_status -ne "needs_owner" }).Count
if ($RequireAssigned -and $assignedRows -lt $requiredIds.Count) {
    Add-Result -Item "리뷰어 배정 상태" -Status "차단" -Evidence "배정 $assignedRows/$($requiredIds.Count)" -NextAction "EXTERNAL_REVIEW_TRACKER.tsv에 reviewer_alias, contact_method, due_at을 채운다."
}
else {
    Add-Result -Item "리뷰어 배정 상태" -Status "완료" -Evidence "배정 $assignedRows/$($requiredIds.Count)"
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
    Add-Result -Item "비밀키 형태 문자열" -Status "차단" -Evidence "$($secretMatches.Count)개 발견" -NextAction "패킷과 문서에서 비밀키 형태 문자열을 제거한다."
}
if ($emphasisMatches.Count -eq 0) {
    Add-Result -Item "별표 강조 제거" -Status "완료" -Evidence "markdown 강조 없음"
}
else {
    Add-Result -Item "별표 강조 제거" -Status "차단" -Evidence "$($emphasisMatches.Count)개 발견" -NextAction "패킷과 문서에서 별표 강조를 제거한다."
}

$blocked = @($results | Where-Object { $_.Status -eq "차단" }).Count
$completed = @($results | Where-Object { $_.Status -eq "완료" }).Count
$status = if ($blocked -gt 0) { "차단" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰어 전달 패킷 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $completed")
$lines.Add("- 차단: $blocked")
$lines.Add("- 패킷 폴더: $PacketRoot")
$lines.Add("- 패킷 수: $packetCount")
$lines.Add("- 담당 배정: $assignedRows")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.NextAction) |")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path (ConvertTo-LongPath -Path $outputDirectory) | Out-Null
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External reviewer packets QA written: $OutputPath"
Write-Host "Status: $status, completed: $completed, blocked: $blocked, packets: $packetCount"

if ($blocked -gt 0) {
    throw "External reviewer packets QA has $blocked blocked item(s)."
}


