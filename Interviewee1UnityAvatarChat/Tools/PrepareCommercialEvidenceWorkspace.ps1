param(
    [string]$EvidenceRoot,
    [string]$BacklogPath,
    [switch]$Force
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

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Write-TextFile {
    param(
        [string]$Path,
        [object]$Lines
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)
    if ((Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path)) -and -not $Force) {
        return
    }

    Set-Content -LiteralPath (ConvertTo-LongPath -Path $Path) -Value $Lines -Encoding UTF8
}

function Copy-Template {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Source))) {
        return
    }
    Ensure-Directory -Path (Split-Path -Parent $Destination)
    if ((Test-Path -LiteralPath (ConvertTo-LongPath -Path $Destination)) -and -not $Force) {
        return
    }

    Copy-Item -LiteralPath (ConvertTo-LongPath -Path $Source) -Destination (ConvertTo-LongPath -Path $Destination) -Force
}

function Format-TsvCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Test-TextLikeFile {
    param([System.IO.FileInfo]$File)

    $textExtensions = @(
        ".bat", ".cmd", ".config", ".csv", ".css", ".htm", ".html", ".ini",
        ".js", ".json", ".log", ".manifest", ".md", ".ps1", ".psm1", ".srt",
        ".tsv", ".txt", ".vdf", ".vtt", ".xml", ".yaml", ".yml"
    )
    $textNames = @("LICENSE", "NOTICE", "README")
    $extension = $File.Extension.ToLowerInvariant()
    if ($textExtensions -contains $extension) {
        return $true
    }

    return $textNames -contains $File.Name.ToUpperInvariant()
}

function Assert-NoApiKeyPattern {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return
    }

    $matches = Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -File -Recurse |
        Where-Object { Test-TextLikeFile -File $_ } |
        Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue

    if ($matches) {
        $sample = ($matches | Select-Object -First 4 | ForEach-Object { $_.Path }) -join ", "
        throw "Commercial evidence workspace contains an API key pattern: $sample"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
$marketingRoot = Join-Path $projectRoot "Marketing"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($BacklogPath)) {
    $BacklogPath = Join-Path $docsRoot "INTERNAL_COMMERCIAL_BACKLOG.tsv"
}

Ensure-Directory -Path $EvidenceRoot

$folders = @("Playtest", "Accessibility", "ArtReview", "Trailer", "LegalSteam", "ReviewBriefs")
foreach ($folder in $folders) {
    Ensure-Directory -Path (Join-Path $EvidenceRoot $folder)
}

