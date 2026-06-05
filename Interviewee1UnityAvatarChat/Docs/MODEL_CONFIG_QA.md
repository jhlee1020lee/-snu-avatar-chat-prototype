# 모델 설정 QA

- 생성 시각: 2026-06-03 01:18:28 +09:00
- 서버: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1CloneAI

이 문서는 전시 운영 채팅 모델을 gpt-5.4-mini로 고정하고, 짧은 모델명 정규화와 잘못된 모델명 처리 정책을 검증한다.
실제 API 계정에서 gpt-5.4-mini 호출이 실패하면 /api/config에 오류가 표시되고, 텍스트 대화는 로컬 근거 답변으로 이어져야 한다.

| 케이스 | 상태 | 근거 |
| --- | --- | --- |
| 기본 모델 | 통과 | chatModel=gpt-5.4-mini, source=fixed |
| 구버전 환경 변수 무시 | 통과 | chatModel=gpt-5.4-mini, source=fixed |
| 짧은 모델명 5.4 호환 정규화 | 통과 | chatModel=gpt-5.4-mini, source=OPENAI_CHAT_MODEL |
| 5.5 mini 별칭 5.4 정규화 | 통과 | chatModel=gpt-5.4-mini, source=OPENAI_CHAT_MODEL |
| 잘못된 모델명 기본값 전환 | 통과 | chatModel=gpt-5.4-mini, source=fixed |
