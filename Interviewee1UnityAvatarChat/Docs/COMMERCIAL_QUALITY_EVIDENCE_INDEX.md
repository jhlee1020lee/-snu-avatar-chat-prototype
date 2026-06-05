# 상업 품질 증거 인덱스

- 생성 시각: 2026-06-03 01:18:03 +09:00
- 인덱스 TSV: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv
- 품질 영역: 8
- 증거 행: 16
- 외부 확인 필요 행: 14

이 인덱스는 공식 점수표를 대신하지 않는다. 외부 리뷰어가 COMMERCIAL_QUALITY_SCORECARD.tsv의 evidence 칸을 채울 때 기존 자동 QA, 스모크 캡처, 상점 자료를 빠르게 찾고 P1 백로그 종료 조건과 연결하기 위한 보조 자료다.

| 영역 | 증거 유형 | 경로 | 리뷰 용도 | 외부 확인 | 백로그 | 종료 조건 |
| --- | --- | --- | --- | --- | --- | --- |
| core_loop | runtime_qa | Docs/ACCESSIBILITY_AUTOMATION_QA.md | 5문답 완료, 마무리 카드, 기록 저장 플로우 런타임 QA를 확인 | yes | INT-PLAYTEST-001 | PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 5/5, P0 0, P1 0 |
| core_loop | screenshot | Marketing/Screenshots/06-closing-card.png | 마무리 카드가 실제 세션 종료 화면으로 보이는지 확인 | yes | INT-PLAYTEST-001 | PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 5/5, P0 0, P1 0 |
| writing | content_qa | Docs/UNITY_LOCAL_FALLBACK_CONTENT_QA.md | 서버 없이도 내장 답변이 근거 기반으로 나오는지 확인 | yes | INT-QUALITY-001 | COMMERCIAL_QUALITY_SCORECARD.tsv writing 점수 4 이상, reviewer/evidence 채움 |
| writing | content_qa | Docs/GENERATED_MEMORY_POLICY_QA.md | 생성 기억과 답변 정책이 과장 없이 유지되는지 확인 | yes | INT-QUALITY-001 | COMMERCIAL_QUALITY_SCORECARD.tsv writing/trust_privacy 점수 4 이상 |
| readability | accessibility_qa | Docs/ACCESSIBILITY_AUTOMATION_QA.md | 긴 답변, 큰 글자, 스크롤, 단축키 접근성 자동 검증 확인 | yes | INT-ACCESS-001 | ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록 |
| readability | screenshot | Marketing/Screenshots/04-dialogue-scroll.png | 긴 답변이 대사창 안에서 읽히고 스크롤 단서가 보이는지 확인 | yes | INT-ACCESS-001 | ACCESSIBILITY_OBSERVATION_FORM.md 읽기 난이도 통과 |
| controls | accessibility_qa | Docs/ACCESSIBILITY_AUTOMATION_QA.md | 키보드, 게임패드, 패널 충돌 방지, 기록 삭제 확인 흐름 확인 | yes | INT-ACCESS-001 | ACCESSIBILITY_OBSERVATION_FORM.md 키보드/입력 장치 항목 통과 |
| controls | screenshot | Marketing/Screenshots/08-record-delete.png | 기록함 삭제 확인 화면과 파괴적 조작 확인 흐름 검토 | yes | INT-PLAYTEST-001 | 외부 피드백에 기록 저장/삭제 P0/P1 없음 |
| trust_privacy | safety_qa | Docs/STEAM_LEGAL_READINESS_QA.md | 개인정보, Steam/법무 자동 점검과 보안 문구 확인 | yes | INT-LEGAL-001 | Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록 |
| trust_privacy | screenshot | Marketing/Screenshots/10-data-policy-delete.png | 저장 데이터 삭제 확인이 플레이어에게 명확히 보이는지 확인 | yes | INT-LEGAL-001 | PRIVACY_NOTICE_FINAL.md와 데이터 삭제 화면 증거 등록 |
| art_presentation | visual_qa | Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv | 스크린샷과 Steam 자산의 밝기, 어두움, 보라색 잔상, 가장자리 복잡도 확인 | yes | INT-ART-001 | ART_REVIEW_FORM.md와 이미지/PDF 근거 등록 |
| art_presentation | steam_asset | Marketing/SteamAssets/small_capsule_462x174.png | 작은 Steam 캡슐에서 제목과 분위기가 읽히는지 확인 | yes | INT-ART-001 | 작은 캡슐 판독성, 잘림, 첫인상 외부 리뷰 통과 |
| trailer_store | trailer | Marketing/Trailer/trailer_animatic_60s.mp4 | 상점 트레일러 후보가 플레이 흐름을 설명하는지 확인 | yes | INT-TRAILER-001 | TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록 |
| trailer_store | store_copy | Marketing/StoreCopy/STORE_COPY_QA_REPORT.tsv | 상점 문구가 실제 플레이와 개인정보 안내를 과장 없이 설명하는지 확인 | yes | INT-TRAILER-001 | 외부 리뷰 10초 이해도와 상점 기대치 통과 |
| stability_package | package_qa | Docs/RELEASE_READINESS_REPORT.md | 자동 QA, 패키지, Steam 제출/스테이징 상태를 한눈에 확인 | no | INT-QUALITY-001 | 자동 실패 0, 보류 0, 공식 품질 점수표 완료 |
| stability_package | package_qa | Docs/UNITY_BUILD_SYNC_QA.md | 현재 소스와 Unity 빌드 산출물 동기화 확인 | no | INT-QUALITY-001 | 코드 변경 후 빌드 동기화 통과 |

## 검증 명령

```powershell
.\Tools\ValidateCommercialQualityEvidenceIndex.ps1
```
