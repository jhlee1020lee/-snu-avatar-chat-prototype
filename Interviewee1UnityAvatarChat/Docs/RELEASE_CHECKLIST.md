# 배포 체크리스트

이 문서는 `겉!=속`를 유료 배포물로 묶기 전에 확인할 항목을 정리한다.

## 실행 패키지

- `Build/Interviewee1UnityAvatarChat.exe`
- `Build/Interviewee1UnityAvatarChat_Data`
- `Build/UnityPlayer.dll`
- `Build/UnityCrashHandler64.exe`
- `Build/MonoBleedingEdge`
- `Build/D3D12`
- `Build/ThirdParty/NodeRuntime/node.exe`
- `RUN_AVATAR_CHAT.bat`
- `LaunchAvatarChat.ps1`
- `CollectSupportBundle.ps1`
- `BUILD_INFO.json`
- `BUILD_INFO.txt`
- `../Interviewee1CloneAI/server.js`
- `../Interviewee1CloneAI/data/persona.json`

## 실행 기준

- `RUN_AVATAR_CHAT.bat`으로 앱이 열린다.
- `LaunchAvatarChat.ps1 -CheckOnly -NoStartServer`가 앱 파일과 실행 환경을 점검하고 종료한다.
- 런처 사전 점검 출력에 빌드 ID가 표시된다.
- 로컬 서버가 꺼져 있으면 실행 배치가 서버를 먼저 켠다.
- Windows 배포 패키지는 포함된 NodeRuntime으로 서버를 켠다.
- 포함 런타임이나 OpenAI API가 실패해도 텍스트 대화는 앱 내장 근거 답변으로 이어진다.
- 설정의 `로컬만`을 켜면 텍스트 질문은 서버로 보내지지 않고 Unity 내장 근거 답변만 사용한다.
- 마이크 전사는 `OPENAI_API_KEY`가 있을 때만 제공한다.
- API 키는 앱 파일, 기록 파일, README에 저장하지 않으며, README 예시는 `<your API key>` 같은 중립 placeholder만 사용한다.
- 앱 정보 화면에서 로컬 서버 연결과 API 키 유무가 짧게 표시된다.
- 채팅 모델은 전시 운영 기준인 `gpt-5.4-mini`로 고정하고, 짧은 모델명은 `gpt-...` 형식으로 정규화된다.
- 모델명이 형식에 맞지 않으면 기본 모델로 돌아가고, 실제 API에서 사용할 수 없으면 텍스트 대화는 로컬 근거 답변으로 이어진다.
- `Tools/ValidateModelConfig.ps1`가 기본 모델, 구버전 환경 변수 호환, 짧은 모델명 정규화, 잘못된 모델명 기본값 전환을 검증한다.

## 품질 기준

