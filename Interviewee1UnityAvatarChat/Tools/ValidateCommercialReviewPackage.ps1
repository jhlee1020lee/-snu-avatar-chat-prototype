param(
    [Parameter(Mandatory = $true)]
    [string]$PackageRoot
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

$root = Resolve-Path $PackageRoot
$rootPath = $root.Path
$rootLong = ConvertTo-LongPath -Path $rootPath

function Get-RelativePath {
    param([string]$FullName)

    if ($FullName.StartsWith($rootLong, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($rootLong.Length + 1)
    }
    if ($FullName.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($rootPath.Length + 1)
    }
    return $FullName
}

function Get-PackageFiles {
    @(Get-ChildItem -LiteralPath $rootLong -File -Recurse -ErrorAction Stop)
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

function Get-TextPackageFiles {
    Get-PackageFiles | Where-Object { Test-TextLikeFile -File $_ }
}

function Assert-Path {
    param([string]$RelativePath)

    $path = Join-Path $rootPath $RelativePath
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
        throw "Missing commercial review package item: $RelativePath"
    }
}

function Assert-TextContains {
    param(
        [string]$RelativePath,
        [string[]]$RequiredText
    )

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($text in $RequiredText) {
        if ($content -notmatch [regex]::Escape($text)) {
            throw "$RelativePath is missing required text: $text"
        }
    }
}

function Assert-Utf8Bom {
    param([string]$RelativePath)

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
        throw "$RelativePath must be UTF-8 with BOM for Windows PowerShell compatibility."
    }
}

function Assert-TsvHasNoFailures {
    param(
        [string]$RelativePath,
        [string]$StatusColumn = "status"
    )

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $path)
    if ($rows.Count -eq 0) {
        throw "Report has no rows: $RelativePath"
    }
    $failures = @($rows | Where-Object { $_.$StatusColumn -eq "실패" -or $_.$StatusColumn -eq "fail" })
    if ($failures.Count -gt 0) {
        throw "Report has failed rows: $RelativePath"
    }
}

function Assert-Provenance {
    param([string]$RelativePath)

    $path = Join-Path $rootPath $RelativePath
    Assert-Path -RelativePath $RelativePath
    $provenance = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$provenance.buildId)) {
        throw "Package provenance is missing buildId: $RelativePath"
    }
    if ([string]$provenance.packageType -ne "CommercialReview") {
        throw "Package provenance type mismatch: $($provenance.packageType)"
    }
}

