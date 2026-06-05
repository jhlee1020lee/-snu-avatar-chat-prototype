param(
    [string]$EvidenceRoot,
    [string]$OutboxRoot,
    [string]$ManifestPath,
    [string]$DocsPath,
    [string]$OutputPath,
    [switch]$RequireReadyToSend
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

function Resolve-EvidencePath {
    param([string]$RelativeOrFullPath)

    if ([string]::IsNullOrWhiteSpace($RelativeOrFullPath)) {
        return ""
    }
    if ([System.IO.Path]::IsPathRooted($RelativeOrFullPath)) {
        return $RelativeOrFullPath
    }
    return Join-Path $EvidenceRoot $RelativeOrFullPath
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($OutboxRoot)) {
    $OutboxRoot = Join-Path $EvidenceRoot "ReviewerInviteOutbox"
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $OutboxRoot "INVITE_OUTBOX_MANIFEST.tsv"
}
if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    $DocsPath = Join-Path $docsRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]
$requiredIds = @("PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "ACCESS-01", "ART-01", "TRAILER-01", "LEGAL-01", "QUALITY-01", "ISSUE-01")
$textPaths = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $ManifestPath))) {
    Add-Result -Item "outbox manifest" -Status "blocked" -Evidence "missing: $ManifestPath" -NextAction "Run WriteExternalReviewInviteOutbox.ps1."
    $rows = @()
}
else {
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $ManifestPath) -Encoding UTF8)
    $textPaths.Add($ManifestPath) | Out-Null
    Add-Result -Item "outbox manifest" -Status "complete" -Evidence "$($rows.Count) rows"
}

$requiredColumns = @("id", "role", "status", "reviewer_alias", "contact_method", "invite_status", "due_at", "suggested_due_at", "packet_path", "invite_path", "archive_path", "evidence_path", "outbox_path", "next_action")
$missingColumns = New-Object System.Collections.Generic.List[string]
if ($rows.Count -gt 0) {
    foreach ($column in $requiredColumns) {
        if ($rows[0].PSObject.Properties.Name -notcontains $column) {
            $missingColumns.Add($column) | Out-Null
        }
    }
}
if ($rows.Count -gt 0 -and $missingColumns.Count -eq 0) {
    Add-Result -Item "manifest columns" -Status "complete" -Evidence "required columns present"
}
else {
    Add-Result -Item "manifest columns" -Status "blocked" -Evidence "missing: $($missingColumns -join ', ')" -NextAction "Regenerate invite outbox."
}

$missingIds = @($requiredIds | Where-Object { $id = $_; -not ($rows | Where-Object { $_.id -eq $id }) })
if ($missingIds.Count -eq 0 -and $rows.Count -ge $requiredIds.Count) {
    Add-Result -Item "required reviewer ids" -Status "complete" -Evidence "$($requiredIds.Count) ids present"
}
else {
    Add-Result -Item "required reviewer ids" -Status "blocked" -Evidence "missing: $($missingIds -join ', ')" -NextAction "Regenerate tracker, queue, packets, and invite outbox."
}

$fileFailures = New-Object System.Collections.Generic.List[string]
foreach ($row in $rows) {
    $outboxPath = Resolve-EvidencePath -RelativeOrFullPath ([string]$row.outbox_path)
    $packetPath = Resolve-EvidencePath -RelativeOrFullPath ([string]$row.packet_path)
    $invitePath = Resolve-EvidencePath -RelativeOrFullPath ([string]$row.invite_path)
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $outboxPath))) {
        $fileFailures.Add("$($row.id) outbox missing") | Out-Null
        continue
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $packetPath))) {
        $fileFailures.Add("$($row.id) packet missing") | Out-Null
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $invitePath))) {
        $fileFailures.Add("$($row.id) invite missing") | Out-Null
    }
    $text = Get-Text -Path $outboxPath
    if ($text -notmatch "Source invite body" -or $text -notmatch "Do not add credentials") {
        $fileFailures.Add("$($row.id) outbox content incomplete") | Out-Null
    }
    if ([string]$row.id -match "^PT-" -and $text -notmatch "NewPlaytestEvidenceBundle.ps1") {
        $fileFailures.Add("$($row.id) missing playtest bundle command") | Out-Null
    }
    $textPaths.Add($outboxPath) | Out-Null
}
if ($fileFailures.Count -eq 0) {
    Add-Result -Item "outbox files" -Status "complete" -Evidence "files and source invite content verified"
}
else {
    Add-Result -Item "outbox files" -Status "blocked" -Evidence (($fileFailures | Select-Object -First 8) -join "; ") -NextAction "Regenerate invite outbox."
}

