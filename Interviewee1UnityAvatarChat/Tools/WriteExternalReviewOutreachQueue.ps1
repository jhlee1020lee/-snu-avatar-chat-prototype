param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$PacketRoot,
    [string]$QueuePath,
    [string]$OutputPath,
    [string]$Today
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

function Get-WaveInfo {
    param([string]$Id)

    if ($Id -match "^PT-" -or $Id -eq "ACCESS-01") {
        return [pscustomobject]@{ Wave = "wave-1"; Priority = "P1"; Gate = "외부 증거"; Offset = 7; Order = 1 }
    }
    if ($Id -in @("ART-01", "TRAILER-01", "LEGAL-01")) {
        return [pscustomobject]@{ Wave = "wave-2"; Priority = "P1"; Gate = "상점 제출 증거"; Offset = 10; Order = 2 }
    }
    return [pscustomobject]@{ Wave = "wave-3"; Priority = "P1"; Gate = "최종 상업 판정"; Offset = 14; Order = 3 }
}

function Parse-DateOrNull {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }
    $parsed = [datetime]::MinValue
    if ([datetime]::TryParse($Text, [ref]$parsed)) {
        return $parsed.Date
    }
    return $null
}

function Get-CurrentAction {
    param(
        [object]$Row,
        [datetime]$BaseDate
    )

    $assignment = Get-Value -Row $Row -Name "assignment_status"
    $reviewer = Get-Value -Row $Row -Name "reviewer_alias"
    $contact = Get-Value -Row $Row -Name "contact_method"
    $invite = Get-Value -Row $Row -Name "invite_status"
    $evidence = Get-Value -Row $Row -Name "evidence_status"
    $due = Parse-DateOrNull -Text (Get-Value -Row $Row -Name "due_at")

    if ($evidence -eq "complete") {
        return [pscustomobject]@{ Action = "수입 및 최종 게이트 재검증"; Rank = 70 }
    }
    if ($assignment -eq "needs_owner" -or [string]::IsNullOrWhiteSpace($reviewer)) {
        return [pscustomobject]@{ Action = "리뷰어 배정"; Rank = 10 }
    }
    if ([string]::IsNullOrWhiteSpace($contact)) {
        return [pscustomobject]@{ Action = "연락 경로 확인"; Rank = 15 }
    }
    if ($invite -eq "declined") {
        return [pscustomobject]@{ Action = "대체 리뷰어 배정"; Rank = 12 }
    }
    if ($invite -eq "not_sent" -or [string]::IsNullOrWhiteSpace($invite)) {
        return [pscustomobject]@{ Action = "초대 발송"; Rank = 20 }
    }
    if ($evidence -eq "partial") {
        return [pscustomobject]@{ Action = "누락 증거 보완 요청"; Rank = 25 }
    }
    if ($due -ne $null -and $due -lt $BaseDate) {
        return [pscustomobject]@{ Action = "기한 초과 독촉"; Rank = 30 }
    }
    if ($due -eq $null) {
        return [pscustomobject]@{ Action = "마감일 입력"; Rank = 35 }
    }
    return [pscustomobject]@{ Action = "증거 수령 대기"; Rank = 50 }
}

