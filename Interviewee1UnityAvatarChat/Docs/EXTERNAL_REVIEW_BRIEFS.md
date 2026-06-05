# 외부 리뷰 브리프

- 생성 시각: 2026-06-03 01:18:41 +09:00
- 증거 루트: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence
- 브리프 폴더: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\ReviewBriefs

이 문서는 외부 검증을 시작하기 전에 담당자에게 넘길 안내 묶음이다. 자동 QA나 내부 점수를 대체하지 않고, 실제 증거를 모으기 위한 운영 문서다.

## 역할별 브리프

| 역할 | 파일 | 제출 위치 | 완료 기준 |
| --- | --- | --- | --- |
| 외부 플레이테스트 | ReviewBriefs\PLAYTEST_REVIEW_BRIEF.md | EvidenceDrop\Playtest | 5명 이상 완성 세션, P0/P1 0 |
| 접근성 검토 | ReviewBriefs\ACCESSIBILITY_REVIEW_BRIEF.md | EvidenceDrop\Accessibility | 관찰 양식과 화면/녹화 증거 |
| 아트 리뷰 | ReviewBriefs\ART_REVIEW_BRIEF.md | EvidenceDrop\ArtReview | 검토 양식, 표시 이미지, 승인 또는 보류 결론 |
| 트레일러 리뷰 | ReviewBriefs\TRAILER_REVIEW_BRIEF.md | EvidenceDrop\Trailer | 최종 영상, 자막, 리뷰 양식 |
| Steam 관리자/법무 | ReviewBriefs\LEGAL_STEAM_REVIEW_BRIEF.md | EvidenceDrop\LegalSteam | Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 |
| 5달러 품질 점수표 | ReviewBriefs\QUALITY_SCORECARD_REVIEW_BRIEF.md | EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv | 평균 4.0 이상, 최저 3 이상, 차단 0 |
| 공통 판정 기준표 | ReviewBriefs\REVIEW_DECISION_CALIBRATION.tsv | 모든 리뷰 영역 | 3점, 4점 이상, 차단 기준을 같은 문장으로 적용 |

## 운영 순서

1. Build\ReleaseEvidence\ReviewBriefs의 역할별 파일을 담당자에게 보낸다.
2. 모든 담당자에게 ReviewBriefs\REVIEW_DECISION_CALIBRATION.tsv를 함께 보내 점수 기준을 맞춘다.
3. 각 담당자는 제출 위치에 실제 증거를 넣는다.
4. 발견 이슈는 RegisterExternalIssue.ps1로 등록한다.
5. 증거를 넣은 뒤 RUN_EVIDENCE_AUDIT.bat 또는 아래 명령을 실행한다.
6. 최종 회의 직전 RUN_FINAL_EVIDENCE_GATE.bat와 RunCommercialLaunchGate.ps1 -RequireLaunchReady를 실행한다.

## 검증 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewBriefs.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1 -RequireComplete
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady
```

## 보안

- OpenAI, Steam, GitHub, 운영 계정의 비밀키나 비밀번호를 문서나 증거 폴더에 넣지 않는다.
- Steam Guard 코드, 결제 정보, 개인 계정 보안 질문을 캡처하지 않는다.
- 참가자 실명, 연락처, 학교/직장 식별 정보는 동의 없이 남기지 않는다.
