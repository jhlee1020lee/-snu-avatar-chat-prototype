param(
    [string]$EvidenceRoot,
    [string]$QueuePath,
    [string]$PacketRoot,
    [string]$ArchiveRoot,
    [string]$OutboxRoot,
    [string]$ManifestPath,
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

function Get-Value {
    param(
        [object]$Row,
        [string]$Name
    )

    if ($Row -and $Row.PSObject.Properties.Name -contains $Name) {
        return [string]$Row.$Name
    }
    return ""
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

function Get-OutboxStatus {
    param([object]$Row)

    $reviewer = Get-Value -Row $Row -Name "reviewer_alias"
    $contact = Get-Value -Row $Row -Name "contact_method"
    $due = Get-Value -Row $Row -Name "due_at"
    $invite = Get-Value -Row $Row -Name "invite_status"

    if ($invite -eq "sent" -or $invite -eq "accepted") {
        return "already_sent"
    }
    if ([string]::IsNullOrWhiteSpace($reviewer) -or [string]::IsNullOrWhiteSpace($contact) -or [string]::IsNullOrWhiteSpace($due)) {
        return "needs_assignment"
    }
    return "ready_to_send"
}

function Assert-NoApiKeyPattern {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            continue
        }
        $matches = Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($matches) {
            throw "Invite outbox contains an API key pattern: $path"
        }
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($QueuePath)) {
    $QueuePath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv"
}
if ([string]::IsNullOrWhiteSpace($PacketRoot)) {
    $PacketRoot = Join-Path $EvidenceRoot "ReviewerPackets"
}
if ([string]::IsNullOrWhiteSpace($ArchiveRoot)) {
    $ArchiveRoot = Join-Path $EvidenceRoot "ReviewerPacketArchives"
}
if ([string]::IsNullOrWhiteSpace($OutboxRoot)) {
    $OutboxRoot = Join-Path $EvidenceRoot "ReviewerInviteOutbox"
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $OutboxRoot "INVITE_OUTBOX_MANIFEST.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md"
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $QueuePath))) {
    throw "Missing external review outreach queue: $QueuePath"
}

Ensure-Directory -Path $OutboxRoot
Ensure-Directory -Path (Split-Path -Parent $ManifestPath)
Ensure-Directory -Path (Split-Path -Parent $OutputPath)

Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $OutboxRoot) -Filter "*_INVITE_READY.txt" -File -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

$queueRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $QueuePath) -Encoding UTF8)
$manifestRows = New-Object System.Collections.Generic.List[object]
$textPaths = New-Object System.Collections.Generic.List[string]
$textPaths.Add($QueuePath) | Out-Null

foreach ($row in $queueRows) {
    $id = Get-Value -Row $row -Name "id"
    if ([string]::IsNullOrWhiteSpace($id)) {
        continue
    }

    $status = Get-OutboxStatus -Row $row
    $inviteRelative = Get-Value -Row $row -Name "invite_path"
    $packetRelative = Get-Value -Row $row -Name "packet_path"
    $archiveRelative = Join-Path "ReviewerPacketArchives" "$id.zip"
    $evidenceRelative = Get-Value -Row $row -Name "evidence_path"
    $outboxRelative = Join-Path "ReviewerInviteOutbox" "$($id)_INVITE_READY.txt"
    $invitePath = Resolve-EvidencePath -RelativeOrFullPath $inviteRelative
    $packetPath = Resolve-EvidencePath -RelativeOrFullPath $packetRelative
    $archivePath = Resolve-EvidencePath -RelativeOrFullPath $archiveRelative
    $evidencePath = Resolve-EvidencePath -RelativeOrFullPath $evidenceRelative
    $outboxPath = Resolve-EvidencePath -RelativeOrFullPath $outboxRelative
    $inviteBody = ""
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $invitePath)) {
        $inviteBody = Get-Content -LiteralPath (ConvertTo-LongPath -Path $invitePath) -Raw -Encoding UTF8
    }
    else {
        $inviteBody = "Missing source invite file: $invitePath"
    }

    $nextAction = "Assign reviewer_alias, contact_method, and due_at before sending."
    if ($status -eq "ready_to_send") {
        $nextAction = "Review this file, send the invite, then update invite_status and invite_sent_at."
    }
    elseif ($status -eq "already_sent") {
        $nextAction = "Wait for evidence or import returned EvidenceDrop."
    }

    $outboxLines = New-Object System.Collections.Generic.List[string]
    $outboxLines.Add("External review invite outbox item")
    $outboxLines.Add("")
    $outboxLines.Add("id: $id")
    $outboxLines.Add("role: $(Get-Value -Row $row -Name 'role')")
    $outboxLines.Add("status: $status")
    $outboxLines.Add("reviewer_alias: $(Get-Value -Row $row -Name 'reviewer_alias')")
    $outboxLines.Add("contact_method: $(Get-Value -Row $row -Name 'contact_method')")
    $outboxLines.Add("invite_status: $(Get-Value -Row $row -Name 'invite_status')")
    $outboxLines.Add("due_at: $(Get-Value -Row $row -Name 'due_at')")
    $outboxLines.Add("suggested_due_at: $(Get-Value -Row $row -Name 'suggested_due_at')")
    $outboxLines.Add("packet_path: $packetRelative")
    $outboxLines.Add("archive_path: $archiveRelative")
    $outboxLines.Add("evidence_path: $evidenceRelative")
    $outboxLines.Add("source_invite_path: $inviteRelative")
    $outboxLines.Add("next_action: $nextAction")
    $outboxLines.Add("")
    $outboxLines.Add("Attachments to include")
    $outboxLines.Add("- $packetRelative")
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $archivePath)) {
        $outboxLines.Add("- $archiveRelative")
    }
    $outboxLines.Add("")
    $outboxLines.Add("Do not add credentials, passwords, Steam Guard codes, payment details, or API keys.")
    $outboxLines.Add("")
    $outboxLines.Add("Source invite body")
    $outboxLines.Add("")
    $outboxLines.Add($inviteBody.Trim())
    Set-Content -LiteralPath (ConvertTo-LongPath -Path $outboxPath) -Value $outboxLines -Encoding UTF8
    $textPaths.Add($outboxPath) | Out-Null

    $manifestRows.Add([pscustomobject]@{
        id = $id
        role = Get-Value -Row $row -Name "role"
        status = $status
        reviewer_alias = Get-Value -Row $row -Name "reviewer_alias"
        contact_method = Get-Value -Row $row -Name "contact_method"
        invite_status = Get-Value -Row $row -Name "invite_status"
        invite_sent_at = Get-Value -Row $row -Name "invite_sent_at"
        due_at = Get-Value -Row $row -Name "due_at"
        suggested_due_at = Get-Value -Row $row -Name "suggested_due_at"
        packet_path = $packetRelative
        invite_path = $inviteRelative
        archive_path = $archiveRelative
        evidence_path = $evidenceRelative
        outbox_path = $outboxRelative
        next_action = $nextAction
    }) | Out-Null
}

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("id`trole`tstatus`treviewer_alias`tcontact_method`tinvite_status`tinvite_sent_at`tdue_at`tsuggested_due_at`tpacket_path`tinvite_path`tarchive_path`tevidence_path`toutbox_path`tnext_action")
foreach ($row in $manifestRows) {
    $manifestLines.Add(@(
        (Format-TsvCell $row.id),
        (Format-TsvCell $row.role),
        (Format-TsvCell $row.status),
        (Format-TsvCell $row.reviewer_alias),
        (Format-TsvCell $row.contact_method),
        (Format-TsvCell $row.invite_status),
        (Format-TsvCell $row.invite_sent_at),
        (Format-TsvCell $row.due_at),
        (Format-TsvCell $row.suggested_due_at),
        (Format-TsvCell $row.packet_path),
        (Format-TsvCell $row.invite_path),
        (Format-TsvCell $row.archive_path),
        (Format-TsvCell $row.evidence_path),
        (Format-TsvCell $row.outbox_path),
        (Format-TsvCell $row.next_action)
    ) -join "`t")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $ManifestPath) -Value $manifestLines -Encoding UTF8
