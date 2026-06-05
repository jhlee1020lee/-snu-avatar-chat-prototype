# 출시 지원 인계 메모

이 문서는 `겉!=속`를 5달러 이상 유료 판매 후보로 운영한다고 가정했을 때 개발자, QA, 상점 운영자가 공유해야 할 지원 기준을 정리한다.

## 지원 응답 원칙

- 플레이어가 겪는 문제를 `실행`, `대화`, `마이크`, `저장`, `접근성`, `콘텐츠`로 먼저 분류한다.
- API 실패와 서버 미실행은 게임 진행 불가로 보지 않는다. 텍스트 대화는 로컬 근거 답변으로 이어져야 한다.
- 플레이어가 서버 전송을 원하지 않으면 설정의 `로컬만`을 켜도록 안내한다.
- 개인정보, 내부 프롬프트, API 키, 의학·법률·복지 판단 질문은 안전 답변으로 우회되어야 하며, 실패하면 P0 또는 P1로 분류한다.
- 마이크 전사는 선택 기능이다. 직접 입력과 추천 질문이 기본 경로이며, `로컬만`을 켜면 전사는 꺼진다.
- 저장 삭제 요청은 앱 정보 화면의 `저장 삭제` 흐름을 우선 안내한다.
- 서버/API 상태 문의는 앱 정보 화면의 상태 패널과 런처 사전 점검 출력의 NodeRuntime 줄을 함께 확인한다.

## 이슈 등급

| 등급 | 기준 | 예시 |
| --- | --- | --- |
| P0 | 실행 불가, 저장 삭제 불가, 개인정보 노출 위험 | 앱 시작 실패, API 키가 파일에 포함됨 |
| P1 | 핵심 세션 진행 방해 | 질문 후 응답 없음, 마무리 카드 진입 불가, 긴 답변 화면 이탈 |
| P2 | 상점 설명과 실제 경험 차이 | 스크린샷과 UI 불일치, 이어하기 요약 오류 |
| P3 | 품질 개선 | 문장 어색함, 버튼 위치 혼란, 추가 단축키 요청 |

## 출시 전 확인해야 할 증거

- `RunReleaseSmoke.ps1` 통과 로그
- `ValidateReleasePackage.ps1` 통과 로그
- `RunPackagedServerQA.ps1` 통과 로그, 패키지 내부 안전 답변 확인 포함
- `ValidateSteamSubmissionPackage.ps1` 통과 로그
- `ValidateSteamworksStagingPackage.ps1` 통과 로그
- `ValidateSteamLegalReadiness.ps1` 통과 로그와 `Docs/STEAM_LEGAL_READINESS_QA.md`
- `RunSafetyQA.ps1` 통과 로그
- `Marketing/Screenshots/SCREENSHOT_MANIFEST.tsv`
- 실제 플레이어 5문답 이상 세션 관찰 기록
- 앱의 `FeedbackNotes` 폴더에 저장된 의견 txt/json 세션 정보
- `ValidatePlaytestFeedbackExport.ps1` 통과 로그
- `SummarizePlaytestEvidence.ps1`로 만든 P0/P1 이슈 요약
- `RegisterExternalIssue.ps1`로 등록한 외부 이슈 레지스터
- `ValidateExternalIssueRegister.ps1` 통과 로그와 외부 이슈 레지스터
- 외부 플레이테스트 패키지와 관찰 기록 양식
- 실제 보조기기 기반 접근성 QA 기록
- 외부 아트 리뷰 또는 최종 키아트 승인 기록
- 상업 검토 패키지의 아트/트레일러/법무/Steam 관리자 증거
- `ValidateExternalEvidence.ps1` 감사 결과
- `WriteCommercialLaunchDecision.ps1`로 생성한 `Docs/COMMERCIAL_LAUNCH_DECISION.md`

## 플레이어 문의에 필요한 정보

- Windows 버전
- 실행 방식: 배치 파일 또는 exe 직접 실행
- `BUILD_INFO.txt`의 Build ID
- 런처 사전 점검의 `Node.js runtime ready` 출력
- `LaunchAvatarChat.ps1 -CheckOnly -NoStartServer` 출력
- `CollectSupportBundle.ps1`로 만든 지원 번들
- 마이크 입력 사용 여부
- 로컬 답변 전용 모드 사용 여부
- 문제가 발생한 화면
- 저장 데이터 삭제를 시도했는지 여부
- 재현 가능한 질문 문장

## 운영자가 직접 열어볼 위치

- 마무리 기록: 사용자 데이터 폴더의 `EndingCards`
- 의견 메모: 사용자 데이터 폴더의 `FeedbackNotes`
- 외부 증거 세션 자동 생성: `Tools/NewPlaytestEvidenceBundle.ps1`
- 외부 증거 세션 수동 생성: `Tools/CollectExternalEvidenceSession.ps1`
- 의견 메모 검증: `Tools/ValidatePlaytestFeedbackExport.ps1`
- 플레이테스트 증거 요약: `Tools/SummarizePlaytestEvidence.ps1`
- 외부 이슈 등록: `Tools/RegisterExternalIssue.ps1`
- 외부 이슈 레지스터 QA: `Tools/ValidateExternalIssueRegister.ps1`
- Steam 상점 자료: `Marketing`
- 실행 패키지: `Build/ReleasePackages`
- 외부 플레이테스트 패키지: `Build/ExternalPlaytestPackages`
- 상업 검토 패키지: `Build/CommercialReviewPackages`
- 외부 증거 루트: `Build/ReleaseEvidence`
- 외부 증거 감사: `Tools/ValidateExternalEvidence.ps1`
- 패키지 서버 QA: `Tools/RunPackagedServerQA.ps1`
- Steam 제출 패키지: `Build/SteamSubmissionPackages`
- Steamworks 스테이징 패키지: `Build/SteamworksStagingPackages`
- Steam/법무 준비 자동 QA: `Tools/ValidateSteamLegalReadiness.ps1`
- 상업 출시 결정 보고서: `Tools/WriteCommercialLaunchDecision.ps1`
- 런처 사전 점검: `LaunchAvatarChat.ps1 -CheckOnly -NoStartServer`
- 지원 번들 생성: `CollectSupportBundle.ps1`

## 지원 번들 확인 기준

- `support_info.json`에서 Build ID, OS 버전, 서버/API 모드를 확인한다.
- `launcher_check.txt`에서 앱 파일, NodeRuntime, 로컬 서버 점검 결과를 확인한다.
- `file_presence.tsv`에서 실행 파일, 서버 파일, NodeRuntime 누락 여부를 확인한다.
- 지원 번들은 API 키 값, 환경 변수 전체, 저장된 마무리 기록을 수집하지 않아야 한다.
- 지원 번들 안에서 OpenAI 비밀키 형태 문자열이 발견되면 P0 개인정보/비밀정보 위험으로 분류한다.

## 아직 실제로 끝나지 않은 일

- 외부 플레이어 테스트 결과를 이슈로 반영한다.
- 실제 보조기기 테스트 결과를 접근성 QA 문서에 반영한다.
- 최종 라이브 플레이 녹화 트레일러와 사운드 믹스를 만든다.
- Steam AppID, DepotID, 업로드 계정, 테스트 브랜치 설정을 확정한다.
- 최종 법무/개인정보 문구와 Steam 관리자 설정을 배포 주체 기준으로 확정한다.


