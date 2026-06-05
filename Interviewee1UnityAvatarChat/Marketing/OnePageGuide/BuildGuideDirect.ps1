param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "guide-v2-direct.png")
)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$screenshotRoot = Join-Path $root "Marketing\Screenshots"

$width = 1748
$height = 2480
$margin = 96

function New-Font([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    $families = @("Noto Sans KR", "Malgun Gothic", "맑은 고딕", "Arial")
    foreach ($family in $families) {
        try {
            return [System.Drawing.Font]::new($family, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
        } catch {
        }
    }
    return [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericSansSerif, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-Brush([string]$hex) {
    return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function New-Pen([string]$hex, [float]$size = 1) {
    return [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($hex), $size)
}

function Add-RoundedRect($graphics, [System.Drawing.RectangleF]$rect, [float]$radius, $brush, $pen = $null) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $radius * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    if ($brush -ne $null) { $graphics.FillPath($brush, $path) }
    if ($pen -ne $null) { $graphics.DrawPath($pen, $path) }
    $path.Dispose()
}

function Draw-TextBox($graphics, [string]$text, [System.Drawing.Font]$font, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [System.Drawing.StringAlignment]$align = [System.Drawing.StringAlignment]::Near, [System.Drawing.StringAlignment]$lineAlign = [System.Drawing.StringAlignment]::Near) {
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = $align
    $format.LineAlignment = $lineAlign
    $format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
    $format.FormatFlags = 0
    $rect = [System.Drawing.RectangleF]::new($x, $y, $w, $h)
    $graphics.DrawString($text, $font, $brush, $rect, $format)
    $format.Dispose()
}

function Draw-CroppedImage($graphics, [System.Drawing.Image]$image, [System.Drawing.RectangleF]$dest, [float]$srcXRatio, [float]$srcYRatio, [float]$srcWRatio, [float]$srcHRatio) {
    $src = [System.Drawing.RectangleF]::new(
        $image.Width * $srcXRatio,
        $image.Height * $srcYRatio,
        $image.Width * $srcWRatio,
        $image.Height * $srcHRatio
    )
    $graphics.DrawImage($image, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-InfoPill($graphics, [string]$label, [string]$value, [float]$x, [float]$y, [float]$w) {
    $bg = New-Brush "#EEE5D4"
    $border = New-Pen "#C5A36D" 2
    Add-RoundedRect $graphics ([System.Drawing.RectangleF]::new($x, $y, $w, 104)) 20 $bg $border
    Draw-TextBox $graphics $label (New-Font 27 Bold) (New-Brush "#8A6429") ($x + 34) ($y + 22) ($w - 68) 30
    Draw-TextBox $graphics $value (New-Font 34 Bold) (New-Brush "#1B2A3A") ($x + 34) ($y + 54) ($w - 68) 38
}

function Draw-Step($graphics, [string]$num, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w) {
    $ink = New-Brush "#1B2A3A"
    $muted = New-Brush "#5E554B"
    $gold = New-Brush "#B1843A"
    $circleRect = [System.Drawing.RectangleF]::new($x, $y + 2, 56, 56)
    $graphics.FillEllipse($gold, $circleRect)
    Draw-TextBox $graphics $num (New-Font 28 Bold) (New-Brush "#FFF8EA") $x ($y + 9) 56 42 ([System.Drawing.StringAlignment]::Center)
    Draw-TextBox $graphics $title (New-Font 34 Bold) $ink ($x + 76) ($y - 2) ($w - 76) 42
    Draw-TextBox $graphics $body (New-Font 25 Regular) $muted ($x + 76) ($y + 42) ($w - 76) 86
}

$bitmap = [System.Drawing.Bitmap]::new($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$paper = New-Brush "#F6F0E4"
$ink = New-Brush "#18283A"
$muted = New-Brush "#6B6258"
$gold = New-Brush "#B1843A"
$navy = New-Brush "#17263A"
$line = New-Pen "#D7C7AE" 2

$graphics.FillRectangle($paper, 0, 0, $width, $height)

$hero = [System.Drawing.Image]::FromFile((Join-Path $screenshotRoot "01-title-session-start.png"))
$memory = [System.Drawing.Image]::FromFile((Join-Path $screenshotRoot "05-memory-complete.png"))
$question = [System.Drawing.Image]::FromFile((Join-Path $screenshotRoot "02-question-phone.png"))
$closing = [System.Drawing.Image]::FromFile((Join-Path $screenshotRoot "06-closing-card.png"))

try {
    Draw-TextBox $graphics "겉!=속" (New-Font 91 Bold) $ink $margin 76 ($width - ($margin * 2)) 104 ([System.Drawing.StringAlignment]::Center)
    Draw-TextBox $graphics "대화형 인터뷰 게임 안내" (New-Font 43 Bold) (New-Brush "#816036") $margin 180 ($width - ($margin * 2)) 58 ([System.Drawing.StringAlignment]::Center)
    Draw-TextBox $graphics "책상 맞은편에서 한 사람의 일상, 이동, 도움, 일과 공부, 독립과 취미를 묻는 짧은 전시용 경험입니다." (New-Font 31 Regular) $muted ($margin + 90) 242 ($width - (($margin + 90) * 2)) 84 ([System.Drawing.StringAlignment]::Center)

    $heroRect = [System.Drawing.RectangleF]::new($margin, 352, $width - ($margin * 2), 704)
    Add-RoundedRect $graphics ([System.Drawing.RectangleF]::new($heroRect.X - 10, $heroRect.Y - 10, $heroRect.Width + 20, $heroRect.Height + 20)) 24 (New-Brush "#E8DDCB") $null
    Draw-CroppedImage $graphics $hero $heroRect 0.00 0.02 1.00 0.83
    $overlay = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(178, 18, 27, 38))
    Add-RoundedRect $graphics ([System.Drawing.RectangleF]::new($margin + 54, 834, 742, 182)) 18 $overlay $null
    Draw-TextBox $graphics "인터뷰 자료를 따라가는 사람책형 대화" (New-Font 31 Bold) (New-Brush "#FFF5E5") ($margin + 84) 878 642 42
    Draw-TextBox $graphics "추천 질문, 직접 입력, 기억장, 마무리 기록으로 한 세션을 완성합니다." (New-Font 24 Regular) (New-Brush "#E9DBC3") ($margin + 84) 923 682 74

    $pillY = 1102
    Draw-InfoPill $graphics "소요 시간" "10-15분" $margin $pillY 374
    Draw-InfoPill $graphics "형식" "1인 대화형" ($margin + 404) $pillY 374
    Draw-InfoPill $graphics "자료" "수업 인터뷰 기반" ($margin + 808) $pillY 748

    $sectionY = 1268
    Draw-TextBox $graphics "진행 방법" (New-Font 44 Bold) $ink $margin $sectionY 420 56
    $graphics.DrawLine($line, $margin, $sectionY + 72, $width - $margin, $sectionY + 72)
    Draw-Step $graphics "1" "질문을 고릅니다" "질문 노트나 책상 위 단서를 눌러 대화를 시작합니다." $margin ($sectionY + 112) 720
    Draw-Step $graphics "2" "직접 묻습니다" "필요하면 입력창에 궁금한 말을 직접 적어 이어갑니다." $margin ($sectionY + 254) 720
    Draw-Step $graphics "3" "기억장을 채웁니다" "일상, 이동, 도움, 일과 공부, 독립, 취미 여섯 장면이 열립니다." ($margin + 820) ($sectionY + 112) 736
    Draw-Step $graphics "4" "문장을 남깁니다" "다섯 번의 문답 뒤 오늘 가져갈 문장을 선택하고 기록합니다." ($margin + 820) ($sectionY + 254) 736

    $stripY = 1752
    Draw-TextBox $graphics "화면 구성" (New-Font 44 Bold) $ink $margin $stripY 420 56
    $graphics.DrawLine($line, $margin, $stripY + 72, $width - $margin, $stripY + 72)

    $thumbW = 476
    $thumbH = 268
    $thumbY = $stripY + 110
    $thumbs = @(
        @{ Image = $question; Title = "질문 노트"; Body = "다음 질문과 장면 진행도 확인" },
        @{ Image = $memory; Title = "기억장"; Body = "여섯 장면과 질문의 흔적 보관" },
        @{ Image = $closing; Title = "마무리 카드"; Body = "오늘 남길 문장 선택" }
    )
    for ($i = 0; $i -lt $thumbs.Count; $i++) {
        $x = $margin + ($i * 538)
        Add-RoundedRect $graphics ([System.Drawing.RectangleF]::new($x - 8, $thumbY - 8, $thumbW + 16, 404)) 18 (New-Brush "#EDE3D1") $null
        Draw-CroppedImage $graphics $thumbs[$i].Image ([System.Drawing.RectangleF]::new($x, $thumbY, $thumbW, $thumbH)) 0.00 0.10 1.00 0.72
        Draw-TextBox $graphics $thumbs[$i].Title (New-Font 32 Bold) $ink ($x + 22) ($thumbY + $thumbH + 24) ($thumbW - 44) 40
        Draw-TextBox $graphics $thumbs[$i].Body (New-Font 24 Regular) $muted ($x + 22) ($thumbY + $thumbH + 66) ($thumbW - 44) 60
    }

    $noticeY = 2248
    Add-RoundedRect $graphics ([System.Drawing.RectangleF]::new($margin, $noticeY, $width - ($margin * 2), 128)) 20 (New-Brush "#18283A") $null
    Draw-TextBox $graphics "운영 안내" (New-Font 30 Bold) (New-Brush "#E9C074") ($margin + 36) ($noticeY + 24) 220 40
    Draw-TextBox $graphics "저장 기록은 이 컴퓨터의 로컬 폴더에 남으며, 정보 화면과 기록함에서 직접 삭제할 수 있습니다. 서버 연결이 없어도 내장 자료 답변으로 기본 대화가 이어집니다." (New-Font 25 Regular) (New-Brush "#F7F0E5") ($margin + 236) ($noticeY + 24) ($width - ($margin * 2) - 272) 78

    $graphics.DrawLine((New-Pen "#B1843A" 3), $margin, 2408, $width - $margin, 2408)
    Draw-TextBox $graphics "3조 대상자1 인터뷰 자료 기반 Unity 대화형 인터뷰 게임" (New-Font 25 Bold) (New-Brush "#67513B") $margin 2422 ($width - ($margin * 2)) 38 ([System.Drawing.StringAlignment]::Center)

    $outDir = Split-Path -Parent $OutputPath
    if ($outDir) {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $hero.Dispose()
    $memory.Dispose()
    $question.Dispose()
    $closing.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

Write-Host "Wrote $OutputPath"

