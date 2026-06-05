param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$PacketRoot,
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

function Write-TextFile {
    param(
        [string]$Path,
        [object]$Lines
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)
    Set-Content -LiteralPath (ConvertTo-LongPath -Path $Path) -Value $Lines -Encoding UTF8
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Format-TsvCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }
    return $Text.Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Get-ValueOrPlaceholder {
    param(
        [string]$Value,
        [string]$Placeholder
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Placeholder
    }
    return $Value.Trim()
}

function Assert-NoApiKeyPattern {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $path))) {
            continue
        }
        $matches = Select-String -LiteralPath (ConvertTo-LongPath -Path $path) -Pattern $ApiKeyPattern -ErrorAction SilentlyContinue
        if ($matches) {
            throw "Reviewer packet contains an API key pattern: $path"
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
if ([string]::IsNullOrWhiteSpace($PacketRoot)) {
    $PacketRoot = Join-Path $EvidenceRoot "ReviewerPackets"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_PACKETS.md"
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    throw "Missing external review tracker: $TrackerPath"
}

Ensure-Directory -Path $PacketRoot
$rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
$packetRows = New-Object System.Collections.Generic.List[object]
$textFiles = New-Object System.Collections.Generic.List[string]

foreach ($row in $rows) {
    $packetId = [string]$row.id
    if ([string]::IsNullOrWhiteSpace($packetId)) {
        continue
    }

    $packetPath = Join-Path $PacketRoot $packetId
    Ensure-Directory -Path $packetPath

    $reviewer = Get-ValueOrPlaceholder -Value ([string]$row.reviewer_alias) -Placeholder "미배정"
    $contact = Get-ValueOrPlaceholder -Value ([string]$row.contact_method) -Placeholder "미정"
    $dueAt = Get-ValueOrPlaceholder -Value ([string]$row.due_at) -Placeholder "미정"
    $packageName = Get-ValueOrPlaceholder -Value ([string]$row.package) -Placeholder "미정"
    $briefFile = Get-ValueOrPlaceholder -Value ([string]$row.brief_file) -Placeholder "ReviewBriefs"
    $evidencePath = Get-ValueOrPlaceholder -Value ([string]$row.evidence_path) -Placeholder "EvidenceDrop"
    $requiredEvidence = Get-ValueOrPlaceholder -Value ([string]$row.required_evidence) -Placeholder "담당 브리프 참고"
    $validationCommand = Get-ValueOrPlaceholder -Value ([string]$row.validation_command) -Placeholder "RUN_EVIDENCE_AUDIT.bat"
    $exitCriteria = Get-ValueOrPlaceholder -Value ([string]$row.exit_criteria) -Placeholder "담당 브리프 완료 기준"
    $nextAction = Get-ValueOrPlaceholder -Value ([string]$row.next_action) -Placeholder "담당자 배정 후 초대 발송"
    $isPlaytestPacket = $packetId -match "^PT-"
    $sessionId = $packetId.ToLowerInvariant() -replace "^pt-", "session-"
    $playtestBundleCommand = "Tools\NewPlaytestEvidenceBundle.ps1 -SessionId `"$sessionId`" -EvidenceRoot `"EvidenceDrop\Playtest`" -ObservationFormPath `"<filled form>`""

    $readmePath = Join-Path $packetPath "README.md"
    $invitePath = Join-Path $packetPath "INVITE.txt"
    $checklistPath = Join-Path $packetPath "ACCEPTANCE_CHECKLIST.tsv"
    $returnChecklistPath = Join-Path $packetPath "RETURN_CHECKLIST.tsv"
    $sourceBriefPath = Join-Path $packetPath "SOURCE_BRIEF.md"
    $calibrationPath = Join-Path $packetPath "DECISION_CALIBRATION.tsv"

    $readmeLines = New-Object System.Collections.Generic.List[string]
    $readmeLines.Add("# 외부 리뷰어 전달 패킷 $packetId")
    $readmeLines.Add("")
    $readmeLines.Add("- 역할: $($row.role)")
    $readmeLines.Add("- 리뷰어: $reviewer")
    $readmeLines.Add("- 연락 경로: $contact")
    $readmeLines.Add("- 마감: $dueAt")
    $readmeLines.Add("- 전달 패키지: $packageName")
    $readmeLines.Add("- 원본 브리프: $briefFile")
    $readmeLines.Add("- 제출 위치: $evidencePath")
    $readmeLines.Add("- 현재 증거 상태: $($row.evidence_status)")
    $readmeLines.Add("")
    $readmeLines.Add("## 해야 할 일")
    $readmeLines.Add("")
    $readmeLines.Add("- SOURCE_BRIEF.md를 먼저 읽고, 담당 범위 밖의 판단은 별도 이슈로 남긴다.")
    $readmeLines.Add("- DECISION_CALIBRATION.tsv로 4점 이상, 3점, 차단 기준을 맞춘다.")
    $readmeLines.Add("- COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv에서 담당 품질 영역과 연결된 기존 자동 QA, 스모크 캡처, 상점 자료를 확인한다.")
    $readmeLines.Add("- 실제 실행, 관찰, 캡처, 녹화, 작성 양식만 증거로 제출한다.")
    $readmeLines.Add("- 증거는 $evidencePath 아래에 넣는다.")
    if ($isPlaytestPacket) {
        $readmeLines.Add("- 플레이테스트 세션은 NewPlaytestEvidenceBundle.ps1로 최신 피드백과 support bundle을 한 번에 묶는다.")
    }
    $readmeLines.Add("- 문제가 발견되면 EXTERNAL_ISSUE_REGISTER.tsv에 재현 단계와 심각도를 남긴다.")
    $readmeLines.Add("- 증거를 넣은 뒤 RUN_EVIDENCE_AUDIT.bat 또는 검증 명령을 실행한다.")
    $readmeLines.Add("- 반환 전 RETURN_CHECKLIST.tsv를 채워 누락 증거와 비밀정보 포함 여부를 한 번 더 확인한다.")
    $readmeLines.Add("")
    $readmeLines.Add("## 제출해야 할 증거")
    $readmeLines.Add("")
    foreach ($item in ($requiredEvidence -split "\s*,\s*")) {
        if (-not [string]::IsNullOrWhiteSpace($item)) {
            $readmeLines.Add("- $item")
        }
    }
    $readmeLines.Add("")
    if ($isPlaytestPacket) {
        $readmeLines.Add("## 플레이테스트 세션 수집")
        $readmeLines.Add("")
        $readmeLines.Add('```powershell')
        $readmeLines.Add($playtestBundleCommand)
        $readmeLines.Add('```')
        $readmeLines.Add("")
    }
    $readmeLines.Add("## 검증 명령")
    $readmeLines.Add("")
    $readmeLines.Add('```powershell')
    $readmeLines.Add($validationCommand)
    $readmeLines.Add('```')
    $readmeLines.Add("")
    $readmeLines.Add("## 완료 기준")
    $readmeLines.Add("")
    $readmeLines.Add("- $exitCriteria")
    $readmeLines.Add("")
    $readmeLines.Add("## 다음 조치")
    $readmeLines.Add("")
    $readmeLines.Add("- $nextAction")
    $readmeLines.Add("")
    $readmeLines.Add("## 금지 자료")
    $readmeLines.Add("")
    $readmeLines.Add("- API 키, Steam 비밀번호, Steam Guard 코드, 결제 정보")
    $readmeLines.Add("- 참가자가 공개에 동의하지 않은 실명, 연락처, 학교/직장 식별 정보")
    $readmeLines.Add("- 내부 계정 보안 질문, 개인 인증 화면, 원본 비밀 로그")
    Write-TextFile -Path $readmePath -Lines $readmeLines

    $inviteLines = @(
        "제목: 겉!=속 외부 검토 요청 - $($row.role)",
        "",
        "안녕하세요.",
        "",
        "겉!=속를 USD 5 이상 유료 출시 후보로 판단하기 위한 외부 검토를 부탁드립니다.",
        "담당 항목은 $($row.role)이고, 제출 위치는 $evidencePath 입니다.",
        "먼저 이 패킷의 README.md와 SOURCE_BRIEF.md를 읽은 뒤 실제 실행 증거와 작성 양식을 제출해 주세요.",
        "점수나 보류 판단은 DECISION_CALIBRATION.tsv의 공통 기준에 맞춰 주세요.",
        "품질 점수를 매길 때는 COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv의 기존 자동 QA와 캡처 경로를 함께 확인해 주세요.",
        "반환 전 RETURN_CHECKLIST.tsv를 채워 누락 증거와 비밀정보 포함 여부를 확인해 주세요.",
        "",
        "완료 기준:",
        "$exitCriteria",
        "",
        "필수 증거:",
        "$requiredEvidence",
        "",
        "검토 후 RUN_EVIDENCE_AUDIT.bat 또는 아래 명령을 실행해 주세요.",
        $validationCommand,
        "",
        "API 키, Steam 계정 비밀번호, Steam Guard 코드, 개인 연락처 원문은 어떤 파일에도 넣지 말아 주세요."
    )
    if ($isPlaytestPacket) {
        $inviteLines += @(
            "",
            "플레이테스트 세션은 아래 명령으로 최신 피드백과 support bundle을 한 번에 묶어 주세요.",
            $playtestBundleCommand
        )
    }
    Write-TextFile -Path $invitePath -Lines $inviteLines

    $checklistLines = @(
        "item`tstatus`tevidence`tnotes",
        "reviewer_confirmed`topen`t`t리뷰어가 담당 범위를 수락했는지 확인",
        "package_opened`topen`t`t전달 패키지를 열 수 있는지 확인",
        "brief_read`topen`tSOURCE_BRIEF.md`t담당 브리프를 읽었는지 확인",
        "calibration_read`topen`tDECISION_CALIBRATION.tsv`t공통 판정 기준을 읽었는지 확인",
        "evidence_added`topen`t$evidencePath`t실제 증거 파일을 제출 위치에 넣었는지 확인",
        "validation_ran`topen`t$validationCommand`t검증 명령 또는 감사 배치를 실행했는지 확인",
        "issues_registered`topen`tEXTERNAL_ISSUE_REGISTER.tsv`tP2 이상 이슈를 등록했는지 확인",
        "no_secrets`topen`t`tAPI 키와 계정 비밀번호가 없음을 확인",
        "ready_for_import`topen`t`t원본 프로젝트로 수입해도 되는 상태인지 확인"
    )
    if ($isPlaytestPacket) {
        $checklistLines += "evidence_bundle_created`topen`t$playtestBundleCommand`tNewPlaytestEvidenceBundle.ps1로 피드백과 support bundle을 세션 폴더에 묶었는지 확인"
    }
    Write-TextFile -Path $checklistPath -Lines $checklistLines

    $returnChecklistLines = @(
        "item`tstatus`tevidence`tnotes",
        "required_evidence_present`topen`t$evidencePath`tREADME.md의 제출해야 할 증거가 모두 있는지 확인",
        "filled_forms_renamed`topen`t$evidencePath`tTEMPLATE 또는 REFERENCE 이름의 미작성 파일을 증거로 제출하지 않았는지 확인",
        "quality_index_checked`topen`tEvidenceDrop\COMMERCIAL_QUALITY_EVIDENCE_INDEX.tsv`t담당 영역의 기존 자동 QA와 캡처 경로를 확인했는지 확인",
        "raw_feedback_or_media_present`topen`t$evidencePath`t플레이테스트 원문, 캡처, 녹화, PDF 등 실제 관찰 자료가 있는지 확인",
        "quality_scorecard_updated`topen`tEvidenceDrop\COMMERCIAL_QUALITY_SCORECARD.tsv`t담당 범위가 품질 점수표에 반영됐는지 확인, 해당 없으면 n/a",
        "issue_register_updated`topen`tEvidenceDrop\EXTERNAL_ISSUE_REGISTER.tsv`tP2 이상 이슈와 재현 단계가 등록됐는지 확인",
        "validation_report_saved`topen`t$validationCommand`t검증 명령 실행 결과 또는 RUN_EVIDENCE_AUDIT.bat 결과를 저장했는지 확인",
        "secret_scan_clean`topen`t`tAPI 키, Steam 비밀번호, Steam Guard 코드, 개인 연락처 원문이 없는지 확인",
        "return_scope_clean`topen`tEvidenceDrop`t반환 폴더가 EvidenceDrop 중심이며 계정/캐시/개인 다운로드를 포함하지 않는지 확인",
        "ready_to_return`topen`t`t원본 프로젝트로 수입해도 되는 상태인지 확인"
    )
    if ($isPlaytestPacket) {
        $returnChecklistLines += "evidence_bundle_created`topen`tPLAYTEST_EVIDENCE_BUNDLE.json`t자동 수집 요약 파일과 SESSION_QA.md가 세션 폴더에 있는지 확인"
    }
    Write-TextFile -Path $returnChecklistPath -Lines $returnChecklistLines

    $briefSourcePath = Join-Path $EvidenceRoot $briefFile
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $briefSourcePath)) {
        Copy-Item -LiteralPath (ConvertTo-LongPath -Path $briefSourcePath) -Destination (ConvertTo-LongPath -Path $sourceBriefPath) -Force
    }
    else {
        Write-TextFile -Path $sourceBriefPath -Lines @(
            "# 원본 브리프 누락",
            "",
            "- 예상 브리프: $briefFile",
            "- 조치: WriteExternalReviewBriefs.ps1를 다시 실행한다."
        )
    }

    $sourceCalibrationPath = Join-Path $EvidenceRoot "ReviewBriefs\REVIEW_DECISION_CALIBRATION.tsv"
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path $sourceCalibrationPath)) {
        Copy-Item -LiteralPath (ConvertTo-LongPath -Path $sourceCalibrationPath) -Destination (ConvertTo-LongPath -Path $calibrationPath) -Force
    }
    else {
        Write-TextFile -Path $calibrationPath -Lines @(
            "area`tprice_ready_4_or_5`tborderline_3`tblocker_or_2_or_less`trequired_evidence",
            "missing`tWriteExternalReviewBriefs.ps1를 다시 실행한다.`tWriteExternalReviewBriefs.ps1를 다시 실행한다.`tWriteExternalReviewBriefs.ps1를 다시 실행한다.`tReviewBriefs\REVIEW_DECISION_CALIBRATION.tsv"
        )
    }

    $textFiles.Add($readmePath) | Out-Null
    $textFiles.Add($invitePath) | Out-Null
    $textFiles.Add($checklistPath) | Out-Null
    $textFiles.Add($returnChecklistPath) | Out-Null
    $textFiles.Add($sourceBriefPath) | Out-Null
    $textFiles.Add($calibrationPath) | Out-Null

    $packetRows.Add([pscustomobject]@{
        id = $packetId
        role = [string]$row.role
        packet_path = $packetPath
        readme = $readmePath
        invite = $invitePath
        checklist = $checklistPath
        return_checklist = $returnChecklistPath
        source_brief = $sourceBriefPath
        evidence_path = $evidencePath
        validation_command = $validationCommand
        invite_status = [string]$row.invite_status
        evidence_status = [string]$row.evidence_status
    }) | Out-Null
}