- 첫 화면에서 새 시작, 이어하기, 질문폰, 기록함, 설정이 구분된다.
- 첫 화면에서 정보 화면을 바로 열 수 있어 저장, 서버, API 키 정책을 찾는 데 별도 메뉴 탐색이 필요하지 않다.
- 긴 답변은 대사창 내부에서만 스크롤되며, `Build/release-smoke/long-dialogue-layout.tsv`가 대사창 viewport, content, preferred height, 스크롤 표시 상태를 PASS로 기록한다.
- 캐릭터는 좌우로 눌려 보이지 않으며, `Build/release-smoke/avatar-layout.tsv`가 가로 보정, 화면 footprint, preserveAspect 상태를 PASS로 기록한다.
- 입력 직후 생각 중 문구는 `잠시만요. 생각 좀 해볼게요.`로 짧게 표시되며, `Build/release-smoke/thinking-copy.tsv`가 접수 표현과 장황한 문구가 없음을 PASS로 기록한다.
- 답변과 추천 질문은 별표 강조, 반복 고지, `좋아요`식 접수 표현, AI식 정체성 문구 없이 자연스럽게 출력된다.
- 상용 UI 문구 QA는 Unity 화면 문구뿐 아니라 `Interviewee1CloneAI/data/persona.json`의 제목, 시작 답변, 근거 답변, 추천 질문도 검사한다.
- 설정에서 글자 크기, 소리, 화면 모드, 움직임 줄임, 로컬 답변 전용 모드를 조정할 수 있고 설정 화면에서 버튼이 겹치지 않는다.
- 키보드만으로 추천 질문 선택, 질문폰, 기억장, 기록함, 설정, 정보, 전체 화면, 글자 크기 조작에 접근할 수 있다.
- 게임패드 기본 버튼으로 시작, 질문폰, 기억장, 기록함, 설정, 패널 닫기, 질문 노트 탭 이동에 접근할 수 있다.
- 서버 응답 테마는 `일상`, `이동`, `도움`, `일과 공부`, `독립`, `취미` 기준으로 정리되어 기억장 진행과 어긋나지 않는다.
- 로컬 근거 답변과 추천 질문은 금지된 첫 문장, AI식 표현, 과한 길이, 줄바꿈, 근거 누락, 추천 질문 누락이 없어야 한다.
- 개인정보, 내부 프롬프트, API 키, 의학·법률·복지 판단을 요구하는 질문은 로컬 안전 답변으로 우회해야 한다.
- 질문 후 아직 열리지 않은 기억장 장면을 우선 추천한다.
- 여섯 장면을 모두 열면 완성 알림, 기억장 배지, 마무리 카드가 같은 상태를 보여준다.
- 마무리 카드에서 `저장 후 보기`를 누르면 최신 기록이 기록함에서 바로 열린다.
- 마무리 카드에서 `의견`을 눌러 로컬 의견 메모를 저장할 수 있다.
- 기록함에서 선택한 로컬 기록을 두 단계 확인 후 삭제할 수 있다.
- 정보 화면에서 이어하기 데이터와 저장된 마무리 기록을 두 단계 확인 후 한 번에 삭제할 수 있다.

## 상점 페이지 준비

