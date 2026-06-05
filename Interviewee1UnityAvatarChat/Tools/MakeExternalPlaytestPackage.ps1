param(
    [string]$ReleasePackageRoot,
    [string]$OutputRoot,
    [string]$PackageName = ""
)

$ErrorActionPreference = "Stop"

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

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        throw "Missing required path: $Path"
    }
}

function Reset-PackageDirectory {
    param(
        [string]$PackageRoot,
        [string]$OutputRoot
    )

    $outputFull = ([System.IO.Path]::GetFullPath($OutputRoot)) -replace '[\\/]+$', ''
    $packageFull = [System.IO.Path]::GetFullPath($PackageRoot)
    $expectedPrefix = $outputFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $packageFull.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset package directory outside output root: $packageFull"
    }

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $PackageRoot))) {
        return
    }

    Remove-Item -LiteralPath (ConvertTo-LongPath -Path $PackageRoot) -Recurse -Force -ErrorAction Stop
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination
    )

    Assert-Path -Path $Source
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    $copyOutput = & robocopy $Source $Destination /E /NFL /NDL /NJH /NJS /NP 2>&1
    $copyCode = $LASTEXITCODE
    if ($copyCode -gt 7) {
        throw "robocopy failed for $Source -> $Destination with code ${copyCode}: $(($copyOutput | Select-Object -First 5) -join ' ')"
    }
}

function Copy-RequiredFile {
    param(
        [string]$Source,
        [string]$Destination
    )

    Assert-Path -Path $Source
    New-Item -ItemType Directory -Force -Path (ConvertTo-LongPath -Path (Split-Path -Parent $Destination)) | Out-Null
    Copy-Item -LiteralPath (ConvertTo-LongPath -Path $Source) -Destination (ConvertTo-LongPath -Path $Destination) -Force
}

function Get-PackageFiles {
    param([string]$Path)

    @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -File -Recurse -ErrorAction Stop)
}

function Get-FileSha256 {
    param([string]$Path)

    (Get-FileHash -LiteralPath (ConvertTo-LongPath -Path $Path) -Algorithm SHA256 -ErrorAction Stop).Hash
}

function Write-PackageManifest {
    param(
        [string]$ManifestPath,
        [string]$PackageRoot
    )

    $manifestRoot = ConvertTo-LongPath -Path $PackageRoot
    $manifestRows = Get-PackageFiles -Path $PackageRoot |
        Sort-Object FullName |
        ForEach-Object {
            $relative = $_.FullName.Substring($manifestRoot.Length + 1)
            $hash = Get-FileSha256 -Path $_.FullName
            "{0}`t{1}`t{2}" -f $relative, $_.Length, $hash
        }

    Set-Content -LiteralPath $ManifestPath -Value @("path`tbytes`tsha256") -Encoding UTF8
    Add-Content -LiteralPath $ManifestPath -Value $manifestRows -Encoding UTF8
}

