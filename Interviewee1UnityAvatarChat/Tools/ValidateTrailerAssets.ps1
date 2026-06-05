param(
    [string]$TrailerPath
)

$ErrorActionPreference = "Stop"

$customTrailerPath = -not [string]::IsNullOrWhiteSpace($TrailerPath)

function Resolve-Tool {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw "Tool not found: $($Names -join ', ')"
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$trailerRoot = Join-Path $projectRoot "Marketing\Trailer"
if ([string]::IsNullOrWhiteSpace($TrailerPath)) {
    $TrailerPath = Join-Path $trailerRoot "trailer_animatic_60s.mp4"
}

$required = @(
    "TRAILER_PRODUCTION_PLAN.md",
    "TRAILER_SHOTLIST.tsv",
    "TRAILER_CAPTIONS.srt",
    "TRAILER_CAPTIONS.vtt",
    "trailer_animatic_60s.mp4",
    "TRAILER_BUILD_CAPTURE_SHOTLIST.tsv",
    "trailer_build_capture_60s.mp4"
)

foreach ($file in $required) {
    $path = Join-Path $trailerRoot $file
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing trailer asset: $file"
    }
}

$ffprobe = Resolve-Tool @("ffprobe.exe", "ffprobe")

function Test-ShotList {
    param(
        [string]$Path,
        [string]$Label
    )

    $shotList = Import-Csv -Delimiter "`t" -LiteralPath $Path
    if ($shotList.Count -lt 6) {
        throw "$Label shot list is too short."
    }

    $total = 0.0
    foreach ($shot in $shotList) {
        $duration = [double]$shot.end - [double]$shot.start
        if ($duration -le 0) {
            throw "Invalid $Label shot duration: $($shot.source)"
        }
        if ([string]::IsNullOrWhiteSpace($shot.caption)) {
            throw "Missing $Label shot caption: $($shot.source)"
        }
        $total += $duration
    }

    if ([Math]::Abs($total - 60.0) -gt 0.01) {
        throw "$Label shot list duration is $total seconds, expected 60."
    }
}

function Convert-SrtTimestampToSeconds {
    param([string]$Value)

    if ($Value -notmatch "^(\d{2}):(\d{2}):(\d{2}),(\d{3})$") {
        throw "Invalid SRT timestamp: $Value"
    }

    return ([int]$Matches[1] * 3600) + ([int]$Matches[2] * 60) + [int]$Matches[3] + ([int]$Matches[4] / 1000.0)
}

function Convert-VttTimestampToSeconds {
    param([string]$Value)

    if ($Value -notmatch "^(\d{2}):(\d{2}):(\d{2})\.(\d{3})$") {
        throw "Invalid VTT timestamp: $Value"
    }

    return ([int]$Matches[1] * 3600) + ([int]$Matches[2] * 60) + [int]$Matches[3] + ([int]$Matches[4] / 1000.0)
}

function Get-SrtCaptionEntries {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Caption file is empty: $Path"
    }

    $blocks = [regex]::Split($raw.Trim(), "(?:\r?\n){2,}") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $entries = @()

    foreach ($block in $blocks) {
        $lines = $block -split "\r?\n"
        if ($lines.Count -lt 3) {
            throw "Invalid SRT block: $block"
        }

        if ($lines[0] -notmatch "^\d+$") {
            throw "Invalid SRT index: $($lines[0])"
        }

        if ($lines[1] -notmatch "^(?<start>\d{2}:\d{2}:\d{2},\d{3})\s+-->\s+(?<end>\d{2}:\d{2}:\d{2},\d{3})$") {
            throw "Invalid SRT timing line: $($lines[1])"
        }

        $start = Convert-SrtTimestampToSeconds -Value $Matches["start"]
        $end = Convert-SrtTimestampToSeconds -Value $Matches["end"]
        $text = (($lines | Select-Object -Skip 2) -join " ").Trim()

        if ($end -le $start) {
            throw "Invalid SRT duration at index $($lines[0])."
        }
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "Missing SRT caption text at index $($lines[0])."
        }

        $entries += [pscustomobject]@{
            Index = [int]$lines[0]
            Start = $start
            End = $end
            Text = $text
        }
    }

    return $entries
}

function Get-VttCaptionEntries {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Caption file is empty: $Path"
    }

    $trimmed = $raw.Trim()
    if ($trimmed -notmatch "^WEBVTT(?:\r?\n|$)") {
        throw "VTT file must start with WEBVTT: $Path"
    }

    $body = ($trimmed -replace "^WEBVTT(?:[^\r\n]*)\r?\n+", "")
    $blocks = [regex]::Split($body.Trim(), "(?:\r?\n){2,}") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $entries = @()
    $index = 1

    foreach ($block in $blocks) {
        $lines = @($block -split "\r?\n")
        if ($lines.Count -lt 2) {
            throw "Invalid VTT block: $block"
        }

        $timingLineIndex = 0
        if ($lines[0] -notmatch "-->") {
            if ($lines.Count -lt 3) {
                throw "Invalid VTT block: $block"
            }
            $timingLineIndex = 1
        }

        $timingLine = $lines[$timingLineIndex]
        if ($timingLine -notmatch "^(?<start>\d{2}:\d{2}:\d{2}\.\d{3})\s+-->\s+(?<end>\d{2}:\d{2}:\d{2}\.\d{3})(?:\s+.*)?$") {
            throw "Invalid VTT timing line: $timingLine"
        }

        $start = Convert-VttTimestampToSeconds -Value $Matches["start"]
        $end = Convert-VttTimestampToSeconds -Value $Matches["end"]
        $text = (($lines | Select-Object -Skip ($timingLineIndex + 1)) -join " ").Trim()

        if ($end -le $start) {
            throw "Invalid VTT duration at cue $index."
        }
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "Missing VTT caption text at cue $index."
        }

        $entries += [pscustomobject]@{
            Index = $index
            Start = $start
            End = $end
            Text = $text
        }
        $index += 1
    }

    return $entries
}

