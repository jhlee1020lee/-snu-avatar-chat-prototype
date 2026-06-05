param(
    [string]$OutputPath,
    [string]$TrackerPath,
    [string]$EvidenceRoot,
    [string]$BriefRoot
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
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
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

function Get-Files {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -File -Recurse -ErrorAction Stop)
}

function Get-Directories {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -Directory -ErrorAction Stop)
}

function Test-FileNameLike {
    param(
        [object[]]$Files,
        [string]$Pattern,
        [string]$ExcludePattern = "(^README|README|template|reference|sample|blank|양식|예시)"
    )

    return [bool]($Files | Where-Object { $_.Name -match $Pattern -and $_.Name -notmatch $ExcludePattern } | Select-Object -First 1)
}

function Get-ExistingRows {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @{}
    }

    $map = @{}
    foreach ($row in @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $Path) -Encoding UTF8)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$row.id)) {
            $map[[string]$row.id] = $row
        }
    }
    return $map
}

function Get-ManualValue {
    param(
        [object]$Existing,
        [string]$Name,
        [string]$Default = ""
    )

    if ($Existing -and $Existing.PSObject.Properties.Name -contains $Name) {
        $value = [string]$Existing.$Name
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
    return $Default
}

function Get-PlaytestSessionStatus {
    param([string]$SessionId)

    $sessionPath = Join-Path (Join-Path $EvidenceRoot "Playtest") $SessionId
    $files = Get-Files -Path $sessionPath
    $hasObservation = Test-FileNameLike -Files $files -Pattern "PLAYTEST_OBSERVATION_FORM|observation|관찰"
    $hasSupport = [bool](
        ($files | Where-Object { $_.Name -match "support_info\.json|BUILD_INFO\.txt|SupportBundle|support-bundle" } | Select-Object -First 1) -or
        (Get-Directories -Path $sessionPath | Where-Object { $_.Name -match "SupportBundle|support-bundle" } | Select-Object -First 1)
    )
    $hasFeedback = Test-FileNameLike -Files $files -Pattern "feedback|피드백|participant|플레이테스트"

    if ($hasObservation -and $hasSupport -and $hasFeedback) {
        return "complete"
    }
    if ($files.Count -gt 0 -or (Test-Path -LiteralPath (ConvertTo-LongPath -Path $sessionPath))) {
        return "partial"
    }
    return "missing"
}

function Get-AreaEvidenceStatus {
    param([string]$Area)

    $root = Join-Path $EvidenceRoot $Area
    $files = Get-Files -Path $root
    $countableFiles = @($files | Where-Object { $_.Name -notmatch "(^README|README|template|reference|sample|blank|양식|예시)" })
    switch ($Area) {
        "Accessibility" {
            $form = Test-FileNameLike -Files $files -Pattern "ACCESSIBILITY_OBSERVATION_FORM|accessibility|접근성"
            $media = Test-FileNameLike -Files $files -Pattern "\.(png|jpg|jpeg|mp4|mov|webm)$"
            if ($form -and $media) { return "complete" }
            if ($form -or $media -or $countableFiles.Count -gt 0) { return "partial" }
            return "missing"
        }
        "ArtReview" {
            $form = Test-FileNameLike -Files $files -Pattern "ART_REVIEW_FORM|art.*review|아트"
            $media = Test-FileNameLike -Files $files -Pattern "\.(png|jpg|jpeg|pdf)$"
            if ($form -and $media) { return "complete" }
            if ($form -or $media -or $countableFiles.Count -gt 0) { return "partial" }
            return "missing"
        }
        "Trailer" {
            $form = Test-FileNameLike -Files $files -Pattern "TRAILER_FINAL_REVIEW_FORM|trailer.*review|트레일러"
            $video = [bool]($files | Where-Object { $_.Name -match "\.(mp4|mov|webm)$" -and $_.Length -gt 100000 } | Select-Object -First 1)
            $caption = Test-FileNameLike -Files $files -Pattern "\.(srt|vtt)$|caption|subtitle|자막"
            if ($form -and $video -and $caption) { return "complete" }
            if ($form -or $video -or $caption -or $countableFiles.Count -gt 0) { return "partial" }
            return "missing"
        }
        "LegalSteam" {
            $checklist = Test-FileNameLike -Files $files -Pattern "STEAM_ADMIN_CHECKLIST|steam.*admin|steam"
            $privacy = Test-FileNameLike -Files $files -Pattern "PRIVACY.*FINAL|privacy.*final|개인정보.*최종"
            $branch = Test-FileNameLike -Files $files -Pattern "branch|builds|steam.*test|테스트.*브랜치|\.png$|\.pdf$"
            if ($checklist -and $privacy -and $branch) { return "complete" }
            if ($checklist -or $privacy -or $branch -or $countableFiles.Count -gt 0) { return "partial" }
            return "missing"
        }
    }

    return "missing"
}

function Get-QualityEvidenceStatus {
    $scorecardPath = Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD.tsv"
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $scorecardPath))) {
        return "missing"
    }

    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $scorecardPath) -Encoding UTF8)
    if ($rows.Count -eq 0) {
        return "missing"
    }

    $filled = @($rows | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.reviewer) -and
        -not [string]::IsNullOrWhiteSpace([string]$_.evidence) -and
        -not [string]::IsNullOrWhiteSpace([string]$_.score)
    }).Count
    if ($filled -ge $rows.Count) {
        return "complete"
    }
    if ($filled -gt 0) {
        return "partial"
    }
    return "missing"
}

