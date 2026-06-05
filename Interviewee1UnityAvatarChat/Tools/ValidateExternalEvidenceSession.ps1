param(
    [Parameter(Mandatory = $true)]
    [string]$SessionRoot,
    [string]$BuildInfoPath,
    [string]$OutputPath,
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

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

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
        throw "Missing path: $Path"
    }
}

function Get-FilesSafe {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return @()
    }

    @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $Path) -File -Recurse -ErrorAction Stop)
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

function Get-RelativePath {
    param(
        [string]$Root,
        [string]$Path
    )

    $rootFull = ([System.IO.Path]::GetFullPath($Root)).TrimEnd('\', '/')
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($rootFull.Length).TrimStart('\', '/')
    }
    return $pathFull
}

function Add-Result {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Evidence,
        [string]$Missing = ""
    )

    $script:results.Add([pscustomobject]@{
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

function Get-DefaultBuildInfoPath {
    $projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
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

function Get-SecretMatches {
    param([string]$Path)

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($file in (Get-FilesSafe -Path $Path | Where-Object { Test-TextLikeFile -File $_ })) {
        foreach ($definition in $SecretPatternDefinitions) {
            $found = Select-String -LiteralPath (ConvertTo-LongPath -Path $file.FullName) -Pattern $definition.Pattern -ErrorAction SilentlyContinue
            foreach ($match in $found) {
                $matches.Add([pscustomobject]@{
                    Path = (Get-RelativePath -Root $Path -Path $match.Path)
                    Label = $definition.Label
                }) | Out-Null
            }
        }
    }
    return $matches.ToArray()
}

function Write-FileManifest {
    param(
        [string]$Root,
        [string]$Path
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("relative_path`tbytes`tsha256")
    foreach ($file in (Get-FilesSafe -Path $Root | Sort-Object FullName)) {
        if ($file.Name -eq "SESSION_FILE_MANIFEST.tsv") {
            continue
        }
        $relative = Get-RelativePath -Root $Root -Path $file.FullName
        $hash = (Get-FileHash -LiteralPath (ConvertTo-LongPath -Path $file.FullName) -Algorithm SHA256).Hash
        $lines.Add("$relative`t$($file.Length)`t$hash")
    }

    Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}

Assert-Path -Path $SessionRoot
if ([string]::IsNullOrWhiteSpace($BuildInfoPath)) {
    $BuildInfoPath = Get-DefaultBuildInfoPath
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $SessionRoot "SESSION_QA.md"
}

$sessionRootPath = (Resolve-Path $SessionRoot).Path
$files = Get-FilesSafe -Path $sessionRootPath
$results = New-Object System.Collections.Generic.List[object]

$feedbackRoot = Join-Path $sessionRootPath "Feedback"
if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $feedbackRoot))) {
    $feedbackRoot = $sessionRootPath
}
$supportRoot = Join-Path $sessionRootPath "SupportBundle"
$formsRoot = Join-Path $sessionRootPath "Forms"

$hasObservation = Test-FileNameLike -Files $files -Pattern "PLAYTEST_OBSERVATION_FORM|observation|관찰"
$hasFeedbackText = Test-FileNameLike -Files $files -Pattern "feedback.*\.txt$|피드백.*\.txt$|participant.*\.txt$|플레이테스트.*\.txt$"
$hasFeedbackJson = Test-FileNameLike -Files $files -Pattern "feedback.*\.json$|피드백.*\.json$|participant.*\.json$|플레이테스트.*\.json$"
$hasSupport = [bool](
    ($files | Where-Object {
        $_.Name -match "support_info\.json" -or
        ((Get-RelativePath -Root $sessionRootPath -Path $_.FullName) -match "(^|[\\/])SupportBundle[\\/].*BUILD_INFO\.txt$")
    } | Select-Object -First 1) -or
    ((Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $sessionRootPath) -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "support-bundle" }) | Select-Object -First 1)
)

if ($hasObservation) {
    Add-Result -Item "관찰 양식" -Status "완료" -Evidence "관찰 양식 파일 확인"
}
else {
    Add-Result -Item "관찰 양식" -Status "미완료" -Evidence "관찰 양식 파일 없음" -Missing "Forms 폴더에 작성 완료된 관찰 양식을 넣는다."
}

if ($hasFeedbackText -and $hasFeedbackJson) {
    Add-Result -Item "피드백 원문" -Status "완료" -Evidence "피드백 txt/json 파일 확인"
}
else {
    Add-Result -Item "피드백 원문" -Status "미완료" -Evidence "txt: $hasFeedbackText, json: $hasFeedbackJson" -Missing "앱에서 저장한 feedback txt/json 한 쌍을 넣는다."
}

