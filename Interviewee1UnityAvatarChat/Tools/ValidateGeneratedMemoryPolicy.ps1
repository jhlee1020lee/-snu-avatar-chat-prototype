param(
    [string]$ServerPath,
    [string]$PersonaPath,
    [string]$ReadmePath,
    [string]$GeneratedMemoryPath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Add-Result {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Evidence
    )

    $script:results.Add([pscustomobject]@{
        Item = $Item
        Status = $Status
        Evidence = $Evidence
    }) | Out-Null
}

function Read-Utf8Text {
    param([string]$Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$docsRoot = Join-Path $projectRoot "Docs"

if ([string]::IsNullOrWhiteSpace($ServerPath)) {
    $ServerPath = Join-Path $serverRoot "server.js"
}
if ([string]::IsNullOrWhiteSpace($PersonaPath)) {
    $PersonaPath = Join-Path $serverRoot "data\persona.json"
}
if ([string]::IsNullOrWhiteSpace($ReadmePath)) {
    $ReadmePath = Join-Path $serverRoot "README.md"
}
if ([string]::IsNullOrWhiteSpace($GeneratedMemoryPath)) {
    $GeneratedMemoryPath = Join-Path $serverRoot "data\generated_memory.jsonl"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "GENERATED_MEMORY_POLICY_QA.md"
}

foreach ($path in @($ServerPath, $PersonaPath, $ReadmePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

$server = Read-Utf8Text -Path $ServerPath
$persona = Read-Utf8Text -Path $PersonaPath | ConvertFrom-Json
$readme = Read-Utf8Text -Path $ReadmePath
$results = New-Object System.Collections.Generic.List[object]
$failures = 0

if ($server -match "const\s+INCLUDE_UNREVIEWED_MEMORY_CONTEXT\s*=\s*/\^\(1\|true\|yes\)\$/i\.test\(process\.env\.INCLUDE_UNREVIEWED_MEMORY_CONTEXT\s*\|\|\s*`"`"\)") {
    Add-Result -Item "미검토 확장 기록 기본값" -Status "통과" -Evidence "INCLUDE_UNREVIEWED_MEMORY_CONTEXT는 명시적 환경 변수 없이는 false"
}
else {
    Add-Result -Item "미검토 확장 기록 기본값" -Status "실패" -Evidence "미검토 확장 기록 포함 설정이 명시적 opt-in으로 고정되어 있지 않다."
    $failures++
}

if ($server -match "function\s+isGeneratedMemoryContextEligible" -and
    $server -match "reviewStatus\s*===\s*`"approved`"" -and
    $server -match "INCLUDE_UNREVIEWED_MEMORY_CONTEXT\s*&&\s*reviewStatus\s*===\s*`"unreviewed`"") {
    Add-Result -Item "확장 기록 컨텍스트 필터" -Status "통과" -Evidence "approved만 기본 포함하고 unreviewed는 opt-in일 때만 포함"
}
else {
    Add-Result -Item "확장 기록 컨텍스트 필터" -Status "실패" -Evidence "확장 기록 컨텍스트 필터가 approved 기본 포함/미검토 opt-in 정책을 보장하지 않는다."
    $failures++
}

if ($server -match "loadGeneratedMemories[\s\S]+?\.filter\(isGeneratedMemoryContextEligible\)" -and
    $server -match "allGeneratedMemories\s*=\s*allStoredGeneratedMemories[\s\S]+?\.filter\(isGeneratedMemoryContextEligible\)") {
    Add-Result -Item "서버 답변 경로 적용" -Status "통과" -Evidence "일반 로드와 채팅 응답 경로가 같은 컨텍스트 필터를 사용"
}
else {
    Add-Result -Item "서버 답변 경로 적용" -Status "실패" -Evidence "일반 로드 또는 채팅 응답 경로에 확장 기록 컨텍스트 필터가 적용되지 않았다."
    $failures++
}

if ($server -match "\[`"approved`",\s*`"unreviewed`"\]\.includes\(record\.reviewStatus\s*\|\|\s*`"unreviewed`"\)") {
    Add-Result -Item "옛 미검토 포함 로직 제거" -Status "실패" -Evidence "server.js에 approved와 unreviewed를 함께 기본 포함하는 옛 로직이 남아 있다."
    $failures++
}
else {
    Add-Result -Item "옛 미검토 포함 로직 제거" -Status "통과" -Evidence "approved/unreviewed 동시 기본 포함 로직 없음"
}

$voiceExamples = @($persona.voiceExamples)
if ($voiceExamples.Count -ge 3 -and -not ($voiceExamples | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.text) })) {
    Add-Result -Item "말투 예시" -Status "통과" -Evidence "$($voiceExamples.Count)개 말투 예시 확인"
}
else {
    Add-Result -Item "말투 예시" -Status "실패" -Evidence "persona.json에 상용 답변 톤을 고정할 말투 예시가 3개 이상 필요하다."
    $failures++
}

$exampleText = ($voiceExamples | ForEach-Object { "$($_.situation) $($_.text)" }) -join "`n"
if ($exampleText -match "AI|인공지능|프로그램|UI|플레이테스트|\*\*|출처 부족|내부 기록") {
    Add-Result -Item "말투 예시 문구 품질" -Status "실패" -Evidence "말투 예시에 몰입을 깨는 제작/검증/메타 표현이 있다."
    $failures++
}
else {
    Add-Result -Item "말투 예시 문구 품질" -Status "통과" -Evidence "말투 예시에 AI식/검증용/마크다운 표현 없음"
}

$hasApprovedOnlyReadmePolicy = $readme.Contains("기록된 확장 답변은") -and
    $readme.Contains("검토된 항목만") -and
    $readme.Contains("일관성 메모로 사용")
$hasUnreviewedOptInReadmePolicy = $readme.Contains("INCLUDE_UNREVIEWED_MEMORY_CONTEXT=true")

if ($hasApprovedOnlyReadmePolicy -and $hasUnreviewedOptInReadmePolicy) {
    Add-Result -Item "운영 문서" -Status "통과" -Evidence "README.md에 approved 기본 정책과 unreviewed opt-in 방법 명시"
}
else {
    Add-Result -Item "운영 문서" -Status "실패" -Evidence "README.md에 확장 답변 검토 정책 또는 opt-in 환경 변수가 부족하다."
    $failures++
}

if (Test-Path -LiteralPath $GeneratedMemoryPath) {
    $records = @(Get-Content -LiteralPath $GeneratedMemoryPath -Encoding UTF8 |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object {
            try {
                $_ | ConvertFrom-Json
            }
            catch {
                throw "generated_memory.jsonl has invalid JSON line: $_"
            }
        })
    $activeUnreviewed = @($records | Where-Object { $_.status -ne "rejected" -and ($_.reviewStatus -eq "unreviewed" -or [string]::IsNullOrWhiteSpace([string]$_.reviewStatus)) }).Count
    $approved = @($records | Where-Object { $_.status -ne "rejected" -and $_.reviewStatus -eq "approved" }).Count
    Add-Result -Item "확장 기록 현황" -Status "통과" -Evidence "approved $approved, unreviewed $activeUnreviewed. 미검토 기록은 기본 컨텍스트에서 제외됨"
}
else {
    Add-Result -Item "확장 기록 현황" -Status "통과" -Evidence "generated_memory.jsonl 없음. 첫 확장 답변 생성 전 상태"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 확장 답변 검토 정책 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 서버: $ServerPath")
$lines.Add("- 페르소나: $PersonaPath")
$lines.Add("- 상태: $(if ($failures -eq 0) { "통과" } else { "실패" })")
$lines.Add("- 실패: $failures")
$lines.Add("")
$lines.Add("## 항목")
$lines.Add("")
$lines.Add("| 항목 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Item) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Evidence) |")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

if ($failures -gt 0) {
    throw "Generated memory policy QA failed with $failures issue(s). Report: $OutputPath"
}

Write-Host "Generated memory policy QA passed: $OutputPath"
