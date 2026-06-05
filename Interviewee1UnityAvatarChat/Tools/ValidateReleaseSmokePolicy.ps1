param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Add-Result {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Status,
        [string]$Evidence
    )

    $script:results.Add([pscustomobject]@{
        Area = $Area
        Item = $Item
        Status = $Status
        Evidence = $Evidence
    }) | Out-Null
}

function Add-Pass {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Evidence
    )

    Add-Result -Area $Area -Item $Item -Status "통과" -Evidence $Evidence
}

function Add-Fail {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Evidence
    )

    Add-Result -Area $Area -Item $Item -Status "실패" -Evidence $Evidence
}

function Read-Utf8Text {
    param([string]$Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Test-Pattern {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Text,
        [string]$Pattern,
        [string]$Evidence
    )

    if ($Text -match $Pattern) {
        Add-Pass -Area $Area -Item $Item -Evidence $Evidence
    }
    else {
        Add-Fail -Area $Area -Item $Item -Evidence "패턴 누락: $Pattern"
    }
}

function Test-NoUnsafeSmokeCommand {
    param(
        [string]$Path,
        [string]$Text
    )

    $unsafe = [regex]::Matches($Text, "RunReleaseSmoke\.ps1(?![^\r\n]*(AllowUnityWindows|StaticOnly))")
    if ($unsafe.Count -eq 0) {
        Add-Pass -Area "문서" -Item "$(Split-Path -Leaf $Path) 안전 실행 명령" -Evidence "AllowUnityWindows 또는 StaticOnly 없는 RunReleaseSmoke 명령 없음"
        return
    }

    $examples = @($unsafe | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ", "
    Add-Fail -Area "문서" -Item "$(Split-Path -Leaf $Path) 안전 실행 명령" -Evidence "안전 옵션 없는 RunReleaseSmoke 명령: $examples"
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\RELEASE_SMOKE_POLICY_QA.md"
}

$script:results = New-Object System.Collections.Generic.List[object]
$smokeScriptPath = Join-Path $PSScriptRoot "RunReleaseSmoke.ps1"
if (-not (Test-Path -LiteralPath $smokeScriptPath)) {
    throw "Missing RunReleaseSmoke.ps1: $smokeScriptPath"
}

$smokeSource = Read-Utf8Text -Path $smokeScriptPath
Test-Pattern -Area "스크립트" -Item "창 실행 명시 옵션" -Text $smokeSource -Pattern '\[switch\]\$AllowUnityWindows' -Evidence "AllowUnityWindows switch 확인"
Test-Pattern -Area "스크립트" -Item "창 없는 정적 검증 옵션" -Text $smokeSource -Pattern '\[switch\]\$StaticOnly' -Evidence "StaticOnly switch 확인"
Test-Pattern -Area "스크립트" -Item "기본 실행 즉시 차단" -Text $smokeSource -Pattern 'if \(-not \$AllowUnityWindows -and -not \$StaticOnly\)' -Evidence "기본 실행은 Unity 창 실행 전에 중단"
Test-Pattern -Area "스크립트" -Item "플레이어 실행 함수 가드" -Text $smokeSource -Pattern 'function Run-UnitySmokeChecked[\s\S]+if \(-not \$AllowUnityWindows\)' -Evidence "Unity player 실행 함수 내부 가드 확인"
Test-Pattern -Area "스크립트" -Item "StaticOnly 조기 종료" -Text $smokeSource -Pattern 'if \(\$StaticOnly\)[\s\S]+Static-only smoke complete[\s\S]+return' -Evidence "정적 검증 후 Unity build/capture 전에 종료"
Test-Pattern -Area "스크립트" -Item "긍정 피드백 마무리 기록 스모크" -Text $smokeSource -Pattern 'playtest-feedback-require-ending-record\.tsv[\s\S]+ending-record-needed' -Evidence "마무리 기록 없는 긍정 피드백 저장 차단 스모크 확인"

$docsToCheck = @(
    (Join-Path $projectRoot "README.md"),
    (Join-Path $projectRoot "Docs\RELEASE_CHECKLIST.md"),
    (Join-Path $projectRoot "Docs\TROUBLESHOOTING.md")
)

foreach ($docPath in $docsToCheck) {
    if (-not (Test-Path -LiteralPath $docPath)) {
        Add-Fail -Area "문서" -Item "$(Split-Path -Leaf $docPath) 존재" -Evidence "누락: $docPath"
        continue
    }

    $text = Read-Utf8Text -Path $docPath
    Test-Pattern -Area "문서" -Item "$(Split-Path -Leaf $docPath) 전체 스모크 명령" -Text $text -Pattern "RunReleaseSmoke\.ps1[^\r\n]*-AllowUnityWindows" -Evidence "전체 스모크는 AllowUnityWindows를 명시"
    Test-Pattern -Area "문서" -Item "$(Split-Path -Leaf $docPath) 정적 스모크 명령" -Text $text -Pattern "RunReleaseSmoke\.ps1[^\r\n]*-StaticOnly" -Evidence "창 없는 정적 스모크 명령 확인"
    Test-NoUnsafeSmokeCommand -Path $docPath -Text $text
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$passed = @($results | Where-Object { $_.Status -eq "통과" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 릴리즈 스모크 창 실행 정책 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 실패: $failed")
$lines.Add("- 통과: $passed")
$lines.Add("")
$lines.Add("이 검증은 릴리즈 스모크가 작업 중 실수로 Unity 창을 반복 실행하지 않도록, 전체 스모크에는 명시적 `-AllowUnityWindows`가 필요하고 창 없는 검증에는 `-StaticOnly`가 제공되는지 확인한다.")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $($result.Area) | $($result.Item) | $($result.Status) | $($result.Evidence) |")
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failed -gt 0) {
    throw "Release smoke policy QA failed with $failed issue(s). Report: $OutputPath"
}

Write-Host "Release smoke policy QA passed: $OutputPath"
