param(
    [string]$EvidenceRoot,
    [string]$OutputPath,
    [int]$MinimumPlaytestSessions = 5,
    [switch]$Initialize,
    [switch]$RequireComplete
)

$ErrorActionPreference = "Stop"
$SecretPatternDefinitions = @(
    [pscustomobject]@{ Label = "OpenAI API key"; Pattern = 'sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}' },
    [pscustomobject]@{ Label = "private key block"; Pattern = '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----' },
    [pscustomobject]@{ Label = "authorization bearer token"; Pattern = '(?i)\bAuthorization\s*:\s*Bearer\s+[A-Za-z0-9._~+/=-]{20,}' },
    [pscustomobject]@{ Label = "token assignment"; Pattern = '(?i)\b(access_token|refresh_token|id_token|api_key|secret_key|client_secret)\b\s*[:=]\s*["'']?[A-Za-z0-9._~+/=-]{20,}' },
    [pscustomobject]@{ Label = "password field"; Pattern = '(?i)\b(steam_)?password\b\s*[:=]\s*["'']?\S{6,}' },
    [pscustomobject]@{ Label = "Steam Guard code field"; Pattern = '(?i)\bsteam\s*guard(\s*code|\s*otp)?\b\s*[:=]\s*["'']?[A-Z0-9]{5,}' },
    [pscustomobject]@{ Label = "Steam mobile secret"; Pattern = '(?i)\b(shared_secret|identity_secret)\b\s*[:=]\s*["'']?[A-Za-z0-9+/=]{16,}' }
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

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Get-Files {
    param(
        [string]$Path,
        [string]$Filter = "*"
    )

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }

    @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -File -Filter $Filter -Recurse -ErrorAction Stop)
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

function Get-TextFiles {
    param([string]$Path)

    Get-Files -Path $Path | Where-Object { Test-TextLikeFile -File $_ }
}

function Get-SecretMatches {
    param([string]$Path)

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($file in (Get-TextFiles -Path $Path)) {
        foreach ($definition in $SecretPatternDefinitions) {
            $found = Select-String -LiteralPath (ConvertTo-LongPath -Path $file.FullName) -Pattern $definition.Pattern -ErrorAction SilentlyContinue
            foreach ($match in $found) {
                $matches.Add([pscustomobject]@{
                    Path = $match.Path
                    Label = $definition.Label
                }) | Out-Null
            }
        }
    }
    return $matches.ToArray()
}

function Get-Directories {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }

    @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -Directory -ErrorAction Stop)
}

function Add-Result {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Status,
        [string]$Evidence,
        [string]$Missing = ""
    )

    $script:results.Add([pscustomobject]@{
        Area = $Area
        Item = $Item
        Status = $Status
        Evidence = $Evidence
        Missing = $Missing
    }) | Out-Null
}

function Test-FileNameLike {
    param(
        [object[]]$Files,
        [string]$Pattern,
        [string]$ExcludePattern = "(^README|README|template|reference|sample|blank|양식|예시)"
    )

    return [bool]($Files | Where-Object { $_.Name -match $Pattern -and $_.Name -notmatch $ExcludePattern } | Select-Object -First 1)
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

function Resolve-Tool {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw "Tool not found: $($Names -join ', ')"
}

function Get-DefaultBuildInfoPath {
    $candidates = @(
        (Join-Path $projectRoot "Build\BUILD_INFO.json"),
        (Join-Path $projectRoot "Game\Interviewee1UnityAvatarChat\BUILD_INFO.json"),
        (Join-Path $projectRoot "Interviewee1UnityAvatarChat\BUILD_INFO.json"),
        (Join-Path $projectRoot "BUILD_INFO.json")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $candidate)) {
            return $candidate
        }
    }

    return ""
}

