# 상업 출시 스프린트 계획

- 생성 시각: 2026-06-03 01:18:50 +09:00
- 기준 가격: USD 5 이상
- 스프린트 상태: 차단 대응
- 최종 게이트: 보류
- Steam 상점 제출 자료: 준비됨
- 5달러 이상 최종 출시 후보: 보류
- 게이트: 통과 2, 보류 7, 차단 0
- 백로그: P0 2, P1 6, P2 1
- 보드 파일: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\COMMERCIAL_SPRINT_BOARD.tsv

이 계획은 내부 실행 계획이다. 외부 플레이테스트, 접근성 검토, 아트 리뷰, 최종 트레일러 리뷰, Steam 관리자/법무 증거, 공식 품질 점수표를 대체하지 않는다.

## 운영 원칙

- P0가 하나라도 생기면 상점 제출 후보에서 내리고 수정 스프린트를 먼저 연다.
- P1이 남아 있으면 5달러 이상 최종 유료 출시 후보로 보지 않는다.
- 템플릿은 증거가 아니며, 채워진 양식과 원본 파일, 화면 또는 영상 근거가 있어야 완료로 본다.
- 공식 품질 점수표는 내부 점수가 아니라 외부 리뷰어, 증거 경로, 차단 여부를 기준으로 채운다.

## 회의 흐름

| 순서 | 회의 | 입력 | 산출물 | 종료 조건 |
| ---: | --- | --- | --- | --- |
| 1 | 출시 스프린트 킥오프 | 상업 게이트, 내부 상업 리뷰, 내부 품질 점수표 | 담당자별 증거 수집 일정 | 모든 P1 담당자와 제출 폴더 확정 |
| 2 | 외부 검증 수집 | 외부 플레이테스트/접근성/아트/트레일러/법무 패키지 | EvidenceDrop 파일과 이슈 후보 | 필수 증거 파일 누락 0 |
| 3 | 이슈 분류 | 관찰 기록, 리뷰 양식, 피드백 export | EXTERNAL_ISSUE_REGISTER.tsv | P0/P1 재현 경로와 수정 담당 확정 |
| 4 | 품질 판정 | 공식 점수표, 외부 증거, 이슈 레지스터 | COMMERCIAL_QUALITY_SCORECARD.tsv | 평균 4.0 이상, 최저 3 이상, 차단 0 |
| 5 | 최종 게이트 | 모든 보고서와 패키지 | 출시 후보 판정 | RunCommercialLaunchGate.ps1 -RequireLaunchReady 통과 |

## 실행 보드

