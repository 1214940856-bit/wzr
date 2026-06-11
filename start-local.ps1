$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = Join-Path $root "serve.py"

& python $server --bind 127.0.0.1 --port 4173