- `Marketing/STORE_PAGE_DRAFT.md`에 한 줄 소개, 짧은 소개문, 긴 소개문, 핵심 특징, 태그 후보, 스크린샷 캡션, 주의 문구가 정리되어 있다.
- `Marketing/STORE_PAGE_DRAFT.md`에는 실제 상점에 올릴 문구만 남기고 내부 운영 메모는 `Marketing/STORE_PAGE_INTERNAL_NOTES.md`로 분리되어 있다.
- `Tools/ValidateStoreCopy.ps1`로 상점 문구의 필수 섹션, 길이, 금지 표현, 스크린샷 11장, 별표 강조 제거 여부를 검증할 수 있다.
- `Marketing/StoreCopy/STORE_COPY_QA_REPORT.tsv`에 상점 문구 QA 결과가 남아 있다.
- `Tools/ValidateCommercialUiCopy.ps1`로 플레이어 화면과 의견 메모 저장 제목에 `플레이테스트` 같은 내부 검토 표현이 남지 않았는지 검증할 수 있다.
- `Docs/COMMERCIAL_UI_COPY_QA.md`에 상용 UI 문구 QA 결과가 남아 있다.
- `Marketing/SCREENSHOT_PLAN.md`에 확보한 컷과 추가 촬영 컷이 정리되어 있다.
- `Marketing/Screenshots`에 현재 빌드에서 검증된 11장 스크린샷과 `SCREENSHOT_MANIFEST.tsv`가 들어 있다.
- `Marketing/STEAM_ASSET_PLAN.md`에 Steam 캡슐 자산 초안과 검증 기준이 정리되어 있다.
- `Marketing/Trailer/TRAILER_PRODUCTION_PLAN.md`에 첫 트레일러의 60초 구성, 자막, 애니매틱 제작 기준이 정리되어 있다.
- `Docs/PLAYTEST_PROTOCOL.md`에 실제 유저 테스트 진행 순서, 관찰 항목, 이슈 등급, 통과 기준이 정리되어 있다.
- `Docs/PLAYTEST_OBSERVATION_FORM.md`에 외부 테스트 관찰 기록 양식이 정리되어 있다.
- `Docs/PLAYTEST_ISSUE_TRIAGE.md`에 플레이테스트 이슈 등급과 출시 후보 판정 기준이 정리되어 있다.
- `Docs/ACCESSIBILITY_QA.md`에 키보드 조작, 큰 글자, 움직임 줄임, 실제 보조기기 QA 기준이 정리되어 있다.
- `Docs/ACCESSIBILITY_AUTOMATION_QA.md`에 키보드 단축키 코드와 접근성 스모크 캡처 자동 QA 결과가 정리되어 있다.
- `Docs/PRIVACY_NOTICE_DRAFT.md`에 로컬 저장, 마이크 전사, API 키 저장 정책 고지 초안이 정리되어 있다.
- `Docs/TROUBLESHOOTING.md`에 실행, API, 마이크, 저장 삭제, 접근성 문제 해결 안내가 정리되어 있다.
- `Docs/SUPPORT_HANDOFF.md`에 출시 후 문의 분류, 이슈 등급, 지원 인계 기준이 정리되어 있다.
- `Docs/RELEASE_READINESS_REPORT.md`에 자동 감사 통과 항목과 아직 외부 검증이 필요한 항목이 정리되어 있다.
- `Docs/COMMERCIAL_LAUNCH_DECISION.md`에 Steam 상점 제출 가능 여부와 5달러 이상 최종 출시 후보 여부가 정리되어 있다.
- `Docs/COMMERCIAL_LAUNCH_GATE.md`에 자동 QA, 외부 증거, 플레이테스트, 외부 이슈, 상업 판정을 묶은 최종 게이트 결과가 정리되어 있다.
- `Docs/COMMERCIAL_RELEASE_REVIEW.md`에 5달러 이상 판매 후보 판단용 역할, 게이트, 결정 기록이 정리되어 있다.
- `Docs/EXTERNAL_EVIDENCE_REQUIREMENTS.md`에 실제 외부 증거의 폴더 구조와 필수 파일이 정리되어 있다.
- `Docs/EXTERNAL_REVIEW_BRIEFS.md`와 `Docs/EXTERNAL_REVIEW_BRIEFS_QA.md`에 외부 담당자용 브리프, 초대 문구, 브리프 검증 결과가 정리되어 있다.
- `Docs/EXTERNAL_REVIEW_TRACKER.md`와 `Docs/EXTERNAL_REVIEW_TRACKER_QA.md`에 외부 리뷰 배정, 초대, 마감, 증거 수령 상태가 정리되어 있다.
- `Docs/EXTERNAL_REVIEWER_ROSTER.md`와 `Docs/EXTERNAL_REVIEWER_ROSTER_QA.md`에 외부 리뷰어 명단 템플릿과 검증 결과가 정리되어 있다.
- `Docs/EXTERNAL_REVIEWER_PACKETS.md`와 `Docs/EXTERNAL_REVIEWER_PACKETS_QA.md`에 외부 리뷰어별 전달 패킷과 검증 결과가 정리되어 있다.
- `Docs/EXTERNAL_REVIEW_OUTREACH_QUEUE.md`와 `Docs/EXTERNAL_REVIEW_OUTREACH_QA.md`에 오늘의 외부 리뷰 배정, 초대, 독촉, 수입 순서가 정리되어 있다.
- `Docs/EXTERNAL_EVIDENCE_IMPORT_QA.md`에 반환된 EvidenceDrop 수입 미리보기와 충돌 여부가 정리되어 있다.
- `Docs/EXTERNAL_EVIDENCE_AUDIT.md`에 현재 외부 증거 충족 여부가 정리되어 있다.
- `Docs/EXTERNAL_ISSUE_REGISTER_QA.md`에 외부 리뷰 이슈의 수정/검증 상태가 정리되어 있다.
- `Docs/EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv`에 외부 리뷰 이슈 레지스터 템플릿이 들어 있다.
- `Docs/MODEL_CONFIG_QA.md`에 채팅 모델 환경 변수 정규화와 기본값 검증 결과가 정리되어 있다.
- `CollectSupportBundle.ps1`로 플레이어 문의용 지원 번들을 생성할 수 있다.
- `Docs/ACCESSIBILITY_OBSERVATION_FORM.md`에 실제 접근성 QA 기록 양식이 정리되어 있다.
- `Marketing/SteamAssets`에 Steam 캡슐 초안과 작은 캡슐 미리보기가 들어 있다.
- `Marketing/ArtReview`에 외부 아트 리뷰 브리프와 기록 양식이 들어 있다.
- `Marketing/Steamworks`에 SteamPipe 업로드 계획과 AppBuild/DepotBuild VDF 템플릿이 들어 있다.
- `Marketing/Steamworks/STEAM_ADMIN_CHECKLIST.md`에 실제 Steam 관리자 최종 확인 항목이 들어 있다.
- `Docs/STEAM_LEGAL_READINESS_QA.md`에 개인정보 초안, 상점 고지, 지원 인계, Steamworks 문서, VDF 템플릿 자동 QA 결과가 정리되어 있다.
- `Marketing/SteamAssets/professional_keyart_1920x1080.png`에 캡슐 우선 키아트 후보가 들어 있다.
- `Marketing/SteamAssets/source_keyart_1920x1080.png`에 UI 없는 캡슐 소스가 들어 있다.
- `Marketing/Trailer/trailer_animatic_60s.mp4`가 1920x1080, 약 60초 MP4로 생성되어 있으며 AAC 스테레오 오디오를 포함한다.
- `Marketing/Trailer/trailer_build_capture_60s.mp4`가 현재 빌드 스모크 캡처 기반 1920x1080, 약 60초 MP4로 생성되어 있으며 AAC 스테레오 오디오를 포함한다.
- `Tools/CaptureSteamKeyArt.ps1`로 현재 빌드에서 UI 없는 캡슐 소스를 다시 캡처할 수 있다.
- `Tools/PrepareProfessionalKeyArt.ps1`로 생성형 키아트 후보를 1920x1080 캡슐 소스로 정리할 수 있다.
- `Tools/GenerateSteamAssets.ps1`로 캡슐 초안을 다시 생성할 수 있다.
- `Tools/PromoteSteamScreenshots.ps1`로 최신 릴리즈 스모크 캡처를 상점 스크린샷 세트로 승격하고 `SCREENSHOT_MANIFEST.tsv`를 만든다.
- `Tools/ValidateSteamAssets.ps1`로 캡슐, 스크린샷 크기, 스크린샷 매니페스트를 검증할 수 있다.
- `Tools/ValidateVisualQuality.ps1`로 상점 스크린샷, 키아트, Steam 캡슐 이미지의 밝기, 비어 있지 않음, 보라색 잔상, 가장자리 잘림 위험을 검증할 수 있다.
- 설정, 정보, 기록함, 저장 데이터 안내 같은 모달 스크린샷은 어두운 전체 덮개에 묻히지 않고 강화된 평균 밝기 기준을 통과해야 한다.
- `Tools/ValidateAccessibilityAutomation.ps1`로 키보드 단축키 코드와 접근성 관련 스모크 캡처를 검증할 수 있다.
- `Tools/GenerateTrailerAnimatic.ps1`로 스크린샷 기반 트레일러 애니매틱을 다시 생성할 수 있다.
- `Tools/GenerateBuildCaptureTrailer.ps1`로 현재 빌드 스모크 캡처 기반 트레일러 후보를 다시 생성할 수 있다.
- `Tools/ValidateTrailerAssets.ps1`로 트레일러 길이, 해상도, AAC 오디오를 검증할 수 있다.
- `Tools/ValidateStoreCopy.ps1`로 플레이어가 보는 상점 문구에 내부 개발 표현이 섞이지 않았는지 검증할 수 있다.
- `Tools/ValidateSteamLegalReadiness.ps1`로 Steam/법무 준비 문서와 템플릿의 로컬 준비 상태를 검증할 수 있다.
- `Tools/ValidateExternalIssueRegister.ps1`로 외부 리뷰 이슈의 P0/P1 검증 완료와 P2 처리 상태를 확인할 수 있다.
- `Tools/WriteCommercialLaunchDecision.ps1`로 자동 QA, 패키지, 외부 증거, P0/P1 기준을 묶어 출시 회의용 결정을 생성할 수 있다.
- `Tools/WriteInternalQualityScorecard.ps1`로 내부 자동 QA 기준의 8개 상업 품질 영역 점수와 외부 의존 항목을 따로 정리할 수 있다.
- `Tools/WriteInternalCommercialReview.ps1`로 현재 보고서 상태를 역할별 내부 판단과 다음 스프린트 백로그로 정리할 수 있다.
- `Tools/WriteCommercialSprintPlan.ps1`로 내부 백로그, 품질 점수표, 증거 수집 계획을 묶어 담당자별 상업 출시 스프린트 보드를 만들 수 있다.
- `Tools/WriteExternalReviewBriefs.ps1`와 `Tools/ValidateExternalReviewBriefs.ps1`로 외부 리뷰어 브리프와 초대 문구를 만들고 검증할 수 있다.
- `Tools/WriteExternalReviewTracker.ps1`와 `Tools/ValidateExternalReviewTracker.ps1`로 외부 리뷰어 배정, 초대, 마감, 증거 수령 상태를 추적하고 검증할 수 있다.
- `Tools/WriteExternalReviewerRosterTemplate.ps1`, `Tools/ValidateExternalReviewerRoster.ps1`, `Tools/ApplyExternalReviewerRoster.ps1`로 리뷰어 명단을 만들고 추적표에 반영할 수 있다.
- `Tools/WriteExternalReviewerPackets.ps1`와 `Tools/ValidateExternalReviewerPackets.ps1`로 추적 항목별 초대문, README, 원본 브리프, 수락 체크리스트를 만들고 검증할 수 있다.
- `Tools/WriteExternalReviewOutreachQueue.ps1`와 `Tools/ValidateExternalReviewOutreachQueue.ps1`로 외부 리뷰 발송 큐와 다음 액션을 만들고 검증할 수 있다.
- `Tools/ImportExternalEvidenceDrop.ps1`와 `Tools/ValidateExternalEvidenceImport.ps1`로 반환된 외부 EvidenceDrop을 템플릿/비밀키/충돌 없이 수입할 수 있다.
- `Tools/WriteSteamMarketComparison.ps1`로 Steam 유사작의 현재 가격, 표시 태그, 리뷰 요약을 수집해 가격 비교 캐시를 만들 수 있다.
- `Tools/ValidateSteamMarketComparison.ps1`로 Steam 시장 비교 캐시가 5개 이상 비교작, 가격, 태그, 리뷰 요약, 출처 URL을 갖췄는지 확인할 수 있다.
- `Tools/WriteCommercialPricePositioning.ps1`로 USD 5 이상 가격 주장의 근거, 보류 사유, 시장 비교 필요 항목을 정리할 수 있다.
- `Tools/PrepareCommercialEvidenceWorkspace.ps1`로 내부 백로그 기준의 증거 폴더, 템플릿, `EVIDENCE_COLLECTION_PLAN.tsv`를 준비할 수 있다.
- `Tools/RunCommercialLaunchGate.ps1 -RequireLaunchReady`로 자동 QA, 외부 증거, 플레이테스트, 외부 이슈, 상업 판정을 한 번에 묶은 최종 출시 게이트를 강제할 수 있다.
- `Tools/WriteReleaseReadinessReport.ps1`로 현재 빌드, 상점 자료, 패키지, 패키지 빌드 ID 일치, 보안 검색, 남은 외부 검증 항목을 한 문서로 감사할 수 있다.

