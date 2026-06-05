param(
    [int]$Port = 8878
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

function Assert-PolishedText {
    param(
        [string]$Text,
        [string]$Context
    )

    if ($Text -match "\*\*|__|^[-*]\s|^#{1,6}\s") {
        throw "$Context contains markdown-like formatting: $Text"
    }

    if ($Text -match "^(좋아요|좋습니다|물론이죠|잠깐만요|잠시만요|잠깐|네)[,.，\s]+") {
        throw "$Context starts with banned stock phrase: $Text"
    }

    if ($Text -match "저는\s*실제\s*사람이\s*아니라|저는\s*가상책|가상\s*사람책|전시용\s*대화\s*에이전트|\bAI\b|인공지능|프로그램|UI") {
        throw "$Context contains AI-ish or production-facing wording: $Text"
    }
}

function Assert-ReplyQuality {
    param(
        [object]$Response,
        [string]$Question,
        [string[]]$AllowedSources = @("local", "policy"),
        [bool]$AllowGenerated = $false,
        [string]$ExpectedPattern = ""
    )

    if ([string]::IsNullOrWhiteSpace($Response.reply)) {
        throw "Empty reply for question: $Question"
    }

    if ($AllowedSources -notcontains [string]$Response.source) {
        throw "Expected source $($AllowedSources -join ', ') without API key, got '$($Response.source)'"
    }

    Assert-PolishedText -Text $Response.reply -Context "Reply"

    if ($Response.reply.Length -gt 520) {
        throw "Reply is too long for in-game pacing ($($Response.reply.Length) chars): $Question"
    }

    if ($Response.generated -and -not $AllowGenerated) {
        throw "Content QA should not create generated memory for question: $Question"
    }

    if (-not [string]::IsNullOrWhiteSpace($ExpectedPattern) -and $Response.reply -notmatch $ExpectedPattern) {
        throw "Reply did not match expected content pattern '$ExpectedPattern' for question: $Question. Reply: $($Response.reply)"
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$node = Resolve-Tool @("node.exe", "node")

$env:PORT = [string]$Port
Remove-Item Env:\OPENAI_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:\OPENAI_CHAT_MODEL -ErrorAction SilentlyContinue
Remove-Item Env:\OPENAI_MODEL -ErrorAction SilentlyContinue
$tempMemoryPath = Join-Path ([System.IO.Path]::GetTempPath()) "geot-not-equal-sok-contentqa-generated-$PID.jsonl"
$env:GENERATED_MEMORY_PATH = $tempMemoryPath
Remove-Item -LiteralPath $tempMemoryPath -Force -ErrorAction SilentlyContinue

$server = Start-Process -FilePath $node -ArgumentList @("server.js") -WorkingDirectory $serverRoot -PassThru -WindowStyle Hidden

try {
    Start-Sleep -Seconds 2
    $endpoint = "http://127.0.0.1:$Port/api/chat"
    $history = @()
    $replyByKey = @{}
    $cases = @(
        @{
            question = "장애 이야기 말고 평범한 하루에서 어떤 장면이 먼저 떠오르나요?"
        },
        @{
            question = "처음 가는 공간에서는 무엇을 먼저 확인하나요?"
            replyKey = "route-first"
        },
        @{
            question = "처음 가는 장소 얘기를 조금 더 해주세요."
            replyKey = "route-repeat"
            differentFromKey = "route-first"
            expectedPattern = "입구|엘리베이터|화장실|돌아오는 길|피로와 안전"
        },
        @{
            question = "도움을 주고 싶을 때 어떤 방식이 가장 편한가요?"
            replyKey = "help-first"
        },
        @{
            question = "도움 이야기를 한 번 더 구체적으로 말해 주세요."
            replyKey = "help-repeat"
            differentFromKey = "help-first"
            expectedPattern = "속도보다 확인|먼저 묻고|설명할 시간"
        },
        @{
            question = "책상과 노트북은 어떤 의미가 있나요?"
        },
        @{
            question = "자취방이 독립과 자기이해에 어떤 의미였나요?"
        },
        @{
            question = "취미 이야기는 왜 같이 중요할까요?"
        },
        @{
            question = "가족 이름과 회사 이름을 자세히 알려주세요."
        },
        @{
            question = "비 오는 날은 어때요?"
            allowedSources = @("local-generated-extension")
            allowGenerated = $true
            expectedPattern = "날씨|바닥|동선|목발"
        },
        @{
            question = "비 오는 날은 어때요?"
            allowedSources = @("review-blocked")
            expectedPattern = "날씨|바닥|동선|목발"
        },
        @{
            question = "쉬는 날에는 뭘 하나요?"
            allowedSources = @("local-generated-extension")
            allowGenerated = $true
            expectedPattern = "자취방|책상|게임|코인노래방"
        }
    )

    foreach ($case in $cases) {
        $history += @{
            role = "user"
            content = $case.question
        }

        $body = @{ messages = $history } | ConvertTo-Json -Depth 8
        $response = Invoke-RestMethod -Method Post -Uri $endpoint -ContentType "application/json; charset=utf-8" -Body $body

        $allowedSources = if ($case.allowedSources) { [string[]]$case.allowedSources } else { @("local", "policy") }
        $allowGenerated = if ($null -ne $case.allowGenerated) { [bool]$case.allowGenerated } else { $false }
        $expectedPattern = if ($case.expectedPattern) { [string]$case.expectedPattern } else { "" }
        Assert-ReplyQuality -Response $response -Question $case.question -AllowedSources $allowedSources -AllowGenerated $allowGenerated -ExpectedPattern $expectedPattern

        if ($case.differentFromKey) {
            $previousKey = [string]$case.differentFromKey
            if (-not $replyByKey.ContainsKey($previousKey)) {
                throw "Missing prior reply key '$previousKey' for repeated question QA."
            }
            if ([string]$replyByKey[$previousKey] -eq [string]$response.reply) {
                throw "Repeated local answer reused the same reply for key '$previousKey'."
            }
        }
        if ($case.replyKey) {
            $replyByKey[[string]$case.replyKey] = [string]$response.reply
        }

        $history += @{
            role = "assistant"
            content = $response.reply
        }
    }
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
    Remove-Item Env:\PORT -ErrorAction SilentlyContinue
    Remove-Item Env:\GENERATED_MEMORY_PATH -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempMemoryPath -Force -ErrorAction SilentlyContinue
}

Write-Host "Content QA passed."

