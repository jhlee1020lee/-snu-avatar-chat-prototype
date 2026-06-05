# 외부 리뷰 발송 큐

- 생성 시각: 2026-06-03 01:18:41 +09:00
- 기준일: 2026-06-03
- 상태: 배정 필요
- 전체 항목: 11
- 리뷰어 배정 필요: 11
- 초대 발송 필요: 0
- 독촉 또는 보완 요청: 0
- 증거 수령 대기: 0
- 수입 대기: 0
- 완료 증거: 0
- 큐 TSV: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv

이 큐는 EXTERNAL_REVIEW_TRACKER.tsv와 ReviewerPackets를 바탕으로 오늘 해야 할 외부 검증 운영 순서를 정리한다. 실제 리뷰 증거를 대체하지 않는다.

## 오늘 할 일

| 순서 | ID | 역할 | 액션 | 권장 마감 | 패킷 | 증거 위치 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ACCESS-01 | 접근성 검토 | 리뷰어 배정 | 2026-06-10 | ReviewerPackets\ACCESS-01 | EvidenceDrop\Accessibility |
| 2 | PT-01 | 외부 플레이테스트 1 | 리뷰어 배정 | 2026-06-10 | ReviewerPackets\PT-01 | EvidenceDrop\Playtest\session-01 |
| 3 | PT-02 | 외부 플레이테스트 2 | 리뷰어 배정 | 2026-06-10 | ReviewerPackets\PT-02 | EvidenceDrop\Playtest\session-02 |
| 4 | PT-03 | 외부 플레이테스트 3 | 리뷰어 배정 | 2026-06-10 | ReviewerPackets\PT-03 | EvidenceDrop\Playtest\session-03 |
| 5 | PT-04 | 외부 플레이테스트 4 | 리뷰어 배정 | 2026-06-10 | ReviewerPackets\PT-04 | EvidenceDrop\Playtest\session-04 |
| 6 | PT-05 | 외부 플레이테스트 5 | 리뷰어 배정 | 2026-06-10 | ReviewerPackets\PT-05 | EvidenceDrop\Playtest\session-05 |
| 7 | ART-01 | 아트 리뷰 | 리뷰어 배정 | 2026-06-13 | ReviewerPackets\ART-01 | EvidenceDrop\ArtReview |
| 8 | LEGAL-01 | Steam 관리자/법무 | 리뷰어 배정 | 2026-06-13 | ReviewerPackets\LEGAL-01 | EvidenceDrop\LegalSteam |
| 9 | TRAILER-01 | 트레일러 리뷰 | 리뷰어 배정 | 2026-06-13 | ReviewerPackets\TRAILER-01 | EvidenceDrop\Trailer |
| 10 | ISSUE-01 | 외부 이슈 폐쇄 | 리뷰어 배정 | 2026-06-17 | ReviewerPackets\ISSUE-01 | EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv |
| 11 | QUALITY-01 | 5달러 품질 점수표 | 리뷰어 배정 | 2026-06-17 | ReviewerPackets\QUALITY-01 | EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv |

## 웨이브

| 웨이브 | 목적 | 항목 | 권장 처리 |
| --- | --- | --- | --- |
| wave-1 | 외부 증거 병목 해소 | PT-01..PT-05, ACCESS-01 | 먼저 배정하고 7일 안에 회수한다. |
| wave-2 | 상점 제출 증거 보강 | ART-01, TRAILER-01, LEGAL-01 | Steam 제출 전 검토 증거를 10일 안에 회수한다. |
| wave-3 | 최종 상업 판정 | QUALITY-01, ISSUE-01 | 외부 증거를 읽고 품질 점수표와 이슈 폐쇄 상태를 확정한다. |

## 검증 명령

```powershell
.\Tools\ValidateExternalReviewOutreachQueue.ps1
.\Tools\ValidateExternalReviewerPackets.ps1 -RequireAssigned
.\Tools\RunCommercialLaunchGate.ps1
```

## 운영 규칙

- reviewer_alias, contact_method, invite_status, due_at은 EXTERNAL_REVIEW_TRACKER.tsv에서 사람이 채운다.
- 여러 명을 한 번에 배정할 때는 EXTERNAL_REVIEWER_ROSTER.tsv를 채우고 ApplyExternalReviewerRoster.ps1를 실행한다.
- 초대 발송 전에는 ReviewerPackets의 해당 ID 폴더에서 README.md와 INVITE.txt를 확인한다.
- 돌아온 EvidenceDrop은 ImportExternalEvidenceDrop.ps1 -Preview로 먼저 확인한다.
- API 키, Steam 비밀번호, Steam Guard 코드, 결제 정보는 어떤 증거에도 넣지 않는다.