## 배포 패키지

- `Tools/PrepareNodeRuntime.ps1`로 Windows 배포 패키지에 포함할 NodeRuntime을 준비한다.
- `Tools/WriteBuildMetadata.ps1`로 Unity 빌드 데이터, 서버 코드, 서버 답변 데이터까지 포함한 빌드 ID와 주요 파일 해시를 `BUILD_INFO`에 기록한다.
- `Tools/ValidateModelConfig.ps1`로 채팅 모델 환경 변수 설정이 출시 빌드 기준을 통과하는지 확인한다.
- `Tools/MakeReleasePackage.ps1`로 Unity 런타임, 실행 배치, 서버 최소 파일, NodeRuntime, README, 배포 체크리스트를 별도 폴더로 묶는다.
- `Tools/ValidateReleasePackage.ps1`로 배포 패키지 필수 파일, 지원 문서, 매니페스트, 로그/스모크 캡처/API 키 제외 기준을 확인한다.
- 최종 릴리즈 감사는 Windows 실행 패키지, 외부 플레이테스트 패키지, SteamPipe 스테이징 패키지의 `BUILD_INFO.json`이 현재 빌드 ID와 같은지 확인한다.
- 최종 릴리즈 감사는 Steam 제출 패키지와 상업 검토 패키지에 포함된 `PACKAGE_PROVENANCE.json`이 현재 빌드 ID를 참조하는지 확인한다.
- `Tools/RunPackagedServerQA.ps1`로 배포 패키지 안의 NodeRuntime이 실제 서버를 띄우고 로컬 근거 답변과 안전 답변을 반환하는지 확인한다.
- 패키지 안의 `CollectSupportBundle.ps1`로 빌드 정보, 런처 점검, 필수 파일 존재 여부를 모으고 API 키 값과 저장 기록은 수집하지 않는지 확인한다.
- 배포 패키지는 스모크 캡처, Unity 로그, 서버 로그, `.server.pid`, API 키를 포함하지 않는다.
- 보안 검증은 OpenAI 키 접두사 계열, 구형 긴 키, 점 세 개로 줄인 키 예시 placeholder까지 패키지에서 차단해야 한다.
- API 키 문자열 검사는 텍스트성 파일만 대상으로 하고, 실행 파일/이미지/영상 같은 바이너리는 필수 파일과 매니페스트 검증으로 확인한다.
- 기본 배포 결정은 Windows 패키지에 포함된 NodeRuntime으로 로컬 서버를 사용하고, 서버나 API 키가 없으면 Unity 내장 근거 답변으로 텍스트 대화를 유지하는 방식이다.
- `Tools/MakeSteamSubmissionPackage.ps1`로 상점 문구, 스크린샷, Steam 캡슐, 트레일러, 출시 문서를 별도 상점 제출 패키지로 묶는다.
- `Tools/ValidateSteamSubmissionPackage.ps1`로 상점 제출 패키지의 필수 자산, 지원 문서, 이미지 크기, 매니페스트, 로그/API 키 제외 기준을 확인한다.
- `Tools/MakeSteamworksStagingPackage.ps1`로 SteamPipe 업로드용 `content`, `scripts`, `output` 스테이징 폴더를 만든다.
- `Tools/ValidateSteamworksStagingPackage.ps1`로 스테이징 폴더의 VDF 스크립트, 실행 콘텐츠, NodeRuntime, 금지 파일 제외 기준을 확인한다.
- Steam/법무 준비 자동 QA 보고서는 Windows 실행 패키지, Steam 제출 패키지, Steamworks 스테이징 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- 상업 출시 결정 보고서는 Windows 실행 패키지, Steam 제출 패키지, Steamworks 스테이징 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- 내부 품질 점수표와 내부 품질 리뷰는 Windows 실행 패키지, Steam 제출 패키지, 상업 검토 패키지에 포함되어야 한다.
- 상업 출시 스프린트 계획과 실행 보드는 Windows 실행 패키지, Steam 제출 패키지, 상업 검토 패키지에 포함되어야 한다.
- 외부 리뷰 브리프와 QA 보고서는 Windows 실행 패키지, Steam 제출 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- 외부 리뷰 진행 추적 보드와 QA 보고서는 Windows 실행 패키지, Steam 제출 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- 외부 리뷰어 전달 패킷과 QA 보고서는 Windows 실행 패키지, Steam 제출 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- 외부 EvidenceDrop 수입 QA는 Windows 실행 패키지, Steam 제출 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- 가격 포지셔닝 보고서와 판단 매트릭스는 Windows 실행 패키지, Steam 제출 패키지, 상업 검토 패키지에 포함되어야 한다.
- Steam 시장 비교 보고서, TSV, QA는 Windows 실행 패키지, Steam 제출 패키지, 상업 검토 패키지에 포함되어야 한다.
- 외부 이슈 레지스터 QA 보고서와 템플릿은 Windows 실행 패키지, Steam 제출 패키지, 외부 플레이테스트 패키지, 상업 검토 패키지에 포함되어야 한다.
- `Tools/MakeExternalPlaytestPackage.ps1`로 Windows 실행 패키지, 관찰 문서, 증거 수집 폴더를 묶은 외부 플레이테스트 패키지를 만든다.
- `Tools/ValidateExternalPlaytestPackage.ps1`로 외부 플레이테스트 패키지의 실행 파일, 관찰 양식, 지원 번들 도구, NodeRuntime, 금지 파일 제외 기준을 확인한다.
- 외부 플레이테스트 패키지는 참가자 안내문과 진행자 스크립트를 포함해 고지 문구, 진행 개입 기준, 종료 질문을 통일해야 한다.
- `Tools/ValidateCommercialQualityRubric.ps1`로 5달러 품질 점수표의 평균 점수, 최저 점수, 차단 항목, reviewer/evidence 누락, evidence 상대 경로의 실제 존재 여부를 확인한다.
- `Tools/MakeCommercialReviewPackage.ps1`로 상점 자산, 아트 리뷰 양식, 최종 트레일러 양식, 접근성/법무/Steam 관리자 검토 자료를 묶는다.
- `Tools/ValidateCommercialReviewPackage.ps1`로 상업 검토 패키지의 필수 자산, 검토 양식, 증거 수집 폴더, 금지 파일 제외 기준을 확인한다.
- `Tools/ValidateExternalEvidence.ps1`로 실제 외부 플레이테스트, 접근성 QA, 아트 리뷰, 최종 트레일러, Steam 관리자/법무 증거가 충분한지 감사한다.
- `Tools/ValidateSteamLegalReadiness.ps1`는 통과해야 하지만, 최종 AppID/DepotID/법무 검토/문의 채널 확정은 외부 증거로 남겨야 한다.

