param(
    [string]$StorePagePath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Add-ReportRow {
    param(
        [string]$Status,
        [string]$Check,
        [string]$Detail
    )

    $script:rows.Add([pscustomobject]@{
        status = $Status
        check = $Check
        detail = $Detail
    }) | Out-Null
}

function Add-Pass {
    param(
        [string]$Check,
        [string]$Detail
    )

    Add-ReportRow -Status "통과" -Check $Check -Detail $Detail
}

function Add-Fail {
    param(
        [string]$Check,
        [string]$Detail
    )

    Add-ReportRow -Status "실패" -Check $Check -Detail $Detail
}

function Get-PlainLength {
    param([string]$Text)

    if ($null -eq $Text) {
        return 0
    }

    return (($Text -replace "`r|`n", " ") -replace "\s+", " ").Trim().Length
}

function Get-Sections {
    param([string]$Text)

    $sections = [ordered]@{}
    $currentName = $null
    $buffer = New-Object System.Collections.Generic.List[string]
    $lines = $Text -split "`r?`n"

    foreach ($line in $lines) {
        if ($line -match "^##\s+(.+?)\s*$") {
            if ($currentName) {
                $sections[$currentName] = ($buffer -join "`n").Trim()
            }
            $currentName = $Matches[1].Trim()
            $buffer.Clear()
            continue
        }

        if ($currentName) {
            $buffer.Add($line) | Out-Null
        }
    }

    if ($currentName) {
        $sections[$currentName] = ($buffer -join "`n").Trim()
    }

    return $sections
}

function Escape-Tsv {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ")
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$defaultMarketingRoot = Join-Path $projectRoot "Marketing"
if ([string]::IsNullOrWhiteSpace($StorePagePath)) {
    $StorePagePath = Join-Path $defaultMarketingRoot "STORE_PAGE_DRAFT.md"
}

if (-not (Test-Path -LiteralPath $StorePagePath)) {
    throw "Missing store page draft: $StorePagePath"
}

$StorePagePath = (Resolve-Path $StorePagePath).Path
$marketingRoot = Split-Path -Parent $StorePagePath
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $marketingRoot "StoreCopy\STORE_COPY_QA_REPORT.tsv"
}

$rows = New-Object System.Collections.Generic.List[object]
$content = Get-Content -LiteralPath $StorePagePath -Raw -Encoding UTF8
$sections = Get-Sections -Text $content
$requiredSections = @(
    "한 줄 소개",
    "짧은 소개문",
    "긴 소개문",
    "핵심 특징",
    "태그 후보",
    "스크린샷 세트",
    "상점 페이지 주의 문구"
)

foreach ($section in $requiredSections) {
    if (-not $sections.Contains($section)) {
        Add-Fail -Check "필수 섹션" -Detail "누락: $section"
    }
    elseif ([string]::IsNullOrWhiteSpace($sections[$section])) {
        Add-Fail -Check "필수 섹션" -Detail "본문 없음: $section"
    }
}

$unknownSections = @($sections.Keys | Where-Object { $requiredSections -notcontains $_ })
if ($unknownSections.Count -gt 0) {
    Add-Fail -Check "상점 문구 범위" -Detail "내부 메모로 분리해야 하는 섹션: $($unknownSections -join ', ')"
}
else {
    Add-Pass -Check "상점 문구 범위" -Detail "상점용 필수 섹션만 포함"
}

$forbiddenPatterns = @(
    @{ Pattern = "OpenAI"; Label = "OpenAI" },
    @{ Pattern = "\bAPI\b"; Label = "API" },
    @{ Pattern = "fallback"; Label = "fallback" },
    @{ Pattern = "서버"; Label = "서버" },
    @{ Pattern = "초안"; Label = "초안" },
    @{ Pattern = "생성형"; Label = "생성형" },
    @{ Pattern = "전시용"; Label = "전시용" },
    @{ Pattern = "가격 포지셔닝"; Label = "가격 포지셔닝" },
    @{ Pattern = "10달러"; Label = "10달러" },
    @{ Pattern = "현재 캡슐"; Label = "현재 캡슐" },
    @{ Pattern = "최종 제출 전"; Label = "최종 제출 전" },
    @{ Pattern = "TODO"; Label = "TODO" },
    @{ Pattern = "TBD"; Label = "TBD" },
    @{ Pattern = "placeholder"; Label = "placeholder" }
)

$forbiddenHits = New-Object System.Collections.Generic.List[string]
foreach ($entry in $forbiddenPatterns) {
    if ($content -match $entry.Pattern) {
        $forbiddenHits.Add($entry.Label) | Out-Null
    }
}

if ($forbiddenHits.Count -gt 0) {
    Add-Fail -Check "내부 표현 제거" -Detail "상점 문구에 남은 표현: $($forbiddenHits -join ', ')"
}
else {
    Add-Pass -Check "내부 표현 제거" -Detail "개발자용 표현 없음"
}

if ($content -match "\*\*") {
    Add-Fail -Check "마크다운 강조" -Detail "별표 강조가 남아 있음"
}
else {
    Add-Pass -Check "마크다운 강조" -Detail "별표 강조 없음"
}

$oneLineLength = Get-PlainLength -Text $sections["한 줄 소개"]
if ($oneLineLength -lt 20 -or $oneLineLength -gt 140) {
    Add-Fail -Check "한 줄 소개 길이" -Detail "현재 $oneLineLength자, 기준 20-140자"
}
else {
    Add-Pass -Check "한 줄 소개 길이" -Detail "${oneLineLength}자"
}

$shortLength = Get-PlainLength -Text $sections["짧은 소개문"]
if ($shortLength -lt 60 -or $shortLength -gt 400) {
    Add-Fail -Check "짧은 소개문 길이" -Detail "현재 $shortLength자, 기준 60-400자"
}
else {
    Add-Pass -Check "짧은 소개문 길이" -Detail "${shortLength}자"
}

$longLength = Get-PlainLength -Text $sections["긴 소개문"]
if ($longLength -lt 250 -or $longLength -gt 1600) {
    Add-Fail -Check "긴 소개문 길이" -Detail "현재 $longLength자, 기준 250-1600자"
}
else {
    Add-Pass -Check "긴 소개문 길이" -Detail "${longLength}자"
}

$featureCount = @($sections["핵심 특징"] -split "`r?`n" | Where-Object { $_ -match "^\s*-\s+\S" }).Count
if ($featureCount -lt 6) {
    Add-Fail -Check "핵심 특징 수" -Detail "현재 $featureCount개, 기준 6개 이상"
}
else {
    Add-Pass -Check "핵심 특징 수" -Detail "${featureCount}개"
}

$tagCount = @($sections["태그 후보"] -split "`r?`n" | Where-Object { $_ -match "^\s*-\s+\S" }).Count
if ($tagCount -lt 6 -or $tagCount -gt 15) {
    Add-Fail -Check "태그 후보 수" -Detail "현재 $tagCount개, 기준 6-15개"
}
else {
    Add-Pass -Check "태그 후보 수" -Detail "${tagCount}개"
}

$screenshotMatches = [regex]::Matches($sections["스크린샷 세트"], 'Screenshots/([^`]+\.png)')
$screenshotNames = @($screenshotMatches | ForEach-Object { $_.Groups[1].Value })
$uniqueScreenshotNames = @($screenshotNames | Sort-Object -Unique)
if ($screenshotNames.Count -ne 11 -or $uniqueScreenshotNames.Count -ne 11) {
    Add-Fail -Check "스크린샷 11장" -Detail "경로 $($screenshotNames.Count)개, 고유 $($uniqueScreenshotNames.Count)개"
}
else {
    Add-Pass -Check "스크린샷 11장" -Detail "11개 경로 확인"
}

$missingScreenshots = New-Object System.Collections.Generic.List[string]
foreach ($name in $uniqueScreenshotNames) {
    $path = Join-Path $marketingRoot "Screenshots\$name"
    if (-not (Test-Path -LiteralPath $path)) {
        $missingScreenshots.Add($name) | Out-Null
    }
}
if ($missingScreenshots.Count -gt 0) {
    Add-Fail -Check "스크린샷 파일 존재" -Detail "누락: $($missingScreenshots -join ', ')"
}
else {
    Add-Pass -Check "스크린샷 파일 존재" -Detail "상점 스크린샷 파일 확인"
}

$captionCount = @($sections["스크린샷 세트"] -split "`r?`n" | Where-Object { $_ -match "캡션:" }).Count
if ($captionCount -ne 11) {
    Add-Fail -Check "스크린샷 캡션" -Detail "현재 $captionCount개, 기준 11개"
}
else {
    Add-Pass -Check "스크린샷 캡션" -Detail "11개 캡션 확인"
}

$notice = [string]$sections["상점 페이지 주의 문구"]
if ($notice -notmatch "로컬" -or $notice -notmatch "삭제") {
    Add-Fail -Check "저장 데이터 고지" -Detail "로컬 저장과 삭제 가능 여부를 모두 포함해야 함"
}
else {
    Add-Pass -Check "저장 데이터 고지" -Detail "로컬 저장과 삭제 문구 확인"
}

$valueChecks = @(
    @{ Label = "대화 세션"; Pattern = "대화형 인터뷰|문답|질문" },
    @{ Label = "다섯 문답 완결"; Pattern = "다섯\s*(번의\s*)?(문답|질문)" },
    @{ Label = "기억장 진행"; Pattern = "기억장" },
    @{ Label = "마무리 기록"; Pattern = "마무리|오늘 남길 문장|기록함" },
    @{ Label = "로컬 삭제"; Pattern = "로컬[\s\S]*삭제|삭제[\s\S]*로컬" },
    @{ Label = "연결 독립 기본 대화"; Pattern = "연결 상태와 관계없이|별도 연결이 없어도" },
    @{ Label = "접근성 설정"; Pattern = "글자 크기[\s\S]*소리[\s\S]*화면 모드[\s\S]*움직임 줄임|움직임 줄임[\s\S]*글자 크기" }
)
$missingValueClaims = New-Object System.Collections.Generic.List[string]
foreach ($check in $valueChecks) {
    if ($content -notmatch $check.Pattern) {
        $missingValueClaims.Add($check.Label) | Out-Null
    }
}
if ($missingValueClaims.Count -gt 0) {
    Add-Fail -Check "상점 가치 제안" -Detail "누락: $($missingValueClaims -join ', ')"
}
else {
    Add-Pass -Check "상점 가치 제안" -Detail "대화 세션, 기억장, 기록, 로컬 삭제, 기본 대화, 접근성 확인"
}

$requiredCaptionSignals = @(
    @{ Label = "시작"; Pattern = "시작" },
    @{ Label = "질문"; Pattern = "질문" },
    @{ Label = "단서"; Pattern = "단서" },
    @{ Label = "스크롤"; Pattern = "스크롤" },
    @{ Label = "기억장"; Pattern = "기억장" },
    @{ Label = "마무리"; Pattern = "마무리|문장" },
    @{ Label = "기록"; Pattern = "기록" },
    @{ Label = "삭제"; Pattern = "삭제|관리" },
    @{ Label = "접근성"; Pattern = "글자 크기|움직임 줄임" },
    @{ Label = "데이터"; Pattern = "데이터" },
    @{ Label = "이어하기"; Pattern = "이어" }
)
$missingCaptionSignals = New-Object System.Collections.Generic.List[string]
foreach ($signal in $requiredCaptionSignals) {
    if ($sections["스크린샷 세트"] -notmatch $signal.Pattern) {
        $missingCaptionSignals.Add($signal.Label) | Out-Null
    }
}
if ($missingCaptionSignals.Count -gt 0) {
    Add-Fail -Check "스크린샷 판매 흐름" -Detail "캡션에 부족한 흐름: $($missingCaptionSignals -join ', ')"
}
else {
    Add-Pass -Check "스크린샷 판매 흐름" -Detail "시작, 질문, 단서, 대화, 기억장, 기록, 삭제, 접근성, 이어하기 확인"
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

function Write-LinesWithRetry {
    param(
        [string]$Path,
        [object]$Lines
    )

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        $tempPath = "$Path.tmp-$PID-$([guid]::NewGuid().ToString('N'))"
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

$reportLines = New-Object System.Collections.Generic.List[string]
$reportLines.Add("status`tcheck`tdetail")
foreach ($row in $rows) {
    $status = Escape-Tsv -Text ([string]$row.status)
    $check = Escape-Tsv -Text ([string]$row.check)
    $detail = Escape-Tsv -Text ([string]$row.detail)
    $reportLines.Add(("{0}`t{1}`t{2}" -f $status, $check, $detail))
}
Write-LinesWithRetry -Path $OutputPath -Lines $reportLines

$failures = @($rows | Where-Object { $_.status -eq "실패" })
if ($failures.Count -gt 0) {
    throw "Store copy QA failed with $($failures.Count) issue(s). Report: $OutputPath"
}

Write-Host "Store copy QA passed: $OutputPath"
