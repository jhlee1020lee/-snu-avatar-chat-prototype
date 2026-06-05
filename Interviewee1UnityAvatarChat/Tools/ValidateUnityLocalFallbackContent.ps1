param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Add-Result {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Evidence
    )

    $script:results.Add([pscustomobject]@{
        Item = $Item
        Status = $Status
        Evidence = $Evidence
    }) | Out-Null
}

function Test-SourcePattern {
    param(
        [string]$Item,
        [string]$Pattern,
        [string]$Evidence
    )

    if ($script:source -match $Pattern) {
        Add-Result -Item $Item -Status "통과" -Evidence $Evidence
    }
    else {
        Add-Result -Item $Item -Status "실패" -Evidence "Missing source pattern: $Pattern"
        $script:failures++
    }
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$sourcePath = Join-Path $projectRoot "Assets\Scripts\AvatarChatApp.cs"
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "UNITY_LOCAL_FALLBACK_CONTENT_QA.md"
}

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Missing Unity source: $sourcePath"
}

$source = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
$results = New-Object System.Collections.Generic.List[object]
$failures = 0

Test-SourcePattern -Item "날씨/비 근접 질문" -Pattern '날씨를 좋아하는지까지는 자료에 남아 있지 않아요[\s\S]*바닥[\s\S]*동선[\s\S]*목발' -Evidence "비, 날씨, 바닥 질문을 이동과 목발 동선으로 연결"
Test-SourcePattern -Item "휴식/주말 근접 질문" -Pattern '쉬는 날|주말|휴식[\s\S]*게임[\s\S]*코인노래방' -Evidence "쉬는 날과 휴식 질문을 확인된 취미와 자취방/생활 장면으로 연결"
Test-SourcePattern -Item "물건/전시 구성 질문" -Pattern '전시에서 확인된 물건[\s\S]*목발[\s\S]*책상[\s\S]*노트북' -Evidence "소지품/전시 구성 질문을 확인된 장면 단서로 연결"
Test-SourcePattern -Item "감정/민폐 질문" -Pattern '불안이나 민폐라는 감각[\s\S]*도움[\s\S]*일과 공부' -Evidence "불안, 민폐, 힘듦 질문을 조건 조율과 자기 생활로 연결"
Test-SourcePattern -Item "관계/설명 질문" -Pattern '관계에서 중요한 건[\s\S]*필요한 방식을 어떻게 설명[\s\S]*먼저 묻고' -Evidence "친구/관계 질문을 도움 방식과 설명 권한으로 연결"
Test-SourcePattern -Item "테마 분류 보강: 취미" -Pattern '휴식", "주말' -Evidence "쉬는 날과 휴식 질문이 취미 테마로 분류됨"
Test-SourcePattern -Item "테마 분류 보강: 도움" -Pattern '친구", "관계", "설명' -Evidence "관계와 설명 질문이 도움 테마로 분류됨"
Test-SourcePattern -Item "테마 분류 보강: 이동" -Pattern '날씨", "비", "눈", "바닥' -Evidence "날씨와 바닥 질문이 이동 테마로 분류됨"

$status = if ($failures -eq 0) { "통과" } else { "실패" }
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Unity 내장 답변 콘텐츠 QA")
$lines.Add("")
$lines.Add("- 상태: $status")
$lines.Add("- 실패: $failures")
$lines.Add("- 검사 대상: $sourcePath")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) |")
}

$directory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failures -gt 0) {
    throw "Unity local fallback content QA failed with $failures issue(s). Report: $OutputPath"
}

Write-Host "Unity local fallback content QA passed: $OutputPath"
