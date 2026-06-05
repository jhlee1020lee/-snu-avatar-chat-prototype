param(
    [string]$SmokeRoot,
    [string]$SourcePath,
    [string]$OutputPath,
    [switch]$StaticOnly
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Assert-Path {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required path: $Path"
    }
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

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-ImageMetrics {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path
    $bitmap = [System.Drawing.Bitmap]::new($item.FullName)
    try {
        $sampleStep = 12
        $sum = 0.0
        $sum2 = 0.0
        $count = 0
        $dark = 0

        for ($y = 0; $y -lt $bitmap.Height; $y += $sampleStep) {
            for ($x = 0; $x -lt $bitmap.Width; $x += $sampleStep) {
                $color = $bitmap.GetPixel($x, $y)
                $luminance = 0.2126 * $color.R + 0.7152 * $color.G + 0.0722 * $color.B
                $sum += $luminance
                $sum2 += $luminance * $luminance
                $count++
                if ($luminance -lt 35) {
                    $dark++
                }
            }
        }

        $average = $sum / [math]::Max(1, $count)
        $variance = ($sum2 / [math]::Max(1, $count)) - ($average * $average)
        if ($variance -lt 0) {
            $variance = 0
        }

        [pscustomobject]@{
            Name = $item.Name
            Width = $bitmap.Width
            Height = $bitmap.Height
            Bytes = $item.Length
            AverageLuminance = [math]::Round($average, 2)
            LuminanceStdDev = [math]::Round([math]::Sqrt($variance), 2)
            DarkPixelPct = [math]::Round(100 * $dark / [math]::Max(1, $count), 3)
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

function Test-SmokeImage {
    param(
        [string]$Name,
        [string]$Purpose,
        [int64]$MinBytes = 500000,
        [double]$MinAverageLuminance = 45,
        [double]$MinStdDev = 14,
        [double]$MaxDarkPixelPct = 55
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    try {
        $metrics = Get-ImageMetrics -Path $path
        if ($metrics.Width -ne 1920 -or $metrics.Height -ne 1080) {
            Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence "$Name 해상도 $($metrics.Width)x$($metrics.Height)"
            return
        }
        if ($metrics.Bytes -lt $MinBytes) {
            Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence "$Name 파일 크기 $($metrics.Bytes) bytes"
            return
        }
        if ($metrics.AverageLuminance -lt $MinAverageLuminance) {
            Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence "$Name 평균 밝기 $($metrics.AverageLuminance)"
            return
        }
        if ($metrics.LuminanceStdDev -lt $MinStdDev) {
            Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence "$Name 명암 변화 $($metrics.LuminanceStdDev)"
            return
        }
        if ($metrics.DarkPixelPct -gt $MaxDarkPixelPct) {
            Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence "$Name 어두운 픽셀 $($metrics.DarkPixelPct)%"
            return
        }

        Add-Pass -Area "스모크 캡처" -Item $Purpose -Evidence "$Name $($metrics.Width)x$($metrics.Height), 밝기 $($metrics.AverageLuminance), 명암 $($metrics.LuminanceStdDev)"
    }
    catch {
        Add-Fail -Area "스모크 캡처" -Item $Purpose -Evidence $_.Exception.Message
    }
}

function Test-SmokeReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "`tPASS(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name PASS 항목 없음"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 통과"
}

function Test-ForegroundClutterReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tlead-slips-visible-count`t`t0`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 후속 질문 쪽지 표시됨"
        return
    }
    if ($content -notmatch "state`thotspot-labels-visible-count`t`t0`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 핫스팟 라벨 표시됨"
        return
    }
    if ($content -notmatch "state`thotspots-visible-count`t`t0`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 핫스팟 점 표시됨"
        return
    }
    if ($content -notmatch "`tPASS(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name PASS 항목 없음"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 전면 패널 배경 단서 숨김"
}

function Test-AccessibilitySettingsStateReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`treduced-motion`t`ton`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 움직임 줄임 on 누락"
        return
    }
    if ($content -notmatch "state`treduced-motion-label`t`t움직임 줄임 켜짐`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 움직임 줄임 라벨 누락"
        return
    }
    if ($content -notmatch "state`thigh-contrast-label`t`t읽기 쉬움 켜짐`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 읽기 쉬움 라벨 누락"
        return
    }
    if ($content -notmatch "state`tsound-label`t`t소리 기본`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 소리 라벨 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 접근성 토글 상태 라벨 확인"
}

function Test-SoundSettingsReport {
    param(
        [string]$Name,
        [string]$Purpose,
        [string]$ExpectedLevel,
        [string]$ExpectedLabel,
        [string]$ExpectedAmbience
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tsound-level`t`t$ExpectedLevel`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 소리 단계 $ExpectedLevel 누락"
        return
    }
    if ($content -notmatch "state`tsound-button-label`t`t$ExpectedLabel`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 소리 버튼 라벨 $ExpectedLabel 누락"
        return
    }
    if ($content -notmatch "state`taudio-clips`t`tready`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 오디오 클립 준비 상태 누락"
        return
    }
    if ($content -notmatch "state`tambience-playing`t`t$ExpectedAmbience`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 앰비언스 상태 $ExpectedAmbience 누락"
        return
    }
    if ($content -notmatch "expect`taudio-settings`tconsistent`tconsistent`tPASS") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 오디오 설정 일관성 PASS 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name $ExpectedLabel, 앰비언스 $ExpectedAmbience 확인"
}

function Test-AnswerSourceProgressReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tanswer-source`t`tlocal-only`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name answer-source local-only 누락"
        return
    }
    if ($content -notmatch "state`tprogress-label`t`t1/5 질문 · 내장 답변`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 진행도/답변 출처 라벨 누락"
        return
    }
    if ($content -notmatch "state`tfinish-button`t`tdisabled`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 전 마무리 잠금 누락"
        return
    }
    if ($content -notmatch "state`tfinish-button-label`t`t5문답 후`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 전 마무리 안내 라벨 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 진행도, 내장 답변 출처, 5문답 전 마무리 잠금/라벨 표시"
}

function Test-FiveTurnPlaythroughReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tconversation-turns`t`t5`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 완료 상태 누락"
        return
    }
    if ($content -notmatch "state`tfinish-button`t`tenabled`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 마무리 버튼 활성 상태 누락"
        return
    }
    if ($content -notmatch "state`tfinish-button-label`t`t끝내기`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 후 끝내기 라벨 누락"
        return
    }
    if ($content -notmatch "state`tprogress-label`t`t마무리 가능 · 내장 답변`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 마무리 가능 진행도 라벨 누락"
        return
    }
    if ($content -notmatch "expect`trecords`topen`topen`tPASS") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 기록 저장 후 기록함 열림 증거 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 완료, 마무리 가능, 기록 저장 확인"
}

function Test-FeedbackNoteRequirementReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tfeedback-status`t`t더 다듬기, 조금 아쉬움, 문제 있음을 고른 경우에는 수정할 근거를 짧게 남겨 주세요\.`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 수정 근거 요구 문구 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-note-length`t`t0`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 빈 메모 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-commercial-readiness`t`t부족`tINFO" -or $content -notmatch "state`tfeedback-issue-severity`t`tP1`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 낮은 5달러 기준 또는 P1 이슈 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-issue-severity-label`t`t진행 방해`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 플레이테스트 P1 설명 라벨 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 낮은 평가/P1 이슈에서 빈 메모 저장 차단 확인"
}

function Test-FeedbackCompleteSessionRequirementReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tfeedback-status`t`t좋음, 충분함, 문제 없음은 5문답 완료 뒤에 저장해 주세요\. 중도 문제는 단계와 메모로 저장할 수 있습니다\.`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 완료 요구 문구 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-completed-five-turn-session`t`tfalse`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 미완주 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-positive-quality-ready`t`tfalse`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 긍정 근거 미준비 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-ending-record-saved`t`tfalse`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 마무리 기록 미저장 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-issue-severity`t`t없음`tINFO" -or $content -notmatch "state`tfeedback-issue-severity-label`t`t문제 없음`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 문제 없음 선택 라벨 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 긍정 평가가 5문답 완료 전 저장되지 않음"
}

function Test-FeedbackEndingRecordRequirementReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`tfeedback-status`t`t좋음, 충분함, 문제 없음은 마무리 기록을 저장한 뒤에 품질 근거로 남길 수 있습니다\.`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 마무리 기록 요구 문구 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-completed-five-turn-session`t`ttrue`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 완료 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-ending-record-saved`t`tfalse`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 마무리 기록 미저장 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-positive-quality-ready`t`tfalse`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 긍정 근거 미준비 상태 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-evidence-tier`t`tending-record-needed`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name ending-record-needed 증거 등급 누락"
        return
    }
    if ($content -notmatch "state`tfeedback-rating`t`t좋음`tINFO" -or $content -notmatch "state`tfeedback-commercial-readiness`t`t충분`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 긍정 평가/충분함 선택 상태 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 5문답 후에도 마무리 기록 없이는 긍정 품질 근거 저장 차단"
}

function Test-RecordArchiveMetadataReport {
    param(
        [string]$Name,
        [string]$Purpose
    )

    $path = Join-Path $SmokeRoot $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "누락: $Name"
        return
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match "`tFAIL(\r?\n|$)") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 실패 항목 있음"
        return
    }
    if ($content -notmatch "state`trecord-archive-first-label`t`t[^\r\n]*문답[^\r\n]*장면[^\r\n]*`tINFO") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 기록 목록 메타데이터 누락"
        return
    }
    if ($content -notmatch "state`trecord-delete-cancel`t취소`t취소`tPASS") {
        Add-Fail -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 기록 삭제 취소 버튼 누락"
        return
    }

    Add-Pass -Area "런타임 상태 QA" -Item $Purpose -Evidence "$Name 기록 목록 메타데이터와 삭제 취소 확인"
}

