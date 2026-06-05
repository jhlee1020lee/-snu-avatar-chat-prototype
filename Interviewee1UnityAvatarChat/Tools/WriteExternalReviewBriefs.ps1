param(
    [string]$OutputPath,
    [string]$EvidenceRoot,
    [string]$BriefRoot,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

function ConvertTo-LongPath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith("\\?\")) {
        return $full
    }
    if ($full.StartsWith("\\")) {
        return "\\?\UNC\" + $full.Substring(2)
    }
    return "\\?\" + $full
}

function Ensure-Directory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Write-TextFile {
    param(
        [string]$Path,
        [object]$Lines
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)
    Set-Content -LiteralPath (ConvertTo-LongPath -Path $Path) -Value $Lines -Encoding UTF8
}

function Assert-NoApiKeyPattern {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            continue
        }

        $matches = Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($matches) {
            throw "External review brief contains an API key pattern: $path"
        }
    }
}

function New-BriefLines {
    param(
        [string]$Title,
        [string]$Purpose,
        [string]$Timebox,
        [string]$Package,
        [string]$SubmitLocation,
        [string[]]$BeforeSession,
        [string[]]$ReviewerTasks,
        [string[]]$RequiredFiles,
        [string[]]$StopRules,
        [string[]]$ValidationCommands,
        [string]$InviteBody
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# $Title")
    $lines.Add("")
    $lines.Add("- 목적: $Purpose")
    $lines.Add("- 예상 시간: $Timebox")
    $lines.Add("- 전달 패키지: $Package")
    $lines.Add("- 제출 위치: $SubmitLocation")
    $lines.Add("- 주의: 이 파일은 안내문이다. 실제 증거로 세지 않는다.")
    $lines.Add("")
    $lines.Add("## 시작 전 확인")
    $lines.Add("")
    foreach ($item in $BeforeSession) {
        $lines.Add("- $item")
    }
    $lines.Add("")
    $lines.Add("## 리뷰어 작업")
    $lines.Add("")
    foreach ($item in $ReviewerTasks) {
        $lines.Add("- $item")
    }
    $lines.Add("")
    $lines.Add("## 제출 파일")
    $lines.Add("")
    foreach ($item in $RequiredFiles) {
        $lines.Add("- $item")
    }
    $lines.Add("")
    $lines.Add("## 중단 기준")
    $lines.Add("")
    foreach ($item in $StopRules) {
        $lines.Add("- $item")
    }
    $lines.Add("")
    $lines.Add("## 검증 명령")
    $lines.Add("")
    $lines.Add('```powershell')
    foreach ($command in $ValidationCommands) {
        $lines.Add($command)
    }
    $lines.Add('```')
    $lines.Add("")
    $lines.Add("## 초대 문구")
    $lines.Add("")
    $lines.Add('```text')
    $lines.Add($InviteBody)
    $lines.Add('```')
    $lines.Add("")
    $lines.Add("## 금지 자료")
    $lines.Add("")
    $lines.Add("- OpenAI, Steam, GitHub, 운영 계정의 비밀키나 비밀번호")
    $lines.Add("- Steam Guard 코드, 결제 정보, 개인 계정 보안 질문")
    $lines.Add("- 참가자가 공개에 동의하지 않은 이름, 연락처, 학교/직장 식별 정보")
    $lines.Add("- 내부 개발자 메모나 임시 로그")
    return $lines
}

function New-DecisionCalibrationLines {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("area`tprice_ready_4_or_5`tborderline_3`tblocker_or_2_or_less`trequired_evidence")
    $lines.Add("core_loop`t처음 1분 안에 목표를 이해하고 5문답, 기억장, 마무리 카드가 한 세션처럼 이어진다.`t5문답은 가능하지만 다음 행동이나 마무리 동기가 약하다.`t첫 질문 시작, 5문답 완주, 마무리 카드 중 하나가 막히거나 진행자가 계속 개입해야 한다.`tPlaytest observation form; feedback txt/json; support bundle")
    $lines.Add("writing`t답변이 확인된 자료 안에서 자연스럽고 사람책 인터뷰 톤으로 이어진다.`t답변은 맞지만 반복적이거나 설명문처럼 느껴지는 구간이 있다.`t자료 밖 개인정보를 만들거나 AI 정체성, 프롬프트, 내부 구현 말투가 플레이 중 보인다.`tPlaytest notes; content QA report; issue register")
    $lines.Add("readability`t긴 답변, 큰 글자, 스크롤, 고대비에서 주요 문장이 잘 읽힌다.`t읽을 수는 있지만 글자 밀도, 스크롤 안내, 버튼 판독에 약점이 있다.`t텍스트가 잘리거나 겹쳐 핵심 답변 또는 버튼을 읽기 어렵다.`tAccessibility observation form; screenshots or recording")
    $lines.Add("controls`t키보드, 마우스, 패널, 저장과 삭제 흐름이 예측 가능하고 되돌릴 수 있다.`t주요 조작은 되지만 단축키, 패널 닫기, 삭제 확인이 헷갈린다.`t키보드만으로 5문답 또는 기록 저장을 완료할 수 없다.`tAccessibility observation form; playtest notes; issue register")
    $lines.Add("trust_privacy`t마이크, API, 로컬 저장, 삭제 안내가 명확하고 비밀정보가 패키지에 없다.`t신뢰 문구는 있으나 플레이어가 저장 위치나 서버 사용 여부를 추가로 물어본다.`t비밀키, 계정 정보, 동의 없는 개인정보가 증거나 패키지에 포함된다.`tLegal/Steam checklist; privacy final text; secret scan QA")
    $lines.Add("art_presentation`t캐릭터, 배경, 캡슐, 스크린샷이 실제 게임과 같은 톤이고 작은 캡슐도 읽힌다.`t상점 첫인상은 가능하지만 일부 이미지의 판독성이나 톤 일관성이 약하다.`t작은 캡슐 제목, 캐릭터 비율, 경계선 잔상, 어두운 톤 문제가 구매 판단을 막는다.`tArt review form; marked images or PDF")
    $lines.Add("trailer_store`t첫 10초에 플레이 목적과 실제 조작 흐름이 보이고 자막이 읽힌다.`t게임 목적은 보이지만 속도, 자막, 장면 순서가 약하다.`t실제 플레이가 보이지 않거나 자막이 가리고 상점 문구와 영상이 다른 게임처럼 보인다.`tFinal trailer file; captions; trailer review form")
    $lines.Add("stability_package`tWindows 패키지, Node 런타임, fallback, 지원 번들이 같은 buildId로 검증된다.`t자동 패키지는 통과하지만 최신 런타임 캡처나 피드백 export가 빠져 있다.`t패키지 buildId 불일치, 실행 실패, fallback 실패, 지원 번들 비밀정보 포함이 있다.`tRelease readiness report; package QA; support bundle")
    return $lines
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEW_BRIEFS.md"
}
if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($BriefRoot)) {
    $BriefRoot = Join-Path $EvidenceRoot "ReviewBriefs"
}

