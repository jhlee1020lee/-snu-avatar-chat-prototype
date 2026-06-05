# 제품 브랜딩 QA

- 생성 시각: 2026-06-03 01:18:35 +09:00
- 기준 제목: 겉!=속
- 기준 슬러그: GeotNotEqualSok
- 통과: 6
- 실패: 1

| 영역 | 항목 | 상태 | 근거 |
| --- | --- | --- | --- |
| 게임 코드 | Unity GameTitle | 통과 | AvatarChatApp.cs GameTitle = 겉!=속 |
| 게임 코드 | Unity productName | 통과 | ProjectSettings productName = 겉!=속 |
| 빌드 | 빌드 메타데이터 제목 | 통과 | WriteBuildMetadata.ps1 displayName = 겉!=속 |
| 서버 | persona 제목 | 통과 | persona.json appTitle/displayName = 겉!=속 |
| 상점 자산 | Steam 자산 제목 | 통과 | Steam 자산 생성 제목 = 겉!=속 |
| 패키지 | 패키지 슬러그 | 통과 | Release package slug = GeotNotEqualSok |
| 브랜딩 금지어 | 구 표기 제거 | 실패 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\RELEASE_SMOKE_EVIDENCE_QA.md: 겉=속!; C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\RELEASE_SMOKE_EVIDENCE_QA.md: 겉=속 |
