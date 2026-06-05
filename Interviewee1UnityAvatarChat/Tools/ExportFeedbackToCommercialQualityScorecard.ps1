param(
    [string]$FeedbackRoot,
    [string]$OutputPath,
    [string]$SummaryPath,
    [switch]$RequireInput
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

$Areas = @(
    [pscustomobject]@{
        Area = "core_loop"
        Item = "5문답 세션 완결감"
        Always = $true
        Keywords = @()
    },
    [pscustomobject]@{
        Area = "writing"
        Item = "사람책 인터뷰 말투"
        Always = $false
        Keywords = @("말투", "AI", "사람", "설명문", "답변", "대화", "어조", "문장")
    },
    [pscustomobject]@{
        Area = "readability"
        Item = "긴 답변과 큰 글자 읽기"
        Always = $false
        Keywords = @("긴", "길", "스크롤", "읽", "글자", "잘림", "화면", "대사", "자막", "넘", "뚫")
    },
    [pscustomobject]@{
        Area = "controls"
        Item = "입력, 설정, 기록 저장과 삭제"
        Always = $false
        Keywords = @("입력", "버튼", "키보드", "마우스", "설정", "저장", "삭제", "기록", "조작")
    },
    [pscustomobject]@{
        Area = "trust_privacy"
        Item = "로컬 저장과 개인정보 안내 신뢰"
        Always = $false
        Keywords = @("API", "키", "마이크", "로컬", "로컬 저장", "삭제 안내", "개인정보", "신뢰", "서버")
    },
    [pscustomobject]@{
        Area = "art_presentation"
        Item = "캐릭터, 배경, 캡슐, 스크린샷 완성도"
        Always = $false
        Keywords = @("캐릭터", "사람", "배경", "보라", "색", "그래픽", "그림", "캡슐", "스크린샷", "밝")
    },
    [pscustomobject]@{
        Area = "trailer_store"
        Item = "트레일러와 상점 문구의 실제 플레이 전달"
        Always = $false
        Keywords = @("트레일러", "상점", "가격", "5달러", "유료", "구매", "소개")
    },
    [pscustomobject]@{
        Area = "stability_package"
        Item = "실행 패키지, fallback, 지원 번들 안정성"
        Always = $false
        Keywords = @("실행", "오류", "멈춤", "서버", "fallback", "지원", "번들", "패키지", "튕")
    }
)

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

    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Write-LinesWithRetry {
    param(
        [string]$Path,
        [object]$Lines
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        $tempPath = "$Path.tmp-$PID-$attempt"
        try {
            Set-Content -LiteralPath $tempPath -Value $Lines -Encoding UTF8 -ErrorAction Stop
            Move-Item -LiteralPath $tempPath -Destination $Path -Force -ErrorAction Stop
            return
        }
        catch {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            if ($attempt -eq 8) {
                throw
            }
            Start-Sleep -Milliseconds (120 * $attempt)
        }
    }
}

function Convert-ToInt {
    param(
        [object]$Value,
        [int]$Default = 0
    )

    $parsed = 0
    if ([int]::TryParse(([string]$Value).Trim(), [ref]$parsed)) {
        return $parsed
    }

    return $Default
}

function Convert-RatingToScore {
    param([string]$Rating)

    switch ($Rating) {
        "좋음" { return 4 }
        "보통" { return 3 }
        "헷갈림" { return 2 }
        default { return 0 }
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

function Get-RelativePathSafe {
    param(
        [string]$RootPath,
        [string]$Path
    )

    $rootFull = ([System.IO.Path]::GetFullPath($RootPath)) -replace '[\\/]+$', ''
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($rootFull.StartsWith("\\?\")) {
        $rootFull = $rootFull.Substring(4)
    }
    if ($pathFull.StartsWith("\\?\")) {
        $pathFull = $pathFull.Substring(4)
    }
    $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    if ($pathFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($prefix.Length)
    }

    return $pathFull
}

function Test-KeywordMatch {
    param(
        [string]$Text,
        [string[]]$Keywords
    )

    foreach ($keyword in $Keywords) {
        if ($Text.IndexOf($keyword, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Get-AreaScore {
    param(
        [object]$Record,
        [string]$Area
    )

    $score = [int]$Record.Score
    if ($Area -eq "core_loop" -and [int]$Record.Turns -lt 5) {
        $score = [Math]::Min($score, 2)
    }
    if ($Area -eq "core_loop" -and @($Record.RiskTags) -contains "ending-record-missing") {
        $score = [Math]::Min($score, 2)
    }
    if ($Area -eq "core_loop" -and [string]$Record.EvidenceTier -eq "ending-record-needed") {
        $score = [Math]::Min($score, 2)
    }
    if (@("controls", "stability_package") -contains $Area -and @($Record.RiskTags) -contains "ending-record-missing") {
        $score = [Math]::Min($score, 3)
    }

    return $score
}

function Get-FeedbackNoteText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $match = [regex]::Match($Text, "(?ms)^메모\s*$\s*(.*?)(\r?\n\r?\n오늘 열린 장면|\r?\n\r?\n대화 로그|$)")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return $Text.Trim()
}

function Get-FeedbackRecords {
    param([string]$RootPath)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $RootPath))) {
        return @()
    }

    $records = New-Object System.Collections.Generic.List[object]
    $jsonFiles = @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $RootPath) -Filter "*.json" -File -Recurse -ErrorAction Stop |
        Where-Object { $_.Name -notmatch '(^SESSION_MANIFEST|^BUILD_INFO|PACKAGE_PROVENANCE|template|sample|README)' })

    foreach ($jsonFile in $jsonFiles) {
        $jsonText = Get-Content -LiteralPath $jsonFile.FullName -Raw
        if ($jsonText -match $ApiKeyPattern) {
            throw "Feedback manifest contains an API key pattern: $($jsonFile.FullName)"
        }

        try {
            $manifest = $jsonText | ConvertFrom-Json
        }
        catch {
            continue
        }

        $sessionId = ([string]$manifest.sessionId).Trim()
        $rating = ([string]$manifest.rating).Trim()
        $commercialReadiness = ([string]$manifest.commercialReadiness).Trim()
        $issueSeverity = ([string]$manifest.issueSeverity).Trim()
        if ([string]::IsNullOrWhiteSpace($sessionId) -or [string]::IsNullOrWhiteSpace($rating)) {
            continue
        }
        if ([string]::IsNullOrWhiteSpace($commercialReadiness)) {
            $commercialReadiness = "미기록"
        }
        if ([string]::IsNullOrWhiteSpace($issueSeverity)) {
            $issueSeverity = "미기록"
        }

        $score = Convert-RatingToScore -Rating $rating
        if ($score -eq 0) {
            throw "Feedback manifest has unsupported rating '$rating': $($jsonFile.FullName)"
        }
        $qualityAreas = @($manifest.qualityAreas | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $qualityFocusArea = ([string]$manifest.qualityFocusArea).Trim()
        $riskTags = @($manifest.riskTags | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $evidenceTier = ([string]$manifest.evidenceTier).Trim()
        $sessionCompletionLine = ([string]$manifest.sessionCompletionLine).Trim()
        $dominantAttitude = ([string]$manifest.dominantAttitude).Trim()
        $deepMemoryCount = Convert-ToInt -Value $manifest.deepMemoryCount
        $openedSceneTags = @($manifest.openedSceneTags | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $endingRecordSaved = [bool]$manifest.endingRecordSavedThisSession
        $qualityEvidenceReady = [bool]$manifest.qualityEvidenceReady
        $positiveEvidenceRequiresEndingRecord = [bool]$manifest.positiveEvidenceRequiresEndingRecord
        $commercialQualityEvidenceLine = ([string]$manifest.commercialQualityEvidenceLine).Trim()
        if ($qualityEvidenceReady -and ([string]::IsNullOrWhiteSpace($commercialQualityEvidenceLine) -or $commercialQualityEvidenceLine -notmatch "점수표 후보")) {
            throw "Feedback manifest marks qualityEvidenceReady but lacks a scorecard candidate evidence line: $($jsonFile.FullName)"
        }

        $stem = [System.IO.Path]::GetFileNameWithoutExtension($jsonFile.Name)
        $jsonDirectory = Split-Path -Parent $jsonFile.FullName
        $txtPath = [System.IO.Path]::Combine($jsonDirectory, "$stem.txt")
        $txtText = ""
        if (Test-Path -LiteralPath $txtPath) {
            $txtText = Get-Content -LiteralPath $txtPath -Raw
            if ($txtText -match $ApiKeyPattern) {
                throw "Feedback text contains an API key pattern: $txtPath"
            }
        }

        $records.Add([pscustomobject]@{
            SessionId = $sessionId
            Rating = $rating
            CommercialReadiness = $commercialReadiness
            IssueSeverity = $issueSeverity
            QualityFocusArea = $qualityFocusArea
            QualityAreas = $qualityAreas
            RiskTags = $riskTags
            EvidenceTier = $evidenceTier
            SessionCompletionLine = $sessionCompletionLine
            DominantAttitude = $dominantAttitude
            DeepMemoryCount = $deepMemoryCount
            OpenedSceneTags = $openedSceneTags
            EndingRecordSaved = $endingRecordSaved
            QualityEvidenceReady = $qualityEvidenceReady
            PositiveEvidenceRequiresEndingRecord = $positiveEvidenceRequiresEndingRecord
            CommercialQualityEvidenceLine = $commercialQualityEvidenceLine
            Score = $score
            Turns = Convert-ToInt -Value $manifest.conversationTurns
            OpenedMemoryCount = Convert-ToInt -Value $manifest.openedMemoryCount
            MemoryThemeCount = Convert-ToInt -Value $manifest.memoryThemeCount
            BuildId = ([string]$manifest.buildId).Trim()
            JsonPath = $jsonFile.FullName
            TextPath = $txtPath
            RelativeJsonPath = Get-RelativePathSafe -RootPath $RootPath -Path $jsonFile.FullName
            RelativeTextPath = if (Test-Path -LiteralPath $txtPath) { Get-RelativePathSafe -RootPath $RootPath -Path $txtPath } else { "" }
            Text = "$rating`n$commercialReadiness`n$issueSeverity`n$jsonText`n$txtText"
            SearchText = Get-FeedbackNoteText -Text $txtText
        }) | Out-Null
    }

    return $records.ToArray()
}

function Test-FeedbackRootHasManifest {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return $false
    }

    $files = @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -Filter "*.json" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '(^SESSION_MANIFEST|^BUILD_INFO|PACKAGE_PROVENANCE|template|sample|README)' } |
        Select-Object -First 1)

    return $files.Count -gt 0
}

function Get-FeedbackInputKind {
    param([string]$Path)

    $normalized = ([string]$Path).Replace("\", "/")
    if ($normalized -match "Build/release-smoke/playtest-feedback-files") {
        return "internal-smoke-fallback"
    }
    if ($normalized -match "EvidenceDrop/Playtest|Build/ReleaseEvidence/Playtest") {
        return "external-playtest"
    }

    return "custom"
}

function New-DraftRow {
    param(
        [object]$Area,
        [object[]]$Records
    )

    $matchingRecords = @()
    if ($Area.Always) {
        $matchingRecords = @($Records)
    }
    else {
        $matchingRecords = @($Records | Where-Object {
            ((@($_.QualityAreas) -contains $Area.Area) -or (Test-KeywordMatch -Text ([string]$_.SearchText) -Keywords $Area.Keywords))
        })
    }

    if ($matchingRecords.Count -eq 0) {
        return [pscustomobject]@{
            area = $Area.Area
            item = $Area.Item
            score = ""
            blocker = "false"
            reviewer = ""
            evidence = ""
            notes = "피드백 export만으로 직접 판단할 증거가 부족함. 외부 리뷰에서 채워야 함."
            status = "증거 부족"
        }
    }

    $scores = @($matchingRecords | ForEach-Object { Get-AreaScore -Record $_ -Area $Area.Area })
    $averageScore = [Math]::Round((($scores | Measure-Object -Average).Average), 0)
    $score = [Math]::Max(1, [Math]::Min(5, [int]$averageScore))
    $good = @($matchingRecords | Where-Object { $_.Rating -eq "좋음" }).Count
    $normal = @($matchingRecords | Where-Object { $_.Rating -eq "보통" }).Count
    $confused = @($matchingRecords | Where-Object { $_.Rating -eq "헷갈림" }).Count
    $commercialEnough = @($matchingRecords | Where-Object { $_.CommercialReadiness -eq "충분" }).Count
    $commercialHold = @($matchingRecords | Where-Object { $_.CommercialReadiness -eq "보류" }).Count
    $commercialInsufficient = @($matchingRecords | Where-Object { $_.CommercialReadiness -eq "부족" }).Count
    $issueP0 = @($matchingRecords | Where-Object { $_.IssueSeverity -eq "P0" }).Count
    $issueP1 = @($matchingRecords | Where-Object { $_.IssueSeverity -eq "P1" }).Count
    $issueP2 = @($matchingRecords | Where-Object { $_.IssueSeverity -eq "P2" }).Count
    $issueNone = @($matchingRecords | Where-Object { $_.IssueSeverity -eq "없음" }).Count
    $shortSessions = @($matchingRecords | Where-Object { [int]$_.Turns -lt 5 }).Count
    $endingRecordMissing = @($matchingRecords | Where-Object { @($_.RiskTags) -contains "ending-record-missing" }).Count
    $endingRecordNeeded = @($matchingRecords | Where-Object { $_.PositiveEvidenceRequiresEndingRecord -or $_.EvidenceTier -eq "ending-record-needed" }).Count
    $qualityReady = @($matchingRecords | Where-Object { $_.QualityEvidenceReady }).Count
    $structuredAreaMatches = @($matchingRecords | Where-Object { @($_.QualityAreas) -contains $Area.Area }).Count
    $selectedFocusMatches = @($matchingRecords | Where-Object { $_.QualityFocusArea -eq $Area.Area }).Count
    $deepTotal = (($matchingRecords | Measure-Object -Property DeepMemoryCount -Sum).Sum)
    $completionSummary = @($matchingRecords | ForEach-Object { $_.SessionCompletionLine } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) $($_.Count)" })
    $attitudeSummary = @($matchingRecords | ForEach-Object { $_.DominantAttitude } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) $($_.Count)" })
    $sceneTagSummary = @($matchingRecords | ForEach-Object { @($_.OpenedSceneTags) } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { "$($_.Name) $($_.Count)" })
    $riskTagSummary = @($matchingRecords | ForEach-Object { @($_.RiskTags) } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { "$($_.Name) $($_.Count)" })
    $evidenceTierSummary = @($matchingRecords | ForEach-Object { $_.EvidenceTier } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Group-Object | Sort-Object Count -Descending | ForEach-Object { "$($_.Name) $($_.Count)" })
    $commercialEvidenceSummary = @($matchingRecords | ForEach-Object { $_.CommercialQualityEvidenceLine } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) $($_.Count)" })
    $evidence = (($matchingRecords | Select-Object -First 5 | ForEach-Object { $_.RelativeJsonPath }) -join "; ")
    $buildIds = @($matchingRecords | ForEach-Object { $_.BuildId } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $buildNote = if ($buildIds.Count -gt 0) { "빌드 $($buildIds -join ', ')." } else { "빌드 ID 없음." }
    $structuredNote = if ($structuredAreaMatches -gt 0) { "구조화 영역 매칭 ${structuredAreaMatches}개, 직접 선택 ${selectedFocusMatches}개." } else { "키워드 기반 매칭." }
    $completionNote = if ($completionSummary.Count -gt 0) { "세션 완성도: $($completionSummary -join ', ')." } else { "세션 완성도 없음." }
    $attitudeNote = if ($attitudeSummary.Count -gt 0) { "주된 태도: $($attitudeSummary -join ', ')." } else { "주된 태도 없음." }
    $sceneNote = if ($sceneTagSummary.Count -gt 0) { "장면 태그: $($sceneTagSummary -join ', '), 깊은 기록 합계 $deepTotal." } else { "장면 태그 없음, 깊은 기록 합계 $deepTotal." }
    $riskNote = if ($riskTagSummary.Count -gt 0) { "위험 태그: $($riskTagSummary -join ', ')." } else { "위험 태그 없음." }
    $tierNote = if ($evidenceTierSummary.Count -gt 0) { "증거 등급: $($evidenceTierSummary -join ', ')." } else { "증거 등급 없음." }
    $commercialEvidenceNote = if ($commercialEvidenceSummary.Count -gt 0) { "상업 품질 근거: $($commercialEvidenceSummary -join ' / ')." } else { "상업 품질 근거 없음." }
    $hasBlockerIssue = ($issueP0 + $issueP1) -gt 0
    $blockerValue = if ($hasBlockerIssue) { "true" } else { "false" }
    $notes = "피드백 $($matchingRecords.Count)개 기반 초안. $structuredNote $completionNote $attitudeNote $sceneNote 평점 분포: 좋음 $good, 보통 $normal, 헷갈림 $confused. 5달러 기준: 충분 $commercialEnough, 보류 $commercialHold, 부족 $commercialInsufficient. 이슈 등급: P0 $issueP0, P1 $issueP1, P2 $issueP2, 없음 $issueNone. 5문답 미만 $shortSessions, 마무리 기록 없음 $endingRecordMissing, 마무리 기록 필요 $endingRecordNeeded, 품질 근거 준비 $qualityReady. $commercialEvidenceNote $riskNote $tierNote $buildNote 검토자가 실제 점수로 확정해야 함."

    return [pscustomobject]@{
        area = $Area.Area
        item = $Area.Item
        score = [string]$score
        blocker = $blockerValue
        reviewer = "feedback-export-draft"
        evidence = $evidence
        notes = $notes
        status = "초안"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$evidenceDropRoot = Join-Path $projectRoot "EvidenceDrop"

if ([string]::IsNullOrWhiteSpace($FeedbackRoot)) {
    $candidates = @(
        (Join-Path $evidenceDropRoot "Playtest"),
        (Join-Path $buildRoot "ReleaseEvidence\Playtest"),
        (Join-Path $buildRoot "release-smoke\playtest-feedback-files")
    )
    $FeedbackRoot = ($candidates | Where-Object { Test-FeedbackRootHasManifest -Path $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($FeedbackRoot)) {
        $FeedbackRoot = Join-Path $buildRoot "ReleaseEvidence\Playtest"
    }
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $evidenceDropRoot)) {
        $OutputPath = Join-Path $evidenceDropRoot "COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv"
    }
    else {
        $OutputPath = Join-Path $buildRoot "ReleaseEvidence\COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv"
    }
}

if ([string]::IsNullOrWhiteSpace($SummaryPath)) {
    $SummaryPath = [System.IO.Path]::ChangeExtension($OutputPath, ".md")
}

$records = @(Get-FeedbackRecords -RootPath $FeedbackRoot)
if ($RequireInput -and $records.Count -eq 0) {
    throw "No playtest feedback records were found under $FeedbackRoot."
}
$feedbackInputKind = Get-FeedbackInputKind -Path $FeedbackRoot

$rows = @($Areas | ForEach-Object { New-DraftRow -Area $_ -Records $records })

$tsvLines = New-Object System.Collections.Generic.List[string]
$tsvLines.Add("area`titem`tscore`tblocker`treviewer`tevidence`tnotes")
foreach ($row in $rows) {
    $tsvLines.Add((
        (Format-TsvCell $row.area),
        (Format-TsvCell $row.item),
        (Format-TsvCell $row.score),
        (Format-TsvCell $row.blocker),
        (Format-TsvCell $row.reviewer),
        (Format-TsvCell $row.evidence),
        (Format-TsvCell $row.notes)
    ) -join "`t")
}

Write-LinesWithRetry -Path $OutputPath -Lines $tsvLines

$scoredRows = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.score) })
$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add("# 피드백 기반 상업 품질 점수표 초안")
$summaryLines.Add("")
$summaryLines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$summaryLines.Add("- 입력 루트: $FeedbackRoot")
$summaryLines.Add("- 입력 종류: $feedbackInputKind")
$summaryLines.Add("- 피드백 수: $($records.Count)")
$summaryLines.Add("- 점수 초안 행: $($scoredRows.Count)/$($Areas.Count)")
$summaryLines.Add("- 출력 점수표 초안: $OutputPath")
$summaryLines.Add("")
$summaryLines.Add("이 파일은 공식 출시 게이트를 통과시키는 점수표가 아니다. 리뷰어가 원본 피드백, 관찰 기록, 영상, 상점 자료를 보고 `COMMERCIAL_QUALITY_SCORECARD.tsv`를 직접 확정해야 한다.")
if ($feedbackInputKind -eq "internal-smoke-fallback") {
    $summaryLines.Add("")
    $summaryLines.Add("현재 초안은 외부 Playtest 증거가 비어 있어 내부 릴리즈 스모크 feedback export로 생성한 파이프라인 검증용 샘플이다. 공식 품질 판정에는 외부 참가자 증거를 사용해야 한다.")
}
$summaryLines.Add("")
$summaryLines.Add("| 영역 | 상태 | 초안 점수 | 증거 |")
$summaryLines.Add("| --- | --- | ---: | --- |")
foreach ($row in $rows) {
    $summaryLines.Add("| $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.status) | $(Escape-MarkdownCell $row.score) | $(Escape-MarkdownCell $row.evidence) |")
}

Write-LinesWithRetry -Path $SummaryPath -Lines $summaryLines

Write-Host "Commercial quality scorecard draft written: $OutputPath"
Write-Host "Draft summary written: $SummaryPath"
Write-Host "Feedback records: $($records.Count), scored draft rows: $($scoredRows.Count)/$($Areas.Count)"