Copy-Template -Source (Join-Path $docsRoot "PLAYTEST_OBSERVATION_FORM.md") -Destination (Join-Path $EvidenceRoot "Playtest\PLAYTEST_OBSERVATION_FORM_TEMPLATE.md")
Copy-Template -Source (Join-Path $docsRoot "PLAYTEST_ISSUE_TRIAGE.md") -Destination (Join-Path $EvidenceRoot "Playtest\PLAYTEST_ISSUE_TRIAGE_TEMPLATE.md")
Copy-Template -Source (Join-Path $docsRoot "PLAYTEST_MODERATOR_SCRIPT.md") -Destination (Join-Path $EvidenceRoot "Playtest\PLAYTEST_MODERATOR_SCRIPT_REFERENCE.md")
Copy-Template -Source (Join-Path $docsRoot "PLAYTEST_PARTICIPANT_BRIEF.md") -Destination (Join-Path $EvidenceRoot "Playtest\PLAYTEST_PARTICIPANT_BRIEF_REFERENCE.md")
Copy-Template -Source (Join-Path $docsRoot "ACCESSIBILITY_OBSERVATION_FORM.md") -Destination (Join-Path $EvidenceRoot "Accessibility\ACCESSIBILITY_OBSERVATION_FORM_TEMPLATE.md")
Copy-Template -Source (Join-Path $marketingRoot "ArtReview\ART_REVIEW_FORM.md") -Destination (Join-Path $EvidenceRoot "ArtReview\ART_REVIEW_FORM_TEMPLATE.md")
Copy-Template -Source (Join-Path $marketingRoot "ArtReview\ART_REVIEW_BRIEF.md") -Destination (Join-Path $EvidenceRoot "ArtReview\ART_REVIEW_BRIEF_REFERENCE.md")
Copy-Template -Source (Join-Path $marketingRoot "Trailer\TRAILER_FINAL_REVIEW_FORM.md") -Destination (Join-Path $EvidenceRoot "Trailer\TRAILER_FINAL_REVIEW_FORM_TEMPLATE.md")
Copy-Template -Source (Join-Path $marketingRoot "Trailer\TRAILER_CAPTIONS.srt") -Destination (Join-Path $EvidenceRoot "Trailer\TRAILER_CAPTIONS_TEMPLATE.srt")
Copy-Template -Source (Join-Path $marketingRoot "Trailer\TRAILER_CAPTIONS.vtt") -Destination (Join-Path $EvidenceRoot "Trailer\TRAILER_CAPTIONS_TEMPLATE.vtt")
Copy-Template -Source (Join-Path $marketingRoot "Trailer\TRAILER_BUILD_CAPTURE_SHOTLIST.tsv") -Destination (Join-Path $EvidenceRoot "Trailer\TRAILER_BUILD_CAPTURE_SHOTLIST_REFERENCE.tsv")
Copy-Template -Source (Join-Path $marketingRoot "Steamworks\STEAM_ADMIN_CHECKLIST.md") -Destination (Join-Path $EvidenceRoot "LegalSteam\STEAM_ADMIN_CHECKLIST_TEMPLATE.md")
Copy-Template -Source (Join-Path $docsRoot "PRIVACY_NOTICE_DRAFT.md") -Destination (Join-Path $EvidenceRoot "LegalSteam\PRIVACY_NOTICE_DRAFT_REFERENCE.md")
Copy-Template -Source (Join-Path $docsRoot "PRIVACY_NOTICE_FINAL_TEMPLATE.md") -Destination (Join-Path $EvidenceRoot "LegalSteam\PRIVACY_NOTICE_FINAL_TEMPLATE.md")
Copy-Template -Source (Join-Path $docsRoot "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv") -Destination (Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv")
Copy-Template -Source (Join-Path $docsRoot "EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv") -Destination (Join-Path $EvidenceRoot "EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv")

$readmes = @{
    "Playtest" = @(
        "# Playtest Evidence",
        "",
        "Required before launch review:",
        "- five session folders named session-01 through session-05",
        "- each session has filled observation form, original feedback txt/json, support bundle, SESSION_QA.md, SESSION_FILE_MANIFEST.tsv, and issue media when relevant",
        "- use Tools\NewPlaytestEvidenceBundle.ps1 from the playtest package when possible",
        "- use Tools\CollectExternalEvidenceSession.ps1 only when feedback and support bundle paths must be passed manually",
        "- if a session is copied manually, run Tools\ValidateExternalEvidenceSession.ps1 -SessionRoot <session> -RequireComplete before counting it",
        "",
        "Template files in this folder are not counted as evidence."
    )
    "Accessibility" = @(
        "# Accessibility Evidence",
        "",
        "Required before launch review:",
        "- filled accessibility observation form",
        "- screenshot or recording for screen scaling, keyboard-only, high contrast, or assistive input evidence",
        "",
        "Template files in this folder are not counted as evidence."
    )
    "ArtReview" = @(
        "# Art Review Evidence",
        "",
        "Required before launch review:",
        "- filled art review form",
        "- reviewed key art, small capsule, screenshot, or PDF mark-up evidence",
        "",
        "Template files in this folder are not counted as evidence."
    )
    "Trailer" = @(
        "# Trailer Evidence",
        "",
        "Required before launch review:",
        "- final live-play based video file",
        "- filled trailer final review form",
        "- subtitle or caption file",
        "",
        "Template files in this folder are not counted as evidence."
    )
    "LegalSteam" = @(
        "# Legal And Steam Evidence",
        "",
        "Required before launch review:",
        "- filled Steam admin checklist",
        "- completed privacy template copied to PRIVACY_NOTICE_FINAL.md",
        "- final privacy wording file named like PRIVACY_NOTICE_FINAL.md",
        "- Steam test branch execution evidence such as screenshot or PDF",
        "",
        "Do not store Steam credentials, passwords, Steam Guard codes, or API keys here."
    )
}

foreach ($entry in $readmes.GetEnumerator()) {
    Write-TextFile -Path (Join-Path $EvidenceRoot "$($entry.Key)\README_NEXT_STEPS.md") -Lines $entry.Value
}

$planRows = New-Object System.Collections.Generic.List[string]
$planRows.Add("backlog_id`tpriority`towner`tevidence_folder`texpected_files`tcollection_command`texit_criteria")

if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $BacklogPath)) {
    $backlogRows = @(Import-Csv -Delimiter "`t" -LiteralPath $BacklogPath)
}
else {
    $backlogRows = @()
}