function Test-SourcePattern {
    param(
        [string]$Item,
        [string]$Pattern,
        [string]$Path
    )

    $text = $script:sourceText
    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        if (-not (Test-Path -LiteralPath $Path)) {
            Add-Fail -Area "키보드/설정 코드" -Item $Item -Evidence "소스 없음: $Path"
            return
        }
        $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }

    if ($text -match $Pattern) {
        Add-Pass -Area "키보드/설정 코드" -Item $Item -Evidence "패턴 확인: $Pattern"
    }
    else {
        Add-Fail -Area "키보드/설정 코드" -Item $Item -Evidence "패턴 누락: $Pattern"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($SmokeRoot)) {
    $SmokeRoot = Join-Path $projectRoot "Build\release-smoke"
}
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path $projectRoot "Assets\Scripts\AvatarChatApp.cs"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\ACCESSIBILITY_AUTOMATION_QA.md"
}

Assert-Path $SmokeRoot
Assert-Path $SourcePath

$results = New-Object System.Collections.Generic.List[object]
$sourceText = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8

Test-SourcePattern -Item "Enter 직접 입력 전송" -Pattern "KeyCode\.Return|KeyCode\.KeypadEnter"
Test-SourcePattern -Item "Shift+Enter 줄바꿈 유지" -Pattern "KeyCode\.LeftShift|KeyCode\.RightShift"
Test-SourcePattern -Item "Esc 닫기/일시정지" -Pattern "KeyCode\.Escape"
Test-SourcePattern -Item "추천 질문 1번" -Pattern "KeyCode\.Alpha1|KeyCode\.Keypad1"
Test-SourcePattern -Item "추천 질문 2번" -Pattern "KeyCode\.Alpha2|KeyCode\.Keypad2"
Test-SourcePattern -Item "추천 질문 3번" -Pattern "KeyCode\.Alpha3|KeyCode\.Keypad3"
Test-SourcePattern -Item "질문폰 열린 상태 숫자 탭 선택" -Pattern "SelectNoteTabShortcut"
Test-SourcePattern -Item "질문폰 좌우 탭 이동" -Pattern "KeyCode\.LeftArrow|KeyCode\.RightArrow"
Test-SourcePattern -Item "질문폰 단축키" -Pattern "KeyCode\.Q"
Test-SourcePattern -Item "기억장 단축키" -Pattern "KeyCode\.M"
Test-SourcePattern -Item "기억장 카드 질문 조작" -Pattern "SubmitMemoryCardQuestion|memory-card-action|memoryCardButtons"
Test-SourcePattern -Item "기억장 키보드/패드 카드 선택" -Pattern "HandleMemoryBookShortcuts|selected-memory-card-index|memory-book-shortcut-action"
Test-SourcePattern -Item "기록함 단축키" -Pattern "KeyCode\.R"
Test-SourcePattern -Item "기록함 키보드/패드 슬롯 삭제" -Pattern "HandleRecordArchiveShortcuts|selected-record-archive-index|record-archive-shortcut-action"
Test-SourcePattern -Item "설정 단축키" -Pattern "KeyCode\.S"
Test-SourcePattern -Item "정보 단축키" -Pattern "KeyCode\.I"
Test-SourcePattern -Item "전체 화면 단축키" -Pattern "KeyCode\.F"
Test-SourcePattern -Item "글자 확대 단축키" -Pattern "KeyCode\.Equals|KeyCode\.Plus|KeyCode\.KeypadPlus"
Test-SourcePattern -Item "글자 축소 단축키" -Pattern "KeyCode\.Minus|KeyCode\.Underscore|KeyCode\.KeypadMinus"
Test-SourcePattern -Item "설정 단축키 상태 감사" -Pattern "RunShortcutAction\(""settings""\)|KeyCode\.S"
Test-SourcePattern -Item "읽기 영역 키보드 넘김" -Pattern "TryAdvanceDialoguePage|KeyCode\.PageDown|KeyCode\.DownArrow"
Test-SourcePattern -Item "기록함 방향키 스크롤" -Pattern "KeyCode\.UpArrow|KeyCode\.DownArrow"
Test-SourcePattern -Item "읽기 영역 처음/끝 이동" -Pattern "KeyCode\.Home|KeyCode\.End"
Test-SourcePattern -Item "활성 읽기 영역 선택" -Pattern "GetActiveKeyboardScrollRect"
Test-SourcePattern -Item "열린 패널 단축키 충돌 방지" -Pattern "HandleOpenPanelShortcutToggles|HasModalShortcutBlocker"
Test-SourcePattern -Item "패널 진입 선택 포커스" -Pattern "(?s)SelectFirstInteractable.*SetSelectedGameObject"
Test-SourcePattern -Item "패널 닫힘 선택 포커스 해제" -Pattern "(?s)ClearSelectionIfInside.*currentSelectedGameObject.*SetSelectedGameObject"
Test-SourcePattern -Item "파괴적 확인 기본 취소 포커스" -Pattern "(?s)Fresh Start Cancel Button.*Fresh Start Confirm Button"
Test-SourcePattern -Item "게임패드 기본 조작" -Pattern "HandleGamepadShortcuts|JoystickButton0"
Test-SourcePattern -Item "게임패드 핵심 질문 진행" -Pattern "TrySubmitLeadShortcut|primary-question"
Test-SourcePattern -Item "게임패드 추천 질문 선택" -Pattern "CycleSelectedLead|selected-lead-index"
Test-SourcePattern -Item "게임패드 취소/닫기" -Pattern "JoystickButton1|IsCancelKeyDown"
Test-SourcePattern -Item "게임패드 패널 열기" -Pattern "JoystickButton2|JoystickButton3|JoystickButton6|JoystickButton7"
Test-SourcePattern -Item "마무리 카드 키보드/패드 조작" -Pattern "HandleClosingCardShortcuts|selected-closing-index|closing-shortcut-action"
Test-SourcePattern -Item "게임패드 상태 감사 확장" -Pattern "note-tab|dialogue-size-level|Run-GamepadShortcutGuard"
Test-SourcePattern -Item "런타임 단축키 상태 감사" -Pattern "RunSmokeKeyPress|WriteSmokeStateReport"
Test-SourcePattern -Item "긴 대사 페이지 넘김" -Pattern "BuildDialoguePages|TryAdvanceDialoguePage|AdvanceDialoguePageOrStory"
Test-SourcePattern -Item "긴 대사 레이아웃 상태 감사" -Pattern "--smoke-expect-dialogue-scrollable|AppendSmokeDialogueLayout"
Test-SourcePattern -Item "캐릭터 비율 상태 감사" -Pattern "--smoke-expect-avatar-natural|AppendSmokeAvatarLayout"
Test-SourcePattern -Item "생각 중 문구 상태 감사" -Pattern "--smoke-expect-thinking-copy|AppendSmokeThinkingCopy"
Test-SourcePattern -Item "기록함 스크롤 갱신" -Pattern "RefreshRecordArchiveScroll"
Test-SourcePattern -Item "질문폰 탭 전환" -Pattern "ShowNoteTab"
Test-SourcePattern -Item "질문폰 근거 탭" -Pattern "BuildEvidenceNoteText"
Test-SourcePattern -Item "질문폰 지난 말 탭" -Pattern "BuildHistoryNoteText"
Test-SourcePattern -Item "질문폰 진행 길잡이" -Pattern "Question Phone Session Guide|BuildQuestionPhoneGuideText|question-guide"
Test-SourcePattern -Item "이야기 모드 진행 버튼" -Pattern "Story Mode Next Button|RequestStoryModeAdvance|story-controls"
Test-SourcePattern -Item "이야기 모드 키보드/패드 조작" -Pattern "HandleStoryModeShortcuts|KeyCode\.Space|JoystickButton0|story-shortcut-action"
Test-SourcePattern -Item "기록 삭제 취소 버튼" -Pattern "Record Archive Cancel Delete Button|CancelPendingRecordDelete|record-delete-cancel"
Test-SourcePattern -Item "정보 화면 서버 상태 감사" -Pattern "ServerStatusIdleText|about-server-status|server-status\.tsv"
Test-SourcePattern -Item "정보 화면 의견 폴더 버튼" -Pattern "About Feedback Folder Button|OpenPlaytestFeedbackFolder|FeedbackNotes"
Test-SourcePattern -Item "움직임 줄임 저장" -Pattern "SetReducedMotionEnabled|ReducedMotionKey"
Test-SourcePattern -Item "로컬 답변 전용 저장" -Pattern "SetLocalAnswerOnlyEnabled|LocalAnswerOnlyKey"
Test-SourcePattern -Item "로컬 답변 서버 우회" -Pattern "usedLocalAnswerOnly|서버 전송 없이"
Test-SourcePattern -Item "로컬 답변 마이크 전사 차단" -Pattern "마이크 전사는 꺼져"
Test-SourcePattern -Item "글자 크기 저장" -Pattern "SetDialogueSizeLevel|DialogueSizeKey"
Test-SourcePattern -Item "5문답 풀루프 스모크" -Pattern "--smoke-submit-questions|SmokeSubmitQuestionSequence"
Test-SourcePattern -Item "5문답 전 마무리 잠금" -Pattern "IsCompletedFiveTurnSession\(\)|finish-button"
Test-SourcePattern -Item "5문답 전 마무리 안내 라벨" -Pattern "GetCompletionActionLabel|5문답 후|finish-button-label"
Test-SourcePattern -Item "의견 낮은 평가 메모 요구" -Pattern "ShouldRequirePlaytestFeedbackNote|더 다듬기, 조금 아쉬움, 문제 있음"
Test-SourcePattern -Item "의견 긍정 평가 5문답 요구" -Pattern "ShouldRequireCompletedPlaytestSession|좋음, 충분함, 문제 없음"
Test-SourcePattern -Item "의견 긍정 평가 마무리 기록 요구" -Pattern "ShouldRequireEndingRecordForPositiveEvidence|마무리 기록을 저장한 뒤|endingRecordSavedThisSession"
Test-SourcePattern -Item "의견창 플레이어 표현" -Pattern 'commercialLabels\s*=\s*\{\s*"더 다듬기",\s*"조금 아쉬움",\s*"충분함"\s*\}'
Test-SourcePattern -Item "의견 문제 단계 설명 라벨" -Pattern "사소한 문제|진행 방해|진행 불가"
Test-SourcePattern -Item "의견창 키보드/패드 평가 조작" -Pattern "HandlePlaytestFeedbackShortcuts|feedback-shortcut-action|GetPlaytestFeedbackGroupLabel"
Test-SourcePattern -Item "의견 구조화 품질 영역" -Pattern "qualityFocusArea|GetPlaytestQualityAreas|feedback-quality-focus"
Test-SourcePattern -Item "의견 위험 태그와 증거 등급" -Pattern "riskTags|evidenceTier|feedback-evidence-tier"
Test-SourcePattern -Item "의견 점수표 마무리 기록 반영" -Path (Join-Path $PSScriptRoot "ExportFeedbackToCommercialQualityScorecard.ps1") -Pattern "ending-record-needed|ending-record-missing|마무리 기록 없음"
Test-SourcePattern -Item "의견 마무리 기록 런타임 스모크" -Path (Join-Path $PSScriptRoot "RunReleaseSmoke.ps1") -Pattern "playtest-feedback-require-ending-record\.tsv|ending-record-needed|마무리 기록을 저장한 뒤"
Test-SourcePattern -Item "기록함 목록 세션 메타데이터" -Pattern "ExtractRecordMetaLabel|record-archive-first-label|문답.*장면"
Test-SourcePattern -Item "기록함 미리보기 본문 크기" -Pattern "RecordArchivePreviewBodyFontSize\s*=\s*18"
Test-SourcePattern -Item "기록함 미리보기 잉크 대비" -Pattern "RecordArchivePreviewBodyColor\s*=\s*new Color32\(24,\s*32,\s*46,\s*255\)"
Test-SourcePattern -Item "기록함 미리보기 줄간격" -Pattern "RecordArchivePreviewBodyLineSpacing\s*=\s*1\.16f"
Test-SourcePattern -Item "첫 화면 정보 버튼" -Pattern "startAboutButton|Start About Button|start-about-visible"
Test-SourcePattern -Item "첫 화면 설정 버튼" -Pattern "startSettingsButton|Settings From Start Button|start-settings-visible"
Test-SourcePattern -Item "첫 화면 유지 스모크" -Pattern "--smoke-keep-start"
Test-SourcePattern -Item "소리 설정 런타임 감사" -Pattern "--smoke-sound-level|AppendSmokeAudioState|audio-settings"
Test-SourcePattern -Item "답변 읽기 집중 상태 감사" -Pattern "--smoke-expect-dialogue-reading-focus|AppendSmokeDialogueReadingFocus|dialogue-reading-followup-dock"

