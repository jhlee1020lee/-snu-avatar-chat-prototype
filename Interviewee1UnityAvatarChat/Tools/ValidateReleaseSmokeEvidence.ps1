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

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Read-SmokeRows {
    param([string]$Path)

    return @(Import-Csv -LiteralPath $Path -Delimiter "`t" -Encoding UTF8)
}

function Get-SmokeRow {
    param(
        [object[]]$Rows,
        [string]$Type,
        [string]$Name
    )

    return @($Rows | Where-Object { $_.type -eq $Type -and $_.name -eq $Name } | Select-Object -First 1)
}

function Test-SmokeRow {
    param(
        [string]$FileName,
        [object[]]$Rows,
        [string]$Type,
        [string]$Name,
        [string]$Actual,
        [string]$Result
    )

    $row = Get-SmokeRow -Rows $Rows -Type $Type -Name $Name
    if ($row.Count -eq 0) {
        return "missing $Type/$Name"
    }
    if ($null -ne $Actual -and [string]$row[0].actual -ne $Actual) {
        return "$Type/$Name actual '$($row[0].actual)' != '$Actual'"
    }
    if ($null -ne $Result -and [string]$row[0].result -ne $Result) {
        return "$Type/$Name result '$($row[0].result)' != '$Result'"
    }

    return ""
}

function Test-CommonSmokeEvidence {
    param(
        [string]$FileName,
        [string]$CurrentBuildId
    )

    $path = Join-Path $smokeRoot $FileName
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Fail -Area "공통 증거" -Item $FileName -Evidence "파일 누락: $path"
        return $null
    }

    $item = Get-Item -LiteralPath $path
    if ($item.Length -lt 1000) {
        Add-Fail -Area "공통 증거" -Item $FileName -Evidence "파일이 너무 작음: $($item.Length) bytes"
        return $null
    }

    $rows = Read-SmokeRows -Path $path
    if ($rows.Count -lt 20) {
        Add-Fail -Area "공통 증거" -Item $FileName -Evidence "TSV 행 부족: $($rows.Count)"
        return $null
    }

    $failRows = @($rows | Where-Object { $_.result -eq "FAIL" })
    if ($failRows.Count -gt 0) {
        $examples = @($failRows | Select-Object -First 3 | ForEach-Object { "$($_.type)/$($_.name)" }) -join ", "
        Add-Fail -Area "공통 증거" -Item $FileName -Evidence "실패 행 포함: $examples"
        return $rows
    }

    $checks = @(
        @{ Type = "state"; Name = "game-title"; Actual = "겉!=속"; Result = "INFO" },
        @{ Type = "state"; Name = "product-name"; Actual = "겉!=속"; Result = "INFO" },
        @{ Type = "state"; Name = "build-id"; Actual = $CurrentBuildId; Result = "INFO" },
        @{ Type = "state"; Name = "ui-font"; Actual = "Paperlogy-4Regular / Paperlogy-6SemiBold / Paperlogy-7Bold"; Result = "INFO" }
    )

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($check in $checks) {
        $error = Test-SmokeRow -FileName $FileName -Rows $rows -Type $check.Type -Name $check.Name -Actual $check.Actual -Result $check.Result
        if (-not [string]::IsNullOrWhiteSpace($error)) {
            $errors.Add($error) | Out-Null
        }
    }

    if ($errors.Count -gt 0) {
        Add-Fail -Area "공통 증거" -Item $FileName -Evidence ($errors -join "; ")
    }
    else {
        Add-Pass -Area "공통 증거" -Item $FileName -Evidence "현재 buildId $CurrentBuildId, 브랜딩, Paperlogy, FAIL 없음"
    }

    return $rows
}

