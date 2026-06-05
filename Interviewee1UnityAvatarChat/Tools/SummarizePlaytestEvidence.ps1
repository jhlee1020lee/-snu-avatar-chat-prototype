param(
    [string]$EvidenceRoot,
    [string]$OutputPath,
    [int]$MinimumSessions = 5,
    [switch]$RequireNoBlockers,
    [switch]$RequireComplete
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

function Get-FilesSafe {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }

    @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -File -Recurse -ErrorAction Stop |
        Where-Object { $_.Name -notmatch '(^README|README|template|reference|sample|blank|양식|예시)' })
}

function Get-DirectoriesSafe {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }

    @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -Directory -ErrorAction Stop |
        Where-Object { $_.Name -notmatch '^\.' })
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

function Get-TextFileContent {
    param([object[]]$Files)

    $texts = New-Object System.Collections.Generic.List[string]
    foreach ($file in $Files) {
        if ($file.Extension -notmatch '^\.(txt|md|json|csv|tsv)$') {
            continue
        }
        try {
            $texts.Add((Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop)) | Out-Null
        }
        catch {
        }
    }

    return ($texts -join "`n")
}

function Get-FirstBuildId {
    param([string]$Text)

    $patterns = @(
        'Build ID:\s*([A-Za-z0-9_.-]+)',
        '"buildId"\s*:\s*"([^"]+)"',
        '빌드 ID:\s*([A-Za-z0-9_.-]+)'
    )
    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Text, $pattern)
        if ($match.Success) {
            return $match.Groups[1].Value
        }
    }

    return ""
}

function Count-IssueGrade {
    param(
        [string]$Text,
        [string]$Grade
    )

    $pattern = "(?im)(^|\||\s)$Grade(\s|/|\||:|-)"
    return ([regex]::Matches($Text, $pattern)).Count
}

function Get-SessionStatus {
    param(
        [object[]]$Files,
        [string]$Text
    )

    $hasObservation = [bool]($Files | Where-Object { $_.Name -match 'PLAYTEST_OBSERVATION_FORM|observation|관찰' } | Select-Object -First 1)
    $hasFeedback = [bool]($Files | Where-Object { $_.Name -match 'feedback|피드백|participant|플레이테스트' } | Select-Object -First 1)
    $hasFeedbackJson = [bool]($Files | Where-Object { $_.Name -match 'feedback.*\.json$|\.json$' } | Select-Object -First 1)
    $hasSupport = [bool](
        ($Files | Where-Object { $_.Name -match 'support_info\.json|BUILD_INFO\.txt|SupportBundle|support-bundle' } | Select-Object -First 1) -or
        ($Text -match 'support_info\.json|BUILD_INFO|지원 번들|SupportBundle')
    )

    if ($hasObservation -and $hasFeedback -and $hasFeedbackJson -and $hasSupport) {
        return "완성"
    }

    return "불완전"
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
$evidenceDropRoot = Join-Path $projectRoot "EvidenceDrop"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $evidenceDropRoot)) {
        $EvidenceRoot = Join-Path $evidenceDropRoot "Playtest"
    }
    else {
        $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence\Playtest"
    }
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $evidenceDropRoot)) {
        $OutputPath = Join-Path $evidenceDropRoot "PLAYTEST_EVIDENCE_SUMMARY.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "PLAYTEST_EVIDENCE_SUMMARY.md"
    }
}

$sessions = Get-DirectoriesSafe -Path $EvidenceRoot
$sessionRows = New-Object System.Collections.Generic.List[object]
$totalP0 = 0
$totalP1 = 0
$totalP2 = 0
$totalP3 = 0
$completeSessions = 0
$secretMatches = @()

