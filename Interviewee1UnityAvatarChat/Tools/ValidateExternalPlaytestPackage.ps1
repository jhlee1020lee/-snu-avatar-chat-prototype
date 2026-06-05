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
        throw "Missing external playtest package item: $RelativePath"
    }
}

function Assert-TextContains {
    param(
        [string]$RelativePath,
        [string[]]$RequiredText
    )

    $path = Join-Path $rootPath $RelativePath
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

Assert-Path "README_EXTERNAL_PLAYTEST.txt"
Assert-Path "RUN_EVIDENCE_AUDIT.bat"
Assert-Path "RUN_FINAL_EVIDENCE_GATE.bat"
Assert-Path "PLAYTEST_PACKAGE_MANIFEST.tsv"
Assert-Path "Game\START_HERE.txt"
Assert-Path "Game\Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat"
Assert-Path "Game\Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1"
Assert-Path "Game\Interviewee1UnityAvatarChat\CollectSupportBundle.ps1"
Assert-Path "Game\Interviewee1UnityAvatarChat\BUILD_INFO.txt"
Assert-Path "Game\Interviewee1UnityAvatarChat\Build\Interviewee1UnityAvatarChat.exe"
Assert-Path "Game\Interviewee1CloneAI\server.js"
Assert-Path "Game\Interviewee1CloneAI\data\persona.json"
Assert-Path "Game\NodeRuntime\node.exe"
Assert-Path "ObserverDocs\PLAYTEST_PROTOCOL.md"
Assert-Path "ObserverDocs\PLAYTEST_MODERATOR_SCRIPT.md"
Assert-Path "ObserverDocs\PLAYTEST_PARTICIPANT_BRIEF.md"
Assert-Path "ObserverDocs\ACCESSIBILITY_QA.md"
Assert-Path "ObserverDocs\ACCESSIBILITY_AUTOMATION_QA.md"
Assert-Path "ObserverDocs\ACCESSIBILITY_OBSERVATION_FORM.md"
Assert-Path "ObserverDocs\PRIVACY_NOTICE_DRAFT.md"
Assert-Path "ObserverDocs\PRIVACY_NOTICE_FINAL_TEMPLATE.md"
Assert-Path "ObserverDocs\STEAM_LEGAL_READINESS_QA.md"
Assert-Path "ObserverDocs\TROUBLESHOOTING.md"
Assert-Path "ObserverDocs\SUPPORT_HANDOFF.md"
Assert-Path "ObserverDocs\RELEASE_READINESS_REPORT.md"
Assert-Path "ObserverDocs\COMMERCIAL_LAUNCH_DECISION.md"
Assert-Path "ObserverDocs\COMMERCIAL_LAUNCH_GATE.md"
Assert-Path "ObserverDocs\EXTERNAL_EVIDENCE_REQUIREMENTS.md"
Assert-Path "ObserverDocs\EXTERNAL_EVIDENCE_AUDIT.md"
Assert-Path "ObserverDocs\PLAYTEST_EVIDENCE_SUMMARY.md"
Assert-Path "ObserverDocs\EXTERNAL_ISSUE_REGISTER_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv"
Assert-Path "ObserverDocs\COMMERCIAL_UI_COPY_QA.md"
Assert-Path "ObserverDocs\MODEL_CONFIG_QA.md"
Assert-Path "ObserverDocs\UNITY_LOCAL_FALLBACK_CONTENT_QA.md"
Assert-Path "ObserverDocs\GENERATED_MEMORY_POLICY_QA.md"
Assert-Path "ObserverDocs\UNITY_BUILD_SYNC_QA.md"
Assert-Path "ObserverDocs\COMMERCIAL_QUALITY_RUBRIC.md"
Assert-Path "ObserverDocs\COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv"
Assert-Path "ObserverDocs\COMMERCIAL_QUALITY_REVIEW_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_BRIEFS.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_BRIEFS_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_TRACKER.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_TRACKER_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEWER_ROSTER.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEWER_ROSTER_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEWER_PACKETS.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEWER_PACKETS_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_OUTREACH_QUEUE.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_OUTREACH_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_INVITE_OUTBOX.md"
Assert-Path "ObserverDocs\EXTERNAL_REVIEW_INVITE_OUTBOX_QA.md"
Assert-Path "ObserverDocs\EXTERNAL_EVIDENCE_IMPORT_QA.md"
Assert-Path "Forms\PLAYTEST_OBSERVATION_FORM.md"
Assert-Path "Forms\PLAYTEST_ISSUE_TRIAGE.md"
Assert-Path "Forms\ACCESSIBILITY_OBSERVATION_FORM.md"
Assert-Path "EvidenceDrop\README_EVIDENCE_DROP.txt"
Assert-Path "EvidenceDrop\README_EVIDENCE_WORKSPACE.md"
Assert-Path "EvidenceDrop\EVIDENCE_COLLECTION_PLAN.tsv"
Assert-Path "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv"
Assert-Path "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv"
Assert-Path "EvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.md"
Assert-Path "Marketing\Screenshots\06-closing-card.png"
Assert-Path "Marketing\Screenshots\04-dialogue-scroll.png"
Assert-Path "Marketing\Screenshots\08-record-delete.png"
Assert-Path "Marketing\Screenshots\10-data-policy-delete.png"
Assert-Path "Marketing\SteamAssets\small_capsule_462x174.png"
Assert-Path "Marketing\StoreCopy\STORE_COPY_QA_REPORT.tsv"
Assert-Path "Marketing\Trailer\trailer_animatic_60s.mp4"
Assert-Path "Marketing\VisualQuality\VISUAL_QUALITY_REPORT.tsv"
Assert-Path "EvidenceDrop\Playtest"
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
Assert-Path "EvidenceDrop\ReviewerInviteOutbox\PT-01_INVITE_READY.txt"
Assert-Path "EvidenceDrop\ReviewerPackets\REVIEWER_PACKET_MANIFEST.tsv"
Assert-Path "EvidenceDrop\ReviewerPackets\PT-01\README.md"
Assert-Path "EvidenceDrop\ReviewerPackets\PT-01\INVITE.txt"
Assert-Path "EvidenceDrop\ReviewerPackets\PT-01\ACCEPTANCE_CHECKLIST.tsv"
Assert-Path "EvidenceDrop\ReviewerPackets\PT-01\RETURN_CHECKLIST.tsv"
Assert-Path "EvidenceDrop\ReviewerPacketArchives\REVIEWER_PACKET_ARCHIVE_MANIFEST.tsv"
Assert-Path "EvidenceDrop\ReviewerPacketArchives\PT-01.zip"
Assert-Path "EvidenceDrop\ReviewerPacketArchives\ACCESS-01.zip"
Assert-Path "EvidenceDrop\ReviewBriefs\PLAYTEST_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\ACCESSIBILITY_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\ART_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\TRAILER_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\LEGAL_STEAM_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\QUALITY_SCORECARD_REVIEW_BRIEF.md"
Assert-Path "EvidenceDrop\ReviewBriefs\REVIEW_INVITATION_TEMPLATES.md"
Assert-Path "Tools\NewPlaytestEvidenceBundle.ps1"
Assert-Path "Tools\CollectExternalEvidenceSession.ps1"
Assert-Path "Tools\ValidateExternalEvidenceSession.ps1"
Assert-Path "Tools\RegisterExternalIssue.ps1"
Assert-Path "Tools\ValidateExternalEvidence.ps1"
Assert-Path "Tools\ValidatePlaytestFeedbackExport.ps1"
Assert-Path "Tools\ExportFeedbackToCommercialQualityScorecard.ps1"
Assert-Path "Tools\ImportPlaytestFeedbackIssues.ps1"
Assert-Path "Tools\PrepareCommercialEvidenceWorkspace.ps1"
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
Assert-Path "Tools\SummarizePlaytestEvidence.ps1"
Assert-Path "Tools\ValidateExternalIssueRegister.ps1"
Assert-Path "Tools\ValidateCommercialQualityRubric.ps1"
Assert-Path "Tools\WriteCommercialQualityEvidenceIndex.ps1"
Assert-Path "Tools\ValidateCommercialQualityEvidenceIndex.ps1"

Assert-TextContains "Game\START_HERE.txt" @(
    "API",
    "FeedbackNotes",
    "OPENAI_API_KEY"
)
Assert-TextContains "README_EXTERNAL_PLAYTEST.txt" @(
    "RUN_EVIDENCE_AUDIT.bat",
    "RUN_FINAL_EVIDENCE_GATE.bat",
    "EvidenceDrop\Playtest",
    "NewPlaytestEvidenceBundle.ps1",
    "CollectExternalEvidenceSession.ps1",
    "ValidateExternalEvidenceSession.ps1",
    "COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv",
    "EVIDENCE_COLLECTION_PLAN.tsv",
    "PLAYTEST_PARTICIPANT_BRIEF.md",
    "PLAYTEST_MODERATOR_SCRIPT.md",
    "EvidenceDrop\ReviewBriefs",
    "EvidenceDrop\ReviewerPackets",
    "EvidenceDrop\ReviewerPacketArchives",
    "EvidenceDrop\ReviewerInviteOutbox",
    "EXTERNAL_REVIEWER_ROSTER.tsv",
    "EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv",
    "EXTERNAL_REVIEW_TRACKER.tsv",
    "ReviewerInviteOutbox",
    "ImportExternalEvidenceDrop.ps1",
    "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv",
    "COMMERCIAL_QUALITY_SCORECARD.tsv"
)
Assert-TextContains "EvidenceDrop\README_EVIDENCE_DROP.txt" @(
    "RUN_EVIDENCE_AUDIT.bat",
    "EXTERNAL_EVIDENCE_AUDIT.md",
    "PLAYTEST_EVIDENCE_SUMMARY.md",
    "EXTERNAL_ISSUE_REGISTER_QA.md",
    "EVIDENCE_COLLECTION_PLAN.tsv",
    "COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv",
    "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv",
    "COMMERCIAL_QUALITY_REVIEW_QA.md"
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
Assert-Utf8Bom "Tools\ValidateCommercialQualityRubric.ps1"
Assert-Utf8Bom "Tools\WriteCommercialQualityEvidenceIndex.ps1"
Assert-Utf8Bom "Tools\ValidateCommercialQualityEvidenceIndex.ps1"

$nodeVersion = (& (Join-Path $rootPath "Game\NodeRuntime\node.exe") --version 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $nodeVersion -notmatch '^v(\d+)') {
    throw "External playtest NodeRuntime did not report a valid version."
}
if ([int]$Matches[1] -lt 20) {
    throw "External playtest NodeRuntime must be Node.js 20 or newer, found $nodeVersion"
}

$forbiddenMatches = Get-PackageFiles |
    Where-Object { $_.Name -match "\.log$|\.pid$|^\.server\.pid$" -or (Get-RelativePath -FullName $_.FullName) -match "(^|\\)(release-smoke)(\\|$)|(^|\\)smoke-[^\\]+\.png$" }
if ($forbiddenMatches) {
    $sample = ($forbiddenMatches | Select-Object -First 8 | ForEach-Object { Get-RelativePath -FullName $_.FullName }) -join ", "
    throw "External playtest package contains forbidden generated files: $sample"
}

$secretMatches = Get-TextPackageFiles |
    Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
if ($secretMatches) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { Get-RelativePath -FullName $_.Path }) -join ", "
    throw "External playtest package may contain an API key: $sample"
}

$manifest = Get-Content -LiteralPath (Join-Path $rootPath "PLAYTEST_PACKAGE_MANIFEST.tsv")
if ($manifest.Count -lt 20 -or $manifest[0] -ne "path`tbytes`tsha256") {
    throw "External playtest package manifest is missing or malformed."
}

Write-Host "External playtest package validation passed: $rootPath"
