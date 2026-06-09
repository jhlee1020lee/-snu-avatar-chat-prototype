param(
    [string]$UnityExe = "C:\Program Files\Unity\Hub\Editor\6000.4.5f1\Editor\Unity.exe",
    [switch]$SkipUnityBuild,
    [switch]$StaticOnly,
    [switch]$AllowUnityWindows
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "[release-smoke] $Message"
}

function Assert-File {
    param(
        [string]$Path,
        [int64]$MinBytes = 1
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing expected file: $Path"
    }

    $item = Get-Item -LiteralPath $Path
    if ($item.Length -lt $MinBytes) {
        throw "File is too small: $Path ($($item.Length) bytes)"
    }
}

function Run-ProcessChecked {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WorkingDirectory $WorkingDirectory -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        throw "$FilePath exited with code $($process.ExitCode)"
    }
}

function Stop-SmokeProcesses {
    Get-Process -Name "Interviewee1UnityAvatarChat", "UnityCrashHandler64" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

function Run-UnitySmokeChecked {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory,
        [int]$Retries = 1
    )

    if (-not $AllowUnityWindows) {
        throw "RunReleaseSmoke launches Unity player windows. Re-run with -AllowUnityWindows when the desktop is free, or use non-Unity validators such as ValidateCommercialUiCopy.ps1 while working."
    }

    for ($attempt = 1; $attempt -le ($Retries + 1); $attempt++) {
        Stop-SmokeProcesses
        Start-Sleep -Milliseconds 250

        $playerArgs = @("-force-d3d11") + $ArgumentList
        $process = Start-Process -FilePath $FilePath -ArgumentList $playerArgs -WorkingDirectory $WorkingDirectory -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            return
        }

        Stop-SmokeProcesses
        if ($attempt -gt $Retries) {
            throw "$FilePath exited with code $($process.ExitCode)"
        }

        Write-Warning "Unity smoke attempt $attempt failed with code $($process.ExitCode); retrying once."
        Start-Sleep -Seconds 1
    }
}

function Run-PanelShortcutGuard {
    param(
        [string]$Name,
        [string[]]$SetupArgs,
        [string]$Key,
        [string]$ExpectedOpen,
        [string]$ExpectedClosed
    )

    $reportPath = Join-Path $smokeDir "panel-shortcut-$Name.tsv"
    $args = @("--smoke-skip-start") + $SetupArgs + @("--smoke-key", $Key)
    if (-not [string]::IsNullOrWhiteSpace($ExpectedOpen)) {
        $args += @("--smoke-expect-open", $ExpectedOpen)
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedClosed)) {
        $args += @("--smoke-expect-closed", $ExpectedClosed)
    }
    $args += @("--smoke-state-output", $reportPath, "--smoke-capture-delay", "0.1")

    Run-UnitySmokeChecked -FilePath $appExe -ArgumentList $args -WorkingDirectory $buildDir -Retries 1
    Assert-File -Path $reportPath -MinBytes 50

    $report = Get-Content -LiteralPath $reportPath -Raw
    if ($report -match "`tFAIL(\r?\n|$)") {
        throw "Panel shortcut guard failed: $reportPath"
    }
}

function Run-GamepadShortcutGuard {
    param(
        [string]$Name,
        [string[]]$SetupArgs,
        [string[]]$Keys,
        [string]$ExpectedOpen,
        [string]$ExpectedClosed,
        [string]$ExpectedStateName,
        [string]$ExpectedStateValue,
        [string[]]$ExpectedStates,
        [string]$CaptureDelay = "0.1"
    )

    $reportPath = Join-Path $smokeDir "gamepad-shortcut-$Name.tsv"
    $args = @("--smoke-skip-start") + $SetupArgs
    foreach ($key in $Keys) {
        $args += @("--smoke-key", $key)
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedOpen)) {
        $args += @("--smoke-expect-open", $ExpectedOpen)
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedClosed)) {
        $args += @("--smoke-expect-closed", $ExpectedClosed)
    }
    $args += @("--smoke-state-output", $reportPath, "--smoke-capture-delay", $CaptureDelay)

    Run-UnitySmokeChecked -FilePath $appExe -ArgumentList $args -WorkingDirectory $buildDir -Retries 1
    Assert-File -Path $reportPath -MinBytes 50

    $report = Get-Content -LiteralPath $reportPath -Raw
    if ($report -match "`tFAIL(\r?\n|$)") {
        throw "Gamepad shortcut QA failed: $reportPath"
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedStateName)) {
        $expectedPattern = "state`t$ExpectedStateName`t`t$ExpectedStateValue`tINFO"
        if ($report -notmatch [regex]::Escape($expectedPattern)) {
            throw "Gamepad shortcut state mismatch: $reportPath expected $ExpectedStateName=$ExpectedStateValue"
        }
    }
    foreach ($expectedState in @($ExpectedStates)) {
        if ([string]::IsNullOrWhiteSpace($expectedState) -or $expectedState -notmatch "=") {
            continue
        }

        $parts = $expectedState.Split("=", 2)
        $expectedPattern = "state`t$($parts[0])`t`t$($parts[1])`tINFO"
        if ($report -notmatch [regex]::Escape($expectedPattern)) {
            throw "Gamepad shortcut state mismatch: $reportPath expected $expectedState"
        }
    }

    return $reportPath
}

function Assert-ForegroundClutterHidden {
    param(
        [string]$ReportPath,
        [string]$Context
    )

    Assert-File -Path $ReportPath -MinBytes 80
    $report = Get-Content -LiteralPath $ReportPath -Raw
    if ($report -match "`tFAIL(\r?\n|$)") {
        throw "Foreground clutter guard failed: $ReportPath"
    }
    if ($report -notmatch "state`tlead-slips-visible-count`t`t0`tINFO") {
        throw "Foreground clutter guard did not hide lead slips during $Context`: $ReportPath"
    }
    if ($report -notmatch "state`thotspot-labels-visible-count`t`t0`tINFO") {
        throw "Foreground clutter guard did not hide hotspot labels during $Context`: $ReportPath"
    }
    if ($report -notmatch "state`thotspots-visible-count`t`t0`tINFO") {
        throw "Foreground clutter guard did not hide hotspot dots during $Context`: $ReportPath"
    }
}

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

if (-not $AllowUnityWindows -and -not $StaticOnly) {
    throw "RunReleaseSmoke opens Unity player windows for visual/runtime smoke tests. Re-run with -AllowUnityWindows when the desktop is free, or use -StaticOnly for the non-Unity checks."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$buildDir = Join-Path $projectRoot "Build"
$appExe = Join-Path $buildDir "Interviewee1UnityAvatarChat.exe"
$logPath = Join-Path $buildDir "unity-build.log"
$smokeDir = Join-Path $buildDir "release-smoke"

New-Item -ItemType Directory -Force -Path $smokeDir | Out-Null
$npm = Resolve-Tool @("npm.cmd", "npm")
$node = Resolve-Tool @("node.exe", "node")
$powershell = Resolve-Tool @("pwsh.exe", "pwsh", "powershell.exe", "powershell")

Write-Step "Node server syntax check"
Run-ProcessChecked -FilePath $npm -ArgumentList @("run", "check") -WorkingDirectory $serverRoot

Write-Step "Model config QA"
$modelConfigQa = Join-Path $PSScriptRoot "ValidateModelConfig.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $modelConfigQa
) -WorkingDirectory $repoRoot

Write-Step "OpenAI failure error check"
$env:PORT = "8876"
$env:OPENAI_API_KEY = "invalid-release-smoke-token"
$env:OPENAI_CHAT_MODEL = "gpt-5.4-mini"
$server = Start-Process -FilePath $node -ArgumentList @("server.js") -WorkingDirectory $serverRoot -PassThru -WindowStyle Hidden
try {
    Start-Sleep -Seconds 2
    $payload = @{
        messages = @(
            @{
                role = "user"
                content = "처음 가는 공간에서는 무엇을 먼저 확인하나요?"
            }
        )
    } | ConvertTo-Json -Depth 5

    $response = Invoke-WebRequest -Method Post -Uri "http://127.0.0.1:8876/api/chat" -ContentType "application/json; charset=utf-8" -Body $payload -SkipHttpErrorCheck
    if ($response.StatusCode -lt 400) {
        throw "Expected API failure status, got $($response.StatusCode)."
    }

    $errorPayload = $response.Content | ConvertFrom-Json
    if ([string]$errorPayload.error -notmatch "gpt-5\.4-mini.*호출 실패") {
        throw "Expected visible gpt-5.4-mini failure message, got '$($errorPayload.error)'."
    }
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
    Remove-Item Env:\PORT -ErrorAction SilentlyContinue
    Remove-Item Env:\OPENAI_API_KEY -ErrorAction SilentlyContinue
    Remove-Item Env:\OPENAI_CHAT_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:\OPENAI_MODEL -ErrorAction SilentlyContinue
}

Write-Step "Content reply QA"
$contentQa = Join-Path $PSScriptRoot "RunContentQA.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $contentQa,
    "-Port", "8878"
) -WorkingDirectory $repoRoot

Write-Step "Recommended question answer-match QA"
$recommendedQuestionQa = Join-Path $PSScriptRoot "RunRecommendedQuestionQA.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $recommendedQuestionQa,
    "-Port", "8885"
) -WorkingDirectory $repoRoot

Write-Step "Long session reply QA"
$longSessionQa = Join-Path $PSScriptRoot "RunLongSessionQA.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $longSessionQa,
    "-Port", "8881"
) -WorkingDirectory $repoRoot

Write-Step "Privacy and prompt-injection safety QA"
$safetyQa = Join-Path $PSScriptRoot "RunSafetyQA.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $safetyQa,
    "-Port", "8883"
) -WorkingDirectory $repoRoot

