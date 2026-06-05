param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$RosterPath,
    [string]$OutputPath
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

function Ensure-Directory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path (ConvertTo-LongPath -Path $Path) | Out-Null
    }
}

function Format-TsvCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Assert-NoApiKeyPattern {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            continue
        }
        $matches = Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($matches) {
            throw "Reviewer roster apply output contains an API key pattern: $path"
        }
    }
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
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER_APPLY.md"
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    & (Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}
if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $RosterPath))) {
    throw "Missing reviewer roster: $RosterPath"
}

$allowedInviteStatuses = @("not_sent", "sent", "accepted", "declined")
$trackerRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
$rosterRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $RosterPath) -Encoding UTF8)
$rosterMap = @{}
foreach ($row in $rosterRows) {
    if (-not [string]::IsNullOrWhiteSpace([string]$row.id)) {
        $rosterMap[[string]$row.id] = $row
    }
}

$applied = New-Object System.Collections.Generic.List[object]
$skipped = New-Object System.Collections.Generic.List[object]
$updatedRows = New-Object System.Collections.Generic.List[object]

foreach ($tracker in $trackerRows) {
    $id = [string]$tracker.id
    $roster = $rosterMap[$id]
    if ($roster) {
        $reviewer = [string]$roster.reviewer_alias
        $contact = [string]$roster.contact_method
        $dueAt = [string]$roster.due_at
        $inviteStatus = [string]$roster.invite_status
        if ([string]::IsNullOrWhiteSpace($inviteStatus)) {
            $inviteStatus = [string]$tracker.invite_status
        }
        if ($allowedInviteStatuses -notcontains $inviteStatus) {
            throw "Invalid invite_status '$inviteStatus' for $id"
        }

        if (-not [string]::IsNullOrWhiteSpace($reviewer) -and -not [string]::IsNullOrWhiteSpace($contact) -and -not [string]::IsNullOrWhiteSpace($dueAt)) {
            $dueDate = [datetime]::MinValue
            if (-not [datetime]::TryParse($dueAt, [ref]$dueDate)) {
                throw "Invalid due_at '$dueAt' for $id"
            }
            if ($dueDate.Date -lt (Get-Date).Date) {
                throw "Past due_at '$dueAt' for $id; choose today or a future date."
            }

            $tracker.reviewer_alias = $reviewer.Trim()
            $tracker.contact_method = $contact.Trim()
            $tracker.due_at = $dueAt.Trim()
            $tracker.invite_status = $inviteStatus.Trim()
            if ($roster.PSObject.Properties.Name -contains "invite_sent_at" -and -not [string]::IsNullOrWhiteSpace([string]$roster.invite_sent_at)) {
                $tracker.invite_sent_at = ([string]$roster.invite_sent_at).Trim()
            }
            if ($roster.PSObject.Properties.Name -contains "notes" -and -not [string]::IsNullOrWhiteSpace([string]$roster.notes)) {
                $tracker.notes = ([string]$roster.notes).Trim()
            }
            $applied.Add([pscustomobject]@{ id = $id; role = [string]$tracker.role; reviewer = $tracker.reviewer_alias; due_at = $tracker.due_at }) | Out-Null
        }
        else {
            $skipped.Add([pscustomobject]@{ id = $id; role = [string]$tracker.role; reason = "reviewer_alias, contact_method, due_at 중 하나 이상 비어 있음" }) | Out-Null
        }
    }
    else {
        $skipped.Add([pscustomobject]@{ id = $id; role = [string]$tracker.role; reason = "명단 행 없음" }) | Out-Null
    }
    $updatedRows.Add($tracker) | Out-Null
}

$header = "id`trole`tassignment_status`treviewer_alias`tcontact_method`tinvite_status`tinvite_sent_at`tdue_at`treceived_at`tpackage`tbrief_file`tevidence_path`trequired_evidence`tevidence_status`tvalidation_command`texit_criteria`tnext_action`tnotes"
$trackerLines = New-Object System.Collections.Generic.List[string]
$trackerLines.Add($header)
foreach ($row in $updatedRows) {
    $assignmentStatus = if ([string]::IsNullOrWhiteSpace([string]$row.reviewer_alias)) { "needs_owner" } elseif ($row.invite_status -eq "sent" -or $row.invite_status -eq "accepted") { "assigned" } else { "owner_named" }
    $trackerLines.Add(@(
        (Format-TsvCell $row.id),
        (Format-TsvCell $row.role),
        (Format-TsvCell $assignmentStatus),
        (Format-TsvCell $row.reviewer_alias),
        (Format-TsvCell $row.contact_method),
        (Format-TsvCell $row.invite_status),
        (Format-TsvCell $row.invite_sent_at),
        (Format-TsvCell $row.due_at),
        (Format-TsvCell $row.received_at),
        (Format-TsvCell $row.package),
        (Format-TsvCell $row.brief_file),
        (Format-TsvCell $row.evidence_path),
        (Format-TsvCell $row.required_evidence),
        (Format-TsvCell $row.evidence_status),
        (Format-TsvCell $row.validation_command),
        (Format-TsvCell $row.exit_criteria),
        (Format-TsvCell $row.next_action),
        (Format-TsvCell $row.notes)
    ) -join "`t")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Value $trackerLines -Encoding UTF8

& (Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "WriteExternalReviewerPackets.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "WriteExternalReviewerPacketArchives.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "WriteExternalReviewOutreachQueue.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "WriteExternalReviewInviteOutbox.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "ValidateExternalReviewTracker.ps1") 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "ValidateExternalReviewerPackets.ps1") 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "ValidateExternalReviewerPacketArchives.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "ValidateExternalReviewOutreachQueue.ps1") 2>&1 | Out-Null
& (Join-Path $PSScriptRoot "ValidateExternalReviewInviteOutbox.ps1") -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰어 명단 적용 결과")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 적용: $($applied.Count)")
$lines.Add("- 건너뜀: $($skipped.Count)")
$lines.Add("- 추적 TSV: $TrackerPath")
$lines.Add("- 명단 TSV: $RosterPath")
$lines.Add("")
$lines.Add("| ID | 역할 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($row in $applied) {
    $lines.Add("| $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.role) | 적용 | $(Escape-MarkdownCell ($row.reviewer + ' / ' + $row.due_at)) |")
}
foreach ($row in $skipped) {
    $lines.Add("| $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.role) | 건너뜀 | $(Escape-MarkdownCell $row.reason) |")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Assert-NoApiKeyPattern -Paths @($TrackerPath, $RosterPath, $OutputPath)

Write-Host "External reviewer roster applied: $($applied.Count)"
Write-Host "Skipped: $($skipped.Count)"
Write-Host "Apply report: $OutputPath"
