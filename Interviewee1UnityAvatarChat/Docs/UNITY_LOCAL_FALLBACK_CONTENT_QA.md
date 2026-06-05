# Unity 내장 답변 콘텐츠 QA

- 상태: 실패
- 실패: 1
- 검사 대상: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Assets\Scripts\AvatarChatApp.cs

| 항목 | 상태 | 근거 |
| --- | --- | --- |
| 날씨/비 근접 질문 | 통과 | 비, 날씨, 바닥 질문을 이동과 목발 동선으로 연결 |
| 휴식/주말 근접 질문 | 통과 | 쉬는 날과 휴식 질문을 확인된 취미와 자취방/생활 장면으로 연결 |
| 물건/전시 구성 질문 | 실패 | Missing source pattern: 전시에서 확인된 물건[\s\S]*목발[\s\S]*책상[\s\S]*노트북 |
| 감정/민폐 질문 | 통과 | 불안, 민폐, 힘듦 질문을 조건 조율과 자기 생활로 연결 |
| 관계/설명 질문 | 통과 | 친구/관계 질문을 도움 방식과 설명 권한으로 연결 |
| 테마 분류 보강: 취미 | 통과 | 쉬는 날과 휴식 질문이 취미 테마로 분류됨 |
| 테마 분류 보강: 도움 | 통과 | 관계와 설명 질문이 도움 테마로 분류됨 |
| 테마 분류 보강: 이동 | 통과 | 날씨와 바닥 질문이 이동 테마로 분류됨 |
