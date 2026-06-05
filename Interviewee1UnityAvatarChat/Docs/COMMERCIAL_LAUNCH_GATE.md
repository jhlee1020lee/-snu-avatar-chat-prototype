# 상업 출시 최종 게이트

- 생성 시각: 2026-06-02 19:08:13 +09:00
- 기준 가격: USD 5 이상
- 최종 판정: 보류
- 통과 게이트: 2
- 보류 게이트: 7
- 차단 게이트: 0
- Steam 상점 제출 자료: 준비됨
- 5달러 이상 최종 출시 후보: 보류

## 결정

Steam 상점 제출 자료는 준비됐지만, 외부 증거가 부족해 최종 유료 출시는 보류한다.

## 게이트

| 영역 | 게이트 | 상태 | 근거 | 다음 조치 |
| --- | --- | --- | --- | --- |
| 자동 QA | 릴리즈 감사 | 통과 | 자동 실패 0, 보류 0, 외부 미완료 6 |  |
| 외부 증거 | 외부 증거 전체 | 보류 | 미완료 5 | Playtest, Accessibility, ArtReview, Trailer, LegalSteam 증거를 채운다. |
| 외부 플레이테스트 | 5명 이상 완성 세션 | 보류 | 완성 0/5 | 외부 참가자 5명 이상의 5문답 세션 증거를 수집한다. |
| 상업 품질 | 5달러 품질 루브릭 | 보류 | 상태 미완료, 평균 0, 문제 32, 차단 0 | 외부 리뷰 점수표를 채우고 평균 4.0 이상, 최저 3 이상, 차단 0을 만든다. |
| 외부 이슈 | 외부 이슈 폐쇄 | 보류 | 상태 증거 없음, 미해결 P2 0 | 외부 리뷰 이슈를 등록하고 P2 이상을 해결 또는 수용 위험으로 정리한다. |
| 외부 리뷰어 | 리뷰어 배정 | 보류 | 준비 0/11 | EXTERNAL_REVIEWER_ROSTER.tsv에 reviewer_alias, contact_method, due_at을 채우고 ApplyExternalReviewerRoster.ps1를 실행한다. |
| 시장 비교 | Steam 유사작 가격/태그/리뷰 톤 | 통과 | 상태 완료, 비교작 8, 차단 0, 보류 0 |  |
| 가격 포지셔닝 | 5달러 이상 가격 근거 | 보류 | 상태 보류, 보류 3, 차단 0 | 외부 증거, 공식 품질 점수표, 최신 Steam 유사작 가격 비교를 채운다. |
| 상업 판정 | 상업 출시 결정 | 보류 | Steam 제출 준비, 최종 출시 후보 보류 | 외부 증거와 외부 이슈 폐쇄 게이트를 통과시킨다. |

## 남은 조치

- 외부 증거: Playtest, Accessibility, ArtReview, Trailer, LegalSteam 증거를 채운다.
- 외부 플레이테스트: 외부 참가자 5명 이상의 5문답 세션 증거를 수집한다.
- 상업 품질: 외부 리뷰 점수표를 채우고 평균 4.0 이상, 최저 3 이상, 차단 0을 만든다.
- 외부 이슈: 외부 리뷰 이슈를 등록하고 P2 이상을 해결 또는 수용 위험으로 정리한다.
- 외부 리뷰어: EXTERNAL_REVIEWER_ROSTER.tsv에 reviewer_alias, contact_method, due_at을 채우고 ApplyExternalReviewerRoster.ps1를 실행한다.
- 가격 포지셔닝: 외부 증거, 공식 품질 점수표, 최신 Steam 유사작 가격 비교를 채운다.
- 상업 판정: 외부 증거와 외부 이슈 폐쇄 게이트를 통과시킨다.

## 검증 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\RunCommercialLaunchGate.ps1 -RequireLaunchReady
```
