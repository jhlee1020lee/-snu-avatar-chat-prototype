param(
    [string]$ScorecardPath,
    [string]$ReviewPath,
    [decimal]$PriceTargetUsd = 5
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

function Read-Report {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        try {
            return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            if ($attempt -eq 8) {
                throw
            }
            Start-Sleep -Milliseconds (120 * $attempt)
        }
    }

    return ""
}

function Get-ReportNumber {
    param(
        [string]$Text,
        [string]$Label
    )

    $match = [regex]::Match($Text, "-\s*$([regex]::Escape($Label)):\s*(\d+)")
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }

    return -1
}

function Test-ReportContains {
    param(
        [string]$Text,
        [string]$Pattern
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return [regex]::IsMatch($Text, $Pattern)
}

function Test-ReportContainsRow {
    param(
        [string]$Text,
        [string]$Area,
        [string]$Item,
        [string]$Status
    )

    $pattern = "\|\s*$([regex]::Escape($Area))\s*\|\s*$([regex]::Escape($Item))\s*\|\s*$([regex]::Escape($Status))\s*\|"
    return [regex]::IsMatch($Text, $pattern)
}

function Test-TsvHasNoFailures {
    param(
        [string]$Path,
        [string]$StatusColumn = "status"
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $Path -Encoding UTF8)
    if ($rows.Count -eq 0) {
        return $false
    }

    $failures = @($rows | Where-Object { $_.$StatusColumn -eq "실패" -or $_.$StatusColumn -eq "fail" })
    return $failures.Count -eq 0
}

function Test-VisualQuality {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $Path -Encoding UTF8)
    if ($rows.Count -eq 0) {
        return $false
    }

    $badRows = @($rows | Where-Object {
        $average = [decimal]$_.average_luminance
        $dark = [decimal]$_.dark_pixel_pct
        $purple = [decimal]$_.purple_pixel_pct
        $edge = [decimal]$_.edge_busy_pct
        $average -lt 105 -or $dark -gt 8 -or $purple -gt 0.25 -or $edge -gt 6
    })

    return $badRows.Count -eq 0
}

