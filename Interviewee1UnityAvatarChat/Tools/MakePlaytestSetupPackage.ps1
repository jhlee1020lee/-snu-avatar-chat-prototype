param(
    [string]$SourcePackageRoot,
    [string]$PackageName = "GeotNotEqualSok-Playtest-Setup",
    [string]$OutputRoot,
    [switch]$SkipSetupExe
)

$ErrorActionPreference = "Stop"

function ConvertTo-LongPath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith("\\?\")) {
        return $full
    }
    if ($full.StartsWith("\\")) {
        return "\\?\UNC\" + $full.Substring(2)
    }
    return "\\?\" + $full
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Text
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Text, [System.Text.UTF8Encoding]::new($false))
}

function Write-Windows1252 {
    param(
        [string]$Path,
        [string]$Text
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Text, [System.Text.Encoding]::Default)
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($SourcePackageRoot)) {
    $SourcePackageRoot = Join-Path $buildRoot "ExternalPlaytestPackages\GeotNotEqualSok-ExternalPlaytest-QA"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $buildRoot "InstallerPackages"
}

$sourceFullPath = [System.IO.Path]::GetFullPath($SourcePackageRoot)
if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $sourceFullPath) -PathType Container)) {
    throw "Missing external playtest package: $sourceFullPath"
}

$outputFullPath = [System.IO.Path]::GetFullPath($OutputRoot)
$setupRoot = Join-Path $outputFullPath $PackageName
$zipPath = Join-Path $outputFullPath "$PackageName.zip"
$setupExePath = Join-Path $outputFullPath "$PackageName.exe"

New-Item -ItemType Directory -Force -Path $outputFullPath | Out-Null
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $setupRoot)) {
    $resolvedSetup = [System.IO.Path]::GetFullPath($setupRoot)
    if (-not $resolvedSetup.StartsWith($outputFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove setup root outside output folder: $resolvedSetup"
    }
    Remove-Item -LiteralPath (ConvertTo-LongPath -Path $setupRoot) -Recurse -Force
}
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $zipPath)) {
    Remove-Item -LiteralPath (ConvertTo-LongPath -Path $zipPath) -Force
}
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $setupExePath)) {
    Remove-Item -LiteralPath (ConvertTo-LongPath -Path $setupExePath) -Force
}

$payloadRoot = Join-Path $setupRoot "Payload"
New-Item -ItemType Directory -Force -Path $payloadRoot | Out-Null
Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $sourceFullPath) -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $payloadRoot -Recurse -Force
}