$needsAssignment = @($rows | Where-Object { $_.status -eq "needs_assignment" }).Count
$ready = @($rows | Where-Object { $_.status -eq "ready_to_send" }).Count
$alreadySent = @($rows | Where-Object { $_.status -eq "already_sent" }).Count
$badStatus = @($rows | Where-Object { $_.status -notin @("needs_assignment", "ready_to_send", "already_sent") })
if ($badStatus.Count -eq 0) {
    Add-Result -Item "outbox status values" -Status "complete" -Evidence "ready $ready, needs assignment $needsAssignment, already sent $alreadySent"
}
else {
    Add-Result -Item "outbox status values" -Status "blocked" -Evidence "$($badStatus.Count) invalid status rows" -NextAction "Regenerate invite outbox."
}

if ($RequireReadyToSend -and $needsAssignment -gt 0) {
    Add-Result -Item "ready-to-send condition" -Status "blocked" -Evidence "needs assignment $needsAssignment" -NextAction "Apply reviewer roster with aliases, contact routes, and due dates."
}
else {
    Add-Result -Item "ready-to-send condition" -Status "complete" -Evidence "needs assignment $needsAssignment"
}

$docsText = Get-Text -Path $DocsPath
if ($docsText -ne "" -and $docsText -match "External Review Invite Outbox" -and $docsText -match "copy-ready") {
    Add-Result -Item "summary document" -Status "complete" -Evidence $DocsPath
    $textPaths.Add($DocsPath) | Out-Null
}
else {
    Add-Result -Item "summary document" -Status "blocked" -Evidence "missing or incomplete: $DocsPath" -NextAction "Run WriteExternalReviewInviteOutbox.ps1."
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
    Add-Result -Item "secret-shaped strings" -Status "complete" -Evidence "found 0"
}
else {
    Add-Result -Item "secret-shaped strings" -Status "blocked" -Evidence "$($secretMatches.Count) found" -NextAction "Remove secret-shaped values from outbox files."
}
if ($emphasisMatches.Count -eq 0) {
    Add-Result -Item "markdown emphasis" -Status "complete" -Evidence "double-star emphasis not found"
}
else {
    Add-Result -Item "markdown emphasis" -Status "blocked" -Evidence "$($emphasisMatches.Count) found" -NextAction "Remove double-star markdown emphasis."
}

$blocked = @($results | Where-Object { $_.Status -eq "blocked" }).Count
$completed = @($results | Where-Object { $_.Status -eq "complete" }).Count
$status = if ($blocked -gt 0) { "blocked" } else { "complete" }

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# External Review Invite Outbox QA")
$lines.Add("")
$lines.Add("- Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- Status: $status")
$lines.Add("- Complete: $completed")
$lines.Add("- Blocked: $blocked")
$lines.Add("- Manifest: $ManifestPath")
$lines.Add("- Rows: $($rows.Count)")
$lines.Add("")
$lines.Add("| Item | Status | Evidence | Next action |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.NextAction) |")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External review invite outbox QA written: $OutputPath"
Write-Host "Status: $status, complete: $completed, blocked: $blocked, rows: $($rows.Count)"

if ($blocked -gt 0) {
    throw "External review invite outbox QA has $blocked blocked item(s)."
}
