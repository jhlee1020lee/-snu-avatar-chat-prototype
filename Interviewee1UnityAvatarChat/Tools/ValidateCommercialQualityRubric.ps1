param(
    [string]$ScorecardPath,
    [string]$OutputPath,
    [string]$EvidenceRoot,
    [decimal]$MinimumAverageScore = 4.0,
    [int]$MinimumScore = 3,
    [switch]$Initialize,
    [switch]$RequireReady
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"
$RequiredAreas = @(
    "core_loop",
    "writing",
    "readability",
    "controls",
    "trust_privacy",
    "art_presentation",
    "trailer_store",
    "stability_package"
)
$ExternalEvidencePrefixesByArea = @{
    core_loop = @("EvidenceDrop/Playtest", "Build/ReleaseEvidence/Playtest")
    writing = @("EvidenceDrop/Playtest", "Build/ReleaseEvidence/Playtest")
    readability = @("EvidenceDrop/Accessibility", "Build/ReleaseEvidence/Accessibility", "EvidenceDrop/Playtest", "Build/ReleaseEvidence/Playtest")
    controls = @("EvidenceDrop/Accessibility", "Build/ReleaseEvidence/Accessibility", "EvidenceDrop/Playtest", "Build/ReleaseEvidence/Playtest")
    trust_privacy = @("EvidenceDrop/LegalSteam", "Build/ReleaseEvidence/LegalSteam")
    art_presentation = @("EvidenceDrop/ArtReview", "Build/ReleaseEvidence/ArtReview")
    trailer_store = @("EvidenceDrop/Trailer", "Build/ReleaseEvidence/Trailer")
}
$DisallowedEvidenceNamePattern = "(?i)(COMMERCIAL_QUALITY_EVIDENCE_INDEX|COMMERCIAL_QUALITY_SCORECARD_DRAFT|COMMERCIAL_QUALITY_REVIEW_QA|COMMERCIAL_QUALITY_SCORECARD_TEMPLATE|_TEMPLATE|TEMPLATE\.|DRAFT_REFERENCE|SOURCE_BRIEF|REVIEW_BRIEF|INVITE|ACCEPTANCE_CHECKLIST|RETURN_CHECKLIST|README|MANIFEST)"

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

function ConvertFrom-LongPath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith("\\?\UNC\")) {
        return "\\" + $full.Substring(8)
    }
    if ($full.StartsWith("\\?\")) {
        return $full.Substring(4)
    }
    return $full
}

function Ensure-Directory {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Write-LinesWithRetry {
    param(
        [string]$Path,
        [object]$Lines
    )

    $directory = Split-Path -Parent $Path
    Ensure-Directory -Path $directory

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

function Test-Truthy {
    param([string]$Value)

    return $Value -match '^(?i:true|yes|y|1|차단|blocker)$'
}

function Split-EvidenceReferences {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    return @($Text -split "[;`r`n]+" | ForEach-Object { ([string]$_).Trim().Trim('"') } | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })
}

function Resolve-EvidenceReference {
    param(
        [string]$Reference,
        [string]$EvidenceRootPath,
        [string]$ProjectRootPath
    )

    if ($Reference -match '^(?i:https?://|steam://)') {
        return [pscustomobject]@{
            Exists = $false
            Reason = "원격 URL은 로컬 증거로 인정하지 않음"
            Path = $Reference
        }
    }

    if ([System.IO.Path]::IsPathRooted($Reference)) {
        return [pscustomobject]@{
            Exists = $false
            Reason = "절대 경로는 패키지에서 재현할 수 없음"
            Path = ConvertFrom-LongPath -Path $Reference
        }
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($Reference -match '^(?i:EvidenceDrop)[\\/]') {
        $withoutRoot = $Reference.Substring("EvidenceDrop".Length).TrimStart("\", "/")
        $candidates.Add((Join-Path $EvidenceRootPath $withoutRoot)) | Out-Null
    }
    if ($Reference -match '^(?i:Build[\\/]ReleaseEvidence)[\\/]') {
        $candidates.Add((Join-Path $ProjectRootPath $Reference)) | Out-Null
    }
    $candidates.Add((Join-Path $EvidenceRootPath $Reference)) | Out-Null
    $candidates.Add((Join-Path $ProjectRootPath $Reference)) | Out-Null

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $candidate)) {
            return [pscustomobject]@{
                Exists = $true
                Reason = "확인됨"
                Path = ConvertFrom-LongPath -Path $candidate
            }
        }
    }

    return [pscustomobject]@{
        Exists = $false
        Reason = "파일 또는 폴더 없음"
        Path = $Reference
    }
}

function Normalize-EvidenceReference {
    param([string]$Reference)

    return ([string]$Reference).Trim().Trim('"').Replace("\", "/")
}

function Test-ExternalEvidenceReferenceForArea {
    param(
        [string]$Area,
        [string]$Reference
    )

    if (-not $ExternalEvidencePrefixesByArea.ContainsKey($Area)) {
        return $false
    }

    $normalized = Normalize-EvidenceReference -Reference $Reference
    foreach ($prefix in @($ExternalEvidencePrefixesByArea[$Area])) {
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Test-SubstantiveEvidencePath {
    param([string]$Path)

    $longPath = ConvertTo-LongPath -Path $Path
    if (-not (Test-Path -LiteralPath $longPath)) {
        return $false
    }

    $item = Get-Item -LiteralPath $longPath
    if (-not $item.PSIsContainer) {
        return $item.Length -gt 20 -and $item.Name -notmatch $DisallowedEvidenceNamePattern
    }

    $files = @(Get-ChildItem -LiteralPath $longPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.Length -gt 20 -and $_.Name -notmatch $DisallowedEvidenceNamePattern
    })

    return $files.Count -gt 0
}

function Test-EvidenceReferencePolicy {
    param(
        [string]$Reference,
        [object]$Resolved
    )

    $normalized = Normalize-EvidenceReference -Reference $Reference
    $name = [System.IO.Path]::GetFileName($normalized)
    if ($normalized -match $DisallowedEvidenceNamePattern -or $name -match $DisallowedEvidenceNamePattern) {
        return "보조자료/템플릿/초안은 공식 evidence로 인정하지 않음"
    }

    if (-not (Test-SubstantiveEvidencePath -Path $Resolved.Path)) {
        return "실제 관찰/리뷰/영상/캡처/최종 문서로 볼 수 있는 파일이 없음"
    }

    return ""
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
$defaultEvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $EvidenceRoot = Join-Path $projectRoot "EvidenceDrop"
    }
    else {
        $EvidenceRoot = $defaultEvidenceRoot
    }
}

if ([string]::IsNullOrWhiteSpace($ScorecardPath)) {
    $ScorecardPath = Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_SCORECARD.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $OutputPath = Join-Path $projectRoot "EvidenceDrop\COMMERCIAL_QUALITY_REVIEW_QA.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_REVIEW_QA.md"
    }
}

if ($Initialize) {
    Ensure-Directory -Path (Split-Path -Parent $ScorecardPath)
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $ScorecardPath))) {
        $template = Join-Path $docsRoot "COMMERCIAL_QUALITY_SCORECARD_TEMPLATE.tsv"
        if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $template)) {
            Copy-Item -LiteralPath (ConvertTo-LongPath -Path $template) -Destination $ScorecardPath -Force
        }
        else {
            $rows = New-Object System.Collections.Generic.List[string]
            $rows.Add("area`titem`tscore`tblocker`treviewer`tevidence`tnotes")
            foreach ($area in $RequiredAreas) {
                $rows.Add("$area`t`t`tfalse`t`t`t")
            }
            Set-Content -LiteralPath $ScorecardPath -Value $rows -Encoding UTF8
        }
    }
}