function Convert-PackageScriptsToUtf8Bom {
    param([string]$Path)

    $encoding = New-Object System.Text.UTF8Encoding -ArgumentList $true
    foreach ($script in Get-ChildItem -LiteralPath $Path -File -Filter "*.ps1" -ErrorAction Stop) {
        $content = Get-Content -LiteralPath $script.FullName -Raw -ErrorAction Stop
        [System.IO.File]::WriteAllText($script.FullName, $content, $encoding)
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($ReleasePackageRoot)) {
    $ReleasePackageRoot = Join-Path $buildRoot "ReleasePackages\GeotNotEqualSok-Windows-QA"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "ExternalPlaytestPackages"
}
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $PackageName = "GeotNotEqualSok-ExternalPlaytest-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$releaseRoot = (Resolve-Path $ReleasePackageRoot).Path
$packageRoot = Join-Path $OutputRoot $PackageName
$gameRoot = Join-Path $packageRoot "Game"
$observerDocsRoot = Join-Path $packageRoot "ObserverDocs"
$formsRoot = Join-Path $packageRoot "Forms"
$evidenceRoot = Join-Path $packageRoot "EvidenceDrop"
$toolsRoot = Join-Path $packageRoot "Tools"

$steamLegalValidationScript = Join-Path $PSScriptRoot "ValidateSteamLegalReadiness.ps1"
& $steamLegalValidationScript 2>&1 | Out-Null
$commercialUiCopyValidationScript = Join-Path $PSScriptRoot "ValidateCommercialUiCopy.ps1"
& $commercialUiCopyValidationScript 2>&1 | Out-Null
$commercialDecisionScript = Join-Path $PSScriptRoot "WriteCommercialLaunchDecision.ps1"
& $commercialDecisionScript 2>&1 | Out-Null
$externalReviewBriefsScript = Join-Path $PSScriptRoot "WriteExternalReviewBriefs.ps1"
& $externalReviewBriefsScript 2>&1 | Out-Null
$externalReviewBriefsValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewBriefs.ps1"
& $externalReviewBriefsValidationScript 2>&1 | Out-Null
$externalReviewTrackerScript = Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1"
& $externalReviewTrackerScript 2>&1 | Out-Null
$externalReviewTrackerValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewTracker.ps1"
& $externalReviewTrackerValidationScript 2>&1 | Out-Null
$externalReviewerRosterScript = Join-Path $PSScriptRoot "WriteExternalReviewerRosterTemplate.ps1"
& $externalReviewerRosterScript 2>&1 | Out-Null
$externalReviewerRosterValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewerRoster.ps1"
& $externalReviewerRosterValidationScript 2>&1 | Out-Null
$externalReviewerPacketsScript = Join-Path $PSScriptRoot "WriteExternalReviewerPackets.ps1"
& $externalReviewerPacketsScript 2>&1 | Out-Null
$externalReviewerPacketsValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewerPackets.ps1"
& $externalReviewerPacketsValidationScript 2>&1 | Out-Null
$externalReviewerPacketArchivesScript = Join-Path $PSScriptRoot "WriteExternalReviewerPacketArchives.ps1"
& $externalReviewerPacketArchivesScript 2>&1 | Out-Null
$externalReviewerPacketArchivesValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewerPacketArchives.ps1"
& $externalReviewerPacketArchivesValidationScript 2>&1 | Out-Null
$qualityEvidenceIndexScript = Join-Path $PSScriptRoot "WriteCommercialQualityEvidenceIndex.ps1"
& $qualityEvidenceIndexScript 2>&1 | Out-Null
$qualityEvidenceIndexValidationScript = Join-Path $PSScriptRoot "ValidateCommercialQualityEvidenceIndex.ps1"
& $qualityEvidenceIndexValidationScript -RequireComplete 2>&1 | Out-Null
$externalReviewOutreachScript = Join-Path $PSScriptRoot "WriteExternalReviewOutreachQueue.ps1"
& $externalReviewOutreachScript 2>&1 | Out-Null
$externalReviewOutreachValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewOutreachQueue.ps1"
& $externalReviewOutreachValidationScript 2>&1 | Out-Null
$externalReviewInviteOutboxScript = Join-Path $PSScriptRoot "WriteExternalReviewInviteOutbox.ps1"
& $externalReviewInviteOutboxScript 2>&1 | Out-Null
$externalReviewInviteOutboxValidationScript = Join-Path $PSScriptRoot "ValidateExternalReviewInviteOutbox.ps1"
& $externalReviewInviteOutboxValidationScript 2>&1 | Out-Null
$externalEvidenceImportScript = Join-Path $PSScriptRoot "ImportExternalEvidenceDrop.ps1"
& $externalEvidenceImportScript -SourceEvidenceDrop (Join-Path $buildRoot "ReleaseEvidence") -DestinationEvidenceRoot (Join-Path $buildRoot "ReleaseEvidence") -Preview 2>&1 | Out-Null
$externalEvidenceImportValidationScript = Join-Path $PSScriptRoot "ValidateExternalEvidenceImport.ps1"
& $externalEvidenceImportValidationScript 2>&1 | Out-Null

Reset-PackageDirectory -PackageRoot $packageRoot -OutputRoot $OutputRoot
New-Item -ItemType Directory -Force -Path $gameRoot, $observerDocsRoot, $formsRoot, $evidenceRoot, $toolsRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $evidenceRoot "Playtest") | Out-Null

Copy-DirectoryContents -Source $releaseRoot -Destination $gameRoot

