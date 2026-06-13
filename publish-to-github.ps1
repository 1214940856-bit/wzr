param(
    [string]$Message = "Update portfolio site",
    [string]$PublishRoot = "C:\Users\Lenovo\Desktop\wzr-github-sync-clean"
)

$ErrorActionPreference = "Stop"

$SourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpectedRemote = "https://github.com/1214940856-bit/wzr.git"
$ExpectedDomain = "wwwlf-zuopingji.xyz"

function Invoke-Git {
    param(
        [string[]]$GitArgs,
        [string]$WorkingDirectory = $PublishRoot
    )

    & git -C $WorkingDirectory @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed."
    }
}

if (-not (Test-Path -LiteralPath $PublishRoot)) {
    throw "GitHub sync folder was not found: $PublishRoot"
}

if (-not (Test-Path -LiteralPath (Join-Path $PublishRoot ".git"))) {
    throw "GitHub sync folder is not a git repository: $PublishRoot"
}

$remote = (& git -C $PublishRoot remote get-url origin).Trim()
if ($remote -ne $ExpectedRemote) {
    throw "Unexpected origin remote: $remote"
}

Set-Content -LiteralPath (Join-Path $SourceRoot "CNAME") -Value $ExpectedDomain -NoNewline -Encoding ASCII

Invoke-Git -GitArgs @("fetch", "origin", "--prune")

$branch = (& git -C $PublishRoot branch --show-current).Trim()
if (-not $branch) {
    throw "GitHub sync folder is not on a branch."
}

Invoke-Git -GitArgs @("pull", "--ff-only", "origin", "main")

$filesToCopy = @(
    "index.html",
    ".gitignore",
    "CNAME",
    ".nojekyll",
    "PUBLISH_STEPS.md",
    "publish-to-github.ps1",
    "sync-dist.ps1",
    "check-dist.ps1",
    ".github\workflows\pages.yml"
)

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $SourceRoot $file
    $destinationPath = Join-Path $PublishRoot $file

    if (Test-Path -LiteralPath $sourcePath) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    }
}

$html = [IO.File]::ReadAllText((Join-Path $SourceRoot "index.html"), [Text.Encoding]::UTF8)
$assetPaths = [regex]::Matches($html, "assets/[A-Za-z0-9._/-]+") |
    ForEach-Object Value |
    Sort-Object -Unique

foreach ($assetPath in $assetPaths) {
    $relativePath = $assetPath.Replace("/", [IO.Path]::DirectorySeparatorChar)
    $sourcePath = Join-Path $SourceRoot $relativePath
    $destinationPath = Join-Path $PublishRoot $relativePath

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing referenced asset: $assetPath"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
}

Set-Content -LiteralPath (Join-Path $PublishRoot "CNAME") -Value $ExpectedDomain -NoNewline -Encoding ASCII

& powershell -ExecutionPolicy Bypass -File (Join-Path $PublishRoot "sync-dist.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "sync-dist.ps1 failed."
}

& powershell -ExecutionPolicy Bypass -File (Join-Path $PublishRoot "check-dist.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "check-dist.ps1 failed."
}

Invoke-Git -GitArgs @("add", ".")

$status = (& git -C $PublishRoot status --short)
if (-not $status) {
    Write-Host "No changes to publish."
    exit 0
}

Invoke-Git -GitArgs @("commit", "-m", $Message)
Invoke-Git -GitArgs @("push", "origin", "HEAD:main")

Write-Host ""
Write-Host "Published to GitHub successfully."
Write-Host "Next: wait for GitHub Actions, then open https://wwwlf-zuopingji.xyz?v=latest"
