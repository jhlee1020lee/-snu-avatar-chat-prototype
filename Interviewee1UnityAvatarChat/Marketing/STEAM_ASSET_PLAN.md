# Steam 상점 자산 계획

이 문서는 `겉!=속`를 Steam에 등록한다고 가정했을 때 필요한 그래픽 자산 초안을 정리한다.

## 기준

- Valve Steamworks 그래픽 자산 문서 기준으로 준비한다.
- 기본 캡슐류에는 게임 아트와 게임명만 넣는다.
- 현재 캡슐은 생성형 키아트 후보를 1920x1080으로 정리한 `professional_keyart_1920x1080.png`를 우선 소스로 사용한다.
- 현재 빌드 기반의 UI 없는 캡처 `source_keyart_1920x1080.png`도 함께 보관해 실제 게임 화면과의 톤 차이를 비교한다.
- 최종 제출 전에는 영어 병기, 최신 업로드 슬롯, 외부 아트 리뷰를 다시 확인한다.
- 공식 문서: https://partner.steamgames.com/doc/store/assets

## 생성 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\CaptureSteamKeyArt.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PrepareProfessionalKeyArt.ps1 -SourceImage "<generated key art png>"
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\GenerateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\PromoteSteamScreenshots.ps1
```

## 검증 명령

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateSteamAssets.ps1
.\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateVisualQuality.ps1
```

## 생성된 자산

| 파일 | 크기 | 용도 |
| --- | --- | --- |
| `SteamAssets/header_capsule_920x430.png` | 920x430 | 상점 헤더 캡슐 |
| `SteamAssets/small_capsule_462x174.png` | 462x174 | 작은 캡슐 |
| `SteamAssets/main_capsule_1232x706.png` | 1232x706 | 큰 캡슐 |
| `SteamAssets/vertical_capsule_748x896.png` | 748x896 | 세로 캡슐 |
| `SteamAssets/page_background_1438x810.png` | 1438x810 | 페이지 배경 |
| `SteamAssets/library_capsule_600x900.png` | 600x900 | 라이브러리 캡슐 |
| `SteamAssets/library_hero_3840x1240.png` | 3840x1240 | 라이브러리 히어로 |
| `SteamAssets/library_header_920x430.png` | 920x430 | 라이브러리 헤더 |
| `SteamAssets/library_logo_1280x720.png` | 1280x720 | 투명 로고 |
| `SteamAssets/shortcut_icon_256x256.png` | 256x256 | 바로가기 아이콘 초안 |
| `SteamAssets/professional_keyart_1920x1080.png` | 1920x1080 | 캡슐 우선 소스 |
| `SteamAssets/source_keyart_1920x1080.png` | 1920x1080 | UI 없는 캡슐 소스 |

## 스크린샷 세트

`Marketing/Screenshots`의 11장 스크린샷은 릴리즈 스모크 캡처를 `PromoteSteamScreenshots.ps1`로 승격해 관리한다. `Screenshots/SCREENSHOT_MANIFEST.tsv`에는 각 상점 컷의 원본 캡처, 파일 크기, SHA-256 해시, 승격 시간이 남는다. `ValidateSteamAssets.ps1`는 11장 전체의 존재, 1920x1080 규격, 매니페스트 행을 함께 검사한다.

## 작은 캡슐 확인

`SteamAssets/Audit`에는 작은 캡슐을 184x69, 120x45로 줄인 미리보기가 있다. 작은 크기에서 제목이 읽히지 않으면 상점 노출 성능이 떨어지므로 이 파일을 우선 확인한다.

## 시각 품질 QA

`Tools/ValidateVisualQuality.ps1`는 11장 상점 스크린샷과 1920x1080 키아트를 검사한다. 검증 기준은 해상도, 파일 크기, 평균 밝기, 밝기 분산, 어두운 픽셀 비율, 강한 보라색 잔상 비율, 가장자리 고대비 픽셀 비율이다. 결과는 `Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv`에 남는다.

## 남은 아트 작업

- 외부 아트 리뷰 또는 전문 일러스트 보정
- 한국어 제목 외 영어 제목 병기 여부 결정
- Steam 심사 전 Valve 문서 기준으로 최신 파일명/업로드 슬롯 재확인