function Get-IssueEvidenceStatus {
    $issuePath = Join-Path $EvidenceRoot "EXTERNAL_ISSUE_REGISTER.tsv"
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $issuePath))) {
        return "missing"
    }

    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $issuePath) -Encoding UTF8)
    if ($rows.Count -eq 0) {
        return "missing"
    }
    $realRows = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.issue_id) -and $_.issue_id -notmatch "TEMPLATE|SAMPLE" })
    if ($realRows.Count -eq 0) {
        return "missing"
    }
    $open = @($realRows | Where-Object { $_.status -notmatch "verified|closed|accepted_risk" }).Count
    if ($open -eq 0) {
        return "complete"
    }
    return "partial"
}

function Add-Row {
    param(
        [string]$Id,
        [string]$Role,
        [string]$Package,
        [string]$BriefFile,
        [string]$EvidencePath,
        [string]$RequiredEvidence,
        [string]$EvidenceStatus,
        [string]$ValidationCommand,
        [string]$ExitCriteria,
        [string]$NextAction
    )

    $existing = $existingRows[$Id]
    $reviewer = Get-ManualValue -Existing $existing -Name "reviewer_alias"
    $contact = Get-ManualValue -Existing $existing -Name "contact_method"
    $inviteStatus = Get-ManualValue -Existing $existing -Name "invite_status" -Default "not_sent"
    $inviteSentAt = Get-ManualValue -Existing $existing -Name "invite_sent_at"
    $dueAt = Get-ManualValue -Existing $existing -Name "due_at"
    $receivedAt = Get-ManualValue -Existing $existing -Name "received_at"
    $notes = Get-ManualValue -Existing $existing -Name "notes"

    if ($EvidenceStatus -eq "complete" -and [string]::IsNullOrWhiteSpace($receivedAt)) {
        $receivedAt = Get-Date -Format "yyyy-MM-dd"
    }

    $assignmentStatus = if ([string]::IsNullOrWhiteSpace($reviewer)) { "needs_owner" } elseif ($inviteStatus -eq "sent" -or $inviteStatus -eq "accepted") { "assigned" } else { "owner_named" }

    $script:rows.Add([pscustomobject]@{
        id = $Id
        role = $Role
        assignment_status = $assignmentStatus
        reviewer_alias = $reviewer
        contact_method = $contact
        invite_status = $inviteStatus
        invite_sent_at = $inviteSentAt
        due_at = $dueAt
        received_at = $receivedAt
        package = $Package
        brief_file = $BriefFile
        evidence_path = $EvidencePath
        required_evidence = $RequiredEvidence
        evidence_status = $EvidenceStatus
        validation_command = $ValidationCommand
        exit_criteria = $ExitCriteria
        next_action = $NextAction
        notes = $notes
    }) | Out-Null
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($BriefRoot)) {
    $BriefRoot = Join-Path $EvidenceRoot "ReviewBriefs"
}
if ([string]::IsNullOrWhiteSpace($TrackerPath)) {
    $TrackerPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_TRACKER.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_TRACKER.md"
}

Ensure-Directory -Path $EvidenceRoot
Ensure-Directory -Path $BriefRoot

$existingRows = Get-ExistingRows -Path $TrackerPath
$rows = New-Object System.Collections.Generic.List[object]

