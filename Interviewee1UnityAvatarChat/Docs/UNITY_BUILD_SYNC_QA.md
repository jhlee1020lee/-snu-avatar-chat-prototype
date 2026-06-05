# Unity 빌드 동기화 QA

- 생성 시각: 2026-06-03 01:18:24 +09:00
- 상태: 통과
- 통과: 3
- 보류: 0
- 실패: 0

이 검사는 Unity 창을 띄우지 않고 소스 파일과 최신 빌드 산출물의 수정 시각을 비교한다. Windows 실행 파일 래퍼는 Unity 빌드 때 수정 시각이 유지될 수 있으므로 실제 런타임 코드와 데이터 산출물을 함께 본다.

| 항목 | 상태 | 근거 |
| --- | --- | --- |
| 최근 소스 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Assets\Scripts\AvatarChatApp.cs / 2026-06-03 01:12:25 |
| 최신 빌드 산출물 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\Interviewee1UnityAvatarChat_Data\Managed\Assembly-CSharp.dll / 2026-06-03 01:13:27 |
| Unity 재빌드 필요 | 통과 | 최신 빌드 산출물이 검사 대상 소스보다 최신이거나 같음 |