function Add-Score {
    param(
        [string]$Area,
        [string]$Item,
        [int]$Score,
        [bool]$InternalBlocker,
        [bool]$ExternalDependency,
        [string]$Evidence,
        [string]$Limitation,
        [string]$NextAction
    )

    $status = if ($InternalBlocker -or $Score -lt 3) {
        "차단"
    }
    elseif ($Score -lt 4 -or $ExternalDependency) {
        "보류"
    }
    else {
        "통과"
    }

    $script:rows.Add([pscustomobject]@{
        area = $Area
        item = $Item
        score = $Score
        status = $status
        internal_blocker = if ($InternalBlocker) { "yes" } else { "no" }
        external_dependency = if ($ExternalDependency) { "yes" } else { "no" }
        evidence = $Evidence
        limitation = $Limitation
        next_action = $NextAction
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
$marketingRoot = Join-Path $projectRoot "Marketing"

if ([string]::IsNullOrWhiteSpace($ScorecardPath)) {
    $ScorecardPath = Join-Path $docsRoot "INTERNAL_QUALITY_SCORECARD.tsv"
}
if ([string]::IsNullOrWhiteSpace($ReviewPath)) {
    $ReviewPath = Join-Path $docsRoot "INTERNAL_QUALITY_REVIEW.md"
}

$releaseText = Read-Report -Path (Join-Path $docsRoot "RELEASE_READINESS_REPORT.md")
$accessibilityText = Read-Report -Path (Join-Path $docsRoot "ACCESSIBILITY_AUTOMATION_QA.md")
$commercialCopyText = Read-Report -Path (Join-Path $docsRoot "COMMERCIAL_UI_COPY_QA.md")
$modelText = Read-Report -Path (Join-Path $docsRoot "MODEL_CONFIG_QA.md")
$legalText = Read-Report -Path (Join-Path $docsRoot "STEAM_LEGAL_READINESS_QA.md")
$externalText = Read-Report -Path (Join-Path $docsRoot "EXTERNAL_EVIDENCE_AUDIT.md")

$storeCopyPath = Join-Path $marketingRoot "StoreCopy\STORE_COPY_QA_REPORT.tsv"
$visualQualityPath = Join-Path $marketingRoot "VisualQuality\VISUAL_QUALITY_REPORT.tsv"
$buildCaptureTrailerPath = Join-Path $marketingRoot "Trailer\trailer_build_capture_60s.mp4"
$buildCaptureShotListPath = Join-Path $marketingRoot "Trailer\TRAILER_BUILD_CAPTURE_SHOTLIST.tsv"
$trailerCaptionsPath = Join-Path $marketingRoot "Trailer\TRAILER_CAPTIONS.srt"
$trailerWebVttPath = Join-Path $marketingRoot "Trailer\TRAILER_CAPTIONS.vtt"

$autoPassed = Get-ReportNumber -Text $releaseText -Label "자동 통과"
$autoFailed = Get-ReportNumber -Text $releaseText -Label "자동 실패"
$pending = Get-ReportNumber -Text $releaseText -Label "보류"
$accessibilityFailed = Get-ReportNumber -Text $accessibilityText -Label "자동 실패"
$commercialCopyFailed = Get-ReportNumber -Text $commercialCopyText -Label "실패"
$legalFailed = Get-ReportNumber -Text $legalText -Label "자동 실패"

$releaseAutomatedClean = $autoPassed -gt 0 -and $autoFailed -eq 0
$releaseClean = $releaseAutomatedClean -and $pending -eq 0
$contentClean = Test-ReportContainsRow -Text $releaseText -Area "콘텐츠" -Item "근거 답변 QA" -Status "통과"
$longSessionClean = Test-ReportContainsRow -Text $releaseText -Area "콘텐츠" -Item "장시간 세션 QA" -Status "통과"
$safetyClean = Test-ReportContainsRow -Text $releaseText -Area "콘텐츠 안전" -Item "개인정보/프롬프트 주입 QA" -Status "통과"
$uiCopyClean = $commercialCopyFailed -eq 0 -and (Test-ReportContainsRow -Text $releaseText -Area "상용 문구" -Item "플레이어 UI 문구 QA" -Status "통과")
$storeCopyClean = Test-TsvHasNoFailures -Path $storeCopyPath
$visualClean = (Test-ReportContainsRow -Text $releaseText -Area "상점" -Item "시각 품질 QA" -Status "통과") -and (Test-TsvHasNoFailures -Path $visualQualityPath)
$accessibilityFullClean = $accessibilityFailed -eq 0 -and (Test-ReportContainsRow -Text $releaseText -Area "접근성" -Item "접근성 자동 QA" -Status "통과")
$accessibilityStaticClean = $accessibilityFailed -eq 0 -and (Test-ReportContainsRow -Text $releaseText -Area "접근성" -Item "접근성 정적 자동 QA" -Status "통과")
$accessibilityClean = $accessibilityFullClean -or $accessibilityStaticClean
$legalClean = $legalFailed -eq 0 -and (Test-ReportContainsRow -Text $releaseText -Area "법무/상점" -Item "Steam/법무 준비 자동 QA" -Status "통과")
$modelClean = (Test-ReportContains -Text $modelText -Pattern "기본 모델\s*\|\s*통과") -and
    (Test-ReportContains -Text $modelText -Pattern "잘못된 모델명 기본값 전환\s*\|\s*통과")
$packageClean = (Test-ReportContainsRow -Text $releaseText -Area "패키지" -Item "Windows 실행 패키지 검증" -Status "통과") -and
    (Test-ReportContainsRow -Text $releaseText -Area "패키지" -Item "패키지 서버 실행 QA" -Status "통과") -and
    (Test-ReportContainsRow -Text $releaseText -Area "패키지" -Item "Steam 제출 패키지 검증" -Status "통과") -and
    (Test-ReportContainsRow -Text $releaseText -Area "Steamworks" -Item "SteamPipe 스테이징 패키지 검증" -Status "통과")
$trailerClean = Test-ReportContainsRow -Text $releaseText -Area "상점" -Item "트레일러 자산 QA" -Status "통과"
$buildCaptureTrailerClean = $trailerClean -and
    (Test-Path -LiteralPath $buildCaptureTrailerPath) -and
    (Test-Path -LiteralPath $buildCaptureShotListPath) -and
    (Test-Path -LiteralPath $trailerCaptionsPath) -and
    (Test-Path -LiteralPath $trailerWebVttPath)
$steamAssetsClean = Test-ReportContainsRow -Text $releaseText -Area "상점" -Item "Steam 그래픽/스크린샷 QA" -Status "통과"

$needsPlaytest = Test-ReportContainsRow -Text $externalText -Area "외부 플레이테스트" -Item "5명 이상 세션 증거" -Status "미완료"
$needsAccessibility = Test-ReportContainsRow -Text $externalText -Area "접근성" -Item "실제 접근성 QA 증거" -Status "미완료"
$needsArt = Test-ReportContainsRow -Text $externalText -Area "상업 아트" -Item "외부 아트 리뷰 증거" -Status "미완료"
$needsTrailer = Test-ReportContainsRow -Text $externalText -Area "트레일러" -Item "최종 트레일러 증거" -Status "미완료"
$needsLegal = Test-ReportContainsRow -Text $externalText -Area "법무/상점" -Item "Steam 관리자와 개인정보 최종 증거" -Status "미완료"

$rows = New-Object System.Collections.Generic.List[object]

$fiveTurnLoopClean = Test-ReportContains -Text $accessibilityText -Pattern "5문답 후 마무리 카드와 기록 저장 전체 루프.*통과"
Add-Score -Area "core_loop" -Item "핵심 진행과 대화 루프" -Score $(if ($contentClean -and $longSessionClean -and $fiveTurnLoopClean) { 4 } elseif ($contentClean -and $longSessionClean) { 3 } else { 2 }) -InternalBlocker $(-not ($contentClean -and $longSessionClean)) -ExternalDependency $needsPlaytest -Evidence "근거 답변 QA, 장시간 세션 QA, 5문답 풀루프 런타임 증거" -Limitation "외부 5명 플레이테스트가 아직 공식 증거로 들어오지 않았다." -NextAction "외부 참가자 세션 5개를 수집하고 P0/P1을 닫는다."
Add-Score -Area "writing" -Item "문장 톤과 몰입감" -Score $(if ($contentClean -and $uiCopyClean -and $storeCopyClean) { 4 } else { 2 }) -InternalBlocker $(-not ($contentClean -and $uiCopyClean -and $storeCopyClean)) -ExternalDependency $needsPlaytest -Evidence "근거 답변 QA, 상용 UI 문구 QA, 상점 문구 QA" -Limitation "실제 플레이어가 답변 톤을 어떻게 받아들이는지 아직 외부 증거가 없다." -NextAction "플레이테스트 피드백에서 반복 표현, 과한 설명, AI식 문장을 태그한다."
$readabilitySourceClean = (Test-ReportContains -Text $accessibilityText -Pattern "긴 대사 스크롤 갱신.*통과") -and
    (Test-ReportContains -Text $accessibilityText -Pattern "긴 대사 레이아웃 상태 감사.*통과")
$readabilityRuntimeClean = (Test-ReportContains -Text $accessibilityText -Pattern "긴 답변 스크롤.*통과") -and
    (Test-ReportContains -Text $accessibilityText -Pattern "긴 대사 레이아웃.*통과")
$readabilityLimitation = if ($readabilityRuntimeClean) { "최신 Unity 런타임 캡처는 통과했지만, 실제 확대/고대비/보조 입력 환경 검증은 아직 없다." } else { "최신 Unity 런타임 캡처가 부족하며, 실제 확대/고대비/보조 입력 환경 검증도 아직 없다." }
$readabilityNextAction = if ($readabilityRuntimeClean) { "외부 접근성 관찰 양식과 실제 입력/확대/고대비 증거를 수집한다." } else { "전체 런타임 스모크 후 외부 접근성 관찰 양식을 수집한다." }
Add-Score -Area "readability" -Item "긴 글 읽기와 화면 안정성" -Score $(if ($readabilityRuntimeClean) { 4 } elseif ($readabilitySourceClean) { 3 } else { 2 }) -InternalBlocker $(-not ($readabilitySourceClean -or $readabilityRuntimeClean)) -ExternalDependency $($needsAccessibility -or -not $readabilityRuntimeClean) -Evidence "접근성 자동 QA, 긴 답변 스크롤 캡처, 런타임 레이아웃 감사" -Limitation $readabilityLimitation -NextAction $readabilityNextAction
$controlsSourceClean = (Test-ReportContains -Text $accessibilityText -Pattern "Enter 직접 입력 전송.*통과") -and
    (Test-ReportContains -Text $accessibilityText -Pattern "열린 패널 단축키 충돌 방지.*통과") -and
    (Test-ReportContains -Text $accessibilityText -Pattern "의견창 키보드/패드 평가 조작.*통과")
$controlsRuntimeClean = (Test-ReportContains -Text $accessibilityText -Pattern "게임패드 A 버튼 첫 추천 질문 진행.*통과") -and
    (Test-ReportContains -Text $accessibilityText -Pattern "마무리 카드 키보드 문장 선택.*통과") -and
    (Test-ReportContains -Text $accessibilityText -Pattern "기록함 키보드 슬롯 선택과 삭제 확인.*통과")
$controlsLimitation = if ($controlsRuntimeClean) { "최신 Unity 런타임 단축키 TSV는 통과했지만, 키보드만 조작하는 실제 사용자 관찰 증거는 아직 없다." } else { "최신 Unity 런타임 단축키 TSV가 부족하며, 키보드만 조작하는 실제 사용자 관찰 증거도 아직 없다." }
$controlsNextAction = if ($controlsRuntimeClean) { "실제 사용자에게 키보드만으로 질문, 기록, 삭제, 설정 변경을 수행하게 하고 관찰 증거를 수집한다." } else { "전체 런타임 스모크 후 실제 사용자에게 키보드만으로 질문, 기록, 삭제, 설정 변경을 수행하게 한다." }
Add-Score -Area "controls" -Item "입력, 단축키, 패널 조작" -Score $(if ($controlsRuntimeClean) { 4 } elseif ($controlsSourceClean) { 3 } else { 2 }) -InternalBlocker $(-not ($controlsSourceClean -or $controlsRuntimeClean)) -ExternalDependency $($needsAccessibility -or -not $controlsRuntimeClean) -Evidence "접근성 자동 QA, 단축키/패널 충돌 런타임 상태 감사" -Limitation $controlsLimitation -NextAction $controlsNextAction
Add-Score -Area "trust_privacy" -Item "개인정보, 로컬 저장, 모델 실패 대응" -Score $(if ($safetyClean -and $legalClean -and $modelClean -and $uiCopyClean) { 4 } else { 2 }) -InternalBlocker $(-not ($safetyClean -and $legalClean -and $modelClean -and $uiCopyClean)) -ExternalDependency $needsLegal -Evidence "안전 QA, Steam/법무 자동 QA, 모델 설정 QA, 상용 UI 문구 QA" -Limitation "배포 주체 기준 최종 개인정보 문구와 Steam 관리자 증거는 아직 없다." -NextAction "Steam 관리자 체크리스트와 최종 개인정보 문구를 외부 증거 폴더에 넣는다."
Add-Score -Area "art_presentation" -Item "상점 첫인상과 화면 밝기" -Score $(if ($steamAssetsClean -and $visualClean) { 4 } else { 2 }) -InternalBlocker $(-not ($steamAssetsClean -and $visualClean)) -ExternalDependency $needsArt -Evidence "Steam 그래픽/스크린샷 QA, 시각 품질 QA" -Limitation "외부 아트 리뷰 승인 증거는 아직 없다." -NextAction "키아트, 캡슐, 스크린샷을 외부 아트 리뷰어에게 검토받는다."
Add-Score -Area "trailer_store" -Item "상점 문구와 트레일러 후보" -Score $(if ($buildCaptureTrailerClean -and $storeCopyClean) { 4 } elseif ($trailerClean -and $storeCopyClean) { 3 } else { 2 }) -InternalBlocker $(-not ($trailerClean -and $storeCopyClean)) -ExternalDependency $needsTrailer -Evidence "트레일러 자산 QA, 빌드 캡처 트레일러, 상점 문구 QA" -Limitation "현재 트레일러는 빌드 캡처 후보이며, 최종 외부 리뷰 증거가 없다." -NextAction "최종 트레일러 MP4, 자막, 리뷰 양식을 수집한다."
$stabilityAutomatedClean = $releaseAutomatedClean -and $packageClean
$stabilityLimitation = if ($stabilityAutomatedClean -and $pending -gt 0) {
    "자동 릴리즈 감사와 패키지 검증은 통과했지만, 외부 리뷰어 배정 같은 운영 보류가 남아 있다."
}
elseif ($stabilityAutomatedClean) {
    "자동 릴리즈 감사와 패키지 검증은 통과했지만, 외부 운영 환경에서의 최종 검증은 아직 남아 있다."
}
else {
    "패키지 또는 자동 검증이 최신 빌드와 완전히 일치하지 않는다."
}
$stabilityNextAction = if ($stabilityAutomatedClean) { "외부 증거 수집 후 최종 상업 출시 게이트를 다시 실행한다." } else { "Unity 빌드, 전체 런타임 스모크, 패키지 생성을 다시 실행해 보류 증거를 갱신한다." }
Add-Score -Area "stability_package" -Item "Windows 패키지와 Steam 제출 안정성" -Score $(if ($stabilityAutomatedClean) { 4 } else { 2 }) -InternalBlocker $(-not $stabilityAutomatedClean) -ExternalDependency $(-not $releaseClean) -Evidence "릴리즈 감사, Windows 패키지, 패키지 서버 QA, Steam 제출, SteamPipe 스테이징 검증" -Limitation $stabilityLimitation -NextAction $stabilityNextAction

$totalScore = ($rows | Measure-Object -Property score -Sum).Sum
$averageScore = if ($rows.Count -gt 0) { [math]::Round($totalScore / $rows.Count, 2) } else { 0 }
$minScore = if ($rows.Count -gt 0) { ($rows | Measure-Object -Property score -Minimum).Minimum } else { 0 }
$blockedCount = @($rows | Where-Object { $_.internal_blocker -eq "yes" -or $_.status -eq "차단" }).Count
$externalDependencyCount = @($rows | Where-Object { $_.external_dependency -eq "yes" }).Count
$heldCount = @($rows | Where-Object { $_.status -eq "보류" }).Count
$passedCount = @($rows | Where-Object { $_.status -eq "통과" }).Count
$reviewStatus = if ($blockedCount -gt 0) {
    "차단"
}
elseif ($averageScore -lt 4 -or $minScore -lt 4 -or $externalDependencyCount -gt 0) {
    "보류"
}
else {
    "통과"
}

$tsvLines = New-Object System.Collections.Generic.List[string]
$tsvLines.Add("area`titem`tscore`tstatus`tinternal_blocker`texternal_dependency`tevidence`tlimitation`tnext_action")
foreach ($row in $rows) {
    $tsvLines.Add((
        (Format-TsvCell $row.area),
        (Format-TsvCell $row.item),
        (Format-TsvCell ([string]$row.score)),
        (Format-TsvCell $row.status),
        (Format-TsvCell $row.internal_blocker),
        (Format-TsvCell $row.external_dependency),
        (Format-TsvCell $row.evidence),
        (Format-TsvCell $row.limitation),
        (Format-TsvCell $row.next_action)
    ) -join "`t")
}
Write-LinesWithRetry -Path $ScorecardPath -Lines $tsvLines

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 내부 품질 점수표")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 기준 가격: USD $PriceTargetUsd 이상")
$lines.Add("- 상태: $reviewStatus")
$lines.Add("- 평균 점수: $averageScore")
$lines.Add("- 최저 점수: $minScore")
$lines.Add("- 통과 영역: $passedCount")
$lines.Add("- 보류 영역: $heldCount")
$lines.Add("- 내부 차단: $blockedCount")
$lines.Add("- 외부 의존: $externalDependencyCount")
$lines.Add("- 점수표 파일: $ScorecardPath")
$lines.Add("")
$lines.Add("이 문서는 내부 자동 QA와 휴리스틱 기준으로 만든 보조 판단이다. 공식 외부 리뷰 점수표인 Build/ReleaseEvidence/COMMERCIAL_QUALITY_SCORECARD.tsv를 대체하지 않는다.")
$lines.Add("")
$lines.Add("## 영역별 점수")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 점수 | 상태 | 내부 차단 | 외부 의존 | 근거 | 한계 | 다음 행동 |")
$lines.Add("| --- | --- | ---: | --- | --- | --- | --- | --- | --- |")
foreach ($row in $rows) {
    $lines.Add("| $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.item) | $($row.score) | $(Escape-MarkdownCell $row.status) | $(Escape-MarkdownCell $row.internal_blocker) | $(Escape-MarkdownCell $row.external_dependency) | $(Escape-MarkdownCell $row.evidence) | $(Escape-MarkdownCell $row.limitation) | $(Escape-MarkdownCell $row.next_action) |")
}
$lines.Add("")
$lines.Add("## 판정")
$lines.Add("")
if ($blockedCount -gt 0) {
    $lines.Add("- 내부 자동 기준에서 차단 항목이 있다. 외부 검증 전에 해당 영역을 먼저 수정한다.")
}
elseif ($externalDependencyCount -gt 0) {
    $lines.Add("- 내부 자동 기준은 출시 후보까지 올라왔지만, 외부 증거가 부족해 최종 유료 출시 판정은 보류한다.")
}
else {
    $lines.Add("- 내부 자동 기준과 외부 의존 기준 모두 통과했다. 공식 상업 출시 게이트를 재실행한다.")
}
$lines.Add("- 공식 품질 점수표는 외부 리뷰어, 증거 경로, 차단 여부를 포함해 별도로 작성해야 한다.")

Write-LinesWithRetry -Path $ReviewPath -Lines $lines

Write-Host "Internal quality scorecard written: $ScorecardPath"
Write-Host "Internal quality review written: $ReviewPath"
Write-Host "Internal quality status: $reviewStatus, average: $averageScore, minimum: $minScore, internal blockers: $blockedCount, external dependencies: $externalDependencyCount"