## 검증 명령

전체 스모크 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -AllowUnityWindows
```

Unity 빌드를 생략하고 현재 빌드 파일로 빠르게 확인:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -SkipUnityBuild -AllowUnityWindows
```

`RunReleaseSmoke.ps1`는 Unity 플레이어 캡처를 여러 번 실행하므로 작업 중 기본 실행은 창 실행을 차단한다. 데스크톱 사용이 가능할 때만 `-AllowUnityWindows`를 붙인다.
Unity 창 없이 서버/문구/안전/기존 상점 자료 중심의 정적 검증만 돌리려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -StaticOnly
```

개별 확인:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1 -CheckOnly -NoStartServer
```

```powershell
npm --prefix .\99_GroupProject\Interviewee1CloneAI run check
```

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunContentQA.ps1
```

장시간 답변 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunLongSessionQA.ps1
```

개인정보/프롬프트 주입 안전 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunSafetyQA.ps1
```

모델 설정 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateModelConfig.ps1
```

접근성 자동 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateAccessibilityAutomation.ps1
```

긴 답변 레이아웃 회귀 확인:

```powershell
Get-Content .\99_GroupProject\Interviewee1UnityAvatarChat\Build\release-smoke\long-dialogue-layout.tsv
```

Steam/법무 준비 자동 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamLegalReadiness.ps1
```

