# 5달러 이상 상업 품질 루브릭

`겉!=속`를 Steam에서 USD 5 이상으로 판매할 수 있는지 판단하기 위한 점수 기준이다. 이 루브릭은 자동 QA를 대체하지 않는다. 자동 QA가 통과한 뒤, 외부 플레이테스트와 상업 리뷰 결과를 같은 기준으로 비교하기 위한 회의 도구다.

## 점수 기준

| 점수 | 의미 |
| ---: | --- |
| 5 | 현재 가격대에서 강점으로 말할 수 있다 |
| 4 | 출시 가능한 수준이며 작은 보완만 필요하다 |
| 3 | 기능은 되지만 구매 설득력이나 완성도에 약점이 있다 |
| 2 | 유료 출시 전 수정이 필요하다 |
| 1 | 출시 후보로 볼 수 없다 |

## 필수 평가 영역

| 영역 | 질문 |
| --- | --- |
| core_loop | 5문답, 기억장, 마무리 카드가 하나의 완결된 세션으로 느껴지는가 |
| writing | 답변 말투가 AI 설명문처럼 보이지 않고 사람책 인터뷰 톤을 유지하는가 |
| readability | 긴 답변, 큰 글자, 스크롤, 자막과 UI 문구가 읽기 편한가 |
| controls | 키보드, 마우스, 설정, 기록 저장/삭제 흐름이 예측 가능한가 |
| trust_privacy | 로컬 저장, API 키, 마이크, 삭제 안내가 신뢰를 주는가 |
| art_presentation | 캐릭터, 배경, 캡슐, 스크린샷이 상점 첫인상에서 저가 프로토타입처럼 보이지 않는가 |
| trailer_store | 트레일러와 상점 문구가 실제 플레이를 정확하게 팔고 있는가 |
| stability_package | Windows 실행 패키지, Node 런타임, fallback, 지원 번들이 안정적으로 동작하는가 |

## 통과 기준

- 모든 필수 영역이 점수표에 있어야 한다.
- 평균 점수는 4.0 이상이어야 한다.
- 최저 점수는 3 이상이어야 한다.
- `blocker`가 true인 항목이 없어야 한다.
- 각 행에는 reviewer와 evidence가 있어야 한다.
- evidence는 `EvidenceDrop` 또는 `Build/ReleaseEvidence` 기준 상대 경로여야 하며 실제 파일이나 폴더가 있어야 한다.
- `COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv`, 점수표 초안, 템플릿, 리뷰 브리프, README, 체크리스트, 초대장, 매니페스트는 공식 evidence가 아니다.
- `stability_package`를 제외한 영역은 담당 외부 증거 폴더를 최소 하나 이상 참조해야 한다.
- P0/P1 외부 이슈가 남아 있으면 루브릭 점수와 무관하게 출시 후보가 아니다.

## 외부 증거 매핑

| 영역 | 반드시 포함해야 하는 외부 증거 |
| --- | --- |
| core_loop | `EvidenceDrop/Playtest` 또는 `Build/ReleaseEvidence/Playtest` |
| writing | `EvidenceDrop/Playtest` 또는 `Build/ReleaseEvidence/Playtest` |
| readability | `EvidenceDrop/Accessibility`, `Build/ReleaseEvidence/Accessibility`, `EvidenceDrop/Playtest`, `Build/ReleaseEvidence/Playtest` 중 하나 이상 |
| controls | `EvidenceDrop/Accessibility`, `Build/ReleaseEvidence/Accessibility`, `EvidenceDrop/Playtest`, `Build/ReleaseEvidence/Playtest` 중 하나 이상 |
| trust_privacy | `EvidenceDrop/LegalSteam` 또는 `Build/ReleaseEvidence/LegalSteam` |
| art_presentation | `EvidenceDrop/ArtReview` 또는 `Build/ReleaseEvidence/ArtReview` |
| trailer_store | `EvidenceDrop/Trailer` 또는 `Build/ReleaseEvidence/Trailer` |
| stability_package | 내부 패키지/빌드 QA 증거 허용. 단, 템플릿과 보조 인덱스는 증거가 아니다. |

## 점수표 위치

기본 점수표:

`Build/ReleaseEvidence/COMMERCIAL_QUALITY_SCORECARD.tsv`

초기 템플릿 생성:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -Initialize
```

검증:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityRubric.ps1 -RequireReady
```

피드백 export 기반 초안 생성:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ExportFeedbackToCommercialQualityScorecard.ps1 -FeedbackRoot ".\EvidenceDrop\Playtest" -OutputPath ".\EvidenceDrop\COMMERCIAL_QUALITY_SCORECARD_DRAFT.tsv"
```

초안은 리뷰어 보조 자료다. 공식 판정은 리뷰어가 원본 증거를 확인한 뒤 채운 `COMMERCIAL_QUALITY_SCORECARD.tsv`만 사용한다.

품질 영역별 기존 자동 QA, 스모크 캡처, 상점 자료 인덱스 생성:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\WriteCommercialQualityEvidenceIndex.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateCommercialQualityEvidenceIndex.ps1 -RequireComplete
```

`COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv`는 리뷰어가 evidence 경로를 찾기 위한 보조 자료다. 이 인덱스만으로 공식 점수표를 통과 처리하지 않는다.

## 점수표 열

| 열 | 설명 |
| --- | --- |
| area | 필수 평가 영역 |
| item | 평가 항목 이름 |
| score | 1에서 5 사이 정수 |
| blocker | true/false. 출시 차단이면 true |
| reviewer | 리뷰어 코드 또는 역할 |
| evidence | 관찰 양식, 리뷰 양식, 영상, 스크린샷, 보고서의 로컬 상대 경로. 여러 개면 세미콜론으로 구분 |
| notes | 판단 근거와 수정 요청 |

## 회의 사용법

1. 외부 플레이테스트 5세션과 상업 리뷰 증거를 먼저 모은다.
2. 각 역할이 자기 영역 점수를 채운다.
3. 점수 3 이하 항목과 blocker true 항목은 외부 이슈 레지스터에 등록한다.
4. 수정 뒤 같은 빌드 ID 기준으로 다시 검증한다.
5. `COMMERCIAL_QUALITY_REVIEW_QA.md`가 완료 상태가 아니면 최종 유료 출시 후보로 보지 않는다.


