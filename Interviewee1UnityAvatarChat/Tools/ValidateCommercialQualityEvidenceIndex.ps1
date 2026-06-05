param(
    [string]$IndexPath,
    [string]$OutputPath,
    [string]$EvidenceRoot,
    [switch]$RequireComplete
)

$ErrorActionPreference = "Stop"
$RequiredAreas = @(
    "core_loop",
    "writing",
    "readability",
    "controls",
    "trust_privacy",
    "art_presentation",
    "trailer_store",
    "stability_package"
)
$RequiredBacklogIds = @(
    "INT-PLAYTEST-001",
    "INT-ACCESS-001",
    "INT-ART-001",
    "INT-TRAILER-001",
    "INT-LEGAL-001",
    "INT-QUALITY-001"
)
$SecretPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}|BEGIN\s+(RSA\s+)?PRIVATE\s+KEY|Authorization:\s*Bearer\s+[A-Za-z0-9._-]+|(?i)(password|steam_guard|mobile_secret)\s*[:=]"

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

    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Resolve-RelativeEvidence {
    param(
        [string]$Reference,
        [string]$ProjectRoot,
        [string]$EvidenceRootPath
    )

    if ([string]::IsNullOrWhiteSpace($Reference)) {
        return $null
    }
    if ($Reference -match '^(?i:https?://|steam://)') {
        return $null
    }
    if ([System.IO.Path]::IsPathRooted($Reference)) {
        return $null
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($Reference -match '^(?i:EvidenceDrop)[\\/]') {
        $withoutRoot = $Reference.Substring("EvidenceDrop".Length).TrimStart("\", "/")
        $candidates.Add((Join-Path $EvidenceRootPath $withoutRoot)) | Out-Null
    }
    $candidates.Add((Join-Path $ProjectRoot $Reference)) | Out-Null
    $candidates.Add((Join-Path $EvidenceRootPath $Reference)) | Out-Null
    if ($Reference -match '^(?i:Docs)[\\/]') {
        $withoutRoot = $Reference.Substring("Docs".Length).TrimStart("\", "/")
        $candidates.Add((Join-Path $ProjectRoot (Join-Path "ObserverDocs" $withoutRoot))) | Out-Null
        $candidates.Add((Join-Path $ProjectRoot (Join-Path "Game\Interviewee1UnityAvatarChat\Docs" $withoutRoot))) | Out-Null
    }
    if ($Reference -match '^(?i:Marketing)[\\/]') {
        $withoutRoot = $Reference.Substring("Marketing".Length).TrimStart("\", "/")
        $candidates.Add((Join-Path $ProjectRoot (Join-Path "Game\Interviewee1UnityAvatarChat\Marketing" $withoutRoot))) | Out-Null
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $candidate)) {
            return $candidate
        }
    }
    return $null
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $EvidenceRoot = Join-Path $projectRoot "EvidenceDrop"
    }
    else {
        $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
    }
}
if ([string]::IsNullOrWhiteSpace($IndexPath)) {
    $IndexPath = Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $OutputPath = Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX_QA.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX_QA.md"
    }
}

