# Interviewee1 Unity Avatar Chat

3조 대상자1 인터뷰 자료를 바탕으로 만든 Unity 대화형 인터뷰 게임입니다.

## 현재 구성

- 해상도 기준: 1920x1080
- 주요 화면: 타이틀, 인터뷰, 질문 노트, 기억장, 마무리 카드, 기록함, 설정, 정보
- 채팅 서버: `../Interviewee1CloneAI/server.js`의 `/api/chat`
- 마이크 입력: 서버의 `/api/transcribe`
- 저장 기록: 로컬 사용자 데이터 폴더의 `EndingCards`
- 의견 메모: 로컬 사용자 데이터 폴더의 `FeedbackNotes`

인터뷰 내용을 전시용 게임 흐름에 맞게 재구성했습니다.
정보 화면에서 이어하기 데이터와 저장된 마무리 기록을 두 단계 확인 후 삭제할 수 있습니다.
정보 화면은 시작 화면에서 바로 열 수 있고, 로컬 서버 연결과 API 키 유무도 확인할 수 있습니다.
설정에서 `로컬만`을 켜면 텍스트 질문을 서버로 보내지 않고 Unity 내장 자료 답변만 사용합니다.

## 실행

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat
```

실행 배치는 `LaunchAvatarChat.ps1`를 호출해 앱 파일, 포함된 NodeRuntime, 로컬 서버, API 환경 변수를 먼저 점검합니다. 배포 패키지는 Node.js 22 LTS 런타임을 포함하며, 로컬 서버가 꺼져 있으면 이 런타임으로 `../Interviewee1CloneAI/server.js`를 먼저 켠 뒤 Unity 실행 파일을 엽니다. 서버가 열리지 않거나 API 키가 없어도 텍스트 대화는 Unity 내장 자료 답변으로 이어집니다. 설정에서 `로컬만`을 켜면 텍스트 질문은 서버로 보내지지 않습니다. 마이크 전사는 서버와 `OPENAI_API_KEY`가 있을 때만 동작합니다.
채팅 모델은 전시 운영 기준인 `gpt-5.4-mini`로 고정됩니다. `OPENAI_CHAT_MODEL`에 다른 값을 넣거나 예전 `OPENAI_MODEL` 값이 남아 있어도 서버는 `gpt-5.4-mini`를 사용하며, 해당 모델 호출이 실패하면 `/api/config`와 Unity 상태 표시에서 오류를 확인할 수 있습니다.

실행 전 점검만 하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1 -CheckOnly -NoStartServer
```

## 빌드

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.4.5f1\Editor\Unity.exe" -batchmode -quit -projectPath ".\99_GroupProject\Interviewee1UnityAvatarChat" -executeMethod AvatarChatBuildTools.BuildWindows -logFile ".\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-build.log"
```

## 배포 패키지

패키지를 만들기 전 포함할 NodeRuntime을 준비합니다.

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PrepareNodeRuntime.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeReleasePackage.ps1
```

패키지는 Unity 실행 파일, 런타임 폴더, 실행 배치, 서버 최소 파일, NodeRuntime, README와 배포 체크리스트만 묶습니다. 스모크 캡처, 로그, 서버 PID 파일, API 키는 포함하지 않습니다.
패키지 안의 `BUILD_INFO.txt`에는 버전, 빌드 ID, 주요 실행 파일 해시가 들어 있어 지원 문의 때 같은 빌드인지 확인할 수 있습니다.
패키지 안의 `CollectSupportBundle.ps1`는 문의 대응용 빌드 정보, 런처 점검 결과, 필수 파일 존재 여부만 모읍니다. API 키 값, 환경 변수 전체, 저장된 마무리 기록은 수집하지 않습니다.

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateReleasePackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA
```

플레이어 PC에서 지원 번들을 만들려면 패키지 루트에서:

```powershell
.\Interviewee1UnityAvatarChat\CollectSupportBundle.ps1
```

## 상점 자산

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CaptureSteamKeyArt.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PrepareProfessionalKeyArt.ps1 -SourceImage "<generated key art png>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PromoteSteamScreenshots.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateVisualQuality.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateTrailerAnimatic.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateBuildCaptureTrailer.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateTrailerAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateStoreCopy.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialUiCopy.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamLegalReadiness.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteReleaseReadinessReport.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteCommercialLaunchDecision.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1
```