상업 출시 결정 보고서:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteCommercialLaunchDecision.ps1
```

외부 이슈 레지스터 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1
```

배포 패키지 생성:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PrepareNodeRuntime.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeReleasePackage.ps1
```

배포 패키지 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateReleasePackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunPackagedServerQA.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA
```

패키지 지원 번들 QA:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA\Interviewee1UnityAvatarChat\CollectSupportBundle.ps1 -OutputRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\SupportBundleQA
```

Steam 제출 패키지 생성과 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeSteamSubmissionPackage.ps1 -PackageName "GeotNotEqualSok-SteamSubmission-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamSubmissionPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA
```

Steamworks 스테이징 패키지 생성과 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeSteamworksStagingPackage.ps1 -PackageName "GeotNotEqualSok-Steamworks-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamworksStagingPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamworksStagingPackages\GeotNotEqualSok-Steamworks-QA
```

외부 플레이테스트 패키지 생성과 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeExternalPlaytestPackage.ps1 -PackageName "GeotNotEqualSok-ExternalPlaytest-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalPlaytestPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA
```

외부 플레이테스트 패키지 루트에서는 다음 배치 파일이 동작해야 한다:

```bat
RUN_EVIDENCE_AUDIT.bat
RUN_FINAL_EVIDENCE_GATE.bat
```

