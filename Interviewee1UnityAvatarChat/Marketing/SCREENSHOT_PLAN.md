# 스크린샷 촬영 계획

상점 페이지용 스크린샷은 기능 설명보다 플레이어가 실제로 보게 될 흐름을 보여주는 순서로 배치한다.

최신 세트는 `Tools/PromoteSteamScreenshots.ps1`로 `Build/release-smoke`의 검증 캡처를 승격해 만든다. 승격 결과와 원본 파일, SHA-256 해시는 `Screenshots/SCREENSHOT_MANIFEST.tsv`에 남긴다.

## 현재 확보한 컷

| 파일 | 역할 | 상태 |
| --- | --- | --- |
| `Screenshots/01-title-session-start.png` | 첫 화면, 세션 구조, 주요 버튼 | 사용 가능 |
| `Screenshots/02-question-phone.png` | 여섯 장면 진행 구조 | 사용 가능 |
| `Screenshots/03-hotspot-preview.png` | 사물 단서와 질문 확인 흐름 | 사용 가능 |
| `Screenshots/04-dialogue-scroll.png` | 긴 답변과 대사창 안정성 | 사용 가능 |
| `Screenshots/05-memory-complete.png` | 기억장 완성과 수집 보상 | 사용 가능 |
| `Screenshots/06-closing-card.png` | 마무리 문장 선택 | 사용 가능 |
| `Screenshots/07-record-archive.png` | 저장 기록 재방문 가치 | 사용 가능 |
| `Screenshots/08-record-delete.png` | 기록 관리와 개인정보 신뢰 | 사용 가능 |
| `Screenshots/09-accessibility-settings.png` | 글자 크기, 소리, 화면 모드, 움직임 줄임 | 사용 가능 |
| `Screenshots/10-data-policy-delete.png` | 저장 데이터 위치와 삭제 신뢰 | 사용 가능 |
| `Screenshots/11-title-continue.png` | 저장된 세션과 이어하기 신뢰 | 사용 가능 |
| `Screenshots/SCREENSHOT_MANIFEST.tsv` | 최신 스모크 캡처 승격 근거 | 사용 가능 |
| `SteamAssets/professional_keyart_1920x1080.png` | 캡슐 우선 키아트 소스 | 사용 가능 |
| `SteamAssets/source_keyart_1920x1080.png` | UI 없는 키아트 소스 | 사용 가능 |

## 추가 촬영 컷

| 우선순위 | 장면 | 목적 |
| --- | --- | --- |
| 1 | 실제 플레이어 세션 기반 추가 컷 | 상점 최종 업로드 전에 외부 플레이테스트 장면으로 교체할 후보를 확보한다. |

## 캡션 원칙

- 설명이 아니라 플레이어 행동을 말한다.
- “AI”, “기능”, “시스템” 같은 개발자 중심 단어를 줄인다.
- 실제 게임 화면에서 확인 가능한 내용만 쓴다.

## 컷 순서

1. 시작 화면
2. 질문폰
3. 사물 단서 질문 확인
4. 대화 장면
5. 기억장
6. 마무리 카드
7. 기록함
8. 기록 삭제
9. 설정
10. 저장 데이터 안내
11. 이어하기가 있는 타이틀
