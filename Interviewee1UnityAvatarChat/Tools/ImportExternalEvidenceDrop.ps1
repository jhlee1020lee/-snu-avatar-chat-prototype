param(
    [Parameter(Mandatory = $true)]
    [string]$SourceEvidenceDrop,
    [string]$DestinationEvidenceRoot,
    [string]$ReportPath,
    [switch]$Force,
    [switch]$Preview
)

$ErrorActionPreference = "Stop"
$SecretPatternDefinitions = @(
    [pscustomobject]@{ Label = "OpenAI API key"; Pattern = 'sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}' },
    [pscustomobject]@{ Label = "private key block"; Pattern = '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----' },
    [pscustomobject]@{ Label = "authorization bearer token"; Pattern = '(?i)\bAuthorization\s*:\s*Bearer\s+[A-Za-z0-9._~+/=-]{20,}' },
    [pscustomobject]@{ Label = "token assignment"; Pattern = '(?i)\b(access_token|refresh_token|id_token|api_key|secret_key|client_secret)\b\s*[:=]\s*["'']?[A-Za-z0-9._~+/=-]{20,}' },
    [pscustomobject]@{ Label = "password field"; Pattern = '(?i)\b(steam_)?password\b\s*[:=]\s*["'']?\S{6,}' },
    [pscustomobject]@{ Label = "Steam Guard code field"; Pattern = '(?i)\bsteam\s*guard(\s*code|\s*otp)?\b\s*[:=]\s*["'']?[A-Z0-9]{5,}' },
    [pscustomobject]@{ Label = "Steam mobile secret"; Pattern = '(?i)\b(shared_secret|identity_secret)\b\s*[:=]\s*["'']?[A-Za-z0-9+/=]{16,}' }
)

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

function ConvertFrom-LongPath {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith("\\?\UNC\")) {
        return "\\" + $full.Substring(8)
    }
    if ($full.StartsWith("\\?\")) {
        return $full.Substring(4)
    }
    return $full
}

function Ensure-Directory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Test-TextLikeFile {
    param([System.IO.FileInfo]$File)

    $textExtensions = @(
        ".bat", ".cmd", ".config", ".csv", ".css", ".htm", ".html", ".ini",
        ".js", ".json", ".log", ".manifest", ".md", ".ps1", ".psm1", ".srt",
        ".tsv", ".txt", ".vdf", ".vtt", ".xml", ".yaml", ".yml"
    )
    $textNames = @("LICENSE", "NOTICE", "README")
    $extension = $File.Extension.ToLowerInvariant()
    if ($textExtensions -contains $extension) {
        return $true
    }
    return $textNames -contains $File.Name.ToUpperInvariant()
}

function Test-TemplateLikeFile {
    param([System.IO.FileInfo]$File)

    $relative = Get-RelativePath -FullName $File.FullName
    return ($File.Name -match "(^README|README|TEMPLATE|REFERENCE|SAMPLE|BLANK|양식|예시)" -or
        $relative -match "(^|\\)ReviewBriefs(\\|$)" -or
        $relative -match "(^|\\)ReviewerPackets(\\|$)" -or
        $relative -match "EXTERNAL_REVIEW_OUTREACH_QUEUE" -or
        $relative -match "COMMERCIAL_QUALITY_SCORECARD_DRAFT" -or
        $relative -match "EXTERNAL_EVIDENCE_AUDIT|PLAYTEST_EVIDENCE_SUMMARY|EXTERNAL_ISSUE_REGISTER_QA|COMMERCIAL_QUALITY_REVIEW_QA")
}

function Get-RelativePath {
    param([string]$FullName)

    $sourceFull = (ConvertFrom-LongPath -Path $script:sourceRoot) -replace '[\\/]+$', ''
    $fileFull = ConvertFrom-LongPath -Path $FullName
    if ($fileFull.StartsWith($sourceFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fileFull.Substring($sourceFull.Length + 1)
    }
    return $fileFull
}

function Test-EmptyCommercialQualityScorecard {
    param([System.IO.FileInfo]$File)

    if ($File.Name -ne "COMMERCIAL_QUALITY_SCORECARD.tsv") {
        return $false
    }

    try {
        $scoreRows = @(Import-Csv -Delimiter "`t" -LiteralPath (ConvertTo-LongPath -Path $File.FullName) -Encoding UTF8)
    }
    catch {
        return $false
    }

    if ($scoreRows.Count -eq 0) {
        return $true
    }

    $filledRows = @($scoreRows | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.score) -or
        -not [string]::IsNullOrWhiteSpace([string]$_.reviewer) -or
        -not [string]::IsNullOrWhiteSpace([string]$_.evidence) -or
        (([string]$_.blocker).Trim() -match '^(?i:true|yes|y|1|차단|blocker)$')
    })

    return $filledRows.Count -eq 0
}

