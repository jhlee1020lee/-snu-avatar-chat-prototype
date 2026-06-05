param(
    [string]$OutputPath,
    [string]$MatrixPath,
    [decimal]$PriceTargetUsd = 5,
    [int]$MinimumComparableCount = 5
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

function Get-DecimalPrice {
    param([object]$PriceOverview)

    if ($null -eq $PriceOverview) {
        return $null
    }

    $value = if ($PriceOverview.initial -and [int]$PriceOverview.initial -gt 0) {
        [int]$PriceOverview.initial
    }
    else {
        [int]$PriceOverview.final
    }

    return [math]::Round($value / 100, 2)
}

function Get-CurrentDecimalPrice {
    param([object]$PriceOverview)

    if ($null -eq $PriceOverview) {
        return $null
    }

    return [math]::Round(([int]$PriceOverview.final) / 100, 2)
}

function Format-Price {
    param([Nullable[decimal]]$Price)

    if ($null -eq $Price) {
        return ""
    }

    return "{0:0.00}" -f $Price
}

function Invoke-SteamJson {
    param([string]$Url)

    $response = Invoke-WebRequest -Uri $Url -Headers @{
        "User-Agent" = "Mozilla/5.0"
        "Accept-Language" = "en-US,en;q=0.9"
    } -UseBasicParsing -TimeoutSec 30

    return $response.Content | ConvertFrom-Json
}

function Invoke-SteamHtml {
    param([string]$Url)

    $response = Invoke-WebRequest -Uri $Url -Headers @{
        "User-Agent" = "Mozilla/5.0"
        "Accept-Language" = "en-US,en;q=0.9"
    } -UseBasicParsing -TimeoutSec 30

    return $response.Content
}

function Get-StoreTags {
    param([string]$Html)

    $tags = New-Object System.Collections.Generic.List[string]
    foreach ($match in [regex]::Matches($Html, 'app_tag"[^>]*>\s*([^<]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $tag = [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
        if (-not [string]::IsNullOrWhiteSpace($tag) -and -not $tags.Contains($tag)) {
            $tags.Add($tag) | Out-Null
        }
        if ($tags.Count -ge 6) {
            break
        }
    }

    return ($tags -join ", ")
}

function Get-ReviewSummary {
    param([string]$Html)

    $reviewRows = New-Object System.Collections.Generic.List[string]
    $pattern = '<a class="user_reviews_summary_row".*?<div class="subtitle column[^"]*">\s*([^<]+)\s*</div>.*?<span class="game_review_summary[^"]*"[^>]*>\s*([^<]+)\s*</span>.*?<span class="nonresponsive_hidden responsive_reviewdesc">\s*-\s*([^<]+)\s*</span>'
    foreach ($match in [regex]::Matches($Html, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        $label = [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim().TrimEnd(":")
        $summary = [System.Net.WebUtility]::HtmlDecode($match.Groups[2].Value).Trim()
        $detail = [System.Net.WebUtility]::HtmlDecode($match.Groups[3].Value).Trim()
        if (-not [string]::IsNullOrWhiteSpace($label) -and -not [string]::IsNullOrWhiteSpace($summary)) {
            $reviewRows.Add("${label}: ${summary} (${detail})") | Out-Null
        }
    }

    if ($reviewRows.Count -eq 0) {
        return ""
    }

    return ($reviewRows | Select-Object -First 2) -join "; "
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

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON.md"
}
if ([string]::IsNullOrWhiteSpace($MatrixPath)) {
    $MatrixPath = Join-Path $docsRoot "STEAM_MARKET_COMPARISON.tsv"
}

$candidates = @(
    [pscustomobject]@{ appid = 914800; relevance_tags = "conversation, visual novel, listening"; comparison_reason = "대화 중심 내러티브와 정돈된 짧은 세션 가치 비교" },
    [pscustomobject]@{ appid = 1082430; relevance_tags = "short narrative, emotional, accessibility"; comparison_reason = "짧은 체험형 내러티브의 가격 기대치 비교" },
    [pscustomobject]@{ appid = 1491670; relevance_tags = "cultural story, short narrative, cooking"; comparison_reason = "문화적 소재를 짧은 내러티브로 판매하는 사례 비교" },
    [pscustomobject]@{ appid = 1102130; relevance_tags = "short story, emotional, interactive story"; comparison_reason = "짧은 인터랙티브 스토리의 낮은 가격대 기준점" },
    [pscustomobject]@{ appid = 1055540; relevance_tags = "short, exploration, wholesome"; comparison_reason = "짧고 밀도 높은 인디 경험의 저가 기준점" },
    [pscustomobject]@{ appid = 1070710; relevance_tags = "letters, kindness, asynchronous conversation"; comparison_reason = "대화와 기록 감정 가치를 중심으로 한 저가 기준점" },
    [pscustomobject]@{ appid = 1135690; relevance_tags = "objects, memory, narrative"; comparison_reason = "사물과 기억을 다루는 높은 완성도 인디 가격 기준점" },
    [pscustomobject]@{ appid = 1307580; relevance_tags = "gentle adventure, cozy, screenshots"; comparison_reason = "짧지만 시각 완성도가 높은 인디 가격 기준점" }
)

$fetchedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$rows = New-Object System.Collections.Generic.List[object]
$failures = New-Object System.Collections.Generic.List[string]

foreach ($candidate in $candidates) {
    $appid = [string]$candidate.appid
    $storeUrl = "https://store.steampowered.com/app/$appid"
    $detailsUrl = "https://store.steampowered.com/api/appdetails?appids=$appid&cc=US&l=english"

    try {
        $details = Invoke-SteamJson -Url $detailsUrl
        $entry = $details.$appid
        if (-not $entry.success) {
            throw "Steam appdetails returned success=false"
        }

        $data = $entry.data
        $html = Invoke-SteamHtml -Url $storeUrl
        $listPrice = Get-DecimalPrice -PriceOverview $data.price_overview
        $currentPrice = Get-CurrentDecimalPrice -PriceOverview $data.price_overview
        $discount = if ($data.price_overview) { [int]$data.price_overview.discount_percent } else { 0 }
        $storeTags = Get-StoreTags -Html $html
        $genres = if ($data.genres) {
            (($data.genres | ForEach-Object { $_.description }) -join ", ")
        }
        else {
            $storeTags
        }
        $recommendations = if ($data.recommendations -and $data.recommendations.total) {
            [string]$data.recommendations.total
        }
        else {
            ""
        }
        $metacritic = if ($data.metacritic -and $data.metacritic.score) {
            [string]$data.metacritic.score
        }
        else {
            ""
        }

        $rows.Add([pscustomobject]@{
            appid = $appid
            title = [string]$data.name
            list_price_usd = Format-Price -Price $listPrice
            current_price_usd = Format-Price -Price $currentPrice
            discount_percent = [string]$discount
            release_date = [string]$data.release_date.date
            steam_genres = $genres
            visible_store_tags = $storeTags
            review_tone = Get-ReviewSummary -Html $html
            recommendations_total = $recommendations
            metacritic_score = $metacritic
            relevance_tags = [string]$candidate.relevance_tags
            comparison_reason = [string]$candidate.comparison_reason
            source_url = $storeUrl
            appdetails_url = $detailsUrl
            fetched_at = $fetchedAt
        }) | Out-Null

        Start-Sleep -Milliseconds 250
    }
    catch {
        $failures.Add("${appid}: $($_.Exception.Message)") | Out-Null
    }
}

$matrixLines = New-Object System.Collections.Generic.List[string]
$matrixLines.Add("appid`ttitle`tlist_price_usd`tcurrent_price_usd`tdiscount_percent`trelease_date`tsteam_genres`tvisible_store_tags`treview_tone`trecommendations_total`tmetacritic_score`trelevance_tags`tcomparison_reason`tsource_url`tappdetails_url`tfetched_at")
foreach ($row in $rows) {
    $matrixLines.Add((
        (Format-TsvCell $row.appid),
        (Format-TsvCell $row.title),
        (Format-TsvCell $row.list_price_usd),
        (Format-TsvCell $row.current_price_usd),
        (Format-TsvCell $row.discount_percent),
        (Format-TsvCell $row.release_date),
        (Format-TsvCell $row.steam_genres),
        (Format-TsvCell $row.visible_store_tags),
        (Format-TsvCell $row.review_tone),
        (Format-TsvCell $row.recommendations_total),
        (Format-TsvCell $row.metacritic_score),
        (Format-TsvCell $row.relevance_tags),
        (Format-TsvCell $row.comparison_reason),
        (Format-TsvCell $row.source_url),
        (Format-TsvCell $row.appdetails_url),
        (Format-TsvCell $row.fetched_at)
    ) -join "`t")
}
Write-LinesWithRetry -Path $MatrixPath -Lines $matrixLines

$validRows = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.title) -and -not [string]::IsNullOrWhiteSpace($_.source_url) })
$listAboveTarget = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.list_price_usd) -and [decimal]$_.list_price_usd -ge $PriceTargetUsd }).Count
$currentAboveTarget = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.current_price_usd) -and [decimal]$_.current_price_usd -ge $PriceTargetUsd }).Count
$discounted = @($rows | Where-Object { [int]$_.discount_percent -gt 0 }).Count
$status = if ($validRows.Count -ge $MinimumComparableCount -and $failures.Count -eq 0) {
    "완료"
}
elseif ($validRows.Count -ge $MinimumComparableCount) {
    "부분 완료"
}
else {
    "보류"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Steam 시장 비교")
$lines.Add("")
$lines.Add("- 생성 시각: $fetchedAt")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- 상태: $status")
$lines.Add("- 비교작 수: $($validRows.Count)")
$lines.Add("- 정가 USD $PriceTargetUsd 이상: $listAboveTarget")
$lines.Add("- 현재가 USD $PriceTargetUsd 이상: $currentAboveTarget")
$lines.Add("- 할인 중: $discounted")
$lines.Add("- 실패: $($failures.Count)")
$lines.Add("- 비교표 파일: $MatrixPath")
$lines.Add("")
$lines.Add("이 문서는 Steam 미국 상점 기준의 현재 가격, 표시 태그, 리뷰 요약을 기록한 시장 비교 캐시다. Steam 가격과 리뷰 요약은 바뀔 수 있으므로 최종 가격 회의 직전에 다시 생성해야 한다.")
$lines.Add("")
$lines.Add("## 판단")
$lines.Add("")
if ($listAboveTarget -ge 3) {
    $lines.Add("- USD $PriceTargetUsd 이상 정가 자체는 유사 내러티브/코지 인디 시장 안에 존재한다.")
}
else {
    $lines.Add("- 현재 비교표만 보면 USD $PriceTargetUsd 이상 정가 근거가 약하다.")
}
if ($currentAboveTarget -lt $listAboveTarget) {
    $lines.Add("- 할인 중인 비교작이 있어 현재 체감 가격은 정가보다 낮을 수 있다. 출시 할인 전략을 따로 정해야 한다.")
}
$lines.Add("- 이 게임은 대화 세션, 기록 저장, 연결 상태와 관계없는 기본 텍스트 대화, 접근성 옵션, 상점 신뢰 증거가 모두 완성되어야 USD $PriceTargetUsd 이상 가격 후보로 설득력이 생긴다.")
$lines.Add("")
$lines.Add("## 비교표")
$lines.Add("")
$lines.Add("| 제목 | 정가 USD | 현재가 USD | 할인 | 출시일 | 장르 | 표시 태그 | 리뷰 요약 | 관련성 | 출처 |")
$lines.Add("| --- | ---: | ---: | ---: | --- | --- | --- | --- | --- | --- |")
foreach ($row in $rows) {
    $lines.Add("| $(Escape-MarkdownCell $row.title) | $(Escape-MarkdownCell $row.list_price_usd) | $(Escape-MarkdownCell $row.current_price_usd) | $(Escape-MarkdownCell $row.discount_percent)% | $(Escape-MarkdownCell $row.release_date) | $(Escape-MarkdownCell $row.steam_genres) | $(Escape-MarkdownCell $row.visible_store_tags) | $(Escape-MarkdownCell $row.review_tone) | $(Escape-MarkdownCell $row.comparison_reason) | $(Escape-MarkdownCell $row.source_url) |")
}
if ($failures.Count -gt 0) {
    $lines.Add("")
    $lines.Add("## 수집 실패")
    $lines.Add("")
    foreach ($failure in $failures) {
        $lines.Add("- $failure")
    }
}

Write-LinesWithRetry -Path $OutputPath -Lines $lines

Write-Host "Steam market comparison written: $OutputPath"
Write-Host "Steam market comparison matrix written: $MatrixPath"
Write-Host "Status: $status, rows: $($validRows.Count), list >= target: $listAboveTarget, current >= target: $currentAboveTarget, failures: $($failures.Count)"
