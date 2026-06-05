param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$RosterPath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

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

function Ensure-Directory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path (ConvertTo-LongPath -Path $Path) | Out-Null
    }
}

function Format-TsvCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Get-ExistingRows {
    param([string]$Path)

    $map = @{}
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return $map
    }
    foreach ($row in @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $Path) -Encoding UTF8)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$row.id)) {
            $map[[string]$row.id] = $row
        }
    }
    return $map
}

function Get-Value {
    param(
        [object]$Primary,
        [object]$Fallback,
        [string]$Name,
        [string]$Default = ""
    )

    foreach ($source in @($Primary, $Fallback)) {
        if ($source -and $source.PSObject.Properties.Name -contains $Name) {
            $value = [string]$source.$Name
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value.Trim()
            }
        }
    }
    return $Default
}

function Get-Profile {
    param([string]$Id)

    if ($Id -match "^PT-") {
        return "일반 PC 사용자, 20분 플레이 가능, 긴 답변 읽기와 기록 저장 흐름을 솔직히 평가할 사람"
    }
    switch ($Id) {
        "ACCESS-01" { return "키보드 전용 조작, 화면 배율, 큰 글자, 고대비 조건을 실제로 확인할 접근성 검토자" }
        "ART-01" { return "상업 아트 또는 Steam 캡슐 판독성 검토 경험이 있는 아트 리뷰어" }
        "TRAILER-01" { return "게임 트레일러의 첫 10초 이해도, 자막, 실제 플레이 전달력을 볼 영상 리뷰어" }
        "LEGAL-01" { return "Steamworks 설정, 개인정보 문구, 테스트 브랜치 실행을 확인할 운영 또는 법무 담당자" }
        "QUALITY-01" { return "외부 증거를 읽고 USD 5 이상 품질 점수표를 채울 프로듀서 또는 선임 리뷰어" }
        "ISSUE-01" { return "외부 리뷰 이슈의 심각도, 재현 단계, 해결 또는 수용 위험을 닫을 QA 담당자" }
    }
    return "외부 검토 담당자"
}

function Assert-NoApiKeyPattern {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            continue
        }
        $matches = Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($matches) {
            throw "Reviewer roster contains an API key pattern: $path"
        }
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($TrackerPath)) {
    $TrackerPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_TRACKER.tsv"
}
if ([string]::IsNullOrWhiteSpace($RosterPath)) {
    $RosterPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEWER_ROSTER.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_ROSTER.md"
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    $trackerScript = Join-Path $PSScriptRoot "WriteExternalReviewTracker.ps1"
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $trackerScript))) {
        throw "Missing tracker and tracker writer: $TrackerPath"
    }
    & $trackerScript -EvidenceRoot $EvidenceRoot 2>&1 | Out-Null
}

$trackerRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
$existingRows = Get-ExistingRows -Path $RosterPath
$rosterRows = New-Object System.Collections.Generic.List[object]

foreach ($tracker in $trackerRows) {
    $id = [string]$tracker.id
    if ([string]::IsNullOrWhiteSpace($id)) {
        continue
    }
    $existing = $existingRows[$id]
    $defaultProfile = Get-Profile -Id $id
    $reviewerProfile = Get-Value -Primary $existing -Fallback $null -Name "reviewer_profile" -Default $defaultProfile
    if ($id -eq "QUALITY-01" -and $reviewerProfile -match "USD\s+10\s+이상\s+품질\s+점수표") {
        $reviewerProfile = $defaultProfile
    }
    $rosterRows.Add([pscustomobject]@{
        id = $id
        role = [string]$tracker.role
        reviewer_profile = $reviewerProfile
        reviewer_alias = Get-Value -Primary $existing -Fallback $tracker -Name "reviewer_alias"
        contact_method = Get-Value -Primary $existing -Fallback $tracker -Name "contact_method"
        due_at = Get-Value -Primary $existing -Fallback $tracker -Name "due_at"
        backup_reviewer_alias = Get-Value -Primary $existing -Fallback $null -Name "backup_reviewer_alias"
        backup_contact_method = Get-Value -Primary $existing -Fallback $null -Name "backup_contact_method"
        invite_status = Get-Value -Primary $existing -Fallback $tracker -Name "invite_status" -Default "not_sent"
        invite_sent_at = Get-Value -Primary $existing -Fallback $tracker -Name "invite_sent_at"
        notes = Get-Value -Primary $existing -Fallback $tracker -Name "notes"
    }) | Out-Null
}