Write-Step "Commercial UI copy QA"
$commercialUiCopyQa = Join-Path $PSScriptRoot "ValidateCommercialUiCopy.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $commercialUiCopyQa
) -WorkingDirectory $repoRoot

Write-Step "Product branding QA"
$productBrandingQa = Join-Path $PSScriptRoot "ValidateProductBranding.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $productBrandingQa
) -WorkingDirectory $repoRoot

Write-Step "Unity build sync QA"
$unityBuildSyncQa = Join-Path $PSScriptRoot "ValidateUnityBuildSync.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $unityBuildSyncQa
) -WorkingDirectory $repoRoot

Write-Step "Release smoke window policy QA"
$releaseSmokePolicyQa = Join-Path $PSScriptRoot "ValidateReleaseSmokePolicy.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $releaseSmokePolicyQa
) -WorkingDirectory $repoRoot

Write-Step "Paperlogy font QA"
$paperlogyFontQa = Join-Path $PSScriptRoot "ValidatePaperlogyUsage.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $paperlogyFontQa
) -WorkingDirectory $repoRoot

$steamAssetQa = Join-Path $PSScriptRoot "ValidateSteamAssets.ps1"
$trailerAssetQa = Join-Path $PSScriptRoot "ValidateTrailerAssets.ps1"
Write-Step "Existing trailer asset QA"
$existingTrailer = Join-Path $projectRoot "Marketing\Trailer\trailer_animatic_60s.mp4"
$existingBuildCaptureTrailer = Join-Path $projectRoot "Marketing\Trailer\trailer_build_capture_60s.mp4"
if ((Test-Path -LiteralPath $existingTrailer) -and (Test-Path -LiteralPath $existingBuildCaptureTrailer)) {
    Run-ProcessChecked -FilePath $powershell -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $trailerAssetQa
    ) -WorkingDirectory $repoRoot
}
else {
    Write-Warning "Skipping existing trailer asset QA because generated trailer videos are not both present yet. They will be regenerated later in this smoke run."
}

if ($StaticOnly) {
    Write-Step "Static-only smoke complete"
    Write-Host "Skipped Unity build, Unity player captures, runtime smoke reports, and package-refresh steps. Re-run with -AllowUnityWindows for the full release smoke."
    return
}

if (-not $SkipUnityBuild) {
    Write-Step "Unity build"
    if (-not $AllowUnityWindows) {
        throw "RunReleaseSmoke may open Unity editor/player windows during build and visual smoke capture. Re-run with -AllowUnityWindows when windowed Unity execution is acceptable, or run targeted non-Unity validators while working."
    }

    if (-not (Test-Path -LiteralPath $UnityExe)) {
        throw "Unity executable not found: $UnityExe"
    }

    Run-ProcessChecked -FilePath $UnityExe -ArgumentList @(
        "-batchmode",
        "-quit",
        "-projectPath", $projectRoot,
        "-executeMethod", "AvatarChatBuildTools.BuildWindows",
        "-logFile", $logPath
    ) -WorkingDirectory $repoRoot

    $buildLog = Get-Content -LiteralPath $logPath -Raw
    if ($buildLog -notmatch "Build Finished, Result: Success") {
        throw "Unity build log does not show success"
    }
    if ($buildLog -match "error CS|warning CS|BuildFailedException") {
        throw "Unity build log contains C# errors, warnings, or BuildFailedException"
    }
}

Assert-File -Path $appExe -MinBytes 100000

Write-Step "Build metadata refresh"
$buildMetadataScript = Join-Path $PSScriptRoot "WriteBuildMetadata.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $buildMetadataScript
) -WorkingDirectory $repoRoot
Assert-File -Path (Join-Path $buildDir "BUILD_INFO.json") -MinBytes 100
Assert-File -Path (Join-Path $buildDir "BUILD_INFO.txt") -MinBytes 100
$buildInfo = Get-Content -LiteralPath (Join-Path $buildDir "BUILD_INFO.json") -Raw | ConvertFrom-Json
$currentBuildId = [string]$buildInfo.buildId
if ([string]::IsNullOrWhiteSpace($currentBuildId)) {
    throw "BUILD_INFO.json is missing buildId."
}

Write-Step "Unity title capture"
$titleShot = Join-Path $smokeDir "title-no-save.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-capture", $titleShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $titleShot -MinBytes 100000

Write-Step "Unity saved title capture"
$savedTitleShot = Join-Path $smokeDir "title-with-save.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-seed-save",
    "--smoke-capture", $savedTitleShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $savedTitleShot -MinBytes 100000

Write-Step "Unity start continue button state"
$startContinueButtonReport = Join-Path $smokeDir "start-continue-button.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-seed-save",
    "--smoke-click-continue",
    "--smoke-expect-closed", "start,question,memory,records,settings,about,feedback,closing",
    "--smoke-state-output", $startContinueButtonReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $startContinueButtonReport -MinBytes 180

$startContinueButtonState = Get-Content -LiteralPath $startContinueButtonReport -Raw
if ($startContinueButtonState -match "`tFAIL(\r?\n|$)") {
    throw "Start continue button QA failed: $startContinueButtonReport"
}
if ($startContinueButtonState -notmatch "state`tstart-menu-action`t`tcontinue-button`tINFO") {
    throw "Start continue button click did not register: $startContinueButtonReport"
}
if ($startContinueButtonState -notmatch "state`tstart-menu-open`t`tclosed`tINFO") {
    throw "Start continue button click did not close the title screen: $startContinueButtonReport"
}
if ($startContinueButtonState -notmatch "state`tconversation-turns`t`t3`tINFO") {
    throw "Start continue button click did not restore the saved turn count: $startContinueButtonReport"
}
if ($startContinueButtonState -notmatch "state`tfirst-impression`t`t목발`tINFO") {
    throw "Start continue button click did not restore first impression context: $startContinueButtonReport"
}
if ($startContinueButtonState -notmatch "state`tstart-save-preview-line`t`t지난 대화 · 질문 3/5 · 기억장 3/6 · 일과 공부`tINFO") {
    throw "Start continue button QA did not expose the saved-session preview line: $startContinueButtonReport"
}

Write-Step "Unity story mode state"
$storyModeReport = Join-Path $smokeDir "story-mode.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-start-story-mode",
    "--smoke-expect-story-mode",
    "--smoke-state-output", $storyModeReport,
    "--smoke-capture-delay", "0.3"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $storyModeReport -MinBytes 180

$storyModeState = Get-Content -LiteralPath $storyModeReport -Raw
if ($storyModeState -match "`tFAIL(\r?\n|$)") {
    throw "Story mode QA failed: $storyModeReport"
}
if ($storyModeState -notmatch "story`tnext-label`t`t다음 2/6`tINFO") {
    throw "Story mode QA did not show progress in the next-scene button: $storyModeReport"
}

Write-Step "Unity story mode shortcut state"
$storyModeShortcutReport = Join-Path $smokeDir "story-mode-shortcuts.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-start-story-mode",
    "--smoke-delayed-key", "RightArrow",
    "--smoke-state-output", $storyModeShortcutReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $storyModeShortcutReport -MinBytes 180

$storyModeShortcutState = Get-Content -LiteralPath $storyModeShortcutReport -Raw
if ($storyModeShortcutState -match "`tFAIL(\r?\n|$)") {
    throw "Story mode shortcut QA failed: $storyModeShortcutReport"
}
if ($storyModeShortcutState -notmatch "state`tstory-shortcut-action`t`tnext-key`tINFO") {
    throw "Story mode keyboard next shortcut did not register: $storyModeShortcutReport"
}
if ($storyModeShortcutState -notmatch "state`tstory-index`t`t1`tINFO") {
    throw "Story mode keyboard next shortcut did not advance to the second scene: $storyModeShortcutReport"
}
if ($storyModeShortcutState -notmatch "story`tnext-label`t`t다음 3/6`tINFO") {
    throw "Story mode keyboard next shortcut did not update the next-scene progress label: $storyModeShortcutReport"
}

Write-Step "Unity story mode next button state"
$storyModeNextButtonReport = Join-Path $smokeDir "story-mode-next-button.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-click-story-next",
    "--smoke-state-output", $storyModeNextButtonReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $storyModeNextButtonReport -MinBytes 180

$storyModeNextButtonState = Get-Content -LiteralPath $storyModeNextButtonReport -Raw
if ($storyModeNextButtonState -match "`tFAIL(\r?\n|$)") {
    throw "Story mode next button QA failed: $storyModeNextButtonReport"
}
if ($storyModeNextButtonState -notmatch "state`tstory-shortcut-action`t`tnext-button`tINFO") {
    throw "Story mode next button click did not register: $storyModeNextButtonReport"
}
if ($storyModeNextButtonState -notmatch "state`tstory-index`t`t1`tINFO") {
    throw "Story mode next button click did not advance to the second scene: $storyModeNextButtonReport"
}
if ($storyModeNextButtonState -notmatch "story`tnext-label`t`t다음 3/6`tINFO") {
    throw "Story mode next button click did not update the next-scene progress label: $storyModeNextButtonReport"
}

Write-Step "Unity story mode direct question button state"
$storyModeDirectQuestionButtonReport = Join-Path $smokeDir "story-mode-direct-question-button.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-click-story-question",
    "--smoke-expect-closed", "question,memory,records,settings,about,feedback,closing",
    "--smoke-state-output", $storyModeDirectQuestionButtonReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $storyModeDirectQuestionButtonReport -MinBytes 180

