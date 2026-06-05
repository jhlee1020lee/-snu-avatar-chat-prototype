param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverPersonaPath = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI\data\persona.json"
$serverReadmePath = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI\README.md"
$serverDataRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI\data"
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\PRODUCT_BRANDING_QA.md"
}
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)

$expectedTitle = "겉!=속"
$expectedSlug = "GeotNotEqualSok"
$forbidden = @("겉=속!", "겉=속", "GeotEqualsSok", "목발에서 책상까지", "CrutchToDesk", "Crutch to Desk")
$results = New-Object System.Collections.Generic.List[object]

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

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Test-ContentPattern {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Path,
        [string]$Pattern,
        [string]$Evidence
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

    Add-Result -Area $Area -Item $Item -Status "통과" -Evidence $Evidence
}

Test-ContentPattern -Area "게임 코드" -Item "Unity GameTitle" -Path (Join-Path $projectRoot "Assets\Scripts\AvatarChatApp.cs") -Pattern 'GameTitle\s*=\s*"겉!=속"' -Evidence "AvatarChatApp.cs GameTitle = $expectedTitle"
Test-ContentPattern -Area "게임 코드" -Item "Unity productName" -Path (Join-Path $projectRoot "ProjectSettings\ProjectSettings.asset") -Pattern 'productName:\s*겉!=속' -Evidence "ProjectSettings productName = $expectedTitle"
Test-ContentPattern -Area "빌드" -Item "빌드 메타데이터 제목" -Path (Join-Path $projectRoot "Tools\WriteBuildMetadata.ps1") -Pattern 'displayName\s*=\s*"겉!=속"' -Evidence "WriteBuildMetadata.ps1 displayName = $expectedTitle"
Test-ContentPattern -Area "서버" -Item "persona 제목" -Path $serverPersonaPath -Pattern '(?s)"appTitle"\s*:\s*"겉!=속".*"displayName"\s*:\s*"겉!=속"' -Evidence "persona.json appTitle/displayName = $expectedTitle"
Test-ContentPattern -Area "상점 자산" -Item "Steam 자산 제목" -Path (Join-Path $projectRoot "Tools\GenerateSteamAssets.ps1") -Pattern 'Title\s+"겉!=속"|Text\s+"겉!=속"|Title\s+"겉!=`n속"' -Evidence "Steam 자산 생성 제목 = $expectedTitle"
Test-ContentPattern -Area "패키지" -Item "패키지 슬러그" -Path (Join-Path $projectRoot "Tools\MakeReleasePackage.ps1") -Pattern $expectedSlug -Evidence "Release package slug = $expectedSlug"

$scanRoots = @(
    "Assets",
    "Docs",
    "Marketing",
    "ProjectSettings",
    "Tools",
    "Build\Interviewee1UnityAvatarChat_Data\app.info",
    "README.md",
    "LaunchAvatarChat.ps1",
    "RUN_AVATAR_CHAT.bat"
)
$textExtensions = @(".asset", ".bat", ".cs", ".css", ".csv", ".html", ".js", ".json", ".jsonl", ".md", ".meta", ".ps1", ".psm1", ".srt", ".tsv", ".txt", ".vtt", ".xml", ".yaml", ".yml")
$scanFiles = foreach ($root in $scanRoots) {
    $path = Join-Path $projectRoot $root
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Get-Item -LiteralPath $path
    }
    elseif (Test-Path -LiteralPath $path -PathType Container) {
        Get-ChildItem -LiteralPath $path -File -Recurse
    }
}
if (Test-Path -LiteralPath $serverPersonaPath) {
    $scanFiles += Get-Item -LiteralPath $serverPersonaPath
}
if (Test-Path -LiteralPath $serverReadmePath) {
    $scanFiles += Get-Item -LiteralPath $serverReadmePath
}
if (Test-Path -LiteralPath $serverDataRoot -PathType Container) {
    $scanFiles += Get-ChildItem -LiteralPath $serverDataRoot -File -Recurse
}

$hits = New-Object System.Collections.Generic.List[string]
foreach ($file in $scanFiles) {
    if ($textExtensions -notcontains $file.Extension.ToLowerInvariant()) {
        continue
    }
    if ($file.FullName -eq $PSCommandPath -or [System.IO.Path]::GetFullPath($file.FullName) -eq $outputFullPath) {
        continue
    }

    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($bad in $forbidden) {
        if ($text -like "*$bad*") {
            $hits.Add("$($file.FullName): $bad") | Out-Null
        }
    }
}

if ($hits.Count -gt 0) {
    Add-Result -Area "브랜딩 금지어" -Item "구 표기 제거" -Status "실패" -Evidence (($hits | Select-Object -First 12) -join "; ")
}
else {
    Add-Result -Area "브랜딩 금지어" -Item "구 표기 제거" -Status "통과" -Evidence "스캔 범위에서 구 제목/구 슬러그 없음"
}

$passCount = @($results | Where-Object { $_.Status -eq "통과" }).Count
$failCount = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 제품 브랜딩 QA") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')") | Out-Null
$lines.Add("- 기준 제목: $expectedTitle") | Out-Null
$lines.Add("- 기준 슬러그: $expectedSlug") | Out-Null
$lines.Add("- 통과: $passCount") | Out-Null
$lines.Add("- 실패: $failCount") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("| 영역 | 항목 | 상태 | 근거 |") | Out-Null
$lines.Add("| --- | --- | --- | --- |") | Out-Null
foreach ($row in $results) {
    $lines.Add("| $(Escape-MarkdownCell $row.Area) | $(Escape-MarkdownCell $row.Item) | $(Escape-MarkdownCell $row.Status) | $(Escape-MarkdownCell $row.Evidence) |") | Out-Null
}

if ($failCount -gt 0) {
    Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8
    throw "Product branding QA failed with $failCount issue(s). Report: $OutputPath"
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8
Write-Host "Product branding QA passed: $OutputPath"

