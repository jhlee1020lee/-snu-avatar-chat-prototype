# 외부 리뷰어 전달 패킷

- 생성 시각: 2026-06-03 01:18:41 +09:00
- 증거 루트: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence
- 패킷 폴더: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets
- 패킷 수: 11
- 추적 TSV: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\EXTERNAL_REVIEW_TRACKER.tsv

이 문서는 외부 리뷰어에게 보낼 역할별 전달 패킷의 생성 결과다. 패킷은 안내와 체크리스트이며, 실제 리뷰 증거로 세지 않는다.

## 운영 순서

1. EXTERNAL_REVIEWER_ROSTER.tsv에 reviewer_alias, contact_method, due_at을 채운 뒤 ApplyExternalReviewerRoster.ps1로 추적표에 반영한다.
2. 이 도구를 다시 실행해 각 리뷰어 패킷을 최신화한다.
3. 각 패킷의 INVITE.txt, README.md, SOURCE_BRIEF.md, DECISION_CALIBRATION.tsv를 담당자에게 보낸다.
4. 담당자가 증거를 넣으면 RUN_EVIDENCE_AUDIT.bat를 실행하고 RETURN_CHECKLIST.tsv를 채운다.
5. 돌아온 EvidenceDrop은 ImportExternalEvidenceDrop.ps1로 미리보기 후 수입한다.

## 패킷

| ID | 역할 | 패킷 | 제출 위치 | 검증 명령 |
| --- | --- | --- | --- | --- |
| PT-01 | 외부 플레이테스트 1 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\PT-01 | EvidenceDrop\Playtest\session-01 | Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest" -RequireNoBlockers -RequireComplete |
| PT-02 | 외부 플레이테스트 2 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\PT-02 | EvidenceDrop\Playtest\session-02 | Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest" -RequireNoBlockers -RequireComplete |
| PT-03 | 외부 플레이테스트 3 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\PT-03 | EvidenceDrop\Playtest\session-03 | Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest" -RequireNoBlockers -RequireComplete |
| PT-04 | 외부 플레이테스트 4 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\PT-04 | EvidenceDrop\Playtest\session-04 | Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest" -RequireNoBlockers -RequireComplete |
| PT-05 | 외부 플레이테스트 5 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\PT-05 | EvidenceDrop\Playtest\session-05 | Tools\SummarizePlaytestEvidence.ps1 -EvidenceRoot "EvidenceDrop\Playtest" -RequireNoBlockers -RequireComplete |
| ACCESS-01 | 접근성 검토 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\ACCESS-01 | EvidenceDrop\Accessibility | Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete |
| ART-01 | 아트 리뷰 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\ART-01 | EvidenceDrop\ArtReview | Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete |
| TRAILER-01 | 트레일러 리뷰 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\TRAILER-01 | EvidenceDrop\Trailer | Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete |
| LEGAL-01 | Steam 관리자/법무 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\LEGAL-01 | EvidenceDrop\LegalSteam | Tools\ValidateExternalEvidence.ps1 -EvidenceRoot "EvidenceDrop" -RequireComplete |
| QUALITY-01 | 5달러 품질 점수표 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\QUALITY-01 | EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv | Tools\ValidateCommercialQualityRubric.ps1 -ScorecardPath "EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv" -RequireReady |
| ISSUE-01 | 외부 이슈 폐쇄 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewerPackets\ISSUE-01 | EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv | Tools\ValidateExternalIssueRegister.ps1 -IssueRegisterPath "EvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv" -RequireClosed |

## 검증 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerPackets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewTracker.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1
```

## 보안

- 패킷에는 API 키, Steam 비밀번호, Steam Guard 코드, 개인 인증 정보를 넣지 않는다.
- 패킷은 증거 수집 안내이며, 최종 출시 증거로는 실제 실행 결과와 작성 양식만 인정한다.