$storyModeDirectQuestionButtonState = Get-Content -LiteralPath $storyModeDirectQuestionButtonReport -Raw
if ($storyModeDirectQuestionButtonState -match "`tFAIL(\r?\n|$)") {
    throw "Story mode direct question button QA failed: $storyModeDirectQuestionButtonReport"
}
if ($storyModeDirectQuestionButtonState -notmatch "state`tstory-shortcut-action`t`tquestion-button`tINFO") {
    throw "Story mode direct question button click did not register: $storyModeDirectQuestionButtonReport"
}
if ($storyModeDirectQuestionButtonState -notmatch "story`tactive`t`tinactive`tINFO") {
    throw "Story mode direct question button click did not leave story mode: $storyModeDirectQuestionButtonReport"
}
if ($storyModeDirectQuestionButtonState -notmatch "story`tcontrols-visible`t`thidden`tINFO") {
    throw "Story mode direct question button click did not hide story controls: $storyModeDirectQuestionButtonReport"
}
if ($storyModeDirectQuestionButtonState -notmatch "copy`tthinking-status`t`t직접 질문으로 이어갑니다`tINFO") {
    throw "Story mode direct question button click did not show transition status copy: $storyModeDirectQuestionButtonReport"
}

Write-Step "Unity story mode direct question state"
$storyModeDirectQuestionReport = Join-Path $smokeDir "story-mode-direct-question.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-start-story-mode",
    "--smoke-delayed-key", "Q",
    "--smoke-expect-closed", "question,memory,records,settings,about,feedback,closing",
    "--smoke-state-output", $storyModeDirectQuestionReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $storyModeDirectQuestionReport -MinBytes 180

$storyModeDirectQuestionState = Get-Content -LiteralPath $storyModeDirectQuestionReport -Raw
if ($storyModeDirectQuestionState -match "`tFAIL(\r?\n|$)") {
    throw "Story mode direct question QA failed: $storyModeDirectQuestionReport"
}
if ($storyModeDirectQuestionState -notmatch "state`tstory-shortcut-action`t`tquestion-key`tINFO") {
    throw "Story mode direct question shortcut did not register: $storyModeDirectQuestionReport"
}
if ($storyModeDirectQuestionState -notmatch "story`tactive`t`tinactive`tINFO") {
    throw "Story mode direct question shortcut did not leave story mode: $storyModeDirectQuestionReport"
}
if ($storyModeDirectQuestionState -notmatch "story`tcontrols-visible`t`thidden`tINFO") {
    throw "Story mode direct question shortcut did not hide story controls: $storyModeDirectQuestionReport"
}
if ($storyModeDirectQuestionState -notmatch "copy`tthinking-status`t`t직접 질문으로 이어갑니다`tINFO") {
    throw "Story mode direct question shortcut did not show transition status copy: $storyModeDirectQuestionReport"
}

Write-Step "Unity story mode gamepad direct question state"
$storyModeGamepadDirectQuestionReport = Join-Path $smokeDir "story-mode-direct-question-gamepad.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-start-story-mode",
    "--smoke-key", "JoystickButton2",
    "--smoke-expect-closed", "question,memory,records,settings,about,feedback,closing",
    "--smoke-state-output", $storyModeGamepadDirectQuestionReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $storyModeGamepadDirectQuestionReport -MinBytes 180

$storyModeGamepadDirectQuestionState = Get-Content -LiteralPath $storyModeGamepadDirectQuestionReport -Raw
if ($storyModeGamepadDirectQuestionState -match "`tFAIL(\r?\n|$)") {
    throw "Story mode gamepad direct question QA failed: $storyModeGamepadDirectQuestionReport"
}
if ($storyModeGamepadDirectQuestionState -notmatch "state`tstory-shortcut-action`t`tquestion-gamepad`tINFO") {
    throw "Story mode gamepad direct question shortcut did not register: $storyModeGamepadDirectQuestionReport"
}
if ($storyModeGamepadDirectQuestionState -notmatch "story`tactive`t`tinactive`tINFO") {
    throw "Story mode gamepad direct question shortcut did not leave story mode: $storyModeGamepadDirectQuestionReport"
}
if ($storyModeGamepadDirectQuestionState -notmatch "story`tcontrols-visible`t`thidden`tINFO") {
    throw "Story mode gamepad direct question shortcut did not hide story controls: $storyModeGamepadDirectQuestionReport"
}
if ($storyModeGamepadDirectQuestionState -notmatch "copy`tthinking-status`t`t직접 질문으로 이어갑니다`tINFO") {
    throw "Story mode gamepad direct question shortcut did not show transition status copy: $storyModeGamepadDirectQuestionReport"
}

Write-Step "Unity Steam key art capture"
$keyArtShot = Join-Path $smokeDir "steam-keyart.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-key-art",
    "--smoke-capture", $keyArtShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $keyArtShot -MinBytes 100000

Write-Step "Unity avatar layout state"
$avatarLayoutReport = Join-Path $smokeDir "avatar-layout.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-expect-avatar-natural",
    "--smoke-state-output", $avatarLayoutReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $avatarLayoutReport -MinBytes 180

$avatarLayoutState = Get-Content -LiteralPath $avatarLayoutReport -Raw
if ($avatarLayoutState -match "`tFAIL(\r?\n|$)") {
    throw "Avatar layout QA failed: $avatarLayoutReport"
}

Write-Step "Unity thinking copy state"
$thinkingCopyReport = Join-Path $smokeDir "thinking-copy.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-thinking-state",
    "--smoke-expect-thinking-copy",
    "--smoke-state-output", $thinkingCopyReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $thinkingCopyReport -MinBytes 180

$thinkingCopyState = Get-Content -LiteralPath $thinkingCopyReport -Raw
if ($thinkingCopyState -match "`tFAIL(\r?\n|$)") {
    throw "Thinking copy QA failed: $thinkingCopyReport"
}

Write-Step "Unity server status info capture"
$serverStatusReport = Join-Path $smokeDir "server-status.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-about",
    "--smoke-state-output", $serverStatusReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $serverStatusReport -MinBytes 180

$serverStatusState = Get-Content -LiteralPath $serverStatusReport -Raw
if ($serverStatusState -match "`tFAIL(\r?\n|$)") {
    throw "Server status info QA failed: $serverStatusReport"
}
if ($serverStatusState -match "확인 중|확인하고" -or $serverStatusState -notmatch "state`tabout-server-status`t`t답변 연결 상태는 상태 확인으로 볼 수 있습니다.`tINFO") {
    throw "Server status info QA did not show stable default status: $serverStatusReport"
}

$serverStatusShot = Join-Path $smokeDir "server-status.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-about",
    "--smoke-capture", $serverStatusShot,
    "--smoke-capture-delay", "1.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $serverStatusShot -MinBytes 100000

Write-Step "Unity local answer only capture"
$localAnswerOnlyShot = Join-Path $smokeDir "local-answer-only.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-local-only",
    "--smoke-submit-question", "도움은 어떻게 물어보면 좋나요?",
    "--smoke-capture", $localAnswerOnlyShot,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $localAnswerOnlyShot -MinBytes 100000

Write-Step "Unity progress and answer source state"
$answerSourceReport = Join-Path $smokeDir "answer-source-progress.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-local-only",
    "--smoke-submit-question", "도움은 어떻게 물어보면 좋나요?",
    "--smoke-state-output", $answerSourceReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $answerSourceReport -MinBytes 220

$answerSourceState = Get-Content -LiteralPath $answerSourceReport -Raw
if ($answerSourceState -match "`tFAIL(\r?\n|$)") {
    throw "Answer source progress QA failed: $answerSourceReport"
}
if ($answerSourceState -notmatch "state`tanswer-source`t`tlocal-only`tINFO" -or
    $answerSourceState -notmatch "state`tprogress-label`t`t1/5 질문 · 내장 답변`tINFO" -or
    $answerSourceState -notmatch "state`tfinish-button`t`tdisabled`tINFO" -or
    $answerSourceState -notmatch "state`tfinish-button-label`t`t5문답 후`tINFO") {
    throw "Answer source progress QA did not show local-only progress label with clearly locked finish button: $answerSourceReport"
}

Write-Step "Unity memory card question state"
$memoryCardQuestionReport = Join-Path $smokeDir "memory-card-question.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-local-only",
    "--smoke-click-memory-card", "0",
    "--smoke-state-output", $memoryCardQuestionReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $memoryCardQuestionReport -MinBytes 220

$memoryCardQuestionState = Get-Content -LiteralPath $memoryCardQuestionReport -Raw
if ($memoryCardQuestionState -match "`tFAIL(\r?\n|$)") {
    throw "Memory card question QA failed: $memoryCardQuestionReport"
}
if ($memoryCardQuestionState -notmatch "state`tmemory-card-action`t`t일상`tINFO" -or
    $memoryCardQuestionState -notmatch "state`tmemory-card-buttons`t`t6`tINFO" -or
    $memoryCardQuestionState -notmatch "state`tconversation-turns`t`t1`tINFO" -or
    $memoryCardQuestionState -notmatch "state`tanswer-source`t`tlocal-only`tINFO") {
    throw "Memory card question QA did not start a local answer from the first memory card: $memoryCardQuestionReport"
}

Write-Step "Unity memory book keyboard question state"
$memoryBookShortcutReport = Join-Path $smokeDir "memory-book-shortcuts.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-local-only",
    "--smoke-memory-filled",
    "--smoke-key", "RightArrow",
    "--smoke-key", "Return",
    "--smoke-expect-closed", "memory",
    "--smoke-state-output", $memoryBookShortcutReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $memoryBookShortcutReport -MinBytes 240

$memoryBookShortcutState = Get-Content -LiteralPath $memoryBookShortcutReport -Raw
if ($memoryBookShortcutState -match "`tFAIL(\r?\n|$)") {
    throw "Memory book keyboard shortcut QA failed: $memoryBookShortcutReport"
}
if ($memoryBookShortcutState -notmatch "state`tmemory-book-shortcut-action`t`tsubmit-key`tINFO" -or
    $memoryBookShortcutState -notmatch "state`tselected-memory-card-index`t`t1`tINFO" -or
    $memoryBookShortcutState -notmatch "state`tmemory-card-action`t`t이동`tINFO" -or
    $memoryBookShortcutState -notmatch "state`tconversation-turns`t`t1`tINFO" -or
    $memoryBookShortcutState -notmatch "state`tanswer-source`t`tlocal-only`tINFO" -or
    $memoryBookShortcutState -notmatch "expect`tmemory`tclosed`tclosed`tPASS") {
    throw "Memory book keyboard shortcut did not choose and submit the second memory card: $memoryBookShortcutReport"
}