foreach ($session in $sessions) {
    $files = Get-FilesSafe -Path $session.FullName
    $text = Get-TextFileContent -Files $files
    $status = Get-SessionStatus -Files $files -Text $text
    $p0 = Count-IssueGrade -Text $text -Grade "P0"
    $p1 = Count-IssueGrade -Text $text -Grade "P1"
    $p2 = Count-IssueGrade -Text $text -Grade "P2"
    $p3 = Count-IssueGrade -Text $text -Grade "P3"
    $buildId = Get-FirstBuildId -Text $text

    if ($status -eq "완성") {
        $completeSessions++
    }

    $totalP0 += $p0
    $totalP1 += $p1
    $totalP2 += $p2
    $totalP3 += $p3

    $sessionSecrets = $files |
        Where-Object { Test-TextLikeFile -File $_ } |
        Select-String -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
    if ($sessionSecrets) {
        $secretMatches += $sessionSecrets
    }

    $sessionRows.Add([pscustomobject]@{
        Session = $session.Name
        Status = $status
        Files = $files.Count
        BuildId = $buildId
        P0 = $p0
        P1 = $p1
        P2 = $p2
        P3 = $p3
    }) | Out-Null
}

$blockers = $totalP0 + $totalP1
$completeEnough = $completeSessions -ge $MinimumSessions
$summaryStatus = if ($secretMatches) {
    "실패"
}
elseif ($blockers -gt 0) {
    "차단 이슈 있음"
}
elseif ($completeEnough) {
    "완료"
}
else {
    "증거 부족"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 플레이테스트 증거 요약")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 증거 루트: $EvidenceRoot")
$lines.Add("- 상태: $summaryStatus")
$lines.Add("- 세션: $($sessions.Count)")
$lines.Add("- 완성 세션: $completeSessions/$MinimumSessions")
$lines.Add("- P0: $totalP0")
$lines.Add("- P1: $totalP1")
$lines.Add("- P2: $totalP2")
$lines.Add("- P3: $totalP3")
$lines.Add("- 비밀키 패턴: $($secretMatches.Count)")
$lines.Add("")
$lines.Add("이 요약은 외부 플레이테스트 증거 폴더의 관찰 기록, 피드백 export, 지원 번들을 읽어 출시 차단 이슈를 빠르게 확인하기 위한 문서다.")
$lines.Add("")
$lines.Add("| 세션 | 상태 | 파일 수 | Build ID | P0 | P1 | P2 | P3 |")
$lines.Add("| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |")
if ($sessionRows.Count -eq 0) {
    $lines.Add("| 없음 | 증거 부족 | 0 |  | 0 | 0 | 0 | 0 |")
}
else {
    foreach ($row in $sessionRows) {
        $lines.Add("| $(Escape-MarkdownCell $row.Session) | $(Escape-MarkdownCell $row.Status) | $($row.Files) | $(Escape-MarkdownCell $row.BuildId) | $($row.P0) | $($row.P1) | $($row.P2) | $($row.P3) |")
    }
}
$lines.Add("")
$lines.Add("## 판정")
$lines.Add("")
if ($secretMatches) {
    $lines.Add("- 비밀키 형태 문자열이 발견되어 P0로 본다.")
}
elseif ($blockers -gt 0) {
    $lines.Add("- P0/P1 차단 이슈가 있어 5달러 이상 유료 판매 후보로 볼 수 없다.")
}
elseif (-not $completeEnough) {
    $lines.Add("- 완성 세션이 ${MinimumSessions}개 미만이라 외부 플레이테스트 완료로 볼 수 없다.")
}
else {
    $lines.Add("- 완성 세션 수와 P0/P1 기준은 통과했다. 실제 수정 반영 여부는 릴리즈 회의에서 확인한다.")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Playtest evidence summary written: $OutputPath"
Write-Host "Complete sessions: $completeSessions/$MinimumSessions, blockers: $blockers, secrets: $($secretMatches.Count)"

if ($secretMatches) {
    throw "Playtest evidence contains API key pattern(s)."
}
if ($RequireNoBlockers -and $blockers -gt 0) {
    throw "Playtest evidence has $blockers P0/P1 blocker(s)."
}
if ($RequireComplete -and -not $completeEnough) {
    throw "Playtest evidence is incomplete: $completeSessions/$MinimumSessions complete session(s)."
}