function Add-FlowCheck {
    param(
        [string]$Area,
        [string]$Item,
        [string]$FileName,
        [object[]]$Checks
    )

    if (-not $script:rowsByFile.ContainsKey($FileName)) {
        Add-Fail -Area $Area -Item $Item -Evidence "공통 검증에서 파일을 읽지 못함: $FileName"
        return
    }

    $rows = $script:rowsByFile[$FileName]
    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($check in $Checks) {
        $error = Test-SmokeRow -FileName $FileName -Rows $rows -Type $check.Type -Name $check.Name -Actual $check.Actual -Result $check.Result
        if (-not [string]::IsNullOrWhiteSpace($error)) {
            $errors.Add($error) | Out-Null
        }
    }

    if ($errors.Count -gt 0) {
        Add-Fail -Area $Area -Item $Item -Evidence "$FileName`: $($errors -join '; ')"
    }
    else {
        Add-Pass -Area $Area -Item $Item -Evidence "$FileName 필수 상태 통과"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$smokeRoot = Join-Path $buildRoot "release-smoke"
$buildInfoPath = Join-Path $buildRoot "BUILD_INFO.json"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\RELEASE_SMOKE_EVIDENCE_QA.md"
}

if (-not (Test-Path -LiteralPath $buildInfoPath)) {
    throw "Missing BUILD_INFO.json: $buildInfoPath"
}
if (-not (Test-Path -LiteralPath $smokeRoot)) {
    throw "Missing release smoke directory: $smokeRoot"
}

$buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw -Encoding UTF8 | ConvertFrom-Json
$currentBuildId = [string]$buildInfo.buildId
if ([string]::IsNullOrWhiteSpace($currentBuildId)) {
    throw "BUILD_INFO.json is missing buildId."
}

$script:results = New-Object System.Collections.Generic.List[object]
$script:rowsByFile = @{}

$canonicalSmokeFiles = @(
    "story-mode.tsv",
    "story-mode-shortcuts.tsv",
    "story-mode-next-button.tsv",
    "story-mode-direct-question-button.tsv",
    "story-mode-direct-question.tsv",
    "story-mode-direct-question-gamepad.tsv",
    "avatar-layout.tsv",
    "thinking-copy.tsv",
    "server-status.tsv",
    "answer-source-progress.tsv",
    "memory-card-question.tsv",
    "memory-book-shortcuts.tsv",
    "memory-reward-toast.tsv",
    "dialogue-reading-focus.tsv",
    "data-policy-delete-prompt.tsv",
    "data-policy-delete-button.tsv",
    "accessibility-settings.tsv",
    "sound-default.tsv",
    "sound-small.tsv",
    "sound-off.tsv",
    "shortcut-settings-open.tsv",
    "gamepad-shortcut-question.tsv",
    "gamepad-shortcut-cancel.tsv",
    "gamepad-shortcut-memory.tsv",
    "gamepad-shortcut-records.tsv",
    "gamepad-shortcut-settings.tsv",
    "gamepad-shortcut-note-tab-next.tsv",
    "gamepad-shortcut-lead-next.tsv",
    "gamepad-shortcut-text-up.tsv",
    "gamepad-shortcut-primary-question.tsv",
    "gamepad-shortcut-selected-question.tsv",
    "panel-shortcut-archive-blocks-question.tsv",
    "panel-shortcut-settings-blocks-question.tsv",
    "panel-shortcut-question-blocks-memory.tsv",
    "panel-shortcut-memory-blocks-settings.tsv",
    "panel-shortcut-archive-self-closes.tsv",
    "start-utility-visible.tsv",
    "start-continue-button.tsv",
    "start-info-access.tsv",
    "long-dialogue-layout.tsv",
    "foreground-clutter-hotspot.tsv",
    "foreground-clutter-memory.tsv",
    "closing-card-shortcuts.tsv",
    "closing-card-save-button.tsv",
    "closing-card-continue-button.tsv",
    "five-turn-playthrough.tsv",
    "first-impression-crutch-deep-arc.tsv",
    "first-impression-desk-deep-arc.tsv",
    "first-impression-face-deep-arc.tsv",
    "playtest-feedback-shortcuts.tsv",
    "playtest-feedback-require-note.tsv",
    "playtest-feedback-require-complete-session.tsv",
    "playtest-feedback-require-ending-record.tsv",
    "record-delete-confirm.tsv",
    "record-archive-shortcuts.tsv"
)

foreach ($fileName in $canonicalSmokeFiles) {
    $rows = Test-CommonSmokeEvidence -FileName $fileName -CurrentBuildId $currentBuildId
    if ($null -ne $rows) {
        $script:rowsByFile[$fileName] = $rows
    }
}

Add-FlowCheck -Area "첫 화면" -Item "첫 30초 목표 문구" -FileName "start-utility-visible.tsv" -Checks @(
    @{ Type = "state"; Name = "start-objective-visible"; Actual = "visible"; Result = "INFO" },
    @{ Type = "state"; Name = "start-objective-line"; Actual = "먼저 보인 겉 장면을 질문으로 따라가 생활의 속 맥락까지 확인하세요."; Result = "INFO" },
    @{ Type = "expect"; Name = "start-objective"; Actual = "present"; Result = "PASS" }
)

Add-FlowCheck -Area "첫 화면" -Item "첫 인상 겉/속 연결" -FileName "start-utility-visible.tsv" -Checks @(
    @{ Type = "state"; Name = "first-impression-option-map"; Actual = "목발 -> 이동 · 책상 -> 일과 공부 · 표정 -> 일상"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-display"; Actual = "첫 인상 없이 대화 시작"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-option-1-label"; Actual = "목발 이동 장면"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-option-2-label"; Actual = "책상 일과 공부 장면"; Result = "INFO" }
)

Add-FlowCheck -Area "첫 화면" -Item "이어하기 버튼 복귀" -FileName "start-continue-button.tsv" -Checks @(
    @{ Type = "state"; Name = "start-menu-action"; Actual = "continue-button"; Result = "INFO" },
    @{ Type = "state"; Name = "start-menu-open"; Actual = "closed"; Result = "INFO" },
    @{ Type = "state"; Name = "start-save-present"; Actual = "yes"; Result = "INFO" },
    @{ Type = "state"; Name = "start-save-preview-line"; Actual = "지난 대화 · 질문 3/5 · 기억장 3/6 · 일과 공부"; Result = "INFO" },
    @{ Type = "state"; Name = "conversation-turns"; Actual = "3"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression"; Actual = "목발"; Result = "INFO" },
    @{ Type = "expect"; Name = "start"; Actual = "closed"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "장면 버튼 상태 안내" -FileName "start-utility-visible.tsv" -Checks @(
    @{ Type = "state"; Name = "question-chapter-state-line"; Actual = "장면 버튼: 열기 6 · 깊게 0 · 깊음 0"; Result = "INFO" },
    @{ Type = "state"; Name = "question-chapter-1-label"; Actual = "일상 · 열기"; Result = "INFO" },
    @{ Type = "state"; Name = "question-chapter-3-label"; Actual = "도움 · 열기"; Result = "INFO" }
)

Add-FlowCheck -Area "핵심 루프" -Item "빈 태도 마무리 문장" -FileName "start-utility-visible.tsv" -Checks @(
    @{ Type = "state"; Name = "closing-recommendation-line"; Actual = "도움 방식은 아직 질문 태도가 쌓이지 않은 상태에서 도움을 먼저 묻는 방향을 제안합니다."; Result = "INFO" }
)

Add-FlowCheck -Area "핵심 루프" -Item "5턴 플레이스루" -FileName "five-turn-playthrough.tsv" -Checks @(
    @{ Type = "state"; Name = "conversation-turns"; Actual = "5"; Result = "INFO" },
    @{ Type = "state"; Name = "finish-button"; Actual = "enabled"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source"; Actual = "local-only"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-display"; Actual = "첫 인상 없이 대화 시작"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-quality-focus-label"; Actual = "초점: 전체 느낌"; Result = "INFO" },
    @{ Type = "state"; Name = "closing-recommendation-line"; Actual = "이동 확인은 대화에서 열린 장면을 하루 동선 확인으로 정리합니다."; Result = "INFO" },
    @{ Type = "state"; Name = "choice-consequence-line"; Actual = "선택 결과: 호기심 질문 -> 취미 깊은 기록 · 질문 태도와 단서가 맞아 장면이 깊어졌습니다."; Result = "INFO" },
    @{ Type = "state"; Name = "next-session-prompt-line"; Actual = "도움 장면을 배려/호기심 질문으로 깊은 기록까지 열어보세요."; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-review-action"; Actual = "판단 보강: 메모의 품질 영역을 다음 외부 리뷰에서 다시 확인하세요."; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-commercial-quality-evidence"; Actual = "점수표 보류: 5달러 충분 판정 전 다음 외부 리뷰에서 재확인 필요."; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-completed-five-turn-session"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-ending-record-saved"; Actual = "true"; Result = "INFO" },
    @{ Type = "expect"; Name = "records"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "마무리 카드 단축키" -FileName "closing-card-shortcuts.tsv" -Checks @(
    @{ Type = "state"; Name = "conversation-turns"; Actual = "5"; Result = "INFO" },
    @{ Type = "state"; Name = "closing-shortcut-action"; Actual = "next-key"; Result = "INFO" },
    @{ Type = "state"; Name = "next-session-prompt-line"; Actual = "일상 장면을 배려/호기심 질문으로 깊은 기록까지 열어보세요."; Result = "INFO" },
    @{ Type = "expect"; Name = "closing"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "마무리 저장 버튼" -FileName "closing-card-save-button.tsv" -Checks @(
    @{ Type = "state"; Name = "conversation-turns"; Actual = "5"; Result = "INFO" },
    @{ Type = "state"; Name = "closing-shortcut-action"; Actual = "save-button"; Result = "INFO" },
    @{ Type = "state"; Name = "closing-save-button-label"; Actual = "저장 후 보기"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-ending-record-saved"; Actual = "true"; Result = "INFO" },
    @{ Type = "expect"; Name = "records"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "마무리 계속 버튼" -FileName "closing-card-continue-button.tsv" -Checks @(
    @{ Type = "state"; Name = "conversation-turns"; Actual = "5"; Result = "INFO" },
    @{ Type = "state"; Name = "closing-shortcut-action"; Actual = "continue-button"; Result = "INFO" },
    @{ Type = "state"; Name = "closing-continue-button-label"; Actual = "계속하기"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-ending-record-saved"; Actual = "false"; Result = "INFO" },
    @{ Type = "expect"; Name = "closing"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "records"; Actual = "closed"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "목발 첫인상 깊은 기록" -FileName "first-impression-crutch-deep-arc.tsv" -Checks @(
    @{ Type = "state"; Name = "first-impression"; Actual = "목발"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme"; Actual = "이동"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme-opened"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme-deep"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "selected-closing-label"; Actual = "이동 확인"; Result = "INFO" },
    @{ Type = "expect"; Name = "closing"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "책상 첫인상 깊은 기록" -FileName "first-impression-desk-deep-arc.tsv" -Checks @(
    @{ Type = "state"; Name = "first-impression"; Actual = "책상"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme"; Actual = "일과 공부"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme-opened"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme-deep"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "selected-closing-label"; Actual = "사람 보기"; Result = "INFO" },
    @{ Type = "expect"; Name = "closing"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "핵심 루프" -Item "표정 첫인상 깊은 기록" -FileName "first-impression-face-deep-arc.tsv" -Checks @(
    @{ Type = "state"; Name = "first-impression"; Actual = "표정"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme"; Actual = "일상"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme-opened"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "first-impression-theme-deep"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "selected-closing-label"; Actual = "사람 보기"; Result = "INFO" },
    @{ Type = "expect"; Name = "closing"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "피드백" -Item "부정/수정 의견 메모 요구" -FileName "playtest-feedback-require-note.tsv" -Checks @(
    @{ Type = "state"; Name = "feedback"; Actual = "open"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-note-length"; Actual = "0"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-evidence-tier"; Actual = "issue-or-hold"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-quality-focus-label"; Actual = "초점: 전체 느낌"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-review-action"; Actual = "우선 수정: P1 문제를 이슈로 등록하고 재검증하세요."; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-commercial-quality-evidence"; Actual = "점수표 보류: P1 이슈를 외부 이슈 레지스터에 등록해야 합니다."; Result = "INFO" },
    @{ Type = "expect"; Name = "feedback"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "피드백" -Item "긍정 평가 5문답 요구" -FileName "playtest-feedback-require-complete-session.tsv" -Checks @(
    @{ Type = "state"; Name = "feedback"; Actual = "open"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-completed-five-turn-session"; Actual = "false"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-evidence-tier"; Actual = "incomplete-positive"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-review-action"; Actual = "근거 보강: 긍정 의견은 5문답 완료 뒤 다시 저장해야 합니다."; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-commercial-quality-evidence"; Actual = "점수표 보류: 긍정 판정 전에 5문답 완료 증거가 필요합니다."; Result = "INFO" },
    @{ Type = "expect"; Name = "feedback"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "피드백" -Item "긍정 평가 마무리 기록 요구" -FileName "playtest-feedback-require-ending-record.tsv" -Checks @(
    @{ Type = "state"; Name = "feedback"; Actual = "open"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-completed-five-turn-session"; Actual = "true"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-ending-record-saved"; Actual = "false"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-evidence-tier"; Actual = "ending-record-needed"; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-review-action"; Actual = "근거 보강: 마무리 기록 저장 뒤 긍정 의견을 다시 남겨야 합니다."; Result = "INFO" },
    @{ Type = "state"; Name = "feedback-commercial-quality-evidence"; Actual = "점수표 보류: 긍정 판정 전에 마무리 기록 저장 증거가 필요합니다."; Result = "INFO" },
    @{ Type = "expect"; Name = "feedback"; Actual = "open"; Result = "PASS" }
)

Add-FlowCheck -Area "접근성" -Item "설정 토글" -FileName "accessibility-settings.tsv" -Checks @(
    @{ Type = "state"; Name = "reduced-motion"; Actual = "on"; Result = "INFO" },
    @{ Type = "state"; Name = "high-contrast"; Actual = "on"; Result = "PASS" }
)

Add-FlowCheck -Area "읽기" -Item "대화 읽기 집중 모드" -FileName "dialogue-reading-focus.tsv" -Checks @(
    @{ Type = "expect"; Name = "dialogue-reading-focus"; Actual = "active"; Result = "PASS" },
    @{ Type = "expect"; Name = "dialogue-reading-hotspots"; Actual = "0"; Result = "PASS" },
    @{ Type = "expect"; Name = "dialogue-reading-followups"; Actual = "3"; Result = "PASS" }
)

Add-FlowCheck -Area "개인정보" -Item "저장 삭제 버튼 확정" -FileName "data-policy-delete-button.tsv" -Checks @(
    @{ Type = "state"; Name = "clear-data-action"; Actual = "confirm-button"; Result = "INFO" },
    @{ Type = "state"; Name = "clear-data-pending"; Actual = "idle"; Result = "INFO" },
    @{ Type = "state"; Name = "start-save-present"; Actual = "no"; Result = "INFO" },
    @{ Type = "state"; Name = "conversation-turns"; Actual = "0"; Result = "INFO" },
    @{ Type = "expect"; Name = "about"; Actual = "closed"; Result = "PASS" }
)

Add-FlowCheck -Area "기록" -Item "삭제 확인 2단계" -FileName "record-delete-confirm.tsv" -Checks @(
    @{ Type = "state"; Name = "record-delete-selection"; Actual = "selected"; Result = "INFO" },
    @{ Type = "state"; Name = "record-delete-pending"; Actual = "pending"; Result = "PASS" },
    @{ Type = "state"; Name = "record-delete-label"; Actual = "삭제 확정"; Result = "PASS" },
    @{ Type = "state"; Name = "record-delete-cancel"; Actual = "취소"; Result = "PASS" }
)

Add-FlowCheck -Area "기억 카드" -Item "카드에서 질문 진입" -FileName "memory-card-question.tsv" -Checks @(
    @{ Type = "state"; Name = "conversation-turns"; Actual = "1"; Result = "INFO" },
    @{ Type = "state"; Name = "memory-card-action"; Actual = "일상"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source"; Actual = "local-only"; Result = "INFO" }
)

Add-FlowCheck -Area "보상" -Item "장면 보상 토스트" -FileName "memory-reward-toast.tsv" -Checks @(
    @{ Type = "state"; Name = "reward-toast-visible"; Actual = "visible"; Result = "INFO" },
    @{ Type = "state"; Name = "reward-line"; Actual = "보상: 도움 장면 열림 · 배려/호기심 질문으로 깊은 기록까지 이어 보세요."; Result = "INFO" },
    @{ Type = "state"; Name = "reward-toast-text"; Actual = "보상: 도움 장면 열림 · 배려/호기심 질문으로 깊은 기록까지 이어 보세요."; Result = "INFO" }
)

Add-FlowCheck -Area "서버/근거" -Item "서버 상태 표시" -FileName "server-status.tsv" -Checks @(
    @{ Type = "state"; Name = "about-server-status"; Actual = "답변 연결 상태는 상태 확인으로 볼 수 있습니다."; Result = "INFO" },
    @{ Type = "expect"; Name = "about-server-status"; Actual = "settled"; Result = "PASS" },
    @{ Type = "state"; Name = "server-error"; Actual = ""; Result = "INFO" }
)

Add-FlowCheck -Area "서버/근거" -Item "내장 답변 출처 표시" -FileName "answer-source-progress.tsv" -Checks @(
    @{ Type = "state"; Name = "conversation-turns"; Actual = "1"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source"; Actual = "local-only"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source-label"; Actual = "내장 답변만 사용"; Result = "INFO" },
    @{ Type = "state"; Name = "choice-consequence-line"; Actual = "선택 결과: 호기심 질문 -> 도움 얕은 기록 · 배려/호기심으로 단서를 맞추면 깊어집니다."; Result = "INFO" }
)

Add-FlowCheck -Area "스토리" -Item "이야기 모드 진입" -FileName "story-mode.tsv" -Checks @(
    @{ Type = "story"; Name = "active"; Actual = "active"; Result = "INFO" },
    @{ Type = "story"; Name = "controls-visible"; Actual = "visible"; Result = "INFO" },
    @{ Type = "story"; Name = "beat"; Actual = "겉: 목발 · 속: 하루를 준비하는 방식"; Result = "INFO" },
    @{ Type = "story"; Name = "pace"; Actual = "연출: 짧은 정적 0.8초 · 낮은 방 톤 · 목발 쪽으로 천천히 시선 이동"; Result = "INFO" },
    @{ Type = "story"; Name = "next-label"; Actual = "다음 2/6"; Result = "INFO" },
    @{ Type = "state"; Name = "story-pace-line"; Actual = "연출: 짧은 정적 0.8초 · 낮은 방 톤 · 목발 쪽으로 천천히 시선 이동"; Result = "INFO" },
    @{ Type = "expect"; Name = "story-active"; Actual = "active"; Result = "PASS" },
    @{ Type = "expect"; Name = "story-beat"; Actual = "present"; Result = "PASS" },
    @{ Type = "expect"; Name = "story-pace"; Actual = "present"; Result = "PASS" },
    @{ Type = "expect"; Name = "story-controls"; Actual = "visible"; Result = "PASS" }
)

Add-FlowCheck -Area "스토리" -Item "이야기 모드 단축키" -FileName "story-mode-shortcuts.tsv" -Checks @(
    @{ Type = "story"; Name = "active"; Actual = "active"; Result = "INFO" },
    @{ Type = "state"; Name = "story-shortcut-action"; Actual = "next-key"; Result = "INFO" },
    @{ Type = "story"; Name = "index"; Actual = "1"; Result = "INFO" },
    @{ Type = "story"; Name = "next-label"; Actual = "다음 3/6"; Result = "INFO" },
    @{ Type = "story"; Name = "pace"; Actual = "연출: 짧은 정적 0.7초 · 문밖 소리 낮춤 · 이동 경로 쪽으로 시선 이동"; Result = "INFO" },
    @{ Type = "state"; Name = "story-pace-line"; Actual = "연출: 짧은 정적 0.7초 · 문밖 소리 낮춤 · 이동 경로 쪽으로 시선 이동"; Result = "INFO" }
)

Add-FlowCheck -Area "스토리" -Item "이야기 모드 다음 버튼 전환" -FileName "story-mode-next-button.tsv" -Checks @(
    @{ Type = "story"; Name = "active"; Actual = "active"; Result = "INFO" },
    @{ Type = "state"; Name = "story-shortcut-action"; Actual = "next-button"; Result = "INFO" },
    @{ Type = "story"; Name = "index"; Actual = "1"; Result = "INFO" },
    @{ Type = "story"; Name = "next-label"; Actual = "다음 3/6"; Result = "INFO" },
    @{ Type = "story"; Name = "pace"; Actual = "연출: 짧은 정적 0.7초 · 문밖 소리 낮춤 · 이동 경로 쪽으로 시선 이동"; Result = "INFO" },
    @{ Type = "state"; Name = "story-pace-line"; Actual = "연출: 짧은 정적 0.7초 · 문밖 소리 낮춤 · 이동 경로 쪽으로 시선 이동"; Result = "INFO" }
)

Add-FlowCheck -Area "스토리" -Item "이야기 모드 버튼 직접 질문 전환" -FileName "story-mode-direct-question-button.tsv" -Checks @(
    @{ Type = "story"; Name = "active"; Actual = "inactive"; Result = "INFO" },
    @{ Type = "story"; Name = "controls-visible"; Actual = "hidden"; Result = "INFO" },
    @{ Type = "state"; Name = "story-shortcut-action"; Actual = "question-button"; Result = "INFO" },
    @{ Type = "copy"; Name = "thinking-status"; Actual = "직접 질문으로 이어갑니다"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source"; Actual = "대기"; Result = "INFO" },
    @{ Type = "expect"; Name = "question"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "memory"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "records"; Actual = "closed"; Result = "PASS" }
)

Add-FlowCheck -Area "스토리" -Item "이야기 모드 직접 질문 전환" -FileName "story-mode-direct-question.tsv" -Checks @(
    @{ Type = "story"; Name = "active"; Actual = "inactive"; Result = "INFO" },
    @{ Type = "story"; Name = "controls-visible"; Actual = "hidden"; Result = "INFO" },
    @{ Type = "state"; Name = "story-shortcut-action"; Actual = "question-key"; Result = "INFO" },
    @{ Type = "copy"; Name = "thinking-status"; Actual = "직접 질문으로 이어갑니다"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source"; Actual = "대기"; Result = "INFO" },
    @{ Type = "expect"; Name = "question"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "memory"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "records"; Actual = "closed"; Result = "PASS" }
)

Add-FlowCheck -Area "스토리" -Item "이야기 모드 패드 직접 질문 전환" -FileName "story-mode-direct-question-gamepad.tsv" -Checks @(
    @{ Type = "story"; Name = "active"; Actual = "inactive"; Result = "INFO" },
    @{ Type = "story"; Name = "controls-visible"; Actual = "hidden"; Result = "INFO" },
    @{ Type = "state"; Name = "story-shortcut-action"; Actual = "question-gamepad"; Result = "INFO" },
    @{ Type = "copy"; Name = "thinking-status"; Actual = "직접 질문으로 이어갑니다"; Result = "INFO" },
    @{ Type = "state"; Name = "answer-source"; Actual = "대기"; Result = "INFO" },
    @{ Type = "expect"; Name = "question"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "memory"; Actual = "closed"; Result = "PASS" },
    @{ Type = "expect"; Name = "records"; Actual = "closed"; Result = "PASS" }
)

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$passed = @($results | Where-Object { $_.Status -eq "통과" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 릴리즈 스모크 증거 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 현재 buildId: $currentBuildId")
$lines.Add("- 정규 TSV: $($canonicalSmokeFiles.Count)")
$lines.Add("- 실패: $failed")
$lines.Add("- 통과: $passed")
$lines.Add("")
$lines.Add("이 검증은 릴리즈 스모크 폴더에 남아 있는 예전 임시 TSV가 아니라, `RunReleaseSmoke.ps1` 전체 실행이 생성하는 정규 TSV만 현재 빌드 증거로 인정한다.")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Area) | $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) |")
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failed -gt 0) {
    throw "Release smoke evidence QA failed with $failed issue(s). Report: $OutputPath"
}

Write-Host "Release smoke evidence QA passed: $OutputPath"

