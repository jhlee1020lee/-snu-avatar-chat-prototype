param(
    [int]$Port = 8881
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
        [string]$Question
    )

    if ([string]::IsNullOrWhiteSpace($Response.reply)) {
        throw "Empty reply for question: $Question"
    }

    if (@("local", "policy") -notcontains [string]$Response.source) {
        throw "Expected local or policy source without API key, got '$($Response.source)'"
    }

    Assert-PolishedText -Text $Response.reply -Context "Reply"

    if ($Response.reply.Length -gt 620) {
        throw "Reply is too long for long-session pacing ($($Response.reply.Length) chars): $Question"
    }

    if ($Response.generated) {
        throw "Long session QA should not create generated memory for question: $Question"
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

$server = Start-Process -FilePath $node -ArgumentList @("server.js") -WorkingDirectory $serverRoot -PassThru -WindowStyle Hidden

try {
    Start-Sleep -Seconds 2
    $endpoint = "http://127.0.0.1:$Port/api/chat"
    $history = @()
    $seenReplies = New-Object System.Collections.Generic.HashSet[string]
    $duplicateCount = 0

    $cases = @(
        @{ question = "이 대화는 어떤 방식으로 시작하면 좋을까요?"; theme = "" },
        @{ question = "평범한 하루에서 장애보다 먼저 보이는 장면은 무엇인가요?"; theme = "일상" },
        @{ question = "목발은 하루에서 어떤 역할을 하나요?"; theme = "이동" },
        @{ question = "처음 가는 공간에서는 무엇을 먼저 확인하나요?"; theme = "이동" },
        @{ question = "계단이나 화장실 위치를 미리 보는 이유는 무엇인가요?"; theme = "이동" },
        @{ question = "도움을 주고 싶을 때 어떤 방식이 가장 편한가요?"; theme = "도움" },
        @{ question = "도움이 선의여도 불편할 때는 어떤 경우인가요?"; theme = "도움" },
        @{ question = "책상과 노트북은 일상에서 어떤 의미인가요?"; theme = "일과 공부" },
        @{ question = "직장에서는 필요한 도움을 어떻게 설명하나요?"; theme = "도움" },
        @{ question = "박사과정과 공부는 이 이야기에서 어떤 위치에 있나요?"; theme = "일과 공부" },
        @{ question = "자취방이 독립과 자기이해에 어떤 의미였나요?"; theme = "독립" },
        @{ question = "집안일과 생활비를 직접 챙기는 일이 왜 중요했나요?"; theme = "독립" },
        @{ question = "어릴 때 민폐가 아닐까 걱정했던 마음은 어떻게 달라졌나요?"; theme = "독립" },
        @{ question = "쉬는 시간과 취미는 하루를 어떻게 바꾸나요?"; theme = "취미" },
        @{ question = "게임과 코인노래방 이야기를 같이 넣는 이유가 있나요?"; theme = "취미" },
        @{ question = "극복담으로만 보이지 않게 하려면 어떤 질문이 좋을까요?"; theme = "일상" },
        @{ question = "오늘 이야기를 한 문장으로 남긴다면 무엇이 좋을까요?"; theme = "" },
        @{ question = "자료에 없는 가족 이름이나 회사 이름은 말할 수 있나요?"; theme = "" }
    )

    foreach ($case in $cases) {
        $history += @{
            role = "user"
            content = $case.question
        }

        $body = @{ messages = $history } | ConvertTo-Json -Depth 12
        $response = Invoke-RestMethod -Method Post -Uri $endpoint -ContentType "application/json; charset=utf-8" -Body $body

        Assert-ReplyQuality -Response $response -Question $case.question

        $normalizedReply = ($response.reply -replace "\s+", " ").Trim()
        if (-not $seenReplies.Add($normalizedReply)) {
            $duplicateCount++
        }

        $history += @{
            role = "assistant"
            content = $response.reply
        }
    }

    if ($duplicateCount -gt 8) {
        throw "Too many repeated replies in long session: $duplicateCount"
    }
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
    Remove-Item Env:\PORT -ErrorAction SilentlyContinue
}

Write-Host "Long session QA passed."