if ($StaticOnly) {
    Add-Result -Area "런타임 상태 QA" -Item "Unity 런타임 스모크 증거" -Status "보류" -Evidence "StaticOnly 모드: Unity 창을 띄우지 않기 위해 캡처/TSV 런타임 검증을 건너뜀"
}
else {
    Test-SmokeImage -Name "accessibility-settings.png" -Purpose "큰 글자, 소리, 화면 모드, 움직임 줄임 설정 화면"
    Test-SmokeImage -Name "local-answer-only.png" -Purpose "로컬 답변 전용 대화 화면" -MinBytes 900000
    Test-SmokeImage -Name "settings-shortcut-open.png" -Purpose "설정 단축키로 열린 설정 화면"
    Test-SmokeImage -Name "long-dialogue.png" -Purpose "긴 답변 클릭 넘김 캡처" -MinBytes 900000
    Test-SmokeImage -Name "hotspot-preview.png" -Purpose "핫스팟 질문 확인 쪽지" -MinBytes 900000
    Test-SmokeImage -Name "question-phone.png" -Purpose "질문폰 키보드 대상 화면" -MinBytes 900000
    Test-SmokeImage -Name "question-phone-evidence.png" -Purpose "질문폰 근거 탭 화면" -MinBytes 900000
    Test-SmokeImage -Name "question-phone-history.png" -Purpose "질문폰 지난 말 탭 화면" -MinBytes 900000
    Test-SmokeImage -Name "closing-card.png" -Purpose "마무리 카드 저장 흐름 화면"
    Test-SmokeImage -Name "ending-archive.png" -Purpose "기록함 읽기 화면"
    Test-SmokeImage -Name "record-delete-confirm.png" -Purpose "기록 삭제 확인 화면"
    Test-SmokeImage -Name "data-policy-delete-prompt.png" -Purpose "저장 데이터 삭제 확인 화면"
    Test-SmokeReport -Name "server-status.tsv" -Purpose "정보 화면 서버 상태 안정 문구"
    Test-SmokeReport -Name "story-mode.tsv" -Purpose "이야기 모드 진행 버튼 상태"
    Test-SmokeReport -Name "story-mode-shortcuts.tsv" -Purpose "이야기 모드 키보드 다음 장면 조작"
    Test-SmokeReport -Name "memory-card-question.tsv" -Purpose "기억장 카드 질문 시작 조작"
    Test-SmokeReport -Name "memory-book-shortcuts.tsv" -Purpose "기억장 키보드 카드 선택과 질문 시작"
    Test-SmokeReport -Name "record-archive-shortcuts.tsv" -Purpose "기록함 키보드 슬롯 선택과 삭제 확인"
    Test-SmokeReport -Name "dialogue-reading-focus.tsv" -Purpose "답변 읽기 중 장면 핫스팟 숨김"
    Test-SmokeReport -Name "panel-shortcut-archive-blocks-question.tsv" -Purpose "기록함 열린 상태에서 질문폰 단축키 차단"
    Test-SmokeReport -Name "panel-shortcut-settings-blocks-question.tsv" -Purpose "설정 열린 상태에서 질문폰 단축키 차단"
    Test-SmokeReport -Name "panel-shortcut-question-blocks-memory.tsv" -Purpose "질문폰 열린 상태에서 기억장 단축키 차단"
    Test-SmokeReport -Name "panel-shortcut-memory-blocks-settings.tsv" -Purpose "기억장 열린 상태에서 설정 단축키 차단"
    Test-SmokeReport -Name "panel-shortcut-archive-self-closes.tsv" -Purpose "기록함 단축키 재입력 닫기"
    Test-SmokeReport -Name "shortcut-settings-open.tsv" -Purpose "설정 단축키 열기 상태"
    Test-SmokeReport -Name "gamepad-shortcut-question.tsv" -Purpose "게임패드 X 버튼 질문폰 열기"
    Test-SmokeReport -Name "gamepad-shortcut-cancel.tsv" -Purpose "게임패드 B 버튼 열린 패널 닫기"
    Test-SmokeReport -Name "gamepad-shortcut-memory.tsv" -Purpose "게임패드 Y 버튼 기억장 열기"
    Test-SmokeReport -Name "gamepad-shortcut-records.tsv" -Purpose "게임패드 Back 버튼 기록함 열기"
    Test-SmokeReport -Name "gamepad-shortcut-settings.tsv" -Purpose "게임패드 Menu 버튼 설정 열기"
    Test-SmokeReport -Name "gamepad-shortcut-note-tab-next.tsv" -Purpose "게임패드 RB 버튼 질문폰 탭 전환"
    Test-SmokeReport -Name "gamepad-shortcut-lead-next.tsv" -Purpose "게임패드 RB 버튼 추천 질문 선택"
    Test-SmokeReport -Name "gamepad-shortcut-text-up.tsv" -Purpose "게임패드 RB 버튼 글자 크기 키우기"
    Test-SmokeReport -Name "gamepad-shortcut-primary-question.tsv" -Purpose "게임패드 A 버튼 첫 추천 질문 진행"
    Test-SmokeReport -Name "gamepad-shortcut-selected-question.tsv" -Purpose "게임패드 RB 후 A 버튼 선택 질문 진행"
    Test-SmokeReport -Name "closing-card-shortcuts.tsv" -Purpose "마무리 카드 키보드 문장 선택"
    Test-SmokeReport -Name "start-utility-visible.tsv" -Purpose "첫 화면 설정/정보 버튼 표시 상태"
    Test-SmokeReport -Name "start-info-access.tsv" -Purpose "첫 화면 정보 버튼 실행 상태"
    Test-SmokeReport -Name "long-dialogue-layout.tsv" -Purpose "긴 답변 페이지 넘김 런타임 레이아웃"
    Test-SmokeReport -Name "avatar-layout.tsv" -Purpose "캐릭터 비율 런타임 레이아웃"
    Test-AccessibilitySettingsStateReport -Name "accessibility-settings.tsv" -Purpose "설정 토글 상태 라벨"
    Test-SoundSettingsReport -Name "sound-default.tsv" -Purpose "소리 기본 설정과 방 분위기음" -ExpectedLevel "2" -ExpectedLabel "소리 기본" -ExpectedAmbience "playing"
    Test-SoundSettingsReport -Name "sound-small.tsv" -Purpose "소리 작게 설정과 방 분위기음" -ExpectedLevel "1" -ExpectedLabel "소리 작게" -ExpectedAmbience "playing"
    Test-SoundSettingsReport -Name "sound-off.tsv" -Purpose "소리 끔 설정과 방 분위기음 정지" -ExpectedLevel "0" -ExpectedLabel "소리 끔" -ExpectedAmbience "stopped"
    Test-ForegroundClutterReport -Name "accessibility-settings.tsv" -Purpose "설정 중 배경 질문/라벨/핫스팟 숨김"
    Test-ForegroundClutterReport -Name "foreground-clutter-hotspot.tsv" -Purpose "단서 미리보기 중 배경 질문/라벨/핫스팟 숨김"
    Test-ForegroundClutterReport -Name "foreground-clutter-memory.tsv" -Purpose "기억장 중 배경 질문/라벨/핫스팟 숨김"
    Test-SmokeReport -Name "thinking-copy.tsv" -Purpose "생각 중 짧은 문구 런타임 상태"
    Test-AnswerSourceProgressReport -Name "answer-source-progress.tsv" -Purpose "진행도와 답변 출처 런타임 표시"
    Test-FiveTurnPlaythroughReport -Name "five-turn-playthrough.tsv" -Purpose "5문답 후 마무리 카드와 기록 저장 전체 루프"
    Test-FeedbackNoteRequirementReport -Name "playtest-feedback-require-note.tsv" -Purpose "낮은 평가와 P1 이슈의 빈 메모 저장 차단"
    Test-FeedbackCompleteSessionRequirementReport -Name "playtest-feedback-require-complete-session.tsv" -Purpose "긍정 평가의 5문답 미완료 저장 차단"
    Test-FeedbackEndingRecordRequirementReport -Name "playtest-feedback-require-ending-record.tsv" -Purpose "긍정 평가의 마무리 기록 미저장 저장 차단"
    Test-SmokeReport -Name "playtest-feedback-shortcuts.tsv" -Purpose "의견창 키보드 평가 선택과 저장 차단"
    Test-RecordArchiveMetadataReport -Name "record-delete-confirm.tsv" -Purpose "기록함 목록의 문답/장면 메타데이터와 삭제 취소"
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$passed = @($results | Where-Object { $_.Status -eq "통과" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count
$pending = @($results | Where-Object { $_.Status -eq "보류" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 접근성 자동 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 스모크 캡처: $SmokeRoot")
$lines.Add("- 소스: $SourcePath")
$lines.Add("- 자동 통과: $passed")
$lines.Add("- 자동 실패: $failed")
$lines.Add("- 보류: $pending")
$lines.Add("")
$lines.Add("이 자동 QA는 키보드 단축키 코드와 접근성 관련 스모크 캡처를 확인한다. 실제 스크린리더, Windows 고대비, 화면 확대, 보조 입력 장치 테스트를 대체하지 않는다.")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Area) | $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) |")
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failed -gt 0) {
    throw "Accessibility automation QA failed with $failed issue(s). Report: $OutputPath"
}

Write-Host "Accessibility automation QA passed: $OutputPath"
