# 상업 가격 포지셔닝

- 생성 시각: 2026-06-03 01:18:50 +09:00
- 기준 가격: USD 5 이상
- 상태: 차단
- 통과: 2
- 보류: 3
- 차단: 1
- 권고: 가격 논의 전에 차단 항목을 먼저 수정해야 한다.
- 매트릭스 파일: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\COMMERCIAL_PRICE_POSITIONING_MATRIX.tsv

이 문서는 가격 판단용 내부 보조 자료다. 최신 Steam 시장 가격 비교, 외부 리뷰, 공식 품질 점수표를 대체하지 않는다.

## 가격 논리

- USD 5 이상 가격은 단발성 과제물이 아니라 정돈된 대화 세션, 기억장 진행, 기록 저장, 연결 상태와 관계없는 기본 텍스트 대화, 개인정보 관리, 접근성 옵션을 하나의 완성 경험으로 제시할 때만 설득력이 있다.
- 내부 자동 QA가 통과해도 실제 구매자 기대치는 외부 플레이테스트, 상점 아트 리뷰, 최종 트레일러, Steam 관리자 검증으로 확인해야 한다.
- 공식 품질 점수표가 비어 있으면 가격 승인은 보류한다.

## 판단 매트릭스

| 영역 | 주장 | 상태 | 근거 | 위험 | 다음 행동 |
| --- | --- | --- | --- | --- | --- |
| store_promise | 상점 문구가 짧은 체험이 아니라 정돈된 대화 세션, 기억장, 기록, 연결 상태와 관계없는 기본 텍스트 대화 가치를 설명한다. | 통과 | STORE_PAGE_DRAFT.md, STORE_COPY_QA_REPORT.tsv | 가치 제안이 흐리면 USD 5 이상 가격이 단발성 과제물처럼 보일 수 있다. | 상점 첫 문단과 스크린샷 캡션에서 대화 세션, 기억장, 기록, 연결 독립성, 개인정보 관리 요소를 유지한다. |
| product_quality | 내부 자동 품질 기준에서 가격을 즉시 막는 차단 항목이 없다. | 차단 | INTERNAL_QUALITY_REVIEW.md 상태 차단, 평균 3.5, 최저 2, 내부 차단 2 | 내부 차단이 있으면 외부 리뷰 전에 가격 논의를 멈춰야 한다. | INTERNAL_QUALITY_SCORECARD.tsv의 internal_blocker=yes 항목을 먼저 닫는다. |
| official_quality | 공식 5달러 품질 점수표가 외부 리뷰어와 증거 경로로 채워져 있다. | 보류 | COMMERCIAL_QUALITY_REVIEW_QA.md 상태 미완료, 평균 0 | 공식 점수표 없이 내부 점수만으로 USD 5 이상 가격을 승인하면 근거가 약하다. | COMMERCIAL_QUALITY_SCORECARD.tsv에 reviewer, evidence, blocker, 점수를 채우고 -RequireReady를 통과시킨다. |
| external_validation | 외부 플레이테스트, 접근성, 아트, 트레일러, 법무/Steam 증거가 가격 주장을 뒷받침한다. | 보류 | EXTERNAL_EVIDENCE_AUDIT.md 미완료 5, 실패 0 | 외부 증거가 없으면 실제 구매자가 체감하는 가치, 판독성, 신뢰를 검증하지 못한다. | COMMERCIAL_SPRINT_BOARD.tsv의 evidence_collection 레인을 완료한다. |
| price_readiness | P1 상업 출시 백로그가 닫혀 USD 5 이상 출시 후보로 올릴 수 있다. | 보류 | COMMERCIAL_SPRINT_BOARD.tsv 열린 P1 6 | P1이 남아 있으면 가격보다 출시 신뢰 문제가 먼저다. | 열린 P1을 닫고 RunCommercialLaunchGate.ps1 -RequireLaunchReady를 실행한다. |
| market_positioning | 동일 타깃의 짧은 내러티브/인터랙티브 픽션 가격, 태그, 리뷰 톤 비교가 준비되어 있다. | 통과 | STEAM_MARKET_COMPARISON_QA.md 상태 완료, 비교작 8, 차단 0, 보류 0 | 시장 비교 없이 가격을 고정하면 할인 전략, 기대 플레이타임, 태그 포지셔닝이 흔들릴 수 있다. | WriteSteamMarketComparison.ps1로 최종 가격 회의 직전 비교표를 갱신하고 ValidateSteamMarketComparison.ps1 -RequireReady를 통과시킨다. |

## 최종 가격 회의 조건

- ValidateExternalEvidence.ps1 -RequireComplete 통과
- SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete 통과
- ValidateCommercialQualityRubric.ps1 -RequireReady 통과
- ValidateExternalIssueRegister.ps1 -RequireClosed 통과
- ValidateSteamMarketComparison.ps1 -RequireReady 통과
- RunCommercialLaunchGate.ps1 -RequireLaunchReady 통과