$manifestPath = Join-Path $PacketRoot "REVIEWER_PACKET_MANIFEST.tsv"
$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("id`trole`tpacket_path`tevidence_path`tvalidation_command`tinvite_status`tevidence_status")
foreach ($packet in $packetRows) {
    $manifestLines.Add((
        (Format-TsvCell $packet.id),
        (Format-TsvCell $packet.role),
        (Format-TsvCell $packet.packet_path),
        (Format-TsvCell $packet.evidence_path),
        (Format-TsvCell $packet.validation_command),
        (Format-TsvCell $packet.invite_status),
        (Format-TsvCell $packet.evidence_status)
    ) -join "`t")
}
Write-TextFile -Path $manifestPath -Lines $manifestLines
$textFiles.Add($manifestPath) | Out-Null

$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add("# 외부 리뷰어 전달 패킷")
$summaryLines.Add("")
$summaryLines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$summaryLines.Add("- 증거 루트: $EvidenceRoot")
$summaryLines.Add("- 패킷 폴더: $PacketRoot")
$summaryLines.Add("- 패킷 수: $($packetRows.Count)")
$summaryLines.Add("- 추적 TSV: $TrackerPath")
$summaryLines.Add("")
$summaryLines.Add("이 문서는 외부 리뷰어에게 보낼 역할별 전달 패킷의 생성 결과다. 패킷은 안내와 체크리스트이며, 실제 리뷰 증거로 세지 않는다.")
$summaryLines.Add("")
$summaryLines.Add("## 운영 순서")
$summaryLines.Add("")
$summaryLines.Add("1. EXTERNAL_REVIEWER_ROSTER.tsv에 reviewer_alias, contact_method, due_at을 채운 뒤 ApplyExternalReviewerRoster.ps1로 추적표에 반영한다.")
$summaryLines.Add("2. 이 도구를 다시 실행해 각 리뷰어 패킷을 최신화한다.")
$summaryLines.Add("3. 각 패킷의 INVITE.txt, README.md, SOURCE_BRIEF.md, DECISION_CALIBRATION.tsv를 담당자에게 보낸다.")
$summaryLines.Add("4. 담당자가 증거를 넣으면 RUN_EVIDENCE_AUDIT.bat를 실행하고 RETURN_CHECKLIST.tsv를 채운다.")
$summaryLines.Add("5. 돌아온 EvidenceDrop은 ImportExternalEvidenceDrop.ps1로 미리보기 후 수입한다.")
$summaryLines.Add("")
$summaryLines.Add("## 패킷")
$summaryLines.Add("")
$summaryLines.Add("| ID | 역할 | 패킷 | 제출 위치 | 검증 명령 |")
$summaryLines.Add("| --- | --- | --- | --- | --- |")
foreach ($packet in $packetRows) {
    $summaryLines.Add("| $(Escape-MarkdownCell $packet.id) | $(Escape-MarkdownCell $packet.role) | $(Escape-MarkdownCell $packet.packet_path) | $(Escape-MarkdownCell $packet.evidence_path) | $(Escape-MarkdownCell $packet.validation_command) |")
}
$summaryLines.Add("")
$summaryLines.Add("## 검증 명령")
$summaryLines.Add("")
$summaryLines.Add('```powershell')
$summaryLines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewerPackets.ps1")
$summaryLines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalReviewTracker.ps1")
$summaryLines.Add(".\99_GroupProject\Interviewee1UnityAvatarChat\Tools\ValidateExternalEvidence.ps1")
$summaryLines.Add('```')
$summaryLines.Add("")
$summaryLines.Add("## 보안")
$summaryLines.Add("")
$summaryLines.Add("- 패킷에는 API 키, Steam 비밀번호, Steam Guard 코드, 개인 인증 정보를 넣지 않는다.")
$summaryLines.Add("- 패킷은 증거 수집 안내이며, 최종 출시 증거로는 실제 실행 결과와 작성 양식만 인정한다.")
Write-TextFile -Path $OutputPath -Lines $summaryLines
$textFiles.Add($OutputPath) | Out-Null

Assert-NoApiKeyPattern -Paths $textFiles.ToArray()

Write-Host "External reviewer packets written: $PacketRoot"
Write-Host "External reviewer packet summary written: $OutputPath"
Write-Host "Reviewer packets: $($packetRows.Count)"


