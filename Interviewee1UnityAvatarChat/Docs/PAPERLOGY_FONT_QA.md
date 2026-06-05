# Paperlogy 폰트 QA

- 생성 시각: 2026-06-03 01:18:36 +09:00
- 자동 통과: 12
- 자동 실패: 0

이 QA는 게임 UI와 상점/트레일러 생성 스크립트가 번들된 Paperlogy 폰트를 우선 사용하도록 유지되는지 확인한다.

| 영역 | 항목 | 상태 | 근거 |
| --- | --- | --- | --- |
| 폰트 자산 | Paperlogy Regular | 통과 | C:\\codex\\snu_etl_downloader_portable\\downloads\\2026_Spring\\understanding_exceptional_children\\99_GroupProject\\Interviewee1UnityAvatarChat\\Assets\\Resources\\Fonts\\Paperlogy-4Regular.ttf (679480 bytes) |
| 폰트 자산 | Paperlogy SemiBold | 통과 | C:\\codex\\snu_etl_downloader_portable\\downloads\\2026_Spring\\understanding_exceptional_children\\99_GroupProject\\Interviewee1UnityAvatarChat\\Assets\\Resources\\Fonts\\Paperlogy-6SemiBold.ttf (677712 bytes) |
| 폰트 자산 | Paperlogy Bold | 통과 | C:\\codex\\snu_etl_downloader_portable\\downloads\\2026_Spring\\understanding_exceptional_children\\99_GroupProject\\Interviewee1UnityAvatarChat\\Assets\\Resources\\Fonts\\Paperlogy-7Bold.ttf (676716 bytes) |
| 게임 UI | 런타임 폰트 리소스 로드 | 통과 | 패턴 확인: (?s)Resources\\.Load<Font>\\("Fonts/Paperlogy-4Regular"\\).*Resources\\.Load<Font>\\("Fonts/Paperlogy-6SemiBold"\\).*Resources\\.Load<Font>\\("Fonts/Paperlogy-7Bold"\\) |
| 게임 UI | 동적 폰트 fallback 우선순위 | 통과 | 패턴 확인: (?s)"Paperlogy".*"Paperlogy 4 Regular".*"Noto Sans KR".*"Malgun Gothic" |
| 게임 UI | 런타임 폰트 스모크 상태 | 통과 | 패턴 확인: state\\\\tui-font\|GetUiFontReport |
| 상점/트레일러 | GenerateSteamAssets.ps1 Paperlogy 번들 로드 | 통과 | 패턴 확인: (?s)Paperlogy-7Bold\\.ttf.*PrivateFontCollection.*AddFontFile |
| 상점/트레일러 | GenerateTrailerAnimatic.ps1 Paperlogy 번들 로드 | 통과 | 패턴 확인: (?s)Paperlogy-7Bold\\.ttf.*PrivateFontCollection.*AddFontFile |
| 상점/트레일러 | GenerateBuildCaptureTrailer.ps1 Paperlogy 번들 로드 | 통과 | 패턴 확인: (?s)Paperlogy-7Bold\\.ttf.*PrivateFontCollection.*AddFontFile |
| 산출물 증거 | Steam 자산 생성 폰트 증거 | 통과 | SteamAssets Paperlogy-7Bold 해시 확인 |
| 산출물 증거 | 애니매틱 트레일러 생성 폰트 증거 | 통과 | trailer_animatic_60s.mp4 Paperlogy-7Bold 해시 확인 |
| 산출물 증거 | 빌드 캡처 트레일러 생성 폰트 증거 | 통과 | trailer_build_capture_60s.mp4 Paperlogy-7Bold 해시 확인 |