function Get-SecretMatches {
    param([object[]]$Files)

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($file in $Files) {
        if (-not (Test-TextLikeFile -File $file)) {
            continue
        }
        foreach ($definition in $SecretPatternDefinitions) {
            $found = Select-String -LiteralPath (ConvertTo-LongPath -Path $file.FullName) -Pattern $definition.Pattern -ErrorAction SilentlyContinue
            foreach ($match in $found) {
                $matches.Add([pscustomobject]@{
                    Path = $match.Path
                    Label = $definition.Label
                }) | Out-Null
            }
        }
    }
    return $matches.ToArray()
}

function Get-FileHashOrEmpty {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return ""
    }
    return (Get-FileHash -LiteralPath (ConvertTo-LongPath -Path $Path) -Algorithm SHA256).Hash
}

function Get-NormalizedTextOrEmpty {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $Path))) {
        return ""
    }

    $text = Get-Content -LiteralPath (ConvertTo-LongPath -Path $Path) -Raw -Encoding UTF8
    return (($text -replace "`r`n", "`n") -replace "`r", "`n").TrimEnd()
}

function Add-ImportRow {
    param(
        [string]$RelativePath,
        [string]$Status,
        [string]$Reason,
        [string]$Destination = ""
    )

    $script:rows.Add([pscustomobject]@{
        relative_path = $RelativePath
        status = $Status
        reason = $Reason
        destination = $Destination
    }) | Out-Null
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

function Copy-EvidenceFile {
    param(
        [System.IO.FileInfo]$File,
        [string]$RelativePath
    )

    $destination = Join-Path $DestinationEvidenceRoot $RelativePath
    $sourceHash = Get-FileHashOrEmpty -Path $File.FullName
    $destinationHash = Get-FileHashOrEmpty -Path $destination
    $replaceEmptyScorecardTemplate = $false

    if (-not [string]::IsNullOrWhiteSpace($destinationHash)) {
        if ($sourceHash -eq $destinationHash) {
            Add-ImportRow -RelativePath $RelativePath -Status "skipped" -Reason "same file already exists" -Destination $destination
            return
        }
        if (Test-TextLikeFile -File $File) {
            $sourceText = Get-NormalizedTextOrEmpty -Path $File.FullName
            $destinationText = Get-NormalizedTextOrEmpty -Path $destination
            if ($sourceText -eq $destinationText) {
                Add-ImportRow -RelativePath $RelativePath -Status "skipped" -Reason "same text already exists" -Destination $destination
                return
            }
        }
        $destinationFile = Get-Item -LiteralPath (ConvertTo-LongPath -Path $destination) -ErrorAction SilentlyContinue
        if ($File.Name -eq "COMMERCIAL_QUALITY_SCORECARD.tsv" -and
            $null -ne $destinationFile -and
            (Test-EmptyCommercialQualityScorecard -File $destinationFile) -and
            -not (Test-EmptyCommercialQualityScorecard -File $File)) {
            $replaceEmptyScorecardTemplate = $true
        }
        if (-not $Force -and -not $replaceEmptyScorecardTemplate) {
            Add-ImportRow -RelativePath $RelativePath -Status "conflict" -Reason "destination exists with different content; rerun with -Force after review" -Destination $destination
            return
        }
    }

    if ($Preview) {
        $reason = if ($replaceEmptyScorecardTemplate) { "would replace empty official scorecard template" } else { "would copy" }
        Add-ImportRow -RelativePath $RelativePath -Status "preview" -Reason $reason -Destination $destination
        return
    }

    Ensure-Directory -Path (Split-Path -Parent $destination)
    Copy-Item -LiteralPath (ConvertTo-LongPath -Path $File.FullName) -Destination (ConvertTo-LongPath -Path $destination) -Force
    $reason = if ($replaceEmptyScorecardTemplate) { "replaced empty official scorecard template" } else { "imported" }
    Add-ImportRow -RelativePath $RelativePath -Status "copied" -Reason $reason -Destination $destination
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
$buildRoot = Join-Path $projectRoot "Build"

if ([string]::IsNullOrWhiteSpace($DestinationEvidenceRoot)) {
    $DestinationEvidenceRoot = Join-Path $buildRoot "ReleaseEvidence"
}
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $docsRoot "EXTERNAL_EVIDENCE_IMPORT_QA.md"
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $SourceEvidenceDrop))) {
    throw "Missing source EvidenceDrop: $SourceEvidenceDrop"
}

$sourceRoot = (Resolve-Path $SourceEvidenceDrop).Path
Ensure-Directory -Path $DestinationEvidenceRoot

