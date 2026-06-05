param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

function Add-Result {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Status,
        [string]$Evidence
    )

    $script:results.Add([pscustomobject]@{
        Area = $Area
        Item = $Item
        Status = $Status
        Evidence = $Evidence
    }) | Out-Null
}

function Add-Pass {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Evidence
    )

    Add-Result -Area $Area -Item $Item -Status "통과" -Evidence $Evidence
}

function Add-Fail {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Evidence
    )

    Add-Result -Area $Area -Item $Item -Status "실패" -Evidence $Evidence
}

function Assert-Path {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Add-Pass -Area $Area -Item $Item -Evidence $Path
        return $true
    }

    Add-Fail -Area $Area -Item $Item -Evidence "누락: $Path"
    return $false
}

function Test-Pattern {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Text,
        [string]$Pattern
    )

    if ($Text -match $Pattern) {
        Add-Pass -Area $Area -Item $Item -Evidence "패턴 확인: $Pattern"
    }
    else {
        Add-Fail -Area $Area -Item $Item -Evidence "패턴 누락: $Pattern"
    }
}

function Test-NoPattern {
    param(
        [string]$Area,
        [string]$Item,
        [string]$Text,
        [string]$Pattern
    )

    if ($Text -match $Pattern) {
        Add-Fail -Area $Area -Item $Item -Evidence "금지 패턴 발견: $Pattern"
    }
    else {
        Add-Pass -Area $Area -Item $Item -Evidence "금지 패턴 없음: $Pattern"
    }
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Read-TextIfExists {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }

    return ""
}

