# 릴리즈 스모크 창 실행 정책 QA

- 생성 시각: 2026-06-03 01:18:35 +09:00
- 실패: 0
- 통과: 15

이 검증은 릴리즈 스모크가 작업 중 실수로 Unity 창을 반복 실행하지 않도록, 전체 스모크에는 명시적 -AllowUnityWindows가 필요하고 창 없는 검증에는 -StaticOnly가 제공되는지 확인한다.

| 영역 | 항목 | 상태 | 근거 |
| --- | --- | --- | --- |
| 스크립트 | 창 실행 명시 옵션 | 통과 | AllowUnityWindows switch 확인 |
| 스크립트 | 창 없는 정적 검증 옵션 | 통과 | StaticOnly switch 확인 |
| 스크립트 | 기본 실행 즉시 차단 | 통과 | 기본 실행은 Unity 창 실행 전에 중단 |
| 스크립트 | 플레이어 실행 함수 가드 | 통과 | Unity player 실행 함수 내부 가드 확인 |
| 스크립트 | StaticOnly 조기 종료 | 통과 | 정적 검증 후 Unity build/capture 전에 종료 |
| 스크립트 | 긍정 피드백 마무리 기록 스모크 | 통과 | 마무리 기록 없는 긍정 피드백 저장 차단 스모크 확인 |
| 문서 | README.md 전체 스모크 명령 | 통과 | 전체 스모크는 AllowUnityWindows를 명시 |
| 문서 | README.md 정적 스모크 명령 | 통과 | 창 없는 정적 스모크 명령 확인 |
| 문서 | README.md 안전 실행 명령 | 통과 | AllowUnityWindows 또는 StaticOnly 없는 RunReleaseSmoke 명령 없음 |
| 문서 | RELEASE_CHECKLIST.md 전체 스모크 명령 | 통과 | 전체 스모크는 AllowUnityWindows를 명시 |
| 문서 | RELEASE_CHECKLIST.md 정적 스모크 명령 | 통과 | 창 없는 정적 스모크 명령 확인 |
| 문서 | RELEASE_CHECKLIST.md 안전 실행 명령 | 통과 | AllowUnityWindows 또는 StaticOnly 없는 RunReleaseSmoke 명령 없음 |
| 문서 | TROUBLESHOOTING.md 전체 스모크 명령 | 통과 | 전체 스모크는 AllowUnityWindows를 명시 |
| 문서 | TROUBLESHOOTING.md 정적 스모크 명령 | 통과 | 창 없는 정적 스모크 명령 확인 |
| 문서 | TROUBLESHOOTING.md 안전 실행 명령 | 통과 | AllowUnityWindows 또는 StaticOnly 없는 RunReleaseSmoke 명령 없음 |
