param(
    [string]$EvidenceRoot,
    [string]$TrackerPath,
    [string]$PacketRoot,
    [string]$ArchiveRoot,
    [string]$DocsPath
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
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-RelativePath {
    param(
        [string]$Root,
        [string]$Path
    )

    $rootFull = ([System.IO.Path]::GetFullPath($Root)) -replace '[\\/]+$', ''
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    if ($pathFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($prefix.Length)
    }
    return $pathFull
}

function Get-FileSha256 {
    param([string]$Path)

    (Get-FileHash -LiteralPath (ConvertTo-LongPath -Path $Path) -Algorithm SHA256 -ErrorAction Stop).Hash
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $EvidenceRoot = Join-Path $projectRoot "EvidenceDrop"
    }
    else {
        $EvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
    }
}
if ([string]::IsNullOrWhiteSpace($TrackerPath)) {
    $TrackerPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEW_TRACKER.tsv"
}
if ([string]::IsNullOrWhiteSpace($PacketRoot)) {
    $PacketRoot = Join-Path $EvidenceRoot "ReviewerPackets"
}
if ([string]::IsNullOrWhiteSpace($ArchiveRoot)) {
    $ArchiveRoot = Join-Path $EvidenceRoot "ReviewerPacketArchives"
}
if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    if (Test-Path -LiteralPath (ConvertTo-LongPath -Path (Join-Path $projectRoot "EvidenceDrop"))) {
        $DocsPath = Join-Path $EvidenceRoot "EXTERNAL_REVIEWER_PACKET_ARCHIVES.md"
    }
    else {
        $DocsPath = Join-Path $docsRoot "EXTERNAL_REVIEWER_PACKET_ARCHIVES.md"
    }
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $TrackerPath))) {
    throw "Missing external review tracker: $TrackerPath"
}
if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $PacketRoot))) {
    throw "Missing reviewer packet root: $PacketRoot"
}

Ensure-Directory -Path $ArchiveRoot
foreach ($existing in Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $ArchiveRoot) -File -Filter "*.zip" -ErrorAction SilentlyContinue) {
    Remove-Item -LiteralPath (ConvertTo-LongPath -Path $existing.FullName) -Force
}

$rows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $TrackerPath) -Encoding UTF8)
$archiveRows = New-Object System.Collections.Generic.List[object]
$requiredFiles = @(
    "README.md",
    "INVITE.txt",
    "ACCEPTANCE_CHECKLIST.tsv",
    "RETURN_CHECKLIST.tsv",
    "SOURCE_BRIEF.md",
    "DECISION_CALIBRATION.tsv"
)

foreach ($row in $rows) {
    $id = ([string]$row.id).Trim()
    if ([string]::IsNullOrWhiteSpace($id)) {
        continue
    }

    $packetPath = Join-Path $PacketRoot $id
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $packetPath))) {
        throw "Missing reviewer packet: $packetPath"
    }
    foreach ($file in $requiredFiles) {
        $requiredPath = Join-Path $packetPath $file
        if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $requiredPath))) {
            throw "Reviewer packet $id is missing $file"
        }
    }

    $archivePath = Join-Path $ArchiveRoot "$id.zip"
    $packetFiles = @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $packetPath) -File -Recurse -ErrorAction Stop)
    if ($packetFiles.Count -lt $requiredFiles.Count) {
        throw "Reviewer packet $id has too few files: $($packetFiles.Count)"
    }

    Compress-Archive -LiteralPath $packetFiles.FullName -DestinationPath $archivePath -Force
    $archiveItem = Get-Item -LiteralPath (ConvertTo-LongPath -Path $archivePath)
    $archiveRows.Add([pscustomobject]@{
        id = $id
        role = [string]$row.role
        archive_path = Get-RelativePath -Root $EvidenceRoot -Path $archivePath
        packet_path = Get-RelativePath -Root $EvidenceRoot -Path $packetPath
        package = [string]$row.package
        reviewer_alias = [string]$row.reviewer_alias
        contact_method = [string]$row.contact_method
        invite_status = [string]$row.invite_status
        due_at = [string]$row.due_at
        file_count = [string]$packetFiles.Count
        bytes = [string]$archiveItem.Length
        sha256 = Get-FileSha256 -Path $archivePath
    }) | Out-Null
}

$manifestPath = Join-Path $ArchiveRoot "REVIEWER_PACKET_ARCHIVE_MANIFEST.tsv"
$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("id`trole`tarchive_path`tpacket_path`tpackage`treviewer_alias`tcontact_method`tinvite_status`tdue_at`tfile_count`tbytes`tsha256")
foreach ($archive in $archiveRows) {
    $manifestLines.Add((@(
        (Format-TsvCell $archive.id),
        (Format-TsvCell $archive.role),
        (Format-TsvCell $archive.archive_path),
        (Format-TsvCell $archive.packet_path),
        (Format-TsvCell $archive.package),
        (Format-TsvCell $archive.reviewer_alias),
        (Format-TsvCell $archive.contact_method),
        (Format-TsvCell $archive.invite_status),
        (Format-TsvCell $archive.due_at),
        (Format-TsvCell $archive.file_count),
        (Format-TsvCell $archive.bytes),
        (Format-TsvCell $archive.sha256)
    ) -join "`t"))
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $manifestPath) -Value $manifestLines -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 리뷰어 패킷 ZIP")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 증거 루트: $EvidenceRoot")
$lines.Add("- 원본 패킷: $PacketRoot")
$lines.Add("- ZIP 폴더: $ArchiveRoot")
$lines.Add("- ZIP 수: $($archiveRows.Count)")
$lines.Add("- manifest: $manifestPath")
$lines.Add("")
$lines.Add("이 ZIP은 리뷰어에게 바로 보낼 수 있는 패킷 묶음이다. ZIP 자체는 운영 자료이며, 최종 출시 증거로는 실제 리뷰어가 반환한 EvidenceDrop 자료만 인정한다.")
$lines.Add("")
$lines.Add("| ID | 역할 | ZIP | 패키지 | 초대 상태 | 마감 |")
$lines.Add("| --- | --- | --- | --- | --- | --- |")
foreach ($archive in $archiveRows) {
    $lines.Add("| $(Escape-MarkdownCell $archive.id) | $(Escape-MarkdownCell $archive.role) | $(Escape-MarkdownCell $archive.archive_path) | $(Escape-MarkdownCell $archive.package) | $(Escape-MarkdownCell $archive.invite_status) | $(Escape-MarkdownCell $archive.due_at) |")
}
$lines.Add("")
$lines.Add("## 검증 명령")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add(".\Tools\ValidateExternalReviewerPacketArchives.ps1")
$lines.Add('```')

Ensure-Directory -Path (Split-Path -Parent $DocsPath)
Set-Content -LiteralPath (ConvertTo-LongPath -Path $DocsPath) -Value $lines -Encoding UTF8

Write-Host "External reviewer packet archives written: $ArchiveRoot"
Write-Host "External reviewer packet archive summary written: $DocsPath"
Write-Host "Reviewer packet archives: $($archiveRows.Count)"