$installScript = @'
param(
    [string]$InstallRoot
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$payloadRoot = Join-Path $scriptRoot "Payload"
if (-not (Test-Path -LiteralPath $payloadRoot -PathType Container)) {
    throw "Payload folder is missing: $payloadRoot"
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "GeotNotEqualSokPlaytest"
}

Ensure-Directory -Path $InstallRoot
Copy-Item -LiteralPath (Join-Path $payloadRoot "*") -Destination $InstallRoot -Recurse -Force

$gameBat = Join-Path $InstallRoot "Game\Interviewee1UnityAvatarChat\RUN_AVATAR_CHAT.bat"
if (-not (Test-Path -LiteralPath $gameBat)) {
    throw "Installed game launcher is missing: $gameBat"
}

$desktop = [Environment]::GetFolderPath("Desktop")
$shell = New-Object -ComObject WScript.Shell

$gameShortcut = $shell.CreateShortcut((Join-Path $desktop "겉!=속 플레이테스트.lnk"))
$gameShortcut.TargetPath = $gameBat
$gameShortcut.WorkingDirectory = Split-Path -Parent $gameBat
$gameShortcut.Description = "겉!=속 외부 플레이테스트 실행"
$gameShortcut.Save()

$evidenceRoot = Join-Path $InstallRoot "EvidenceDrop"
Ensure-Directory -Path $evidenceRoot
$evidenceShortcut = $shell.CreateShortcut((Join-Path $desktop "겉!=속 테스트자료 폴더.lnk"))
$evidenceShortcut.TargetPath = $evidenceRoot
$evidenceShortcut.WorkingDirectory = $evidenceRoot
$evidenceShortcut.Description = "겉!=속 플레이테스트 피드백과 증거 폴더"
$evidenceShortcut.Save()

$readme = Join-Path $InstallRoot "README_EXTERNAL_PLAYTEST.txt"
Write-Host ""
Write-Host "겉!=속 플레이테스트 설치 완료"
Write-Host "설치 위치: $InstallRoot"
Write-Host "바탕화면 바로가기: 겉!=속 플레이테스트"
Write-Host "테스트자료 폴더 바로가기: 겉!=속 테스트자료 폴더"
Write-Host ""
Write-Host "테스터는 바탕화면의 '겉!=속 플레이테스트'를 실행하면 됩니다."
if (Test-Path -LiteralPath $readme) {
    Write-Host "안내 파일: $readme"
}
'@

$installBat = @'
@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Playtest.ps1"
if errorlevel 1 (
  echo.
  echo 설치 중 문제가 발생했습니다. 이 창의 내용을 개발자에게 보내 주세요.
  pause
  exit /b 1
)
echo.
echo 설치가 끝났습니다. 바탕화면의 "겉!=속 플레이테스트" 바로가기를 실행하세요.
pause
'@

$runPortableBat = @'
@echo off
setlocal
cd /d "%~dp0Payload\Game\Interviewee1UnityAvatarChat"
call RUN_AVATAR_CHAT.bat
'@

$includesBundledApiKey = Test-Path -LiteralPath (Join-Path $sourceFullPath "Game\Interviewee1UnityAvatarChat\RuntimeSecrets\OPENAI_API_KEY.txt")

if ($includesBundledApiKey) {
    $readme = @'
겉!=속 내부 테스트 설치 패키지

EXE로 보내는 경우:
- GeotNotEqualSok-Playtest-Setup.exe 파일을 보내면 됩니다.
- 테스터는 EXE를 더블클릭해 설치합니다.

ZIP으로 보내려면:
- GeotNotEqualSok-Playtest-Setup.zip 을 보내도 됩니다.
- 압축 해제 후 설치하기.bat 를 실행합니다.

테스터용 실행 방법:
1. 설치 파일 또는 설치하기.bat 를 실행합니다.
2. 설치가 끝나면 바탕화면의 "겉!=속 플레이테스트" 바로가기를 실행합니다.
3. 게임에서 질문과 답변을 최소 5번 진행합니다.
4. 마지막에 기록을 저장하고 의견을 남깁니다.
5. 바탕화면의 "겉!=속 테스트자료 폴더"에 생성된 자료 또는 피드백 파일을 개발자에게 보내 주세요.

API 키:
- 내부 테스트용 API 키가 패키지에 포함되어 있습니다.
- 테스터가 따로 OPENAI_API_KEY를 설정할 필요는 없습니다.
- 키는 RuntimeSecrets 폴더에 들어 있으므로 외부 배포하면 안 됩니다.
- 테스트가 끝나면 OpenAI 콘솔에서 해당 키를 폐기하세요.
- 런처는 로컬 서버/API 상태가 정상이 아니면 게임을 실행하지 않습니다.

설치 위치:
%LOCALAPPDATA%\GeotNotEqualSokPlaytest

설치 없이 바로 실행하려면:
게임 바로 실행.bat 를 더블클릭합니다.

주의:
- 이 패키지는 내부 팀 테스트용입니다. 외부 배포하지 마세요.
- Steam 계정, 비밀번호, 개인 계정 정보는 어떤 파일에도 넣지 마세요.
- Windows SmartScreen이 경고하면 "추가 정보" 후 실행을 눌러야 할 수 있습니다. 이 파일은 서명된 상용 설치 파일이 아니라 플레이테스트용 설치 패키지입니다.
'@
}
else {
    $readme = @'
겉!=속 플레이테스트 설치 패키지

EXE로 보내는 경우:
- GeotNotEqualSok-Playtest-Setup.exe 파일을 보내면 됩니다.
- 테스터는 EXE를 더블클릭해 설치합니다.

ZIP으로 보내려면:
- GeotNotEqualSok-Playtest-Setup.zip 을 보내도 됩니다.
- 압축 해제 후 설치하기.bat 를 실행합니다.

테스터용 실행 방법:
1. 설치 파일 또는 설치하기.bat 를 실행합니다.
2. OPENAI_API_KEY 환경 변수가 설정되어 있는지 확인합니다.
3. 설치가 끝나면 바탕화면의 "겉!=속 플레이테스트" 바로가기를 실행합니다.
4. 게임에서 질문과 답변을 최소 5번 진행합니다.
5. 마지막에 기록을 저장하고 의견을 남깁니다.
6. 바탕화면의 "겉!=속 테스트자료 폴더"에 생성된 자료 또는 피드백 파일을 개발자에게 보내 주세요.

API 키:
- API 키는 이 패키지에 포함하지 않습니다.
- 런처는 로컬 서버/API 상태가 정상이 아니면 게임을 실행하지 않습니다.
- PowerShell에서 아래처럼 1회 설정 후 새 터미널 또는 바로가기로 실행할 수 있습니다.
  [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "여기에_API_키", "User")

설치 위치:
%LOCALAPPDATA%\GeotNotEqualSokPlaytest

설치 없이 바로 실행하려면:
게임 바로 실행.bat 를 더블클릭합니다.

주의:
- Steam 계정, 비밀번호, API 키, 개인 계정 정보는 어떤 파일에도 넣지 마세요.
- Windows SmartScreen이 경고하면 "추가 정보" 후 실행을 눌러야 할 수 있습니다. 이 파일은 서명된 상용 설치 파일이 아니라 플레이테스트용 설치 패키지입니다.
'@
}

Write-Utf8NoBom -Path (Join-Path $setupRoot "Install-Playtest.ps1") -Text $installScript
Write-Utf8NoBom -Path (Join-Path $setupRoot "설치하기.bat") -Text $installBat
Write-Utf8NoBom -Path (Join-Path $setupRoot "게임 바로 실행.bat") -Text $runPortableBat
Write-Utf8NoBom -Path (Join-Path $setupRoot "README_설치.txt") -Text $readme

$zipItems = @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $setupRoot) -Force | ForEach-Object { $_.FullName })
Compress-Archive -LiteralPath $zipItems -DestinationPath $zipPath -Force