for ($index = 1; $index -le 5; $index++) {
    $sessionId = "session-{0:D2}" -f $index
    Add-Row `
        -Id ("PT-{0:D2}" -f $index) `
        -Role "외부 플레이테스트 $index" `
        -Package "ExternalPlaytestPackage" `
        -BriefFile "ReviewBriefs\PLAYTEST_REVIEW_BRIEF.md" `
        -EvidencePath "EvidenceDrop\Playtest\$sessionId" `
        -RequiredEvidence "관찰 양식, feedback txt/json, support bundle, 문제 화면" `
        -EvidenceStatus (Get-PlaytestSessionStatus -SessionId $sessionId) `
        -ValidationCommand 'Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest" -RequireNoBlockers -RequireComplete' `
        -ExitCriteria "5문답 이상 완성 세션, P0/P1 0" `
        -NextAction "참가자 1명을 배정하고 $sessionId 증거를 수집한다."
}

Add-Row -Id "ACCESS-01" -Role "접근성 검토" -Package "CommercialReviewPackage" -BriefFile "ReviewBriefs\ACCESSIBILITY_REVIEW_BRIEF.md" -EvidencePath "EvidenceDrop\Accessibility" -RequiredEvidence "접근성 관찰 양식, 화면 배율/키보드/고대비 캡처 또는 녹화" -EvidenceStatus (Get-AreaEvidenceStatus -Area "Accessibility") -ValidationCommand 'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete' -ExitCriteria "관찰 양식과 화면/녹화 증거 등록" -NextAction "접근성 검토자를 배정하고 실제 입력 조건 증거를 받는다."
Add-Row -Id "ART-01" -Role "아트 리뷰" -Package "SteamSubmissionPackage, CommercialReviewPackage" -BriefFile "ReviewBriefs\ART_REVIEW_BRIEF.md" -EvidencePath "EvidenceDrop\ArtReview" -RequiredEvidence "아트 리뷰 양식, 표시 이미지 또는 PDF, 승인/보류 결론" -EvidenceStatus (Get-AreaEvidenceStatus -Area "ArtReview") -ValidationCommand 'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete' -ExitCriteria "캡슐/키아트 외부 승인 또는 수정 이슈 등록" -NextAction "아트 리뷰어에게 캡슐과 실제 화면을 함께 전달한다."
Add-Row -Id "TRAILER-01" -Role "트레일러 리뷰" -Package "SteamSubmissionPackage, CommercialReviewPackage" -BriefFile "ReviewBriefs\TRAILER_REVIEW_BRIEF.md" -EvidencePath "EvidenceDrop\Trailer" -RequiredEvidence "최종 영상, 자막, 트레일러 리뷰 양식" -EvidenceStatus (Get-AreaEvidenceStatus -Area "Trailer") -ValidationCommand 'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete' -ExitCriteria "실제 플레이 기반 최종 영상과 자막 승인" -NextAction "실제 조작 녹화 기반 최종 트레일러 검토를 요청한다."
Add-Row -Id "LEGAL-01" -Role "Steam 관리자/법무" -Package "SteamSubmissionPackage, Steamworks staging package" -BriefFile "ReviewBriefs\LEGAL_STEAM_REVIEW_BRIEF.md" -EvidencePath "EvidenceDrop\LegalSteam" -RequiredEvidence "Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 실행 증거" -EvidenceStatus (Get-AreaEvidenceStatus -Area "LegalSteam") -ValidationCommand 'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete' -ExitCriteria "Steam 관리자 설정과 개인정보 문구 최종 확인" -NextAction "상점 운영/법무 담당자에게 비밀정보 없는 증거를 요청한다."
Add-Row -Id "QUALITY-01" -Role "5달러 품질 점수표" -Package "CommercialReviewPackage" -BriefFile "ReviewBriefs\QUALITY_SCORECARD_REVIEW_BRIEF.md" -EvidencePath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" -RequiredEvidence "8개 품질 영역 점수, reviewer, evidence, blocker" -EvidenceStatus (Get-QualityEvidenceStatus) -ValidationCommand 'Tools\ValidateCommercialQualityRubric.ps1 -ScorecardPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" -RequireReady' -ExitCriteria "평균 4.0 이상, 최저 3 이상, 차단 0" -NextAction "프로듀서가 외부 증거를 확인하고 공식 점수표를 채운다."
Add-Row -Id "ISSUE-01" -Role "외부 이슈 폐쇄" -Package "CommercialReviewPackage" -BriefFile "ReviewBriefs\REVIEW_INVITATION_TEMPLATES.md" -EvidencePath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv" -RequiredEvidence "P0/P1 verified, P2 closed 또는 accepted risk" -EvidenceStatus (Get-IssueEvidenceStatus) -ValidationCommand 'Tools\ValidateExternalIssueRegister.ps1 -IssueRegisterPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv" -RequireClosed' -ExitCriteria "외부 이슈 레지스터 상태 완료" -NextAction "외부 리뷰 이슈를 등록하고 해결/검증 상태를 갱신한다."