| ID | 레인 | 우선순위 | 담당 | 영역 | 연결 품질 | 제출 위치 | 산출물 | 검증 명령 | 중단 규칙 | 완료 기준 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| INT-AUTO-001 | fix_now | P0 | QA | 자동 QA |  | Docs와 EvidenceDrop |  | Tools\RunCommercialLaunchGate.ps1 | 해당 항목의 완료 기준을 증거로 확인할 때까지 보류한다. | RELEASE_READINESS_REPORT.md 자동 실패 0, 보류 0 |
| INT-PLAYTEST-001 | evidence_collection | P1 | 기획/QA | 외부 플레이테스트 | core_loop 4/보류, writing 4/보류 | ExternalPlaytestPackage와 EvidenceDrop\Playtest | session-01..session-05 with observation form, feedback txt/json, support bundle | Tools\SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete | P0/P1 발견 시 개발 수정 스프린트로 되돌리고 verified 증거를 남긴다. | 완성 세션 5/5, P0 0, P1 0 |
| INT-ACCESS-001 | evidence_collection | P1 | 접근성 검토자 | 접근성 | readability 2/차단, controls 4/보류 | CommercialReviewPackage EvidenceDrop\Accessibility | ACCESSIBILITY_OBSERVATION_FORM_FILLED.md plus png/mp4 evidence | Tools\ValidateExternalEvidence.ps1 -RequireComplete | 키보드만 조작, 확대, 고대비, 실제 입력 장치 중 하나라도 실패하면 출시 후보에서 내린다. | ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록 |
| INT-ART-001 | evidence_collection | P1 | 아트 리뷰어 | 아트/상점 첫인상 | art_presentation 4/보류 | SteamSubmissionPackage Marketing, CommercialReviewPackage EvidenceDrop\ArtReview | ART_REVIEW_FORM_FILLED.md plus png/jpg/pdf review evidence | Tools\ValidateExternalEvidence.ps1 -RequireComplete | 작은 캡슐 제목 판독, 키아트 잘림, 보라색 잔상 지적이 있으면 상점 자산을 다시 만든다. | ART_REVIEW_FORM.md와 이미지/PDF 근거 등록 |
| INT-TRAILER-001 | evidence_collection | P1 | 트레일러 편집자 | 트레일러 | trailer_store 4/보류 | SteamSubmissionPackage Marketing\Trailer, CommercialReviewPackage EvidenceDrop\Trailer | TRAILER_FINAL_REVIEW_FORM_FILLED.md, final mp4, captions srt/vtt | Tools\ValidateExternalEvidence.ps1 -RequireComplete | 10초 안에 플레이 목적이 전달되지 않거나 자막/사운드가 빠지면 최종 트레일러로 보지 않는다. | TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록 |
| INT-LEGAL-001 | evidence_collection | P1 | 상점 운영/법무 | Steam 관리자/법무 | trust_privacy 4/보류 | SteamSubmissionPackage Marketing\Steamworks, CommercialReviewPackage EvidenceDrop\LegalSteam | STEAM_ADMIN_CHECKLIST_FILLED.md, PRIVACY_NOTICE_FINAL.md, Steam test branch screenshot/pdf | Tools\ValidateExternalEvidence.ps1 -RequireComplete | AppID/DepotID, 문의 채널, 개인정보 최종 문구, 테스트 브랜치 실행 증거가 없으면 제출하지 않는다. | Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록 |
| INT-QUALITY-001 | review_decision | P1 | 기획/프로듀서 | 5달러 품질 루브릭 | core_loop 4/보류, writing 4/보류, readability 2/차단, controls 4/보류, trust_privacy 4/보류, art_presentation 4/보류, trailer_store 4/보류, stability_package 2/차단 | CommercialReviewPackage EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv | COMMERCIAL_QUALITY_SCORECARD.tsv filled with reviewer and evidence | Tools\ValidateCommercialQualityRubric.ps1 -RequireReady | 평균 4.0 미만, 최저 3 미만, 차단 항목, reviewer/evidence 누락 중 하나라도 있으면 보류한다. | 상태 완료, 평균 4.0 이상, 최저 3 이상, 차단 0 |
| INT-QUALITY-AUTO-001 | fix_now | P0 | 기획/프로듀서 | 내부 품질 점수표 |  | Docs와 EvidenceDrop |  | Tools\RunCommercialLaunchGate.ps1 | 해당 항목의 완료 기준을 증거로 확인할 때까지 보류한다. | 내부 품질 점수표 내부 차단 0 |
| INT-ISSUE-001 | triage_verification | P2 | QA | 외부 이슈 폐쇄 | core_loop 4/보류, readability 2/차단, controls 4/보류, trust_privacy 4/보류, art_presentation 4/보류, trailer_store 4/보류 | Build\ReleaseEvidence\EXTERNAL_ISSUE_REGISTER.tsv | EXTERNAL_ISSUE_REGISTER.tsv with P0/P1 verified and P2 closed or accepted risk | Tools\ValidateExternalIssueRegister.ps1 -RequireClosed | P0/P1 미검증 또는 P2 미해결이 남으면 최종 게이트를 통과시키지 않는다. | 이슈 레지스터 상태 완료 |

## 패키지 인계

- 외부 플레이테스트: Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA
- 상업 검토: Build\CommercialReviewPackages\GeotNotEqualSok-CommercialReview-QA
- Steam 제출: Build\SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA
- 최종 증거 원본: Build\ReleaseEvidence

## 검증 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\SummarizePlaytestEvidence.ps1 -RequireNoBlockers -RequireComplete
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1 -RequireClosed
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady
```