function Get-SessionQaSummary {
    param([string]$SessionQaPath)

    if ([string]::IsNullOrWhiteSpace($SessionQaPath) -or -not (Test-Path -LiteralPath $SessionQaPath)) {
        return ""
    }

    $text = Get-Content -LiteralPath $SessionQaPath -Raw -Encoding UTF8
    $statusMatch = [regex]::Match($text, "-\s*상태:\s*([^\r\n]+)")
    $incompleteMatch = [regex]::Match($text, "-\s*미완료:\s*(\d+)")
    $failedMatch = [regex]::Match($text, "-\s*실패:\s*(\d+)")
    $missingRows = @([regex]::Matches($text, "\|\s*([^|]+?)\s*\|\s*(미완료|실패)\s*\|[^|]*\|\s*([^|]+?)\s*\|") | ForEach-Object {
        "$($_.Groups[1].Value.Trim()) $($_.Groups[2].Value.Trim())"
    } | Select-Object -First 3)

    $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim() } else { "세션 QA 미완료" }
    $incomplete = if ($incompleteMatch.Success) { $incompleteMatch.Groups[1].Value.Trim() } else { "?" }
    $failed = if ($failedMatch.Success) { $failedMatch.Groups[1].Value.Trim() } else { "?" }
    $details = if ($missingRows.Count -gt 0) { " (" + ($missingRows -join ", ") + ")" } else { "" }
    return "SESSION_QA 상태 $status, 미완료 $incomplete, 실패 $failed$details"
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
$evidenceDropRoot = Join-Path $projectRoot "EvidenceDrop"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $evidenceDropRoot)) {
        $EvidenceRoot = $evidenceDropRoot
    }
    else {
        $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
    }
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $evidenceDropRoot)) {
        $OutputPath = Join-Path $evidenceDropRoot "EXTERNAL_EVIDENCE_AUDIT.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "EXTERNAL_EVIDENCE_AUDIT.md"
    }
}

$areas = @("Playtest", "Accessibility", "ArtReview", "Trailer", "LegalSteam")

if ($Initialize) {
    Ensure-Directory -Path $EvidenceRoot
    foreach ($area in $areas) {
        $areaPath = Join-Path $EvidenceRoot $area
        Ensure-Directory -Path $areaPath
        $readmePath = Join-Path $areaPath "README.txt"
        if (-not (Test-Path -LiteralPath $readmePath)) {
            Set-Content -LiteralPath $readmePath -Value "Place external evidence for $area here. Do not include API keys, Steam credentials, passwords, or private account notes." -Encoding UTF8
        }
    }
}

$results = New-Object System.Collections.Generic.List[object]

$playtestRoot = Join-Path $EvidenceRoot "Playtest"
$sessionDirs = Get-Directories -Path $playtestRoot | Where-Object { $_.Name -notmatch '^\.' }
$completeSessions = 0
$completeSessionNames = New-Object System.Collections.Generic.List[string]
$incompleteSessionNotes = New-Object System.Collections.Generic.List[string]
$sessionQaScript = Join-Path $PSScriptRoot "ValidateExternalEvidenceSession.ps1"
$sessionBuildInfoPath = Get-DefaultBuildInfoPath
$powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")
foreach ($session in $sessionDirs) {
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $sessionQaScript))) {
        $incompleteSessionNotes.Add("$($session.Name): ValidateExternalEvidenceSession.ps1 누락") | Out-Null
        continue
    }

    $sessionQaPath = Join-Path $session.FullName "SESSION_QA.md"
    $files = Get-Files -Path $session.FullName
    $hasObservation = Test-FileNameLike -Files $files -Pattern "PLAYTEST_OBSERVATION_FORM|observation|관찰"
    $hasFeedbackText = Test-FileNameLike -Files $files -Pattern "feedback.*\.txt$|피드백.*\.txt$|participant.*\.txt$|플레이테스트.*\.txt$"
    $hasFeedbackJson = Test-FileNameLike -Files $files -Pattern "feedback.*\.json$|피드백.*\.json$|participant.*\.json$|플레이테스트.*\.json$"
    $hasSupport = [bool](
        ($files | Where-Object { $_.Name -match "support_info\.json|BUILD_INFO\.txt|SupportBundle|support-bundle" } | Select-Object -First 1) -or
        (Get-Directories -Path $session.FullName | Where-Object { $_.Name -match "SupportBundle|support-bundle" } | Select-Object -First 1)
    )
    if (-not ($hasObservation -and $hasFeedbackText -and $hasFeedbackJson -and $hasSupport)) {
        $incompleteSessionNotes.Add("$($session.Name): 관찰 양식 $hasObservation, 피드백 txt $hasFeedbackText, 피드백 json $hasFeedbackJson, 지원 번들 $hasSupport") | Out-Null
        continue
    }

    try {
        $sessionQaArgs = @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            $sessionQaScript,
            "-SessionRoot",
            $session.FullName,
            "-OutputPath",
            $sessionQaPath,
            "-RequireComplete"
        )
        if (-not [string]::IsNullOrWhiteSpace($sessionBuildInfoPath)) {
            $sessionQaArgs += @("-BuildInfoPath", $sessionBuildInfoPath)
        }
        $qaOutput = & $powershell @sessionQaArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            $message = Get-SessionQaSummary -SessionQaPath $sessionQaPath
            if ([string]::IsNullOrWhiteSpace($message)) {
                $message = ($qaOutput | ForEach-Object { [string]$_ } | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
                } | Select-Object -Last 1) -join " "
                if ([string]::IsNullOrWhiteSpace($message)) {
                    $message = "세션 QA 미완료"
                }
            }
            throw $message
        }
        $completeSessions++
        $completeSessionNames.Add($session.Name) | Out-Null
    }
    catch {
        $reason = $_.Exception.Message
        if ([string]::IsNullOrWhiteSpace($reason)) {
            $reason = "세션 QA 미완료"
        }
        $incompleteSessionNotes.Add("$($session.Name): $reason") | Out-Null
    }
}
if ($completeSessions -ge $MinimumPlaytestSessions) {
    Add-Result -Area "외부 플레이테스트" -Item "5명 이상 세션 증거" -Status "완료" -Evidence "$($completeSessions)개 완성 세션, 세션 QA 통과: $($completeSessionNames -join ', ')"
}
else {
    $sessionReason = if ($incompleteSessionNotes.Count -gt 0) {
        (@($incompleteSessionNotes | Select-Object -First 3) -join " / ")
    }
    else {
        "세션 폴더 없음"
    }
    Add-Result -Area "외부 플레이테스트" -Item "5명 이상 세션 증거" -Status "미완료" -Evidence "$completeSessions/$($MinimumPlaytestSessions)개 완성 세션, 세션 QA 기준" -Missing "각 세션에 관찰 양식, 지원 번들, 피드백 txt/json을 넣고 ValidateExternalEvidenceSession.ps1 -RequireComplete를 통과한다. $sessionReason"
}

