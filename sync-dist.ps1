$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist"
$distAssets = Join-Path $dist "assets"
$indexPath = Join-Path $root "index.html"

New-Item -ItemType Directory -Path $dist -Force | Out-Null
Copy-Item -LiteralPath $indexPath -Destination (Join-Path $dist "index.html") -Force

if (Test-Path -LiteralPath $distAssets) {
    $resolvedDistAssets = (Resolve-Path -LiteralPath $distAssets).Path
    $resolvedDist = (Resolve-Path -LiteralPath $dist).Path
    if (-not $resolvedDistAssets.StartsWith($resolvedDist, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to replace assets outside the dist directory."
    }
    Remove-Item -LiteralPath $resolvedDistAssets -Recurse -Force
}

$html = [IO.File]::ReadAllText($indexPath, [Text.Encoding]::UTF8)
$assetPaths = [regex]::Matches($html, "assets/[A-Za-z0-9._/-]+") |
    ForEach-Object Value |
    Sort-Object -Unique

foreach ($assetPath in $assetPaths) {
    $relativePath = $assetPath.Replace("/", [IO.Path]::DirectorySeparatorChar)
    $sourcePath = Join-Path $root $relativePath
    $destinationPath = Join-Path $dist $relativePath

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing referenced asset: $assetPath"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
}

Write-Host "Synced index.html and $($assetPaths.Count) referenced assets to dist."