전체 릴리즈 스모크는 Unity 빌드와 플레이어 캡처를 여러 번 실행합니다. 작업 중 실수로 Unity 창이 반복해서 뜨는 일을 막기 위해 기본 실행은 즉시 차단합니다. 데스크톱 사용이 괜찮을 때만 명시적으로 허용해서 실행합니다.

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -AllowUnityWindows
```

창을 띄우지 않는 서버/문구/안전/상점 문구 중심 검증만 먼저 돌리려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -StaticOnly
```

키아트 캡처는 현재 빌드 실행 파일을 사용합니다. 캡슐 자산은 `Marketing/SteamAssets`, 트레일러 애니매틱과 빌드 캡처 기반 후보는 `Marketing/Trailer`에 생성됩니다.
시각 품질 QA 보고서는 `Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv`에 생성되며, 상점 스크린샷과 Steam 자산의 밝기, 암부, 보라색 잔상, 가장자리 위험을 함께 검증합니다.
상점 문구 QA 보고서는 `Marketing/StoreCopy/STORE_COPY_QA_REPORT.tsv`에 생성됩니다.
상용 UI 문구 QA 보고서는 `Docs/COMMERCIAL_UI_COPY_QA.md`에 생성됩니다.
릴리즈 스모크 창 실행 정책 QA 보고서는 `Docs/RELEASE_SMOKE_POLICY_QA.md`에 생성됩니다.
Steam/법무 준비 자동 QA 보고서는 `Docs/STEAM_LEGAL_READINESS_QA.md`에 생성됩니다.
외부 이슈 레지스터 QA 보고서는 `Docs/EXTERNAL_ISSUE_REGISTER_QA.md`에 생성됩니다.
상업 출시 결정 보고서는 `Docs/COMMERCIAL_LAUNCH_DECISION.md`에 생성됩니다.
상업 출시 최종 게이트는 `Docs/COMMERCIAL_LAUNCH_GATE.md`에 생성됩니다.

Steam 상점 제출용 자산 패키지:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeSteamSubmissionPackage.ps1 -PackageName "GeotNotEqualSok-SteamSubmission-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamSubmissionPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA
```

Steamworks 업로드 전 스테이징 패키지:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeSteamworksStagingPackage.ps1 -PackageName "GeotNotEqualSok-Steamworks-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamworksStagingPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamworksStagingPackages\GeotNotEqualSok-Steamworks-QA
```

외부 플레이테스트 운영 패키지:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeExternalPlaytestPackage.ps1 -PackageName "GeotNotEqualSok-ExternalPlaytest-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalPlaytestPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA
```

상업 검토 패키지:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeCommercialReviewPackage.ps1 -PackageName "GeotNotEqualSok-CommercialReview-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialReviewPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\CommercialReviewPackages\GeotNotEqualSok-CommercialReview-QA
```

외부 증거 감사:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -Initialize
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidatePlaytestFeedbackExport.ps1 -FeedbackRoot "<FeedbackNotes folder>" -RequireFiveTurnSession
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CollectExternalEvidenceSession.ps1 -SessionId "session-01" -FeedbackPath "<feedback txt>" -FeedbackManifestPath "<feedback json>" -ObservationFormPath "<filled observation form>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\SummarizePlaytestEvidence.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1
```

5달러 이상 최종 출시 게이트를 강제로 확인하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady
```

## 서버 환경 변수

서버는 API 키를 앱 파일이나 기록 파일에 저장하지 않습니다. 필요할 때 실행 환경에서만 읽습니다.