function Assert-NoApiKeyPattern {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            continue
        }
        $matches = Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($matches) {
            throw "Outreach queue contains an API key pattern: $path"
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
if ([string]::IsNullOrWhiteSpace($PacketRoot)) {
    $PacketRoot = Join-Path $EvidenceRoot "ReviewerPackets"
}
if ([string]::IsNullOrWhiteSpace($QueuePath)) {
    $QueuePath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_OUTREACH_QUEUE.md"
}

$baseDate = (Get-Date).Date
if (-not [string]::IsNullOrWhiteSpace($Today)) {
    $baseDate = [datetime]::Parse($Today).Date
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    throw "Missing external review tracker: $TrackerPath"
}

$rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
$queueRows = New-Object System.Collections.Generic.List[object]

foreach ($row in $rows) {
    $id = Get-Value -Row $row -Name "id"
    if ([string]::IsNullOrWhiteSpace($id)) {
        continue
    }

    $wave = Get-WaveInfo -Id $id
    $action = Get-CurrentAction -Row $row -BaseDate $baseDate
    $due = Parse-DateOrNull -Text (Get-Value -Row $row -Name "due_at")
    if ($due -eq $null) {
        $due = $baseDate.AddDays($wave.Offset)
    }
    $reminder = $due.AddDays(-2)
    $packetRelative = Join-Path "ReviewerPackets" $id
    $inviteRelative = Join-Path $packetRelative "INVITE.txt"

    $queueRows.Add([pscustomobject]@{
        queue_order = 0
        id = $id
        role = Get-Value -Row $row -Name "role"
        wave = $wave.Wave
        priority = $wave.Priority
        gate = $wave.Gate
        current_action = $action.Action
        action_rank = $action.Rank
        reviewer_alias = Get-Value -Row $row -Name "reviewer_alias"
        contact_method = Get-Value -Row $row -Name "contact_method"
        invite_status = Get-Value -Row $row -Name "invite_status"
        invite_sent_at = Get-Value -Row $row -Name "invite_sent_at"
        due_at = Get-Value -Row $row -Name "due_at"
        suggested_due_at = $due.ToString("yyyy-MM-dd")
        reminder_at = $reminder.ToString("yyyy-MM-dd")
        received_at = Get-Value -Row $row -Name "received_at"
        package = Get-Value -Row $row -Name "package"
        packet_path = $packetRelative
        invite_path = $inviteRelative
        evidence_path = Get-Value -Row $row -Name "evidence_path"
        evidence_status = Get-Value -Row $row -Name "evidence_status"
        validation_command = Get-Value -Row $row -Name "validation_command"
        exit_criteria = Get-Value -Row $row -Name "exit_criteria"
        next_action = Get-Value -Row $row -Name "next_action"
        notes = Get-Value -Row $row -Name "notes"
        wave_order = $wave.Order
    }) | Out-Null
}

$orderedRows = @($queueRows | Sort-Object action_rank, wave_order, id)
$index = 1
foreach ($row in $orderedRows) {
    $row.queue_order = $index
    $index += 1
}

Ensure-Directory -Path (Split-Path -Parent $QueuePath)
$header = "queue_order`tid`trole`twave`tpriority`tgate`tcurrent_action`taction_rank`treviewer_alias`tcontact_method`tinvite_status`tinvite_sent_at`tdue_at`tsuggested_due_at`treminder_at`treceived_at`tpackage`tpacket_path`tinvite_path`tevidence_path`tevidence_status`tvalidation_command`texit_criteria`tnext_action`tnotes"
$tsvLines = New-Object System.Collections.Generic.List[string]
$tsvLines.Add($header)
foreach ($row in $orderedRows) {
    $tsvLines.Add(@(
        (Format-TsvCell $row.queue_order),
        (Format-TsvCell $row.id),
        (Format-TsvCell $row.role),
        (Format-TsvCell $row.wave),
        (Format-TsvCell $row.priority),
        (Format-TsvCell $row.gate),
        (Format-TsvCell $row.current_action),
        (Format-TsvCell $row.action_rank),
        (Format-TsvCell $row.reviewer_alias),
        (Format-TsvCell $row.contact_method),
        (Format-TsvCell $row.invite_status),
        (Format-TsvCell $row.invite_sent_at),
        (Format-TsvCell $row.due_at),
        (Format-TsvCell $row.suggested_due_at),
        (Format-TsvCell $row.reminder_at),
        (Format-TsvCell $row.received_at),
        (Format-TsvCell $row.package),
        (Format-TsvCell $row.packet_path),
        (Format-TsvCell $row.invite_path),
        (Format-TsvCell $row.evidence_path),
        (Format-TsvCell $row.evidence_status),
        (Format-TsvCell $row.validation_command),
        (Format-TsvCell $row.exit_criteria),
        (Format-TsvCell $row.next_action),
        (Format-TsvCell $row.notes)
    ) -join "`t")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $QueuePath) -Value $tsvLines -Encoding UTF8

$needsOwner = @($orderedRows | Where-Object { $_.current_action -eq "리뷰어 배정" }).Count
$sendNeeded = @($orderedRows | Where-Object { $_.current_action -eq "초대 발송" }).Count
$followUp = @($orderedRows | Where-Object { $_.current_action -match "독촉|보완" }).Count
$waiting = @($orderedRows | Where-Object { $_.current_action -eq "증거 수령 대기" }).Count
$readyImport = @($orderedRows | Where-Object { $_.current_action -match "수입" }).Count
$complete = @($orderedRows | Where-Object { $_.evidence_status -eq "complete" }).Count
$status = "진행 전"
if ($complete -ge $orderedRows.Count -and $orderedRows.Count -gt 0) {
    $status = "완료"
}
elseif ($sendNeeded -gt 0 -or $waiting -gt 0 -or $followUp -gt 0 -or $readyImport -gt 0) {
    $status = "진행 중"
}
elseif ($needsOwner -gt 0) {
    $status = "배정 필요"
}

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰 발송 큐")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준일: $($baseDate.ToString('yyyy-MM-dd'))")
$lines.Add("- 상태: $status")
$lines.Add("- 전체 항목: $($orderedRows.Count)")
$lines.Add("- 리뷰어 배정 필요: $needsOwner")
$lines.Add("- 초대 발송 필요: $sendNeeded")
$lines.Add("- 독촉 또는 보완 요청: $followUp")
$lines.Add("- 증거 수령 대기: $waiting")
$lines.Add("- 수입 대기: $readyImport")
$lines.Add("- 완료 증거: $complete")
$lines.Add("- 큐 TSV: $QueuePath")
$lines.Add("")
$lines.Add("이 큐는 EXTERNAL_REVIEW_TRACKER.tsv와 ReviewerPackets를 바탕으로 오늘 해야 할 외부 검증 운영 순서를 정리한다. 실제 리뷰 증거를 대체하지 않는다.")
$lines.Add("")
$lines.Add("## 오늘 할 일")
$lines.Add("")
$lines.Add("| 순서 | ID | 역할 | 액션 | 권장 마감 | 패킷 | 증거 위치 |")
$lines.Add("| --- | --- | --- | --- | --- | --- | --- |")
foreach ($row in @($orderedRows | Where-Object { $_.current_action -ne "완료" } | Select-Object -First 12)) {
    $lines.Add("| $(Escape-MarkdownCell $row.queue_order) | $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.role) | $(Escape-MarkdownCell $row.current_action) | $(Escape-MarkdownCell $row.suggested_due_at) | $(Escape-MarkdownCell $row.packet_path) | $(Escape-MarkdownCell $row.evidence_path) |")
}
$lines.Add("")
$lines.Add("## 웨이브")
$lines.Add("")
$lines.Add("| 웨이브 | 목적 | 항목 | 권장 처리 |")
$lines.Add("| --- | --- | --- | --- |")
$lines.Add("| wave-1 | 외부 증거 병목 해소 | PT-01..PT-05, ACCESS-01 | 먼저 배정하고 7일 안에 회수한다. |")
$lines.Add("| wave-2 | 상점 제출 증거 보강 | ART-01, TRAILER-01, LEGAL-01 | Steam 제출 전 검토 증거를 10일 안에 회수한다. |")
$lines.Add("| wave-3 | 최종 상업 판정 | QUALITY-01, ISSUE-01 | 외부 증거를 읽고 품질 점수표와 이슈 폐쇄 상태를 확정한다. |")
$lines.Add("")
$lines.Add("## 검증 명령")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add(".\Tools\ValidateExternalReviewOutreachQueue.ps1")
$lines.Add(".\Tools\ValidateExternalReviewerPackets.ps1 -RequireAssigned")
$lines.Add(".\Tools\RunCommercialLaunchGate.ps1")
$lines.Add('```')
$lines.Add("")
$lines.Add("## 운영 규칙")
$lines.Add("")
$lines.Add("- reviewer_alias, contact_method, invite_status, due_at은 EXTERNAL_REVIEW_TRACKER.tsv에서 사람이 채운다.")
$lines.Add("- 여러 명을 한 번에 배정할 때는 EXTERNAL_REVIEWER_ROSTER.tsv를 채우고 ApplyExternalReviewerRoster.ps1를 실행한다.")
$lines.Add("- 초대 발송 전에는 ReviewerPackets의 해당 ID 폴더에서 README.md와 INVITE.txt를 확인한다.")
$lines.Add("- 돌아온 EvidenceDrop은 ImportExternalEvidenceDrop.ps1 -Preview로 먼저 확인한다.")
$lines.Add("- API 키, Steam 비밀번호, Steam Guard 코드, 결제 정보는 어떤 증거에도 넣지 않는다.")
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Assert-NoApiKeyPattern -Paths @($QueuePath, $OutputPath)

Write-Host "External review outreach queue written: $QueuePath"
Write-Host "External review outreach summary written: $OutputPath"
Write-Host "Queue status: $status, total: $($orderedRows.Count), assign: $needsOwner, send: $sendNeeded, follow-up: $followUp"
