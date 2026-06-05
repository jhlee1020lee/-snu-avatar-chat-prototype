# 내부 상업 리뷰

- 생성 시각: 2026-06-03 01:18:49 +09:00
- 기준 가격: USD 5 이상
- 리뷰 상태: 차단
- 자동 QA: 통과 40, 실패 9, 보류 1
- 외부 증거: 미완료 5, 실패 0
- 플레이테스트: 완성 세션 0/5, P0 0, P1 0
- 품질 루브릭: 상태 미완료, 평균 0
- 내부 품질 점수표: 상태 차단, 평균 3.5, 최저 2, 내부 차단 2, 외부 의존 8
- 최종 게이트: 보류
- 백로그: P0 2, P1 6, P2 1
- 백로그 파일: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\INTERNAL_COMMERCIAL_BACKLOG.tsv
- 내부 품질 리뷰 파일: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\INTERNAL_QUALITY_REVIEW.md

이 리뷰는 내부 회의용이다. 외부 플레이테스트, 접근성 검토, 아트 리뷰, 최종 트레일러 리뷰, Steam 관리자 증거를 대체하지 않는다.

## 역할별 판단

| 역할 | 판단 | 근거 | 다음 행동 |
| --- | --- | --- | --- |
| 프로듀서/QA | 자동 QA 차단 | 자동 통과 40, 자동 실패 9, 보류 1 | 릴리즈 감사 실패를 먼저 수정한다. |
| 상점 운영 | Steam 상점 제출 자료는 패키징 가능 | COMMERCIAL_LAUNCH_GATE.md Steam 상점 제출 자료 준비됨 | 최종 출시 전까지 외부 증거와 품질 점수표를 채운다. |
| 프로듀서 | 최종 유료 출시는 외부 증거 부족으로 보류 | 외부 증거 미완료 5 | 외부 증거 수집 스프린트를 진행한다. |
| 기획/프로듀서 | 5달러 품질 판정은 아직 확정 불가 | 품질 루브릭 상태 미완료, 평균 0, 문제 32 | 공식 점수표를 외부 증거 기준으로 채운다. |
| 기획/프로듀서 | 내부 품질 기준 차단 | 상태 차단, 평균 3.5, 최저 2, 내부 차단 2 | 내부 점수표의 차단 영역을 먼저 수정한다. |
| 전체 팀 | 5달러 이상 최종 출시는 보류 | 최종 판정 보류, 최종 출시 후보 보류 | 백로그의 P1 항목을 완료하고 게이트를 재실행한다. |

## 다음 스프린트 백로그

| ID | 우선순위 | 담당 | 영역 | 상태 | 근거 | 다음 행동 | 완료 기준 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| INT-AUTO-001 | P0 | QA | 자동 QA | open | RELEASE_READINESS_REPORT.md | 자동 실패와 보류 항목을 재현하고 수정한다. | RELEASE_READINESS_REPORT.md 자동 실패 0, 보류 0 |
| INT-PLAYTEST-001 | P1 | 기획/QA | 외부 플레이테스트 | open | PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 0/5, P0 0, P1 0 | 외부 참가자 5명으로 5문답 세션, 관찰 양식, 피드백 export, 지원 번들을 수집한다. | 완성 세션 5/5, P0 0, P1 0 |
| INT-ACCESS-001 | P1 | 접근성 검토자 | 접근성 | open | EXTERNAL_EVIDENCE_AUDIT.md 실제 접근성 QA 증거 미완료 | 화면 배율, 키보드만 조작, 고대비 또는 실제 입력 장치 테스트 양식과 화면 증거를 수집한다. | ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록 |
| INT-ART-001 | P1 | 아트 리뷰어 | 아트/상점 첫인상 | open | EXTERNAL_EVIDENCE_AUDIT.md 외부 아트 리뷰 증거 미완료 | 작은 캡슐, 키아트, 실제 스크린샷에 대한 외부 아트 리뷰 양식을 수집한다. | ART_REVIEW_FORM.md와 이미지/PDF 근거 등록 |
| INT-TRAILER-001 | P1 | 트레일러 편집자 | 트레일러 | open | EXTERNAL_EVIDENCE_AUDIT.md 최종 트레일러 증거 미완료 | 라이브 플레이 기반 최종 MP4, 리뷰 양식, 자막 또는 캡션 증거를 수집한다. | TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록 |
| INT-LEGAL-001 | P1 | 상점 운영/법무 | Steam 관리자/법무 | open | EXTERNAL_EVIDENCE_AUDIT.md Steam 관리자와 개인정보 최종 증거 미완료 | Steam 관리자 체크리스트, 최종 개인정보 문구, 테스트 브랜치 실행 증거를 수집한다. | Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록 |
| INT-QUALITY-001 | P1 | 기획/프로듀서 | 5달러 품질 루브릭 | open | COMMERCIAL_QUALITY_REVIEW_QA.md 상태 미완료 | COMMERCIAL_QUALITY_SCORECARD.tsv를 리뷰어/evidence 포함으로 채운다. | 상태 완료, 평균 4.0 이상, 최저 3 이상, 차단 0 |
| INT-QUALITY-AUTO-001 | P0 | 기획/프로듀서 | 내부 품질 점수표 | open | INTERNAL_QUALITY_REVIEW.md 내부 차단 2 | INTERNAL_QUALITY_SCORECARD.tsv에서 internal_blocker=yes 영역을 수정한다. | 내부 품질 점수표 내부 차단 0 |
| INT-ISSUE-001 | P2 | QA | 외부 이슈 폐쇄 | open | EXTERNAL_ISSUE_REGISTER_QA.md 상태 증거 없음 | 외부 리뷰에서 발견된 이슈를 등록하고 P2 이상은 verified 또는 수용 위험으로 정리한다. | 이슈 레지스터 상태 완료 |

## 회의 종료 조건

- P0 백로그가 있으면 상점 제출 후보로도 보지 않는다.
- P1 백로그가 남아 있으면 5달러 이상 최종 유료 출시 후보로 보지 않는다.
- 모든 외부 증거와 품질 점수표가 완료된 뒤 RunCommercialLaunchGate.ps1 -RequireLaunchReady를 통과해야 출시 후보로 본다.