$observerDocs = @(
    "PLAYTEST_PROTOCOL.md",
    "PLAYTEST_MODERATOR_SCRIPT.md",
    "PLAYTEST_PARTICIPANT_BRIEF.md",
    "ACCESSIBILITY_QA.md",
    "ACCESSIBILITY_AUTOMATION_QA.md",
    "ACCESSIBILITY_OBSERVATION_FORM.md",
    "PRIVACY_NOTICE_DRAFT.md",
    "PRIVACY_NOTICE_FINAL_TEMPLATE.md",
    "STEAM_LEGAL_READINESS_QA.md",
    "TROUBLESHOOTING.md",
    "SUPPORT_HANDOFF.md",
    "RELEASE_READINESS_REPORT.md",
    "COMMERCIAL_LAUNCH_DECISION.md",
    "COMMERCIAL_LAUNCH_GATE.md",
    "EXTERNAL_EVIDENCE_REQUIREMENTS.md",
    "EXTERNAL_EVIDENCE_AUDIT.md",
    "PLAYTEST_EVIDENCE_SUMMARY.md",
    "EXTERNAL_ISSUE_REGISTER_QA.md",
    "EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv",
    "COMMERCIAL_UI_COPY_QA.md",
    "MODEL_CONFIG_QA.md",
    "UNITY_LOCAL_FALLBACK_CONTENT_QA.md",
    "GENERATED_MEMORY_POLICY_QA.md",
    "UNITY_BUILD_SYNC_QA.md",
    "COMMERCIAL_QUALITY_RUBRIC.md",
    "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv",
    "COMMERCIAL_QUALITY_REVIEW_QA.md",
    "EXTERNAL_REVIEW_BRIEFS.md",
    "EXTERNAL_REVIEW_BRIEFS_QA.md",
    "EXTERNAL_REVIEW_TRACKER.md",
    "EXTERNAL_REVIEW_TRACKER_QA.md",
    "EXTERNAL_REVIEWER_ROSTER.md",
    "EXTERNAL_REVIEWER_ROSTER_QA.md",
    "EXTERNAL_REVIEWER_PACKETS.md",
    "EXTERNAL_REVIEWER_PACKETS_QA.md",
    "EXTERNAL_REVIEWER_PACKET_ARCHIVES.md",
    "EXTERNAL_REVIEWER_PACKET_ARCHIVES_QA.md",
    "EXTERNAL_REVIEW_OUTREACH_QUEUE.md",
    "EXTERNAL_REVIEW_OUTREACH_QA.md",
    "EXTERNAL_REVIEW_INVITE_OUTBOX.md",
    "EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md",
    "EXTERNAL_EVIDENCE_IMPORT_QA.md"
)
foreach ($name in $observerDocs) {
    Copy-RequiredFile -Source (Join-Path $docsRoot $name) -Destination (Join-Path $observerDocsRoot $name)
}

$marketingRoot = Join-Path $packageRoot "Marketing"
foreach ($name in @("Screenshots", "SteamAssets", "StoreCopy", "Trailer", "VisualQuality")) {
    Copy-DirectoryContents -Source (Join-Path $projectRoot "Marketing\$name") -Destination (Join-Path $marketingRoot $name)
}

