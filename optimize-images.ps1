$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$imageDirectory = Join-Path $root "assets\images"
$maxLongEdge = 2400
$jpegQuality = 85L

$images = @(
    @{ Source = "new-year-poster.jpg"; Destination = "new-year-poster-web.jpg" },
    @{ Source = "daxue-poster.png"; Destination = "daxue-poster-web.jpg" },
    @{ Source = "shanghai-ip-expo-poster.jpg"; Destination = "shanghai-ip-expo-poster-web.jpg" },
    @{ Source = "shanghai-ip-expo-poster-1.jpg"; Destination = "shanghai-ip-expo-poster-1-web.jpg" }
)

$jpegEncoder = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object MimeType -eq "image/jpeg"
$encoderParameters = [Drawing.Imaging.EncoderParameters]::new(1)
$encoderParameters.Param[0] = [Drawing.Imaging.EncoderParameter]::new(
    [Drawing.Imaging.Encoder]::Quality,
    $jpegQuality
)

foreach ($image in $images) {
    $sourcePath = Join-Path $imageDirectory $image.Source
    $destinationPath = Join-Path $imageDirectory $image.Destination
    $source = [Drawing.Image]::FromFile($sourcePath)

    try {
        $scale = [Math]::Min(
            [double]1,
            [double]$maxLongEdge / [Math]::Max($source.Width, $source.Height)
        )
        $width = [Math]::Max(1, [int][Math]::Round($source.Width * $scale))
        $height = [Math]::Max(1, [int][Math]::Round($source.Height * $scale))
        $bitmap = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)

        try {
            $graphics = [Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([Drawing.Color]::White)
                $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.DrawImage($source, 0, 0, $width, $height)
            }
            finally {
                $graphics.Dispose()
            }

            $bitmap.Save($destinationPath, $jpegEncoder, $encoderParameters)
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

$encoderParameters.Dispose()
Write-Host "Generated optimized web images."