$header = "id`trole`tassignment_status`treviewer_alias`tcontact_method`tinvite_status`tinvite_sent_at`tdue_at`treceived_at`tpackage`tbrief_file`tevidence_path`trequired_evidence`tevidence_status`tvalidation_command`texit_criteria`tnext_action`tnotes"
$trackerLines = New-Object System.Collections.Generic.List[string]
$trackerLines.Add($header)
foreach ($row in $rows) {
    $trackerLines.Add((
        (Format-TsvCell $row.id),
        (Format-TsvCell $row.role),
        (Format-TsvCell $row.assignment_status),
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
Ensure-Directory -Path (Split-Path -Parent $TrackerPath)
Set-Content -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Value $trackerLines -Encoding UTF8

$complete = @($rows | Where-Object { $_.evidence_status -eq "complete" }).Count
$partial = @($rows | Where-Object { $_.evidence_status -eq "partial" }).Count
$missing = @($rows | Where-Object { $_.evidence_status -eq "missing" }).Count
$assigned = @($rows | Where-Object { $_.assignment_status -ne "needs_owner" }).Count
$sent = @($rows | Where-Object { $_.invite_status -eq "sent" -or $_.invite_status -eq "accepted" }).Count
$trackerStatus = if ($complete -eq $rows.Count) { "완료" } else { "진행 전" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰 진행 추적 보드")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $trackerStatus")
$lines.Add("- 추적 항목: $($rows.Count)")
$lines.Add("- 담당 배정: $assigned/$($rows.Count)")
$lines.Add("- 초대 발송: $sent/$($rows.Count)")
$lines.Add("- 증거 완료: $complete")
$lines.Add("- 증거 일부: $partial")
$lines.Add("- 증거 없음: $missing")
$lines.Add("- 추적 TSV: $TrackerPath")
$lines.Add("")
$lines.Add("이 보드는 외부 검증 업무의 배정과 증거 수령 상태를 추적한다. 실제 리뷰 증거를 대체하지 않으며, reviewer_alias, contact_method, invite_status, due_at, notes는 사람이 채운 뒤 다음 실행에서도 보존된다.")
$lines.Add("")
$lines.Add("## 항목")
$lines.Add("")
$lines.Add("| ID | 역할 | 배정 | 초대 | 증거 | 제출 위치 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- | --- | --- | --- |")
foreach ($row in $rows) {
    $assigneeText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewer_alias)) { $row.assignment_status } else { $row.reviewer_alias }
    $lines.Add("| $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.role) | $(Escape-MarkdownCell $assigneeText) | $(Escape-MarkdownCell $row.invite_status) | $(Escape-MarkdownCell $row.evidence_status) | $(Escape-MarkdownCell $row.evidence_path) | $(Escape-MarkdownCell $row.next_action) |")
}
$lines.Add("")
$lines.Add("## 운영 기준")
$lines.Add("")
$lines.Add("- invite_status는 not_sent, sent, accepted, declined 중 하나로 둔다.")
$lines.Add("- 외부 증거 파일이 들어온 뒤에도 validation_command가 통과하기 전까지 최종 출시 후보로 보지 않는다.")
$lines.Add("- reviewer_alias에는 실제 이름 대신 식별 가능한 약칭을 써도 된다.")
$lines.Add("- contact_method에는 개인 연락처 원문보다 팀 내부에서 찾을 수 있는 채널명만 둔다.")
$lines.Add("")
$lines.Add("## 검증 명령")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewTracker.ps1")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete")
$lines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady")
$lines.Add('```')

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

$secretMatches = @()
foreach ($path in @($OutputPath, $TrackerPath)) {
    $secretMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue)
}
if ($secretMatches.Count -gt 0) {
    throw "External review tracker contains an API key pattern."
}

Write-Host "External review tracker written: $OutputPath"
Write-Host "External review tracker TSV written: $TrackerPath"
Write-Host "Tracker status: $trackerStatus, assigned: $assigned/$($rows.Count), complete: $complete, partial: $partial, missing: $missing"
