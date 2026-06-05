param(
    [string]$SourcePath,
    [string]$PersonaPath,
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

function Read-Utf8Text {
    param([string]$Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Test-CopyText {
    param(
        [string]$Text,
        [string]$Context
    )

    if ($Text -match "플레이테스트") {
        return "$Context에 '플레이테스트' 표현이 남아 있다."
    }
    if ($Text -cmatch "저는\s*실제\s*사람이\s*아니라|저는\s*가상책|가상\s*사람책|전시용\s*대화\s*에이전트|\bAI\b|인공지능|프로그램|UI") {
        return "$Context에 AI식 정체성 또는 제작 도구 표현이 남아 있다."
    }
    if ($Text -match "\*\*") {
        return "$Context에 별표 강조 흔적이 남아 있다."
    }
    if ($Text -match "^(좋아요|좋습니다|물론이죠|잠깐만요|잠시만요|잠깐|네)[,.，\s]+") {
        return "$Context가 접수 표현으로 시작한다."
    }

    return ""
}

function Add-PersonaText {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [object]$Value
    )

    if ($null -eq $Value) {
        return
    }
    $text = [string]$Value
    if (-not [string]::IsNullOrWhiteSpace($text)) {
        $Target.Add($text) | Out-Null
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path $projectRoot "Assets\Scripts\AvatarChatApp.cs"
}
if ([string]::IsNullOrWhiteSpace($PersonaPath)) {
    $PersonaPath = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI\data\persona.json"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "Docs\COMMERCIAL_UI_COPY_QA.md"
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Missing source file: $SourcePath"
}
if (-not (Test-Path -LiteralPath $PersonaPath)) {
    throw "Missing persona file: $PersonaPath"
}

$source = Read-Utf8Text -Path $SourcePath
$launcherPath = Join-Path $projectRoot "LaunchAvatarChat.ps1"
$launcherSource = if (Test-Path -LiteralPath $launcherPath) { Read-Utf8Text -Path $launcherPath } else { "" }
$persona = Read-Utf8Text -Path $PersonaPath | ConvertFrom-Json
$playerStringText = ([regex]::Matches($source, '"(?:\\.|[^"\\])*"') |
    ForEach-Object { $_.Value } |
    Where-Object { $_ -match "[가-힣]" -and $_ -notmatch '^"\^' -and $_ -notmatch "\\s\*|\\b" }) -join "`n"
$results = New-Object System.Collections.Generic.List[object]
$failures = 0

if ($playerStringText -match "플레이테스트") {
    Add-Result -Item "상용 UI 표현" -Status "실패" -Evidence "AvatarChatApp.cs에 플레이어에게 미완성판처럼 보일 수 있는 '플레이테스트' 표현이 남아 있다."
    $failures++
} else {
    Add-Result -Item "상용 UI 표현" -Status "통과" -Evidence "AvatarChatApp.cs에 한국어 '플레이테스트' 표현 없음"
}

if ($playerStringText -cmatch "저는\s*실제\s*사람이\s*아니라|저는\s*가상책|가상\s*사람책|전시용\s*대화\s*에이전트|\bAI\b|인공지능|프로그램|UI") {
    Add-Result -Item "몰입 방해 표현" -Status "실패" -Evidence "플레이어 화면 문구에 AI식 정체성 또는 제작 도구 표현이 남아 있다."
    $failures++
} else {
    Add-Result -Item "몰입 방해 표현" -Status "통과" -Evidence "반복 정체성 고지와 AI식 표현 없음"
}

$personaPlayerText = New-Object System.Collections.Generic.List[string]
Add-PersonaText -Target $personaPlayerText -Value $persona.appTitle
Add-PersonaText -Target $personaPlayerText -Value $persona.displayName
Add-PersonaText -Target $personaPlayerText -Value $persona.personaLabel
Add-PersonaText -Target $personaPlayerText -Value $persona.opening
Add-PersonaText -Target $personaPlayerText -Value $persona.unknownAnswer
foreach ($question in @($persona.suggestedQuestions)) {
    Add-PersonaText -Target $personaPlayerText -Value $question
}
foreach ($example in @($persona.voiceExamples)) {
    Add-PersonaText -Target $personaPlayerText -Value $example.situation
    Add-PersonaText -Target $personaPlayerText -Value $example.text
}
foreach ($fact in @($persona.facts)) {
    Add-PersonaText -Target $personaPlayerText -Value $fact.title
    Add-PersonaText -Target $personaPlayerText -Value $fact.summary
    Add-PersonaText -Target $personaPlayerText -Value $fact.answer
}
foreach ($card in @($persona.sceneCards)) {
    Add-PersonaText -Target $personaPlayerText -Value $card.title
    Add-PersonaText -Target $personaPlayerText -Value $card.situation
    Add-PersonaText -Target $personaPlayerText -Value $card.answer
    foreach ($followup in @($card.followups)) {
        Add-PersonaText -Target $personaPlayerText -Value $followup
    }
}

$personaCopyFailure = ""
foreach ($text in $personaPlayerText) {
    $personaCopyFailure = Test-CopyText -Text $text -Context "persona.json 플레이어 문구"
    if (-not [string]::IsNullOrWhiteSpace($personaCopyFailure)) {
        break
    }
}
if (-not [string]::IsNullOrWhiteSpace($personaCopyFailure)) {
    Add-Result -Item "서버 답변 데이터 문구" -Status "실패" -Evidence $personaCopyFailure
    $failures++
} else {
    Add-Result -Item "서버 답변 데이터 문구" -Status "통과" -Evidence "persona.json의 제목, 시작 답변, 말투 예시, 근거 답변, 추천 질문에 AI식 표현과 별표 강조 없음"
}

if ($playerStringText -match "\*\*") {
    Add-Result -Item "마크다운 강조" -Status "실패" -Evidence "플레이어 화면 문구에 별표 강조 흔적이 남아 있다."
    $failures++
} else {
    Add-Result -Item "마크다운 강조" -Status "통과" -Evidence "별표 강조 흔적 없음"
}

if ($source -match "공식 근거는 이야기를 마친 뒤 5문답을 완료하고 저장한 의견만 사용합니다|5달러 기준 부족한 점|빌드와 세션 ID가 함께 남습니다") {
    Add-Result -Item "의견 메모 화면 문구" -Status "실패" -Evidence "의견 창에 리뷰 운영/빌드 메타데이터 문구가 플레이어 화면 문구로 남아 있다."
    $failures++
}
else {
    Add-Result -Item "의견 메모 화면 문구" -Status "통과" -Evidence "의견 창 설명은 플레이어용 소감 문구로 정리됨"
}

if ($source -notmatch '"의견 남기기"' -or $source -notmatch "\{GameTitle\} 의견 메모" -or $source -notmatch '"FeedbackNotes"' -or $source -notmatch "이야기를 마친 뒤 느낀 점" -or $source -notmatch "완성도 느낌" -or $source -notmatch "문제 단계") {
    Add-Result -Item "의견 메모 표현" -Status "실패" -Evidence "의견 메모 UI 또는 저장 제목이 상용 표현으로 정리되지 않았다."
    $failures++
} else {
    Add-Result -Item "의견 메모 표현" -Status "통과" -Evidence "의견 남기기, 의견 메모, FeedbackNotes, 플레이어용 안내, 완성도 느낌, 문제 단계 문구 확인"
}

if ($source -notmatch "LocalAnswerOnlyKey" -or $source -notmatch '"내장만"' -or $source -notmatch "서버로 보내지 않고") {
    Add-Result -Item "로컬 답변 선택권" -Status "실패" -Evidence "서버 전송 없이 내장 답변만 쓰는 플레이어 선택 문구가 부족하다."
    $failures++
} else {
    Add-Result -Item "로컬 답변 선택권" -Status "통과" -Evidence "설정 토글과 서버 전송 없음 근거 문구 확인"
}

if ($source -notmatch "About Feedback Folder Button" -or $source -notmatch '"의견 폴더"' -or $source -notmatch "OpenPlaytestFeedbackFolder" -or $source -notmatch '"FeedbackNotes"') {
    Add-Result -Item "정보 화면 의견 폴더 접근" -Status "실패" -Evidence "정보 화면에서 플레이어 의견 저장 폴더를 바로 열 수 없다."
    $failures++
} else {
    Add-Result -Item "정보 화면 의견 폴더 접근" -Status "통과" -Evidence "정보 화면 의견 폴더 버튼과 FeedbackNotes 저장 경로 연결 확인"
}

if ($source -notmatch "startAboutButton" -or $source -notmatch "Start About Button" -or $source -notmatch "start-about-visible" -or $source -match "startAboutButton\.gameObject\.SetActive\(false\)") {
    Add-Result -Item "첫 화면 정보 접근" -Status "실패" -Evidence "시작 화면에서 정보 화면을 바로 열 수 있는 버튼이 없다."
    $failures++
} else {
    Add-Result -Item "첫 화면 정보 접근" -Status "통과" -Evidence "시작 화면 정보 버튼 표시와 정보 화면 연결 상태 감사 확인"
}

if ($source -notmatch "startSettingsButton" -or $source -notmatch "Settings From Start Button" -or $source -notmatch "start-settings-visible" -or $source -match "startSettingsButton\.gameObject\.SetActive\(false\)") {
    Add-Result -Item "첫 화면 설정 접근" -Status "실패" -Evidence "시작 화면에서 설정을 바로 열 수 있는 버튼이 없다."
    $failures++
} else {
    Add-Result -Item "첫 화면 설정 접근" -Status "통과" -Evidence "시작 화면 설정 버튼 표시와 상태 감사 확인"
}

if ($source -notmatch "BuildStartObjectiveLine" -or $source -notmatch "startObjectiveText" -or $source -notmatch "start-objective-line" -or $source -notmatch "start-objective" -or $source -notmatch "겉 장면" -or $source -notmatch "속 맥락") {
    Add-Result -Item "첫 화면 목표 문구" -Status "실패" -Evidence "첫 30초에 겉 장면을 질문으로 따라가 속 맥락을 확인하는 목표 문구가 부족하다."
    $failures++
} else {
    Add-Result -Item "첫 화면 목표 문구" -Status "통과" -Evidence "시작 화면 목표 문구와 상태 감사에서 겉 장면/속 맥락 안내 확인"
}

if ($source -notmatch "BuildFirstImpressionOptionLabel" -or
    $source -notmatch "BuildFirstImpressionOptionMapLine" -or
    $source -notmatch "firstImpressionButtons" -or
    $source -notmatch "first-impression-option-map" -or
    $source -notmatch "first-impression-option-1-label" -or
    $source -notmatch "GetThemeForFirstImpressionOption" -or
    $source -notmatch '"목발", StringComparison\.Ordinal\)\) return "이동"' -or
    $source -notmatch '"책상", StringComparison\.Ordinal\)\) return "일과 공부"' -or
    $source -notmatch '"표정", StringComparison\.Ordinal\)\) return "일상"' -or
    $source -notmatch "겉 단서를 고르면, 연결된 속 장면") {
    Add-Result -Item "첫 인상 겉/속 연결" -Status "실패" -Evidence "첫 인상 선택에서 겉 단서와 이어지는 속 장면을 선택 전에 보여주지 않는다."
    $failures++
} else {
    Add-Result -Item "첫 인상 겉/속 연결" -Status "통과" -Evidence "첫 인상 버튼과 상태 감사에서 목발/책상/표정이 이동/일과 공부/일상으로 이어지는 관계 확인"
}

if ($source -notmatch "ShouldRequirePlaytestFeedbackNote" -or $source -notmatch "더 다듬기" -or $source -notmatch "조금 아쉬움" -or $source -notmatch "문제 있음" -or $source -notmatch "전체 느낌" -or $source -notmatch "문제 단계") {
    Add-Result -Item "의견 메모 근거 확보" -Status "실패" -Evidence "낮은 평가나 이슈 등급을 선택했을 때 수정 근거 메모를 요구하는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "의견 메모 근거 확보" -Status "통과" -Evidence "평가 행 라벨과 낮은 완성도/P2 이상 메모 요구 문구 확인"
}

if ($source -notmatch "GetPlaytestQualityFocusLabel" -or
    $source -notmatch 'default:\s*return "전체 느낌";' -or
    $source -match 'default:\s*return "자동";' -or
    $source -match '초점:\s*자동') {
    Add-Result -Item "의견 초점 기본 라벨" -Status "실패" -Evidence "의견 초점 기본값이 플레이어 화면에서 '자동' 같은 시스템식 표현으로 노출될 수 있다."
    $failures++
} else {
    Add-Result -Item "의견 초점 기본 라벨" -Status "통과" -Evidence "의견 초점 기본 라벨은 전체 느낌으로 표시되고 내부 auto ID와 분리됨"
}

if ($source -match 'string\[\]\s+commercialLabels\s*=\s*\{[^}]*"보류"' -or
    $source -match 'playtestFeedbackStatusText\.text\s*=\s*"[^"]*보류' -or
    $source -match 'playtestFeedbackEvidenceText\.text\s*=\s*"[^"]*보류') {
    Add-Result -Item "의견창 플레이어 표현" -Status "실패" -Evidence "의견 남기기 화면의 버튼 또는 상태 문구에 운영자식 '보류' 표현이 남아 있다."
    $failures++
} elseif ($source -notmatch '"더 다듬기"' -or $source -notmatch '"조금 아쉬움"' -or $source -notmatch '"충분함"') {
    Add-Result -Item "의견창 플레이어 표현" -Status "실패" -Evidence "완성도 선택 버튼이 플레이어가 말하기 쉬운 표현으로 정리되지 않았다."
    $failures++
} else {
    Add-Result -Item "의견창 플레이어 표현" -Status "통과" -Evidence "완성도 선택과 상태 문구에서 보류 대신 플레이어 자연어 라벨을 사용함"
}

if ($source -notmatch "사소한 문제" -or $source -notmatch "진행 방해" -or $source -notmatch "진행 불가" -or $source -notmatch "feedback-issue-severity-label") {
    Add-Result -Item "의견 문제 단계 설명" -Status "실패" -Evidence "플레이어가 문제 단계를 화면에서 바로 읽을 수 있는 라벨이 부족하다."
    $failures++
} else {
    Add-Result -Item "의견 문제 단계 설명" -Status "통과" -Evidence "사소한 문제, 진행 방해, 진행 불가 라벨과 상태 감사 확인"
}

if ($source -notmatch "ShouldRequireCompletedPlaytestSession" -or
    $source -notmatch "ShouldRequireEndingRecordForPositiveEvidence" -or
    $source -notmatch "좋음, 충분함, 문제 없음" -or
    $source -notmatch "마무리 기록을 저장한 뒤" -or
    $source -notmatch "completedFiveTurnSession" -or
    $source -notmatch "endingRecordSavedThisSession" -or
    $source -notmatch "qualityEvidenceReady") {
    Add-Result -Item "긍정 의견 완주 근거 확보" -Status "실패" -Evidence "5문답 미완료 상태에서 긍정 의견이 품질 근거로 저장되는 것을 막는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "긍정 의견 완주 근거 확보" -Status "통과" -Evidence "좋음/충분함/문제 없음 저장 전에 5문답 완료, 마무리 기록 저장, 품질 근거 상태를 남기는 흐름 확인"
}

if ($source -notmatch 'schemaVersion = "6"' -or
    $source -notmatch "sessionCompletionLine" -or
    $source -notmatch "dominantAttitude" -or
    $source -notmatch "deepMemoryCount" -or
    $source -notmatch "openedSceneTags" -or
    $source -notmatch "reviewActionRecommendation" -or
    $source -notmatch "commercialQualityEvidenceLine" -or
    $source -notmatch "BuildReviewActionRecommendationLine" -or
    $source -notmatch "BuildCommercialQualityEvidenceLine" -or
    $source -notmatch "주된 질문 태도:" -or
    $source -notmatch "열린 장면 태그:" -or
    $source -notmatch "추천 조치:" -or
    $source -notmatch "상업 품질 근거:" -or
    $source -notmatch "feedback-review-action" -or
    $source -notmatch "feedback-commercial-quality-evidence") {
    Add-Result -Item "의견 export 세션 맥락" -Status "실패" -Evidence "의견 txt/json에 세션 완성도, 질문 태도, 깊은 기록, 열린 장면 태그, 추천 조치가 구조화되어 있지 않다."
    $failures++
} else {
    Add-Result -Item "의견 export 세션 맥락" -Status "통과" -Evidence "의견 txt/json이 세션 완성도, 질문 태도, 깊은 기록, 열린 장면 태그, 추천 조치, 상업 품질 근거를 외부 리뷰용 구조화 필드로 남김"
}

if ($source -notmatch "Playtest Readiness Panel" -or
    $source -notmatch "BuildPlaytestFeedbackReadinessLine" -or
    $source -notmatch "문답 5/5 완료" -or
    $source -notmatch "마무리 기록 전" -or
    $source -notmatch "feedback-readiness-line") {
    Add-Result -Item "의견창 세션 준비 상태" -Status "실패" -Evidence "의견 창에서 5문답, 마무리 기록, 선택 상태를 한 줄로 확인하는 준비 상태 표시가 부족하다."
    $failures++
} else {
    Add-Result -Item "의견창 세션 준비 상태" -Status "통과" -Evidence "의견 창에 문답 진행, 마무리 기록, 긍정/수정 의견 상태를 표시하고 상태 감사에도 남김"
}

if ($source -notmatch "Question Phone Session Guide" -or
    $source -notmatch "BuildQuestionPhoneGuideText" -or
    $source -notmatch "BuildQuestionSessionQualityLine" -or
    $source -notmatch "BuildChapterButtonLabel" -or
    $source -notmatch "BuildChapterStateSummaryLine" -or
    $source -notmatch "장면: 새로 열기" -or
    $source -notmatch "더 묻기" -or
    $source -notmatch "깊음" -or
    $source -notmatch "주된 질문" -or
    $source -notmatch "question-session-quality-line" -or
    $source -notmatch "question-chapter-state-line" -or
    $source -notmatch "question-chapter-1-label" -or
    $source -notmatch "마무리 가능 ·") {
    Add-Result -Item "질문 노트 진행 길잡이" -Status "실패" -Evidence "첫 세션에서 다음 흐름을 읽을 수 있는 질문 노트 길잡이 문구가 부족하다."
    $failures++
} else {
    Add-Result -Item "질문 노트 진행 길잡이" -Status "통과" -Evidence "질문 노트에서 장면 버튼 상태, 주된 질문 태도, 깊은 기록, 마무리 가능 상태를 플레이어 문구와 상태 감사로 안내함"
}

if ($source -notmatch "BuildLeadAttitudeHint" -or
    $source -notmatch "BuildChoiceConsequenceLine" -or
    $source -notmatch "배려/호기심으로 깊게" -or
    $source -notmatch "BuildQuestionSessionQualityLine" -or
    $source -notmatch "selected-lead-label" -or
    $source -notmatch "choice-consequence-line" -or
    $source -notmatch "선택 기록:" -or
    $source -notmatch "마지막 선택 기록:" -or
    $source -notmatch "되묻기" -or
    $source -notmatch "얕은 기록") {
    Add-Result -Item "질문 태도 결과 표시" -Status "실패" -Evidence "질문 카드와 질문 노트가 태도 선택의 결과를 충분히 표시하지 않는다."
    $failures++
} else {
    Add-Result -Item "질문 태도 결과 표시" -Status "통과" -Evidence "질문 카드/질문 노트/마무리 카드/스모크 상태가 배려, 호기심, 단정, 거리두기의 결과를 표시함"
}

if ($source -notmatch "BuildNextSessionPromptLine" -or
    $source -notmatch "GetFirstShallowOpenedTheme" -or
    $source -notmatch "GetFirstUnopenedTheme" -or
    $source -notmatch "다음에 이어볼 질문:" -or
    $source -notmatch "다음 질문 방향:" -or
    $source -notmatch "next-session-prompt-line") {
    Add-Result -Item "마무리 다음 질문 방향" -Status "실패" -Evidence "마무리 카드와 저장 기록이 다음 세션에서 이어볼 질문 방향을 남기지 않는다."
    $failures++
} else {
    Add-Result -Item "마무리 다음 질문 방향" -Status "통과" -Evidence "마무리 카드, 저장 기록, 의견 기록, 스모크 상태에 다음 질문 방향이 남음"
}

if ($source -notmatch "RunSmokeContinueButtonClick" -or
    $source -notmatch "start-menu-action" -or
    $source -notmatch "start-save-preview-line" -or
    $source -notmatch "continue-button" -or
    $source -notmatch "저장된 대화를 이어갑니다" -or
    $source -notmatch "지난 대화 ·") {
    Add-Result -Item "이어하기 버튼 복귀 조작" -Status "실패" -Evidence "시작 화면 이어하기 버튼이 실제 저장 세션 복귀 경로와 스모크 상태에 연결되어 있지 않다."
    $failures++
} else {
    Add-Result -Item "이어하기 버튼 복귀 조작" -Status "통과" -Evidence "시작 화면 이어하기 버튼, 저장 미리보기, 복귀 상태 스모크가 연결됨"
}

if ($source -notmatch "Story Mode Next Button" -or
    $source -notmatch "RequestStoryModeAdvance" -or
    $source -notmatch "BuildStoryModeBeatLine" -or
    $source -notmatch "BuildStoryModePaceLine" -or
    $source -notmatch "BuildStoryModeQuietMomentLine" -or
    $source -notmatch "GetStoryModeQuietSeconds" -or
    $source -notmatch "RunSmokeStoryNextButtonClick" -or
    $source -notmatch "StopStoryModeForDirectQuestion" -or
    $source -notmatch "RunSmokeStoryQuestionButtonClick" -or
    $source -notmatch "storyModeOuterCues" -or
    $source -notmatch "storyModeInnerCues" -or
    $source -notmatch "storyModePaceCues" -or
    $source -notmatch "next-button" -or
    $source -notmatch "question-button" -or
    $source -notmatch "question-key" -or
    $source -notmatch '"겉: ' -or
    $source -notmatch "짧은 정적" -or
    $source -notmatch "story-pace-line" -or
    $source -notmatch '"다음 장면"' -or
    $source -notmatch '"직접 질문"' -or
    $source -notmatch '"5문답 후"') {
    Add-Result -Item "이야기 모드 진행 조작" -Status "실패" -Evidence "이야기 보기 중 장면 넘김, 직접 질문 전환, 겉/속 장면 비트, 정적/소리/시선 연출, 마무리 잠금 문구가 부족하다."
    $failures++
} else {
    Add-Result -Item "이야기 모드 진행 조작" -Status "통과" -Evidence "이야기 보기에서 다음 장면, 직접 질문, 겉/속 장면 비트, 정적/소리/시선 연출, 5문답 후 마무리 잠금 문구 확인"
}

if ($source -notmatch "SubmitMemoryCardQuestion" -or $source -notmatch "memoryCardButtons" -or $source -notmatch "themeLeadQuestions") {
    Add-Result -Item "기억장 장면 이어가기" -Status "실패" -Evidence "기억장 카드에서 장면 질문으로 이어지는 조작 근거가 부족하다."
    $failures++
} else {
    Add-Result -Item "기억장 장면 이어가기" -Status "통과" -Evidence "기억장 카드 버튼과 장면별 질문 연결 확인"
}

if ($source -notmatch "HandleMemoryBookShortcuts" -or $source -notmatch "CycleMemoryCardSelection" -or $source -notmatch "memory-book-shortcut-action") {
    Add-Result -Item "기억장 키보드 완주 조작" -Status "실패" -Evidence "기억장 카드 선택과 질문 시작을 키보드/패드로 완료하는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "기억장 키보드 완주 조작" -Status "통과" -Evidence "기억장 카드 선택과 질문 시작 단축 조작 확인"
}

if ($source -notmatch "HandleClosingCardShortcuts" -or
    $source -notmatch "CycleClosingCardShortcut" -or
    $source -notmatch "closing-shortcut-action" -or
    $source -notmatch "RunSmokeClosingSaveButtonClick" -or
    $source -notmatch "RunSmokeClosingContinueButtonClick" -or
    $source -notmatch "closing-save-button-label" -or
    $source -notmatch "closing-continue-button-label" -or
    $source -notmatch "save-button" -or
    $source -notmatch "continue-button") {
    Add-Result -Item "마무리 카드 완주 조작" -Status "실패" -Evidence "마무리 카드에서 문장 선택과 저장을 키보드/패드로 완료하는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "마무리 카드 완주 조작" -Status "통과" -Evidence "마무리 카드 문장 선택, 저장/계속 버튼, 키보드/패드 저장 조작 확인"
}

if ($source -notmatch "BuildClosingSelectionLine" -or
    $source -notmatch "HasFirstImpressionChoice" -or
    $source -notmatch "BuildFirstImpressionDisplayLabel" -or
    $source -notmatch "first-impression-display" -or
    $source -notmatch "첫 인상 없이 대화 시작" -or
    $source -notmatch "오늘 열린 장면을 하루의 동선으로 묶습니다" -or
    $source -notmatch "아직 질문이 적은 상태에서, 먼저 묻는 태도를 남깁니다" -or
    $source -notmatch "RefreshClosingChoiceLabels" -or
    $source -notmatch "추천 ·" -or
    $source -notmatch "선택 이유:" -or
    $source -notmatch "closing-recommendation-line") {
    Add-Result -Item "마무리 카드 선택 결과감" -Status "실패" -Evidence "마무리 카드 추천 표시, 선택 이유, 저장 기록/상태 감사 연결이 부족하다."
    $failures++
} else {
    Add-Result -Item "마무리 카드 선택 결과감" -Status "통과" -Evidence "추천 문장 표시, 선택 이유, 저장 기록, 스모크 상태 감사가 플레이어 선택 결과를 남김"
}

if ($source -notmatch "BuildSessionCompletionLine" -or
    $source -notmatch "세션 완성도:" -or
    $source -notmatch "session-completion-line" -or
    $source -notmatch "5문답 완료" -or
    $source -notmatch "남은") {
    Add-Result -Item "마무리 세션 완성도" -Status "실패" -Evidence "마무리 카드, 저장 기록, 상태 감사에서 문답/장면/깊은 기록 완성도를 함께 보여주는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "마무리 세션 완성도" -Status "통과" -Evidence "마무리 카드와 저장 기록, 스모크 상태가 문답 완료, 열린 장면, 남은 장면, 깊은 기록 수를 한 줄로 남김"
}

if ($source -notmatch "HandleRecordArchiveShortcuts" -or $source -notmatch "CycleRecordArchiveSelection" -or $source -notmatch "record-archive-shortcut-action") {
    Add-Result -Item "기록함 키보드 완주 조작" -Status "실패" -Evidence "기록함 슬롯 선택과 삭제 확인을 키보드/패드로 완료하는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "기록함 키보드 완주 조작" -Status "통과" -Evidence "기록함 슬롯 선택과 삭제 확인 단축 조작 확인"
}

if ($source -notmatch "Record Archive Cancel Delete Button" -or $source -notmatch "CancelPendingRecordDelete" -or $source -notmatch "기록 삭제를 취소했습니다") {
    Add-Result -Item "기록 삭제 취소" -Status "실패" -Evidence "기록 삭제 확인 상태에서 명시적인 취소 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "기록 삭제 취소" -Status "통과" -Evidence "기록 삭제 확인 상태의 취소 버튼과 상태 문구 확인"
}

if ($source -notmatch "HandleClearLocalDataButtonClick" -or
    $source -notmatch "RunSmokeClearLocalDataButtonClick" -or
    $source -notmatch "clear-data-action" -or
    $source -notmatch "prompt-button" -or
    $source -notmatch "confirm-button" -or
    $source -notmatch "저장 데이터와 기록이 완전히 지워집니다") {
    Add-Result -Item "저장 삭제 버튼 확정 조작" -Status "실패" -Evidence "저장 삭제 버튼이 실제 버튼 클릭, 확인, 확정 상태 증거로 연결되어 있지 않다."
    $failures++
} else {
    Add-Result -Item "저장 삭제 버튼 확정 조작" -Status "통과" -Evidence "저장 삭제 버튼의 첫 클릭/확정 클릭과 스모크 상태 증거 확인"
}

if ($source -notmatch "RecordArchivePreviewBodyFontSize\s*=\s*18" -or
    $source -notmatch "RecordArchivePreviewBodyColor\s*=\s*new Color32\(24,\s*32,\s*46,\s*255\)" -or
    $source -notmatch "RecordArchivePreviewBodyLineSpacing\s*=\s*1\.16f") {
    Add-Result -Item "기록함 미리보기 가독성" -Status "실패" -Evidence "저장 기록 미리보기 본문 크기, 잉크색, 줄간격 기준이 부족하다."
    $failures++
} else {
    Add-Result -Item "기록함 미리보기 가독성" -Status "통과" -Evidence "본문 18px, 짙은 잉크색, 1.16 줄간격 기준 확인"
}

if ($source -notmatch "HandlePlaytestFeedbackShortcuts" -or $source -notmatch "feedback-shortcut-action" -or $source -notmatch "GetPlaytestFeedbackGroupLabel") {
    Add-Result -Item "의견창 키보드/패드 조작" -Status "실패" -Evidence "플레이테스트 의견창 평가 선택과 저장을 키보드/패드로 완료하는 흐름이 부족하다."
    $failures++
} else {
    Add-Result -Item "의견창 키보드/패드 조작" -Status "통과" -Evidence "의견창 평가 선택, 문제 단계, 저장 단축 조작 확인"
}

if ($source -notmatch "ServerStatusIdleText" -or
    $source -notmatch "답변 연결은 정보 화면에서 확인할 수 있습니다" -or
    $source -notmatch "답변 연결 없음 · 내장 답변으로 계속합니다" -or
    $source -match "로컬 서버 상태는 상태 확인으로 점검합니다|로컬 서버 상태를 확인하고 있습니다|런처로 실행하면 자동으로 확인") {
    Add-Result -Item "정보 화면 서버 상태 문구" -Status "실패" -Evidence "정보 화면의 로컬 서버 상태가 대기/로딩 문구로 남을 수 있다."
    $failures++
} else {
    Add-Result -Item "정보 화면 서버 상태 문구" -Status "통과" -Evidence "정보 화면 기본/실패 상태가 답변 연결과 내장 답변 지속 문구로 고정됨"
}

if ($launcherSource -notmatch "Server response was not confirmed within 8 seconds" -or
    $launcherSource -notmatch "built-in evidence answers" -or
    $launcherSource -notmatch "Skipping automatic server start; text chat will use the server only if it is already running") {
    Add-Result -Item "런처 서버 실패 안내" -Status "실패" -Evidence "서버 자동 시작 실패나 -NoStartServer 경로에서 내장 근거 답변 지속과 진단 방법을 충분히 안내하지 않는다."
    $failures++
} else {
    Add-Result -Item "런처 서버 실패 안내" -Status "통과" -Evidence "서버 미응답과 -NoStartServer 경로가 내장 근거 답변 지속 및 지원 번들 진단을 안내함"
}

if ($source -match "겉 판단과 속 이야기가 달라질|그 선택을 뒤집|어디까지 맞고 어디서부터 부족|첫 인상이 하루 전체를 얼마나 좁게") {
    Add-Result -Item "제품 제목 의미" -Status "실패" -Evidence "겉!=속 제목과 어긋나는 반전/불일치 중심 문구가 남아 있다."
    $failures++
} elseif ($source -notmatch "먼저 보인 장면과 생활의 맥락이 이어져" -or $source -notmatch "그 장면이 생활과 어떻게 이어지는지") {
    Add-Result -Item "제품 제목 의미" -Status "실패" -Evidence "겉!=속 제목을 플레이 규칙으로 설명하는 문구가 부족하다."
    $failures++
} else {
    Add-Result -Item "제품 제목 의미" -Status "통과" -Evidence "첫 인상, 질문 태도, 답변 프레이밍이 먼저 보인 장면과 생활 맥락의 연결을 확인함"
}

if ($source -notmatch "GetThemeForFirstImpression" -or $source -notmatch "IsFirstImpressionTheme" -or $source -notmatch "BuildFirstImpressionResonanceLine" -or $source -notmatch "GetRecommendedClosingIndex" -or $source -notmatch "BuildFirstImpressionTargetLine" -or $source -notmatch "first-impression-target" -or $source -notmatch "처음 보인 장면은 하루와 같은 선 위에 있다") {
    Add-Result -Item "첫 인상 선택 결과 반영" -Status "실패" -Evidence "첫 인상 선택이 깊은 기록과 마무리 카드 추천에 연결되는 소스 근거가 부족하다."
    $failures++
} else {
    Add-Result -Item "첫 인상 선택 결과 반영" -Status "통과" -Evidence "첫 인상 테마 매핑, 깊은 기록 연결, 엔딩 공명 문장, 추천 마무리 카드, 진행 안내 상태 확인"
}

if ($source -notmatch "BuildMemoryBookSubtitle" -or $source -notlike "*첫 인상 {firstImpression}에서 {theme} 장면으로 이어가 보세요*" -or $source -notlike "*첫 인상 {firstImpression}에서 {theme} 깊은 기록을 더 물어보세요*") {
    Add-Result -Item "깊은 기록 목표 안내" -Status "실패" -Evidence "기억장/질문 노트에서 첫 인상 목표와 깊은 기록 목표를 안내하는 문구가 부족하다."
    $failures++
} else {
    Add-Result -Item "깊은 기록 목표 안내" -Status "통과" -Evidence "기억장과 질문 노트가 첫 인상 장면 및 깊은 기록 목표를 안내함"
}

if ($source -notmatch "BuildMemoryRewardLine" -or
    $source -notmatch "lastRewardLine" -or
    $source -notmatch "reward-line" -or
    $source -notmatch "reward-toast-visible" -or
    $source -notmatch "reward-toast-text" -or
    $source -notmatch "새 기록:" -or
    $source -notmatch "기록함" -or
    $source -notmatch "깊은 기록") {
    Add-Result -Item "장면 보상 피드백" -Status "실패" -Evidence "장면/깊은 기록을 열었을 때 즉시 보이는 보상 문구와 스모크 상태 감사가 부족하다."
    $failures++
} else {
    Add-Result -Item "장면 보상 피드백" -Status "통과" -Evidence "보상 토스트, 기록함 안내, 깊은 기록 유도 문구, 상태 감사 확인"
}

if ($source -notmatch "BuildFirstImpressionTargetQuestion" -or $source -notmatch "AddFirstImpressionTargetQuestion" -or $source -notmatch "목발은 하루의 이동과 어떻게 이어지나요" -or $source -notmatch "책상은 일과 공부, 이동의 리듬과 어떻게 이어지나요" -or $source -notmatch "표정 뒤의 평범한 하루는 어떤 장면으로 이어지나요") {
    Add-Result -Item "첫 인상 목표 질문 추천" -Status "실패" -Evidence "첫 인상 선택을 깊은 기록 질문 추천으로 우선 연결하는 근거가 부족하다."
    $failures++
} else {
    Add-Result -Item "첫 인상 목표 질문 추천" -Status "통과" -Evidence "목발/책상/표정 첫 인상별 목표 질문이 추천 질문 목록에 우선 반영됨"
}

if ($source -notmatch "GetStoryModeNextButtonLabel" -or
    $source -notmatch 'return \$"다음 \{next\}/\{total\}"' -or
    $source -notmatch '"마무리로"' -or
    $source -notmatch "story\\tnext-label") {
    Add-Result -Item "이야기 모드 진행 버튼" -Status "실패" -Evidence "이야기 모드의 다음 버튼이 현재 장면 진행도를 플레이어에게 보여주지 않는다."
    $failures++
} else {
    Add-Result -Item "이야기 모드 진행 버튼" -Status "통과" -Evidence "다음 2/6 같은 진행 라벨과 마지막 마무리 라벨, 상태 감사 확인"
}

if ($source -notmatch "GetSoundLevelLabel" -or $source -notmatch "소리 끔" -or $source -notmatch "소리 작게" -or $source -notmatch "소리 기본" -or $source -notmatch "AppendSmokeAudioState") {
    Add-Result -Item "소리 설정 표현" -Status "실패" -Evidence "소리 설정 단계 라벨 또는 런타임 상태 감사가 부족하다."
    $failures++
} else {
    Add-Result -Item "소리 설정 표현" -Status "통과" -Evidence "소리 끔/작게/기본 라벨과 오디오 상태 감사 확인"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상용 UI 문구 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 소스: $SourcePath")
$lines.Add("- 페르소나: $PersonaPath")
$lines.Add("- 실패: $failures")
$lines.Add("")
$lines.Add("이 검증은 Steam 유료 판매 빌드에서 플레이어가 보는 화면과 저장 메모에 미완성판처럼 보이는 표현이 남지 않도록 확인한다.")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $($result.Item) | $($result.Status) | $($result.Evidence) |")
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failures -gt 0) {
    throw "Commercial UI copy QA failed: $failures failure(s)."
}

Write-Host "Commercial UI copy QA passed: $OutputPath"

