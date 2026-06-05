param(
    [string]$FeedbackRoot,
    [string]$BuildInfoPath,
    [switch]$RequireFiveTurnSession
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"
$AllowedQualityAreas = @("core_loop", "writing", "readability", "controls", "trust_privacy", "art_presentation", "trailer_store", "stability_package")
$AllowedQualityFocusAreas = @("auto") + $AllowedQualityAreas
$AllowedRiskTags = @("incomplete-session", "ending-record-missing", "negative-rating", "commercial-insufficient", "commercial-hold", "issue-p2", "issue-p1", "issue-p0", "accessibility-settings-used", "local-only")
$AllowedEvidenceTiers = @("positive-complete-session", "incomplete-positive", "ending-record-needed", "issue-or-hold", "neutral-note")

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing path: $Path"
    }
}

function Assert-TextContains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($FeedbackRoot)) {
    $FeedbackRoot = Join-Path $buildRoot "release-smoke\playtest-feedback-files"
}
if ([string]::IsNullOrWhiteSpace($BuildInfoPath)) {
    $BuildInfoPath = Join-Path $buildRoot "BUILD_INFO.json"
}

Assert-Path -Path $FeedbackRoot
Assert-Path -Path $BuildInfoPath

$buildInfo = Get-Content -LiteralPath $BuildInfoPath -Raw | ConvertFrom-Json
$expectedBuildId = [string]$buildInfo.buildId
if ([string]::IsNullOrWhiteSpace($expectedBuildId)) {
    throw "BUILD_INFO.json is missing buildId."
}

$jsonFiles = @(Get-ChildItem -LiteralPath $FeedbackRoot -Filter "*.json" -File | Sort-Object LastWriteTime -Descending)
$txtFiles = @(Get-ChildItem -LiteralPath $FeedbackRoot -Filter "*.txt" -File | Sort-Object LastWriteTime -Descending)
if ($jsonFiles.Count -lt 1 -or $txtFiles.Count -lt 1) {
    throw "Playtest feedback export must contain at least one txt and one json file."
}

