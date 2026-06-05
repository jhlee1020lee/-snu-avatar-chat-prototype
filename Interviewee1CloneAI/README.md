# 겉!=속

기존 게임을 건드리지 않고 새로 만든 3조 인터뷰대상자1용 대화형 인터뷰 앱입니다. 채팅, 마이크 입력, 음성 답변, OpenAI API 프록시 서버를 포함합니다.

## 실행

1. PowerShell 또는 명령 프롬프트에서 이 폴더로 이동합니다.
2. `OPENAI_API_KEY`가 설정된 상태에서 실행합니다.
3. `npm start` 또는 `RUN_CLONE_AI.bat`을 실행합니다.
4. 브라우저에서 `http://127.0.0.1:8765`를 엽니다.

API 키가 없으면 텍스트 채팅은 근거 카드 기반 로컬 모드로 동작하지만, 마이크 전사와 OpenAI 음성 합성은 사용할 수 없습니다.

## 구성

- `index.html`: 전시용 화면 구조
- `styles.css`: 캐릭터, 책상, 목발, 채팅 UI
- `app.js`: 채팅, 녹음, 음성 재생, 아바타 상태
- `server.js`: OpenAI Responses API, 전사, 음성 합성 프록시
- `data/persona.json`: 인터뷰 근거, 응답 규칙, 추천 질문
- `data/generated_memory.jsonl`: 생성된 확장 답변 기록. 첫 확장 답변이 생길 때 자동 생성됩니다.
- `EXHIBITION_RUNBOOK.md`: 전시 당일 실행, 종료, 오류 대응, 운영 체크리스트
- `EVIDENCE_NOTES.md`: 직접 근거와 안전 경계 정리
- `MATERIAL_REVIEW_AUDIT.md`: 전체 폴더 자료 검토 범위 감사
- `COMPLETION_AUDIT.md`: 요구사항별 완료 여부와 검증 명령 기록

## 설계 메모

- 브라우저에 `OPENAI_API_KEY`를 넣지 않습니다.
- 실제 인터뷰 대상자 본인이 아니라는 고지를 앱 안에 유지합니다.
- 인터뷰에 없는 개인정보나 사적인 사실은 만들지 않도록 프롬프트에 제한을 걸었습니다.
- 근거 카드로 바로 답하기 어려운 질문은 대상자 1의 확인된 결에 맞춘 답변을 만들고, `data/generated_memory.jsonl`에 `unreviewed` 상태로 기록합니다.
- 기록된 확장 답변은 `사용`으로 검토된 항목만 다음 답변에서 낮은 우선순위의 일관성 메모로 사용합니다.
- 미확인 확장 답변을 운영 검토용으로 함께 넣어야 할 때만 `INCLUDE_UNREVIEWED_MEMORY_CONTEXT=true`를 명시합니다.
- 자동 QA나 리허설에서 운영 기록을 건드리지 않으려면 `GENERATED_MEMORY_PATH`로 임시 기록 파일을 지정할 수 있습니다.
- 앱의 `확장 답변` 패널에서 생성 답변을 수정하고 `사용`, `수정 필요`, `미확인` 상태로 정리하거나 삭제할 수 있습니다.
- 관람객 화면에서는 관리자 패널을 숨깁니다. 관리자 화면은 `http://127.0.0.1:8765?staff=1`로 엽니다.
- 기본 채팅 모델은 `OPENAI_CHAT_MODEL` 또는 `OPENAI_MODEL`로 바꿀 수 있고, 기본값은 `gpt-5.4-mini`입니다. `gpt-5.5-mini`처럼 현재 사용할 수 없는 mini 이름은 `gpt-5.4-mini`로 보정됩니다.
- Unity 패키지는 정보 화면의 `상태 확인`에서 `/api/config` 기준 로컬 서버와 API 키 상태를 보여줍니다. 서버나 API가 준비되지 않아도 텍스트 채팅은 앱 내장 근거 답변으로 이어지고, 마이크 전사와 API 음성 기능만 서버/API 키가 필요합니다.
- 기록 확인 API는 `http://127.0.0.1:8765/api/generated-memory`입니다.

## 환경 변수

```powershell
$env:OPENAI_API_KEY="<OPENAI_API_KEY>"
$env:OPENAI_CHAT_MODEL="gpt-5.4-mini"
$env:OPENAI_TRANSCRIBE_MODEL="gpt-4o-mini-transcribe"
$env:OPENAI_TTS_MODEL="gpt-4o-mini-tts"
$env:OPENAI_TTS_VOICE="cedar"
$env:INCLUDE_UNREVIEWED_MEMORY_CONTEXT="false"
$env:GENERATED_MEMORY_PATH="data/generated_memory.jsonl"
```