function Write-LinesWithRetry {
    param(
        [string]$Path,
        [object]$Lines
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        $tempPath = "$Path.tmp-$PID-$([guid]::NewGuid().ToString('N'))"
        try {
            Set-Content -LiteralPath $tempPath -Value $Lines -Encoding UTF8 -ErrorAction Stop
            Move-Item -LiteralPath $tempPath -Destination $Path -Force -ErrorAction Stop
            return
        }
        catch {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            if ($attempt -eq 8) {
                throw
            }
            Start-Sleep -Milliseconds (120 * $attempt)
        }
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$marketingRoot = Join-Path $projectRoot "Marketing"
$steamworksRoot = Join-Path $marketingRoot "Steamworks"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "STEAM_LEGAL_READINESS_QA.md"
}

$results = New-Object System.Collections.Generic.List[object]

$privacyPath = Join-Path $docsRoot "PRIVACY_NOTICE_DRAFT.md"
$privacyTemplatePath = Join-Path $docsRoot "PRIVACY_NOTICE_FINAL_TEMPLATE.md"
$supportPath = Join-Path $docsRoot "SUPPORT_HANDOFF.md"
$storePath = Join-Path $marketingRoot "STORE_PAGE_DRAFT.md"
$uploadPlanPath = Join-Path $steamworksRoot "STEAMWORKS_UPLOAD_PLAN.md"
$adminChecklistPath = Join-Path $steamworksRoot "STEAM_ADMIN_CHECKLIST.md"
$appTemplatePath = Join-Path $steamworksRoot "app_build_windows_template.vdf"
$depotTemplatePath = Join-Path $steamworksRoot "depot_build_windows_template.vdf"

Assert-Path -Area "문서" -Item "개인정보 안내 초안" -Path $privacyPath | Out-Null
Assert-Path -Area "문서" -Item "개인정보 최종본 템플릿" -Path $privacyTemplatePath | Out-Null
Assert-Path -Area "문서" -Item "지원 인계 문서" -Path $supportPath | Out-Null
Assert-Path -Area "상점" -Item "상점 페이지 문구" -Path $storePath | Out-Null
Assert-Path -Area "Steamworks" -Item "업로드 준비 메모" -Path $uploadPlanPath | Out-Null
Assert-Path -Area "Steamworks" -Item "관리자 체크리스트" -Path $adminChecklistPath | Out-Null
Assert-Path -Area "Steamworks" -Item "AppBuild 템플릿" -Path $appTemplatePath | Out-Null
Assert-Path -Area "Steamworks" -Item "DepotBuild 템플릿" -Path $depotTemplatePath | Out-Null

$privacy = Read-TextIfExists -Path $privacyPath
$privacyTemplate = Read-TextIfExists -Path $privacyTemplatePath
$support = Read-TextIfExists -Path $supportPath
$store = Read-TextIfExists -Path $storePath
$uploadPlan = Read-TextIfExists -Path $uploadPlanPath
$adminChecklist = Read-TextIfExists -Path $adminChecklistPath
$appTemplate = Read-TextIfExists -Path $appTemplatePath
$depotTemplate = Read-TextIfExists -Path $depotTemplatePath
$combined = @($privacy, $privacyTemplate, $support, $store, $uploadPlan, $adminChecklist, $appTemplate, $depotTemplate) -join "`n"

Test-Pattern -Area "개인정보" -Item "로컬 저장 고지" -Text $privacy -Pattern "로컬|사용자 데이터|PlayerPrefs"
Test-Pattern -Area "개인정보" -Item "삭제 방법 고지" -Text $privacy -Pattern "삭제"
Test-Pattern -Area "개인정보" -Item "마이크 전사 조건" -Text $privacy -Pattern "마이크.*전사|전사.*마이크"
Test-Pattern -Area "개인정보" -Item "API 키 저장 금지" -Text $privacy -Pattern "API 키.*저장하지 않는다|API 키.*저장하지 않습니다"
Test-Pattern -Area "개인정보" -Item "외부 자동 업로드 없음" -Text $privacy -Pattern "외부 서버로 자동 업로드하지 않는다|자동 업로드"
Test-Pattern -Area "개인정보" -Item "법무 최종 검토 필요 명시" -Text $privacy -Pattern "법무 검토|배포 주체|판매 지역"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "템플릿/최종본 구분" -Text $privacyTemplate -Pattern "템플릿 자체는 최종 법무 증거가 아니며|PRIVACY_NOTICE_FINAL\.md"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "배포 주체 자리" -Text $privacyTemplate -Pattern "배포 주체"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "문의 채널 자리" -Text $privacyTemplate -Pattern "문의 채널"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "판매 지역 자리" -Text $privacyTemplate -Pattern "판매 지역"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "마지막 업데이트 자리" -Text $privacyTemplate -Pattern "마지막 업데이트"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "로컬 저장 고지" -Text $privacyTemplate -Pattern "로컬 컴퓨터|PlayerPrefs|사용자 데이터"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "삭제 방법 고지" -Text $privacyTemplate -Pattern "삭제"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "마이크 전사 조건" -Text $privacyTemplate -Pattern "마이크.*전사|전사.*마이크"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "API 키 저장 금지" -Text $privacyTemplate -Pattern "API 키.*저장하지 않는다|API 키.*저장하지 않습니다"
Test-Pattern -Area "개인정보 최종본 템플릿" -Item "외부 자동 업로드 없음" -Text $privacyTemplate -Pattern "외부 서버로 자동 업로드하지 않는다|자동 업로드"

Test-Pattern -Area "상점" -Item "로컬 기록 고지" -Text $store -Pattern "로컬 컴퓨터|로컬 기록|로컬"
Test-Pattern -Area "상점" -Item "실제 인물 재현 아님 고지" -Text $store -Pattern "실제 인물.*재현하지 않습니다|초상이나 신원"
Test-Pattern -Area "상점" -Item "저장 데이터 삭제 고지" -Text $store -Pattern "삭제"

Test-Pattern -Area "지원" -Item "지원 번들 비밀정보 제외" -Text $support -Pattern "API 키 값.*수집하지|환경 변수 전체.*수집하지|비밀키"
Test-Pattern -Area "지원" -Item "이슈 등급 기준" -Text $support -Pattern "P0|P1|P2|P3"
Test-Pattern -Area "지원" -Item "Steam 운영 위치" -Text $support -Pattern "Steam 제출 패키지|Steamworks 스테이징"

Test-Pattern -Area "Steamworks" -Item "공식 업로드 참고 링크" -Text $uploadPlan -Pattern "partner\.steamgames\.com/doc/sdk/uploading"
Test-Pattern -Area "Steamworks" -Item "AppID 필요 항목" -Text $uploadPlan -Pattern "Steam AppID"
Test-Pattern -Area "Steamworks" -Item "DepotID 필요 항목" -Text $uploadPlan -Pattern "DepotID"
Test-Pattern -Area "Steamworks" -Item "steamcmd 업로드 명령" -Text $uploadPlan -Pattern "steamcmd\.exe"
Test-NoPattern -Area "Steamworks" -Item "계정 인증정보 저장 금지" -Text $combined -Pattern "Steam Guard 코드\s*[:=]\s*\S|비밀번호\s*[:=]\s*\S|password\s*[:=]\s*\S"

foreach ($required in @("Steam AppID", "Windows DepotID", "테스트 브랜치명", "실행 파일 경로", "SteamPipe 업로드 성공", "Steam 클라이언트에서 실행", "개인정보/마이크/로컬 저장 안내", "지원 이메일 또는 문의 채널")) {
    Test-Pattern -Area "관리자 체크리스트" -Item $required -Text $adminChecklist -Pattern ([regex]::Escape($required))
}
foreach ($required in @("PRIVACY_NOTICE_FINAL_TEMPLATE.md", "배포 주체 확정", "문의 채널 확정", "판매 지역 확인", "마지막 업데이트 날짜 기입", "PRIVACY_NOTICE_FINAL.md", "비밀번호/API 키/Steam Guard 코드 미포함 확인")) {
    Test-Pattern -Area "관리자 체크리스트" -Item $required -Text $adminChecklist -Pattern ([regex]::Escape($required))
}

Test-Pattern -Area "VDF 템플릿" -Item "AppBuild 블록" -Text $appTemplate -Pattern '"AppBuild"'
Test-Pattern -Area "VDF 템플릿" -Item "AppID 자리표시자" -Text $appTemplate -Pattern "REPLACE_WITH_STEAM_APP_ID"
Test-Pattern -Area "VDF 템플릿" -Item "DepotID 자리표시자" -Text $appTemplate -Pattern "REPLACE_WITH_WINDOWS_DEPOT_ID"
Test-Pattern -Area "VDF 템플릿" -Item "ContentRoot" -Text $appTemplate -Pattern '"ContentRoot"\s+"\.\.\\content"'
Test-Pattern -Area "VDF 템플릿" -Item "DepotBuild 블록" -Text $depotTemplate -Pattern '"DepotBuild"'
Test-Pattern -Area "VDF 템플릿" -Item "로그/PID 제외" -Text $depotTemplate -Pattern '\*\.log|\.server\.pid'

Test-NoPattern -Area "보안" -Item "API 키 형태 문자열 없음" -Text $combined -Pattern $ApiKeyPattern
Test-NoPattern -Area "보안" -Item "Steam 계정 예시값 없음" -Text $combined -Pattern "account_name\s*=\s*\S|steam_login\s*=\s*\S"

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$passed = @($results | Where-Object { $_.Status -eq "통과" }).Count
$failed = @($results | Where-Object { $_.Status -eq "실패" }).Count

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Steam/법무 준비 자동 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 자동 통과: $passed")
$lines.Add("- 자동 실패: $failed")
$lines.Add("")
$lines.Add("이 자동 QA는 개인정보 안내 초안과 최종본 템플릿, 상점 주의 문구, 지원 인계, Steamworks 업로드 메모, 관리자 체크리스트, VDF 템플릿의 기본 구성을 확인한다. 실제 AppID/DepotID, Steam 관리자 화면 설정, 배포 주체 기준 법무 검토, 문의 채널 확정은 외부 증거가 필요하다.")
$lines.Add("")
$lines.Add("| 영역 | 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Area) | $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) |")
}

Write-LinesWithRetry -Path $OutputPath -Lines $lines

if ($failed -gt 0) {
    throw "Steam/legal readiness QA failed with $failed issue(s). Report: $OutputPath"
}

Write-Host "Steam/legal readiness QA passed: $OutputPath"