if ($hasSupport) {
    Add-Result -Item "지원 번들" -Status "완료" -Evidence "지원 번들 진단 파일 확인"
}
else {
    Add-Result -Item "지원 번들" -Status "미완료" -Evidence "지원 번들 없음" -Missing "CollectSupportBundle.ps1 결과 폴더 또는 zip을 넣는다."
}

$feedbackValidationStatus = "미완료"
$feedbackValidationEvidence = "피드백 txt/json 한 쌍 또는 build info가 부족함"
if ($hasFeedbackText -and $hasFeedbackJson -and -not [string]::IsNullOrWhiteSpace($BuildInfoPath) -and (Test-Path -LiteralPath (ConvertTo-LongPath -Path $BuildInfoPath))) {
    try {
        $validateFeedback = Join-Path $PSScriptRoot "ValidatePlaytestFeedbackExport.ps1"
        Assert-Path -Path $validateFeedback
        $output = & $validateFeedback -FeedbackRoot $feedbackRoot -BuildInfoPath $BuildInfoPath -RequireFiveTurnSession 2>&1
        $feedbackValidationStatus = "완료"
        $feedbackValidationEvidence = ($output | Select-Object -Last 1) -join " "
        if ([string]::IsNullOrWhiteSpace($feedbackValidationEvidence)) {
            $feedbackValidationEvidence = "ValidatePlaytestFeedbackExport.ps1 -RequireFiveTurnSession 통과"
        }
    }
    catch {
        $feedbackValidationStatus = "실패"
        $feedbackValidationEvidence = $_.Exception.Message
    }
}
elseif ($hasFeedbackText -and $hasFeedbackJson) {
    $feedbackValidationEvidence = "build info를 찾을 수 없어 buildId/5문답 검증을 건너뜀"
}
if ($feedbackValidationStatus -eq "완료") {
    Add-Result -Item "피드백 JSON 검증" -Status $feedbackValidationStatus -Evidence $feedbackValidationEvidence
}
else {
    Add-Result -Item "피드백 JSON 검증" -Status $feedbackValidationStatus -Evidence $feedbackValidationEvidence -Missing "ValidatePlaytestFeedbackExport.ps1 -RequireFiveTurnSession 통과 필요"
}

$secretMatches = Get-SecretMatches -Path $sessionRootPath
if ($secretMatches.Count -gt 0) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { "$($_.Label): $($_.Path)" }) -join ", "
    Add-Result -Item "비밀정보 검색" -Status "실패" -Evidence $sample -Missing "API 키, 토큰, 비밀번호, Steam Guard 코드, private key 형태 문자열을 제거한다."
}
else {
    Add-Result -Item "비밀정보 검색" -Status "완료" -Evidence "비밀정보 패턴 없음"
}

$fileManifestPath = Join-Path $sessionRootPath "SESSION_FILE_MANIFEST.tsv"
Write-FileManifest -Root $sessionRootPath -Path $fileManifestPath
Add-Result -Item "파일 해시 명세" -Status "완료" -Evidence "SESSION_FILE_MANIFEST.tsv 생성"

$complete = @($results | Where-Object { $_.Status -eq "완료" }).Count
$incomplete = @($results | Where-Object { $_.Status -eq "미완료" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count
$status = if ($failed -gt 0) { "실패" } elseif ($incomplete -gt 0) { "미완료" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 플레이테스트 세션 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 세션 루트: $sessionRootPath")
$lines.Add("- 상태: $status")
$lines.Add("- 완료: $complete")
$lines.Add("- 미완료: $incomplete")
$lines.Add("- 실패: $failed")
if (-not [string]::IsNullOrWhiteSpace($BuildInfoPath)) {
    $lines.Add("- 빌드 정보: $BuildInfoPath")
}
$lines.Add("")
$lines.Add("이 검사는 한 명의 외부 플레이테스트 세션이 최종 게이트 증거로 쓸 수 있을 만큼 완성됐는지 확인한다.")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 | 부족한 증거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) | $(Escape-MarkdownCell $result.Missing) |")
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

Write-Host "External evidence session QA written: $OutputPath"
Write-Host "Status: $status, complete: $complete, incomplete: $incomplete, failed: $failed"

if ($failed -gt 0) {
    throw "External evidence session QA failed: $failed item(s)."
}
if ($RequireComplete -and $incomplete -gt 0) {
    throw "External evidence session is incomplete: $incomplete item(s)."
}
