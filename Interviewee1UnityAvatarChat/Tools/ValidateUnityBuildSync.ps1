param(
    [string]$OutputPath,
    [switch]$RequireCurrent
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\UNITY_BUILD_SYNC_QA.md"
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-LatestFile {
    param([string[]]$Roots)

    $files = foreach ($root in $Roots) {
        if (Test-Path -LiteralPath $root -PathType Leaf) {
            Get-Item -LiteralPath $root
        }
        elseif (Test-Path -LiteralPath $root -PathType Container) {
            Get-ChildItem -LiteralPath $root -File -Recurse
        }
    }

    return $files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
}

$sourceRoots = @(
    (Join-Path $projectRoot "Assets\Scripts"),
    (Join-Path $projectRoot "Assets\Editor"),
    (Join-Path $projectRoot "Assets\Resources\Fonts"),
    (Join-Path $projectRoot "ProjectSettings\ProjectSettings.asset"),
    (Join-Path $projectRoot "ProjectSettings\ProjectVersion.txt")
)
$buildArtifacts = @(
    (Join-Path $buildRoot "Interviewee1UnityAvatarChat_Data\Managed\Assembly-CSharp.dll"),
    (Join-Path $buildRoot "Interviewee1UnityAvatarChat.exe"),
    (Join-Path $buildRoot "Interviewee1UnityAvatarChat_Data")
)

$latestSource = Get-LatestFile -Roots $sourceRoots
$latestBuildArtifact = Get-LatestFile -Roots $buildArtifacts

$results = New-Object System.Collections.Generic.List[object]
if (-not $latestSource) {
    $results.Add([pscustomobject]@{ Item = "소스 파일"; Status = "실패"; Evidence = "검사할 소스 파일 없음" }) | Out-Null
}
else {
    $results.Add([pscustomobject]@{ Item = "최근 소스"; Status = "통과"; Evidence = "$($latestSource.FullName) / $($latestSource.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" }) | Out-Null
}

if (-not $latestBuildArtifact) {
    $results.Add([pscustomobject]@{ Item = "빌드 산출물"; Status = "실패"; Evidence = "Build 폴더에 실행 산출물 없음" }) | Out-Null
}
else {
    $results.Add([pscustomobject]@{ Item = "최신 빌드 산출물"; Status = "통과"; Evidence = "$($latestBuildArtifact.FullName) / $($latestBuildArtifact.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" }) | Out-Null
}

$status = "통과"
if (-not $latestSource -or -not $latestBuildArtifact) {
    $status = "실패"
}
elseif ($latestSource.LastWriteTimeUtc -gt $latestBuildArtifact.LastWriteTimeUtc) {
    $status = "보류"
    $results.Add([pscustomobject]@{
        Item = "Unity 재빌드 필요"
        Status = "보류"
        Evidence = "최근 소스가 최신 빌드 산출물보다 최신임. 소스 변경이 실행 파일에 반영됐다는 런타임 증거가 필요함."
    }) | Out-Null
}
else {
    $results.Add([pscustomobject]@{
        Item = "Unity 재빌드 필요"
        Status = "통과"
        Evidence = "최신 빌드 산출물이 검사 대상 소스보다 최신이거나 같음"
    }) | Out-Null
}

$passCount = @($results | Where-Object { $_.Status -eq "통과" }).Count
$holdCount = @($results | Where-Object { $_.Status -eq "보류" }).Count
$failCount = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Unity 빌드 동기화 QA") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')") | Out-Null
$lines.Add("- 상태: $status") | Out-Null
$lines.Add("- 통과: $passCount") | Out-Null
$lines.Add("- 보류: $holdCount") | Out-Null
$lines.Add("- 실패: $failCount") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("이 검사는 Unity 창을 띄우지 않고 소스 파일과 최신 빌드 산출물의 수정 시각을 비교한다. Windows 실행 파일 래퍼는 Unity 빌드 때 수정 시각이 유지될 수 있으므로 실제 런타임 코드와 데이터 산출물을 함께 본다.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("| 항목 | 상태 | 근거 |") | Out-Null
$lines.Add("| --- | --- | --- |") | Out-Null
foreach ($row in $results) {
    $lines.Add("| $(Escape-MarkdownCell $row.Item) | $(Escape-MarkdownCell $row.Status) | $(Escape-MarkdownCell $row.Evidence) |") | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8
Write-Host "Unity build sync QA written: $OutputPath"
Write-Host "Status: $status, pending: $holdCount, failures: $failCount"

if ($failCount -gt 0) {
    throw "Unity build sync QA failed with $failCount issue(s). Report: $OutputPath"
}
if ($RequireCurrent -and $status -ne "통과") {
    throw "Unity build sync QA is not current: $status. Report: $OutputPath"
}