Write-Step "Unity reward toast state"
$rewardToastReport = Join-Path $smokeDir "memory-reward-toast.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-show-memory-toast", "도움",
    "--smoke-state-output", $rewardToastReport,
    "--smoke-capture-delay", "0.3"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $rewardToastReport -MinBytes 220

$rewardToastState = Get-Content -LiteralPath $rewardToastReport -Raw
if ($rewardToastState -match "`tFAIL(\r?\n|$)") {
    throw "Reward toast QA failed: $rewardToastReport"
}
if ($rewardToastState -notmatch "state`treward-toast-visible`t`tvisible`tINFO" -or
    $rewardToastState -notmatch "state`treward-line`t`t보상: 도움 장면 열림 · 배려/호기심 질문으로 깊은 기록까지 이어 보세요\.`tINFO" -or
    $rewardToastState -notmatch "state`treward-toast-text`t`t보상: 도움 장면 열림 · 배려/호기심 질문으로 깊은 기록까지 이어 보세요\.`tINFO") {
    throw "Reward toast QA did not prove visible reward feedback: $rewardToastReport"
}

Write-Step "Unity dialogue reading focus state"
$dialogueReadingFocusReport = Join-Path $smokeDir "dialogue-reading-focus.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-local-only",
    "--smoke-submit-question", "도움은 어떻게 물어보면 좋나요?",
    "--smoke-expect-dialogue-reading-focus",
    "--smoke-state-output", $dialogueReadingFocusReport,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $dialogueReadingFocusReport -MinBytes 260

$dialogueReadingFocusState = Get-Content -LiteralPath $dialogueReadingFocusReport -Raw
if ($dialogueReadingFocusState -match "`tFAIL(\r?\n|$)") {
    throw "Dialogue reading focus QA failed: $dialogueReadingFocusReport"
}
if ($dialogueReadingFocusState -notmatch "expect`tdialogue-reading-focus`tactive`tactive`tPASS" -or
    $dialogueReadingFocusState -notmatch "expect`tdialogue-reading-hotspots`t0`t0`tPASS" -or
    $dialogueReadingFocusState -notmatch "expect`tdialogue-reading-hotspot-labels`t0`t0`tPASS" -or
    $dialogueReadingFocusState -notmatch "expect`tdialogue-reading-followups`tvisible`t[1-9][0-9]*`tPASS" -or
    $dialogueReadingFocusState -notmatch "state`tfinish-button`t`tdisabled`tINFO" -or
    $dialogueReadingFocusState -notmatch "state`tfinish-button-label`t`t5문답 후`tINFO" -or
    $dialogueReadingFocusState -notmatch "expect`tdialogue-reading-followup-dock`t<=372`t(3[0-6][0-9](\.[0-9])?|37[0-2](\.[0-9])?)`tPASS") {
    throw "Dialogue reading focus QA did not preserve a clean reading state: $dialogueReadingFocusReport"
}

Write-Step "Unity data policy capture"
$dataPolicyShot = Join-Path $smokeDir "data-policy-delete-prompt.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-about",
    "--smoke-clear-data-prompt",
    "--smoke-capture", $dataPolicyShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $dataPolicyShot -MinBytes 100000

Write-Step "Unity data policy confirmation state"
$dataPolicyState = Join-Path $smokeDir "data-policy-delete-prompt.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-about",
    "--smoke-clear-data-prompt",
    "--smoke-expect-clear-data-prompt",
    "--smoke-state-output", $dataPolicyState,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $dataPolicyState -MinBytes 220

$dataPolicyStateText = Get-Content -LiteralPath $dataPolicyState -Raw
if ($dataPolicyStateText -match "`tFAIL(\r?\n|$)") {
    throw "Data policy delete prompt QA failed: $dataPolicyState"
}

Write-Step "Unity data policy clear button confirmation state"
$dataPolicyButtonState = Join-Path $smokeDir "data-policy-delete-button.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-seed-save",
    "--smoke-skip-start",
    "--smoke-open-about",
    "--smoke-click-clear-data-confirm",
    "--smoke-expect-closed", "about,start,records,question,memory,settings,feedback,closing",
    "--smoke-state-output", $dataPolicyButtonState,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $dataPolicyButtonState -MinBytes 260

$dataPolicyButtonStateText = Get-Content -LiteralPath $dataPolicyButtonState -Raw
if ($dataPolicyButtonStateText -match "`tFAIL(\r?\n|$)") {
    throw "Data policy clear button QA failed: $dataPolicyButtonState"
}
if ($dataPolicyButtonStateText -notmatch "state`tclear-data-action`t`tconfirm-button`tINFO" -or
    $dataPolicyButtonStateText -notmatch "state`tclear-data-pending`t`tidle`tINFO" -or
    $dataPolicyButtonStateText -notmatch "state`tstart-save-present`t`tno`tINFO" -or
    $dataPolicyButtonStateText -notmatch "state`tconversation-turns`t`t0`tINFO" -or
    $dataPolicyButtonStateText -notmatch "expect`tabout`tclosed`tclosed`tPASS") {
    throw "Data policy clear button QA did not prove actual button confirmation and saved-session removal: $dataPolicyButtonState"
}

Write-Step "Unity accessibility settings capture"
$accessibilityShot = Join-Path $smokeDir "accessibility-settings.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-settings",
    "--smoke-reduced-motion",
    "--smoke-high-contrast",
    "--smoke-capture", $accessibilityShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $accessibilityShot -MinBytes 100000

Write-Step "Unity accessibility settings state"
$accessibilityState = Join-Path $smokeDir "accessibility-settings.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-settings",
    "--smoke-reduced-motion",
    "--smoke-high-contrast",
    "--smoke-expect-high-contrast",
    "--smoke-state-output", $accessibilityState,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $accessibilityState -MinBytes 240

$accessibilityStateText = Get-Content -LiteralPath $accessibilityState -Raw
if ($accessibilityStateText -match "`tFAIL(\r?\n|$)") {
    throw "Accessibility settings QA failed: $accessibilityState"
}
if ($accessibilityStateText -notmatch "state`treduced-motion`t`ton`tINFO") {
    throw "Accessibility settings QA did not enable reduced motion: $accessibilityState"
}
if ($accessibilityStateText -notmatch "state`treduced-motion-label`t`t움직임 줄임 켜짐`tINFO") {
    throw "Accessibility settings QA did not show explicit reduced motion label: $accessibilityState"
}
if ($accessibilityStateText -notmatch "state`thigh-contrast-label`t`t읽기 쉬움 켜짐`tINFO") {
    throw "Accessibility settings QA did not show explicit high contrast label: $accessibilityState"
}
if ($accessibilityStateText -notmatch "state`tsound-label`t`t소리 기본`tINFO") {
    throw "Accessibility settings QA did not preserve sound label: $accessibilityState"
}
Assert-ForegroundClutterHidden -ReportPath $accessibilityState -Context "accessibility settings"

Write-Step "Unity sound settings state QA"
$soundDefaultState = Join-Path $smokeDir "sound-default.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-settings",
    "--smoke-sound-level", "default",
    "--smoke-expect-audio",
    "--smoke-state-output", $soundDefaultState,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $soundDefaultState -MinBytes 260

$soundDefaultText = Get-Content -LiteralPath $soundDefaultState -Raw
if ($soundDefaultText -match "`tFAIL(\r?\n|$)" -or
    $soundDefaultText -notmatch "state`tsound-level`t`t2`tINFO" -or
    $soundDefaultText -notmatch "state`tsound-button-label`t`t소리 기본`tINFO" -or
    $soundDefaultText -notmatch "state`tambience-playing`t`tplaying`tINFO" -or
    $soundDefaultText -notmatch "expect`taudio-settings`tconsistent`tconsistent`tPASS") {
    throw "Sound default QA failed: $soundDefaultState"
}

$soundSmallState = Join-Path $smokeDir "sound-small.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-settings",
    "--smoke-sound-level", "small",
    "--smoke-expect-audio",
    "--smoke-state-output", $soundSmallState,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $soundSmallState -MinBytes 260

$soundSmallText = Get-Content -LiteralPath $soundSmallState -Raw
if ($soundSmallText -match "`tFAIL(\r?\n|$)" -or
    $soundSmallText -notmatch "state`tsound-level`t`t1`tINFO" -or
    $soundSmallText -notmatch "state`tsound-button-label`t`t소리 작게`tINFO" -or
    $soundSmallText -notmatch "state`tambience-playing`t`tplaying`tINFO" -or
    $soundSmallText -notmatch "expect`taudio-settings`tconsistent`tconsistent`tPASS") {
    throw "Sound small QA failed: $soundSmallState"
}

$soundOffState = Join-Path $smokeDir "sound-off.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-settings",
    "--smoke-sound-level", "off",
    "--smoke-expect-audio",
    "--smoke-state-output", $soundOffState,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $soundOffState -MinBytes 260

$soundOffText = Get-Content -LiteralPath $soundOffState -Raw
if ($soundOffText -match "`tFAIL(\r?\n|$)" -or
    $soundOffText -notmatch "state`tsound-level`t`t0`tINFO" -or
    $soundOffText -notmatch "state`tsound-button-label`t`t소리 끔`tINFO" -or
    $soundOffText -notmatch "state`tambience-playing`t`tstopped`tINFO" -or
    $soundOffText -notmatch "expect`taudio-settings`tconsistent`tconsistent`tPASS") {
    throw "Sound off QA failed: $soundOffState"
}