$defaultRows = @(
    [pscustomobject]@{ id = "INT-PLAYTEST-001"; priority = "P1"; owner = "기획/QA"; area = "외부 플레이테스트"; exit_criteria = "완성 세션 5/5, P0 0, P1 0" },
    [pscustomobject]@{ id = "INT-ACCESS-001"; priority = "P1"; owner = "접근성 검토자"; area = "접근성"; exit_criteria = "ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록" },
    [pscustomobject]@{ id = "INT-ART-001"; priority = "P1"; owner = "아트 리뷰어"; area = "아트/상점 첫인상"; exit_criteria = "ART_REVIEW_FORM.md와 이미지/PDF 근거 등록" },
    [pscustomobject]@{ id = "INT-TRAILER-001"; priority = "P1"; owner = "트레일러 편집자"; area = "트레일러"; exit_criteria = "TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록" },
    [pscustomobject]@{ id = "INT-LEGAL-001"; priority = "P1"; owner = "상점 운영/법무"; area = "Steam 관리자/법무"; exit_criteria = "Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록" },
    [pscustomobject]@{ id = "INT-QUALITY-001"; priority = "P1"; owner = "기획/프로듀서"; area = "5달러 품질 루브릭"; exit_criteria = "상태 완료, 평균 4.0 이상, 최저 3 이상, 차단 0" },
    [pscustomobject]@{ id = "INT-ISSUE-001"; priority = "P2"; owner = "QA"; area = "외부 이슈 폐쇄"; exit_criteria = "이슈 레지스터 상태 완료" }
)

if ($backlogRows.Count -eq 0) {
    $backlogRows = $defaultRows
}

foreach ($row in $backlogRows) {
    $id = [string]$row.id
    $folder = ""
    $expected = ""
    $command = ""
    switch -Regex ($id) {
        "PLAYTEST" {
            $folder = "Playtest"
            $expected = "session-01..session-05 with observation form, feedback txt/json, support bundle"
            $command = 'Tools\NewPlaytestEvidenceBundle.ps1 -SessionId "session-01" -EvidenceRoot "EvidenceDrop\Playtest" -ObservationFormPath "<filled form>"'
        }
        "ACCESS" {
            $folder = "Accessibility"
            $expected = "ACCESSIBILITY_OBSERVATION_FORM_FILLED.md plus png/mp4 evidence"
            $command = "Fill ACCESSIBILITY_OBSERVATION_FORM_TEMPLATE.md and add screen or recording evidence"
        }
        "ART" {
            $folder = "ArtReview"
            $expected = "ART_REVIEW_FORM_FILLED.md plus png/jpg/pdf review evidence"
            $command = "Fill ART_REVIEW_FORM_TEMPLATE.md and attach capsule/keyart review evidence"
        }
        "TRAILER" {
            $folder = "Trailer"
            $expected = "TRAILER_FINAL_REVIEW_FORM_FILLED.md, final mp4, captions srt/vtt"
            $command = "Fill TRAILER_FINAL_REVIEW_FORM_TEMPLATE.md and add final video plus captions"
        }
        "LEGAL" {
            $folder = "LegalSteam"
            $expected = "STEAM_ADMIN_CHECKLIST_FILLED.md, PRIVACY_NOTICE_FINAL.md, Steam test branch screenshot/pdf"
            $command = "Fill STEAM_ADMIN_CHECKLIST_TEMPLATE.md, add final privacy text and Steam test branch evidence"
        }
        "QUALITY" {
            $folder = "."
            $expected = "COMMERCIAL_QUALITY_SCORECARD.tsv filled with reviewer and evidence"
            $command = "Fill COMMERCIAL_QUALITY_SCORECARD.tsv, then run Tools\ValidateCommercialQualityRubric.ps1 -RequireReady"
        }
        "ISSUE" {
            $folder = "."
            $expected = "EXTERNAL_ISSUE_REGISTER.tsv with P0/P1 verified and P2 closed or accepted risk"
            $command = 'Tools\RegisterExternalIssue.ps1 -IssueId "EXT-001" -Priority "P2" -Area "<area>" -Source "<source>" -Title "<title>"'
        }
    }

    if ([string]::IsNullOrWhiteSpace($folder)) {
        continue
    }

    $planRows.Add((
        (Format-TsvCell $id),
        (Format-TsvCell ([string]$row.priority)),
        (Format-TsvCell ([string]$row.owner)),
        (Format-TsvCell $folder),
        (Format-TsvCell $expected),
        (Format-TsvCell $command),
        (Format-TsvCell ([string]$row.exit_criteria))
    ) -join "`t")
}

