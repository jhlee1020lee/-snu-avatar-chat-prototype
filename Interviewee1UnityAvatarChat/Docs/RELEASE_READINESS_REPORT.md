# 릴리즈 준비 감사 보고서

- 생성 시각: 2026-06-03 01:18:49 +09:00
- 프로젝트: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat
- Windows 패키지: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA
- Steam 제출 패키지: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA
- Steamworks 스테이징 패키지: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamworksStagingPackages\GeotNotEqualSok-Steamworks-QA
- 외부 플레이테스트 패키지: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-20260603-011758
- 상업 검토 패키지: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\CommercialReviewPackages\GeotNotEqualSok-CommercialReview-QA

## 요약

- 자동 통과: 40
- 자동 실패: 9
- 보류: 1
- 외부 검증 미완료: 6

이 보고서는 현재 작업 폴더의 빌드, 상점 자료, 문서, 패키지 검증 결과를 기준으로 한다. 외부 플레이테스트, 실제 보조기기 QA, 외부 아트 리뷰, 최종 법무/Steam 관리자 설정은 이 컴퓨터 안에서 완료했다고 증명할 수 없으므로 미완료로 남긴다.

## 감사 항목

| 영역 | 항목 | 상태 | 근거 | 다음 조치 |
| --- | --- | --- | --- | --- |
| 빌드 | Windows 실행 파일 | 통과 | Build/Interviewee1UnityAvatarChat.exe, 667648 bytes |  |
| 빌드 | 빌드 메타데이터 | 통과 | BUILD_INFO.json 1.0 geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971 확인 |  |
| 빌드 | Unity 빌드 동기화 QA | 통과 | ValidateUnityBuildSync.ps1 통과 |  |
| 실행 | 런처 사전 점검 | 통과 | LaunchAvatarChat.ps1 -CheckOnly -NoStartServer 통과 |  |
| 배포 운영 | 번들 Node.js 런타임 | 통과 | Build/ThirdParty/NodeRuntime v22.22.3 확인 |  |
| 서버 | Node 서버 문법 검사 | 통과 | npm --prefix Interviewee1CloneAI run check 통과 |  |
| 서버 | 모델 설정 QA | 통과 | ValidateModelConfig.ps1 통과 |  |
| 콘텐츠 | 근거 답변 QA | 통과 | RunContentQA.ps1 통과 |  |
| 콘텐츠 | Unity 내장 답변 QA | 실패 | Unity local fallback content QA failed with 1 issue(s). Report: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\UNITY_LOCAL_FALLBACK_CONTENT_QA.md | 수정 후 감사 보고서를 다시 생성한다. |
| 콘텐츠 | 장시간 세션 QA | 통과 | RunLongSessionQA.ps1 통과 |  |
| 콘텐츠 안전 | 개인정보/프롬프트 주입 QA | 통과 | RunSafetyQA.ps1 통과 |  |
| 콘텐츠 안전 | 확장 답변 검토 정책 QA | 통과 | ValidateGeneratedMemoryPolicy.ps1 통과 |  |
| 상용 문구 | 플레이어 UI 문구 QA | 통과 | ValidateCommercialUiCopy.ps1 통과 |  |
| 상용 문구 | 제품 브랜딩 QA | 실패 | Product branding QA failed with 1 issue(s). Report: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\PRODUCT_BRANDING_QA.md | 수정 후 감사 보고서를 다시 생성한다. |
| 배포 운영 | 릴리즈 스모크 창 실행 정책 QA | 통과 | ValidateReleaseSmokePolicy.ps1 통과 |  |
| 핵심 루프 | 릴리즈 스모크 증거 QA | 실패 | Release smoke evidence QA failed with 55 issue(s). Report: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\RELEASE_SMOKE_EVIDENCE_QA.md | 수정 후 감사 보고서를 다시 생성한다. |
| 핵심 루프 | 첫인상 3갈래 깊은 기록 스모크 | 실패 | First impression smoke is missing 'state	build-id		geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971	INFO': C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\release-smoke\first-impression-crutch-deep-arc.tsv | 수정 후 감사 보고서를 다시 생성한다. |
| 상용 문구 | Paperlogy 폰트 QA | 통과 | ValidatePaperlogyUsage.ps1 통과 |  |
| 상점 | Steam 그래픽/스크린샷 QA | 통과 | ValidateSteamAssets.ps1 통과 |  |
| 상점 | 시각 품질 QA | 통과 | ValidateVisualQuality.ps1 통과 |  |
| 접근성 | 접근성 자동 QA | 통과 | ValidateAccessibilityAutomation.ps1 통과 |  |
| 상점 | 트레일러 자산 QA | 통과 | ValidateTrailerAssets.ps1 통과 |  |
| 상점 | 상점 문구 QA | 통과 | ValidateStoreCopy.ps1 통과 |  |
| 법무/상점 | Steam/법무 준비 자동 QA | 통과 | ValidateSteamLegalReadiness.ps1 통과 |  |
| 상업 품질 | 5달러 품질 루브릭 QA | 통과 | ValidateCommercialQualityRubric.ps1 보고서 생성 |  |
| 상업 품질 | 내부 품질 점수표 | 통과 | WriteInternalQualityScorecard.ps1 보고서 생성 |  |
| 상업 운영 | 상업 출시 스프린트 계획 | 통과 | WriteCommercialSprintPlan.ps1 보고서 생성 |  |
| 외부 검증 운영 | 외부 리뷰 브리프 QA | 통과 | ValidateExternalReviewBriefs.ps1 통과 |  |
| 외부 검증 운영 | 외부 리뷰 진행 추적 QA | 통과 | ValidateExternalReviewTracker.ps1 통과 |  |
| 외부 검증 운영 | 외부 리뷰어 명단 QA | 미완료 | 상태 보류, 준비 0/11 | reviewer_alias, contact_method, due_at을 모두 채운 뒤 ApplyExternalReviewerRoster.ps1를 실행한다. |
| 외부 검증 운영 | 외부 리뷰어 전달 패킷 QA | 통과 | ValidateExternalReviewerPackets.ps1 통과 |  |
| 외부 검증 운영 | 외부 리뷰 발송 큐 QA | 통과 | ValidateExternalReviewOutreachQueue.ps1 통과 |  |
| 외부 검증 운영 | 외부 리뷰 초대 outbox QA | 통과 | ValidateExternalReviewInviteOutbox.ps1 통과 |  |
| 외부 검증 운영 | 외부 증거 수입 QA | 통과 | ValidateExternalEvidenceImport.ps1 통과 |  |
| 상업 운영 | Steam 시장 비교 QA | 통과 | ValidateSteamMarketComparison.ps1 보고서 생성 |  |
| 상업 운영 | 가격 포지셔닝 보고서 | 통과 | WriteCommercialPricePositioning.ps1 보고서 생성 |  |
| 상점 | 상점 스크린샷 매니페스트 | 통과 | 11장 스크린샷 매니페스트 확인 |  |
| 외부 검증 운영 | 외부 증거 감사 보고서 | 통과 | ValidateExternalEvidence.ps1 보고서 생성 |  |
| 외부 검증 운영 | 플레이테스트 피드백 export 검증 | 보류 | 현재 BUILD_INFO와 일치하는 최신 피드백 export가 없음: feedback-pt-20260602-182526-cc0ee6cc-20260602-182532-643.json buildId 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' does not match BUILD_INFO 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971'. | 최신 Unity 빌드/런타임 스모크 또는 실제 플레이테스트에서 새 feedback txt/json을 생성한다. |
| 외부 검증 운영 | 플레이테스트 증거 요약 | 통과 | SummarizePlaytestEvidence.ps1 보고서 생성 |  |
| 외부 검증 운영 | 외부 이슈 레지스터 QA | 통과 | ValidateExternalIssueRegister.ps1 보고서 생성 |  |
| 외부 검증 운영 | 외부 이슈 등록 도구 | 통과 | RegisterExternalIssue.ps1 존재 및 검증 연결 확인 |  |
| 문서 | 출시/지원 문서 | 통과 | 49개 출시 문서 확인 |  |
| 보안 | API 키 형태 문자열 검색 | 통과 | API 키 형태 문자열 없음 |  |
| 패키지 | Windows 실행 패키지 검증 | 실패 | Windows 실행 패키지 buildId 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' does not match current build 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971'. | 수정 후 감사 보고서를 다시 생성한다. |
| 패키지 | 패키지 서버 실행 QA | 통과 | RunPackagedServerQA.ps1 통과 |  |
| 지원 | 지원 번들 생성 QA | 통과 | CollectSupportBundle.ps1 필수 파일과 서버 오류 진단 필드 생성, API 키 형태 문자열 없음 |  |
| 외부 검증 운영 | 외부 플레이테스트 패키지 검증 | 실패 | 외부 플레이테스트 패키지 buildId 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' does not match current build 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971'. | 수정 후 감사 보고서를 다시 생성한다. |
| 상업 검토 운영 | 상업 검토 패키지 검증 | 실패 | Missing commercial review package item: Docs\UNITY_LOCAL_FALLBACK_CONTENT_QA.md | 수정 후 감사 보고서를 다시 생성한다. |
| 패키지 | Steam 제출 패키지 검증 | 실패 | Missing Steam submission package item: Docs\GENERATED_MEMORY_POLICY_QA.md | 수정 후 감사 보고서를 다시 생성한다. |
| Steamworks | SteamPipe 스테이징 패키지 검증 | 실패 | Missing Steamworks staging package item: docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md | 수정 후 감사 보고서를 다시 생성한다. |
| 외부 검증 | 실제 플레이어 5문답 이상 관찰 QA | 미완료 | 로컬 자동 QA로 대체할 수 없음 | 외부 참가자 테스트를 진행하고 이슈를 반영한다. |
| 외부 검증 | 실제 보조기기 기반 접근성 QA | 미완료 | 키보드/큰 글자/움직임 줄임 자동 검증만 완료 | 스크린리더, 확대, 실제 입력 장치로 확인한다. |
| 상업 아트 | 외부 아트 리뷰와 최종 키아트 승인 | 미완료 | 현재 키아트는 제출 후보 | 외부 리뷰 또는 전문 보정을 거쳐 최종 승인한다. |
| 트레일러 | 라이브 플레이 녹화와 최종 사운드 믹스 | 미완료 | 현재 애니매틱과 빌드 캡처 후보는 자동 생성본 | 실제 조작 녹화 기반 최종 트레일러로 교체한다. |
| 법무/상점 | 개인정보 문구와 Steam 관리자 설정 최종화 | 미완료 | 현재 문서는 초안 | 배포 주체, 문의 채널, 지역 기준으로 최종 검토한다. |

## 상태 집계

- 미완료: 6
- 보류: 1
- 실패: 9
- 통과: 40
