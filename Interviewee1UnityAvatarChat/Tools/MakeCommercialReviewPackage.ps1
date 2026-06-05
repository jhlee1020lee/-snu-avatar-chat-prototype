param(
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

    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $PackageRoot)) {
        Remove-Item -LiteralPath (ConvertTo-LongPath -Path $PackageRoot) -Recurse -Force -ErrorAction Stop
    }
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
$marketingRoot = Join-Path $projectRoot "Marketing"
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "CommercialReviewPackages"
}
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $PackageName = "GeotNotEqualSok-CommercialReview-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$packageRoot = Join-Path $OutputRoot $PackageName
$packageMarketingRoot = Join-Path $packageRoot "Marketing"
$packageDocsRoot = Join-Path $packageRoot "Docs"
$packageToolsRoot = Join-Path $packageRoot "Tools"
$evidenceRoot = Join-Path $packageRoot "EvidenceDrop"

$storeCopyValidationScript = Join-Path $projectRoot "Tools\ValidateStoreCopy.ps1"
& $storeCopyValidationScript 2>&1 | Out-Null
$steamLegalValidationScript = Join-Path $projectRoot "Tools\ValidateSteamLegalReadiness.ps1"
& $steamLegalValidationScript 2>&1 | Out-Null
$commercialUiCopyValidationScript = Join-Path $projectRoot "Tools\ValidateCommercialUiCopy.ps1"
& $commercialUiCopyValidationScript 2>&1 | Out-Null
$commercialDecisionScript = Join-Path $projectRoot "Tools\WriteCommercialLaunchDecision.ps1"
& $commercialDecisionScript 2>&1 | Out-Null
$internalQualityScript = Join-Path $projectRoot "Tools\WriteInternalQualityScorecard.ps1"
& $internalQualityScript 2>&1 | Out-Null
$internalReviewScript = Join-Path $projectRoot "Tools\WriteInternalCommercialReview.ps1"
& $internalReviewScript 2>&1 | Out-Null
$sprintPlanScript = Join-Path $projectRoot "Tools\WriteCommercialSprintPlan.ps1"
& $sprintPlanScript 2>&1 | Out-Null
$externalReviewBriefsScript = Join-Path $projectRoot "Tools\WriteExternalReviewBriefs.ps1"
& $externalReviewBriefsScript 2>&1 | Out-Null
$externalReviewBriefsValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewBriefs.ps1"
& $externalReviewBriefsValidationScript 2>&1 | Out-Null
$externalReviewTrackerScript = Join-Path $projectRoot "Tools\WriteExternalReviewTracker.ps1"
& $externalReviewTrackerScript 2>&1 | Out-Null
$externalReviewTrackerValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewTracker.ps1"
& $externalReviewTrackerValidationScript 2>&1 | Out-Null
$externalReviewerRosterScript = Join-Path $projectRoot "Tools\WriteExternalReviewerRosterTemplate.ps1"
& $externalReviewerRosterScript 2>&1 | Out-Null
$externalReviewerRosterValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewerRoster.ps1"
& $externalReviewerRosterValidationScript 2>&1 | Out-Null
$externalReviewerPacketsScript = Join-Path $projectRoot "Tools\WriteExternalReviewerPackets.ps1"
& $externalReviewerPacketsScript 2>&1 | Out-Null
$externalReviewerPacketsValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewerPackets.ps1"
& $externalReviewerPacketsValidationScript 2>&1 | Out-Null
$externalReviewerPacketArchivesScript = Join-Path $projectRoot "Tools\WriteExternalReviewerPacketArchives.ps1"
& $externalReviewerPacketArchivesScript 2>&1 | Out-Null
$externalReviewerPacketArchivesValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewerPacketArchives.ps1"
& $externalReviewerPacketArchivesValidationScript 2>&1 | Out-Null
$qualityEvidenceIndexScript = Join-Path $projectRoot "Tools\WriteCommercialQualityEvidenceIndex.ps1"
& $qualityEvidenceIndexScript 2>&1 | Out-Null
$qualityEvidenceIndexValidationScript = Join-Path $projectRoot "Tools\ValidateCommercialQualityEvidenceIndex.ps1"
& $qualityEvidenceIndexValidationScript -RequireComplete 2>&1 | Out-Null
$externalReviewOutreachScript = Join-Path $projectRoot "Tools\WriteExternalReviewOutreachQueue.ps1"
& $externalReviewOutreachScript 2>&1 | Out-Null
$externalReviewOutreachValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewOutreachQueue.ps1"
& $externalReviewOutreachValidationScript 2>&1 | Out-Null
$externalReviewInviteOutboxScript = Join-Path $projectRoot "Tools\WriteExternalReviewInviteOutbox.ps1"
& $externalReviewInviteOutboxScript 2>&1 | Out-Null
$externalReviewInviteOutboxValidationScript = Join-Path $projectRoot "Tools\ValidateExternalReviewInviteOutbox.ps1"
& $externalReviewInviteOutboxValidationScript 2>&1 | Out-Null
$externalEvidenceImportScript = Join-Path $projectRoot "Tools\ImportExternalEvidenceDrop.ps1"
& $externalEvidenceImportScript -SourceEvidenceDrop (Join-Path $buildRoot "ReleaseEvidence") -DestinationEvidenceRoot (Join-Path $buildRoot "ReleaseEvidence") -Preview 2>&1 | Out-Null
$externalEvidenceImportValidationScript = Join-Path $projectRoot "Tools\ValidateExternalEvidenceImport.ps1"
& $externalEvidenceImportValidationScript 2>&1 | Out-Null
$marketComparisonValidationScript = Join-Path $projectRoot "Tools\ValidateSteamMarketComparison.ps1"
& $marketComparisonValidationScript 2>&1 | Out-Null
$pricePositioningScript = Join-Path $projectRoot "Tools\WriteCommercialPricePositioning.ps1"
& $pricePositioningScript 2>&1 | Out-Null
$buildMetadataScript = Join-Path $projectRoot "Tools\WriteBuildMetadata.ps1"
& $buildMetadataScript 2>&1 | Out-Null
$buildInfoPath = Join-Path $buildRoot "BUILD_INFO.json"
$buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) {
    throw "BUILD_INFO.json is missing buildId."
}