$rows = New-Object System.Collections.Generic.List[object]
$allowedRoots = @("Playtest", "Accessibility", "ArtReview", "Trailer", "LegalSteam")
$allowedRootFiles = @("COMMERCIAL_QUALITY_SCORECARD.tsv", "EXTERNAL_ISSUE_REGISTER.tsv", "EXTERNAL_REVIEW_TRACKER.tsv", "EXTERNAL_REVIEWER_ROSTER.tsv")

$allFiles = @(Get-ChildItem -LiteralPath (ConvertTo-LongPath -Path $sourceRoot) -File -Recurse -ErrorAction Stop)
$secretMatches = Get-SecretMatches -Files $allFiles
if ($secretMatches.Count -gt 0) {
    $sample = ($secretMatches | Select-Object -First 4 | ForEach-Object { "$($_.Label): $(Get-RelativePath -FullName $_.Path)" }) -join ", "
    throw "Source EvidenceDrop contains a secret pattern: $sample"
}

foreach ($file in $allFiles | Sort-Object FullName) {
    $relative = Get-RelativePath -FullName $file.FullName
    $parts = $relative -split "[\\/]"
    $rootName = $parts[0]

    if (Test-TemplateLikeFile -File $file) {
        Add-ImportRow -RelativePath $relative -Status "skipped" -Reason "template, reference, generated report, or review brief"
        continue
    }

    $isAllowedArea = $allowedRoots -contains $rootName
    $isAllowedRootFile = ($parts.Count -eq 1 -and $allowedRootFiles -contains $file.Name)
    if (-not $isAllowedArea -and -not $isAllowedRootFile) {
        Add-ImportRow -RelativePath $relative -Status "skipped" -Reason "outside allowed evidence paths"
        continue
    }

    if (Test-EmptyCommercialQualityScorecard -File $file) {
        Add-ImportRow -RelativePath $relative -Status "skipped" -Reason "empty official scorecard template"
        continue
    }

    Copy-EvidenceFile -File $file -RelativePath $relative
}

$copied = @($rows | Where-Object { $_.status -eq "copied" }).Count
$previewed = @($rows | Where-Object { $_.status -eq "preview" }).Count
$skipped = @($rows | Where-Object { $_.status -eq "skipped" }).Count
$conflicts = @($rows | Where-Object { $_.status -eq "conflict" }).Count
$status = if ($conflicts -gt 0) { "차단" } else { "완료" }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 외부 증거 수입 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 상태: $status")
$lines.Add("- 모드: $(if ($Preview) { 'preview' } else { 'copy' })")
$lines.Add("- 원본 EvidenceDrop: $sourceRoot")
$lines.Add("- 대상 증거 루트: $DestinationEvidenceRoot")
$lines.Add("- 복사: $copied")
$lines.Add("- 미리보기: $previewed")
$lines.Add("- 건너뜀: $skipped")
$lines.Add("- 충돌: $conflicts")
$lines.Add("- 비밀키 형태 문자열: 0")
$lines.Add("- 비밀정보 검사 범위: API 키, bearer/token 필드, 비밀번호 필드, Steam Guard 코드, Steam mobile secret, private key block")
$lines.Add("")
$lines.Add("이 보고서는 외부 패키지에서 돌아온 EvidenceDrop을 원본 ReleaseEvidence로 들여올 때 템플릿, 참고 문서, 생성 보고서, 비밀정보를 섞지 않기 위한 감사 기록이다.")
$lines.Add("")
$lines.Add("| 경로 | 상태 | 사유 | 대상 |")
$lines.Add("| --- | --- | --- | --- |")
foreach ($row in $rows) {
    $lines.Add("| $(Escape-MarkdownCell $row.relative_path) | $(Escape-MarkdownCell $row.status) | $(Escape-MarkdownCell $row.reason) | $(Escape-MarkdownCell $row.destination) |")
}

Ensure-Directory -Path (Split-Path -Parent $ReportPath)
Set-Content -LiteralPath (ConvertTo-LongPath -Path $ReportPath) -Value $lines -Encoding UTF8

$manifestPath = [System.IO.Path]::ChangeExtension($ReportPath, ".tsv")
$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("relative_path`tstatus`treason`tdestination")
foreach ($row in $rows) {
    $manifestLines.Add((
        (Format-TsvCell $row.relative_path),
        (Format-TsvCell $row.status),
        (Format-TsvCell $row.reason),
        (Format-TsvCell $row.destination)
    ) -join "`t")
}
Set-Content -LiteralPath (ConvertTo-LongPath -Path $manifestPath) -Value $manifestLines -Encoding UTF8

Write-Host "External evidence import QA written: $ReportPath"
Write-Host "Import status: $status, copied: $copied, preview: $previewed, skipped: $skipped, conflicts: $conflicts"

if ($conflicts -gt 0) {
    throw "External evidence import has $conflicts conflict(s)."
}