$validPairs = 0
$latestTurns = 0
$latestSessionId = ""
foreach ($jsonFile in $jsonFiles) {
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($jsonFile.Name)
    $txtPath = Join-Path $FeedbackRoot "$stem.txt"
    if (-not (Test-Path -LiteralPath $txtPath)) {
        throw "Missing matching txt file for $($jsonFile.Name)."
    }

    $manifest = Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json
    $text = Get-Content -LiteralPath $txtPath -Raw

    $sessionId = [string]$manifest.sessionId
    $buildId = [string]$manifest.buildId
    $rating = [string]$manifest.rating
    $commercialReadiness = [string]$manifest.commercialReadiness
    $issueSeverity = [string]$manifest.issueSeverity
    $runtimePlatform = [string]$manifest.runtimePlatform
    $operatingSystem = [string]$manifest.operatingSystem
    $screen = [string]$manifest.screen
    $turns = [int]$manifest.conversationTurns
    $sessionCompletionLine = ([string]$manifest.sessionCompletionLine).Trim()
    $openedMemoryCount = [int]$manifest.openedMemoryCount
    $memoryThemeCount = [int]$manifest.memoryThemeCount
    $openedSceneTags = @($manifest.openedSceneTags | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $dominantAttitude = ([string]$manifest.dominantAttitude).Trim()
    $deepMemoryCount = [int]$manifest.deepMemoryCount
    $completedFiveTurnSession = [bool]$manifest.completedFiveTurnSession
    $positiveEvidenceRequiresCompletedSession = [bool]$manifest.positiveEvidenceRequiresCompletedSession
    $positiveEvidenceRequiresEndingRecord = [bool]$manifest.positiveEvidenceRequiresEndingRecord
    $endingRecordSavedThisSession = [bool]$manifest.endingRecordSavedThisSession
    $qualityEvidenceReady = [bool]$manifest.qualityEvidenceReady
    $qualityFocusArea = ([string]$manifest.qualityFocusArea).Trim()
    $qualityAreas = @($manifest.qualityAreas | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $riskTags = @($manifest.riskTags | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $evidenceTier = ([string]$manifest.evidenceTier).Trim()
    $reviewActionRecommendation = ([string]$manifest.reviewActionRecommendation).Trim()
    $commercialQualityEvidenceLine = ([string]$manifest.commercialQualityEvidenceLine).Trim()

    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        throw "$($jsonFile.Name) is missing sessionId."
    }
    if ($buildId -ne $expectedBuildId) {
        throw "$($jsonFile.Name) buildId '$buildId' does not match BUILD_INFO '$expectedBuildId'."
    }
    if ($rating -notin @("헷갈림", "보통", "좋음")) {
        throw "$($jsonFile.Name) has invalid rating '$rating'."
    }
    if ($commercialReadiness -notin @("부족", "보류", "충분")) {
        throw "$($jsonFile.Name) has invalid commercialReadiness '$commercialReadiness'."
    }
    if ($issueSeverity -notin @("없음", "P2", "P1", "P0")) {
        throw "$($jsonFile.Name) has invalid issueSeverity '$issueSeverity'."
    }
    if ([string]::IsNullOrWhiteSpace($runtimePlatform) -or [string]::IsNullOrWhiteSpace($operatingSystem) -or [string]::IsNullOrWhiteSpace($screen)) {
        throw "$($jsonFile.Name) is missing runtime environment fields."
    }
    if ($turns -lt 0 -or $openedMemoryCount -lt 0 -or $memoryThemeCount -lt 1 -or $openedMemoryCount -gt $memoryThemeCount) {
        throw "$($jsonFile.Name) has invalid progress counts."
    }
    if ([string]::IsNullOrWhiteSpace($sessionCompletionLine) -or $sessionCompletionLine -notmatch "문답|5문답 완료") {
        throw "$($jsonFile.Name) is missing sessionCompletionLine."
    }
    if ([string]::IsNullOrWhiteSpace($dominantAttitude)) {
        throw "$($jsonFile.Name) is missing dominantAttitude."
    }
    if ($deepMemoryCount -lt 0 -or $deepMemoryCount -gt $memoryThemeCount) {
        throw "$($jsonFile.Name) has invalid deepMemoryCount '$deepMemoryCount'."
    }
    if ($openedSceneTags.Count -ne $openedMemoryCount) {
        throw "$($jsonFile.Name) openedSceneTags count $($openedSceneTags.Count) does not match openedMemoryCount $openedMemoryCount."
    }
    foreach ($tag in $openedSceneTags) {
        if ($tag -notmatch "^[^:]+:(deep|shallow)$") {
            throw "$($jsonFile.Name) has invalid openedSceneTags value '$tag'."
        }
    }
    if ($RequireFiveTurnSession -and $turns -lt 5) {
        throw "$($jsonFile.Name) has only $turns turn(s); expected at least 5."
    }
    if ($RequireFiveTurnSession -and -not $completedFiveTurnSession) {
        throw "$($jsonFile.Name) is missing completedFiveTurnSession=true for a required five-turn session."
    }
    if ($positiveEvidenceRequiresCompletedSession -and -not $completedFiveTurnSession) {
        throw "$($jsonFile.Name) marks positive evidence before completing five turns."
    }
    if ($qualityEvidenceReady -and (-not $positiveEvidenceRequiresCompletedSession -or -not $completedFiveTurnSession)) {
        throw "$($jsonFile.Name) has inconsistent qualityEvidenceReady state."
    }
    if ($qualityEvidenceReady -and -not $endingRecordSavedThisSession) {
        throw "$($jsonFile.Name) marks qualityEvidenceReady=true without endingRecordSavedThisSession=true."
    }
    if ($positiveEvidenceRequiresEndingRecord -and (-not $completedFiveTurnSession -or $endingRecordSavedThisSession)) {
        throw "$($jsonFile.Name) has inconsistent positiveEvidenceRequiresEndingRecord state."
    }
    if ($qualityAreas.Count -lt 1 -or $qualityAreas -notcontains "core_loop") {
        throw "$($jsonFile.Name) is missing structured qualityAreas with core_loop."
    }
    if ($qualityFocusArea -notin $AllowedQualityFocusAreas) {
        throw "$($jsonFile.Name) has unsupported qualityFocusArea '$qualityFocusArea'."
    }
    if ($qualityFocusArea -ne "auto" -and $qualityAreas -notcontains $qualityFocusArea) {
        throw "$($jsonFile.Name) selected qualityFocusArea '$qualityFocusArea' is missing from qualityAreas."
    }
    foreach ($area in $qualityAreas) {
        if ($area -notin $AllowedQualityAreas) {
            throw "$($jsonFile.Name) has unsupported qualityAreas value '$area'."
        }
    }
    foreach ($tag in $riskTags) {
        if ($tag -notin $AllowedRiskTags) {
            throw "$($jsonFile.Name) has unsupported riskTags value '$tag'."
        }
    }
    if ($evidenceTier -notin $AllowedEvidenceTiers) {
        throw "$($jsonFile.Name) has unsupported evidenceTier '$evidenceTier'."
    }
    if ([string]::IsNullOrWhiteSpace($reviewActionRecommendation) -or $reviewActionRecommendation.Length -lt 16) {
        throw "$($jsonFile.Name) is missing a useful reviewActionRecommendation."
    }
    if ([string]::IsNullOrWhiteSpace($commercialQualityEvidenceLine) -or $commercialQualityEvidenceLine.Length -lt 18 -or $commercialQualityEvidenceLine -notmatch "점수표") {
        throw "$($jsonFile.Name) is missing a useful commercialQualityEvidenceLine."
    }
    if ($qualityEvidenceReady -and $evidenceTier -ne "positive-complete-session") {
        throw "$($jsonFile.Name) has qualityEvidenceReady=true but evidenceTier '$evidenceTier'."
    }
    if ($qualityEvidenceReady -and $commercialQualityEvidenceLine -notmatch "점수표 후보") {
        throw "$($jsonFile.Name) has qualityEvidenceReady=true but commercialQualityEvidenceLine '$commercialQualityEvidenceLine'."
    }
    if ($positiveEvidenceRequiresEndingRecord -and $evidenceTier -ne "ending-record-needed") {
        throw "$($jsonFile.Name) has positiveEvidenceRequiresEndingRecord=true but evidenceTier '$evidenceTier'."
    }
    if ($turns -lt 5 -and $riskTags -notcontains "incomplete-session") {
        throw "$($jsonFile.Name) is missing incomplete-session risk tag for an unfinished session."
    }
    if ($issueSeverity -ne "없음" -and $riskTags -notcontains "issue-$($issueSeverity.ToLowerInvariant())") {
        throw "$($jsonFile.Name) is missing matching issue risk tag for '$issueSeverity'."
    }

    Assert-TextContains -Text $text -Pattern "세션 ID:\s*$([regex]::Escape($sessionId))" -Message "$($jsonFile.Name) matching txt is missing the same session ID."
    Assert-TextContains -Text $text -Pattern "빌드 ID:\s*$([regex]::Escape($expectedBuildId))" -Message "$($jsonFile.Name) matching txt is missing the expected build ID."
    Assert-TextContains -Text $text -Pattern "설정:\s*글자 크기 단계" -Message "$($jsonFile.Name) matching txt is missing accessibility/settings metadata."
    Assert-TextContains -Text $text -Pattern "5달러 기준:\s*$([regex]::Escape($commercialReadiness))" -Message "$($jsonFile.Name) matching txt is missing the 5 dollar readiness field."
    Assert-TextContains -Text $text -Pattern "이슈 등급:\s*$([regex]::Escape($issueSeverity))" -Message "$($jsonFile.Name) matching txt is missing the issue severity field."
    Assert-TextContains -Text $text -Pattern "세션 완성도:\s*$([regex]::Escape($sessionCompletionLine))" -Message "$($jsonFile.Name) matching txt is missing the session completion line."
    Assert-TextContains -Text $text -Pattern "주된 질문 태도:\s*$([regex]::Escape($dominantAttitude))" -Message "$($jsonFile.Name) matching txt is missing the dominant attitude."
    Assert-TextContains -Text $text -Pattern "깊은 기록 수:\s*$deepMemoryCount/$memoryThemeCount" -Message "$($jsonFile.Name) matching txt is missing the deep memory count."
    Assert-TextContains -Text $text -Pattern "열린 장면 태그:\s*.+" -Message "$($jsonFile.Name) matching txt is missing opened scene tags."
    Assert-TextContains -Text $text -Pattern "5문답 완료:\s*(예|아니오)" -Message "$($jsonFile.Name) matching txt is missing five-turn completion metadata."
    Assert-TextContains -Text $text -Pattern "마무리 기록 저장:\s*(예|아니오)" -Message "$($jsonFile.Name) matching txt is missing ending-record metadata."
    Assert-TextContains -Text $text -Pattern "긍정 근거 마무리 필요:\s*(예|아니오)" -Message "$($jsonFile.Name) matching txt is missing ending-record requirement metadata."
    Assert-TextContains -Text $text -Pattern "긍정 근거 사용 가능:\s*(예|아니오)" -Message "$($jsonFile.Name) matching txt is missing positive evidence readiness metadata."
    Assert-TextContains -Text $text -Pattern "선택 초점:\s*.+\($([regex]::Escape($qualityFocusArea))\)" -Message "$($jsonFile.Name) matching txt is missing the selected quality focus."
    Assert-TextContains -Text $text -Pattern "품질 영역:\s*.+" -Message "$($jsonFile.Name) matching txt is missing structured quality areas."
    Assert-TextContains -Text $text -Pattern "위험 태그:\s*.+" -Message "$($jsonFile.Name) matching txt is missing risk tags."
    Assert-TextContains -Text $text -Pattern "증거 등급:\s*$([regex]::Escape($evidenceTier))" -Message "$($jsonFile.Name) matching txt is missing the evidence tier."
    Assert-TextContains -Text $text -Pattern "추천 조치:\s*$([regex]::Escape($reviewActionRecommendation))" -Message "$($jsonFile.Name) matching txt is missing the review action recommendation."
    Assert-TextContains -Text $text -Pattern "상업 품질 근거:\s*$([regex]::Escape($commercialQualityEvidenceLine))" -Message "$($jsonFile.Name) matching txt is missing the commercial quality evidence line."
    Assert-TextContains -Text $text -Pattern "메모" -Message "$($jsonFile.Name) matching txt is missing memo section."
    Assert-TextContains -Text $text -Pattern "대화 로그" -Message "$($jsonFile.Name) matching txt is missing conversation log section."

    if ($text -match $ApiKeyPattern) {
        throw "$($jsonFile.Name) matching txt contains an API key pattern."
    }
    if ((Get-Content -LiteralPath $jsonFile.FullName -Raw) -match $ApiKeyPattern) {
        throw "$($jsonFile.Name) contains an API key pattern."
    }

    $validPairs++
    if ($validPairs -eq 1) {
        $latestTurns = $turns
        $latestSessionId = $sessionId
    }
}

if ($validPairs -lt 1) {
    throw "No valid playtest feedback export pairs were found."
}

Write-Host "Playtest feedback export validation passed: $validPairs pair(s), latest $latestSessionId, $latestTurns turn(s), build $expectedBuildId"