Ensure-Directory -Path $BriefRoot

$briefs = @(
    [pscustomobject]@{
        File = "PLAYTEST_REVIEW_BRIEF.md"
        Title = "외부 플레이테스트 리뷰 브리프"
        Purpose = "처음 1분 이해도, 5문답 완주, 긴 답변 스크롤, 저장/기록 흐름을 실제 참가자로 확인한다."
        Timebox = "참가자 1명당 20분, 전체 5명 이상"
        Package = "ExternalPlaytestPackage"
        SubmitLocation = "EvidenceDrop\Playtest\session-01 부터 session-05"
        Before = @(
            "참가자에게 PLAYTEST_PARTICIPANT_BRIEF.md를 먼저 보여준다.",
            "진행자는 PLAYTEST_MODERATOR_SCRIPT.md의 개입 기준을 따른다.",
            "앱 설정에서 로컬만, 글자 크기, 소리 옵션 위치를 미리 확인한다."
        )
        Tasks = @(
            "참가자가 도움 없이 처음 질문을 시작하는지 관찰한다.",
            "최소 5번 질문과 답변을 진행하게 한다.",
            "긴 답변에서 스크롤바나 스크롤 안내를 알아차리는지 기록한다.",
            "기억장, 오늘 남길 문장, 기록함까지 이어지는지 확인한다.",
            "문장 첫머리, 별표 강조, AI식 정체성 고지, 너무 짧게 깜박이는 접수 문구가 보이면 이슈로 등록한다."
        )
        Files = @(
            "채워진 PLAYTEST_OBSERVATION_FORM.md",
            "앱이 저장한 feedback txt와 json",
            "세션 직후 생성한 support bundle",
            "문제가 보이는 화면 캡처나 짧은 녹화",
            "EXTERNAL_ISSUE_REGISTER.tsv에 등록한 이슈"
        )
        Stops = @(
            "참가자가 첫 질문 시작 방법을 찾지 못하고 2분 이상 멈추면 P1 후보로 등록한다.",
            "긴 답변이 화면 밖으로 나가 읽을 수 없으면 P1 후보로 등록한다.",
            "비밀키, 계정 정보, 개인 연락처가 증거 파일에 들어가면 즉시 중단하고 삭제한다."
        )
        Commands = @(
            'Tools\ValidatePlaytestFeedbackExport.ps1 -FeedbackRoot "<feedback folder>" -RequireFiveTurnSession',
            'Tools\NewPlaytestEvidenceBundle.ps1 -SessionId "session-01" -EvidenceRoot "EvidenceDrop\Playtest" -ObservationFormPath "<filled form>"',
            'Tools\CollectExternalEvidenceSession.ps1 -SessionId "session-01" -EvidenceRoot "EvidenceDrop\Playtest" -FeedbackPath "<feedback txt>" -FeedbackManifestPath "<feedback json>" -ObservationFormPath "<filled form>" -SupportBundleRoot "<support bundle>"',
            'Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest"'
        )
        Invite = "안녕하세요. 겉!=속 외부 플레이테스트를 부탁드립니다. 20분 정도 게임을 진행하면서 첫 질문 시작, 5문답 완주, 긴 답변 읽기, 기록 저장 흐름을 관찰해 주세요. 끝나면 관찰 양식, 앱 피드백 txt/json, support bundle, 문제 화면을 EvidenceDrop\Playtest 세션 폴더에 넣어 주세요. 계정 비밀번호나 비밀키는 어떤 파일에도 넣지 말아 주세요."
    },
    [pscustomobject]@{
        File = "ACCESSIBILITY_REVIEW_BRIEF.md"
        Title = "접근성 리뷰 브리프"
        Purpose = "키보드 조작, 글자 크기, 화면 확대, 고대비 환경에서 대화 흐름이 유지되는지 확인한다."
        Timebox = "40분"
        Package = "CommercialReviewPackage"
        SubmitLocation = "EvidenceDrop\Accessibility"
        Before = @(
            "Windows 화면 배율 100%, 150%, 200% 중 최소 두 조건을 정한다.",
            "마우스 없이 키보드만으로 시작, 질문, 설정, 기록함, 종료를 시도한다.",
            "가능하면 고대비 또는 색약 보정 환경을 함께 켠다."
        )
        Tasks = @(
            "처음부터, 이어하기, 질문폰, 기억장, 마무리 카드, 설정 메뉴의 초점 이동을 확인한다.",
            "긴 답변 스크롤과 글자 크기 조절이 겹치거나 잘리지 않는지 본다.",
            "캐릭터, 하단 대사창, 질문 버튼이 배율 변경 후에도 서로 겹치지 않는지 캡처한다.",
            "스크린리더 사용 가능 여부를 확인했다면 읽히는 라벨과 읽히지 않는 영역을 적는다."
        )
        Files = @(
            "채워진 ACCESSIBILITY_OBSERVATION_FORM.md",
            "화면 배율별 캡처나 녹화",
            "키보드 전용 조작 실패가 있으면 재현 단계",
            "EXTERNAL_ISSUE_REGISTER.tsv에 등록한 접근성 이슈"
        )
        Stops = @(
            "키보드만으로 5문답을 진행할 수 없으면 P1 이상 후보로 등록한다.",
            "긴 답변 또는 버튼 글자가 3번째 줄부터 잘리면 P1 후보로 등록한다.",
            "시각 효과 때문에 텍스트 판독이 어렵다는 판단이 나오면 상점 후보에서 내린다."
        )
        Commands = @(
            'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop"'
        )
        Invite = "안녕하세요. 겉!=속 접근성 검토를 부탁드립니다. 키보드 전용 조작, 화면 배율, 큰 글자, 고대비 조건에서 대화와 기록 저장이 가능한지 봐 주세요. 결과는 접근성 관찰 양식과 캡처/녹화로 EvidenceDrop\Accessibility에 넣어 주세요. 개인 계정 정보나 비밀키는 포함하지 말아 주세요."
    },
    [pscustomobject]@{
        File = "ART_REVIEW_BRIEF.md"
        Title = "아트 리뷰 브리프"
        Purpose = "캐릭터 비율, 보라색 경계선 잔상, 밝은 인터뷰룸 톤, Steam 캡슐 판독성을 외부 시선으로 확인한다."
        Timebox = "45분"
        Package = "SteamSubmissionPackage와 CommercialReviewPackage"
        SubmitLocation = "EvidenceDrop\ArtReview"
        Before = @(
            "Steam 캡슐, 스크린샷, 키아트, 실제 게임 화면을 함께 연다.",
            "작은 캡슐 120x45 미리보기와 462x174 이미지를 우선 확인한다.",
            "게임 본문 화면과 상점 이미지의 분위기가 어긋나는지 비교한다."
        )
        Tasks = @(
            "캐릭터가 좌우로 눌려 보이는지, 경계선 잔상이 남는지 표시한다.",
            "배경이 인터뷰 공간으로 보이는지, 어둡거나 심문실처럼 보이지 않는지 판단한다.",
            "Steam 작은 캡슐에서 제목과 인물 실루엣이 읽히는지 확인한다.",
            "상점 스크린샷이 실제 플레이를 충분히 보여주는지 본다."
        )
        Files = @(
            "채워진 ART_REVIEW_FORM.md",
            "표시가 들어간 png, jpg, 또는 PDF",
            "승인 또는 보류 결론",
            "EXTERNAL_ISSUE_REGISTER.tsv에 등록한 아트 이슈"
        )
        Stops = @(
            "작은 캡슐 제목이 읽히지 않으면 보류한다.",
            "캐릭터 비율이나 보라색 경계선 문제가 남으면 상점 이미지 승인으로 보지 않는다.",
            "게임 화면과 상점 키아트 톤이 서로 다른 게임처럼 보이면 보류한다."
        )
        Commands = @(
            'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop"'
        )
        Invite = "안녕하세요. 겉!=속 상업 아트 검토를 부탁드립니다. 캐릭터 비율, 보라색 잔상, 밝은 인터뷰룸 톤, Steam 캡슐 판독성을 봐 주세요. 검토 양식과 표시 이미지를 EvidenceDrop\ArtReview에 넣어 주시면 됩니다. 계정 정보나 비밀키는 포함하지 말아 주세요."
    },
    [pscustomobject]@{
        File = "TRAILER_REVIEW_BRIEF.md"
        Title = "트레일러 리뷰 브리프"
        Purpose = "실제 플레이 기반 최종 영상이 10초 안에 대화 게임의 목적과 조작 흐름을 전달하는지 확인한다."
        Timebox = "50분"
        Package = "SteamSubmissionPackage와 CommercialReviewPackage"
        SubmitLocation = "EvidenceDrop\Trailer"
        Before = @(
            "애니매틱과 빌드 캡처 후보를 참고하되 최종 증거는 실제 조작 녹화여야 한다.",
            "자막 파일과 최종 영상 파일명이 서로 연결되게 준비한다.",
            "Steam 상점 첫 영상으로 볼 때 10초 안의 정보량을 먼저 본다."
        )
        Tasks = @(
            "첫 10초에 질문, 답변, 기억장, 기록 저장 중 최소 두 흐름이 보이는지 확인한다.",
            "자막이 대사창이나 버튼을 가리지 않는지 본다.",
            "사운드가 너무 크거나 작아 대화 톤을 해치지 않는지 확인한다.",
            "영상이 실제 플레이와 다르게 과장된 인상을 주지 않는지 판단한다."
        )
        Files = @(
            "최종 mp4, mov, 또는 webm",
            "자막 srt 또는 vtt",
            "채워진 TRAILER_FINAL_REVIEW_FORM.md",
            "EXTERNAL_ISSUE_REGISTER.tsv에 등록한 트레일러 이슈"
        )
        Stops = @(
            "첫 10초에 게임 목적이 보이지 않으면 보류한다.",
            "자막 누락 또는 자막 겹침이 있으면 보류한다.",
            "최종 영상이 실제 플레이가 아니라면 최종 트레일러 증거로 보지 않는다."
        )
        Commands = @(
            'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop"'
        )
        Invite = "안녕하세요. 겉!=속 최종 트레일러 검토를 부탁드립니다. 실제 플레이 기반 영상이 대화, 기억장, 기록 저장 흐름을 10초 안에 보여주는지 확인해 주세요. 최종 영상, 자막, 리뷰 양식을 EvidenceDrop\Trailer에 넣어 주세요. 계정 정보나 비밀키는 포함하지 말아 주세요."
    },
    [pscustomobject]@{
        File = "LEGAL_STEAM_REVIEW_BRIEF.md"
        Title = "Steam 관리자와 법무 리뷰 브리프"
        Purpose = "AppID, DepotID, 테스트 브랜치 실행, 개인정보 문구, 문의 채널이 실제 출시 주체 기준으로 맞는지 확인한다."
        Timebox = "60분"
        Package = "SteamSubmissionPackage와 Steamworks staging package"
        SubmitLocation = "EvidenceDrop\LegalSteam"
        Before = @(
            "Steamworks 계정 화면은 비밀정보가 보이지 않게 캡처 범위를 제한한다.",
            "AppID와 DepotID는 값 자체보다 설정 완료 여부와 파일명 증거를 남긴다.",
            "개인정보 문구는 배포 주체, 문의 채널, 저장 데이터 범위를 최종 문장으로 정한다."
        )
        Tasks = @(
            "Steamworks 업로드 계획과 실제 관리자 설정이 맞는지 확인한다.",
            "테스트 브랜치에서 Windows 패키지가 실행되는지 증거를 남긴다.",
            "개인정보 문구가 앱 정보 화면, README, 상점 문구와 어긋나지 않는지 본다.",
            "비밀정보가 패키지나 증거 폴더에 들어가지 않았는지 확인한다."
        )
        Files = @(
            "채워진 STEAM_ADMIN_CHECKLIST.md",
            "PRIVACY_NOTICE_FINAL.md",
            "테스트 브랜치 실행 캡처 또는 PDF",
            "AppID/DepotID 설정 완료를 보여주는 비밀정보 없는 증거"
        )
        Stops = @(
            "Steam 계정 비밀번호, Guard 코드, 비밀키가 보이면 즉시 삭제하고 다시 캡처한다.",
            "테스트 브랜치 실행 증거가 없으면 최종 제출로 보지 않는다.",
            "개인정보 최종 문구가 없으면 출시 후보로 보지 않는다."
        )
        Commands = @(
            'Tools\ValidateSteamLegalReadiness.ps1',
            'Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop"'
        )
        Invite = "안녕하세요. 겉!=속 Steam 관리자와 법무 검토를 부탁드립니다. Steamworks 설정, 테스트 브랜치 실행, 개인정보 최종 문구가 맞는지 확인해 주세요. 비밀정보가 보이지 않는 증거만 EvidenceDrop\LegalSteam에 넣어 주세요. 비밀번호, Guard 코드, 비밀키는 절대 포함하지 말아 주세요."
    },
    [pscustomobject]@{
        File = "QUALITY_SCORECARD_REVIEW_BRIEF.md"
        Title = "5달러 품질 점수표 리뷰 브리프"
        Purpose = "외부 증거를 근거로 5달러 이상 유료 판매 후보인지 같은 기준으로 점수화한다."
        Timebox = "60분"
        Package = "CommercialReviewPackage"
        SubmitLocation = "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv"
        Before = @(
            "COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv는 참고용으로만 본다.",
            "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv에서 영역별 기존 자동 QA, 스모크 캡처, 상점 자료 경로를 먼저 확인한다.",
            "각 점수에는 reviewer와 실제 존재하는 evidence 상대 경로를 반드시 적는다.",
            "평균 4.0 이상, 최저 3 이상, 차단 항목 0이 아니면 최종 후보가 아니다."
        )
        Tasks = @(
            "core_loop, writing, readability, controls, trust_privacy, art_presentation, trailer_store, stability_package를 각각 평가한다.",
            "점수 근거가 되는 플레이테스트, 접근성, 아트, 트레일러, Steam/법무 증거 경로를 EvidenceDrop 기준 상대 경로로 적는다.",
            "차단 항목은 점수와 별개로 blocker 필드에 표시한다.",
            "P0/P1 이슈가 있으면 점수표를 통과로 만들지 않는다."
        )
        Files = @(
            "채워진 COMMERCIAL_QUALITY_SCORECARD.tsv",
            "참고한 COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv 행 또는 실제 증거 경로",
            "참고한 증거 파일 전체",
            "점수 보류 사유가 있으면 EXTERNAL_ISSUE_REGISTER.tsv 이슈"
        )
        Stops = @(
            "reviewer 또는 evidence가 비어 있으면 공식 점수표로 보지 않는다.",
            "evidence 경로가 실제 파일이나 폴더를 가리키지 않으면 보류한다.",
            "평균 4.0 미만, 최저 3 미만, 차단 항목 1개 이상이면 보류한다.",
            "외부 증거 없이 내부 자동 QA만으로 점수를 채우면 보류한다."
        )
        Commands = @(
            'Tools\ValidateCommercialQualityRubric.ps1 -ScorecardPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv"',
            'Tools\ValidateCommercialQualityRubric.ps1 -ScorecardPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" -RequireReady'
        )
        Invite = "안녕하세요. 겉!=속 5달러 품질 점수표 검토를 부탁드립니다. 외부 플레이테스트, 접근성, 아트, 트레일러, Steam/법무 증거를 근거로 8개 영역을 채점해 주세요. 점수표에는 reviewer와 실제 존재하는 evidence 상대 경로를 반드시 남겨 주세요. 계정 정보나 비밀키는 포함하지 말아 주세요."
    }
)