$accessibilityRoot = Join-Path $EvidenceRoot "Accessibility"
$accessibilityFiles = Get-Files -Path $accessibilityRoot
$hasAccessibilityForm = Test-FileNameLike -Files $accessibilityFiles -Pattern "ACCESSIBILITY_OBSERVATION_FORM|accessibility|접근성"
$hasAccessibilityMedia = Test-FileNameLike -Files $accessibilityFiles -Pattern "\.(png|jpg|jpeg|mp4|mov|webm)$"
if ($hasAccessibilityForm -and $hasAccessibilityMedia) {
    Add-Result -Area "접근성" -Item "실제 접근성 QA 증거" -Status "완료" -Evidence "관찰 양식과 화면/녹화 증거 확인"
}
else {
    Add-Result -Area "접근성" -Item "실제 접근성 QA 증거" -Status "미완료" -Evidence "양식: $hasAccessibilityForm, 화면/녹화: $hasAccessibilityMedia" -Missing "접근성 관찰 양식과 화면 배율/키보드/고대비 또는 실제 입력 장치 증거를 넣는다."
}

$artRoot = Join-Path $EvidenceRoot "ArtReview"
$artFiles = Get-Files -Path $artRoot
$hasArtForm = Test-FileNameLike -Files $artFiles -Pattern "ART_REVIEW_FORM|art.*review|아트"
$hasArtEvidence = Test-FileNameLike -Files $artFiles -Pattern "\.(png|jpg|jpeg|pdf)$"
if ($hasArtForm -and $hasArtEvidence) {
    Add-Result -Area "상업 아트" -Item "외부 아트 리뷰 증거" -Status "완료" -Evidence "아트 리뷰 양식과 이미지/PDF 증거 확인"
}
else {
    Add-Result -Area "상업 아트" -Item "외부 아트 리뷰 증거" -Status "미완료" -Evidence "양식: $hasArtForm, 이미지/PDF: $hasArtEvidence" -Missing "아트 리뷰 양식과 캡슐/키아트 검토 증거를 넣는다."
}