function Test-CaptionsAgainstShotList {
    param(
        [string]$CaptionPath,
        [string]$ShotListPath,
        [string]$Label,
        [ValidateSet("Srt", "Vtt")]
        [string]$Format = "Srt"
    )

    if ($Format -eq "Vtt") {
        $captions = @(Get-VttCaptionEntries -Path $CaptionPath)
    } else {
        $captions = @(Get-SrtCaptionEntries -Path $CaptionPath)
    }
    $shotList = @(Import-Csv -Delimiter "`t" -LiteralPath $ShotListPath)

    if ($captions.Count -ne $shotList.Count) {
        throw "$Label caption count is $($captions.Count), expected $($shotList.Count)."
    }

    for ($i = 0; $i -lt $shotList.Count; $i++) {
        $caption = $captions[$i]
        $shot = $shotList[$i]
        $shotStart = [double]$shot.start
        $shotEnd = [double]$shot.end

        if ($caption.Index -ne ($i + 1)) {
            throw "$Label caption index $($caption.Index) is out of order, expected $($i + 1)."
        }
        if ([Math]::Abs($caption.Start - $shotStart) -gt 0.05 -or [Math]::Abs($caption.End - $shotEnd) -gt 0.05) {
            throw "$Label caption timing mismatch at index $($caption.Index): $($caption.Start)-$($caption.End), expected $shotStart-$shotEnd."
        }
        if ($caption.Text.Length -lt 8) {
            throw "$Label caption is too short at index $($caption.Index)."
        }
        if ($caption.Text -ne $shot.caption) {
            throw "$Label caption text mismatch at index $($caption.Index): '$($caption.Text)', expected '$($shot.caption)'."
        }
    }
}

function Test-TrailerFile {
    param(
        [string]$Path,
        [string]$Label
    )

    $probe = & $ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -show_entries format=duration -of default=noprint_wrappers=1 $Path
    $text = $probe -join "`n"

    if ($text -notmatch "width=1920" -or $text -notmatch "height=1080") {
        throw "$Label must be 1920x1080. ffprobe output: $text"
    }

    if ($text -notmatch "duration=([0-9.]+)") {
        throw "Could not read $Label duration. ffprobe output: $text"
    }

    $durationSeconds = [double]$Matches[1]
    if ($durationSeconds -lt 59.5 -or $durationSeconds -gt 60.5) {
        throw "$Label duration is $durationSeconds seconds, expected about 60."
    }

    $audioProbe = & $ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels,sample_rate -of default=noprint_wrappers=1 $Path
    $audioText = $audioProbe -join "`n"

    if ([string]::IsNullOrWhiteSpace($audioText)) {
        throw "$Label must include an audio stream."
    }
    if ($audioText -notmatch "codec_name=aac") {
        throw "$Label audio must be AAC. ffprobe output: $audioText"
    }
    if ($audioText -notmatch "sample_rate=48000") {
        throw "$Label audio sample rate must be 48000 Hz. ffprobe output: $audioText"
    }
    if ($audioText -notmatch "channels=([0-9]+)") {
        throw "Could not read $Label audio channels. ffprobe output: $audioText"
    }
    $channels = [int]$Matches[1]
    if ($channels -lt 2) {
        throw "$Label audio must be stereo. ffprobe output: $audioText"
    }
}

Test-ShotList -Path (Join-Path $trailerRoot "TRAILER_SHOTLIST.tsv") -Label "Trailer animatic"
Test-TrailerFile -Path $TrailerPath -Label "Trailer"

if (-not $customTrailerPath) {
    Test-ShotList -Path (Join-Path $trailerRoot "TRAILER_BUILD_CAPTURE_SHOTLIST.tsv") -Label "Build capture trailer"
    Test-CaptionsAgainstShotList -CaptionPath (Join-Path $trailerRoot "TRAILER_CAPTIONS.srt") -ShotListPath (Join-Path $trailerRoot "TRAILER_BUILD_CAPTURE_SHOTLIST.tsv") -Label "Build capture trailer SRT" -Format "Srt"
    Test-CaptionsAgainstShotList -CaptionPath (Join-Path $trailerRoot "TRAILER_CAPTIONS.vtt") -ShotListPath (Join-Path $trailerRoot "TRAILER_BUILD_CAPTURE_SHOTLIST.tsv") -Label "Build capture trailer VTT" -Format "Vtt"
    Test-TrailerFile -Path (Join-Path $trailerRoot "trailer_build_capture_60s.mp4") -Label "Build capture trailer"
}

Write-Host "Trailer asset validation passed: $TrailerPath"
