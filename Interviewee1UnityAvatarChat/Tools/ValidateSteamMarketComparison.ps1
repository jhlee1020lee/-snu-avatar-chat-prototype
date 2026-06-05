param(
    [string]$MatrixPath,
    [string]$OutputPath,
    [decimal]$PriceTargetUsd = 5,
    [int]$MinimumComparableCount = 5,
    [int]$MaximumAgeDays = 30,
    [switch]$RequireReady
)

$ErrorActionPreference = "Stop"

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Format-TsvCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Add-Issue {
    param(
        [string]$Severity,
        [string]$Area,
        [string]$Detail
    )

    $script:issues.Add([pscustomobject]@{
        severity = $Severity
        area = $Area
        detail = $Detail
    }) | Out-Null
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

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($MatrixPath)) {
    $MatrixPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON_QA.md"
}

$issues = New-Object System.Collections.Generic.List[object]
$rows = @()

if (-not (Test-Path -LiteralPath $MatrixPath)) {
    Add-Issue -Severity "보류" -Area "파일" -Detail "시장 비교 TSV가 없다: $MatrixPath"
}
else {
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $MatrixPath -Encoding UTF8)
    if ($rows.Count -lt $MinimumComparableCount) {
        Add-Issue -Severity "보류" -Area "비교작 수" -Detail "비교작 $($rows.Count)개, 필요 $MinimumComparableCount개"
    }
}

$requiredColumns = @(
    "appid",
    "title",
    "list_price_usd",
    "current_price_usd",
    "steam_genres",
    "visible_store_tags",
    "review_tone",
    "source_url",
    "fetched_at"
)

foreach ($row in $rows) {
    foreach ($column in $requiredColumns) {
        if (-not ($row.PSObject.Properties.Name -contains $column)) {
            Add-Issue -Severity "차단" -Area "컬럼" -Detail "필수 컬럼 누락: $column"
            break
        }
        if ([string]::IsNullOrWhiteSpace([string]$row.$column)) {
            Add-Issue -Severity "보류" -Area "행 데이터" -Detail "$($row.title) $column 값이 비어 있다."
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$row.source_url) -and [string]$row.source_url -notmatch "^https://store\.steampowered\.com/app/\d+") {
        Add-Issue -Severity "차단" -Area "출처" -Detail "$($row.title) 출처 URL이 Steam 앱 URL이 아니다: $($row.source_url)"
    }

    foreach ($priceColumn in @("list_price_usd", "current_price_usd")) {
        $value = [string]$row.$priceColumn
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            try {
                $null = [decimal]$value
            }
            catch {
                Add-Issue -Severity "차단" -Area "가격" -Detail "$($row.title) $priceColumn 숫자 변환 실패: $value"
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$row.fetched_at)) {
        try {
            $fetchedAt = [datetimeoffset]::Parse([string]$row.fetched_at)
            if ($fetchedAt -lt (Get-Date).AddDays(-1 * $MaximumAgeDays)) {
                Add-Issue -Severity "보류" -Area "갱신일" -Detail "$($row.title) 시장 비교가 $MaximumAgeDays일보다 오래됐다: $($row.fetched_at)"
            }
        }
        catch {
            Add-Issue -Severity "차단" -Area "갱신일" -Detail "$($row.title) fetched_at 파싱 실패: $($row.fetched_at)"
        }
    }
}

$blockers = @($issues | Where-Object { $_.severity -eq "차단" }).Count
$holds = @($issues | Where-Object { $_.severity -eq "보류" }).Count
$listAboveTarget = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.list_price_usd) -and [decimal]$_.list_price_usd -ge $PriceTargetUsd }).Count
$currentAboveTarget = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.current_price_usd) -and [decimal]$_.current_price_usd -ge $PriceTargetUsd }).Count
$status = if ($blockers -gt 0) {
    "차단"
}
elseif ($holds -gt 0) {
    "보류"
}
else {
    "완료"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Steam 시장 비교 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 비교표: $MatrixPath")
$lines.Add("- 상태: $status")
$lines.Add("- 비교작 수: $($rows.Count)")
$lines.Add("- 정가 USD $PriceTargetUsd 이상: $listAboveTarget")
$lines.Add("- 현재가 USD $PriceTargetUsd 이상: $currentAboveTarget")
$lines.Add("- 차단: $blockers")
$lines.Add("- 보류: $holds")
$lines.Add("")
$lines.Add("## 문제")
$lines.Add("")
if ($issues.Count -eq 0) {
    $lines.Add("- 없음")
}
else {
    foreach ($issue in $issues) {
        $lines.Add("- [$($issue.severity)] $($issue.area): $($issue.detail)")
    }
}
$lines.Add("")
$lines.Add("## 비교작")
$lines.Add("")
$lines.Add("| AppID | 제목 | 정가 USD | 현재가 USD | 리뷰 요약 | 태그 | 출처 |")
$lines.Add("| --- | --- | ---: | ---: | --- | --- | --- |")
foreach ($row in $rows) {
    $lines.Add("| $(Escape-MarkdownCell $row.appid) | $(Escape-MarkdownCell $row.title) | $(Escape-MarkdownCell $row.list_price_usd) | $(Escape-MarkdownCell $row.current_price_usd) | $(Escape-MarkdownCell $row.review_tone) | $(Escape-MarkdownCell $row.visible_store_tags) | $(Escape-MarkdownCell $row.source_url) |")
}

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Steam market comparison QA written: $OutputPath"
Write-Host "Status: $status, rows: $($rows.Count), blockers: $blockers, holds: $holds"

if ($RequireReady -and $status -ne "완료") {
    throw "Steam market comparison is not ready: $status"
}