$trailerRoot = Join-Path $EvidenceRoot "Trailer"
$trailerFiles = Get-Files -Path $trailerRoot
$hasTrailerForm = Test-FileNameLike -Files $trailerFiles -Pattern "TRAILER_FINAL_REVIEW_FORM|trailer.*review|트레일러"
$hasFinalTrailer = [bool]($trailerFiles | Where-Object { $_.Name -match "\.(mp4|mov|webm)$" -and $_.Length -gt 100000 } | Select-Object -First 1)
$hasCaption = Test-FileNameLike -Files $trailerFiles -Pattern "\.(srt|vtt)$|caption|subtitle|자막"
if ($hasTrailerForm -and $hasFinalTrailer -and $hasCaption) {
    Add-Result -Area "트레일러" -Item "최종 트레일러 증거" -Status "완료" -Evidence "리뷰 양식, 최종 영상, 자막 증거 확인"
}
else {
    Add-Result -Area "트레일러" -Item "최종 트레일러 증거" -Status "미완료" -Evidence "양식: $hasTrailerForm, 영상: $hasFinalTrailer, 자막: $hasCaption" -Missing "라이브 플레이 기반 최종 영상, 리뷰 양식, 자막/캡션 파일을 넣는다."
}

$legalRoot = Join-Path $EvidenceRoot "LegalSteam"
$legalFiles = Get-Files -Path $legalRoot
$hasSteamChecklist = Test-FileNameLike -Files $legalFiles -Pattern "STEAM_ADMIN_CHECKLIST|steam.*admin|steam"
$hasFinalPrivacy = Test-FileNameLike -Files $legalFiles -Pattern "PRIVACY.*FINAL|privacy.*final|개인정보.*최종"
$hasBranchEvidence = Test-FileNameLike -Files $legalFiles -Pattern "branch|builds|steam.*test|테스트.*브랜치|\.png$|\.pdf$"
if ($hasSteamChecklist -and $hasFinalPrivacy -and $hasBranchEvidence) {
    Add-Result -Area "법무/상점" -Item "Steam 관리자와 개인정보 최종 증거" -Status "완료" -Evidence "Steam 체크리스트, 최종 개인정보 문구, 테스트 브랜치 증거 확인"
}
else {
    Add-Result -Area "법무/상점" -Item "Steam 관리자와 개인정보 최종 증거" -Status "미완료" -Evidence "Steam 체크리스트: $hasSteamChecklist, 개인정보 최종본: $hasFinalPrivacy, 브랜치 증거: $hasBranchEvidence" -Missing "Steam 관리자 체크리스트, 개인정보 최종 문구, 테스트 브랜치 실행 증거를 넣는다."
}

$secretMatches = @()
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $EvidenceRoot)) {
    $secretMatches = Get-SecretMatches -Path $EvidenceRoot
}
if ($secretMatches) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { "$($_.Label): $($_.Path)" }) -join ", "
    Add-Result -Area "보안" -Item "외부 증거 비밀정보 검색" -Status "실패" -Evidence $sample -Missing "증거 폴더에서 API 키, 토큰, 비밀번호, Steam Guard 코드, private key 형태 문자열을 제거한다."
}
else {
    Add-Result -Area "보안" -Item "외부 증거 비밀정보 검색" -Status "완료" -Evidence "API 키, 토큰, 비밀번호, Steam Guard 코드, private key 형태 문자열 없음"
}

$complete = @($results | Where-Object { $_.Status -eq "완료" }).Count
$incomplete = @($results | Where-Object { $_.Status -eq "미완료" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 검증 증거 감사")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 증거 루트: $EvidenceRoot")
$lines.Add("- 완료: $complete")
$lines.Add("- 미완료: $incomplete")
$lines.Add("- 실패: $failed")
$lines.Add("")
$lines.Add("이 보고서는 자동 QA로 대체할 수 없는 외부 증거가 실제로 들어왔는지 확인한다. 증거가 부족하면 최종 유료 출시 후보로 완료 처리하지 않는다.")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 | 부족한 증거 |")
$lines.Add("| --- | --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Area) | $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.Missing) |")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "External evidence audit written: $OutputPath"
Write-Host "Complete: $complete, incomplete: $incomplete, failed: $failed"

if ($failed -gt 0) {
    throw "External evidence audit has $failed failed item(s)."
}
if ($RequireComplete -and $incomplete -gt 0) {
    throw "External evidence audit is incomplete: $incomplete item(s)."
}
