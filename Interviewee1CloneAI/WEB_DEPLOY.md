# Web 배포 메모

이 프로젝트를 웹으로 배포할 때는 Unity를 WebGL로 빌드한 뒤, Node 서버가 WebGL 정적 파일과 `/api/*`를 같은 도메인에서 함께 제공합니다.

## 구조

```text
Interviewee1CloneAI/
  server.js
  package.json
  data/
  public/                    # Unity WebGL 빌드 결과
    index.html
    Build/
    TemplateData/
```

브라우저는 `https://배포주소/`를 열고, Unity WebGL은 같은 주소의 `/api/config`, `/api/chat`, `/api/transcribe`를 호출합니다. OpenAI API 키는 브라우저에 넣지 않고 서버 환경변수로만 둡니다.

## 로컬 WebGL 빌드

Unity가 설치된 컴퓨터에서 저장소 루트(`99_GroupProject`) 기준으로 실행합니다.

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.4.5f1\Editor\Unity.exe" -batchmode -quit -projectPath ".\Interviewee1UnityAvatarChat" -executeMethod AvatarChatBuildTools.BuildWebGL -logFile ".\Interviewee1UnityAvatarChat\Build\unity-build-webgl.log"
```

성공하면 `Interviewee1CloneAI/public`에 WebGL 파일이 생성됩니다.

## 로컬 웹 실행

```powershell
$env:OPENAI_API_KEY="sk-..."
node .\server.js
```

그 다음 브라우저에서 `http://127.0.0.1:8765`를 엽니다.

## 클라우드 배포

Render, Railway, Fly.io, Cloud Run 같은 Node 서버 호스팅에 `Interviewee1CloneAI` 폴더를 배포합니다.

필수 환경변수:

```text
OPENAI_API_KEY=sk-...
PORT=서비스가 지정하거나 자동 주입
```

선택 환경변수:

```text
HOST=0.0.0.0
OPENAI_CHAT_MODEL=gpt-5.4-mini
STATIC_ROOT=public
```

시작 명령:

```text
node server.js
```

주의: 일반적인 클라우드 빌드 서버에는 Unity Editor가 없으므로 `public/` WebGL 빌드는 배포 전에 로컬에서 만들어 포함해야 합니다.
