# SNU Avatar Chat Prototype

`겉!=속`은 2026년 봄학기 특수아동의 이해 3조 프로젝트를 위해 만든 인터뷰 기반 대화형 전시 프로토타입입니다. 관람객이 처음 보이는 겉 단서에서 출발해, 질문을 통해 대상자 1의 일상, 이동, 도움, 일과 공부, 독립, 취미를 더 입체적으로 이해하도록 설계했습니다.

이 저장소는 Unity 앱과 로컬 AI 프록시 서버를 함께 보관합니다. 빌드 산출물과 Unity 캐시는 제외하고, 소스와 에셋 중심으로 백업했습니다.

## 현재 상태

- Unity 대화 앱: `Interviewee1UnityAvatarChat`
- 로컬 서버: `Interviewee1CloneAI`
- 주요 흐름: 자기소개, 첫인상 선택, 카테고리별 5문답, 다음 카테고리/마무리 선택
- 추천질문: 채팅창 위 3개 카드와 오른쪽 질문 노트에 표시
- 답변 방식: 서버/API 답변과 Unity 내장 로컬 답변을 함께 사용
- 검증: Unity 배치 빌드와 스모크 테스트로 주요 UI 상태 확인

## 실행

Windows에서 프로젝트 루트 기준으로 실행합니다.

```powershell
.\Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat
```

또는 점검만 먼저 실행합니다.

```powershell
.\Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1 -CheckOnly -NoStartServer
```

`LaunchAvatarChat.ps1`는 로컬 서버 상태, Node 런타임, API 환경 변수를 확인한 뒤 Unity 앱을 실행합니다.

## 서버 실행

Unity 앱은 기본적으로 `http://127.0.0.1:8765`의 서버와 통신합니다.

```powershell
cd .\Interviewee1CloneAI
npm start
```

API 키가 없으면 텍스트 답변은 앱/서버의 로컬 근거 답변으로 제한됩니다. 마이크 전사와 OpenAI 음성 합성은 `OPENAI_API_KEY`가 있을 때만 사용할 수 있습니다.

```powershell
$env:OPENAI_API_KEY="<your key>"
$env:OPENAI_CHAT_MODEL="gpt-5.4-mini"
```

## Unity 빌드

Unity 6000.4.5f1 기준으로 빌드했습니다.

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.4.5f1\Editor\Unity.exe" `
  -batchmode -quit `
  -projectPath ".\Interviewee1UnityAvatarChat" `
  -executeMethod AvatarChatBuildTools.BuildWindows `
  -logFile ".\Interviewee1UnityAvatarChat\Build\unity-build.log"
```

빌드 결과물은 `Interviewee1UnityAvatarChat\Build`에 생성되지만, 이 저장소에서는 추적하지 않습니다.

## 폴더 구조

```text
.
├─ Interviewee1UnityAvatarChat/
│  ├─ Assets/              Unity 씬, 스크립트, 아바타/배경/일러스트 리소스
│  ├─ Packages/            Unity 패키지 매니페스트
│  ├─ ProjectSettings/     Unity 프로젝트 설정
│  ├─ Docs/                QA, 릴리즈, 플레이테스트, 문구 검토 문서
│  ├─ Marketing/           발표/상점/스크린샷/트레일러 관련 산출물
│  ├─ Tools/               빌드, 검증, 패키징용 PowerShell 도구
│  └─ LaunchAvatarChat.ps1 실행 전 점검 및 앱 실행 스크립트
├─ Interviewee1CloneAI/
│  ├─ server.js            OpenAI 프록시, 로컬 답변, 추천질문 생성/필터
│  ├─ data/persona.json    인터뷰 근거와 응답 규칙
│  ├─ app.js               브라우저 버전 인터랙션 코드
│  └─ index.html           브라우저용 전시 화면
└─ .gitignore              Unity 캐시/빌드/로그/백업 제외 규칙
```

## 최근 반영된 흐름

- 이어하기 비활성화 및 새 세션 중심 흐름 정리
- 긴 답변 페이지 분할
- 카테고리별 5문답 후 결과 카드 표시
- 결과 카드에서 다음 카테고리 진행 또는 종료 선택
- 추천질문은 활성 카테고리 안에서만 표시
- 채팅창 위 추천질문 3개와 오른쪽 질문 노트 동시 표시
- “자료에 없음”, “확인된 이야기”, “새로 단정” 같은 내부 설명 말투 제거
- 추천질문에 내부 메타 문구가 들어오지 않도록 서버와 Unity 양쪽에서 필터링
- 일러스트 5장 연결 준비

## AI 사용 방식

이 프로젝트는 AI를 무제한 자유 대화로 쓰지 않습니다.

- 직접 질문은 서버의 `/api/chat`을 통해 답변을 생성할 수 있습니다.
- 중요한 카테고리 추천질문은 Unity의 질문은행을 우선합니다.
- 서버가 추천질문을 주더라도 개인정보, 병명, 회사명, 내부 프롬프트/API 문구, “자료 부족” 류 표현은 필터링합니다.
- 서버/API가 준비되지 않아도 Unity 내장 로컬 답변으로 텍스트 대화 흐름을 유지합니다.

## Git 백업 정책

추적하는 것:

- Unity `Assets`, `Packages`, `ProjectSettings`
- 로컬 서버 소스와 persona 데이터
- 발표/QA/운영 문서
- 필요한 이미지, 폰트, 일러스트 에셋

추적하지 않는 것:

- Unity `Library`, `Build`, `Logs`, `Temp`, `UserSettings`
- 서버 `artifacts`, `node_modules`, `.env`, 로그 파일
- 로컬 zip 백업 폴더 `_recovery_backups`

이 저장소의 첫 백업 커밋은 `Backup avatar chat prototype`입니다.

## 발표 전 빠른 점검

1. 로컬 서버가 켜지는지 확인합니다.
2. Unity 앱이 시작 화면에서 정상 실행되는지 확인합니다.
3. 첫 자기소개 후 첫인상 선택을 진행합니다.
4. 오른쪽 질문 노트와 채팅창 위 추천질문 3개가 함께 보이는지 확인합니다.
5. 한 카테고리에서 5개 질문 후 결과 카드가 뜨는지 확인합니다.
6. 다음 카테고리로 넘어가기와 종료 선택을 둘 다 확인합니다.

## 참고 문서

- Unity 앱 상세 설명: `Interviewee1UnityAvatarChat/README.md`
- 서버 상세 설명: `Interviewee1CloneAI/README.md`
- 팀 데모 체크리스트: `Interviewee1UnityAvatarChat/TEAM_DEMO_CHECKLIST_20260605.md`
- 추천질문 정리: `Interviewee1UnityAvatarChat/Docs/RECOMMENDED_QUESTIONS.md`
