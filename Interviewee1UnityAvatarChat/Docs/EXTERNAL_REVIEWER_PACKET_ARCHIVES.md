# 외부 리뷰어 패킷 ZIP

- 생성 시각: 2026-06-03 01:18:08 +09:00
- 증거 루트: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-20260603-011758\EvidenceDrop
- 원본 패킷: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-20260603-011758\EvidenceDrop\ReviewerPackets
- ZIP 폴더: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-20260603-011758\EvidenceDrop\ReviewerPacketArchives
- ZIP 수: 11
- manifest: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-20260603-011758\EvidenceDrop\ReviewerPacketArchives\REVIEWER_PACKET_ARCHIVE_MANIFEST.tsv

이 ZIP은 리뷰어에게 바로 보낼 수 있는 패킷 묶음이다. ZIP 자체는 운영 자료이며, 최종 출시 증거로는 실제 리뷰어가 반환한 EvidenceDrop 자료만 인정한다.

| ID | 역할 | ZIP | 패키지 | 초대 상태 | 마감 |
| --- | --- | --- | --- | --- | --- |
| PT-01 | 외부 플레이테스트 1 | ReviewerPacketArchives\PT-01.zip | ExternalPlaytestPackage | not_sent |  |
| PT-02 | 외부 플레이테스트 2 | ReviewerPacketArchives\PT-02.zip | ExternalPlaytestPackage | not_sent |  |
| PT-03 | 외부 플레이테스트 3 | ReviewerPacketArchives\PT-03.zip | ExternalPlaytestPackage | not_sent |  |
| PT-04 | 외부 플레이테스트 4 | ReviewerPacketArchives\PT-04.zip | ExternalPlaytestPackage | not_sent |  |
| PT-05 | 외부 플레이테스트 5 | ReviewerPacketArchives\PT-05.zip | ExternalPlaytestPackage | not_sent |  |
| ACCESS-01 | 접근성 검토 | ReviewerPacketArchives\ACCESS-01.zip | CommercialReviewPackage | not_sent |  |
| ART-01 | 아트 리뷰 | ReviewerPacketArchives\ART-01.zip | SteamSubmissionPackage, CommercialReviewPackage | not_sent |  |
| TRAILER-01 | 트레일러 리뷰 | ReviewerPacketArchives\TRAILER-01.zip | SteamSubmissionPackage, CommercialReviewPackage | not_sent |  |
| LEGAL-01 | Steam 관리자/법무 | ReviewerPacketArchives\LEGAL-01.zip | SteamSubmissionPackage, Steamworks staging package | not_sent |  |
| QUALITY-01 | 5달러 품질 점수표 | ReviewerPacketArchives\QUALITY-01.zip | CommercialReviewPackage | not_sent |  |
| ISSUE-01 | 외부 이슈 폐쇄 | ReviewerPacketArchives\ISSUE-01.zip | CommercialReviewPackage | not_sent |  |

## 검증 명령

```powershell
.\Tools\ValidateExternalReviewerPacketArchives.ps1
```