if (-not $SkipSetupExe) {
    $iexpress = (Get-Command iexpress.exe -ErrorAction SilentlyContinue).Source
    if ($iexpress) {
        $driveRoot = [System.IO.Path]::GetPathRoot($outputFullPath)
        $sfxBaseRoot = Join-Path $driveRoot "codex\playtest_setup_sfx"
        $sfxRoot = Join-Path $sfxBaseRoot $PackageName
        $packageZip = Join-Path $sfxRoot "Package.zip"
        $bootstrapBat = Join-Path $sfxRoot "SetupBootstrap.bat"
        $sedPath = Join-Path $sfxRoot "SetupPackage.sed"
        $tempSetupExe = Join-Path $sfxRoot "$PackageName.exe"

        if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $sfxRoot)) {
            $resolvedSfx = [System.IO.Path]::GetFullPath($sfxRoot)
            if (-not $resolvedSfx.StartsWith([System.IO.Path]::GetFullPath($sfxBaseRoot), [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing to remove setup staging outside staging folder: $resolvedSfx"
            }
            Remove-Item -LiteralPath (ConvertTo-LongPath -Path $sfxRoot) -Recurse -Force
        }
        if (Test-Path -LiteralPath $tempSetupExe) {
            Remove-Item -LiteralPath $tempSetupExe -Force
        }
        New-Item -ItemType Directory -Force -Path $sfxRoot | Out-Null
        Copy-Item -LiteralPath $zipPath -Destination $packageZip -Force

        $bootstrap = @'
@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%~dp0Package.zip' -DestinationPath '%TEMP%\GeotNotEqualSokPlaytestSetup' -Force; & '%TEMP%\GeotNotEqualSokPlaytestSetup\Install-Playtest.ps1'"
if errorlevel 1 (
  echo.
  echo 설치 중 문제가 발생했습니다. 이 창의 내용을 개발자에게 보내 주세요.
  pause
  exit /b 1
)
echo.
echo 설치가 끝났습니다. 바탕화면의 "겉!=속 플레이테스트" 바로가기를 실행하세요.
pause
'@
        Write-Utf8NoBom -Path $bootstrapBat -Text $bootstrap

        $sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles

[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$tempSetupExe
FriendlyName=GeotNotEqualSok Playtest Setup
AppLaunched=SetupBootstrap.bat
FILE0="SetupBootstrap.bat"
FILE1="Package.zip"

[SourceFiles]
SourceFiles0=$sfxRoot\

[SourceFiles0]
%FILE0%=
%FILE1%=
"@
        Write-Windows1252 -Path $sedPath -Text $sed

        & $iexpress /N /Q /M $sedPath | Out-Null
        if (-not (Test-Path -LiteralPath $tempSetupExe -PathType Leaf)) {
            throw "IExpress did not create setup exe: $tempSetupExe"
        }
        Copy-Item -LiteralPath $tempSetupExe -Destination $setupExePath -Force
        Remove-Item -LiteralPath $tempSetupExe -Force
        Remove-Item -LiteralPath (ConvertTo-LongPath -Path $sfxRoot) -Recurse -Force
    }
    else {
        Write-Warning "IExpress is not available. ZIP setup package was created, but setup EXE was skipped."
    }
}

Write-Host "Playtest setup folder created: $setupRoot"
Write-Host "Playtest setup zip created: $zipPath"
if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $setupExePath) -PathType Leaf) {
    Write-Host "Playtest setup exe created: $setupExePath"
}
