# 상업 출시 검토 보드

`겉!=속`를 5달러 이상 유료 판매 후보로 판단하기 위한 최종 검토 보드다. 자동 검증은 기본 조건이고, 아래 항목은 외부 증거가 있어야 완료로 볼 수 있다.

## 검토 참여 역할

| 역할 | 책임 |
| --- | --- |
| 기획 | 핵심 루프, 5문답 세션, 기억장/마무리 카드 보상감 판단 |
| QA | 실행, 저장, 삭제, 긴 답변, 회귀 테스트 판단 |
| 접근성 검토자 | 키보드, 화면 확대, 고대비, 실제 입력 장치 확인 |
| 아트 리뷰어 | 캡슐, 스크린샷, 제목 가독성, 실제 게임과의 톤 일치 확인 |
| 트레일러 편집자 | 라이브 플레이 녹화, 컷 구성, 자막, 최종 사운드 믹스 확인 |
| 상점 운영자 | Steam AppID, DepotID, 빌드 업로드, 상점 문구, 개인정보 문구 확인 |

## 출시 후보 게이트

| 게이트 | 완료 증거 | 차단 기준 |
| --- | --- | --- |
| 외부 플레이테스트 | 관찰 기록 5명분, 지원 번들, 피드백 원문, 피드백 JSON 세션 정보 | P0/P1 이슈 존재 |
| 실제 접근성 QA | `Docs/ACCESSIBILITY_AUTOMATION_QA.md`, 접근성 관찰 양식, 화면 배율/키보드/고대비 결과 | 키보드만으로 5문답 불가 |
| 아트 리뷰 | 아트 리뷰 양식, 작은 캡슐 미리보기 승인 | 작은 캡슐 제목 판독 불가 |
| 시각 품질 QA | `Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv`, QA 통과 로그 | 스크린샷 또는 Steam 캡슐이 너무 어둡거나 보라색 잔상/가장자리 잘림 위험 |
| 상용 UI 문구 QA | `Docs/COMMERCIAL_UI_COPY_QA.md`, QA 통과 로그 | 플레이어 화면 또는 의견 메모에 내부 검토 표현, 별표 강조, AI식 정체성 문구가 남거나 로컬 답변/정보 접근 선택권이 없음 |
| 긴 답변 레이아웃 | `Build/release-smoke/long-dialogue-layout.tsv`, `Docs/ACCESSIBILITY_AUTOMATION_QA.md` | 긴 답변이 대사창 밖으로 새거나 스크롤 cue/스크롤바가 준비되지 않음 |
| 캐릭터 비율 레이아웃 | `Build/release-smoke/avatar-layout.tsv`, `Docs/ACCESSIBILITY_AUTOMATION_QA.md` | 캐릭터가 좌우로 눌려 보이거나 preserveAspect 기준 없이 늘어남 |
| 생각 중 문구 | `Build/release-smoke/thinking-copy.tsv`, `Docs/ACCESSIBILITY_AUTOMATION_QA.md` | 입력 직후 `좋아요`, `잠깐` 같은 접수 표현이나 장황한 생각 중 문구가 표시됨 |
| 모델 설정 QA | `Docs/MODEL_CONFIG_QA.md`, `ValidateModelConfig.ps1` 통과 로그 | 잘못된 모델명이 기본값으로 전환되지 않거나 텍스트 fallback이 끊김 |
| 5달러 품질 루브릭 | `Docs/COMMERCIAL_QUALITY_REVIEW_QA.md`, `Build/ReleaseEvidence/COMMERCIAL_QUALITY_SCORECARD.tsv` | 평균 4.0 미만, 최저 3 미만, 차단 항목 존재, reviewer/evidence 누락 |
| 내부 품질 점수표 | `Docs/INTERNAL_QUALITY_REVIEW.md`, `Docs/INTERNAL_QUALITY_SCORECARD.tsv` | 내부 자동 기준에서 차단 영역이 있거나 외부 증거 의존 항목이 남음 |
| Steam 시장 비교 | `Docs/STEAM_MARKET_COMPARISON.md`, `Docs/STEAM_MARKET_COMPARISON_QA.md` | 비교작 5개 미만, 가격/태그/리뷰 요약/Steam 출처 누락, 30일 이상 지난 캐시 |
| 가격 포지셔닝 | `Docs/COMMERCIAL_PRICE_POSITIONING.md`, `Docs/COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv` | 외부 증거, 공식 품질 점수표, 최신 Steam 유사작 가격 비교가 비어 있음 |
| 외부 리뷰 브리프 | `Docs/EXTERNAL_REVIEW_BRIEFS.md`, `Docs/EXTERNAL_REVIEW_BRIEFS_QA.md`, `Build/ReleaseEvidence/ReviewBriefs` | 역할별 제출 위치, 중단 기준, 검증 명령, 비밀정보 금지 안내 누락 |
| 외부 리뷰 진행 추적 | `Docs/EXTERNAL_REVIEW_TRACKER.md`, `Docs/EXTERNAL_REVIEW_TRACKER_QA.md`, `Build/ReleaseEvidence/EXTERNAL_REVIEW_TRACKER.tsv` | 플레이테스트 5명, 접근성, 아트, 트레일러, Steam/법무, 품질점수표, 이슈 폐쇄 추적 행 누락 |
| 외부 리뷰어 명단 | `Docs/EXTERNAL_REVIEWER_ROSTER.md`, `Docs/EXTERNAL_REVIEWER_ROSTER_QA.md`, `Build/ReleaseEvidence/EXTERNAL_REVIEWER_ROSTER.tsv` | 리뷰어 별칭, 연락 경로, 마감일, 예비 담당자 입력 누락 |
| 외부 리뷰어 전달 패킷 | `Docs/EXTERNAL_REVIEWER_PACKETS.md`, `Docs/EXTERNAL_REVIEWER_PACKETS_QA.md`, `Build/ReleaseEvidence/ReviewerPackets` | ID별 초대문, README, 원본 브리프, 수락 체크리스트 누락 |
| 외부 리뷰 발송 큐 | `Docs/EXTERNAL_REVIEW_OUTREACH_QUEUE.md`, `Docs/EXTERNAL_REVIEW_OUTREACH_QA.md`, `Build/ReleaseEvidence/EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv` | 다음 배정, 초대, 독촉, 수입 액션 누락 |
| 외부 증거 수입 | `Docs/EXTERNAL_EVIDENCE_IMPORT_QA.md`, `ImportExternalEvidenceDrop.ps1`, `ValidateExternalEvidenceImport.ps1` | 반환된 EvidenceDrop 수입 중 충돌, 비밀키 형태 문자열, 템플릿 증거 오판 |
| 최종 트레일러 | 라이브 플레이 녹화본, 최종 MP4, 자막, 사운드 확인 | 실제 플레이가 무엇인지 10초 안에 불명확 |
| 법무/Steam 관리자 | `Docs/STEAM_LEGAL_READINESS_QA.md`, `ValidateSteamLegalReadiness.ps1` 통과 로그, 개인정보 문구 최종본, AppID/DepotID 기록, 테스트 브랜치 실행 증거 | 비밀정보 또는 계정 정보 저장소 포함 |
| API 키 위생 | `Docs/RELEASE_READINESS_REPORT.md`, 패키지 검증 로그 | 실제 API 키 또는 점 세 개로 줄인 키 예시가 README, 지원 번들, 제출 패키지에 남음 |
| 외부 이슈 폐쇄 | `Docs/EXTERNAL_ISSUE_REGISTER_QA.md`, `ValidateExternalIssueRegister.ps1 -RequireClosed` 통과 로그 | P0/P1 미검증 또는 P2 미해결 |
| 패키지 빌드 추적 | `Docs/RELEASE_READINESS_REPORT.md`, 현재 `BUILD_INFO.json`, Windows/외부 플레이테스트/SteamPipe 패키지의 `BUILD_INFO.json`, Steam 제출/상업 검토 패키지의 `PACKAGE_PROVENANCE.json` | 제출 후보 패키지가 현재 빌드 ID와 다름 |

