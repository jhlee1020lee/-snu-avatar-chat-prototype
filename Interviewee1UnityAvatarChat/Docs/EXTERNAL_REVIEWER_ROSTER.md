# 외부 리뷰어 명단

- 생성 시각: 2026-06-03 01:18:41 +09:00
- 명단 TSV: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\EXTERNAL_REVIEWER_ROSTER.tsv
- 전체 항목: 11
- 배정 완료: 0
- 배정 필요: 11

이 명단은 외부 검토 담당자를 추적표에 안전하게 반영하기 위한 운영 파일이다. 실제 리뷰 증거를 대체하지 않는다.

## 사용 순서

1. EXTERNAL_REVIEWER_ROSTER.tsv의 reviewer_alias, contact_method, due_at을 채운다. due_at은 오늘 이후 날짜로 둔다.
2. contact_method에는 내부 공유용 별칭이나 연락 경로만 적고 비밀번호, API 키, Steam Guard 코드는 넣지 않는다.
3. ApplyExternalReviewerRoster.ps1를 실행해 EXTERNAL_REVIEW_TRACKER.tsv에 반영한다.
4. WriteExternalReviewerPackets.ps1와 WriteExternalReviewOutreachQueue.ps1가 갱신한 패킷과 큐를 확인한다.

## 명단

| ID | 역할 | 권장 프로필 | 리뷰어 | 연락 경로 | 마감 |
| --- | --- | --- | --- | --- | --- |
| PT-01 | 외부 플레이테스트 1 | 일반 PC 사용자, 20분 플레이 가능, 긴 답변 읽기와 기록 저장 흐름을 솔직히 평가할 사람 |  |  |  |
| PT-02 | 외부 플레이테스트 2 | 일반 PC 사용자, 20분 플레이 가능, 긴 답변 읽기와 기록 저장 흐름을 솔직히 평가할 사람 |  |  |  |
| PT-03 | 외부 플레이테스트 3 | 일반 PC 사용자, 20분 플레이 가능, 긴 답변 읽기와 기록 저장 흐름을 솔직히 평가할 사람 |  |  |  |
| PT-04 | 외부 플레이테스트 4 | 일반 PC 사용자, 20분 플레이 가능, 긴 답변 읽기와 기록 저장 흐름을 솔직히 평가할 사람 |  |  |  |
| PT-05 | 외부 플레이테스트 5 | 일반 PC 사용자, 20분 플레이 가능, 긴 답변 읽기와 기록 저장 흐름을 솔직히 평가할 사람 |  |  |  |
| ACCESS-01 | 접근성 검토 | 키보드 전용 조작, 화면 배율, 큰 글자, 고대비 조건을 실제로 확인할 접근성 검토자 |  |  |  |
| ART-01 | 아트 리뷰 | 상업 아트 또는 Steam 캡슐 판독성 검토 경험이 있는 아트 리뷰어 |  |  |  |
| TRAILER-01 | 트레일러 리뷰 | 게임 트레일러의 첫 10초 이해도, 자막, 실제 플레이 전달력을 볼 영상 리뷰어 |  |  |  |
| LEGAL-01 | Steam 관리자/법무 | Steamworks 설정, 개인정보 문구, 테스트 브랜치 실행을 확인할 운영 또는 법무 담당자 |  |  |  |
| QUALITY-01 | 5달러 품질 점수표 | 외부 증거를 읽고 USD 5 이상 품질 점수표를 채울 프로듀서 또는 선임 리뷰어 |  |  |  |
| ISSUE-01 | 외부 이슈 폐쇄 | 외부 리뷰 이슈의 심각도, 재현 단계, 해결 또는 수용 위험을 닫을 QA 담당자 |  |  |  |

## 검증 명령

```powershell
.\Tools\ValidateExternalReviewerRoster.ps1
.\Tools\ApplyExternalReviewerRoster.ps1
.\Tools\ValidateExternalReviewerPackets.ps1 -RequireAssigned
```