Write-Step "Unity settings shortcut state and capture"
$shortcutSettingsReport = Join-Path $smokeDir "shortcut-settings-open.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-shortcut-action", "settings",
    "--smoke-expect-open", "settings",
    "--smoke-expect-closed", "about,records,question,memory",
    "--smoke-state-output", $shortcutSettingsReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $shortcutSettingsReport -MinBytes 120

$shortcutSettingsState = Get-Content -LiteralPath $shortcutSettingsReport -Raw
if ($shortcutSettingsState -match "`tFAIL(\r?\n|$)") {
    throw "Settings shortcut QA failed: $shortcutSettingsReport"
}

$shortcutShot = Join-Path $smokeDir "settings-shortcut-open.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-shortcut-action", "settings",
    "--smoke-capture", $shortcutShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $shortcutShot -MinBytes 100000

Write-Step "Unity gamepad shortcut state QA"
$gamepadReports = @()
$gamepadReports += Run-GamepadShortcutGuard -Name "question" -Keys @("JoystickButton2") -ExpectedOpen "question" -ExpectedClosed "memory,records,settings,about"
$gamepadReports += Run-GamepadShortcutGuard -Name "cancel" -Keys @("JoystickButton2", "JoystickButton1") -ExpectedClosed "question,memory,records,settings,about"
$gamepadReports += Run-GamepadShortcutGuard -Name "memory" -Keys @("JoystickButton3") -ExpectedOpen "memory" -ExpectedClosed "question,records,settings,about"
$gamepadReports += Run-GamepadShortcutGuard -Name "records" -Keys @("JoystickButton6") -ExpectedOpen "records" -ExpectedClosed "question,memory,settings,about"
$gamepadReports += Run-GamepadShortcutGuard -Name "settings" -Keys @("JoystickButton7") -ExpectedOpen "settings" -ExpectedClosed "question,memory,records,about"
$gamepadReports += Run-GamepadShortcutGuard -Name "note-tab-next" -SetupArgs @("--smoke-open-note") -Keys @("JoystickButton5") -ExpectedOpen "question" -ExpectedClosed "memory,records,settings,about" -ExpectedStateName "note-tab" -ExpectedStateValue "evidence"
$gamepadReports += Run-GamepadShortcutGuard -Name "lead-next" -Keys @("JoystickButton5") -ExpectedClosed "question,memory,records,settings,about" -ExpectedStateName "selected-lead-index" -ExpectedStateValue "1"
$gamepadReports += Run-GamepadShortcutGuard -Name "text-up" -SetupArgs @("--smoke-open-settings", "--smoke-dialogue-size", "normal") -Keys @("JoystickButton5") -ExpectedOpen "settings" -ExpectedClosed "question,memory,records,about" -ExpectedStateName "dialogue-size-level" -ExpectedStateValue "1"
$gamepadReports += Run-GamepadShortcutGuard -Name "primary-question" -SetupArgs @("--smoke-clear-save", "--smoke-local-only", "--smoke-dialogue-size", "normal") -Keys @("JoystickButton0") -ExpectedClosed "question,memory,records,settings,about" -ExpectedStates @("conversation-turns=1", "answer-source=local-only", "progress-label=1/5 질문 · 내장 답변", "finish-button=disabled", "finish-button-label=5문답 후") -CaptureDelay "0.8"
$gamepadReports += Run-GamepadShortcutGuard -Name "selected-question" -SetupArgs @("--smoke-clear-save", "--smoke-local-only", "--smoke-dialogue-size", "normal") -Keys @("JoystickButton5", "JoystickButton0") -ExpectedClosed "question,memory,records,settings,about" -ExpectedStates @("selected-lead-index=1", "conversation-turns=1", "answer-source=local-only", "progress-label=1/5 질문 · 내장 답변", "finish-button=disabled", "finish-button-label=5문답 후") -CaptureDelay "0.8"

Write-Step "Unity panel shortcut guard QA"
Run-PanelShortcutGuard -Name "archive-blocks-question" -SetupArgs @("--smoke-open-archive") -Key "Q" -ExpectedOpen "records" -ExpectedClosed "question,memory,settings,about"
Run-PanelShortcutGuard -Name "settings-blocks-question" -SetupArgs @("--smoke-open-settings") -Key "Q" -ExpectedOpen "settings" -ExpectedClosed "question,memory,records,about"
Run-PanelShortcutGuard -Name "question-blocks-memory" -SetupArgs @("--smoke-open-note") -Key "M" -ExpectedOpen "question" -ExpectedClosed "memory,records,settings,about"
Run-PanelShortcutGuard -Name "memory-blocks-settings" -SetupArgs @("--smoke-open-memory") -Key "S" -ExpectedOpen "memory" -ExpectedClosed "question,records,settings,about"
Run-PanelShortcutGuard -Name "archive-self-closes" -SetupArgs @("--smoke-open-archive") -Key "R" -ExpectedClosed "records"

Write-Step "Unity start info access QA"
$startUtilityReport = Join-Path $smokeDir "start-utility-visible.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-keep-start",
    "--smoke-expect-open", "start",
    "--smoke-expect-closed", "about,settings,records,question,memory",
    "--smoke-state-output", $startUtilityReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $startUtilityReport -MinBytes 120

$startUtilityState = Get-Content -LiteralPath $startUtilityReport -Raw
if ($startUtilityState -match "`tFAIL(\r?\n|$)") {
    throw "Start utility visibility QA failed: $startUtilityReport"
}
if ($startUtilityState -notmatch "state`tstart-about-visible`t`tvisible`tINFO" -or $startUtilityState -notmatch "state`tstart-settings-visible`t`tvisible`tINFO") {
    throw "Start utility visibility QA did not show visible settings/info buttons: $startUtilityReport"
}
if ($startUtilityState -notmatch "state`tstart-objective-visible`t`tvisible`tINFO" -or $startUtilityState -notmatch "expect`tstart-objective`t겉 장면/속 맥락`tpresent`tPASS") {
    throw "Start objective QA did not show the first-screen objective line: $startUtilityReport"
}
if ($startUtilityState -notmatch "state`tfirst-impression-option-map`t`t목발 -> 이동 · 책상 -> 일과 공부 · 표정 -> 일상`tINFO" -or
    $startUtilityState -notmatch "state`tfirst-impression-display`t`t첫 인상 없이 대화 시작`tINFO" -or
    $startUtilityState -notmatch "state`tfirst-impression-option-1-label`t`t목발 이동 장면`tINFO" -or
    $startUtilityState -notmatch "state`tfirst-impression-option-2-label`t`t책상 일과 공부 장면`tINFO") {
    throw "First impression option QA did not show the outside/inside scene mapping: $startUtilityReport"
}
if ($startUtilityState -notmatch "state`tquestion-chapter-state-line`t`t장면 버튼: 열기 6 · 깊게 0 · 깊음 0`tINFO" -or
    $startUtilityState -notmatch "state`tquestion-chapter-1-label`t`t일상 · 열기`tINFO" -or
    $startUtilityState -notmatch "state`tquestion-chapter-3-label`t`t도움 · 열기`tINFO") {
    throw "Question chapter state QA did not show open/deepen/deep labels: $startUtilityReport"
}
if ($startUtilityState -notmatch "state`tclosing-recommendation-line`t`t도움 방식은 아직 질문 태도가 쌓이지 않은 상태에서 도움을 먼저 묻는 방향을 제안합니다\.`tINFO") {
    throw "Start-state closing recommendation QA did not avoid an awkward empty-attitude sentence: $startUtilityReport"
}

$startInfoReport = Join-Path $smokeDir "start-info-access.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-keep-start",
    "--smoke-shortcut-action", "info",
    "--smoke-expect-open", "about,start",
    "--smoke-expect-closed", "settings,records,question,memory",
    "--smoke-state-output", $startInfoReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $startInfoReport -MinBytes 50

$startInfoState = Get-Content -LiteralPath $startInfoReport -Raw
if ($startInfoState -match "`tFAIL(\r?\n|$)") {
    throw "Start info access QA failed: $startInfoReport"
}

Write-Step "Unity long-dialogue paged capture"
$longShot = Join-Path $smokeDir "long-dialogue.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-long-dialogue",
    "--smoke-capture", $longShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $longShot -MinBytes 100000

Write-Step "Unity long-dialogue paged layout state"
$longLayoutReport = Join-Path $smokeDir "long-dialogue-layout.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-long-dialogue",
    "--smoke-expect-dialogue-scrollable",
    "--smoke-state-output", $longLayoutReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $longLayoutReport -MinBytes 180

$longLayoutState = Get-Content -LiteralPath $longLayoutReport -Raw
if ($longLayoutState -match "`tFAIL(\r?\n|$)") {
    throw "Long dialogue paged layout QA failed: $longLayoutReport"
}

Write-Step "Unity hotspot preview capture"
$hotspotPreviewShot = Join-Path $smokeDir "hotspot-preview.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-hotspot-preview",
    "--smoke-capture", $hotspotPreviewShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $hotspotPreviewShot -MinBytes 100000

Write-Step "Unity hotspot preview foreground clutter state"
$hotspotClutterReport = Join-Path $smokeDir "foreground-clutter-hotspot.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-open-hotspot-preview",
    "--smoke-expect-open", "hotspot",
    "--smoke-state-output", $hotspotClutterReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-ForegroundClutterHidden -ReportPath $hotspotClutterReport -Context "hotspot preview"

Write-Step "Unity question phone capture"
$phoneShot = Join-Path $smokeDir "question-phone.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-note",
    "--smoke-capture", $phoneShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $phoneShot -MinBytes 100000