외부 증거는 `Build/ReleaseEvidence`에 모으고 `ValidateExternalEvidence.ps1 -RequireComplete`를 통과해야 최종 게이트를 통과한 것으로 본다.
외부 플레이테스트 패키지와 상업 검토 패키지 안에서는 `RUN_EVIDENCE_AUDIT.bat`로 `EvidenceDrop` 보고서를 갱신하고, 최종 회의 직전에는 `RUN_FINAL_EVIDENCE_GATE.bat`를 실행한다.
플레이테스트 이슈는 `SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete`를 통과해야 P0/P1이 없는 것으로 본다.
외부 리뷰 이슈는 `ValidateExternalIssueRegister.ps1 -RequireClosed`를 통과해야 수정과 검증이 끝난 것으로 본다.
5달러 품질 점수표는 `ValidateCommercialQualityRubric.ps1 -RequireReady`를 통과해야 상업 품질 기준을 통과한 것으로 본다.
최종 회의용 판정은 `Docs/COMMERCIAL_LAUNCH_DECISION.md`와 `WriteCommercialLaunchDecision.ps1 -RequireLaunchReady`를 기준으로 확인한다.
내부 회의에서는 `Docs/INTERNAL_QUALITY_REVIEW.md`, `Docs/INTERNAL_QUALITY_SCORECARD.tsv`, `Docs/INTERNAL_COMMERCIAL_REVIEW.md`, `Docs/INTERNAL_COMMERCIAL_BACKLOG.tsv`를 먼저 보고, 내부 차단 또는 P1 백로그가 남아 있으면 5달러 이상 최종 유료 출시 후보로 올리지 않는다.
상업 출시 스프린트 운영은 `Docs/COMMERCIAL_SPRINT_PLAN.md`와 `Docs/COMMERCIAL_SPRINT_BOARD.tsv`를 기준으로 담당자, 제출 위치, 검증 명령, 중단 규칙을 확인한다.
외부 담당자에게 넘기는 자료는 `Docs/EXTERNAL_REVIEW_BRIEFS.md`, `Build/ReleaseEvidence/ReviewBriefs`, `Build/ReleaseEvidence/ReviewerPackets`를 기준으로 통일한다. 배정 후보는 `Build/ReleaseEvidence/EXTERNAL_REVIEWER_ROSTER.tsv`에 모으고, `ApplyExternalReviewerRoster.ps1`로 배정/초대/수령 상태를 `Build/ReleaseEvidence/EXTERNAL_REVIEW_TRACKER.tsv`에 반영한다. 당일 운영 순서는 `Build/ReleaseEvidence/EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv`로 확인한다.
반환된 패키지의 `EvidenceDrop`은 원본 폴더로 직접 복사하지 않고 `ImportExternalEvidenceDrop.ps1 -Preview`로 충돌을 확인한 뒤 수입한다.
USD 5 이상 가격 논의는 `ValidateSteamMarketComparison.ps1 -RequireReady`와 `Docs/COMMERCIAL_PRICE_POSITIONING.md`가 통과 상태가 된 뒤에만 최종 가격 후보로 올린다.
최종 출시 버튼 전에는 `RunCommercialLaunchGate.ps1 -RequireLaunchReady`를 실행해 자동 QA, 외부 증거, 플레이테스트, 외부 이슈, 상업 판정이 한 번에 통과하는지 확인한다.

## 결정 기록

| 날짜 | 빌드 ID | 결정 | 근거 | 남은 조치 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## 출시 후보 판정

- 자동 감사 실패가 있으면 출시 후보가 아니다.
- 외부 검증 미완료 항목이 있으면 상점 등록 준비물은 될 수 있지만, 최종 유료 출시 후보는 아니다.
- P0/P1 이슈가 없는 외부 테스트 기록과 Steam 테스트 브랜치 실행 증거가 모였을 때만 최종 후보로 본다.
- 5달러 품질 루브릭이 완료 상태가 아니면 최종 후보가 아니다.
- 외부 리뷰 이슈 장부에 P0/P1 미검증 또는 P2 미해결 항목이 남아 있으면 최종 후보가 아니다.
- 제출 후보 패키지의 빌드 ID 또는 패키지 provenance가 현재 빌드와 다르면 최종 후보가 아니다.
- `COMMERCIAL_LAUNCH_DECISION.md`가 `5달러 이상 최종 출시 후보: 통과`가 아니면 출시 버튼을 누르지 않는다.
- `COMMERCIAL_LAUNCH_GATE.md`가 `최종 판정: 통과`가 아니면 출시 버튼을 누르지 않는다.


