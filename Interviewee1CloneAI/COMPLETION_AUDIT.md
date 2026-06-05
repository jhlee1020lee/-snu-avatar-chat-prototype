# 완료 감사

## 요구사항별 확인

| 요구사항 | 현재 증거 | 판정 |
| --- | --- | --- |
| 기존 게임을 건드리지 말 것 | `99_GroupProject/Interviewee1Chatbot` 파일들의 수정 시각이 2026-05-19로 유지됨. 새 작업은 `99_GroupProject/Interviewee1CloneAI`에 분리됨 | 충족 |
| 폴더 자료를 살펴볼 것 | `MATERIAL_REVIEW_AUDIT.md`에 전체 폴더 856개 파일의 범주별 검토 범위와 직접/간접 반영 자료를 기록 | 충족 |
| 3조 인터뷰대상자1 지체장애인 페르소나 | `data/persona.json`에 대상자1의 목발, 자취방, 출근, 직장, 접근성, 도움, 자기이해, 취미, 평범함, 끈기 카드 구성 | 충족 |
| 실제 인터뷰 근거 반영 | `06_stt_correction/05_exports/2026-05-01__stt_final.md`, `2026-05-01_part1__stt_final.md`를 직접 근거로 추가. `EVIDENCE_NOTES.md`에 반영 내역 기록 | 충족 |
| 버튜버처럼 가상의 캐릭터 | `index.html`, `styles.css`에 아바타, 목발, 휠체어 바퀴, 책상/노트북 시각 요소와 듣는 중/생각 중/말하는 중 상태 애니메이션 구현 | 충족 |
| 채팅 가능 | `app.js`의 채팅 UI와 `/api/chat` 연결. 실제 요청으로 “직장에서 도움 요청은 편한 편인가요?” 응답 확인 | 충족 |
| 마이크 입력 가능 | `app.js`의 MediaRecorder 녹음과 `/api/transcribe` 연결. 합성 음성 파일을 전사해 `마이크 입력 확인입니다.` 결과 확인 | 충족 |
| ChatGPT/OpenAI API 연결 | `server.js`가 브라우저 API 키 노출 없이 Responses API, transcription API, speech API를 프록시함. `/api/config`, `/api/chat`, `/api/speech`, `/api/transcribe` 검증 | 충족 |
| 안전한 클론 AI 경계 | 앱 고지와 프롬프트 규칙에 “실제 대상자가 아닌 인터뷰 기반 가상 사람책” 명시, 개인정보/확인되지 않은 사실 생성 금지 | 충족 |
| 실행 가능성 | `npm run check` 통과. 서버가 `http://127.0.0.1:8765`에서 실행 중. 데스크톱/모바일 Playwright 스크린샷으로 첫 화면 확인 | 충족 |

## 검증 명령 요약

- `node -e "JSON.parse(require('fs').readFileSync('data/persona.json','utf8'))"`
- `npm run check`
- `Invoke-WebRequest http://127.0.0.1:8765/api/config`
- `Invoke-RestMethod http://127.0.0.1:8765/api/chat`
- `Invoke-WebRequest http://127.0.0.1:8765/api/speech`
- `Invoke-RestMethod http://127.0.0.1:8765/api/transcribe`
- `npx playwright screenshot --viewport-size=1440,900 http://127.0.0.1:8765`
- `npx playwright screenshot --viewport-size=390,844 http://127.0.0.1:8765`

## 남은 주의점

- 실제 전시장 컴퓨터에서는 `OPENAI_API_KEY` 환경 변수가 필요하다.
- 마이크 권한은 브라우저에서 허용해야 한다.
- 현재 모델은 환경 변수 `OPENAI_MODEL` 값이 우선 적용된다. 이 컴퓨터에서는 `gpt-5.2`로 실행 중이다.
