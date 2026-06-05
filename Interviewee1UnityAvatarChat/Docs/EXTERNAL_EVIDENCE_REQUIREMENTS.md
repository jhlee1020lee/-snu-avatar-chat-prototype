# 외부 검증 증거 요구사항

자동 QA는 출시 후보의 기본 조건을 확인한다. 아래 증거는 실제 사람과 외부 운영 환경에서만 만들 수 있으므로, 최종 유료 출시 후보 판단 전에 별도로 모아야 한다.

## 증거 루트

기본 위치:

`Build/ReleaseEvidence`

권장 구조:

```text
Build/ReleaseEvidence/
  Playtest/
    session-01/
    session-02/
    session-03/
    session-04/
    session-05/
  Accessibility/
  ArtReview/
  Trailer/
  LegalSteam/
```

초기 폴더를 만들려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -Initialize
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PrepareCommercialEvidenceWorkspace.ps1 -EvidenceRoot ".\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence" -Force
```

`PrepareCommercialEvidenceWorkspace.ps1`는 각 증거 폴더에 템플릿과 `EVIDENCE_COLLECTION_PLAN.tsv`를 넣는다. `TEMPLATE` 또는 `REFERENCE`가 붙은 파일은 실제 증거로 세지 않는다.
같은 실행에서 `ReviewBriefs` 폴더, `ReviewerPackets` 폴더, `ReviewerPacketArchives` 폴더, `EXTERNAL_REVIEW_TRACKER.tsv`, `EXTERNAL_REVIEWER_ROSTER.tsv`, `EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv`, `Docs/EXTERNAL_REVIEW_BRIEFS.md`, `Docs/EXTERNAL_REVIEWER_PACKETS.md`, `Docs/EXTERNAL_REVIEWER_PACKET_ARCHIVES.md`, `Docs/EXTERNAL_REVIEWER_ROSTER.md`, `Docs/EXTERNAL_REVIEW_OUTREACH_QUEUE.md`도 준비된다. 브리프, 리뷰어 패킷, 리뷰어별 ZIP, 리뷰어 명단, 추적 보드, 발송 큐는 외부 담당자에게 보낼 안내문과 운영 장부이며, 실제 증거로 세지 않는다.

증거 상태를 감사하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewBriefs.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewTracker.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerRoster.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerPackets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerPacketArchives.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewOutreachQueue.ps1
```

외부 플레이테스트 1회차 증거를 세션 폴더로 묶으려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidatePlaytestFeedbackExport.ps1 -FeedbackRoot "<PlaytestFeedback folder>" -RequireFiveTurnSession
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\NewPlaytestEvidenceBundle.ps1 -SessionId "session-01" -ObservationFormPath "<filled observation form>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CollectExternalEvidenceSession.ps1 -SessionId "session-01" -FeedbackPath "<feedback txt>" -FeedbackManifestPath "<feedback json>" -ObservationFormPath "<filled observation form>" -SupportBundleRoot "<support bundle>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\SummarizePlaytestEvidence.ps1
```

세션 진행 전에는 `Docs/PLAYTEST_PARTICIPANT_BRIEF.md`로 참가자에게 입력 금지 정보와 저장 자료를 안내하고, `Docs/PLAYTEST_MODERATOR_SCRIPT.md`로 진행자 개입 기준과 종료 질문을 맞춘다.

외부 플레이테스트 패키지나 상업 검토 패키지 안에서는 패키지 루트의 배치 파일을 사용한다:

```bat
RUN_EVIDENCE_AUDIT.bat
RUN_FINAL_EVIDENCE_GATE.bat
```

- `RUN_EVIDENCE_AUDIT.bat`는 `EvidenceDrop`을 기준으로 감사 보고서, 플레이테스트 요약, 피드백 기반 품질 점수표 초안, 외부 이슈 QA 보고서를 새로 쓴다.
- `RUN_FINAL_EVIDENCE_GATE.bat`는 증거가 완성됐는지, P0/P1 차단 이슈가 없는지, 외부 이슈 장부가 닫혔는지 강제 확인한다.
- 패키지 안의 증거 도구는 `EvidenceDrop`을 기본 증거 위치로 잡는다.
- 패키지에 복사되는 PowerShell 도구는 Windows PowerShell에서도 깨지지 않도록 UTF-8 BOM으로 저장한다.
- `EvidenceDrop\EVIDENCE_COLLECTION_PLAN.tsv`는 내부 백로그 ID별로 필요한 파일, 수집 명령, 완료 기준을 보여준다.
- `EvidenceDrop\ReviewBriefs`는 플레이테스트, 접근성, 아트, 트레일러, Steam/법무, 품질점수표 담당자에게 넘길 브리프를 담는다.
- `EvidenceDrop\EXTERNAL_REVIEW_TRACKER.tsv`는 담당자 배정, 초대 발송, 마감, 증거 수령 상태를 추적한다.
- `EvidenceDrop\EXTERNAL_REVIEWER_ROSTER.tsv`는 리뷰어 별칭, 연락 경로, 마감일, 예비 담당자를 모아 추적표에 반영하기 위한 명단이다.
- `EvidenceDrop\ReviewerPackets`는 각 추적 항목별 초대문, README, 원본 브리프, 수락 체크리스트를 담는다.
- `EvidenceDrop\ReviewerPacketArchives`는 각 리뷰어 패킷을 바로 보낼 수 있게 묶은 ZIP과 SHA256 manifest를 담는다.
- `EvidenceDrop\EXTERNAL_REVIEW_OUTREACH_QUEUE.tsv`는 다음 배정, 초대 발송, 독촉, 수입 액션 순서를 보여준다.

외부 패키지가 돌아오면 원본 프로젝트에서 먼저 미리보기 수입을 실행한다:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ImportExternalEvidenceDrop.ps1 -SourceEvidenceDrop "<returned package>\EvidenceDrop" -Preview
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidenceImport.ps1
```