Ensure-Directory -Path (Split-Path -Parent $RosterPath)
$header = "id`trole`treviewer_profile`treviewer_alias`tcontact_method`tdue_at`tbackup_reviewer_alias`tbackup_contact_method`tinvite_status`tinvite_sent_at`tnotes"
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add($header)
foreach ($row in $rosterRows) {
    $lines.Add(@(
        (Format-TsvCell $row.id),
        (Format-TsvCell $row.role),
        (Format-TsvCell $row.reviewer_profile),
        (Format-TsvCell $row.reviewer_alias),
        (Format-TsvCell $row.contact_method),
        (Format-TsvCell $row.due_at),
        (Format-TsvCell $row.backup_reviewer_alias),
        (Format-TsvCell $row.backup_contact_method),
        (Format-TsvCell $row.invite_status),
        (Format-TsvCell $row.invite_sent_at),
        (Format-TsvCell $row.notes)
    ) -join "`t")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $RosterPath) -Value $lines -Encoding UTF8

$assigned = @($rosterRows | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_.reviewer_alias) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.contact_method) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.due_at)
}).Count
$missing = $rosterRows.Count - $assigned

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
$docLines = New-Object System.Collections.Generic.List[string]
$docLines.Add("# 외부 리뷰어 명단")
$docLines.Add("")
$docLines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$docLines.Add("- 명단 TSV: $RosterPath")
$docLines.Add("- 전체 항목: $($rosterRows.Count)")
$docLines.Add("- 배정 완료: $assigned")
$docLines.Add("- 배정 필요: $missing")
$docLines.Add("")
$docLines.Add("이 명단은 외부 검토 담당자를 추적표에 안전하게 반영하기 위한 운영 파일이다. 실제 리뷰 증거를 대체하지 않는다.")
$docLines.Add("")
$docLines.Add("## 사용 순서")
$docLines.Add("")
$docLines.Add("1. EXTERNAL_REVIEWER_ROSTER.tsv의 reviewer_alias, contact_method, due_at을 채운다. due_at은 오늘 이후 날짜로 둔다.")
$docLines.Add("2. contact_method에는 내부 공유용 별칭이나 연락 경로만 적고 비밀번호, API 키, Steam Guard 코드는 넣지 않는다.")
$docLines.Add("3. ApplyExternalReviewerRoster.ps1를 실행해 EXTERNAL_REVIEW_TRACKER.tsv에 반영한다.")
$docLines.Add("4. WriteExternalReviewerPackets.ps1와 WriteExternalReviewOutreachQueue.ps1가 갱신한 패킷과 큐를 확인한다.")
$docLines.Add("")
$docLines.Add("## 명단")
$docLines.Add("")
$docLines.Add("| ID | 역할 | 권장 프로필 | 리뷰어 | 연락 경로 | 마감 |")
$docLines.Add("| --- | --- | --- | --- | --- | --- |")
foreach ($row in $rosterRows) {
    $docLines.Add("| $(Escape-MarkdownCell $row.id) | $(Escape-MarkdownCell $row.role) | $(Escape-MarkdownCell $row.reviewer_profile) | $(Escape-MarkdownCell $row.reviewer_alias) | $(Escape-MarkdownCell $row.contact_method) | $(Escape-MarkdownCell $row.due_at) |")
}
$docLines.Add("")
$docLines.Add("## 검증 명령")
$docLines.Add("")
$docLines.Add('```powershell')
$docLines.Add(".\Tools\ValidateExternalReviewerRoster.ps1")
$docLines.Add(".\Tools\ApplyExternalReviewerRoster.ps1")
$docLines.Add(".\Tools\ValidateExternalReviewerPackets.ps1 -RequireAssigned")
$docLines.Add('```')
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $docLines -Encoding UTF8

Assert-NoApiKeyPattern -Paths @($RosterPath, $OutputPath)

Write-Host "External reviewer roster written: $RosterPath"
Write-Host "External reviewer roster summary written: $OutputPath"
Write-Host "Roster status: assigned $assigned/$($rosterRows.Count), missing $missing"
