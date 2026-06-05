# 현재 게임 문제점 보고서

작성 시각: 2026-05-31 00:41 KST

검토 범위:
- Unity 프로젝트 `Interviewee1UnityAvatarChat`
- 인접 로컬 서버 `Interviewee1CloneAI`
- 현재 빌드 `Build/Interviewee1UnityAvatarChat.exe`
- 스모크 캡처 `Build/release-smoke`
- QA 문서와 릴리즈 증거 폴더

## 요약

현재 빌드는 실행 파일과 일부 자동 스모크는 존재하지만, 최종 제목/브랜딩, 외부 검증 증거, 출시 게이트, 실제 상점/패키지 준비 상태가 서로 맞지 않는다. 기능적으로는 기본 대화, 긴 답변 스크롤, 패널 단축키 일부가 통과 근거를 갖고 있으나, 새 제목 `겉!=속` 기준으로는 앱 내부와 서버 데이터가 아직 거의 갱신되지 않았다.

## P0/P1 급 문제

### 1. 새 제목 `겉!=속`은 반영됐지만 실행 빌드 재생성이 필요함

근거:
- `Assets/Scripts/AvatarChatApp.cs`, `ProjectSettings.asset`, 서버 `persona.json`, 상점 자산 생성기, 패키지 슬러그는 `겉!=속` / `GeotNotEqualSok`로 정리됐다.
- `Tools/ValidateProductBranding.ps1`가 구 제목과 구 슬러그 회귀를 차단한다.
- 다만 Unity 실행 파일은 창 없는 작업 중에는 재빌드하지 않았으므로, 실제 런타임 화면 반영은 다음 Unity 빌드에서 확인해야 한다.

영향:
- 소스와 상점 자료는 새 제목으로 맞았지만, 실행 파일이 새 소스를 담고 있다는 런타임 증거는 아직 없다.
- 사용자가 가장 먼저 보는 타이틀부터 현재 기획과 불일치한다.

### 2. 최종 출시/검증 산출물이 대부분 비어 있거나 없음

근거:
- 다음 파일이 현재 없음: `Docs/RELEASE_READINESS_REPORT.md`, `Docs/COMMERCIAL_LAUNCH_DECISION.md`, `Docs/COMMERCIAL_LAUNCH_GATE.md`, `Docs/ACCESSIBILITY_AUTOMATION_QA.md`, `Docs/EXTERNAL_EVIDENCE_AUDIT.md`, `Docs/PLAYTEST_EVIDENCE_SUMMARY.md`, `Docs/STEAM_LEGAL_READINESS_QA.md`, `Docs/COMMERCIAL_QUALITY_REVIEW_QA.md`, `Build/ReleaseEvidence/COMMERCIAL_QUALITY_SCORECARD.tsv`, `Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv`.
- `Docs/EXTERNAL_ISSUE_REGISTER_QA.md`는 생성됐지만 상태가 `증거 없음`, 등록 이슈 0개.
- `Build/ReleaseEvidence/EXTERNAL_ISSUE_REGISTER.tsv`는 헤더만 있고 실제 이슈 행이 없음.

영향:
- 자동으로 통과한 일부 UI 스모크와 별개로, 실제 외부 플레이테스트/접근성/아트/법무/Steam 검증은 완료됐다고 볼 수 없다.
- 현재 상태는 “전시/시연 후보”에 가깝고, 유료 출시 후보로 보기에는 증거가 부족하다.

### 3. 서버 상태 확인이 사용자 환경에서 불안정할 수 있음

근거:
- `LaunchAvatarChat.ps1 -CheckOnly -NoStartServer`는 실행 파일, Node, API 키 존재를 확인하고 통과했다.
- 하지만 별도 확인에서 `http://127.0.0.1:8765/api/config`는 2초 타임아웃이 발생했다.
- 이후 `/api/chat` 요청은 연결 거부가 발생했다.
- `../Interviewee1CloneAI/.server.log`에는 서버 실행 로그가 남아 있지만, 현재 `node.exe` 프로세스 목록에는 `Interviewee1CloneAI/server.js` 실행 프로세스가 보이지 않았다.

영향:
- 플레이어는 “서버 사용” 상태처럼 보아도 실제 요청은 실패하고 로컬 fallback에 의존할 수 있다.
- 정보 화면의 서버/API 상태가 즉시 신뢰 가능한지 추가 검증이 필요하다.

## P2 급 문제

### 4. UI가 여전히 앱 패널처럼 강하게 보임

근거:
- `Build/release-smoke/question-phone.png`에서 오른쪽 질문폰은 어두운 반투명 패널로, 전시장 속 노트보다 앱 모달처럼 보인다.
- `Build/release-smoke/accessibility-settings.png` 설정 패널은 중앙 모달로 명확하지만, 배경/캐릭터와 시각적으로 분리되어 있다.
- 기존 문서 `Docs/WHY_UI_STILL_FEELS_CHEAP_20260525.md`도 “UI 카드 자체를 더 줄이거나 장면 속 노트/모니터 표면에 직접 표시해야 한다”고 정리한다.