Assert-Path "README_COMMERCIAL_REVIEW.txt"
Assert-Path "RUN_EVIDENCE_AUDIT.bat"
Assert-Path "RUN_FINAL_EVIDENCE_GATE.bat"
Assert-Path "COMMERCIAL_REVIEW_MANIFEST.tsv"
Assert-Provenance -RelativePath "PACKAGE_PROVENANCE.json"
Assert-Path "Docs\COMMERCIAL_RELEASE_REVIEW.md"
Assert-Path "Docs\EXTERNAL_EVIDENCE_REQUIREMENTS.md"
Assert-Path "Docs\EXTERNAL_EVIDENCE_AUDIT.md"
Assert-Path "Docs\PLAYTEST_EVIDENCE_SUMMARY.md"
Assert-Path "Docs\EXTERNAL_ISSUE_REGISTER_QA.md"
Assert-Path "Docs\EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv"
Assert-Path "Docs\MODEL_CONFIG_QA.md"
Assert-Path "Docs\UNITY_LOCAL_FALLBACK_CONTENT_QA.md"
Assert-Path "Docs\GENERATED_MEMORY_POLICY_QA.md"
Assert-Path "Docs\UNITY_BUILD_SYNC_QA.md"
Assert-Path "Docs\COMMERCIAL_UI_COPY_QA.md"
Assert-Path "Docs\COMMERCIAL_QUALITY_RUBRIC.md"
Assert-Path "Docs\COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv"
Assert-Path "Docs\COMMERCIAL_QUALITY_REVIEW_QA.md"
Assert-Path "Docs\RELEASE_READINESS_REPORT.md"
Assert-Path "Docs\COMMERCIAL_LAUNCH_DECISION.md"
Assert-Path "Docs\COMMERCIAL_LAUNCH_GATE.md"
Assert-Path "Docs\INTERNAL_QUALITY_REVIEW.md"
Assert-Path "Docs\INTERNAL_QUALITY_SCORECARD.tsv"
Assert-Path "Docs\INTERNAL_COMMERCIAL_REVIEW.md"
Assert-Path "Docs\INTERNAL_COMMERCIAL_BACKLOG.tsv"
Assert-Path "Docs\COMMERCIAL_SPRINT_PLAN.md"
Assert-Path "Docs\COMMERCIAL_SPRINT_BOARD.tsv"
Assert-Path "Docs\EXTERNAL_REVIEW_BRIEFS.md"
Assert-Path "Docs\EXTERNAL_REVIEW_BRIEFS_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEW_TRACKER.md"
Assert-Path "Docs\EXTERNAL_REVIEW_TRACKER_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_ROSTER.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_ROSTER_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_PACKETS.md"
Assert-Path "Docs\EXTERNAL_REVIEWER_PACKETS_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEW_OUTREACH_QUEUE.md"
Assert-Path "Docs\EXTERNAL_REVIEW_OUTREACH_QA.md"
Assert-Path "Docs\EXTERNAL_REVIEW_INVITE_OUTBOX.md"
Assert-Path "Docs\EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md"
Assert-Path "Docs\EXTERNAL_EVIDENCE_IMPORT_QA.md"
Assert-Path "Docs\COMMERCIAL_PRICE_POSITIONING.md"
Assert-Path "Docs\COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv"
Assert-Path "Docs\STEAM_MARKET_COMPARISON.md"
Assert-Path "Docs\STEAM_MARKET_COMPARISON.tsv"
Assert-Path "Docs\STEAM_MARKET_COMPARISON_QA.md"
Assert-Path "Docs\PLAYTEST_PROTOCOL.md"
Assert-Path "Docs\PLAYTEST_MODERATOR_SCRIPT.md"
Assert-Path "Docs\PLAYTEST_PARTICIPANT_BRIEF.md"
Assert-Path "Docs\ACCESSIBILITY_OBSERVATION_FORM.md"
Assert-Path "Docs\ACCESSIBILITY_AUTOMATION_QA.md"
Assert-Path "Docs\PRIVACY_NOTICE_DRAFT.md"
Assert-Path "Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md"
Assert-Path "Docs\STEAM_LEGAL_READINESS_QA.md"
Assert-Path "Marketing\STORE_PAGE_DRAFT.md"
Assert-Path "Marketing\STORE_PAGE_INTERNAL_NOTES.md"
Assert-TsvHasNoFailures -RelativePath "Marketing\StoreCopy\STORE_COPY_QA_REPORT.tsv"
Assert-Path "Marketing\SteamAssets\professional_keyart_1920x1080.png"
Assert-Path "Marketing\SteamAssets\source_keyart_1920x1080.png"
Assert-Path "Marketing\SteamAssets\Audit\small_capsule_preview_120x45.png"
Assert-Path "Marketing\Screenshots\SCREENSHOT_MANIFEST.tsv"
Assert-Path "Marketing\VisualQuality\VISUAL_QUALITY_REPORT.tsv"
Assert-Path "Marketing\Trailer\trailer_animatic_60s.mp4"
Assert-Path "Marketing\Trailer\trailer_build_capture_60s.mp4"
Assert-Path "Marketing\Trailer\TRAILER_FINAL_REVIEW_FORM.md"
Assert-Path "Marketing\ArtReview\ART_REVIEW_BRIEF.md"
Assert-Path "Marketing\ArtReview\ART_REVIEW_FORM.md"
Assert-Path "Marketing\Steamworks\STEAMWORKS_UPLOAD_PLAN.md"
Assert-Path "Marketing\Steamworks\STEAM_ADMIN_CHECKLIST.md"
Assert-Path "Tools\ValidateExternalEvidence.ps1"
Assert-Path "Tools\NewPlaytestEvidenceBundle.ps1"
Assert-Path "Tools\CollectExternalEvidenceSession.ps1"
Assert-Path "Tools\ValidateExternalEvidenceSession.ps1"
Assert-Path "Tools\RegisterExternalIssue.ps1"
Assert-Path "Tools\ValidatePlaytestFeedbackExport.ps1"
Assert-Path "Tools\ExportFeedbackToCommercialQualityScorecard.ps1"
Assert-Path "Tools\ImportPlaytestFeedbackIssues.ps1"
Assert-Path "Tools\PrepareCommercialEvidenceWorkspace.ps1"
Assert-Path "Tools\SummarizePlaytestEvidence.ps1"
Assert-Path "Tools\ValidateStoreCopy.ps1"
Assert-Path "Tools\ValidateModelConfig.ps1"
Assert-Path "Tools\ValidateAccessibilityAutomation.ps1"
Assert-Path "Tools\ValidateSteamLegalReadiness.ps1"
Assert-Path "Tools\WriteCommercialLaunchDecision.ps1"
Assert-Path "Tools\WriteInternalQualityScorecard.ps1"
Assert-Path "Tools\WriteInternalCommercialReview.ps1"
Assert-Path "Tools\WriteCommercialSprintPlan.ps1"
Assert-Path "Tools\WriteExternalReviewBriefs.ps1"
Assert-Path "Tools\ValidateExternalReviewBriefs.ps1"
Assert-Path "Tools\WriteExternalReviewTracker.ps1"
Assert-Path "Tools\ValidateExternalReviewTracker.ps1"
Assert-Path "Tools\WriteExternalReviewerRosterTemplate.ps1"
Assert-Path "Tools\ValidateExternalReviewerRoster.ps1"
Assert-Path "Tools\ApplyExternalReviewerRoster.ps1"
Assert-Path "Tools\WriteExternalReviewerPackets.ps1"
Assert-Path "Tools\ValidateExternalReviewerPackets.ps1"
Assert-Path "Tools\WriteExternalReviewerPacketArchives.ps1"
Assert-Path "Tools\ValidateExternalReviewerPacketArchives.ps1"
Assert-Path "Tools\WriteExternalReviewOutreachQueue.ps1"
Assert-Path "Tools\ValidateExternalReviewOutreachQueue.ps1"
Assert-Path "Tools\WriteExternalReviewInviteOutbox.ps1"
Assert-Path "Tools\ValidateExternalReviewInviteOutbox.ps1"
Assert-Path "Tools\ImportExternalEvidenceDrop.ps1"
Assert-Path "Tools\ValidateExternalEvidenceImport.ps1"
Assert-Path "Tools\WriteSteamMarketComparison.ps1"
Assert-Path "Tools\ValidateSteamMarketComparison.ps1"
Assert-Path "Tools\WriteCommercialPricePositioning.ps1"
Assert-Path "Tools\ValidateExternalIssueRegister.ps1"
Assert-Path "Tools\ValidateCommercialQualityRubric.ps1"
Assert-Path "Tools\WriteCommercialQualityEvidenceIndex.ps1"
Assert-Path "Tools\ValidateCommercialQualityEvidenceIndex.ps1"
Assert-Path "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv"
Assert-Path "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv"
Assert-Path "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.md"
Assert-Path "EvidenceDrop\README_EVIDENCE_WORKSPACE.md"
Assert-Path "EvidenceDrop\EVIDENCE_COLLECTION_PLAN.tsv"
Assert-Path "EvidenceDrop\Playtest\PLAYTEST_OBSERVATION_FORM_TEMPLATE.md"
Assert-Path "EvidenceDrop\Accessibility\ACCESSIBILITY_OBSERVATION_FORM_TEMPLATE.md"
Assert-Path "EvidenceDrop\ArtReview\ART_REVIEW_FORM_TEMPLATE.md"
Assert-Path "EvidenceDrop\Trailer\TRAILER_FINAL_REVIEW_FORM_TEMPLATE.md"
Assert-Path "EvidenceDrop\LegalSteam\STEAM_ADMIN_CHECKLIST_TEMPLATE.md"
Assert-Path "EvidenceDrop\LegalSteam\PRIVACY_NOTICE_FINAL_TEMPLATE.md"
Assert-Path "EvidenceDrop\EXTERNAL_REVIEW_TRACKER.tsv"
Assert-Path "EvidenceDrop\EXTERNAL_REVIEWER_ROSTER.tsv"
Assert-Path "EvidenceDrop\EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv"
Assert-Path "EvidenceDrop\EXTERNAL_REVIEW_INVITE_OUTBOX.md"
Assert-Path "EvidenceDrop\EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md"
Assert-Path "EvidenceDrop\ReviewerInviteOutbox\INVITE_OUTBOX_MANIFEST.tsv"
Assert-Path "EvidenceDrop\ReviewerInviteOutbox\QUALITY-01_INVITE_READY.txt"
Assert-Path "EvidenceDrop\ReviewerPackets\REVIEWER_PACKET_MANIFEST.tsv"
Assert-Path "EvidenceDrop\ReviewerPackets\QUALITY-01\README.md"
Assert-Path "EvidenceDrop\ReviewerPackets\QUALITY-01\INVITE.txt"
Assert-Path "EvidenceDrop\ReviewerPackets\QUALITY-01\ACCEPTANCE_CHECKLIST.tsv"
Assert-Path "EvidenceDrop\ReviewerPackets\QUALITY-01\RETURN_CHECKLIST.tsv"
Assert-Path "EvidenceDrop\ReviewerPacketArchives\REVIEWER_PACKET_ARCHIVE_MANIFEST.tsv"
Assert-Path "EvidenceDrop\ReviewerPacketArchives\QUALITY-01.zip"
Assert-Path "EvidenceDrop\ReviewerPacketArchives\ISSUE-01.zip"
Assert-Path "EvidenceDrop\ReviewBriefs\PLAYTEST_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\ACCESSIBILITY_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\ART_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\TRAILER_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\LEGAL_STEAM_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\QUALITY_SCORECARD_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\REVIEW_INVITATION_TEMPLATES.md"
Assert-Path "EvidenceDrop\Playtest\README.txt"
Assert-Path "EvidenceDrop\Accessibility\README.txt"
Assert-Path "EvidenceDrop\ArtReview\README.txt"
Assert-Path "EvidenceDrop\Trailer\README.txt"
Assert-Path "EvidenceDrop\LegalSteam\README.txt"

