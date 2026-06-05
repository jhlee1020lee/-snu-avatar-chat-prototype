param(
    [string]$OutputPath,
    [int]$StartupTimeoutSeconds = 6
)

$ErrorActionPreference = "Stop"

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

function Get-FreeLoopbackPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return $listener.LocalEndpoint.Port
    }
    finally {
        $listener.Stop()
    }
}

function Add-Result {
    param(
        [string]$Case,
        [string]$Status,
        [string]$Detail
    )

    $script:results.Add([pscustomobject]@{
        Case = $Case
        Status = $Status
        Detail = $Detail
    }) | Out-Null
}

function Escape-MarkdownCell {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Invoke-ModelCase {
    param(
        [string]$CaseName,
        [hashtable]$Env,
        [string]$ExpectedModel,
        [string]$ExpectedSource,
        [string]$ExpectedRequestedSource,
        [string]$ExpectedNotePattern = "",
        [switch]$ExpectLocalChat
    )

    $port = Get-FreeLoopbackPort
    $envNames = @(
        "PORT",
        "OPENAI_API_KEY",
        "OPENAI_CHAT_MODEL",
        "OPENAI_MODEL",
        "OPENAI_TRANSCRIBE_MODEL",
        "OPENAI_TTS_MODEL",
        "OPENAI_TTS_VOICE"
    )
    $previousEnv = @{}
    foreach ($name in $envNames) {
        $previousEnv[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
    }

    $serverProcess = $null
    try {
        $env:PORT = [string]$port
        foreach ($envName in $envNames | Where-Object { $_ -ne "PORT" }) {
            Remove-Item "Env:\$envName" -ErrorAction SilentlyContinue
        }
        foreach ($key in $Env.Keys) {
            [Environment]::SetEnvironmentVariable($key, [string]$Env[$key], "Process")
        }

        $serverProcess = Start-Process -FilePath $script:node -ArgumentList "server.js" -WorkingDirectory $script:serverRoot -PassThru -WindowStyle Hidden

        $deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
        $config = $null
        do {
            Start-Sleep -Milliseconds 250
            try {
                $config = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/config" -Method Get -TimeoutSec 1
            }
            catch {
                $config = $null
            }
        } while (-not $config -and (Get-Date) -lt $deadline)

        if (-not $config) {
            throw "Server did not answer /api/config on port $port."
        }
        if ([string]$config.chatModel -ne $ExpectedModel) {
            throw "Expected chatModel '$ExpectedModel', got '$($config.chatModel)'."
        }
        if ([string]$config.chatModelSource -ne $ExpectedSource) {
            throw "Expected chatModelSource '$ExpectedSource', got '$($config.chatModelSource)'."
        }
        if ([string]$config.chatModelRequestedSource -ne $ExpectedRequestedSource) {
            throw "Expected chatModelRequestedSource '$ExpectedRequestedSource', got '$($config.chatModelRequestedSource)'."
        }
        if (-not [string]::IsNullOrWhiteSpace($ExpectedNotePattern) -and [string]$config.chatModelNote -notmatch $ExpectedNotePattern) {
            throw "Expected chatModelNote to match '$ExpectedNotePattern', got '$($config.chatModelNote)'."
        }

        if ($ExpectLocalChat) {
            $payload = @{
                messages = @(
                    @{
                        role = "user"
                        content = "처음 가는 공간에서는 무엇을 먼저 확인하나요?"
                    }
                )
            } | ConvertTo-Json -Depth 5

            $reply = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/api/chat" -ContentType "application/json; charset=utf-8" -Body $payload -TimeoutSec 5
            if ([string]$reply.source -ne "local") {
                throw "Expected local source without API key, got '$($reply.source)'."
            }
            if ([string]::IsNullOrWhiteSpace([string]$reply.reply)) {
                throw "Local reply was empty."
            }
        }

        Add-Result -Case $CaseName -Status "통과" -Detail "chatModel=$($config.chatModel), source=$($config.chatModelSource)"
    }
    catch {
        Add-Result -Case $CaseName -Status "실패" -Detail $_.Exception.Message
    }
    finally {
        if ($serverProcess -and -not $serverProcess.HasExited) {
            Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        }

        foreach ($name in $envNames) {
            if ($null -eq $previousEnv[$name]) {
                Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
            }
            else {
                [Environment]::SetEnvironmentVariable($name, [string]$previousEnv[$name], "Process")
            }
        }
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$docsRoot = Join-Path $projectRoot "Docs"
$node = Resolve-Tool @("node.exe", "node")

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $docsRoot "MODEL_CONFIG_QA.md"
}

& $node --check (Join-Path $serverRoot "server.js") | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "server.js syntax check failed."
}

$results = New-Object System.Collections.Generic.List[object]

Invoke-ModelCase `
    -CaseName "기본 모델" `
    -Env @{} `
    -ExpectedModel "gpt-5.4-mini" `
    -ExpectedSource "fixed" `
    -ExpectedRequestedSource "default" `
    -ExpectLocalChat

Invoke-ModelCase `
    -CaseName "구버전 환경 변수 무시" `
    -Env @{ OPENAI_MODEL = "gpt-5.2" } `
    -ExpectedModel "gpt-5.4-mini" `
    -ExpectedSource "fixed" `
    -ExpectedRequestedSource "OPENAI_MODEL_IGNORED" `
    -ExpectedNotePattern "무시" `
    -ExpectLocalChat

Invoke-ModelCase `
    -CaseName "짧은 모델명 5.4 호환 정규화" `
    -Env @{ OPENAI_CHAT_MODEL = "5.4mini"; OPENAI_MODEL = "gpt-5.2" } `
    -ExpectedModel "gpt-5.4-mini" `
    -ExpectedSource "OPENAI_CHAT_MODEL" `
    -ExpectedRequestedSource "OPENAI_CHAT_MODEL" `
    -ExpectedNotePattern "정규화" `
    -ExpectLocalChat

Invoke-ModelCase `
    -CaseName "5.5 mini 별칭 5.4 정규화" `
    -Env @{ OPENAI_CHAT_MODEL = "5.5mini"; OPENAI_MODEL = "gpt-5.2" } `
    -ExpectedModel "gpt-5.4-mini" `
    -ExpectedSource "OPENAI_CHAT_MODEL" `
    -ExpectedRequestedSource "OPENAI_CHAT_MODEL" `
    -ExpectedNotePattern "정규화" `
    -ExpectLocalChat

Invoke-ModelCase `
    -CaseName "잘못된 모델명 기본값 전환" `
    -Env @{ OPENAI_CHAT_MODEL = "bad model name" } `
    -ExpectedModel "gpt-5.4-mini" `
    -ExpectedSource "fixed" `
    -ExpectedRequestedSource "OPENAI_CHAT_MODEL" `
    -ExpectedNotePattern "전시 운영 모델" `
    -ExpectLocalChat

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 모델 설정 QA")
$lines.Add("")
$lines.Add("- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("- 서버: $serverRoot")
$lines.Add("")
$lines.Add("이 문서는 전시 운영 채팅 모델을 gpt-5.4-mini로 고정하고, 짧은 모델명 정규화와 잘못된 모델명 처리 정책을 검증한다.")
$lines.Add("실제 API 계정에서 gpt-5.4-mini 호출이 실패하면 /api/config에 오류가 표시되고, 텍스트 대화는 로컬 근거 답변으로 이어져야 한다.")
$lines.Add("")
$lines.Add("| 케이스 | 상태 | 근거 |")
$lines.Add("| --- | --- | --- |")
foreach ($result in $results) {
    $lines.Add("| $(Escape-MarkdownCell $result.Case) | $(Escape-MarkdownCell $result.Status) | $(Escape-MarkdownCell $result.Detail) |")
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

$failed = @($results | Where-Object { $_.Status -eq "실패" })
if ($failed.Count -gt 0) {
    throw "Model config QA failed with $($failed.Count) issue(s). Report: $OutputPath"
}

Write-Host "Model config QA passed: $OutputPath"