Write-Step "Unity question phone evidence tab capture"
$phoneEvidenceShot = Join-Path $smokeDir "question-phone-evidence.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-seed-save",
    "--smoke-load-save",
    "--smoke-note-tab", "evidence",
    "--smoke-capture", $phoneEvidenceShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $phoneEvidenceShot -MinBytes 100000

Write-Step "Unity question phone history tab capture"
$phoneHistoryShot = Join-Path $smokeDir "question-phone-history.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-seed-save",
    "--smoke-load-save",
    "--smoke-note-tab", "history",
    "--smoke-capture", $phoneHistoryShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $phoneHistoryShot -MinBytes 100000

Write-Step "Unity completed memory book capture"
$memoryShot = Join-Path $smokeDir "memory-complete.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-memory-filled",
    "--smoke-capture", $memoryShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $memoryShot -MinBytes 100000

Write-Step "Unity memory book foreground clutter state"
$memoryClutterReport = Join-Path $smokeDir "foreground-clutter-memory.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-memory-filled",
    "--smoke-expect-open", "memory",
    "--smoke-state-output", $memoryClutterReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-ForegroundClutterHidden -ReportPath $memoryClutterReport -Context "memory book"

Write-Step "Unity closing card capture"
$closingShot = Join-Path $smokeDir "closing-card.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-capture", $closingShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $closingShot -MinBytes 100000

Write-Step "Unity closing card shortcut state"
$closingShortcutReport = Join-Path $smokeDir "closing-card-shortcuts.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-key", "RightArrow",
    "--smoke-expect-open", "closing",
    "--smoke-state-output", $closingShortcutReport,
    "--smoke-capture-delay", "0.2"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $closingShortcutReport -MinBytes 240

$closingShortcutState = Get-Content -LiteralPath $closingShortcutReport -Raw
if ($closingShortcutState -match "`tFAIL(\r?\n|$)") {
    throw "Closing card shortcut QA failed: $closingShortcutReport"
}
if ($closingShortcutState -notmatch "state`tclosing-shortcut-action`t`tnext-key`tINFO" -or
    $closingShortcutState -notmatch "state`tfirst-impression-display`t`t첫 인상 없이 대화 시작`tINFO" -or
    $closingShortcutState -notmatch "state`tselected-closing-index`t`t1`tINFO" -or
    $closingShortcutState -notmatch "state`tselected-closing-label`t`t이동 확인`tINFO" -or
    $closingShortcutState -notmatch "expect`tclosing`topen`topen`tPASS") {
    throw "Closing card keyboard shortcut did not select the second closing sentence: $closingShortcutReport"
}

Write-Step "Unity closing card save button state"
$closingSaveButtonReport = Join-Path $smokeDir "closing-card-save-button.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-click-closing-save",
    "--smoke-expect-open", "records",
    "--smoke-state-output", $closingSaveButtonReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $closingSaveButtonReport -MinBytes 260

$closingSaveButtonState = Get-Content -LiteralPath $closingSaveButtonReport -Raw
if ($closingSaveButtonState -match "`tFAIL(\r?\n|$)") {
    throw "Closing card save button QA failed: $closingSaveButtonReport"
}
if ($closingSaveButtonState -notmatch "state`tclosing-shortcut-action`t`tsave-button`tINFO" -or
    $closingSaveButtonState -notmatch "state`tclosing-save-button-label`t`t저장 후 보기`tINFO" -or
    $closingSaveButtonState -notmatch "state`tfeedback-ending-record-saved`t`ttrue`tINFO" -or
    $closingSaveButtonState -notmatch "expect`trecords`topen`topen`tPASS") {
    throw "Closing card save button did not save the ending record and open the archive: $closingSaveButtonReport"
}

Write-Step "Unity closing card continue button state"
$closingContinueButtonReport = Join-Path $smokeDir "closing-card-continue-button.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-click-closing-continue",
    "--smoke-expect-closed", "closing,records,question,memory,settings,about,feedback",
    "--smoke-state-output", $closingContinueButtonReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $closingContinueButtonReport -MinBytes 260

$closingContinueButtonState = Get-Content -LiteralPath $closingContinueButtonReport -Raw
if ($closingContinueButtonState -match "`tFAIL(\r?\n|$)") {
    throw "Closing card continue button QA failed: $closingContinueButtonReport"
}
if ($closingContinueButtonState -notmatch "state`tclosing-shortcut-action`t`tcontinue-button`tINFO" -or
    $closingContinueButtonState -notmatch "state`tclosing-continue-button-label`t`t계속하기`tINFO" -or
    $closingContinueButtonState -notmatch "state`tfeedback-ending-record-saved`t`tfalse`tINFO" -or
    $closingContinueButtonState -notmatch "expect`tclosing`tclosed`tclosed`tPASS") {
    throw "Closing card continue button did not close the closing card without saving a record: $closingContinueButtonReport"
}

Write-Step "Unity five-turn playthrough and save state"
$fiveTurnPlaythroughReport = Join-Path $smokeDir "five-turn-playthrough.tsv"
$fiveTurnQuestions = "처음 가는 공간에서는 무엇을 먼저 확인하나요?|도움을 받을 때는 어떻게 물어보면 좋나요?|책상과 노트북은 어떤 장면을 보여주나요?|자취방은 독립과 어떤 관련이 있나요?|취미 이야기는 왜 같이 중요할까요?"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-clear-save",
    "--smoke-skip-start",
    "--smoke-local-only",
    "--smoke-submit-questions", $fiveTurnQuestions,
    "--smoke-open-closing-after-questions",
    "--smoke-save-ending-after-questions",
    "--smoke-expect-open", "records",
    "--smoke-expect-closed", "question,memory,settings,about,feedback",
    "--smoke-state-output", $fiveTurnPlaythroughReport,
    "--smoke-capture-delay", "1.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $fiveTurnPlaythroughReport -MinBytes 260

$fiveTurnPlaythroughState = Get-Content -LiteralPath $fiveTurnPlaythroughReport -Raw
if ($fiveTurnPlaythroughState -match "`tFAIL(\r?\n|$)") {
    throw "Five-turn playthrough QA failed: $fiveTurnPlaythroughReport"
}
if ($fiveTurnPlaythroughState -notmatch "state`tconversation-turns`t`t5`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tfinish-button`t`tenabled`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tfinish-button-label`t`t끝내기`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tanswer-source`t`tlocal-only`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tprogress-label`t`t마무리 가능 · 내장 답변`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tfirst-impression-display`t`t첫 인상 없이 대화 시작`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tfeedback-quality-focus-label`t`t초점: 전체 느낌`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tfeedback-commercial-quality-evidence`t`t점수표 보류: 5달러 충분 판정 전 다음 외부 리뷰에서 재확인 필요\.`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "state`tclosing-recommendation-line`t`t이동 확인은 대화에서 열린 장면을 하루 동선 확인으로 정리합니다\.`tINFO" -or
    $fiveTurnPlaythroughState -notmatch "expect`trecords`topen`topen`tPASS") {
    throw "Five-turn playthrough QA did not prove completion, finish readiness, local answer source, and saved record archive: $fiveTurnPlaythroughReport"
}

Write-Step "Unity first impression deep arc state"
$firstImpressionArcCases = @(
    @{
        Name = "crutch"
        Impression = "목발"
        Theme = "이동"
        ClosingLabel = "이동 확인"
        Questions = "목발이 하루의 이동 방식과 어떻게 이어지나요?|도움을 건넬 때 어떤 말로 먼저 물으면 좋을까요?|책상과 노트북은 어떤 의미인가요?|자취방이 독립과 자기이해에 어떤 의미였나요?|취미 이야기는 왜 같이 중요할까요?"
        Target = "첫 인상 목발이 이동 깊은 기록으로 이어졌습니다."
        ArcPrefix = "처음 본 목발이 이동 깊은 기록까지 이어져"
    },
    @{
        Name = "desk"
        Impression = "책상"
        Theme = "일과 공부"
        ClosingLabel = "사람 보기"
        Questions = "책상이 일과 공부, 이동의 리듬과 어떻게 이어지나요?|일과 공부를 이어갈 때 가장 신경 쓰는 점은 무엇인가요?|자취방이 독립과 자기이해에 어떤 의미였나요?|취미 이야기는 왜 같이 중요할까요?|목발보다 먼저 보아야 할 하루의 장면은 무엇인가요?"
        Target = "첫 인상 책상이 일과 공부 깊은 기록으로 이어졌습니다."
        ArcPrefix = "처음 본 책상이 일과 공부 깊은 기록까지 이어져"
    },
    @{
        Name = "face"
        Impression = "표정"
        Theme = "일상"
        ClosingLabel = "사람 보기"
        Questions = "표정 너머의 평범한 하루는 어떤 장면으로 이어지나요?|목발보다 먼저 보아야 할 하루의 장면은 무엇인가요?|일과 공부를 이어갈 때 가장 신경 쓰는 점은 무엇인가요?|자취방이 독립과 자기이해에 어떤 의미였나요?|취미 이야기는 왜 같이 중요할까요?"
        Target = "첫 인상 표정이 일상 깊은 기록으로 이어졌습니다."
        ArcPrefix = "처음 본 표정이 일상 깊은 기록까지 이어져"
    }
)
foreach ($case in $firstImpressionArcCases) {
    $firstImpressionArcReport = Join-Path $smokeDir "first-impression-$($case.Name)-deep-arc.tsv"
    Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
        "--smoke-clear-save",
        "--smoke-skip-start",
        "--smoke-local-only",
        "--smoke-first-impression", $case.Impression,
        "--smoke-submit-questions", $case.Questions,
        "--smoke-open-closing-after-questions",
        "--smoke-expect-open", "closing",
        "--smoke-expect-closed", "question,memory,settings,about,feedback,records",
        "--smoke-state-output", $firstImpressionArcReport,
        "--smoke-capture-delay", "1.5"
    ) -WorkingDirectory $buildDir -Retries 1
    Assert-File -Path $firstImpressionArcReport -MinBytes 300

    $firstImpressionArcState = Get-Content -LiteralPath $firstImpressionArcReport -Raw
    if ($firstImpressionArcState -match "`tFAIL(\r?\n|$)") {
        throw "First impression deep arc QA failed: $firstImpressionArcReport"
    }

    $requiredFirstImpressionStates = @(
        "state`tbuild-id`t`t$currentBuildId`tINFO",
        "state`tfirst-impression`t`t$($case.Impression)`tINFO",
        "state`tfirst-impression-theme`t`t$($case.Theme)`tINFO",
        "state`tfirst-impression-theme-opened`t`ttrue`tINFO",
        "state`tfirst-impression-theme-deep`t`ttrue`tINFO",
        "state`tfirst-impression-target`t`t$($case.Target)`tINFO",
        "state`tselected-closing-label`t`t$($case.ClosingLabel)`tINFO",
        "expect`tclosing`topen`topen`tPASS"
    )
    foreach ($requiredState in $requiredFirstImpressionStates) {
        if ($firstImpressionArcState -notmatch [regex]::Escape($requiredState)) {
            throw "First impression deep arc QA is missing '$requiredState': $firstImpressionArcReport"
        }
    }
    if ($firstImpressionArcState -notmatch [regex]::Escape("state`tfirst-impression-arc`t`t$($case.ArcPrefix)")) {
        throw "First impression deep arc QA did not prove the $($case.Impression) -> $($case.Theme) -> 깊은 기록 path: $firstImpressionArcReport"
    }
}