영향:
- 기능은 동작해도 “전시 공간에서 대화한다”는 몰입감보다 UI 조작감이 앞선다.
- 특히 질문 노트, 기록함, 설정은 실제 소품이 아니라 앱 메뉴처럼 읽힌다.

### 5. 작은 글자와 낮은 대비 영역이 많음

근거:
- `Build/release-smoke/question-phone.png`의 질문 선택 버튼 텍스트가 어둡고 작다.
- `Build/release-smoke/record-delete-confirm.png`의 기록 미리보기 본문은 밝은 배경 위 회색 글자로 길게 표시되어 가독성이 약하다.
- `Build/release-smoke/title-no-save.png`의 시작 카드 보조 설명도 낮은 대비다.

영향:
- 1920x1080 캡처 기준으로도 작은 텍스트가 많아, 빔프로젝터/작은 노트북/화면 확대 환경에서 읽기 부담이 생길 수 있다.

### 6. 접근성은 자동 스모크 일부만 있음

근거:
- `Build/release-smoke/panel-shortcut-*.tsv`는 패널 단축키 충돌 방지 PASS.
- `Build/release-smoke/long-dialogue-layout.tsv`는 긴 답변 스크롤 PASS.
- 그러나 `Docs/ACCESSIBILITY_AUTOMATION_QA.md`는 없고, 실제 보조기기/고대비/화면 확대 관찰 양식도 채워져 있지 않다.

영향:
- “키보드만으로 완주 가능”에 대한 자동 근거는 일부 있지만, 실제 접근성 QA 완료 상태는 아니다.

### 7. 저장/삭제 동작은 있으나 과거 기록 호환 확인이 필요함

근거:
- `Build/release-smoke/record-delete-confirm.png` 미리보기 안에 `겉!=속`가 들어간 기록이 보인다.
- 새 저장 기록과 의견 메모 생성 코드는 `GameTitle`을 따른다.

영향:
- 새 제목 기준 저장은 정리됐지만, 이미 생성된 과거 기록이 섞여 있을 때 기록함 표시가 자연스러운지는 런타임 확인이 필요하다.

### 8. 제품명/패키지명/상점 자산 생성 도구가 예전 이름 체계에 고정됨

근거:
- `ProjectSettings/ProjectSettings.asset:16` productName은 `Interviewee1 Unity Avatar Chat`.
- `LaunchAvatarChat.ps1:10` 로그 prefix는 `[겉!=속]`.
- `Tools/GenerateSteamAssets.ps1`는 Steam 캡슐 제목으로 `겉!=속`를 생성한다.
- `Tools/MakeReleasePackage.ps1`, `MakeSteamSubmissionPackage.ps1`, `RunCommercialLaunchGate.ps1` 등은 `GeotNotEqualSok-*` 패키지명을 기준으로 한다.

영향:
- 제출 패키지, 지원 번들, 빌드 ID, 상점 자산, 안내문이 서로 다른 제품명으로 갈라진다.

## 통과 또는 긍정 근거

- 런처 사전 점검은 실행 파일, 빌드 메타데이터, Node 런타임, API 키 존재를 확인했다.
- `node --check ../Interviewee1CloneAI/server.js`는 문법 통과.
- `Tools/ValidateModelConfig.ps1` 통과.
- `Tools/ValidateCommercialUiCopy.ps1` 통과. 다만 이 검사는 새 제목 불일치까지 잡는 검사는 아니다.
- `Build/release-smoke/long-dialogue-layout.tsv` 긴 답변 스크롤 PASS.
- `Build/release-smoke/thinking-copy.tsv` 생각 중 문구 PASS.
- `Build/release-smoke/panel-shortcut-*.tsv` 패널 단축키 충돌 방지 PASS.
- `Build/release-smoke/avatar-layout.tsv` 아바타 기본 비율 PASS.

## 권장 우선순위

1. 데스크톱 사용 가능 시 Unity 빌드를 다시 만들고 `Build/BUILD_INFO.json`을 갱신한다.
2. `RunReleaseSmoke.ps1 -AllowUnityWindows`로 실제 제목, Paperlogy, 첫 인상 선택, 마무리 카드가 런타임에서 반영됐는지 확인한다.
3. 현재 빌드 기준으로 `RunReleaseSmoke.ps1`, `ValidateAccessibilityAutomation.ps1`, `ValidateVisualQuality.ps1`, `WriteReleaseReadinessReport.ps1`, `RunCommercialLaunchGate.ps1`를 다시 돌려 누락된 QA 산출물을 생성한다.
4. 질문폰/기록함/설정 화면의 작은 텍스트와 대비를 조정한다.
5. 실제 플레이테스트 5명, 접근성 실기기 QA, 아트 리뷰, 법무/Steam 검토 증거를 `Build/ReleaseEvidence`에 채운다.
6. 서버 상태 확인과 API 실패 시 UI 문구를 실제 사용자에게 더 명확히 보이게 한다.

