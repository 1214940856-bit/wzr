$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$videoDirectory = Join-Path $root "assets\videos"
$targetMB = 8.5
$audioKbps = 96
$maxVideoKbps = 1600
$minVideoKbps = 240

function Find-FFmpegTool([string]$name) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $packageRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    $tool = Get-ChildItem $packageRoot -Recurse -Filter "$name.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $tool) {
        throw "$name was not found. Install FFmpeg before running this script."
    }

    return $tool
}

$ffmpeg = Find-FFmpegTool "ffmpeg"
$ffprobe = Find-FFmpegTool "ffprobe"
$scaleFilter = "scale='if(gt(iw,ih),min(1280,iw),-2)':'if(gt(iw,ih),-2,min(1280,ih))'"
$sources = Get-ChildItem $videoDirectory -File -Filter "*.mp4" |
    Where-Object BaseName -NotMatch "-web$" |
    Sort-Object Name

foreach ($source in $sources) {
    $destination = Join-Path $videoDirectory "$($source.BaseName)-web.mp4"
    $durationText = & $ffprobe -v error -show_entries format=duration -of "default=noprint_wrappers=1:nokey=1" $source.FullName
    $duration = [double]::Parse($durationText, [Globalization.CultureInfo]::InvariantCulture)
    $totalKbps = [Math]::Floor(($targetMB * 8192) / $duration)
    $videoKbps = [Math]::Max($minVideoKbps, [Math]::Min($maxVideoKbps, $totalKbps - $audioKbps - 48))
    $bufferKbps = $videoKbps * 2

    Write-Host "Encoding $($source.Name) -> $([IO.Path]::GetFileName($destination)) at $videoKbps kbps"
    & $ffmpeg -hide_banner -loglevel error -stats -y `
        -i $source.FullName `
        -map "0:v:0" -map "0:a?" `
        -vf $scaleFilter -r 30 `
        -c:v libx264 -preset medium -b:v "$($videoKbps)k" -maxrate "$($videoKbps)k" -bufsize "$($bufferKbps)k" `
        -pix_fmt yuv420p -movflags "+faststart" `
        -c:a aac -b:a "$($audioKbps)k" `
        $destination

    if ($LASTEXITCODE -ne 0) {
        throw "FFmpeg failed while encoding $($source.Name)"
    }

    $webDurationText = & $ffprobe -v error -show_entries format=duration -of "default=noprint_wrappers=1:nokey=1" $destination
    $webDuration = [double]::Parse($webDurationText, [Globalization.CultureInfo]::InvariantCulture)
    if ([Math]::Abs($duration - $webDuration) -gt 1) {
        Write-Warning "$($source.Name) decoded to $([Math]::Round($webDuration, 1))s instead of $([Math]::Round($duration, 1))s. Replace the source file if the missing tail is needed."
    }
}

Write-Host "Generated optimized web videos."