$written = New-Object System.Collections.Generic.List[string]
foreach ($brief in $briefs) {
    $path = Join-Path $BriefRoot $brief.File
    $lines = New-BriefLines `
        -Title $brief.Title `
        -Purpose $brief.Purpose `
        -Timebox $brief.Timebox `
        -Package $brief.Package `
        -SubmitLocation $brief.SubmitLocation `
        -BeforeSession $brief.Before `
        -ReviewerTasks $brief.Tasks `
        -RequiredFiles $brief.Files `
        -StopRules $brief.Stops `
        -ValidationCommands $brief.Commands `
        -InviteBody $brief.Invite
    Write-TextFile -Path $path -Lines $lines
    $written.Add($path) | Out-Null
}

$inviteLines = New-Object System.Collections.Generic.List[string]
$inviteLines.Add("# 외부 리뷰 초대 문구 모음")
$inviteLines.Add("")
$inviteLines.Add("아래 문구는 메신저나 이메일에 그대로 붙여 넣기 위한 초안이다. 실제 계정 정보, 비밀번호, 비밀키는 어떤 문구에도 넣지 않는다.")
foreach ($brief in $briefs) {
    $inviteLines.Add("")
    $inviteLines.Add("## $($brief.Title)")
    $inviteLines.Add("")
    $inviteLines.Add('```text')
    $inviteLines.Add($brief.Invite)
    $inviteLines.Add('```')
}
$invitePath = Join-Path $BriefRoot "REVIEW_INVITATION_TEMPLATES.md"
Write-TextFile -Path $invitePath -Lines $inviteLines
$written.Add($invitePath) | Out-Null

