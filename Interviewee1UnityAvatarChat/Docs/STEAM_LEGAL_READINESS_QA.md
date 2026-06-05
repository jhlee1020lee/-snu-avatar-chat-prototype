# Steam/법무 준비 자동 QA

- 생성 시각: 2026-06-04 11:01:23 +09:00
- 자동 통과: 58
- 자동 실패: 0

이 자동 QA는 개인정보 안내 초안과 최종본 템플릿, 상점 주의 문구, 지원 인계, Steamworks 업로드 메모, 관리자 체크리스트, VDF 템플릿의 기본 구성을 확인한다. 실제 AppID/DepotID, Steam 관리자 화면 설정, 배포 주체 기준 법무 검토, 문의 채널 확정은 외부 증거가 필요하다.

| 영역 | 항목 | 상태 | 근거 |
| --- | --- | --- | --- |
| 문서 | 개인정보 안내 초안 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\PRIVACY_NOTICE_DRAFT.md |
| 문서 | 개인정보 최종본 템플릿 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\PRIVACY_NOTICE_FINAL_TEMPLATE.md |
| 문서 | 지원 인계 문서 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Docs\SUPPORT_HANDOFF.md |
| 상점 | 상점 페이지 문구 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Marketing\STORE_PAGE_DRAFT.md |
| Steamworks | 업로드 준비 메모 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Marketing\Steamworks\STEAMWORKS_UPLOAD_PLAN.md |
| Steamworks | 관리자 체크리스트 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Marketing\Steamworks\STEAM_ADMIN_CHECKLIST.md |
| Steamworks | AppBuild 템플릿 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Marketing\Steamworks\app_build_windows_template.vdf |
| Steamworks | DepotBuild 템플릿 | 통과 | C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Marketing\Steamworks\depot_build_windows_template.vdf |
| 개인정보 | 로컬 저장 고지 | 통과 | 패턴 확인: 로컬\|사용자 데이터\|PlayerPrefs |
| 개인정보 | 삭제 방법 고지 | 통과 | 패턴 확인: 삭제 |
| 개인정보 | 마이크 전사 조건 | 통과 | 패턴 확인: 마이크.*전사\|전사.*마이크 |
| 개인정보 | API 키 저장 금지 | 통과 | 패턴 확인: API 키.*저장하지 않는다\|API 키.*저장하지 않습니다 |
| 개인정보 | 외부 자동 업로드 없음 | 통과 | 패턴 확인: 외부 서버로 자동 업로드하지 않는다\|자동 업로드 |
| 개인정보 | 법무 최종 검토 필요 명시 | 통과 | 패턴 확인: 법무 검토\|배포 주체\|판매 지역 |
| 개인정보 최종본 템플릿 | 템플릿/최종본 구분 | 통과 | 패턴 확인: 템플릿 자체는 최종 법무 증거가 아니며\|PRIVACY_NOTICE_FINAL\.md |
| 개인정보 최종본 템플릿 | 배포 주체 자리 | 통과 | 패턴 확인: 배포 주체 |
| 개인정보 최종본 템플릿 | 문의 채널 자리 | 통과 | 패턴 확인: 문의 채널 |
| 개인정보 최종본 템플릿 | 판매 지역 자리 | 통과 | 패턴 확인: 판매 지역 |
| 개인정보 최종본 템플릿 | 마지막 업데이트 자리 | 통과 | 패턴 확인: 마지막 업데이트 |
| 개인정보 최종본 템플릿 | 로컬 저장 고지 | 통과 | 패턴 확인: 로컬 컴퓨터\|PlayerPrefs\|사용자 데이터 |
| 개인정보 최종본 템플릿 | 삭제 방법 고지 | 통과 | 패턴 확인: 삭제 |
| 개인정보 최종본 템플릿 | 마이크 전사 조건 | 통과 | 패턴 확인: 마이크.*전사\|전사.*마이크 |
| 개인정보 최종본 템플릿 | API 키 저장 금지 | 통과 | 패턴 확인: API 키.*저장하지 않는다\|API 키.*저장하지 않습니다 |
| 개인정보 최종본 템플릿 | 외부 자동 업로드 없음 | 통과 | 패턴 확인: 외부 서버로 자동 업로드하지 않는다\|자동 업로드 |
| 상점 | 로컬 기록 고지 | 통과 | 패턴 확인: 로컬 컴퓨터\|로컬 기록\|로컬 |
| 상점 | 실제 인물 재현 아님 고지 | 통과 | 패턴 확인: 실제 인물.*재현하지 않습니다\|초상이나 신원 |
| 상점 | 저장 데이터 삭제 고지 | 통과 | 패턴 확인: 삭제 |
| 지원 | 지원 번들 비밀정보 제외 | 통과 | 패턴 확인: API 키 값.*수집하지\|환경 변수 전체.*수집하지\|비밀키 |
| 지원 | 이슈 등급 기준 | 통과 | 패턴 확인: P0\|P1\|P2\|P3 |
| 지원 | Steam 운영 위치 | 통과 | 패턴 확인: Steam 제출 패키지\|Steamworks 스테이징 |
| Steamworks | 공식 업로드 참고 링크 | 통과 | 패턴 확인: partner\.steamgames\.com/doc/sdk/uploading |
| Steamworks | AppID 필요 항목 | 통과 | 패턴 확인: Steam AppID |
| Steamworks | DepotID 필요 항목 | 통과 | 패턴 확인: DepotID |
| Steamworks | steamcmd 업로드 명령 | 통과 | 패턴 확인: steamcmd\.exe |
| Steamworks | 계정 인증정보 저장 금지 | 통과 | 금지 패턴 없음: Steam Guard 코드\s*[:=]\s*\S\|비밀번호\s*[:=]\s*\S\|password\s*[:=]\s*\S |
| 관리자 체크리스트 | Steam AppID | 통과 | 패턴 확인: Steam\ AppID |
| 관리자 체크리스트 | Windows DepotID | 통과 | 패턴 확인: Windows\ DepotID |
| 관리자 체크리스트 | 테스트 브랜치명 | 통과 | 패턴 확인: 테스트\ 브랜치명 |
| 관리자 체크리스트 | 실행 파일 경로 | 통과 | 패턴 확인: 실행\ 파일\ 경로 |
| 관리자 체크리스트 | SteamPipe 업로드 성공 | 통과 | 패턴 확인: SteamPipe\ 업로드\ 성공 |
| 관리자 체크리스트 | Steam 클라이언트에서 실행 | 통과 | 패턴 확인: Steam\ 클라이언트에서\ 실행 |
| 관리자 체크리스트 | 개인정보/마이크/로컬 저장 안내 | 통과 | 패턴 확인: 개인정보/마이크/로컬\ 저장\ 안내 |
| 관리자 체크리스트 | 지원 이메일 또는 문의 채널 | 통과 | 패턴 확인: 지원\ 이메일\ 또는\ 문의\ 채널 |
| 관리자 체크리스트 | PRIVACY_NOTICE_FINAL_TEMPLATE.md | 통과 | 패턴 확인: PRIVACY_NOTICE_FINAL_TEMPLATE\.md |
| 관리자 체크리스트 | 배포 주체 확정 | 통과 | 패턴 확인: 배포\ 주체\ 확정 |
| 관리자 체크리스트 | 문의 채널 확정 | 통과 | 패턴 확인: 문의\ 채널\ 확정 |
| 관리자 체크리스트 | 판매 지역 확인 | 통과 | 패턴 확인: 판매\ 지역\ 확인 |
| 관리자 체크리스트 | 마지막 업데이트 날짜 기입 | 통과 | 패턴 확인: 마지막\ 업데이트\ 날짜\ 기입 |
| 관리자 체크리스트 | PRIVACY_NOTICE_FINAL.md | 통과 | 패턴 확인: PRIVACY_NOTICE_FINAL\.md |
| 관리자 체크리스트 | 비밀번호/API 키/Steam Guard 코드 미포함 확인 | 통과 | 패턴 확인: 비밀번호/API\ 키/Steam\ Guard\ 코드\ 미포함\ 확인 |
| VDF 템플릿 | AppBuild 블록 | 통과 | 패턴 확인: "AppBuild" |
| VDF 템플릿 | AppID 자리표시자 | 통과 | 패턴 확인: REPLACE_WITH_STEAM_APP_ID |
| VDF 템플릿 | DepotID 자리표시자 | 통과 | 패턴 확인: REPLACE_WITH_WINDOWS_DEPOT_ID |
| VDF 템플릿 | ContentRoot | 통과 | 패턴 확인: "ContentRoot"\s+"\.\.\\content" |
| VDF 템플릿 | DepotBuild 블록 | 통과 | 패턴 확인: "DepotBuild" |
| VDF 템플릿 | 로그/PID 제외 | 통과 | 패턴 확인: \*\.log\|\.server\.pid |
| 보안 | API 키 형태 문자열 없음 | 통과 | 금지 패턴 없음: sk-\.\.\.\|sk-(proj\|live\|test\|svcacct)-[A-Za-z0-9_-]*\|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,} |
| 보안 | Steam 계정 예시값 없음 | 통과 | 금지 패턴 없음: account_name\s*=\s*\S\|steam_login\s*=\s*\S |
