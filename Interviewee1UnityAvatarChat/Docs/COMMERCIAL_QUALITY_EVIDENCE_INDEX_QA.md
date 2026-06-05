# 상업 품질 증거 인덱스 QA

- 생성 시각: 2026-06-03 01:18:03 +09:00
- 상태: 완료
- 인덱스: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleaseEvidence\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv
- 행: 16
- 확인된 증거 경로: 16
- 외부 확인 필요 행: 14
- 문제: 0
- 비밀정보 패턴: 0

이 QA는 품질 점수표 작성을 돕는 증거 인덱스의 형식과 로컬 경로만 확인한다. 외부 리뷰어가 직접 채운 COMMERCIAL_QUALITY_SCORECARD.tsv를 대체하지 않는다.

## 인덱스 행

| 영역 | 증거 유형 | 경로 | 외부 확인 | 백로그 | 종료 조건 |
| --- | --- | --- | --- | --- | --- |
| core_loop | runtime_qa | Docs/ACCESSIBILITY_AUTOMATION_QA.md | yes | INT-PLAYTEST-001 | PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 5/5, P0 0, P1 0 |
| core_loop | screenshot | Marketing/Screenshots/06-closing-card.png | yes | INT-PLAYTEST-001 | PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 5/5, P0 0, P1 0 |
| writing | content_qa | Docs/UNITY_LOCAL_FALLBACK_CONTENT_QA.md | yes | INT-QUALITY-001 | COMMERCIAL_QUALITY_SCORECARD.tsv writing 점수 4 이상, reviewer/evidence 채움 |
| writing | content_qa | Docs/GENERATED_MEMORY_POLICY_QA.md | yes | INT-QUALITY-001 | COMMERCIAL_QUALITY_SCORECARD.tsv writing/trust_privacy 점수 4 이상 |
| readability | accessibility_qa | Docs/ACCESSIBILITY_AUTOMATION_QA.md | yes | INT-ACCESS-001 | ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록 |
| readability | screenshot | Marketing/Screenshots/04-dialogue-scroll.png | yes | INT-ACCESS-001 | ACCESSIBILITY_OBSERVATION_FORM.md 읽기 난이도 통과 |
| controls | accessibility_qa | Docs/ACCESSIBILITY_AUTOMATION_QA.md | yes | INT-ACCESS-001 | ACCESSIBILITY_OBSERVATION_FORM.md 키보드/입력 장치 항목 통과 |
| controls | screenshot | Marketing/Screenshots/08-record-delete.png | yes | INT-PLAYTEST-001 | 외부 피드백에 기록 저장/삭제 P0/P1 없음 |
| trust_privacy | safety_qa | Docs/STEAM_LEGAL_READINESS_QA.md | yes | INT-LEGAL-001 | Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록 |
| trust_privacy | screenshot | Marketing/Screenshots/10-data-policy-delete.png | yes | INT-LEGAL-001 | PRIVACY_NOTICE_FINAL.md와 데이터 삭제 화면 증거 등록 |
| art_presentation | visual_qa | Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv | yes | INT-ART-001 | ART_REVIEW_FORM.md와 이미지/PDF 근거 등록 |
| art_presentation | steam_asset | Marketing/SteamAssets/small_capsule_462x174.png | yes | INT-ART-001 | 작은 캡슐 판독성, 잘림, 첫인상 외부 리뷰 통과 |
| trailer_store | trailer | Marketing/Trailer/trailer_animatic_60s.mp4 | yes | INT-TRAILER-001 | TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록 |
| trailer_store | store_copy | Marketing/StoreCopy/STORE_COPY_QA_REPORT.tsv | yes | INT-TRAILER-001 | 외부 리뷰 10초 이해도와 상점 기대치 통과 |
| stability_package | package_qa | Docs/RELEASE_READINESS_REPORT.md | no | INT-QUALITY-001 | 자동 실패 0, 보류 0, 공식 품질 점수표 완료 |
| stability_package | package_qa | Docs/UNITY_BUILD_SYNC_QA.md | no | INT-QUALITY-001 | 코드 변경 후 빌드 동기화 통과 |
