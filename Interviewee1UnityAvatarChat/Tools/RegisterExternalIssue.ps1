param(
    [string]$IssueRegisterPath,
    [string]$OutputPath,
    [string]$IssueId,
    [ValidateSet("open", "in_progress", "fixed", "verified", "accepted_risk", "wont_fix")]
    [string]$Status = "open",
    [Parameter(Mandatory = $true)]
    [ValidateSet("P0", "P1", "P2", "P3")]
    [string]$Priority,
    [Parameter(Mandatory = $true)]
    [string]$Area,
    [string]$Source = "external-playtest",
    [string]$SessionId = "",
    [string]$BuildId = "",
    [Parameter(Mandatory = $true)]
    [string]$Title,
    [Parameter(Mandatory = $true)]
    [string]$ReproSteps,
    [Parameter(Mandatory = $true)]
    [string]$Expected,
    [Parameter(Mandatory = $true)]
    [string]$Actual,
    [string]$FixSummary = "",
    [string]$VerifiedBy = "",
    [string]$VerifiedAt = "",
    [string]$EvidencePath = "",
    [switch]$UpdateExisting,
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"
$ApiKeyPattern = "sk-\.\.\.|sk-(proj|live|test|svcacct)-[A-Za-z0-9_-]*|sk-[A-Za-z0-9][A-Za-z0-9_-]{20,}"

$requiredColumns = @(
    "issue_id",
    "status",
    "priority",
    "area",
    "source",
    "session_id",
    "build_id",
    "title",
    "repro_steps",
    "expected",
    "actual",
    "fix_summary",
    "verified_by",
    "verified_at",
    "evidence_path"
)

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
        $tempPath = "$Path.tmp-$PID-$attempt"
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

function Assert-NoSecretPattern {
    param(
        [string]$Value,
        [string]$FieldName
    )

    if ([regex]::IsMatch([string]$Value, $ApiKeyPattern)) {
        throw "$FieldName contains an API key pattern."
    }
}

function Normalize-Field {
    param(
        [string]$Value,
        [string]$FieldName
    )

    Assert-NoSecretPattern -Value $Value -FieldName $FieldName
    return ([string]$Value).Replace("`t", " ").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Read-DefaultBuildId {
    param([string]$ProjectRoot)

    $candidatePaths = @(
        (Join-Path $ProjectRoot "Build\BUILD_INFO.json"),
        (Join-Path $ProjectRoot "Game\Interviewee1UnityAvatarChat\BUILD_INFO.json")
    )

    foreach ($buildInfoPath in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $buildInfoPath)) {
            continue
        }

        try {
            $buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$buildInfo.buildId)) {
                return [string]$buildInfo.buildId
            }
        }
        catch {
            continue
        }
    }

    return ""
}

function Get-RegisterRows {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    return @(Import-Csv -Delimiter "`t" -LiteralPath $Path)
}

function Assert-RegisterHeader {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-LinesWithRetry -Path $Path -Lines @($requiredColumns -join "`t")
        return
    }

    $firstLine = Get-Content -LiteralPath $Path -TotalCount 1
    $headers = @($firstLine -split "`t")
    foreach ($column in $requiredColumns) {
        if ($headers -notcontains $column) {
            throw "Issue register is missing required column: $column"
        }
    }
}

