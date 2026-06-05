# 외부 리뷰 진행 추적 보드

- 생성 시각: 2026-06-03 01:18:41 +09:00
- 상태: 진행 전
- 추적 항목: 11
- 담당 배정: 0/11
- 초대 발송: 0/11
- 증거 완료: 0
- 증거 일부: 0
- 증거 없음: 11
- 추적 TSV: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\EXTERNAL_REVIEW_TRACKER.tsv

이 보드는 외부 검증 업무의 배정과 증거 수령 상태를 추적한다. 실제 리뷰 증거를 대체하지 않으며, reviewer_alias, contact_method, invite_status, due_at, notes는 사람이 채운 뒤 다음 실행에서도 보존된다.

## 항목

| ID | 역할 | 배정 | 초대 | 증거 | 제출 위치 | 다음 조치 |
| --- | --- | --- | --- | --- | --- | --- |
| PT-01 | 외부 플레이테스트 1 | needs_owner | not_sent | missing | EvidenceDrop\Playtest\session-01 | 참가자 1명을 배정하고 session-01 증거를 수집한다. |
| PT-02 | 외부 플레이테스트 2 | needs_owner | not_sent | missing | EvidenceDrop\Playtest\session-02 | 참가자 1명을 배정하고 session-02 증거를 수집한다. |
| PT-03 | 외부 플레이테스트 3 | needs_owner | not_sent | missing | EvidenceDrop\Playtest\session-03 | 참가자 1명을 배정하고 session-03 증거를 수집한다. |
| PT-04 | 외부 플레이테스트 4 | needs_owner | not_sent | missing | EvidenceDrop\Playtest\session-04 | 참가자 1명을 배정하고 session-04 증거를 수집한다. |
| PT-05 | 외부 플레이테스트 5 | needs_owner | not_sent | missing | EvidenceDrop\Playtest\session-05 | 참가자 1명을 배정하고 session-05 증거를 수집한다. |
| ACCESS-01 | 접근성 검토 | needs_owner | not_sent | missing | EvidenceDrop\Accessibility | 접근성 검토자를 배정하고 실제 입력 조건 증거를 받는다. |
| ART-01 | 아트 리뷰 | needs_owner | not_sent | missing | EvidenceDrop\ArtReview | 아트 리뷰어에게 캡슐과 실제 화면을 함께 전달한다. |
| TRAILER-01 | 트레일러 리뷰 | needs_owner | not_sent | missing | EvidenceDrop\Trailer | 실제 조작 녹화 기반 최종 트레일러 검토를 요청한다. |
| LEGAL-01 | Steam 관리자/법무 | needs_owner | not_sent | missing | EvidenceDrop\LegalSteam | 상점 운영/법무 담당자에게 비밀정보 없는 증거를 요청한다. |
| QUALITY-01 | 5달러 품질 점수표 | needs_owner | not_sent | missing | EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv | 프로듀서가 외부 증거를 확인하고 공식 점수표를 채운다. |
| ISSUE-01 | 외부 이슈 폐쇄 | needs_owner | not_sent | missing | EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv | 외부 리뷰 이슈를 등록하고 해결/검증 상태를 갱신한다. |

## 운영 기준

- invite_status는 not_sent, sent, accepted, declined 중 하나로 둔다.
- 외부 증거 파일이 들어온 뒤에도 validation_command가 통과하기 전까지 최종 출시 후보로 보지 않는다.
- reviewer_alias에는 실제 이름 대신 식별 가능한 약칭을 써도 된다.
- contact_method에는 개인 연락처 원문보다 팀 내부에서 찾을 수 있는 채널명만 둔다.

## 검증 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewTracker.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady
```