Write-TextFile -Path (Join-Path $EvidenceRoot "EVIDENCE_COLLECTION_PLAN.tsv") -Lines $planRows

$rootReadme = @(
    "# Commercial Evidence Workspace",
    "",
    "This workspace is prepared from the internal commercial backlog.",
    "",
    "Use EVIDENCE_COLLECTION_PLAN.tsv to see the required folder, files, command, and exit criteria for each open backlog item.",
    "Use ReviewBriefs before assigning external reviewers. These files explain each role, output location, stop rule, and validation command.",
    "Use EXTERNAL_REVIEW_TRACKER.tsv to track reviewer assignment, invitation status, due date, and evidence receipt without changing source code.",
    "Use EXTERNAL_REVIEWER_ROSTER.tsv to collect reviewer aliases, contact routes, due dates, and backups before applying them to the tracker.",
    "Use ReviewerPackets after filling the tracker. Each packet contains the invite text, reviewer README, source brief, and acceptance checklist for one review item.",
    "Use ReviewerPacketArchives for per-reviewer ZIP files that can be attached or sent without manually selecting packet files.",
    "Use EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv to see the next reviewer assignment, invite, follow-up, and import action.",
    "Use ReviewerInviteOutbox for copy-ready invite files after reviewer assignments are applied.",
    "Files with TEMPLATE or REFERENCE in the name are not evidence. Rename or copy them after they are filled by an actual reviewer or tester.",
    "Playtest session folders are counted only when ValidateExternalEvidenceSession.ps1 -RequireComplete passes for that session.",
    "",
    "Do not store API keys, Steam credentials, passwords, Steam Guard codes, or private account notes in this workspace.",
    "",
    "Final check:",
    '```powershell',
    ".\Tools\ValidateExternalEvidence.ps1 -EvidenceRoot <EvidenceRoot> -RequireComplete",
    ".\Tools\ValidateCommercialQualityRubric.ps1 -ScorecardPath <EvidenceRoot>\COMMERCIAL_QUALITY_SCORECARD.tsv -RequireReady",
    '```'
)
Write-TextFile -Path (Join-Path $EvidenceRoot "README_EVIDENCE_WORKSPACE.md") -Lines $rootReadme

$reviewBriefScript = Join-Path $PSScriptRoot "WriteExternalReviewBriefs.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $reviewBriefScript)) {
    & $reviewBriefScript -EvidenceRoot $EvidenceRoot -Force 2>&1 | Out-Null
}

$reviewTrackerScript = Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $reviewTrackerScript)) {
    & $reviewTrackerScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$reviewerRosterScript = Join-Path $PSScriptRoot "WriteExternalReviewerRosterTemplate.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $reviewerRosterScript)) {
    & $reviewerRosterScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$reviewerPacketsScript = Join-Path $PSScriptRoot "WriteExternalReviewerPackets.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $reviewerPacketsScript)) {
    & $reviewerPacketsScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$reviewerPacketArchivesScript = Join-Path $PSScriptRoot "WriteExternalReviewerPacketArchives.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $reviewerPacketArchivesScript)) {
    & $reviewerPacketArchivesScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$reviewerPacketArchivesValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewerPacketArchives.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $reviewerPacketArchivesValidationScript)) {
    & $reviewerPacketArchivesValidationScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$outreachQueueScript = Join-Path $PSScriptRoot "WriteExternalReviewOutreachQueue.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $outreachQueueScript)) {
    & $outreachQueueScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$inviteOutboxScript = Join-Path $PSScriptRoot "WriteExternalReviewInviteOutbox.ps1"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $inviteOutboxScript)) {
    & $inviteOutboxScript -EvidenceRoot $EvidenceRoot -OutputPath (Join-Path $EvidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md") 2>&1 | Out-Null
}

Assert-NoApiKeyPattern -Path $EvidenceRoot

Write-Host "Commercial evidence workspace prepared: $EvidenceRoot"
$collectionPlanPath = Join-Path $EvidenceRoot "EVIDENCE_COLLECTION_PLAN.tsv"
Write-Host "Collection plan: $collectionPlanPath"