$issues = New-Object System.Collections.Generic.List[string]
$rows = @()
$resolvedCount = 0
$externalNeededRows = 0
$secretMatches = @()

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $IndexPath))) {
    $issues.Add("인덱스 파일 없음: $IndexPath") | Out-Null
}
else {
    $secretMatches = @(Select-String -LiteralPath (ConvertTo-LongPath -Path $IndexPath) -Pattern $SecretPattern -ErrorAction SilentlyContinue)
    $rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $IndexPath) -Encoding UTF8)
    if ($rows.Count -eq 0) {
        $issues.Add("인덱스 행이 없다.") | Out-Null
    }
    else {
        $columns = @($rows[0].PSObject.Properties.Name)
        foreach ($column in @("area", "evidence_type", "evidence_path", "review_use", "external_needed", "backlog_id", "acceptance_gate", "notes")) {
            if ($columns -notcontains $column) {
                $issues.Add("필수 열 누락: $column") | Out-Null
            }
        }

        foreach ($area in $RequiredAreas) {
            if (-not ($rows | Where-Object { $_.area -eq $area })) {
                $issues.Add("필수 품질 영역 누락: $area") | Out-Null
            }
        }

        foreach ($backlogId in $RequiredBacklogIds) {
            if (-not ($rows | Where-Object { $_.backlog_id -eq $backlogId })) {
                $issues.Add("필수 백로그 연결 누락: $backlogId") | Out-Null
            }
        }

        foreach ($row in $rows) {
            $area = ([string]$row.area).Trim()
            $path = ([string]$row.evidence_path).Trim()
            $externalNeeded = ([string]$row.external_needed).Trim().ToLowerInvariant()
            $backlogId = ([string]$row.backlog_id).Trim()
            $acceptanceGate = ([string]$row.acceptance_gate).Trim()
            if ([string]::IsNullOrWhiteSpace($area)) {
                $issues.Add("area 누락 행") | Out-Null
            }
            if ([string]::IsNullOrWhiteSpace($backlogId)) {
                $issues.Add("backlog_id 누락: $area") | Out-Null
            }
            elseif ($backlogId -notmatch '^INT-[A-Z]+-\d{3}$') {
                $issues.Add("backlog_id 형식 오류: $area = $backlogId") | Out-Null
            }
            if ([string]::IsNullOrWhiteSpace($acceptanceGate)) {
                $issues.Add("acceptance_gate 누락: $area") | Out-Null
            }
            if ($externalNeeded -notin @("yes", "no")) {
                $issues.Add("external_needed 값 오류: $area = $externalNeeded") | Out-Null
            }
            if ([string]::IsNullOrWhiteSpace($path)) {
                $issues.Add("evidence_path 누락: $area") | Out-Null
            }
            elseif ([System.IO.Path]::IsPathRooted($path) -or $path -match '^(?i:https?://|steam://)') {
                $issues.Add("재현 불가 evidence_path: $area = $path") | Out-Null
            }
            else {
                $resolved = Resolve-RelativeEvidence -Reference $path -ProjectRoot $projectRoot -EvidenceRootPath $EvidenceRoot
                if ($null -eq $resolved) {
                    $issues.Add("evidence_path 확인 실패: $area = $path") | Out-Null
                }
                else {
                    $resolvedCount++
                }
            }

            if ($externalNeeded -eq "yes") {
                $externalNeededRows++
                if ([string]::IsNullOrWhiteSpace($backlogId) -or [string]::IsNullOrWhiteSpace($acceptanceGate)) {
                    $issues.Add("외부 확인 행의 백로그/종료 조건 누락: $area") | Out-Null
                }
            }
        }
    }
    if ($secretMatches.Count -gt 0) {
        $issues.Add("비밀정보 형태 문자열 발견: $($secretMatches.Count)") | Out-Null
    }
}

$status = if ($issues.Count -eq 0) { "완료" } else { "차단" }
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 상업 품질 증거 인덱스 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 인덱스: $IndexPath")
$lines.Add("- 행: $($rows.Count)")
$lines.Add("- 확인된 증거 경로: $resolvedCount")
$lines.Add("- 외부 확인 필요 행: $externalNeededRows")
$lines.Add("- 문제: $($issues.Count)")
$lines.Add("- 비밀정보 패턴: $($secretMatches.Count)")
$lines.Add("")
$lines.Add("이 QA는 품질 점수표 작성을 돕는 증거 인덱스의 형식과 로컬 경로만 확인한다. 외부 리뷰어가 직접 채운 `COMMERCIAL_QUALITY_SCORECARD.tsv`를 대체하지 않는다.")
$lines.Add("")
if ($issues.Count -gt 0) {
    $lines.Add("## 문제")
    $lines.Add("")
    foreach ($issue in $issues) {
        $lines.Add("- $issue")
    }
    $lines.Add("")
}
$lines.Add("## 인덱스 행")
$lines.Add("")
$lines.Add("| 영역 | 증거 유형 | 경로 | 외부 확인 | 백로그 | 종료 조건 |")
$lines.Add("| --- | --- | --- | --- | --- | --- |")
foreach ($row in $rows) {
    $lines.Add("| $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.evidence_type) | $(Escape-MarkdownCell $row.evidence_path) | $(Escape-MarkdownCell $row.external_needed) | $(Escape-MarkdownCell $row.backlog_id) | $(Escape-MarkdownCell $row.acceptance_gate) |")
}

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $lines -Encoding UTF8

Write-Host "Commercial quality evidence index QA written: $OutputPath"
Write-Host "Status: $status, rows: $($rows.Count), paths: $resolvedCount, issues: $($issues.Count)"

if ($RequireComplete -and $issues.Count -gt 0) {
    throw "Commercial quality evidence index QA failed with $($issues.Count) issue(s)."
}