function Convert-RowToLine {
    param([object]$Row)

    $values = foreach ($column in $requiredColumns) {
        Normalize-Field -Value ([string]$Row.$column) -FieldName $column
    }

    return $values -join "`t"
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$buildRoot = Join-Path $projectRoot "Build"
$docsRoot = Join-Path $projectRoot "Docs"
$observerDocsRoot = Join-Path $projectRoot "ObserverDocs"
$evidenceDropRoot = Join-Path $projectRoot "EvidenceDrop"

if ([string]::IsNullOrWhiteSpace($IssueRegisterPath)) {
    if (Test-Path -LiteralPath $evidenceDropRoot) {
        $IssueRegisterPath = Join-Path $evidenceDropRoot "EXTERNAL_ISSUE_REGISTER.tsv"
    }
    else {
        $IssueRegisterPath = Join-Path $buildRoot "ReleaseEvidence\EXTERNAL_ISSUE_REGISTER.tsv"
    }
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    if (Test-Path -LiteralPath $observerDocsRoot) {
        $OutputPath = Join-Path $observerDocsRoot "EXTERNAL_ISSUE_REGISTER_QA.md"
    }
    else {
        $OutputPath = Join-Path $docsRoot "EXTERNAL_ISSUE_REGISTER_QA.md"
    }
}
if ([string]::IsNullOrWhiteSpace($IssueId)) {
    $IssueId = "EXT-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}
if ([string]::IsNullOrWhiteSpace($BuildId)) {
    $BuildId = Read-DefaultBuildId -ProjectRoot $projectRoot
}
if ($Status -eq "verified" -and [string]::IsNullOrWhiteSpace($VerifiedAt)) {
    $VerifiedAt = Get-Date -Format "yyyy-MM-dd"
}

$IssueId = Normalize-Field -Value $IssueId -FieldName "issue_id"
$Area = Normalize-Field -Value $Area -FieldName "area"
$Source = Normalize-Field -Value $Source -FieldName "source"
$SessionId = Normalize-Field -Value $SessionId -FieldName "session_id"
$BuildId = Normalize-Field -Value $BuildId -FieldName "build_id"
$Title = Normalize-Field -Value $Title -FieldName "title"
$ReproSteps = Normalize-Field -Value $ReproSteps -FieldName "repro_steps"
$Expected = Normalize-Field -Value $Expected -FieldName "expected"
$Actual = Normalize-Field -Value $Actual -FieldName "actual"
$FixSummary = Normalize-Field -Value $FixSummary -FieldName "fix_summary"
$VerifiedBy = Normalize-Field -Value $VerifiedBy -FieldName "verified_by"
$VerifiedAt = Normalize-Field -Value $VerifiedAt -FieldName "verified_at"
$EvidencePath = Normalize-Field -Value $EvidencePath -FieldName "evidence_path"

if ([string]::IsNullOrWhiteSpace($IssueId)) {
    throw "IssueId is required."
}

$requiredInput = @{
    area = $Area
    source = $Source
    build_id = $BuildId
    title = $Title
    repro_steps = $ReproSteps
    expected = $Expected
    actual = $Actual
}
foreach ($pair in $requiredInput.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace([string]$pair.Value)) {
        throw "$($pair.Key) is required."
    }
}

if ($Status -eq "verified") {
    foreach ($pair in @{
        fix_summary = $FixSummary
        verified_by = $VerifiedBy
        verified_at = $VerifiedAt
        evidence_path = $EvidencePath
    }.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace([string]$pair.Value)) {
            throw "$($pair.Key) is required for verified issues."
        }
    }
}

Assert-RegisterHeader -Path $IssueRegisterPath
$rows = Get-RegisterRows -Path $IssueRegisterPath
$duplicateRows = @($rows | Where-Object { ([string]$_.issue_id).Trim() -eq $IssueId })
if ($duplicateRows.Count -gt 0 -and -not $UpdateExisting) {
    throw "IssueId already exists. Use -UpdateExisting to replace it: $IssueId"
}

$newRow = [pscustomobject]@{
    issue_id = $IssueId
    status = $Status
    priority = $Priority
    area = $Area
    source = $Source
    session_id = $SessionId
    build_id = $BuildId
    title = $Title
    repro_steps = $ReproSteps
    expected = $Expected
    actual = $Actual
    fix_summary = $FixSummary
    verified_by = $VerifiedBy
    verified_at = $VerifiedAt
    evidence_path = $EvidencePath
}

$nextRows = New-Object System.Collections.Generic.List[object]
$replaced = $false
foreach ($row in $rows) {
    if (([string]$row.issue_id).Trim() -eq $IssueId) {
        $nextRows.Add($newRow) | Out-Null
        $replaced = $true
    }
    else {
        $nextRows.Add($row) | Out-Null
    }
}
if (-not $replaced) {
    $nextRows.Add($newRow) | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add($requiredColumns -join "`t")
foreach ($row in $nextRows) {
    $lines.Add((Convert-RowToLine -Row $row))
}
Write-LinesWithRetry -Path $IssueRegisterPath -Lines $lines

if (-not $SkipValidation) {
    $validator = Join-Path $PSScriptRoot "ValidateExternalIssueRegister.ps1"
    if (Test-Path -LiteralPath $validator) {
        & $validator -IssueRegisterPath $IssueRegisterPath -OutputPath $OutputPath
    }
}

Write-Host "External issue registered: $IssueId ($Priority, $Status)"
Write-Host "Issue register: $IssueRegisterPath"