상업 검토 패키지 생성과 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\MakeCommercialReviewPackage.ps1 -PackageName "GeotNotEqualSok-CommercialReview-QA"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialReviewPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\CommercialReviewPackages\GeotNotEqualSok-CommercialReview-QA
```

상업 검토 패키지도 `EvidenceDrop` 기준으로 `RUN_EVIDENCE_AUDIT.bat`와 `RUN_FINAL_EVIDENCE_GATE.bat`가 포함되어야 한다.

외부 증거 감사:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -Initialize
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidatePlaytestFeedbackExport.ps1 -FeedbackRoot "<FeedbackNotes folder>" -RequireFiveTurnSession
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\NewPlaytestEvidenceBundle.ps1 -SessionId "session-01" -ObservationFormPath "<filled observation form>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CollectExternalEvidenceSession.ps1 -SessionId "session-01" -FeedbackPath "<feedback txt>" -FeedbackManifestPath "<feedback json>" -ObservationFormPath "<filled observation form>" -SupportBundleRoot "<support bundle>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\SummarizePlaytestEvidence.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1 -Initialize
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1 -RequireClosed
```

Steam 상점 자산 생성과 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CaptureSteamKeyArt.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PrepareProfessionalKeyArt.ps1 -SourceImage "<generated key art png>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PromoteSteamScreenshots.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateVisualQuality.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateStoreCopy.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialUiCopy.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamLegalReadiness.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteCommercialLaunchDecision.ps1
```

트레일러 애니매틱 생성과 검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateTrailerAnimatic.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateBuildCaptureTrailer.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateTrailerAssets.ps1
```

릴리즈 감사 보고서 생성:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteReleaseReadinessReport.ps1
```

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.4.5f1\Editor\Unity.exe" -batchmode -quit -projectPath ".\99_GroupProject\Interviewee1UnityAvatarChat" -executeMethod AvatarChatBuildTools.BuildWindows -logFile ".\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-build.log"
```

## 남은 상용화 작업

- 외부 아트 리뷰와 영어 제목 병기 여부 결정
- 빌드 캡처 후보를 라이브 플레이 녹화와 최종 사운드 믹스가 들어간 트레일러로 교체
- Steam AppID, DepotID, 업로드 계정, 테스트 브랜치 설정 확정
- 장시간 플레이 QA와 실제 보조기기 기반 접근성 QA
- 실제 플레이어 대상 5문답 이상 세션 관찰 QA 실행과 피드백 이슈 반영
- 개인정보/저장 데이터 안내 문구의 배포 주체 기준 법무 최종 검토

