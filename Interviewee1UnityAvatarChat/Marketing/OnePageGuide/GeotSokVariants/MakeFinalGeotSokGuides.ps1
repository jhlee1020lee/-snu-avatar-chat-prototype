param(
    [string]$InputPattern = "geotsok-raw-*.png",
    [string]$OutputPrefix = "geotsok-guide"
)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot

function New-Font([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    foreach ($family in @("Noto Sans KR", "Malgun Gothic", "맑은 고딕", "Arial")) {
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

function Draw-CenteredText($graphics, [string]$text, [System.Drawing.Font]$font, $brush, [System.Drawing.RectangleF]$rect) {
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString($text, $font, $brush, $rect, $format)
    $format.Dispose()
}

$files = Get-ChildItem -Path $dir -File -Filter $InputPattern | Sort-Object Name
if ($files.Count -eq 0) {
    throw "No files matched $InputPattern"
}

$i = 1
foreach ($file in $files) {
    $image = [System.Drawing.Image]::FromFile($file.FullName)
    $bitmap = [System.Drawing.Bitmap]::new($image.Width, $image.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    try {
        $graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)

        $headerH = [math]::Round($image.Height * 0.235)
        $paper = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(248, 240, 224))
        $graphics.FillRectangle($paper, 0, 0, $image.Width, $headerH)

        $goldPen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml("#B1843A"), [math]::Max(2, [math]::Round($image.Width * 0.003)))
        $thinPen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml("#D7C7AE"), [math]::Max(1, [math]::Round($image.Width * 0.0015)))
        $graphics.DrawLine($goldPen, $image.Width * 0.14, $headerH * 0.78, $image.Width * 0.86, $headerH * 0.78)
        $graphics.DrawLine($thinPen, 0, $headerH - 2, $image.Width, $headerH - 2)

        $titleFont = New-Font ([math]::Round($image.Width * 0.145)) ([System.Drawing.FontStyle]::Bold)
        $subFont = New-Font ([math]::Round($image.Width * 0.039)) ([System.Drawing.FontStyle]::Bold)
        $descFont = New-Font ([math]::Round($image.Width * 0.026)) ([System.Drawing.FontStyle]::Regular)

        Draw-CenteredText $graphics "겉!=속" $titleFont (New-Brush "#18283A") ([System.Drawing.RectangleF]::new(0, $headerH * 0.10, $image.Width, $headerH * 0.38))
        Draw-CenteredText $graphics "대화형 인터뷰 게임 안내" $subFont (New-Brush "#806035") ([System.Drawing.RectangleF]::new(0, $headerH * 0.48, $image.Width, $headerH * 0.16))
        Draw-CenteredText $graphics "보이는 모습에서 시작해, 안쪽의 이야기를 천천히 듣습니다." $descFont (New-Brush "#5F554A") ([System.Drawing.RectangleF]::new($image.Width * 0.08, $headerH * 0.64, $image.Width * 0.84, $headerH * 0.12))

        $out = Join-Path $dir ("{0}-{1:D2}.png" -f $OutputPrefix, $i)
        $bitmap.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
        $image.Dispose()
    }
    $i++
}

Write-Host "Wrote $($files.Count) final guide images to $dir"

