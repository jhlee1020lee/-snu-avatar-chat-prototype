param(
    [string]$DocsPath,
    [string]$EvidenceRoot,
    [string]$BriefRoot,
    [string]$OutputPath
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

function Add-Result {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Evidence,
        [string]$NextAction = ""
    )

    $script:results.Add([pscustomobject]@{
        Item = $Item
        Status = $Status
        Evidence = $Evidence
        NextAction = $NextAction
    }) | Out-Null
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-Text {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return ""
    }

    return Get-Content -LiteralPath (ConvertTo-LongPath -Path $Path) -Raw -Encoding UTF8
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    $DocsPath = Join-Path $docsRoot "EXTERNAL_REVIEW_BRIEFS.md"
}
if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($BriefRoot)) {
    $BriefRoot = Join-Path $EvidenceRoot "ReviewBriefs"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_BRIEFS_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]

$requiredBriefFiles = @(
    "PLAYTEST_REVIEW_BRIEF.md",
    "ACCESSIBILITY_REVIEW_BRIEF.md",
    "ART_REVIEW_BRIEF.md",
    "TRAILER_REVIEW_BRIEF.md",
    "LEGAL_STEAM_REVIEW_BRIEF.md",
    "QUALITY_SCORECARD_REVIEW_BRIEF.md"
)
$requiredFiles = $requiredBriefFiles + @("REVIEW_INVITATION_TEMPLATES.md", "REVIEW_DECISION_CALIBRATION.tsv")

if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $DocsPath)) {
    $docsText = Get-Text -Path $DocsPath
    $missingPhrases = @()
    foreach ($phrase in @("외부 리뷰 브리프", "역할별 브리프", "검증 명령", "비밀키")) {
        if ($docsText -notmatch [regex]::Escape($phrase)) {
            $missingPhrases += $phrase
        }
    }
    if ($missingPhrases.Count -eq 0) {
        Add-Result -Item "요약 문서" -Status "완료" -Evidence $DocsPath
    }
    else {
        Add-Result -Item "요약 문서" -Status "차단" -Evidence "누락 문구: $($missingPhrases -join ', ')" -NextAction "WriteExternalReviewBriefs.ps1를 다시 실행한다."
    }
}
else {
    Add-Result -Item "요약 문서" -Status "차단" -Evidence "문서 없음: $DocsPath" -NextAction "WriteExternalReviewBriefs.ps1를 실행한다."
}

$missing = New-Object System.Collections.Generic.List[string]
$badContent = New-Object System.Collections.Generic.List[string]
$allBriefPaths = New-Object System.Collections.Generic.List[string]
foreach ($name in $requiredBriefFiles) {
    $path = Join-Path $BriefRoot $name
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
        $missing.Add($name) | Out-Null
        continue
    }

    $allBriefPaths.Add($path) | Out-Null
    $text = Get-Text -Path $path
    foreach ($phrase in @("제출 위치", "중단 기준", "검증 명령", "금지 자료")) {
        if ($text -notmatch [regex]::Escape($phrase)) {
            $badContent.Add("$name missing $phrase") | Out-Null
        }
    }
}

$invitePath = Join-Path $BriefRoot "REVIEW_INVITATION_TEMPLATES.md"
if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $invitePath))) {
    $missing.Add("REVIEW_INVITATION_TEMPLATES.md") | Out-Null
}
else {
    $allBriefPaths.Add($invitePath) | Out-Null
    $inviteText = Get-Text -Path $invitePath
    foreach ($phrase in @("외부 리뷰 초대 문구 모음", "겉!=속", "비밀키")) {
        if ($inviteText -notmatch [regex]::Escape($phrase)) {
            $badContent.Add("REVIEW_INVITATION_TEMPLATES.md missing $phrase") | Out-Null
        }
    }
}

$calibrationPath = Join-Path $BriefRoot "REVIEW_DECISION_CALIBRATION.tsv"
if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $calibrationPath))) {
    $missing.Add("REVIEW_DECISION_CALIBRATION.tsv") | Out-Null
}
else {
    $allBriefPaths.Add($calibrationPath) | Out-Null
    $calibrationRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $calibrationPath) -Encoding UTF8)
    $requiredAreas = @("core_loop", "writing", "readability", "controls", "trust_privacy", "art_presentation", "trailer_store", "stability_package")
    foreach ($area in $requiredAreas) {
        if (-not ($calibrationRows | Where-Object { $_.area -eq $area })) {
            $badContent.Add("REVIEW_DECISION_CALIBRATION.tsv missing $area") | Out-Null
        }
    }
    $calibrationText = Get-Text -Path $calibrationPath
    foreach ($phrase in @("price_ready_4_or_5", "borderline_3", "blocker_or_2_or_less", "required_evidence")) {
        if ($calibrationText -notmatch [regex]::Escape($phrase)) {
            $badContent.Add("REVIEW_DECISION_CALIBRATION.tsv missing $phrase") | Out-Null
        }
    }
}

if ($missing.Count -eq 0 -and $badContent.Count -eq 0) {
    Add-Result -Item "역할별 브리프 파일" -Status "완료" -Evidence "$($requiredFiles.Count)개 파일 확인"
}
elseif ($missing.Count -gt 0) {
    Add-Result -Item "역할별 브리프 파일" -Status "차단" -Evidence "누락: $($missing -join ', ')" -NextAction "WriteExternalReviewBriefs.ps1를 다시 실행한다."
}
else {
    Add-Result -Item "역할별 브리프 파일" -Status "차단" -Evidence ($badContent -join "; ") -NextAction "누락된 섹션을 복구한다."
}

$allTextPaths = @($DocsPath) + $allBriefPaths.ToArray()
$secretMatches = @()
foreach ($path in $allTextPaths) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path)) {
        $secretMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue)
    }
}
if ($secretMatches.Count -eq 0) {
    Add-Result -Item "비밀키 형태 문자열" -Status "완료" -Evidence "발견 0"
}
else {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { $_.Path }) -join ", "
    Add-Result -Item "비밀키 형태 문자열" -Status "차단" -Evidence $sample -NextAction "브리프에서 비밀키 형태 문자열을 제거한다."
}

$emphasisMatches = @()
foreach ($path in $allTextPaths) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path)) {
        $emphasisMatches += @(Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern "\*\*" -ErrorAction SilentlyContinue)
    }
}
if ($emphasisMatches.Count -eq 0) {
    Add-Result -Item "별표 강조 제거" -Status "완료" -Evidence "markdown 강조 없음"
}
else {
    $sample = ($emphasisMatches | Select-Object -First 4 | ForEach-Object { $_.Path }) -join ", "
    Add-Result -Item "별표 강조 제거" -Status "차단" -Evidence $sample -NextAction "브리프 문서에서 별표 강조를 제거한다."
}

$completed = @($results | Where-Object { $_.Status -eq "완료" }).Count
$blocked = @($results | Where-Object { $_.Status -eq "차단" }).Count
$status = if ($blocked -gt 0) { "차단" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰 브리프 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $completed")
$lines.Add("- 차단: $blocked")
$lines.Add("- 요약 문서: $DocsPath")
$lines.Add("- 브리프 폴더: $BriefRoot")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 다음 조치 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.NextAction) |")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "External review briefs QA written: $OutputPath"
Write-Host "Status: $status, completed: $completed, blocked: $blocked"

if ($blocked -gt 0) {
    throw "External review briefs QA has $blocked blocked item(s)."
}


