# 문제 해결 안내

이 문서는 플레이어와 운영자가 Windows 배포 패키지에서 자주 만날 수 있는 문제를 빠르게 확인하기 위한 안내다.

## 실행이 안 열릴 때

1. `Interviewee1UnityAvatarChat/RUN_AVATAR_CHAT.bat`을 실행한다.
2. 런처가 앱 파일, 포함된 NodeRuntime, 로컬 서버, API 환경 변수를 점검하는지 확인한다.
3. Windows 보안 경고가 뜨면 배포 출처를 확인한 뒤 실행을 허용한다.
4. 실행 파일을 직접 열었는데 서버 기능이 안 보이면 배치 파일로 다시 실행한다.
5. 그래도 열리지 않으면 `Build/Interviewee1UnityAvatarChat.exe`와 `Build/Interviewee1UnityAvatarChat_Data`가 같은 폴더에 있는지 확인한다.

점검만 실행하려면:

```powershell
.\Interviewee1UnityAvatarChat\LaunchAvatarChat.ps1 -CheckOnly -NoStartServer
```

문의용 지원 번들을 만들려면:

```powershell
.\Interviewee1UnityAvatarChat\CollectSupportBundle.ps1
```

지원 번들은 빌드 ID, 런처 점검 결과, 필수 파일 존재 여부, 서버/API 모드만 모은다. API 키 값, 환경 변수 전체, 저장된 마무리 기록은 수집하지 않는다.

## 텍스트 답변이 느리거나 API가 실패할 때

- API 키가 없거나 서버 호출이 실패해도 텍스트 대화는 앱 내장 근거 답변으로 이어진다.
- 설정에서 `로컬만`을 켜면 텍스트 질문을 서버로 보내지 않고 앱 내장 근거 답변만 사용한다.
- 앱 안에서는 설정의 `정보` 화면에서 로컬 서버 연결과 API 키 유무를 확인할 수 있다.
- 서버가 켜져 있어도 네트워크, 모델명, API 키 문제로 외부 호출이 실패할 수 있다.
- Windows 배포 패키지는 포함된 NodeRuntime으로 서버를 자동 시작한다.
- 런처 출력에 `Node.js runtime ready`가 보이지 않으면 패키지의 `NodeRuntime/node.exe`가 있는지 확인한다.
- 서버 환경 변수는 `OPENAI_CHAT_MODEL`, `OPENAI_TRANSCRIBE_MODEL`, `OPENAI_TTS_MODEL`, `OPENAI_TTS_VOICE`를 사용한다.
- 채팅 모델을 짧게 적으면 서버가 `gpt-...` 형식으로 정규화한다. 형식이 틀리면 기본 모델로 돌아간다.
- 실제 API에서 존재하지 않는 모델이면 텍스트 대화는 로컬 근거 답변으로 이어진다.
- API 키는 배포 패키지에 넣지 말고 실행 환경 변수로만 설정한다.

## 마이크 입력이 안 될 때

- 마이크 전사는 서버와 `OPENAI_API_KEY`가 있을 때만 동작한다.
- 설정에서 `로컬만`을 켜면 마이크 전사는 꺼진다.
- Windows 마이크 권한을 확인한다.
- 마이크가 없어도 직접 입력과 추천 질문은 계속 사용할 수 있다.
- 전사가 실패하면 같은 질문을 텍스트로 입력한다.

## 저장과 기록을 지우고 싶을 때

- 기록함에서 저장한 마무리 기록을 선택한 뒤 `선택 삭제`를 누른다.
- 모든 이어하기 데이터와 기록, 의견 메모를 지우려면 정보 화면에서 `저장 삭제`를 두 번 누른다.
- 마무리 기록과 의견 메모는 사용자 데이터 폴더에 텍스트 파일로 저장된다.

## 화면이나 글자가 불편할 때

- 설정에서 글자 크기를 조정한다.
- 설정에서 움직임 줄임을 켠다.
- `F` 키로 전체 화면을 전환할 수 있다.
- `+`와 `-` 키로 대사 글자 크기를 바꿀 수 있다.

## 키보드 조작

| 키 | 동작 |
| --- | --- |
| `1`, `2`, `3` | 기본 화면에서는 추천 질문 선택, 질문폰이 열려 있으면 탭 선택 |
| `←`, `→` | 질문폰 탭 이동 |
| `↑`, `↓` | 대사창 또는 기록함 조금 스크롤 |
| `PageUp`, `PageDown` | 대사창 또는 기록함 크게 스크롤 |
| `Home`, `End` | 대사창 또는 기록함 처음/끝으로 이동 |
| `Q` | 질문폰 |
| `M` | 기억장 |
| `R` | 기록함 |
| `S` | 설정 |
| `I` | 정보 |
| `F` | 전체 화면 |
| `+`, `-` | 대사 글자 크기 |
| `Esc` | 닫기 또는 일시정지 |

패널이 열린 상태에서는 열린 패널의 닫기 단축키가 우선한다. 다른 패널 단축키는 화면 뒤쪽에 새 창을 겹쳐 열지 않으며, 전체 화면과 글자 크기 조정은 계속 사용할 수 있다.

운영자 검증에서는 `Build/release-smoke/panel-shortcut-*.tsv` 파일로 이 동작을 확인한다. 보고서 안에 `FAIL`이 있으면 해당 패널 조합을 다시 확인한다.

## 게임패드 조작

게임패드가 연결된 경우 `A`는 시작/확정과 현재 추천 질문 진행, `B`는 닫기 또는 일시정지, `X`는 질문 노트, `Y`는 기억장, `Back`은 기록함, `Menu`는 설정을 연다. 기본 화면에서는 `LB`와 `RB`로 추천 질문을 바꾸고, 질문 노트가 열려 있을 때는 탭을 이동한다. 설정 화면에서는 `LB`와 `RB`로 글자 크기를 줄이거나 키운다.

운영자 검증에서는 `Build/release-smoke/gamepad-shortcut-*.tsv` 파일로 `A` 현재 추천 질문 진행, `RB` 추천 질문 선택, `X/Y/Back/Menu`, `B`, `RB` 탭 이동, 설정 화면 `RB` 글자 크기 조정 상태를 확인한다.

## 운영자 확인 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -AllowUnityWindows
```

이 명령은 Unity 플레이어 창을 여러 번 열어 캡처와 런타임 상태를 검증한다. 다른 작업 중에는 실행하지 말고, 창 실행이 괜찮을 때만 `-AllowUnityWindows`를 붙인다.

Unity 창 없이 서버/문구/안전/기존 상점 자료 검증만 확인하려면:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunReleaseSmoke.ps1 -StaticOnly
```

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateModelConfig.ps1
```

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateReleasePackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA
```

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ReleasePackages\GeotNotEqualSok-Windows-QA\Interviewee1UnityAvatarChat\CollectSupportBundle.ps1
```

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamSubmissionPackage.ps1 -PackageRoot .\99_GroupProject\Interviewee1UnityAvatarChat\Build\SteamSubmissionPackages\GeotNotEqualSok-SteamSubmission-QA
```