$rows = @()
$issues = New-Object System.Collections.Generic.List[string]
$status = "증거 없음"
$average = 0
$minimum = 0
$blockers = 0
$scoredRows = 0
$evidenceReferences = 0
$missingEvidenceReferences = 0
$secretMatches = @()

if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $ScorecardPath)) {
    $secretMatches = Select-String -LiteralPath $ScorecardPath -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $ScorecardPath)
    if ($rows.Count -gt 0) {
        $columns = @($rows[0].PSObject.Properties.Name)
        $requiredColumns = @("area", "item", "score", "blocker", "reviewer", "evidence", "notes")
        foreach ($column in $requiredColumns) {
            if ($columns -notcontains $column) {
                $issues.Add("필수 열 누락: $column") | Out-Null
            }
        }
    }

    if ($rows.Count -eq 0) {
        $issues.Add("점수표 행이 없다.") | Out-Null
    }
    else {
        $seenAreas = @{}
        $externalEvidenceAreas = @{}
        $scores = New-Object System.Collections.Generic.List[int]
        foreach ($row in $rows) {
            $area = ([string]$row.area).Trim()
            if (-not [string]::IsNullOrWhiteSpace($area)) {
                $seenAreas[$area] = $true
            }

            $scoreValue = 0
            if (-not [int]::TryParse(([string]$row.score).Trim(), [ref]$scoreValue)) {
                $issues.Add("점수 누락 또는 숫자 아님: $area / $($row.item)") | Out-Null
            }
            elseif ($scoreValue -lt 1 -or $scoreValue -gt 5) {
                $issues.Add("점수 범위 오류: $area / $($row.item) = $scoreValue") | Out-Null
            }
            else {
                $scores.Add($scoreValue) | Out-Null
                if ($scoreValue -lt $MinimumScore) {
                    $issues.Add("최저 점수 미달: $area / $($row.item) = $scoreValue") | Out-Null
                }
            }
            if ([string]::IsNullOrWhiteSpace([string]$row.reviewer)) {
                $issues.Add("reviewer 누락: $area / $($row.item)") | Out-Null
            }
            if ([string]::IsNullOrWhiteSpace([string]$row.evidence)) {
                $issues.Add("evidence 누락: $area / $($row.item)") | Out-Null
            }
            else {
                foreach ($reference in (Split-EvidenceReferences -Text ([string]$row.evidence))) {
                    $evidenceReferences++
                    $resolved = Resolve-EvidenceReference -Reference $reference -EvidenceRootPath $EvidenceRoot -ProjectRootPath $projectRoot
                    if (-not $resolved.Exists) {
                        $missingEvidenceReferences++
                        $issues.Add("evidence 경로 확인 실패: $area / $($row.item) = $reference ($($resolved.Reason))") | Out-Null
                    }
                    else {
                        $policyIssue = Test-EvidenceReferencePolicy -Reference $reference -Resolved $resolved
                        if (-not [string]::IsNullOrWhiteSpace($policyIssue)) {
                            $issues.Add("evidence 정책 위반: $area / $($row.item) = $reference ($policyIssue)") | Out-Null
                        }
                        if (Test-ExternalEvidenceReferenceForArea -Area $area -Reference $reference) {
                            $externalEvidenceAreas[$area] = $true
                        }
                    }
                }
            }
            if (Test-Truthy -Value ([string]$row.blocker)) {
                $blockers++
                $issues.Add("차단 항목 표시: $area / $($row.item)") | Out-Null
            }
        }

        foreach ($area in $RequiredAreas) {
            if (-not $seenAreas.ContainsKey($area)) {
                $issues.Add("필수 영역 누락: $area") | Out-Null
            }
        }
        foreach ($area in $ExternalEvidencePrefixesByArea.Keys) {
            if ($seenAreas.ContainsKey($area) -and -not $externalEvidenceAreas.ContainsKey($area)) {
                $issues.Add("외부 증거 경로 누락: $area 영역은 $($ExternalEvidencePrefixesByArea[$area] -join ' 또는 ') 증거를 최소 1개 포함해야 함") | Out-Null
            }
        }

        $scoredRows = $scores.Count
        if ($scores.Count -gt 0) {
            $average = [Math]::Round((($scores | Measure-Object -Average).Average), 2)
            $minimum = ($scores | Measure-Object -Minimum).Minimum
            if ($average -lt $MinimumAverageScore) {
                $issues.Add("평균 점수 미달: $average / 필요 $MinimumAverageScore") | Out-Null
            }
        }
        else {
            $issues.Add("유효 점수 행이 없다.") | Out-Null
        }
    }

    if ($secretMatches) {
        $issues.Add("API 키 형태 문자열 발견") | Out-Null
    }

    if ($issues.Count -eq 0) {
        $status = "완료"
    }
    elseif ($scoredRows -eq 0 -and -not $secretMatches) {
        $status = "미완료"
    }
    else {
        $status = "보류"
    }
}
else {
    $issues.Add("점수표 파일 없음: ValidateCommercialQualityRubric.ps1 -Initialize로 템플릿을 만들고 reviewer, score, evidence를 채운다.") | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상업 품질 루브릭 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 점수표: $ScorecardPath")
$lines.Add("- 상태: $status")
$lines.Add("- 점수 행: $scoredRows")
$lines.Add("- 평균 점수: $average")
$lines.Add("- 최저 점수: $minimum")
$lines.Add("- 차단 항목: $blockers")
$lines.Add("- 증거 경로: $evidenceReferences")
$lines.Add("- 누락 증거 경로: $missingEvidenceReferences")
$lines.Add("- 문제: $($issues.Count)")
$lines.Add("- 비밀키 패턴: $($secretMatches.Count)")
$lines.Add("")
$lines.Add("## 판정 기준")
$lines.Add("")
$lines.Add("- 평균 점수는 $MinimumAverageScore 이상이어야 한다.")
$lines.Add("- 모든 점수는 $MinimumScore 이상이어야 한다.")
$lines.Add("- 필수 영역, reviewer, evidence, blocker 기준을 모두 만족해야 한다.")
$lines.Add("- evidence 값은 EvidenceDrop 또는 ReleaseEvidence 기준 상대 경로여야 하며 실제 파일이나 폴더가 있어야 한다.")
$lines.Add("- `COMMERCIAL_QUALITY_EVIDENCE_INDEX`, 점수표 초안, 템플릿, 브리프, README, 체크리스트, 초대장, 매니페스트는 공식 evidence로 인정하지 않는다.")
$lines.Add("- stability_package를 제외한 영역은 담당 외부 증거 폴더를 최소 1개 이상 참조해야 한다.")
$lines.Add("")
$lines.Add("## 문제")
$lines.Add("")
if ($issues.Count -eq 0) {
    $lines.Add("- 없음")
}
else {
    foreach ($issue in $issues) {
        $lines.Add("- $issue")
    }
}

$lines.Add("")
$lines.Add("## 점수표")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 점수 | 차단 | 리뷰어 | 증거 | 메모 |")
$lines.Add("| --- | --- | ---: | --- | --- | --- | --- |")
if ($rows.Count -eq 0) {
    $lines.Add("| 없음 | 점수표 없음 | 0 |  |  |  |  |")
}
else {
    foreach ($row in $rows) {
        $lines.Add("| $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.item) | $(Escape-MarkdownCell $row.score) | $(Escape-MarkdownCell $row.blocker) | $(Escape-MarkdownCell $row.reviewer) | $(Escape-MarkdownCell $row.evidence) | $(Escape-MarkdownCell $row.notes) |")
    }
}

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Commercial quality rubric QA written: $OutputPath"
Write-Host "Status: $status, average: $average, minimum: $minimum, blockers: $blockers, issues: $($issues.Count)"

if ($secretMatches) {
    throw "Commercial quality scorecard contains API key pattern(s)."
}
if ($RequireReady -and $status -ne "완료") {
    throw "Commercial quality rubric is not ready: $status"
}
