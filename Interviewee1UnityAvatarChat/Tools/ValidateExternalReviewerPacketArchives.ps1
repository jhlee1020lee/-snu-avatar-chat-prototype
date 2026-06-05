param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$ArchiveRoot,
    [string]$ManifestPath,
    [string]$OutputPath,
    [switch]$RequireAssigned
)

$ErrorActionPreference = "Stop"
$RequiredIds = @("PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "ACCESS-01", "ART-01", "TRAILER-01", "LEGAL-01", "QUALITY-01", "ISSUE-01")
$RequiredEntries = @("README.md", "INVITE.txt", "ACCEPTANCE_CHECKLIST.tsv", "RETURN_CHECKLIST.tsv", "SOURCE_BRIEF.md", "DECISION_CALIBRATION.tsv")

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

function Ensure-Directory {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path (ConvertTo-LongPath -Path $Path) | Out-Null
    }
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Add-Result {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Evidence,
        [string]$NextAction = ""
    )

    $script:results.Add([pscustomobject]@{
        item = $Item
        status = $Status
        evidence = $Evidence
        next_action = $NextAction
    }) | Out-Null
}

function Resolve-EvidencePath {
    param(
        [string]$Reference,
        [string]$EvidenceRootPath
    )

    if ([System.IO.Path]::IsPathRooted($Reference)) {
        return $Reference
    }
    return Join-Path $EvidenceRootPath $Reference
}

function Get-FileSha256 {
    param([string]$Path)

    (Get-FileHash -LiteralPath (ConvertTo-LongPath -Path $Path) -Algorithm SHA256 -ErrorAction Stop).Hash
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $EvidenceRoot = Join-Path $projectRoot "EvidenceDrop"
    }
    else {
        $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
    }
}
if ([string]::IsNullOrWhiteSpace($TrackerPath)) {
    $TrackerPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_TRACKER.tsv"
}
if ([string]::IsNullOrWhiteSpace($ArchiveRoot)) {
    $ArchiveRoot = Join-Path $EvidenceRoot "ReviewerPacketArchives"
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $ArchiveRoot "REVIEWER_PACKET_ARCHIVE_MANIFEST.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $OutputPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEWER_PACKET_ARCHIVES_QA.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_PACKET_ARCHIVES_QA.md"
    }
}

$results = New-Object System.Collections.Generic.List[object]
$archiveIssues = New-Object System.Collections.Generic.List[string]
$archiveCount = 0
$assignedRows = 0

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    Add-Result "추적 TSV" "차단" "파일 없음: $TrackerPath" "WriteExternalReviewTracker.ps1를 실행한다."
    $trackerRows = @()
}
else {
    $trackerRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
    Add-Result "추적 TSV" "완료" "$($trackerRows.Count)개 행 확인"
    $assignedRows = @($trackerRows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.reviewer_alias) -and -not [string]::IsNullOrWhiteSpace([string]$_.contact_method) -and -not [string]::IsNullOrWhiteSpace([string]$_.due_at) }).Count
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $ManifestPath))) {
    Add-Result "ZIP manifest" "차단" "파일 없음: $ManifestPath" "WriteExternalReviewerPacketArchives.ps1를 실행한다."
    $manifestRows = @()
}
else {
    $manifestRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $ManifestPath) -Encoding UTF8)
    $columns = if ($manifestRows.Count -gt 0) { @($manifestRows[0].PSObject.Properties.Name) } else { @() }
    foreach ($column in @("id", "archive_path", "packet_path", "bytes", "sha256")) {
        if ($columns -notcontains $column) {
            $archiveIssues.Add("manifest missing column $column") | Out-Null
        }
    }
    if ($manifestRows.Count -ge $RequiredIds.Count) {
        Add-Result "ZIP manifest" "완료" "$($manifestRows.Count)개 행 확인"
    }
    else {
        Add-Result "ZIP manifest" "차단" "행 부족: $($manifestRows.Count)" "WriteExternalReviewerPacketArchives.ps1를 실행한다."
    }
}

foreach ($id in $RequiredIds) {
    $row = $manifestRows | Where-Object { $_.id -eq $id } | Select-Object -First 1
    if ($null -eq $row) {
        $archiveIssues.Add("$id archive manifest row missing") | Out-Null
        continue
    }

    $archivePath = Resolve-EvidencePath -Reference ([string]$row.archive_path) -EvidenceRootPath $EvidenceRoot
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $archivePath))) {
        $archiveIssues.Add("$id archive missing: $archivePath") | Out-Null
        continue
    }

    $item = Get-Item -LiteralPath (ConvertTo-LongPath -Path $archivePath)
    if ($item.Length -lt 1000) {
        $archiveIssues.Add("$id archive too small: $($item.Length)") | Out-Null
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$row.bytes) -and [int64]$row.bytes -ne $item.Length) {
        $archiveIssues.Add("$id byte count mismatch") | Out-Null
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$row.sha256) -and ([string]$row.sha256).ToUpperInvariant() -ne (Get-FileSha256 -Path $archivePath).ToUpperInvariant()) {
        $archiveIssues.Add("$id sha256 mismatch") | Out-Null
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $entryNames = @($zip.Entries | ForEach-Object { $_.FullName.Replace("/", "\") })
        foreach ($entry in $entryNames) {
            if ($entry -match '(^|\\)\.\.(\\|$)' -or [System.IO.Path]::IsPathRooted($entry)) {
                $archiveIssues.Add("$id unsafe zip entry: $entry") | Out-Null
            }
        }
        foreach ($required in $RequiredEntries) {
            if (-not ($entryNames | Where-Object { $_ -eq $required -or $_ -like "*\$required" })) {
                $archiveIssues.Add("$id archive missing $required") | Out-Null
            }
        }
    }
    finally {
        $zip.Dispose()
    }
    $archiveCount++
}

if ($archiveIssues.Count -eq 0 -and $archiveCount -ge $RequiredIds.Count) {
    Add-Result "리뷰어 패킷 ZIP" "완료" "$archiveCount개 ZIP 확인"
}
else {
    Add-Result "리뷰어 패킷 ZIP" "차단" (($archiveIssues | Select-Object -First 8) -join "; ") "WriteExternalReviewerPacketArchives.ps1를 다시 실행한다."
}

if ($RequireAssigned -and $assignedRows -lt $RequiredIds.Count) {
    Add-Result "리뷰어 배정 상태" "차단" "배정 $assignedRows/$($RequiredIds.Count)" "EXTERNAL_REVIEWER_ROSTER.tsv를 채우고 ApplyExternalReviewerRoster.ps1를 실행한다."
}
else {
    Add-Result "리뷰어 배정 상태" "완료" "배정 $assignedRows/$($RequiredIds.Count)"
}

$blocked = @($results | Where-Object { $_.status -eq "차단" }).Count
$completed = @($results | Where-Object { $_.status -eq "완료" }).Count
$status = if ($blocked -gt 0) { "차단" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰어 패킷 ZIP QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $completed")
$lines.Add("- 차단: $blocked")
$lines.Add("- ZIP 폴더: $ArchiveRoot")
$lines.Add("- ZIP 수: $archiveCount")
$lines.Add("- 담당 배정: $assignedRows")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.item) | $(Escape-MarkdownCell $result.status) | $(Escape-MarkdownCell $result.evidence) | $(Escape-MarkdownCell $result.next_action) |")
}

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External reviewer packet archives QA written: $OutputPath"
Write-Host "Status: $status, completed: $completed, blocked: $blocked, archives: $archiveCount"

if ($blocked -gt 0) {
    throw "External reviewer packet archives QA has $blocked blocked item(s)."
}