```powershell
$env:OPENAI_API_KEY="<your API key>"
$env:OPENAI_CHAT_MODEL="gpt-5.4-mini"
$env:OPENAI_TRANSCRIBE_MODEL="gpt-4o-mini-transcribe"
$env:OPENAI_TTS_MODEL="gpt-4o-mini-tts"
$env:OPENAI_TTS_VOICE="cedar"
```

`OPENAI_MODEL`은 이전 환경에 남아 있어도 무시됩니다. 모델 설정 검증은 `Tools/ValidateModelConfig.ps1`로 실행합니다.

## 문서

- `Docs/IMPROVEMENT_PLAN.md`: 기획, 검토, 반영 내역
- `Docs/RELEASE_CHECKLIST.md`: 배포 전 확인 항목
- `Docs/COMMERCIAL_RELEASE_REVIEW.md`: 상업 출시 검토 보드
- `Docs/EXTERNAL_EVIDENCE_REQUIREMENTS.md`: 외부 검증 증거 요구사항
- `Docs/EXTERNAL_EVIDENCE_AUDIT.md`: 현재 외부 증거 감사 결과
- `Docs/PLAYTEST_EVIDENCE_SUMMARY.md`: 외부 플레이테스트 세션과 P0/P1 이슈 요약
- `Docs/EXTERNAL_ISSUE_REGISTER_QA.md`: 외부 리뷰 이슈 수정/검증 상태 QA 결과
- `Docs/EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv`: 외부 리뷰 이슈 레지스터 템플릿
- `Docs/PLAYTEST_PROTOCOL.md`: 실제 유저 테스트 진행 기준
- `Docs/PLAYTEST_OBSERVATION_FORM.md`: 외부 테스트 관찰 기록 양식
- `Docs/PLAYTEST_ISSUE_TRIAGE.md`: 플레이테스트 이슈 등급 분류 기준
- `Docs/ACCESSIBILITY_QA.md`: 키보드 조작과 접근성 QA 기준
- `Docs/ACCESSIBILITY_AUTOMATION_QA.md`: 키보드 단축키 코드와 접근성 스모크 캡처 자동 QA 결과
- `Docs/ACCESSIBILITY_OBSERVATION_FORM.md`: 실제 접근성 QA 관찰 양식
- `Docs/PRIVACY_NOTICE_DRAFT.md`: 개인정보와 저장 데이터 안내 초안
- `Docs/STEAM_LEGAL_READINESS_QA.md`: Steam/법무 준비 자동 QA 결과
- `Docs/TROUBLESHOOTING.md`: 실행, API, 마이크, 저장 문제 해결
- `Docs/SUPPORT_HANDOFF.md`: 출시 지원과 이슈 등급 인계 기준
- `Docs/MODEL_CONFIG_QA.md`: 채팅 모델 환경 변수 정규화와 기본값 검증 결과
- `Docs/RELEASE_READINESS_REPORT.md`: 자동 감사 결과와 남은 외부 검증 항목
- `Docs/COMMERCIAL_LAUNCH_DECISION.md`: Steam 상점 제출과 5달러 이상 최종 출시 후보 판정
- `Docs/COMMERCIAL_LAUNCH_GATE.md`: 자동 QA, 외부 증거, 플레이테스트, 외부 이슈, 상업 판정을 묶은 최종 게이트 결과
- `Marketing/Steamworks`: SteamPipe 업로드 계획과 VDF 템플릿
- `Marketing/ArtReview`: 외부 아트 리뷰 브리프와 기록 양식
- `CollectSupportBundle.ps1`: 플레이어 문의용 지원 번들 생성
- `Tools/CollectExternalEvidenceSession.ps1`: 외부 플레이테스트 증거 세션 폴더 생성
- `Tools/ValidatePlaytestFeedbackExport.ps1`: 앱이 저장한 의견 메모 txt/json 검증
- `Tools/SummarizePlaytestEvidence.ps1`: 외부 플레이테스트 증거와 차단 이슈 요약