$calibrationPath = Join-Path $BriefRoot "REVIEW_DECISION_CALIBRATION.tsv"
Write-TextFile -Path $calibrationPath -Lines (New-DecisionCalibrationLines)
$written.Add($calibrationPath) | Out-Null

$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("# 외부 리뷰 브리프")
$summary.Add("")
$summary.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$summary.Add("- 증거 루트: $EvidenceRoot")
$summary.Add("- 브리프 폴더: $BriefRoot")
$summary.Add("")
$summary.Add("이 문서는 외부 검증을 시작하기 전에 담당자에게 넘길 안내 묶음이다. 자동 QA나 내부 점수를 대체하지 않고, 실제 증거를 모으기 위한 운영 문서다.")
$summary.Add("")
$summary.Add("## 역할별 브리프")
$summary.Add("")
$summary.Add("| 역할 | 파일 | 제출 위치 | 완료 기준 |")
$summary.Add("| --- | --- | --- | --- |")
$summary.Add("| 외부 플레이테스트 | ReviewBriefs\PLAYTEST_REVIEW_BRIEF.md | EvidenceDrop\Playtest | 5명 이상 완성 세션, P0/P1 0 |")
$summary.Add("| 접근성 검토 | ReviewBriefs\ACCESSIBILITY_REVIEW_BRIEF.md | EvidenceDrop\Accessibility | 관찰 양식과 화면/녹화 증거 |")
$summary.Add("| 아트 리뷰 | ReviewBriefs\ART_REVIEW_BRIEF.md | EvidenceDrop\ArtReview | 검토 양식, 표시 이미지, 승인 또는 보류 결론 |")
$summary.Add("| 트레일러 리뷰 | ReviewBriefs\TRAILER_REVIEW_BRIEF.md | EvidenceDrop\Trailer | 최종 영상, 자막, 리뷰 양식 |")
$summary.Add("| Steam 관리자/법무 | ReviewBriefs\LEGAL_STEAM_REVIEW_BRIEF.md | EvidenceDrop\LegalSteam | Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 |")
$summary.Add("| 5달러 품질 점수표 | ReviewBriefs\QUALITY_SCORECARD_REVIEW_BRIEF.md | EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv | 평균 4.0 이상, 최저 3 이상, 차단 0 |")
$summary.Add("| 공통 판정 기준표 | ReviewBriefs\REVIEW_DECISION_CALIBRATION.tsv | 모든 리뷰 영역 | 3점, 4점 이상, 차단 기준을 같은 문장으로 적용 |")
$summary.Add("")
$summary.Add("## 운영 순서")
$summary.Add("")
$summary.Add("1. Build\ReleaseEvidence\ReviewBriefs의 역할별 파일을 담당자에게 보낸다.")
$summary.Add("2. 모든 담당자에게 ReviewBriefs\REVIEW_DECISION_CALIBRATION.tsv를 함께 보내 점수 기준을 맞춘다.")
$summary.Add("3. 각 담당자는 제출 위치에 실제 증거를 넣는다.")
$summary.Add("4. 발견 이슈는 RegisterExternalIssue.ps1로 등록한다.")
$summary.Add("5. 증거를 넣은 뒤 RUN_EVIDENCE_AUDIT.bat 또는 아래 명령을 실행한다.")
$summary.Add("6. 최종 회의 직전 RUN_FINAL_EVIDENCE_GATE.bat와 RunCommercialLaunchGate.ps1 -RequireLaunchReady를 실행한다.")
$summary.Add("")
$summary.Add("## 검증 명령")
$summary.Add("")
$summary.Add('```powershell')
$summary.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewBriefs.ps1")
$summary.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete")
$summary.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady")
$summary.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady")
$summary.Add('```')
$summary.Add("")
$summary.Add("## 보안")
$summary.Add("")
$summary.Add("- OpenAI, Steam, GitHub, 운영 계정의 비밀키나 비밀번호를 문서나 증거 폴더에 넣지 않는다.")
$summary.Add("- Steam Guard 코드, 결제 정보, 개인 계정 보안 질문을 캡처하지 않는다.")
$summary.Add("- 참가자 실명, 연락처, 학교/직장 식별 정보는 동의 없이 남기지 않는다.")

Write-TextFile -Path $OutputPath -Lines $summary
$written.Add($OutputPath) | Out-Null

Assert-NoApiKeyPattern -Paths $written.ToArray()

Write-Host "External review briefs written: $OutputPath"
Write-Host "Review brief folder: $BriefRoot"


