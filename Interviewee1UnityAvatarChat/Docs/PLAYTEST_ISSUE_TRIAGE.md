# 플레이테스트 이슈 분류 기준

외부 테스트 후 관찰 메모, 지원 번들, 스크린샷, 녹화를 한 이슈 목록으로 정리하기 위한 기준이다.

## 이슈 등급

| 등급 | 의미 | 예시 | 출시 판단 |
| --- | --- | --- | --- |
| P0 | 출시 차단 | 실행 불가, 저장 삭제 불가, 비밀정보 노출 위험 | 해결 전 출시 불가 |
| P1 | 핵심 루프 차단 | 질문 후 응답 없음, 긴 답변을 읽을 수 없음, 5문답 완료 불가 | 해결 전 유료 판매 불가 |
| P2 | 상업 품질 저하 | 말투가 반복적임, 기록함 의미가 약함, 상점 설명과 체감이 다름 | 출시 전 우선 수정 |
| P3 | 다듬기 | 문구 어색함, 버튼 라벨 개선, 작은 시각 조정 | 일정에 따라 반영 |

## 이슈 작성 규칙

- 제목은 `등급 / 화면 / 문제` 형식으로 쓴다.
- 빌드 ID와 지원 번들 경로를 반드시 기록한다.
- 재현 단계는 5단계 이하로 적는다.
- 실제 결과와 기대 결과를 분리한다.
- 감상 의견은 그대로 보존하되, 수정 작업은 재현 가능한 행동 단위로 쪼갠다.

## 출시 후보 판정

- P0이 하나라도 있으면 출시 후보가 아니다.
- P1이 하나라도 있으면 5달러 이상 판매 후보가 아니다.
- 같은 P2가 참가자 2명 이상에게 반복되면 우선 수정 대상으로 본다.
- 접근성 관련 P2는 일반 문구 P2보다 우선한다.
- 모든 수정 후 같은 프로토콜로 회귀 테스트를 진행한다.
- 외부 이슈는 `Tools/RegisterExternalIssue.ps1`로 `Build/ReleaseEvidence/EXTERNAL_ISSUE_REGISTER.tsv`에 등록한다.
- P0/P1은 수정 후 `verified` 상태와 검증 증거가 있어야 닫힌 것으로 본다.
- `ValidateExternalIssueRegister.ps1 -RequireClosed`가 통과해야 최종 유료 출시 후보로 본다.

예시:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RegisterExternalIssue.ps1 -IssueId "EXT-001" -Priority "P2" -Area "문구" -Source "session-01" -SessionId "session-01" -Title "답변 첫머리가 반복적으로 느껴짐" -ReproSteps "5문답을 진행하고 답변 첫 문장을 비교한다" -Expected "각 답변이 자연스럽게 시작된다" -Actual "두 참가자가 반복적인 접수 표현을 지적했다"
```

## 필수 증거

- `BUILD_INFO.txt`의 Build ID
- `CollectSupportBundle.ps1` 결과 폴더
- 관찰 기록 양식
- 문제가 발생한 화면 스크린샷 또는 녹화
- 참가자가 남긴 원문 피드백

