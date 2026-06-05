# Steamworks 업로드 준비 메모

이 폴더는 Steamworks 관리자에서 AppID와 DepotID를 받은 뒤 Windows 빌드를 SteamPipe에 올리기 위한 준비 자료다.

참고 기준:

- Steamworks Uploading to Steam: https://partner.steamgames.com/doc/sdk/uploading
- Steamworks Builds: https://partner.steamgames.com/doc/store/application/builds

## 현재 로컬에서 준비한 것

- Windows 실행 패키지: `Build/ReleasePackages/GeotNotEqualSok-Windows-QA`
- Steamworks 스테이징 패키지 생성: `Tools/MakeSteamworksStagingPackage.ps1`
- Steamworks 스테이징 패키지 검증: `Tools/ValidateSteamworksStagingPackage.ps1`
- AppBuild 템플릿: `app_build_windows_template.vdf`
- DepotBuild 템플릿: `depot_build_windows_template.vdf`

## 운영자가 Steamworks에서 채워야 하는 값

- Steam AppID
- Windows DepotID
- 베타 브랜치명 또는 기본 브랜치 업로드 여부
- SteamPipe install directory
- Steam 관리자 권한이 있는 빌드 업로드 계정

## 기본 절차

1. Windows 실행 패키지를 만든다.
2. `MakeSteamworksStagingPackage.ps1`로 `content`, `scripts`, `output` 폴더를 만든다.
3. Steamworks에서 받은 AppID와 DepotID를 VDF 스크립트에 넣는다.
4. Steamworks SDK의 `steamcmd.exe`로 `scripts/app_build_windows.vdf`를 실행한다.
5. Steamworks App Admin의 Builds 페이지에서 업로드된 빌드를 확인한다.
6. 내부 테스트 브랜치에서 설치, 실행, 저장 삭제, 서버 상태, 마이크 전사 경로를 확인한다.

## 업로드 명령 예시

```powershell
<SteamworksSDK>\tools\ContentBuilder\builder\steamcmd.exe +login <account_name> +run_app_build <staging>\scripts\app_build_windows.vdf +quit
```

실제 계정명, 인증, AppID, DepotID는 이 저장소에 기록하지 않는다.