Write-Step "Unity playtest feedback capture"
$feedbackShot = Join-Path $smokeDir "playtest-feedback.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-open-feedback",
    "--smoke-capture", $feedbackShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $feedbackShot -MinBytes 100000

Write-Step "Unity playtest feedback keyboard shortcut state"
$feedbackShortcutReport = Join-Path $smokeDir "playtest-feedback-shortcuts.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-open-feedback",
    "--smoke-key", "F1",
    "--smoke-key", "F6",
    "--smoke-key", "F9",
    "--smoke-key", "F11",
    "--smoke-expect-open", "feedback",
    "--smoke-state-output", $feedbackShortcutReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $feedbackShortcutReport -MinBytes 260
$feedbackShortcutState = Get-Content -LiteralPath $feedbackShortcutReport -Raw
if ($feedbackShortcutState -match "`tFAIL(\r?\n|$)") {
    throw "Playtest feedback keyboard shortcut QA failed: $feedbackShortcutReport"
}
if ($feedbackShortcutState -notmatch "state`tfeedback-shortcut-action`t`tsave-key`tINFO" -or
    $feedbackShortcutState -notmatch "state`tfeedback-selected-group`t`t문제 단계`tINFO" -or
    $feedbackShortcutState -notmatch "state`tfeedback-rating`t`t헷갈림`tINFO" -or
    $feedbackShortcutState -notmatch "state`tfeedback-commercial-readiness`t`t충분`tINFO" -or
    $feedbackShortcutState -notmatch "state`tfeedback-issue-severity`t`tP1`tINFO" -or
    $feedbackShortcutState -notmatch "state`tfeedback-status`t`t더 다듬기, 조금 아쉬움, 문제 있음을 고른 경우에는 수정할 근거를 짧게 남겨 주세요\.`tINFO") {
    throw "Playtest feedback keyboard shortcut QA did not prove selection and guarded save: $feedbackShortcutReport"
}

