# 전시 실행 문서

## 실행

PowerShell에서 이 폴더로 이동한 뒤 실행합니다.

```powershell
cd "C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1CloneAI"
$env:OPENAI_CHAT_MODEL="gpt-5.4-mini"
npm start
```

관람객 화면:

```text
http://127.0.0.1:8765
```

관리자 화면:

```text
http://127.0.0.1:8765?staff=1
```

## 종료

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -like '*server.js*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

## API 오류 확인

- 화면 상단이 `API 오류`로 표시되면 `OPENAI_API_KEY`와 `OPENAI_CHAT_MODEL`을 확인합니다.
- `gpt-5.4-mini` 호출이 실패하면 화면에 오류 메시지가 바로 뜹니다.
- API 키가 없으면 마이크 전사와 서버 음성 합성은 동작하지 않습니다.

## 생성 답변 관리

백업 위치:

```text
data/generated_memory.jsonl
```

정리본:

```text
data/generated_memory_review_20.md
```

상태 정책:

- `사용`: 다음 답변에 참고됩니다.
- `미확인`: 다음 답변에 낮은 우선순위로 참고됩니다.
- `수정 필요`: 관리자 화면에는 남지만 AI 참고 대상에서 제외됩니다.
- 삭제된 답변: 파일에서 제거되며 AI 참고 대상에서도 완전히 제외됩니다.

## 전시 당일 체크

1. 서버를 실행합니다.
2. 관람객 화면 `http://127.0.0.1:8765`를 열고 관리자 패널이 보이지 않는지 확인합니다.
3. 관리자 화면 `http://127.0.0.1:8765?staff=1`에서 확장 답변 패널이 보이는지 확인합니다.
4. 화면 상단 API 상태가 정상인지 확인합니다.
5. 추천 질문 하나를 눌러 답변 길이와 말투를 확인합니다.
6. 마이크를 쓸 경우 브라우저 권한을 허용하고 짧게 테스트합니다.
7. 문제가 생기면 `초기화`를 눌러 대화만 새로 시작합니다.