Copy-RequiredFile -Source (Join-Path $docsRoot "PLAYTEST_OBSERVATION_FORM.md") -Destination (Join-Path $formsRoot "PLAYTEST_OBSERVATION_FORM.md")
Copy-RequiredFile -Source (Join-Path $docsRoot "PLAYTEST_ISSUE_TRIAGE.md") -Destination (Join-Path $formsRoot "PLAYTEST_ISSUE_TRIAGE.md")
Copy-RequiredFile -Source (Join-Path $docsRoot "ACCESSIBILITY_OBSERVATION_FORM.md") -Destination (Join-Path $formsRoot "ACCESSIBILITY_OBSERVATION_FORM.md")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\NewPlaytestEvidenceBundle.ps1") -Destination (Join-Path $toolsRoot "NewPlaytestEvidenceBundle.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\CollectExternalEvidenceSession.ps1") -Destination (Join-Path $toolsRoot "CollectExternalEvidenceSession.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalEvidenceSession.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalEvidenceSession.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\RegisterExternalIssue.ps1") -Destination (Join-Path $toolsRoot "RegisterExternalIssue.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalEvidence.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalEvidence.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidatePlaytestFeedbackExport.ps1") -Destination (Join-Path $toolsRoot "ValidatePlaytestFeedbackExport.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ExportFeedbackToCommercialQualityScorecard.ps1") -Destination (Join-Path $toolsRoot "ExportFeedbackToCommercialQualityScorecard.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ImportPlaytestFeedbackIssues.ps1") -Destination (Join-Path $toolsRoot "ImportPlaytestFeedbackIssues.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\PrepareCommercialEvidenceWorkspace.ps1") -Destination (Join-Path $toolsRoot "PrepareCommercialEvidenceWorkspace.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewBriefs.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewBriefs.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewBriefs.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewBriefs.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewTracker.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewTracker.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewTracker.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewTracker.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewerRosterTemplate.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewerRosterTemplate.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewerRoster.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewerRoster.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ApplyExternalReviewerRoster.ps1") -Destination (Join-Path $toolsRoot "ApplyExternalReviewerRoster.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewerPackets.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewerPackets.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewerPackets.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewerPackets.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewerPacketArchives.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewerPacketArchives.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewerPacketArchives.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewerPacketArchives.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewOutreachQueue.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewOutreachQueue.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewOutreachQueue.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewOutreachQueue.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewInviteOutbox.ps1") -Destination (Join-Path $toolsRoot "WriteExternalReviewInviteOutbox.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewInviteOutbox.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalReviewInviteOutbox.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ImportExternalEvidenceDrop.ps1") -Destination (Join-Path $toolsRoot "ImportExternalEvidenceDrop.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalEvidenceImport.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalEvidenceImport.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\SummarizePlaytestEvidence.ps1") -Destination (Join-Path $toolsRoot "SummarizePlaytestEvidence.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalIssueRegister.ps1") -Destination (Join-Path $toolsRoot "ValidateExternalIssueRegister.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateCommercialQualityRubric.ps1") -Destination (Join-Path $toolsRoot "ValidateCommercialQualityRubric.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteCommercialQualityEvidenceIndex.ps1") -Destination (Join-Path $toolsRoot "WriteCommercialQualityEvidenceIndex.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateCommercialQualityEvidenceIndex.ps1") -Destination (Join-Path $toolsRoot "ValidateCommercialQualityEvidenceIndex.ps1")
Convert-PackageScriptsToUtf8Bom -Path $toolsRoot
Copy-RequiredFile -Source (Join-Path $docsRoot "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv") -Destination (Join-Path $evidenceRoot "COMMERCIAL_QUALITY_SCORECARD.tsv")
Copy-RequiredFile -Source (Join-Path $buildRoot "ReleaseEvidence\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv") -Destination (Join-Path $evidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv")
Copy-RequiredFile -Source (Join-Path $docsRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.md") -Destination (Join-Path $evidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.md")
& (Join-Path $projectRoot "Tools\PrepareCommercialEvidenceWorkspace.ps1") -EvidenceRoot $evidenceRoot -BacklogPath (Join-Path $docsRoot "INTERNAL_COMMERCIAL_BACKLOG.tsv") -Force 2>&1 | Out-Null
& (Join-Path $projectRoot "Tools\WriteExternalReviewInviteOutbox.ps1") -EvidenceRoot $evidenceRoot -OutputPath (Join-Path $evidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md") 2>&1 | Out-Null
& (Join-Path $projectRoot "Tools\ValidateExternalReviewInviteOutbox.ps1") -EvidenceRoot $evidenceRoot -DocsPath (Join-Path $evidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md") -OutputPath (Join-Path $evidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md") 2>&1 | Out-Null

$readme = @"
겉!=속 external playtest package

Run:
1. Open Game\Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat
2. Let the participant play at least five question-answer turns.
3. Ask the participant to save an ending record and leave in-game feedback.
4. Use Tools\NewPlaytestEvidenceBundle.ps1 to find the latest saved feedback, create the support bundle, and put the session into EvidenceDrop\Playtest.
5. Use Tools\ValidatePlaytestFeedbackExport.ps1 to check the feedback txt/json pair when you need to diagnose a failed session.
6. Use Tools\CollectExternalEvidenceSession.ps1 only when you want to pass every feedback/support path manually. It also writes SESSION_QA.md and SESSION_FILE_MANIFEST.tsv for the session.
7. If a session was copied manually, run Tools\ValidateExternalEvidenceSession.ps1 -SessionRoot "EvidenceDrop\Playtest\<session>" -RequireComplete before counting it.
8. Run RUN_EVIDENCE_AUDIT.bat after each session to refresh EvidenceDrop reports and the feedback-based scorecard draft.
9. Use Tools\ImportPlaytestFeedbackIssues.ps1 for feedback marked P0/P1/P2, then Tools\RegisterExternalIssue.ps1 for any extra bug or review finding. Run RUN_EVIDENCE_AUDIT.bat again.
10. Use EvidenceDrop\EVIDENCE_COLLECTION_PLAN.tsv to see the remaining files for each internal backlog item.
11. Use EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv to find existing automated QA, smoke captures, and store assets for each quality area.
12. Compare EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv with the original evidence, then fill EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv after the review meeting.
13. Run RUN_FINAL_EVIDENCE_GATE.bat only after all five sessions, quality scorecard, and issue closure are done.
14. Back in the source project, run Tools\RunCommercialLaunchGate.ps1 after evidence is merged.

Example collection command:
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\NewPlaytestEvidenceBundle.ps1 -SessionId "session-01" -EvidenceRoot "EvidenceDrop\Playtest" -ObservationFormPath "Forms\PLAYTEST_OBSERVATION_FORM_FILLED.md"

Manual collection command:
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\CollectExternalEvidenceSession.ps1 -SessionId "session-01" -EvidenceRoot "EvidenceDrop\Playtest" -FeedbackPath "<feedback txt>" -FeedbackManifestPath "<feedback json>" -ObservationFormPath "<filled observation form>" -SupportBundleRoot "<support bundle folder or zip>"

Observer docs are in ObserverDocs.
Blank observation and triage forms are in Forms.
Evidence tools are in Tools.
Use ObserverDocs\PLAYTEST_PARTICIPANT_BRIEF.md before the session and ObserverDocs\PLAYTEST_MODERATOR_SCRIPT.md during the session.
Use EvidenceDrop\ReviewBriefs before assigning playtest, accessibility, quality, art, trailer, or Steam/legal reviewers.
Use EvidenceDrop\EXTERNAL_REVIEW_TRACKER.tsv to track assigned reviewers, invite status, due date, and received evidence.
Use EvidenceDrop\EXTERNAL_REVIEWER_ROSTER.tsv with Tools\ApplyExternalReviewerRoster.ps1 to apply reviewer assignments safely.
Use EvidenceDrop\ReviewerPackets to send each reviewer the matching invite text, source brief, and acceptance checklist.
Use EvidenceDrop\ReviewerPacketArchives when you need one ZIP per reviewer instead of selecting files manually.
Use EvidenceDrop\EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv to decide the next reviewer assignment, invite, follow-up, and import action.
Use EvidenceDrop\ReviewerInviteOutbox for copy-ready invite files after reviewer assignments are applied.
After this package is returned, run Tools\ImportExternalEvidenceDrop.ps1 from the source project against this EvidenceDrop before the final gate.
Use ObserverDocs\COMMERCIAL_QUALITY_RUBRIC.md before the review meeting.
Use EvidenceDrop\EVIDENCE_COLLECTION_PLAN.tsv as the session-to-launch evidence checklist.
Use EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv as the quality-area evidence map.

Do not add private account credentials, Steam credentials, or API key values to this package.
"@
Set-Content -LiteralPath (Join-Path $packageRoot "README_EXTERNAL_PLAYTEST.txt") -Value $readme -Encoding UTF8

$evidenceReadme = @"
Drop collected evidence here after each external playtest session.

Expected evidence:
- filled observation form
- support bundle folder or zip
- screenshots or recordings for bugs
- participant feedback txt/json exported from the app

Use EVIDENCE_COLLECTION_PLAN.tsv to see the files each backlog item still needs.
Use RUN_EVIDENCE_AUDIT.bat to refresh EXTERNAL_EVIDENCE_AUDIT.md, PLAYTEST_EVIDENCE_SUMMARY.md, EXTERNAL_ISSUE_REGISTER_QA.md, COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv, and COMMERCIAL_QUALITY_REVIEW_QA.md in this folder.
The draft scorecard is only a reviewer aid. It does not replace COMMERCIAL_QUALITY_SCORECARD.tsv.
COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv is also only a reviewer aid. It does not replace COMMERCIAL_QUALITY_SCORECARD.tsv.
Use RUN_FINAL_EVIDENCE_GATE.bat only when evidence and the commercial quality scorecard are complete enough for final launch review.

Do not place API key values or private account credentials here.
"@
Set-Content -LiteralPath (Join-Path $evidenceRoot "README_EVIDENCE_DROP.txt") -Value $evidenceReadme -Encoding UTF8

$auditBat = @"
@echo off
setlocal
cd /d "%~dp0"
set "POWERSHELL_EXE=pwsh"
where pwsh >nul 2>nul
if errorlevel 1 set "POWERSHELL_EXE=powershell"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateExternalEvidence.ps1" -EvidenceRoot "EvidenceDrop" -OutputPath "EvidenceDrop\EXTERNAL_EVIDENCE_AUDIT.md"
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\SummarizePlaytestEvidence.ps1" -EvidenceRoot "EvidenceDrop\Playtest" -OutputPath "EvidenceDrop\PLAYTEST_EVIDENCE_SUMMARY.md"
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateExternalIssueRegister.ps1" -IssueRegisterPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv" -OutputPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER_QA.md" -Initialize
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ImportPlaytestFeedbackIssues.ps1" -FeedbackRoot "EvidenceDrop\Playtest" -IssueRegisterPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv" -OutputPath "EvidenceDrop\PLAYTEST_FEEDBACK_ISSUE_IMPORT.md" -UpdateExisting
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ExportFeedbackToCommercialQualityScorecard.ps1" -FeedbackRoot "EvidenceDrop\Playtest" -OutputPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv" -SummaryPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD_DRAFT.md"
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateCommercialQualityEvidenceIndex.ps1" -IndexPath "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv" -OutputPath "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX_QA.md" -RequireComplete
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateCommercialQualityRubric.ps1" -ScorecardPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" -OutputPath "EvidenceDrop\COMMERCIAL_QUALITY_REVIEW_QA.md" -Initialize
if errorlevel 1 exit /b %errorlevel%
echo Evidence audit reports written to EvidenceDrop.
exit /b 0
"@
Set-Content -LiteralPath (Join-Path $packageRoot "RUN_EVIDENCE_AUDIT.bat") -Value $auditBat -Encoding ASCII

$finalGateBat = @"
@echo off
setlocal
cd /d "%~dp0"
set "POWERSHELL_EXE=pwsh"
where pwsh >nul 2>nul
if errorlevel 1 set "POWERSHELL_EXE=powershell"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateExternalEvidence.ps1" -EvidenceRoot "EvidenceDrop" -OutputPath "EvidenceDrop\EXTERNAL_EVIDENCE_AUDIT.md" -RequireComplete
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\SummarizePlaytestEvidence.ps1" -EvidenceRoot "EvidenceDrop\Playtest" -OutputPath "EvidenceDrop\PLAYTEST_EVIDENCE_SUMMARY.md" -RequireNoBlockers -RequireComplete
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateExternalIssueRegister.ps1" -IssueRegisterPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv" -OutputPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER_QA.md" -RequireClosed
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateCommercialQualityEvidenceIndex.ps1" -IndexPath "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv" -OutputPath "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX_QA.md" -RequireComplete
if errorlevel 1 exit /b %errorlevel%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "Tools\ValidateCommercialQualityRubric.ps1" -ScorecardPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" -OutputPath "EvidenceDrop\COMMERCIAL_QUALITY_REVIEW_QA.md" -RequireReady
if errorlevel 1 exit /b %errorlevel%
echo Final external evidence gate passed.
exit /b 0
"@
Set-Content -LiteralPath (Join-Path $packageRoot "RUN_FINAL_EVIDENCE_GATE.bat") -Value $finalGateBat -Encoding ASCII

$manifestPath = Join-Path $packageRoot "PLAYTEST_PACKAGE_MANIFEST.tsv"
Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot

$releaseReadinessScript = Join-Path $PSScriptRoot "WriteReleaseReadinessReport.ps1"
if (Test-Path -LiteralPath $releaseReadinessScript) {
    try {
        & $releaseReadinessScript -ExternalPlaytestPackageRoot $packageRoot 2>&1 | Out-Null
    }
    catch {
        Write-Warning "Release readiness snapshot has pending failures: $($_.Exception.Message)"
    }
    Copy-RequiredFile -Source (Join-Path $docsRoot "RELEASE_READINESS_REPORT.md") -Destination (Join-Path $observerDocsRoot "RELEASE_READINESS_REPORT.md")
    $gameDocsRoot = Join-Path $gameRoot "Interviewee1UnityAvatarChat\Docs"
    if (Test-Path -LiteralPath $gameDocsRoot) {
        Copy-RequiredFile -Source (Join-Path $docsRoot "RELEASE_READINESS_REPORT.md") -Destination (Join-Path $gameDocsRoot "RELEASE_READINESS_REPORT.md")
    }
    Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot
}

Write-Host "External playtest package created: $packageRoot"


