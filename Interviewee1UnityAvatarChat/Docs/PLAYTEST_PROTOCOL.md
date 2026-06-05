# 플레이테스트 프로토콜

`겉!=속`를 5달러 이상 유료 판매 후보로 검토하기 위한 플레이테스트 운영 문서다.

## 목표

- 첫 1분 안에 플레이어가 무엇을 하는 게임인지 이해하는지 확인한다.
- 5문답 세션에서 질문 선택, 직접 입력, 기억장, 마무리 카드가 자연스럽게 이어지는지 본다.
- 저장 기록과 삭제 안내가 신뢰를 주는지 확인한다.
- 글자 크기, 소리, 움직임 줄임 설정이 실제로 필요한 플레이어에게 발견되는지 본다.

## 권장 참가자

- 내러티브 게임 경험자 2명
- 접근성 옵션에 민감한 사용자 1명 이상
- 수업/전시 맥락을 모르는 일반 사용자 2명

## 진행 순서

1. `PLAYTEST_PARTICIPANT_BRIEF.md`를 참가자에게 전달하고 개인정보 입력 금지와 중단 가능성을 안내한다.
2. `PLAYTEST_MODERATOR_SCRIPT.md`의 시작 전 준비를 확인한다.
3. 아무 설명 없이 타이틀 화면에서 시작하게 한다.
4. 참가자가 질문폰을 열거나 직접 질문하도록 둔다.
5. 최소 5문답을 진행해 마무리 카드를 열게 한다.
6. 기억장, 기록함, 설정, 정보 화면을 스스로 찾는지 본다.
7. 마무리 카드의 `의견` 버튼으로 로컬 피드백을 남기게 한다.
8. 테스트 진행자는 `FeedbackNotes` 폴더의 텍스트와 JSON 파일을 모아 이슈로 분류한다.
9. 발견한 문제는 `RegisterExternalIssue.ps1`로 `EXTERNAL_ISSUE_REGISTER.tsv`에 등록한다.
10. 테스트 뒤 `NewPlaytestEvidenceBundle.ps1`로 최신 피드백, 관찰 기록, 지원 번들을 한 세션 폴더에 묶는다. 피드백/지원 번들 경로를 직접 지정해야 할 때만 `CollectExternalEvidenceSession.ps1`를 쓴다.
11. `ExportFeedbackToCommercialQualityScorecard.ps1`나 패키지의 `RUN_EVIDENCE_AUDIT.bat`로 피드백 기반 품질 점수표 초안을 만든다.

## 운영 패키지 생성

외부 참가자에게 넘길 패키지는 실행 파일과 관찰 문서, 증거 수집 폴더를 함께 묶는다.

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeExternalPlaytestPackage.ps1 -PackageName "GeotNotEqualSok-ExternalPlaytest-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalPlaytestPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA
```

관찰자는 `Forms/PLAYTEST_OBSERVATION_FORM.md`를 채우고, 발견한 문제는 `Forms/PLAYTEST_ISSUE_TRIAGE.md` 기준으로 분류한다.
진행자는 `ObserverDocs/PLAYTEST_MODERATOR_SCRIPT.md`를 기준으로 개입 시점과 종료 질문을 통일한다.
참가자에게는 `ObserverDocs/PLAYTEST_PARTICIPANT_BRIEF.md`를 전달한다.
참가자가 남긴 앱 내 피드백은 세션 ID, 빌드 ID, 화면 크기, 접근성 설정 상태를 함께 저장한다.

세션 증거 폴더를 만들 때는:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidatePlaytestFeedbackExport.ps1 -FeedbackRoot "<PlaytestFeedback folder>" -RequireFiveTurnSession
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RegisterExternalIssue.ps1 -IssueId "EXT-001" -Priority "P1" -Area "핵심 루프" -Source "session-01" -SessionId "session-01" -Title "<관찰된 문제>" -ReproSteps "<재현 단계>" -Expected "<기대 결과>" -Actual "<실제 결과>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\NewPlaytestEvidenceBundle.ps1 -SessionId "session-01" -ObservationFormPath "<filled observation form>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CollectExternalEvidenceSession.ps1 -SessionId "session-01" -FeedbackPath "<feedback txt>" -FeedbackManifestPath "<feedback json>" -ObservationFormPath "<filled observation form>" -SupportBundleRoot "<support bundle>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\SummarizePlaytestEvidence.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ExportFeedbackToCommercialQualityScorecard.ps1 -FeedbackRoot ".\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\Playtest"
```

## 관찰 항목

- 첫 질문까지 걸린 시간
- 직접 입력을 시도했는지 여부
- 기억장 진행도가 이해됐는지 여부
- 마무리 카드가 보상처럼 느껴졌는지 여부
- 기록 저장/삭제 흐름을 신뢰했는지 여부
- 답변 길이와 스크롤이 편했는지 여부
- “AI 같다”거나 반복적으로 느껴지는 문장이 있었는지 여부
- 글자 크기나 움직임 줄임 설정을 찾았는지 여부

## 이슈 분류

| 등급 | 기준 |
| --- | --- |
| P0 | 앱 진행 불가, 저장 데이터 손상, 개인정보/API 키 노출 가능성 |
| P1 | 주요 루프 이해 실패, 긴 답변 읽기 실패, 기록 저장/삭제 혼란 |
| P2 | 특정 문장 어색함, 버튼 위치 혼란, 상점 설명과 실제 경험의 차이 |
| P3 | 문구 다듬기, 캡션 개선, 미세한 시각 조정 |

## 통과 기준

- 참가자 대부분이 5문답 안에 기억장과 마무리 카드의 의미를 이해한다.
- 저장 기록이 로컬에 남고 삭제할 수 있다는 점을 설명 없이 찾거나, 정보 화면에서 납득한다.
- 답변 첫머리와 말투가 반복적이라는 지적이 반복되지 않는다.
- 플레이어가 최소 한 가지 개인적인 질문을 직접 입력한다.
- P0, P1 이슈가 없는 상태에서 릴리즈 후보로 넘어간다.
- 각 세션마다 관찰 기록, 지원 번들, 참가자 피드백 원문과 JSON 세션 정보가 남아 있다.


