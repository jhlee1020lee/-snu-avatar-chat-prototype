param(
    [string]$ReportPath,
    [switch]$RequireImportedFiles
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

function Get-ReportNumber {
    param(
        [string]$Text,
        [string]$Label
    )

    $match = [regex]::Match($Text, "-\s*$([regex]::Escape($Label)):\s*(\d+)")
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }
    return -1
}

function Get-ReportValue {
    param(
        [string]$Text,
        [string]$Label
    )

    $match = [regex]::Match($Text, "-\s*$([regex]::Escape($Label)):\s*([^\r\n]+)")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return ""
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$docsRoot = Join-Path $projectRoot "Docs"
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $docsRoot "EXTERNAL_EVIDENCE_IMPORT_QA.md"
}

if (-not (Test-Path -LiteralPath (ConvertTo-LongPath -Path $ReportPath))) {
    throw "Missing external evidence import QA report: $ReportPath"
}

$text = Get-Content -LiteralPath (ConvertTo-LongPath -Path $ReportPath) -Raw -Encoding UTF8
$status = Get-ReportValue -Text $text -Label "상태"
$copied = Get-ReportNumber -Text $text -Label "복사"
$previewed = Get-ReportNumber -Text $text -Label "미리보기"
$conflicts = Get-ReportNumber -Text $text -Label "충돌"
$secretCount = Get-ReportNumber -Text $text -Label "비밀키 형태 문자열"

if ($status -ne "완료") {
    throw "External evidence import QA status is not complete: $status"
}
if ($conflicts -ne 0) {
    throw "External evidence import QA has conflicts: $conflicts"
}
if ($secretCount -ne 0) {
    throw "External evidence import QA has secret pattern count: $secretCount"
}
if ($RequireImportedFiles -and ($copied + $previewed) -le 0) {
    throw "External evidence import QA has no copied or previewed evidence files."
}

Write-Host "External evidence import QA passed: $ReportPath"
Write-Host "Copied: $copied, preview: $previewed, conflicts: $conflicts"