Write-Step "Unity playtest feedback note requirement QA"
$feedbackRequireNoteReport = Join-Path $smokeDir "playtest-feedback-require-note.tsv"
$feedbackRequireNoteRoot = Join-Path $smokeDir "playtest-feedback-require-note-files"
if (Test-Path -LiteralPath $feedbackRequireNoteRoot) {
    Remove-Item -LiteralPath $feedbackRequireNoteRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $feedbackRequireNoteRoot | Out-Null
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-feedback-require-note",
    "--smoke-feedback-output", $feedbackRequireNoteRoot,
    "--smoke-expect-open", "feedback",
    "--smoke-state-output", $feedbackRequireNoteReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $feedbackRequireNoteReport -MinBytes 240

$feedbackRequireNoteState = Get-Content -LiteralPath $feedbackRequireNoteReport -Raw
if ($feedbackRequireNoteState -match "`tFAIL(\r?\n|$)") {
    throw "Playtest feedback note requirement QA failed: $feedbackRequireNoteReport"
}
if ($feedbackRequireNoteState -notmatch "state`tfeedback-status`t`t더 다듬기, 조금 아쉬움, 문제 있음을 고른 경우에는 수정할 근거를 짧게 남겨 주세요\.`tINFO" -or
    $feedbackRequireNoteState -notmatch "state`tfeedback-note-length`t`t0`tINFO" -or
    $feedbackRequireNoteState -notmatch "state`tfeedback-commercial-readiness`t`t부족`tINFO" -or
    $feedbackRequireNoteState -notmatch "state`tfeedback-issue-severity`t`tP1`tINFO" -or
    $feedbackRequireNoteState -notmatch "state`tfeedback-quality-focus-label`t`t초점: 전체 느낌`tINFO" -or
    $feedbackRequireNoteState -notmatch "state`tfeedback-commercial-quality-evidence`t`t점수표 보류: P1 이슈를 외부 이슈 레지스터에 등록해야 합니다\.`tINFO" -or
    $feedbackRequireNoteState -notmatch "state`tfeedback-issue-severity-label`t`t진행 방해`tINFO") {
    throw "Playtest feedback note requirement QA did not prove blocked low-score save: $feedbackRequireNoteReport"
}
$unexpectedFeedbackFiles = @(Get-ChildItem -LiteralPath $feedbackRequireNoteRoot -File -ErrorAction SilentlyContinue)
if ($unexpectedFeedbackFiles.Count -ne 0) {
    throw "Playtest feedback note requirement QA wrote files despite missing note: $feedbackRequireNoteRoot"
}

Write-Step "Unity playtest feedback complete-session requirement QA"
$feedbackRequireCompleteReport = Join-Path $smokeDir "playtest-feedback-require-complete-session.tsv"
$feedbackRequireCompleteRoot = Join-Path $smokeDir "playtest-feedback-require-complete-session-files"
if (Test-Path -LiteralPath $feedbackRequireCompleteRoot) {
    Remove-Item -LiteralPath $feedbackRequireCompleteRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $feedbackRequireCompleteRoot | Out-Null
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-feedback-require-complete-session",
    "--smoke-feedback-output", $feedbackRequireCompleteRoot,
    "--smoke-expect-open", "feedback",
    "--smoke-state-output", $feedbackRequireCompleteReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $feedbackRequireCompleteReport -MinBytes 280

$feedbackRequireCompleteState = Get-Content -LiteralPath $feedbackRequireCompleteReport -Raw
if ($feedbackRequireCompleteState -match "`tFAIL(\r?\n|$)") {
    throw "Playtest feedback complete-session requirement QA failed: $feedbackRequireCompleteReport"
}
if ($feedbackRequireCompleteState -notmatch "state`tfeedback-status`t`t좋음, 충분함, 문제 없음은 5문답 완료 뒤에 저장해 주세요\. 중도 문제는 단계와 메모로 저장할 수 있습니다\.`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-completed-five-turn-session`t`tfalse`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-ending-record-saved`t`tfalse`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-positive-quality-ready`t`tfalse`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-rating`t`t좋음`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-commercial-readiness`t`t충분`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-issue-severity`t`t없음`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-commercial-quality-evidence`t`t점수표 보류: 긍정 판정 전에 5문답 완료 증거가 필요합니다\.`tINFO" -or
    $feedbackRequireCompleteState -notmatch "state`tfeedback-issue-severity-label`t`t문제 없음`tINFO") {
    throw "Playtest feedback complete-session requirement QA did not prove blocked positive incomplete save: $feedbackRequireCompleteReport"
}
$unexpectedCompleteFiles = @(Get-ChildItem -LiteralPath $feedbackRequireCompleteRoot -File -ErrorAction SilentlyContinue)
if ($unexpectedCompleteFiles.Count -ne 0) {
    throw "Playtest feedback complete-session requirement QA wrote files despite incomplete session: $feedbackRequireCompleteRoot"
}

Write-Step "Unity playtest feedback ending-record requirement QA"
$feedbackRequireEndingReport = Join-Path $smokeDir "playtest-feedback-require-ending-record.tsv"
$feedbackRequireEndingRoot = Join-Path $smokeDir "playtest-feedback-require-ending-record-files"
if (Test-Path -LiteralPath $feedbackRequireEndingRoot) {
    Remove-Item -LiteralPath $feedbackRequireEndingRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $feedbackRequireEndingRoot | Out-Null
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-feedback-require-complete-session",
    "--smoke-feedback-output", $feedbackRequireEndingRoot,
    "--smoke-expect-open", "feedback",
    "--smoke-state-output", $feedbackRequireEndingReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $feedbackRequireEndingReport -MinBytes 300

$feedbackRequireEndingState = Get-Content -LiteralPath $feedbackRequireEndingReport -Raw
if ($feedbackRequireEndingState -match "`tFAIL(\r?\n|$)") {
    throw "Playtest feedback ending-record requirement QA failed: $feedbackRequireEndingReport"
}
if ($feedbackRequireEndingState -notmatch "state`tfeedback-status`t`t좋음, 충분함, 문제 없음은 마무리 기록을 저장한 뒤에 품질 근거로 남길 수 있습니다\.`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-completed-five-turn-session`t`ttrue`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-ending-record-saved`t`tfalse`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-positive-quality-ready`t`tfalse`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-evidence-tier`t`tending-record-needed`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-rating`t`t좋음`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-commercial-readiness`t`t충분`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-commercial-quality-evidence`t`t점수표 보류: 긍정 판정 전에 마무리 기록 저장 증거가 필요합니다\.`tINFO" -or
    $feedbackRequireEndingState -notmatch "state`tfeedback-issue-severity`t`t없음`tINFO") {
    throw "Playtest feedback ending-record requirement QA did not prove blocked positive save without ending record: $feedbackRequireEndingReport"
}
$unexpectedEndingFiles = @(Get-ChildItem -LiteralPath $feedbackRequireEndingRoot -File -ErrorAction SilentlyContinue)
if ($unexpectedEndingFiles.Count -ne 0) {
    throw "Playtest feedback ending-record requirement QA wrote files despite missing ending record: $feedbackRequireEndingRoot"
}

Write-Step "Unity playtest feedback save QA"
$feedbackSavedShot = Join-Path $smokeDir "playtest-feedback-saved.png"
$feedbackQaRoot = Join-Path $smokeDir "playtest-feedback-files"
if (Test-Path -LiteralPath $feedbackQaRoot) {
    Remove-Item -LiteralPath $feedbackQaRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $feedbackQaRoot | Out-Null
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-save-ending",
    "--smoke-save-feedback",
    "--smoke-feedback-output", $feedbackQaRoot,
    "--smoke-capture", $feedbackSavedShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $feedbackSavedShot -MinBytes 100000
$feedbackText = Get-ChildItem -LiteralPath $feedbackQaRoot -Filter "*.txt" -File | Select-Object -First 1
$feedbackJson = Get-ChildItem -LiteralPath $feedbackQaRoot -Filter "*.json" -File | Select-Object -First 1
if (-not $feedbackText -or -not $feedbackJson) {
    throw "Playtest feedback save did not create both txt and json files."
}
$feedbackTextContent = Get-Content -LiteralPath $feedbackText.FullName -Raw
if ($feedbackTextContent -notmatch "세션 ID:" -or $feedbackTextContent -notmatch "빌드 ID:" -or $feedbackTextContent -notmatch "설정:" -or $feedbackTextContent -notmatch "상업 품질 근거:") {
    throw "Playtest feedback txt is missing session/build/settings metadata."
}
$feedbackManifest = Get-Content -LiteralPath $feedbackJson.FullName -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$feedbackManifest.sessionId) -or [string]::IsNullOrWhiteSpace([string]$feedbackManifest.buildId) -or [string]$feedbackManifest.buildId -eq "unknown") {
    throw "Playtest feedback json is missing a valid sessionId or buildId."
}
if (-not [bool]$feedbackManifest.completedFiveTurnSession -or -not [bool]$feedbackManifest.endingRecordSavedThisSession -or -not [bool]$feedbackManifest.qualityEvidenceReady) {
    throw "Playtest feedback json did not mark the completed ending-record positive quality evidence state."
}
if ([string]::IsNullOrWhiteSpace([string]$feedbackManifest.commercialQualityEvidenceLine) -or [string]$feedbackManifest.commercialQualityEvidenceLine -notmatch "점수표 후보") {
    throw "Playtest feedback json is missing the positive commercial quality evidence line."
}
$feedbackExportQa = Join-Path $PSScriptRoot "ValidatePlaytestFeedbackExport.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $feedbackExportQa,
    "-FeedbackRoot", $feedbackQaRoot,
    "-RequireFiveTurnSession"
) -WorkingDirectory $repoRoot

Write-Step "Unity ending archive capture"
$archiveShot = Join-Path $smokeDir "ending-archive.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-fill-memory",
    "--smoke-open-closing",
    "--smoke-save-ending",
    "--smoke-capture", $archiveShot,
    "--smoke-capture-delay", "0.8"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $archiveShot -MinBytes 100000

Write-Step "Unity record delete confirmation capture"
$deleteShot = Join-Path $smokeDir "record-delete-confirm.png"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-save-ending",
    "--smoke-open-archive",
    "--smoke-delete-record-prompt",
    "--smoke-capture", $deleteShot,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $deleteShot -MinBytes 100000

Write-Step "Unity record delete confirmation state"
$deleteState = Join-Path $smokeDir "record-delete-confirm.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-save-ending",
    "--smoke-open-archive",
    "--smoke-delete-record-prompt",
    "--smoke-expect-record-delete-prompt",
    "--smoke-state-output", $deleteState,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $deleteState -MinBytes 180
$deleteStateText = Get-Content -LiteralPath $deleteState -Raw
if ($deleteStateText -match "`tFAIL(\r?\n|$)") {
    throw "Record delete confirmation QA failed: $deleteState"
}
if ($deleteStateText -notmatch "state`trecord-delete-cancel`t취소`t취소`tPASS") {
    throw "Record delete confirmation QA did not prove visible cancel action: $deleteState"
}
if ($deleteStateText -notmatch "state`trecord-archive-first-label`t`t[^\r\n]*문답[^\r\n]*장면[^\r\n]*`tINFO") {
    throw "Record archive QA did not show session metadata in the first saved-record label: $deleteState"
}

Write-Step "Unity record archive keyboard action state"
$recordArchiveShortcutReport = Join-Path $smokeDir "record-archive-shortcuts.tsv"
Run-UnitySmokeChecked -FilePath $appExe -ArgumentList @(
    "--smoke-skip-start",
    "--smoke-save-ending",
    "--smoke-open-archive",
    "--smoke-key", "DownArrow",
    "--smoke-key", "Delete",
    "--smoke-expect-record-delete-prompt",
    "--smoke-state-output", $recordArchiveShortcutReport,
    "--smoke-capture-delay", "0.5"
) -WorkingDirectory $buildDir -Retries 1
Assert-File -Path $recordArchiveShortcutReport -MinBytes 220
$recordArchiveShortcutState = Get-Content -LiteralPath $recordArchiveShortcutReport -Raw
if ($recordArchiveShortcutState -match "`tFAIL(\r?\n|$)") {
    throw "Record archive keyboard action QA failed: $recordArchiveShortcutReport"
}
if ($recordArchiveShortcutState -notmatch "state`trecord-archive-shortcut-action`t`tdelete-key`tINFO" -or
    $recordArchiveShortcutState -notmatch "state`tselected-record-archive-index`t`t[0-5]`tINFO" -or
    $recordArchiveShortcutState -notmatch "state`trecord-delete-pending`t`tpending`tPASS") {
    throw "Record archive keyboard shortcut did not select and arm deletion: $recordArchiveShortcutReport"
}

Write-Step "Steam screenshot promotion"
$promoteScreenshotsScript = Join-Path $PSScriptRoot "PromoteSteamScreenshots.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $promoteScreenshotsScript,
    "-SourceRoot", $smokeDir
) -WorkingDirectory $repoRoot

Write-Step "Screenshot trailer animatic generation"
$trailerAnimatic = Join-Path $projectRoot "Marketing\Trailer\trailer_animatic_60s.mp4"
$trailerAnimaticScript = Join-Path $PSScriptRoot "GenerateTrailerAnimatic.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $trailerAnimaticScript,
    "-OutputPath", $trailerAnimatic
) -WorkingDirectory $repoRoot
Assert-File -Path $trailerAnimatic -MinBytes 100000

Write-Step "Steam capsule asset generation"
$steamKeyArtSource = Join-Path $projectRoot "Marketing\SteamAssets\source_keyart_1920x1080.png"
$steamProfessionalKeyArt = Join-Path $projectRoot "Marketing\SteamAssets\professional_keyart_1920x1080.png"
$captureSteamKeyArtScript = Join-Path $PSScriptRoot "CaptureSteamKeyArt.ps1"
$prepareProfessionalKeyArtScript = Join-Path $PSScriptRoot "PrepareProfessionalKeyArt.ps1"
$steamAssetScript = Join-Path $PSScriptRoot "GenerateSteamAssets.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $captureSteamKeyArtScript,
    "-OutputPath", $steamKeyArtSource
) -WorkingDirectory $repoRoot
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $prepareProfessionalKeyArtScript,
    "-SourceImage", $steamKeyArtSource,
    "-OutputPath", $steamProfessionalKeyArt
) -WorkingDirectory $repoRoot
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $steamAssetScript
) -WorkingDirectory $repoRoot

Write-Step "Post-capture marketing asset QA"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $steamAssetQa
) -WorkingDirectory $repoRoot

Write-Step "Visual quality QA"
$visualQualityQa = Join-Path $PSScriptRoot "ValidateVisualQuality.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $visualQualityQa
) -WorkingDirectory $repoRoot

Write-Step "Accessibility automation QA"
$accessibilityAutomationQa = Join-Path $PSScriptRoot "ValidateAccessibilityAutomation.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $accessibilityAutomationQa
) -WorkingDirectory $repoRoot

Write-Step "Steam/legal readiness QA"
$steamLegalQa = Join-Path $PSScriptRoot "ValidateSteamLegalReadiness.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $steamLegalQa
) -WorkingDirectory $repoRoot

Write-Step "Build capture trailer generation"
$buildCaptureTrailer = Join-Path $projectRoot "Marketing\Trailer\trailer_build_capture_60s.mp4"
$buildCaptureTrailerScript = Join-Path $PSScriptRoot "GenerateBuildCaptureTrailer.ps1"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $buildCaptureTrailerScript,
    "-SourceRoot", $smokeDir,
    "-OutputPath", $buildCaptureTrailer
) -WorkingDirectory $repoRoot
Assert-File -Path $buildCaptureTrailer -MinBytes 100000

Write-Step "Final trailer asset QA"
Run-ProcessChecked -FilePath $powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $trailerAssetQa
) -WorkingDirectory $repoRoot

Write-Host ""
Write-Host "Release smoke passed."
Write-Host "Screenshots: $smokeDir"