Assert-TextContains "README_COMMERCIAL_REVIEW.txt" @(
    "RUN_EVIDENCE_AUDIT.bat",
    "RUN_FINAL_EVIDENCE_GATE.bat",
    "EvidenceDrop",
    "EVIDENCE_COLLECTION_PLAN.tsv",
    "internal quality scorecard",
    "commercial sprint plan",
    "EvidenceDrop\ReviewBriefs",
    "EvidenceDrop\ReviewerPackets",
    "EvidenceDrop\ReviewerPacketArchives",
    "EvidenceDrop\ReviewerInviteOutbox",
    "EXTERNAL_REVIEWER_ROSTER.tsv",
    "EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv",
    "EXTERNAL_REVIEW_TRACKER.tsv",
    "NewPlaytestEvidenceBundle.ps1",
    "ReviewerInviteOutbox",
    "ImportExternalEvidenceDrop.ps1",
    "Steam market comparison",
    "price positioning",
    "COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv",
    "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv",
    "COMMERCIAL_QUALITY_SCORECARD.tsv"
)
Assert-TextContains "EvidenceDrop\Playtest\README.txt" @(
    "five external playtest session folders",
    "NewPlaytestEvidenceBundle.ps1",
    "CollectExternalEvidenceSession.ps1",
    "ValidateExternalEvidenceSession.ps1"
)
Assert-TextContains "EvidenceDrop\EVIDENCE_COLLECTION_PLAN.tsv" @(
    "INT-PLAYTEST-001",
    "NewPlaytestEvidenceBundle.ps1",
    "EvidenceDrop\Playtest"
)
Assert-TextContains "EvidenceDrop\ReviewerInviteOutbox\PT-01_INVITE_READY.txt" @(
    "Source invite body",
    "NewPlaytestEvidenceBundle.ps1",
    "Do not add credentials"
)
Assert-TextContains "EvidenceDrop\LegalSteam\README.txt" @(
    "Steam admin checklist",
    "final privacy wording",
    "Steam test branch execution evidence"
)
Assert-TextContains "RUN_EVIDENCE_AUDIT.bat" @(
    "POWERSHELL_EXE=pwsh",
    "ValidateExternalEvidence.ps1",
    "EvidenceDrop",
    "ValidateExternalIssueRegister.ps1",
    "ExportFeedbackToCommercialQualityScorecard.ps1",
    "ImportPlaytestFeedbackIssues.ps1",
    "ValidateCommercialQualityEvidenceIndex.ps1",
    "ValidateCommercialQualityRubric.ps1"
)
Assert-TextContains "RUN_FINAL_EVIDENCE_GATE.bat" @(
    "POWERSHELL_EXE=pwsh",
    "-RequireComplete",
    "-RequireNoBlockers",
    "-RequireClosed",
    "-RequireReady"
)
Assert-Utf8Bom "Tools\ValidateExternalEvidence.ps1"
Assert-Utf8Bom "Tools\NewPlaytestEvidenceBundle.ps1"
Assert-Utf8Bom "Tools\ValidateExternalEvidenceSession.ps1"
Assert-Utf8Bom "Tools\SummarizePlaytestEvidence.ps1"
Assert-Utf8Bom "Tools\ValidateExternalIssueRegister.ps1"
Assert-Utf8Bom "Tools\RegisterExternalIssue.ps1"
Assert-Utf8Bom "Tools\ExportFeedbackToCommercialQualityScorecard.ps1"
Assert-Utf8Bom "Tools\ImportPlaytestFeedbackIssues.ps1"
Assert-Utf8Bom "Tools\PrepareCommercialEvidenceWorkspace.ps1"
Assert-Utf8Bom "Tools\WriteInternalQualityScorecard.ps1"
Assert-Utf8Bom "Tools\WriteInternalCommercialReview.ps1"
Assert-Utf8Bom "Tools\WriteCommercialSprintPlan.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewBriefs.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewBriefs.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewTracker.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewTracker.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewerRosterTemplate.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewerRoster.ps1"
Assert-Utf8Bom "Tools\ApplyExternalReviewerRoster.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewerPackets.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewerPackets.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewerPacketArchives.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewerPacketArchives.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewOutreachQueue.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewOutreachQueue.ps1"
Assert-Utf8Bom "Tools\WriteExternalReviewInviteOutbox.ps1"
Assert-Utf8Bom "Tools\ValidateExternalReviewInviteOutbox.ps1"
Assert-Utf8Bom "Tools\ImportExternalEvidenceDrop.ps1"
Assert-Utf8Bom "Tools\ValidateExternalEvidenceImport.ps1"
Assert-Utf8Bom "Tools\WriteSteamMarketComparison.ps1"
Assert-Utf8Bom "Tools\ValidateSteamMarketComparison.ps1"
Assert-Utf8Bom "Tools\WriteCommercialPricePositioning.ps1"
Assert-Utf8Bom "Tools\ValidateCommercialQualityRubric.ps1"
Assert-Utf8Bom "Tools\WriteCommercialQualityEvidenceIndex.ps1"
Assert-Utf8Bom "Tools\ValidateCommercialQualityEvidenceIndex.ps1"

$forbiddenMatches = Get-PackageFiles |
    Where-Object { $_.Name -match "\.log$|\.pid$|^\.server\.pid$" -or (Get-RelativePath -FullName $_.FullName) -match "(^|\\)(release-smoke)(\\|$)|(^|\\)smoke-[^\\]+\.png$" }
if ($forbiddenMatches) {
    $sample = ($forbiddenMatches | Select-Object -First 8 | ForEach-Object { Get-RelativePath -FullName $_.FullName }) -join ", "
    throw "Commercial review package contains forbidden generated files: $sample"
}

$secretMatches = Get-TextPackageFiles |
    Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
if ($secretMatches) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { Get-RelativePath -FullName $_.Path }) -join ", "
    throw "Commercial review package may contain an API key: $sample"
}

$manifest = Get-Content -LiteralPath (Join-Path $rootPath "COMMERCIAL_REVIEW_MANIFEST.tsv")
if ($manifest.Count -lt 20 -or $manifest[0] -ne "path`tbytes`tsha256") {
    throw "Commercial review package manifest is missing or malformed."
}

Write-Host "Commercial review package validation passed: $rootPath"