$textPaths.Add($ManifestPath) | Out-Null

$ready = @($manifestRows | Where-Object { $_.status -eq "ready_to_send" }).Count
$needsAssignment = @($manifestRows | Where-Object { $_.status -eq "needs_assignment" }).Count
$alreadySent = @($manifestRows | Where-Object { $_.status -eq "already_sent" }).Count
$summaryStatus = "needs_assignment"
if ($manifestRows.Count -gt 0 -and $needsAssignment -eq 0) {
    $summaryStatus = "ready"
}
if ($manifestRows.Count -gt 0 -and $alreadySent -eq $manifestRows.Count) {
    $summaryStatus = "sent_or_waiting"
}

$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add("# External Review Invite Outbox")
$summaryLines.Add("")
$summaryLines.Add("- Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$summaryLines.Add("- Status: $summaryStatus")
$summaryLines.Add("- Total: $($manifestRows.Count)")
$summaryLines.Add("- Ready to send: $ready")
$summaryLines.Add("- Needs assignment: $needsAssignment")
$summaryLines.Add("- Already sent: $alreadySent")
$summaryLines.Add("- Outbox root: $OutboxRoot")
$summaryLines.Add("- Manifest: $ManifestPath")
$summaryLines.Add("")
$summaryLines.Add("This outbox turns the tracker queue and ReviewerPackets invites into copy-ready files. It does not mark anything as sent and does not replace returned external evidence.")
$summaryLines.Add("")
$summaryLines.Add("| ID | Role | Status | Reviewer | Contact | Due | Outbox | Next action |")
$summaryLines.Add("| --- | --- | --- | --- | --- | --- | --- | --- |")
foreach ($row in $manifestRows) {
    $summaryLines.Add("| $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.role) | $(Escape-MarkdownCell $row.status) | $(Escape-MarkdownCell $row.reviewer_alias) | $(Escape-MarkdownCell $row.contact_method) | $(Escape-MarkdownCell $row.due_at) | $(Escape-MarkdownCell $row.outbox_path) | $(Escape-MarkdownCell $row.next_action) |")
}
$summaryLines.Add("")
$summaryLines.Add("Validation command")
$summaryLines.Add("")
$summaryLines.Add('```powershell')
$summaryLines.Add(".\Tools\ValidateExternalReviewInviteOutbox.ps1")
$summaryLines.Add('```')
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $summaryLines -Encoding UTF8
$textPaths.Add($OutputPath) | Out-Null

Assert-NoApiKeyPattern -Paths $textPaths.ToArray()

Write-Host "External review invite outbox written: $OutboxRoot"
Write-Host "Invite outbox manifest written: $ManifestPath"
Write-Host "Invite outbox summary written: $OutputPath"
Write-Host "Outbox status: $summaryStatus, total: $($manifestRows.Count), ready: $ready, needs assignment: $needsAssignment"
