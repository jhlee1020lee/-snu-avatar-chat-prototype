param(
    [string]$EvidenceRoot,
    [string]$OutputPath,
    [string]$SummaryPath
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

function Ensure-Directory {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
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
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Add-Evidence {
    param(
        [string]$Area,
        [string]$EvidenceType,
        [string]$EvidencePath,
        [string]$ReviewUse,
        [string]$ExternalNeeded,
        [string]$BacklogId,
        [string]$AcceptanceGate,
        [string]$Notes
    )

    $script:rows.Add([pscustomobject]@{
        area = $Area
        evidence_type = $EvidenceType
        evidence_path = $EvidencePath
        review_use = $ReviewUse
        external_needed = $ExternalNeeded
        backlog_id = $BacklogId
        acceptance_gate = $AcceptanceGate
        notes = $Notes
    }) | Out-Null
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
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv"
}
if ([string]::IsNullOrWhiteSpace($SummaryPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $SummaryPath = Join-Path $EvidenceRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.md"
    }
    else {
        $SummaryPath = Join-Path $docsRoot "COMMERCIAL_QUALITY_EVIDENCE_INDEX.md"
    }
}

$rows = New-Object System.Collections.Generic.List[object]

Add-Evidence "core_loop" "runtime_qa" "Docs/ACCESSIBILITY_AUTOMATION_QA.md" "5문답 완료, 마무리 카드, 기록 저장 플로우 런타임 QA를 확인" "yes" "INT-PLAYTEST-001" "PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 5/5, P0 0, P1 0" "외부 플레이테스트 5세션으로 체감 완결감을 검증해야 한다."
Add-Evidence "core_loop" "screenshot" "Marketing/Screenshots/06-closing-card.png" "마무리 카드가 실제 세션 종료 화면으로 보이는지 확인" "yes" "INT-PLAYTEST-001" "PLAYTEST_EVIDENCE_SUMMARY.md 완성 세션 5/5, P0 0, P1 0" "외부 참가자가 이 화면을 이해했는지 관찰 양식으로 받아야 한다."
Add-Evidence "writing" "content_qa" "Docs/UNITY_LOCAL_FALLBACK_CONTENT_QA.md" "서버 없이도 내장 답변이 근거 기반으로 나오는지 확인" "yes" "INT-QUALITY-001" "COMMERCIAL_QUALITY_SCORECARD.tsv writing 점수 4 이상, reviewer/evidence 채움" "말투가 사람책 인터뷰로 느껴지는지는 외부 독해 평가가 필요하다."
Add-Evidence "writing" "content_qa" "Docs/GENERATED_MEMORY_POLICY_QA.md" "생성 기억과 답변 정책이 과장 없이 유지되는지 확인" "yes" "INT-QUALITY-001" "COMMERCIAL_QUALITY_SCORECARD.tsv writing/trust_privacy 점수 4 이상" "외부 리뷰어가 실제 답변 로그를 보고 어색함을 표시해야 한다."
Add-Evidence "readability" "accessibility_qa" "Docs/ACCESSIBILITY_AUTOMATION_QA.md" "긴 답변, 큰 글자, 스크롤, 단축키 접근성 자동 검증 확인" "yes" "INT-ACCESS-001" "ACCESSIBILITY_OBSERVATION_FORM.md와 화면/녹화 증거 등록" "Windows 확대/고대비/실제 입력 장치 관찰 증거가 아직 필요하다."
Add-Evidence "readability" "screenshot" "Marketing/Screenshots/04-dialogue-scroll.png" "긴 답변이 대사창 안에서 읽히고 스크롤 단서가 보이는지 확인" "yes" "INT-ACCESS-001" "ACCESSIBILITY_OBSERVATION_FORM.md 읽기 난이도 통과" "외부 접근성 관찰 양식에 읽기 난이도를 기록해야 한다."
Add-Evidence "controls" "accessibility_qa" "Docs/ACCESSIBILITY_AUTOMATION_QA.md" "키보드, 게임패드, 패널 충돌 방지, 기록 삭제 확인 흐름 확인" "yes" "INT-ACCESS-001" "ACCESSIBILITY_OBSERVATION_FORM.md 키보드/입력 장치 항목 통과" "키보드만 사용하는 실제 사용자 관찰 증거가 필요하다."
Add-Evidence "controls" "screenshot" "Marketing/Screenshots/08-record-delete.png" "기록함 삭제 확인 화면과 파괴적 조작 확인 흐름 검토" "yes" "INT-PLAYTEST-001" "외부 피드백에 기록 저장/삭제 P0/P1 없음" "외부 참가자가 기록 저장/삭제를 예측 가능하게 느꼈는지 확인해야 한다."
Add-Evidence "trust_privacy" "safety_qa" "Docs/STEAM_LEGAL_READINESS_QA.md" "개인정보, Steam/법무 자동 점검과 보안 문구 확인" "yes" "INT-LEGAL-001" "Steam 체크리스트, 개인정보 최종본, 테스트 브랜치 증거 등록" "최종 개인정보 문구와 Steam 관리자 증거가 별도로 필요하다."
Add-Evidence "trust_privacy" "screenshot" "Marketing/Screenshots/10-data-policy-delete.png" "저장 데이터 삭제 확인이 플레이어에게 명확히 보이는지 확인" "yes" "INT-LEGAL-001" "PRIVACY_NOTICE_FINAL.md와 데이터 삭제 화면 증거 등록" "법무/운영 검토자가 최종 문구를 확정해야 한다."
Add-Evidence "art_presentation" "visual_qa" "Marketing/VisualQuality/VISUAL_QUALITY_REPORT.tsv" "스크린샷과 Steam 자산의 밝기, 어두움, 보라색 잔상, 가장자리 복잡도 확인" "yes" "INT-ART-001" "ART_REVIEW_FORM.md와 이미지/PDF 근거 등록" "외부 아트 리뷰어가 작은 캡슐 판독성과 상점 첫인상을 확인해야 한다."
Add-Evidence "art_presentation" "steam_asset" "Marketing/SteamAssets/small_capsule_462x174.png" "작은 Steam 캡슐에서 제목과 분위기가 읽히는지 확인" "yes" "INT-ART-001" "작은 캡슐 판독성, 잘림, 첫인상 외부 리뷰 통과" "실제 상점 맥락에서 잘림/판독성 리뷰가 필요하다."
Add-Evidence "trailer_store" "trailer" "Marketing/Trailer/trailer_animatic_60s.mp4" "상점 트레일러 후보가 플레이 흐름을 설명하는지 확인" "yes" "INT-TRAILER-001" "TRAILER_FINAL_REVIEW_FORM.md, 최종 MP4, 자막 등록" "최종 라이브 플레이 기반 영상, 자막, 외부 트레일러 리뷰가 필요하다."
Add-Evidence "trailer_store" "store_copy" "Marketing/StoreCopy/STORE_COPY_QA_REPORT.tsv" "상점 문구가 실제 플레이와 개인정보 안내를 과장 없이 설명하는지 확인" "yes" "INT-TRAILER-001" "외부 리뷰 10초 이해도와 상점 기대치 통과" "외부 리뷰어가 10초 이해도와 상점 기대치를 검토해야 한다."
Add-Evidence "stability_package" "package_qa" "Docs/RELEASE_READINESS_REPORT.md" "자동 QA, 패키지, Steam 제출/스테이징 상태를 한눈에 확인" "no" "INT-QUALITY-001" "자동 실패 0, 보류 0, 공식 품질 점수표 완료" "외부 증거가 들어온 뒤 최종 게이트를 다시 실행해야 한다."
Add-Evidence "stability_package" "package_qa" "Docs/UNITY_BUILD_SYNC_QA.md" "현재 소스와 Unity 빌드 산출물 동기화 확인" "no" "INT-QUALITY-001" "코드 변경 후 빌드 동기화 통과" "코드 변경 후에는 재빌드와 스모크 재실행이 필요하다."

Ensure-Directory -Path (Split-Path -Parent $OutputPath)
Ensure-Directory -Path (Split-Path -Parent $SummaryPath)

$tsv = New-Object System.Collections.Generic.List[string]
$tsv.Add("area`tevidence_type`tevidence_path`treview_use`texternal_needed`tbacklog_id`tacceptance_gate`tnotes")
foreach ($row in $rows) {
    $tsv.Add((@(
        (Format-TsvCell $row.area),
        (Format-TsvCell $row.evidence_type),
        (Format-TsvCell $row.evidence_path),
        (Format-TsvCell $row.review_use),
        (Format-TsvCell $row.external_needed),
        (Format-TsvCell $row.backlog_id),
        (Format-TsvCell $row.acceptance_gate),
        (Format-TsvCell $row.notes)
    ) -join "`t"))
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $OutputPath) -Value $tsv -Encoding UTF8

$areaCount = @($rows | Select-Object -ExpandProperty area -Unique).Count
$externalCount = @($rows | Where-Object { $_.external_needed -eq "yes" }).Count
$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("# 상업 품질 증거 인덱스")
$summary.Add("")
$summary.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$summary.Add("- 인덱스 TSV: $OutputPath")
$summary.Add("- 품질 영역: $areaCount")
$summary.Add("- 증거 행: $($rows.Count)")
$summary.Add("- 외부 확인 필요 행: $externalCount")
$summary.Add("")
$summary.Add("이 인덱스는 공식 점수표를 대신하지 않는다. 외부 리뷰어가 `COMMERCIAL_QUALITY_SCORECARD.tsv`의 evidence 칸을 채울 때 기존 자동 QA, 스모크 캡처, 상점 자료를 빠르게 찾고 P1 백로그 종료 조건과 연결하기 위한 보조 자료다.")
$summary.Add("")
$summary.Add("| 영역 | 증거 유형 | 경로 | 리뷰 용도 | 외부 확인 | 백로그 | 종료 조건 |")
$summary.Add("| --- | --- | --- | --- | --- | --- | --- |")
foreach ($row in $rows) {
    $summary.Add("| $(Escape-MarkdownCell $row.area) | $(Escape-MarkdownCell $row.evidence_type) | $(Escape-MarkdownCell $row.evidence_path) | $(Escape-MarkdownCell $row.review_use) | $(Escape-MarkdownCell $row.external_needed) | $(Escape-MarkdownCell $row.backlog_id) | $(Escape-MarkdownCell $row.acceptance_gate) |")
}
$summary.Add("")
$summary.Add("## 검증 명령")
$summary.Add("")
$summary.Add('```powershell')
$summary.Add(".\Tools\ValidateCommercialQualityEvidenceIndex.ps1")
$summary.Add('```')
Set-Content -LiteralPath (ConvertTo-LongPath -Path $SummaryPath) -Value $summary -Encoding UTF8

Write-Host "Commercial quality evidence index written: $OutputPath"
Write-Host "Commercial quality evidence summary written: $SummaryPath"
Write-Host "Evidence rows: $($rows.Count), areas: $areaCount, external-needed rows: $externalCount"