Reset-PackageDirectory -PackageRoot $packageRoot -OutputRoot $OutputRoot
New-Item -ItemType Directory -Force -Path $packageMarketingRoot, $packageDocsRoot, $packageToolsRoot, $evidenceRoot | Out-Null

Copy-DirectoryContents -Source $marketingRoot -Destination $packageMarketingRoot

$docs = @(
    "COMMERCIAL_RELEASE_REVIEW.md",
    "EXTERNAL_EVIDENCE_REQUIREMENTS.md",
    "EXTERNAL_EVIDENCE_AUDIT.md",
    "PLAYTEST_EVIDENCE_SUMMARY.md",
    "EXTERNAL_ISSUE_REGISTER_QA.md",
    "EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv",
    "MODEL_CONFIG_QA.md",
    "UNITY_LOCAL_FALLBACK_CONTENT_QA.md",
    "GENERATED_MEMORY_POLICY_QA.md",
    "UNITY_BUILD_SYNC_QA.md",
    "COMMERCIAL_UI_COPY_QA.md",
    "COMMERCIAL_QUALITY_RUBRIC.md",
    "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv",
    "COMMERCIAL_QUALITY_REVIEW_QA.md",
    "RELEASE_READINESS_REPORT.md",
    "COMMERCIAL_LAUNCH_DECISION.md",
    "COMMERCIAL_LAUNCH_GATE.md",
    "INTERNAL_QUALITY_REVIEW.md",
    "INTERNAL_QUALITY_SCORECARD.tsv",
    "INTERNAL_COMMERCIAL_REVIEW.md",
    "INTERNAL_COMMERCIAL_BACKLOG.tsv",
    "COMMERCIAL_SPRINT_PLAN.md",
    "COMMERCIAL_SPRINT_BOARD.tsv",
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
    "EXTERNAL_EVIDENCE_IMPORT_QA.md",
    "COMMERCIAL_PRICE_POSITIONING.md",
    "COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv",
    "STEAM_MARKET_COMPARISON.md",
    "STEAM_MARKET_COMPARISON.tsv",
    "STEAM_MARKET_COMPARISON_QA.md",
    "RELEASE_CHECKLIST.md",
    "PLAYTEST_PROTOCOL.md",
    "PLAYTEST_MODERATOR_SCRIPT.md",
    "PLAYTEST_PARTICIPANT_BRIEF.md",
    "PLAYTEST_OBSERVATION_FORM.md",
    "PLAYTEST_ISSUE_TRIAGE.md",
    "ACCESSIBILITY_QA.md",
    "ACCESSIBILITY_AUTOMATION_QA.md",
    "ACCESSIBILITY_OBSERVATION_FORM.md",
    "PRIVACY_NOTICE_DRAFT.md",
    "PRIVACY_NOTICE_FINAL_TEMPLATE.md",
    "STEAM_LEGAL_READINESS_QA.md",
    "SUPPORT_HANDOFF.md",
    "TROUBLESHOOTING.md"
)
foreach ($name in $docs) {
    Copy-RequiredFile -Source (Join-Path $docsRoot $name) -Destination (Join-Path $packageDocsRoot $name)
}

Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalEvidence.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalEvidence.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\NewPlaytestEvidenceBundle.ps1") -Destination (Join-Path $packageToolsRoot "NewPlaytestEvidenceBundle.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\CollectExternalEvidenceSession.ps1") -Destination (Join-Path $packageToolsRoot "CollectExternalEvidenceSession.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalEvidenceSession.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalEvidenceSession.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\RegisterExternalIssue.ps1") -Destination (Join-Path $packageToolsRoot "RegisterExternalIssue.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidatePlaytestFeedbackExport.ps1") -Destination (Join-Path $packageToolsRoot "ValidatePlaytestFeedbackExport.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ExportFeedbackToCommercialQualityScorecard.ps1") -Destination (Join-Path $packageToolsRoot "ExportFeedbackToCommercialQualityScorecard.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ImportPlaytestFeedbackIssues.ps1") -Destination (Join-Path $packageToolsRoot "ImportPlaytestFeedbackIssues.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\PrepareCommercialEvidenceWorkspace.ps1") -Destination (Join-Path $packageToolsRoot "PrepareCommercialEvidenceWorkspace.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\SummarizePlaytestEvidence.ps1") -Destination (Join-Path $packageToolsRoot "SummarizePlaytestEvidence.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateStoreCopy.ps1") -Destination (Join-Path $packageToolsRoot "ValidateStoreCopy.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateModelConfig.ps1") -Destination (Join-Path $packageToolsRoot "ValidateModelConfig.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateAccessibilityAutomation.ps1") -Destination (Join-Path $packageToolsRoot "ValidateAccessibilityAutomation.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateSteamLegalReadiness.ps1") -Destination (Join-Path $packageToolsRoot "ValidateSteamLegalReadiness.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteCommercialLaunchDecision.ps1") -Destination (Join-Path $packageToolsRoot "WriteCommercialLaunchDecision.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteInternalQualityScorecard.ps1") -Destination (Join-Path $packageToolsRoot "WriteInternalQualityScorecard.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteInternalCommercialReview.ps1") -Destination (Join-Path $packageToolsRoot "WriteInternalCommercialReview.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteCommercialSprintPlan.ps1") -Destination (Join-Path $packageToolsRoot "WriteCommercialSprintPlan.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewBriefs.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewBriefs.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewBriefs.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewBriefs.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewTracker.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewTracker.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewTracker.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewTracker.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewerRosterTemplate.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewerRosterTemplate.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewerRoster.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewerRoster.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ApplyExternalReviewerRoster.ps1") -Destination (Join-Path $packageToolsRoot "ApplyExternalReviewerRoster.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewerPackets.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewerPackets.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewerPackets.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewerPackets.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewerPacketArchives.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewerPacketArchives.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewerPacketArchives.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewerPacketArchives.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewOutreachQueue.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewOutreachQueue.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewOutreachQueue.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewOutreachQueue.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteExternalReviewInviteOutbox.ps1") -Destination (Join-Path $packageToolsRoot "WriteExternalReviewInviteOutbox.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalReviewInviteOutbox.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalReviewInviteOutbox.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ImportExternalEvidenceDrop.ps1") -Destination (Join-Path $packageToolsRoot "ImportExternalEvidenceDrop.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalEvidenceImport.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalEvidenceImport.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteSteamMarketComparison.ps1") -Destination (Join-Path $packageToolsRoot "WriteSteamMarketComparison.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateSteamMarketComparison.ps1") -Destination (Join-Path $packageToolsRoot "ValidateSteamMarketComparison.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteCommercialPricePositioning.ps1") -Destination (Join-Path $packageToolsRoot "WriteCommercialPricePositioning.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateExternalIssueRegister.ps1") -Destination (Join-Path $packageToolsRoot "ValidateExternalIssueRegister.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateCommercialQualityRubric.ps1") -Destination (Join-Path $packageToolsRoot "ValidateCommercialQualityRubric.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\WriteCommercialQualityEvidenceIndex.ps1") -Destination (Join-Path $packageToolsRoot "WriteCommercialQualityEvidenceIndex.ps1")
Copy-RequiredFile -Source (Join-Path $projectRoot "Tools\ValidateCommercialQualityEvidenceIndex.ps1") -Destination (Join-Path $packageToolsRoot "ValidateCommercialQualityEvidenceIndex.ps1")
Convert-PackageScriptsToUtf8Bom -Path $packageToolsRoot
Copy-RequiredFile -Source (Join-Path $docsRoot "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv") -Destination (Join-Path $evidenceRoot "COMMERCIAL_QUALITY_SCORECARD.tsv")
Copy-RequiredFile -Source (Join-Path $buildRoot "ReleaseEvidence\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv") -Destination (Join-Path $evidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv")
Copy-RequiredFile -Source (Join-Path $docsRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.md") -Destination (Join-Path $evidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.md")
& (Join-Path $projectRoot "Tools\PrepareCommercialEvidenceWorkspace.ps1") -EvidenceRoot $evidenceRoot -BacklogPath (Join-Path $docsRoot "INTERNAL_COMMERCIAL_BACKLOG.tsv") -Force 2>&1 | Out-Null
& (Join-Path $projectRoot "Tools\WriteExternalReviewInviteOutbox.ps1") -EvidenceRoot $evidenceRoot -OutputPath (Join-Path $evidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md") 2>&1 | Out-Null
& (Join-Path $projectRoot "Tools\ValidateExternalReviewInviteOutbox.ps1") -EvidenceRoot $evidenceRoot -DocsPath (Join-Path $evidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX.md") -OutputPath (Join-Path $evidenceRoot "EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md") 2>&1 | Out-Null

$evidenceReadmes = @{
    Playtest = "Place five external playtest session folders here. Each counted session needs the filled observation form, original feedback txt/json, support bundle, SESSION_QA.md, SESSION_FILE_MANIFEST.tsv, and issue media when relevant. Use Tools\NewPlaytestEvidenceBundle.ps1 for automatic latest-feedback collection, Tools\CollectExternalEvidenceSession.ps1 for manual paths, or Tools\ValidateExternalEvidenceSession.ps1 -SessionRoot <session> -RequireComplete after copying a session manually."
    Accessibility = "Place completed accessibility observation forms and screen or recording evidence here. Include keyboard-only, scaling, contrast, subtitle/readability, or assistive-device findings when tested."
    ArtReview = "Place completed art review forms and key art or capsule review evidence here. Include final reviewer name, decision, and required fixes."
    Trailer = "Place final trailer review form, final video file, and caption or subtitle evidence here."
    LegalSteam = "Place Steam admin checklist, completed final privacy wording file PRIVACY_NOTICE_FINAL.md based on the included template, and Steam test branch execution evidence here. Do not include Steam credentials, account passwords, or Steam Guard codes."
}
foreach ($folder in @("Playtest", "Accessibility", "ArtReview", "Trailer", "LegalSteam")) {
    $path = Join-Path $evidenceRoot $folder
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    $folderReadme = @"
$($evidenceReadmes[$folder])

After adding evidence, run RUN_EVIDENCE_AUDIT.bat from the package root.
Do not include API keys, Steam credentials, passwords, or private account notes.
"@
    Set-Content -LiteralPath (Join-Path $path "README.txt") -Value $folderReadme -Encoding UTF8
}

$readme = @"
겉!=속 commercial review package

Purpose:
- external art review
- final trailer review
- accessibility evidence review
- legal and Steam admin readiness review
- 5 dollar quality scorecard review

Key folders:
- Marketing: store page draft, store copy QA report, screenshots, Steam assets, trailer candidates, Steamworks templates, review forms
- Docs: release readiness, commercial launch decision, internal quality scorecard, commercial sprint plan, Steam market comparison, price positioning, internal commercial review backlog, model config QA, commercial UI copy QA, commercial gate, privacy draft and final template, Steam/legal readiness QA, support handoff, accessibility QA reports and forms
- Tools: external evidence collection, issue register, legal readiness, and audit scripts
- EvidenceDrop: place external review evidence by category, follow EVIDENCE_COLLECTION_PLAN.tsv, review COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv and COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv, and fill COMMERCIAL_QUALITY_SCORECARD.tsv
- EvidenceDrop\ReviewBriefs: role-specific handoff briefs and invitation text for each external reviewer
- EvidenceDrop\EXTERNAL_REVIEW_TRACKER.tsv: reviewer assignment, invitation, due date, and evidence receipt tracker
- EvidenceDrop\EXTERNAL_REVIEWER_ROSTER.tsv: reviewer alias, contact route, due date, and backup roster for applying assignments
- EvidenceDrop\ReviewerPackets: per-reviewer invite, README, source brief, and acceptance checklist packets
- EvidenceDrop\ReviewerPacketArchives: one ZIP per reviewer packet, with SHA256 manifest
- EvidenceDrop\EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv: next assignment, invite, follow-up, and import queue
- EvidenceDrop\ReviewerInviteOutbox: copy-ready invite files after reviewer assignments are applied
- Tools\NewPlaytestEvidenceBundle.ps1: collect latest saved playtest feedback plus a generated support bundle into EvidenceDrop\Playtest
- Tools\ImportExternalEvidenceDrop.ps1: after the package is returned, use this from the source project to import a reviewed EvidenceDrop safely

Run RUN_EVIDENCE_AUDIT.bat after adding evidence. It writes EXTERNAL_EVIDENCE_AUDIT.md, PLAYTEST_EVIDENCE_SUMMARY.md, EXTERNAL_ISSUE_REGISTER_QA.md, COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv, and COMMERCIAL_QUALITY_REVIEW_QA.md into EvidenceDrop.
The draft scorecard is only a reviewer aid. It does not replace COMMERCIAL_QUALITY_SCORECARD.tsv.
The quality evidence index is also only a reviewer aid. It does not replace COMMERCIAL_QUALITY_SCORECARD.tsv.
Run RUN_FINAL_EVIDENCE_GATE.bat only after all external evidence, quality scorecard, and issue closure are ready for launch review.

Do not add API keys, Steam credentials, passwords, or private account notes to this package.
"@
Set-Content -LiteralPath (Join-Path $packageRoot "README_COMMERCIAL_REVIEW.txt") -Value $readme -Encoding UTF8

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

$provenance = [ordered]@{
    packageType = "CommercialReview"
    packageName = $PackageName
    displayName = "겉!=속"
    version = [string]$buildInfo.version
    buildId = [string]$buildInfo.buildId
    generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
    sourceBuildInfo = "Build\BUILD_INFO.json"
}
$provenance | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $packageRoot "PACKAGE_PROVENANCE.json") -Encoding UTF8

$manifestPath = Join-Path $packageRoot "COMMERCIAL_REVIEW_MANIFEST.tsv"
Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot

$releaseReadinessScript = Join-Path $projectRoot "Tools\WriteReleaseReadinessReport.ps1"
if (Test-Path -LiteralPath $releaseReadinessScript) {
    try {
        & $releaseReadinessScript -CommercialReviewPackageRoot $packageRoot 2>&1 | Out-Null
    }
    catch {
        Write-Warning "Release readiness snapshot has pending failures: $($_.Exception.Message)"
    }
    Copy-RequiredFile -Source (Join-Path $docsRoot "RELEASE_READINESS_REPORT.md") -Destination (Join-Path $packageDocsRoot "RELEASE_READINESS_REPORT.md")
    Write-PackageManifest -ManifestPath $manifestPath -PackageRoot $packageRoot
}

Write-Host "Commercial review package created: $packageRoot"

