param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\PAPERLOGY_FONT_QA.md"
}

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

function Escape-MarkdownCell {
    param([string]$Text)

    return ($Text -replace "\\", "\\" -replace "\|", "\|" -replace "`r?`n", "<br>")
}

function Test-PathResult {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Path,
        [int64]$MinBytes = 1
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Result -Area $Area -Item $Item -Status "실패" -Evidence "누락: $Path"
        return
    }

    $itemInfo = Get-Item -LiteralPath $Path
    if ($itemInfo.Length -lt $MinBytes) {
        Add-Result -Area $Area -Item $Item -Status "실패" -Evidence "파일 크기 부족: $Path ($($itemInfo.Length) bytes)"
        return
    }

    Add-Result -Area $Area -Item $Item -Status "통과" -Evidence "$Path ($($itemInfo.Length) bytes)"
}

function Test-ContentPattern {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Path,
        [string]$Pattern
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Result -Area $Area -Item $Item -Status "실패" -Evidence "누락: $Path"
        return
    }

    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($text -notmatch $Pattern) {
        Add-Result -Area $Area -Item $Item -Status "실패" -Evidence "패턴 없음: $Pattern"
        return
    }

    Add-Result -Area $Area -Item $Item -Status "통과" -Evidence "패턴 확인: $Pattern"
}

function Test-ProvenanceFontHash {
    param(
        [string]$Item,
        [string]$Path,
        [string]$ExpectedArtifact,
        [string]$ExpectedHash
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Result -Area "산출물 증거" -Item $Item -Status "실패" -Evidence "누락: $Path"
        return
    }

    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $Path -Encoding UTF8)
    $row = $rows | Where-Object { $_.artifact -eq $ExpectedArtifact } | Select-Object -First 1
    if (-not $row) {
        Add-Result -Area "산출물 증거" -Item $Item -Status "실패" -Evidence "artifact 누락: $ExpectedArtifact"
        return
    }

    if ($row.font_path -notmatch "Paperlogy-7Bold\.ttf") {
        Add-Result -Area "산출물 증거" -Item $Item -Status "실패" -Evidence "Paperlogy Bold 경로가 아님: $($row.font_path)"
        return
    }

    if ($row.font_sha256 -ne $ExpectedHash) {
        Add-Result -Area "산출물 증거" -Item $Item -Status "실패" -Evidence "폰트 해시 불일치: $($row.font_sha256)"
        return
    }

    Add-Result -Area "산출물 증거" -Item $Item -Status "통과" -Evidence "$ExpectedArtifact Paperlogy-7Bold 해시 확인"
}

$results = New-Object System.Collections.Generic.List[object]
$fontRoot = Join-Path $projectRoot "Assets\Resources\Fonts"
$sourcePath = Join-Path $projectRoot "Assets\Scripts\AvatarChatApp.cs"
$paperlogyBoldPath = Join-Path $fontRoot "Paperlogy-7Bold.ttf"
$paperlogyBoldHash = if (Test-Path -LiteralPath $paperlogyBoldPath) { (Get-FileHash -LiteralPath $paperlogyBoldPath -Algorithm SHA256).Hash } else { "missing" }

Test-PathResult -Area "폰트 자산" -Item "Paperlogy Regular" -Path (Join-Path $fontRoot "Paperlogy-4Regular.ttf") -MinBytes 100000
Test-PathResult -Area "폰트 자산" -Item "Paperlogy SemiBold" -Path (Join-Path $fontRoot "Paperlogy-6SemiBold.ttf") -MinBytes 100000
Test-PathResult -Area "폰트 자산" -Item "Paperlogy Bold" -Path $paperlogyBoldPath -MinBytes 100000

Test-ContentPattern -Area "게임 UI" -Item "런타임 폰트 리소스 로드" -Path $sourcePath -Pattern '(?s)Resources\.Load<Font>\("Fonts/Paperlogy-4Regular"\).*Resources\.Load<Font>\("Fonts/Paperlogy-6SemiBold"\).*Resources\.Load<Font>\("Fonts/Paperlogy-7Bold"\)'
Test-ContentPattern -Area "게임 UI" -Item "동적 폰트 fallback 우선순위" -Path $sourcePath -Pattern '(?s)"Paperlogy".*"Paperlogy 4 Regular".*"Noto Sans KR".*"Malgun Gothic"'
Test-ContentPattern -Area "게임 UI" -Item "런타임 폰트 스모크 상태" -Path $sourcePath -Pattern 'state\\tui-font|GetUiFontReport'

foreach ($scriptName in @("GenerateSteamAssets.ps1", "GenerateTrailerAnimatic.ps1", "GenerateBuildCaptureTrailer.ps1")) {
    $scriptPath = Join-Path $PSScriptRoot $scriptName
    Test-ContentPattern -Area "상점/트레일러" -Item "$scriptName Paperlogy 번들 로드" -Path $scriptPath -Pattern '(?s)Paperlogy-7Bold\.ttf.*PrivateFontCollection.*AddFontFile'
}

Test-ProvenanceFontHash -Item "Steam 자산 생성 폰트 증거" -Path (Join-Path $projectRoot "Marketing\SteamAssets\ASSET_PROVENANCE.tsv") -ExpectedArtifact "SteamAssets" -ExpectedHash $paperlogyBoldHash
Test-ProvenanceFontHash -Item "애니매틱 트레일러 생성 폰트 증거" -Path (Join-Path $projectRoot "Marketing\Trailer\TRAILER_ANIMATIC_PROVENANCE.tsv") -ExpectedArtifact "trailer_animatic_60s.mp4" -ExpectedHash $paperlogyBoldHash
Test-ProvenanceFontHash -Item "빌드 캡처 트레일러 생성 폰트 증거" -Path (Join-Path $projectRoot "Marketing\Trailer\TRAILER_BUILD_CAPTURE_PROVENANCE.tsv") -ExpectedArtifact "trailer_build_capture_60s.mp4" -ExpectedHash $paperlogyBoldHash

$passed = @($results | Where-Object { $_.Status -eq "통과" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Paperlogy 폰트 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 자동 통과: $passed")
$lines.Add("- 자동 실패: $failed")
$lines.Add("")
$lines.Add("이 QA는 게임 UI와 상점/트레일러 생성 스크립트가 번들된 Paperlogy 폰트를 우선 사용하도록 유지되는지 확인한다.")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Area) | $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) |")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failed -gt 0) {
    throw "Paperlogy font QA failed with $failed issue(s). Report: $OutputPath"
}

Write-Host "Paperlogy font QA passed: $OutputPath"