미리보기에서 충돌이 0이면 실제 수입을 실행한다:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ImportExternalEvidenceDrop.ps1 -SourceEvidenceDrop "<returned package>\EvidenceDrop"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1
```

`ImportExternalEvidenceDrop.ps1`는 템플릿, 참고 파일, 생성 보고서, 브리프, 리뷰어 패킷을 증거로 들여오지 않는다. 같은 파일은 건너뛰고, 대상에 다른 내용의 파일이 있으면 `-Force` 없이는 충돌로 멈춘다. 빈 공식 품질 점수표 템플릿은 수입하지 않고, 실제 점수와 reviewer/evidence가 채워진 `COMMERCIAL_QUALITY_SCORECARD.tsv`만 수입 대상으로 본다. 단, 대상이 빈 공식 점수표 템플릿이고 반환된 점수표가 채워져 있으면 외부 회신 수입을 막지 않도록 `-Force` 없이 교체한다.

외부 리뷰 이슈 장부를 만들고 검증하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1 -Initialize
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RegisterExternalIssue.ps1 -IssueId "EXT-001" -Priority "P2" -Area "UI" -Source "session-01" -SessionId "session-01" -Title "질문폰 탭 이동 안내가 부족함" -ReproSteps "질문폰을 열고 숫자키를 누른다" -Expected "탭이 명확히 바뀐다" -Actual "관찰자가 기능을 알아차리지 못했다"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1
```

5달러 이상 상업 품질 점수표를 만들고 검증하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -Initialize
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ExportFeedbackToCommercialQualityScorecard.ps1 -FeedbackRoot ".\Build\ReleaseEvidence\Playtest" -OutputPath ".\Build\ReleaseEvidence\COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady
```

`COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv`는 참가자 피드백을 빠르게 모아보는 초안이다. 최종 판정에는 리뷰어가 증거를 확인하고 직접 채운 `COMMERCIAL_QUALITY_SCORECARD.tsv`만 사용한다. 점수표의 evidence 값은 `EvidenceDrop` 또는 `Build/ReleaseEvidence` 기준 상대 경로여야 하며, 검증 시 실제 파일이나 폴더가 없으면 보류된다.

증거가 모두 갖춰져야 통과하도록 강제하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidenceImport.ps1 -RequireImportedFiles
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerPackets.ps1 -RequireAssigned
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerPacketArchives.ps1 -RequireAssigned
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerRoster.ps1 -RequireReady
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalIssueRegister.ps1 -RequireClosed
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady
```

## 필수 증거

| 영역 | 최소 증거 |
| --- | --- |
| 외부 플레이테스트 | 참가자 5명분 세션 폴더, 각 세션의 관찰 양식, 지원 번들, 피드백 원문, 피드백 JSON 세션 정보, 참가자 안내와 진행자 스크립트 준수 기록 |
| 실제 접근성 QA | `ACCESSIBILITY_OBSERVATION_FORM.md`, 화면 배율/키보드/고대비 또는 실제 입력 장치 증거 |
| 외부 아트 리뷰 | `ART_REVIEW_FORM.md`, 작은 캡슐 또는 키아트 검토 증거 |
| 최종 트레일러 | 실제 조작 녹화 기반 최종 MP4, `TRAILER_FINAL_REVIEW_FORM.md`, 자막 또는 컷 검토 증거 |
| 법무/Steam 관리자 | `STEAM_ADMIN_CHECKLIST.md`, 최종 개인정보 문구, Steam 테스트 브랜치 실행 증거 |
| 외부 리뷰 이슈 폐쇄 | `Build/ReleaseEvidence/EXTERNAL_ISSUE_REGISTER.tsv`, P0/P1 verified 상태, P2 해결 또는 수용 위험 기록 |
| 5달러 품질 점수표 | `Build/ReleaseEvidence/COMMERCIAL_QUALITY_SCORECARD.tsv`, 평균 4.0 이상, 최저 3 이상, 차단 항목 0, reviewer 기입, 실제 존재하는 evidence 상대 경로 |

## 보안 기준

- API 키 값, Steam 계정 비밀번호, Steam Guard 코드, 개인 인증 정보는 증거 폴더에 넣지 않는다.
- `ValidateExternalEvidence.ps1`와 `ImportExternalEvidenceDrop.ps1`는 OpenAI API 키, bearer/token 필드, 비밀번호 필드, Steam Guard 코드, Steam mobile secret, private key block 형태 문자열을 즉시 실패로 처리한다.
- `sk-`로 시작하는 OpenAI 비밀키 형태 문자열이나 Steam 인증정보가 발견되면 즉시 P0로 분류한다.
- 계정명은 필요한 경우 별도 보안 문서에 관리하고, 이 패키지에는 권한 보유 여부와 증거 파일명만 남긴다.

## 이슈 레지스터 기준

- 템플릿은 `Docs/EXTERNAL_ISSUE_REGISTER_TEMPLATE.tsv`에 있다.
- 실제 장부는 `Build/ReleaseEvidence/EXTERNAL_ISSUE_REGISTER.tsv`에 둔다.
- 외부 이슈는 손으로 TSV를 편집하기보다 `Tools/RegisterExternalIssue.ps1`로 등록한다.
- P0/P1은 `verified` 상태가 아니면 최종 출시 후보로 보지 않는다.
- P2가 `open`, `in_progress`, `fixed` 상태로 남아 있으면 상업 품질 리스크로 본다.
- `verified` 이슈는 수정 요약, 검증자, 검증 시각, 증거 경로가 있어야 한다.

