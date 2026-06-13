$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist"
$limit = 10MB
$files = Get-ChildItem -LiteralPath $dist -Recurse -File |
    Where-Object FullName -NotMatch "\\.netlify\\"
$largeFiles = $files |
    Where-Object Length -GT $limit |
    Sort-Object Length -Descending
$totalMB = [Math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 2)

Write-Host "Deploy size: $totalMB MB"

if ($largeFiles) {
    Write-Host ""
    Write-Host "Deploy blocked: files larger than 10 MB remain."
    $largeFiles |
        Select-Object @{ Name = "MB"; Expression = { [Math]::Round($_.Length / 1MB, 2) } }, FullName |
        Format-Table -AutoSize
    exit 1
}

Write-Host "Deploy check passed."
