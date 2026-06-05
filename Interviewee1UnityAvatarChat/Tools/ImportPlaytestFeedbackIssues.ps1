param(
    [string]$FeedbackRoot,
    [string]$IssueRegisterPath,
    [string]$OutputPath,
    [string]$IssueIdPrefix = "EXT-FB",
    [switch]$UpdateExisting
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

$requiredColumns = @(
    "issue_id",
    "status",
    "priority",
    "area",
    "source",
    "session_id",
    "build_id",
    "title",
    "repro_steps",
    "expected",
    "actual",
    "fix_summary",
    "verified_by",
    "verified_at",
    "evidence_path"
)

function Write-LinesWithRetry {
    param(
        [string]$Path,
        [object]$Lines
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

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

function Normalize-Field {
    param([string]$Value)

    $text = [string]$Value
    if ($text -match $ApiKeyPattern) {
        throw "Imported feedback contains an API key pattern."
    }

    return $text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Get-RelativePathSafe {
    param(
        [string]$RootPath,
        [string]$Path
    )

    $rootFull = ([System.IO.Path]::GetFullPath($RootPath)) -replace '[\\/]+$', ''
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    if ($pathFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($prefix.Length)
    }

    return $pathFull
}

function Get-NoteText {
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

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxLength = 240
    )

    $value = Normalize-Field -Value $Text
    if ($value.Length -le $MaxLength) {
        return $value
    }

    return $value.Substring(0, $MaxLength - 3) + "..."
}

function Join-Tags {
    param([object[]]$Values)

    $tags = @($Values | ForEach-Object { Normalize-Field -Value ([string]$_) } | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })

    if ($tags.Count -eq 0) {
        return "none"
    }

    return ($tags -join ", ")
}

function Test-FeedbackRootHasManifest {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $files = @(Get-ChildItem -LiteralPath $Path -Filter "*.json" -File -Recurse -ErrorAction SilentlyContinue |
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

function Get-PrimaryIssueArea {
    param(
        [string]$QualityFocusArea,
        [object[]]$QualityAreas
    )

    $focus = Normalize-Field -Value $QualityFocusArea
    if (-not [string]::IsNullOrWhiteSpace($focus) -and $focus -ne "auto") {
        return $focus
    }

    foreach ($area in @($QualityAreas)) {
        $value = Normalize-Field -Value ([string]$area)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return "external_playtest"
}

function Merge-ImportedIssueRow {
    param(
        [object]$Existing,
        [object]$Incoming
    )

    if ($null -eq $Existing) {
        return $Incoming
    }

    $status = Normalize-Field -Value ([string]$Existing.status)
    if ([string]::IsNullOrWhiteSpace($status) -or @("open", "in_progress") -contains $status) {
        return $Incoming
    }

    foreach ($field in @("status", "fix_summary", "verified_by", "verified_at")) {
        $ExistingValue = Normalize-Field -Value ([string]$Existing.$field)
        if (-not [string]::IsNullOrWhiteSpace($ExistingValue)) {
            $Incoming.PSObject.Properties[$field].Value = $ExistingValue
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$Existing.evidence_path)) {
        $incomingEvidence = Normalize-Field -Value ([string]$Incoming.evidence_path)
        $existingEvidence = Normalize-Field -Value ([string]$Existing.evidence_path)
        if (-not $incomingEvidence.Contains($existingEvidence)) {
            $Incoming.PSObject.Properties["evidence_path"].Value = "$incomingEvidence; $existingEvidence"
        }
    }

    return $Incoming
}

function Assert-RegisterHeader {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-LinesWithRetry -Path $Path -Lines @($requiredColumns -join "`t")
        return
    }

    $firstLine = Get-Content -LiteralPath $Path -TotalCount 1
    $headers = @($firstLine -split "`t")
    foreach ($column in $requiredColumns) {
        if ($headers -notcontains $column) {
            throw "Issue register is missing required column: $column"
        }
    }
}

function Convert-RowToLine {
    param([object]$Row)

    $values = foreach ($column in $requiredColumns) {
        Normalize-Field -Value ([string]$Row.$column)
    }

    return $values -join "`t"
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
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
if ([string]::IsNullOrWhiteSpace($IssueRegisterPath)) {
    if (Test-Path -LiteralPath $evidenceDropRoot) {
        $IssueRegisterPath = Join-Path $evidenceDropRoot "EXTERNAL_ISSUE_REGISTER.tsv"
    }
    else {
        $IssueRegisterPath = Join-Path $buildRoot "ReleaseEvidence\EXTERNAL_ISSUE_REGISTER.tsv"
    }
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath $evidenceDropRoot) {
        $OutputPath = Join-Path $evidenceDropRoot "PLAYTEST_FEEDBACK_ISSUE_IMPORT.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "PLAYTEST_FEEDBACK_ISSUE_IMPORT.md"
    }
}

Assert-RegisterHeader -Path $IssueRegisterPath
$feedbackInputKind = Get-FeedbackInputKind -Path $FeedbackRoot

$existingRows = @(Import-Csv -Delimiter "`t" -LiteralPath $IssueRegisterPath)
$nextRows = New-Object System.Collections.Generic.List[object]
foreach ($row in $existingRows) {
    $nextRows.Add($row) | Out-Null
}

$jsonFiles = @()
if (Test-Path -LiteralPath $FeedbackRoot) {
    $jsonFiles = @(Get-ChildItem -LiteralPath $FeedbackRoot -Filter "*.json" -File -Recurse |
        Where-Object { $_.Name -notmatch '(^SESSION_MANIFEST|^BUILD_INFO|PACKAGE_PROVENANCE|template|sample|README)' })
}

$imported = 0
$skipped = 0
$updated = 0
$issueRows = New-Object System.Collections.Generic.List[object]

foreach ($jsonFile in $jsonFiles) {
    $jsonText = Get-Content -LiteralPath $jsonFile.FullName -Raw
    if ($jsonText -match $ApiKeyPattern) {
        throw "Feedback manifest contains an API key pattern: $($jsonFile.FullName)"
    }

    try {
        $manifest = $jsonText | ConvertFrom-Json
    }
    catch {
        $skipped++
        continue
    }

    $severity = ([string]$manifest.issueSeverity).Trim().ToUpperInvariant()
    if ($severity -notin @("P0", "P1", "P2")) {
        $skipped++
        continue
    }

    $sessionId = Normalize-Field -Value ([string]$manifest.sessionId)
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        $sessionId = [System.IO.Path]::GetFileNameWithoutExtension($jsonFile.Name)
    }

    $stem = [System.IO.Path]::GetFileNameWithoutExtension($jsonFile.Name)
    $txtPath = [System.IO.Path]::Combine((Split-Path -Parent $jsonFile.FullName), "$stem.txt")
    $note = ""
    if (Test-Path -LiteralPath $txtPath) {
        $txtText = Get-Content -LiteralPath $txtPath -Raw
        if ($txtText -match $ApiKeyPattern) {
            throw "Feedback text contains an API key pattern: $txtPath"
        }
        $note = Get-NoteText -Text $txtText
    }

    $issueId = Normalize-Field -Value ("$IssueIdPrefix-$sessionId-$severity")
    $buildId = Normalize-Field -Value ([string]$manifest.buildId)
    $qualityFocusArea = Normalize-Field -Value ([string]$manifest.qualityFocusArea)
    $qualityAreas = @($manifest.qualityAreas | ForEach-Object { Normalize-Field -Value ([string]$_) } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $riskTags = @($manifest.riskTags | ForEach-Object { Normalize-Field -Value ([string]$_) } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $evidenceTier = Normalize-Field -Value ([string]$manifest.evidenceTier)
    $reviewActionRecommendation = Normalize-Field -Value ([string]$manifest.reviewActionRecommendation)
    $commercialQualityEvidenceLine = Normalize-Field -Value ([string]$manifest.commercialQualityEvidenceLine)
    $issueArea = Get-PrimaryIssueArea -QualityFocusArea $qualityFocusArea -QualityAreas $qualityAreas
    $relativeJson = Get-RelativePathSafe -RootPath $FeedbackRoot -Path $jsonFile.FullName
    $relativeText = if (Test-Path -LiteralPath $txtPath) { Get-RelativePathSafe -RootPath $FeedbackRoot -Path $txtPath } else { "" }
    $evidencePath = if ([string]::IsNullOrWhiteSpace($relativeText)) { $relativeJson } else { "$relativeJson; $relativeText" }
    $feedbackSummary = if ([string]::IsNullOrWhiteSpace($note)) {
        "참가자가 게임 내 피드백에서 $severity 이슈 등급을 선택했지만 자유 메모는 비어 있음."
    }
    else {
        "참가자가 게임 내 피드백에서 $severity 이슈 등급을 선택함. 메모: $(Limit-Text -Text $note)"
    }
    $reviewLine = if ([string]::IsNullOrWhiteSpace($reviewActionRecommendation)) { "추천 조치 없음" } else { "추천 조치: $(Limit-Text -Text $reviewActionRecommendation -MaxLength 180)" }
    $commercialLine = if ([string]::IsNullOrWhiteSpace($commercialQualityEvidenceLine)) { "상업 품질 근거 없음" } else { "상업 품질 근거: $(Limit-Text -Text $commercialQualityEvidenceLine -MaxLength 180)" }
    $qualityLine = "품질 초점: $qualityFocusArea, 품질 영역: $(Join-Tags -Values $qualityAreas), 위험 태그: $(Join-Tags -Values $riskTags), 증거 등급: $evidenceTier"
    $actual = "$feedbackSummary $qualityLine. $reviewLine. $commercialLine."

    $newRow = [pscustomobject]@{
        issue_id = $issueId
        status = "open"
        priority = $severity
        area = $issueArea
        source = "playtest-feedback-export"
        session_id = $sessionId
        build_id = $buildId
        title = "$severity / $issueArea / 참가자 표시 이슈"
        repro_steps = "세션 $sessionId 피드백 txt/json과 관찰 기록을 확인한다."
        expected = "5문답 세션에서 $severity 등급에 해당하는 문제 없이 $issueArea 영역을 완료한다."
        actual = $actual
        fix_summary = ""
        verified_by = ""
        verified_at = ""
        evidence_path = $evidencePath
    }

    $existingIndex = -1
    for ($i = 0; $i -lt $nextRows.Count; $i++) {
        if (([string]$nextRows[$i].issue_id).Trim() -eq $issueId) {
            $existingIndex = $i
            break
        }
    }

    if ($existingIndex -ge 0) {
        if ($UpdateExisting) {
            $nextRows[$existingIndex] = Merge-ImportedIssueRow -Existing $nextRows[$existingIndex] -Incoming $newRow
            $updated++
        }
        else {
            $skipped++
            continue
        }
    }
    else {
        $nextRows.Add($newRow) | Out-Null
        $imported++
    }

    $issueRows.Add($newRow) | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add($requiredColumns -join "`t")
foreach ($row in $nextRows) {
    $lines.Add((Convert-RowToLine -Row $row))
}
Write-LinesWithRetry -Path $IssueRegisterPath -Lines $lines

$reportLines = New-Object System.Collections.Generic.List[string]
$reportLines.Add("# 플레이테스트 피드백 이슈 import")
$reportLines.Add("")
$reportLines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$reportLines.Add("- 피드백 루트: $FeedbackRoot")
$reportLines.Add("- 입력 종류: $feedbackInputKind")
$reportLines.Add("- 이슈 레지스터: $IssueRegisterPath")
$reportLines.Add("- 처리 manifest: $($jsonFiles.Count)")
$reportLines.Add("- 신규 등록: $imported")
$reportLines.Add("- 갱신: $updated")
$reportLines.Add("- 건너뜀: $skipped")
$reportLines.Add("")
$reportLines.Add("| ID | 등급 | 영역 | 세션 | Build ID | 근거 |")
$reportLines.Add("| --- | --- | --- | --- | --- | --- |")
if ($issueRows.Count -eq 0) {
    $reportLines.Add("| 없음 |  |  |  |  | P0/P1/P2 피드백 없음 |")
}
else {
    foreach ($row in $issueRows) {
        $reportLines.Add("| $($row.issue_id) | $($row.priority) | $($row.area) | $($row.session_id) | $($row.build_id) | $($row.evidence_path) |")
    }
}

Write-LinesWithRetry -Path $OutputPath -Lines $reportLines

Write-Host "Playtest feedback issue import written: $OutputPath"
Write-Host "Imported: $imported, updated: $updated, skipped: $skipped"
