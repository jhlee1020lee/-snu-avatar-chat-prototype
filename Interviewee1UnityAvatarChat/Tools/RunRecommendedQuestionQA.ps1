param(
    [int]$Port = 8885,
    [switch]$KeepServer
)

$ErrorActionPreference = "Stop"

function Normalize-QuestionKey {
    param([string]$Value)
    return ([string]$Value) `
        -replace "\s+", "" `
        -replace "[\?？!！\.。~…·,，:：'""“”‘’\(\)\[\]{}<>\-_/\\]", "" `
        | ForEach-Object { $_.ToLowerInvariant() }
}

function Test-KeyAny {
    param(
        [string]$Key,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if ($Key.Contains($pattern)) {
            return $true
        }
    }
    return $false
}

function Get-ExpectedFactId {
    param([string]$Question)

    $key = Normalize-QuestionKey $Question
    if ([string]::IsNullOrWhiteSpace($key)) { return "" }

    if (Test-KeyAny $key @("미국과한국", "이동환경을볼때", "편하다불편하다", "교통정보나지원서비스")) { return "accessibility" }
    if (Test-KeyAny $key @("노트북과메모", "책상과노트북", "책상앞", "책상은왜", "직장일과박사과정", "직장일과컴퓨터공학박사과정", "공부와일을병행", "읽고정리하는시간", "꾸준히챙기는리듬", "회사에가고공부하고집")) { return "desk" }
    if (Test-KeyAny $key @("어떤업무장면", "업무장면에서기여", "함께일하는사람", "직장에서필요한도움", "직장생활에서는목발", "도움을요청하는일이부담보다조율", "프로젝트를마쳤을때", "결과물을만들", "자기몫이나기여")) { return "workplace" }
    if (Test-KeyAny $key @("도움을주고싶을때", "도움이필요해보여도", "도움을건네기전에", "도움을주기전에", "바로잡아주기보다", "혼자할수있는부분", "좋은의도가있어도", "좋은의도와실제로편한도움", "도움을받을때설명할시간", "도움을묻는말", "기다려주는태도", "어디를잡아야")) { return "help" }
    if (Test-KeyAny $key @("처음가는장소", "처음가는공간", "입구와엘리베이터", "엘리베이터나화장실", "비가오거나", "바닥이미끄러운", "이동계획을세울때", "이동전에어떤정보")) { return "route" }
    if (Test-KeyAny $key @("자취방에서", "자취방은장애를설명", "혼자생활하며자기생활", "생활을직접정", "혼자사는공간", "집안일생활비공과금", "자취방은")) { return "room" }
    if (Test-KeyAny $key @("혼자사는방은독립이나자기이해", "자취를시작한뒤스스로설명", "필요한도움을말하는태도", "독립은큰결심")) { return "self-understanding" }
    if (Test-KeyAny $key @("게임이나코인노래방", "게임과코인노래방", "취미이야기", "쉬는시간이함께", "좋아하는것을챙기는", "좋아하는시간", "해야할일사이에좋아하는", "쉬는날에는", "게임을하는시간", "코인노래방같은여가", "자기답게쉬는시간")) { return "hobby" }
    if (Test-KeyAny $key @("해야할일이많을때", "끝까지이어가게", "끈기라는말", "어떻게든흘러간다는말", "어려운일이있어도", "버틴다는말보다", "조정하며이어")) { return "motto" }
    if (Test-KeyAny $key @("평범한사람으로기억", "목발을보고들어온관람객", "장애를한사람의전부", "전시에서자취방과책상", "겉으로보이는단서", "처음보는사람이가장먼저", "목발을쓰는날에도하루에서가장평범")) { return "ordinary" }
    if (Test-KeyAny $key @("목발을짚고하루를시작", "목발은하루를밖으로", "목발은어떤의미")) { return "crutch" }

    return ""
}

function Add-Question {
    param(
        [System.Collections.Generic.HashSet[string]]$Set,
        [string]$Question
    )

    $clean = ([string]$Question) -replace "\s+", " "
    $clean = $clean.Trim()
    if ($clean.Length -lt 8 -or $clean.Length -gt 140) { return }
    if ($clean -notmatch "[가-힣]" -or $clean -notmatch "[?？]$") { return }
    [void]$Set.Add($clean)
}

function Add-QuotedQuestions {
    param(
        [System.Collections.Generic.HashSet[string]]$Set,
        [string]$Text
    )

    foreach ($match in [regex]::Matches($Text, '["'']([^"'']{8,140}[?？])["'']')) {
        Add-Question $Set $match.Groups[1].Value
    }
}

function Invoke-Chat {
    param(
        [string]$Question,
        [string[]]$History = @()
    )

    $messages = New-Object System.Collections.ArrayList
    foreach ($item in $History) {
        if (-not [string]::IsNullOrWhiteSpace($item)) {
            [void]$messages.Add(@{ role = "user"; content = $item })
        }
    }
    [void]$messages.Add(@{ role = "user"; content = $Question })

    $body = @{ messages = $messages } | ConvertTo-Json -Depth 8
    return Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/chat" -Method Post -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec 20
}

function Read-Utf8Text {
    param([string]$Path)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    return [System.IO.File]::ReadAllText($Path, $encoding)
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $projectRoot "..\..")
$serverRoot = Join-Path $repoRoot "99_GroupProject\Interviewee1CloneAI"
$serverJs = Join-Path $serverRoot "server.js"
$personaPath = Join-Path $serverRoot "data\persona.json"
$unitySource = Join-Path $projectRoot "Assets\Scripts\AvatarChatApp.cs"
$reportPath = Join-Path $projectRoot "Build\recommended-question-qa.tsv"
$node = (Get-Command "node.exe", "node" -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if ([string]::IsNullOrWhiteSpace($node)) {
    throw "node was not found."
}

New-Item -ItemType Directory -Force -Path (Split-Path $reportPath -Parent) | Out-Null

$questions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$persona = Read-Utf8Text $personaPath | ConvertFrom-Json
foreach ($question in @($persona.suggestedQuestions)) {
    Add-Question $questions $question
}
Add-QuotedQuestions $questions (Read-Utf8Text $serverJs)
Add-QuotedQuestions $questions (Read-Utf8Text $unitySource)

$classifiedQuestions = @($questions | Where-Object { -not [string]::IsNullOrWhiteSpace((Get-ExpectedFactId $_)) } | Sort-Object)
if ($classifiedQuestions.Count -lt 50) {
    throw "Too few classified recommended questions: $($classifiedQuestions.Count). Extraction may be broken."
}

$badTemplates = @($questions | Where-Object { $_ -match "아직\s*(묻지|꺼내지)\s*않은|장면\s*\{index\}|\{label\}" })
if ($badTemplates.Count -gt 0) {
    throw "Generic recommended question templates are still present: $($badTemplates -join ' / ')"
}

$oldPort = $env:PORT
$oldKey = $env:OPENAI_API_KEY
$oldGeneratedMemory = $env:GENERATED_MEMORY_PATH
$env:PORT = [string]$Port
$env:OPENAI_API_KEY = ""
$env:GENERATED_MEMORY_PATH = Join-Path ([System.IO.Path]::GetTempPath()) "geotnotsok-recommended-question-qa-$Port.jsonl"
Remove-Item -LiteralPath $env:GENERATED_MEMORY_PATH -Force -ErrorAction SilentlyContinue

$server = Start-Process -FilePath $node -ArgumentList @("server.js") -WorkingDirectory $serverRoot -PassThru -WindowStyle Hidden
$failures = New-Object System.Collections.Generic.List[string]
$report = New-Object System.Collections.Generic.List[string]
$report.Add("type`tquestion`texpected`tactual`tsource`tresult")

try {
    $deadline = (Get-Date).AddSeconds(20)
    do {
        Start-Sleep -Milliseconds 300
        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/config" -Method Get -TimeoutSec 2 | Out-Null
            break
        } catch {
            if ((Get-Date) -ge $deadline) { throw }
        }
    } while ($true)

    $queue = [System.Collections.Generic.Queue[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($question in $classifiedQuestions) {
        $queue.Enqueue($question)
        [void]$seen.Add($question)
    }

    while ($queue.Count -gt 0 -and $seen.Count -le 260) {
        $question = $queue.Dequeue()
        $expected = Get-ExpectedFactId $question
        if ([string]::IsNullOrWhiteSpace($expected)) { continue }

        try {
            $response = Invoke-Chat -Question $question
            $actual = [string]$response.cardId
            $source = [string]$response.source
            $ok = $actual -eq $expected -and -not [string]::IsNullOrWhiteSpace([string]$response.reply)
            if (-not $ok) {
                $failures.Add("$question expected=$expected actual=$actual source=$source")
            }
            $report.Add("answer`t$question`t$expected`t$actual`t$source`t$(if ($ok) { 'PASS' } else { 'FAIL' })")

            $suggestions = @($response.suggestions)
            if ($suggestions.Count -ne 3) {
                $failures.Add("$question returned $($suggestions.Count) suggestions, expected 3")
            }

            foreach ($suggestion in $suggestions) {
                $suggestionText = [string]$suggestion
                $suggestionExpected = Get-ExpectedFactId $suggestionText
                if ([string]::IsNullOrWhiteSpace($suggestionExpected)) {
                    $failures.Add("Unclassified returned suggestion from '$question': $suggestionText")
                    $report.Add("suggestion`t$suggestionText`t`t`t`tFAIL")
                    continue
                }

                if ($seen.Add($suggestionText)) {
                    $queue.Enqueue($suggestionText)
                }
                $report.Add("suggestion`t$suggestionText`t$suggestionExpected`tqueued`t`tPASS")
            }
        } catch {
            $failures.Add("$question threw $($_.Exception.Message)")
            $report.Add("answer`t$question`t$expected`t`t`tFAIL")
        }
    }
}
finally {
    $report | Set-Content -LiteralPath $reportPath -Encoding UTF8
    if (-not $KeepServer -and $server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
    $env:PORT = $oldPort
    $env:OPENAI_API_KEY = $oldKey
    $env:GENERATED_MEMORY_PATH = $oldGeneratedMemory
}

if ($failures.Count -gt 0) {
    $failures | Select-Object -First 40 | ForEach-Object { Write-Host "[recommended-question-qa] $_" }
    throw "Recommended question QA failed with $($failures.Count) issue(s). Report: $reportPath"
}

Write-Host "Recommended question QA passed for $($seen.Count) question(s). Report: $reportPath"
