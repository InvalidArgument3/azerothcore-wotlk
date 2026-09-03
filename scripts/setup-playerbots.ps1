# mod-playerbots setup: build, database, config, client data
# Run AFTER scripts\install-deps.ps1 (as admin) completes.

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: $name. Run scripts\install-deps.ps1 as Administrator first."
    }
}

Write-Host "=== mod-playerbots setup ===" -ForegroundColor Cyan

Require-Command git
Require-Command cmake
Require-Command bash

# --- Build ---
Write-Host "`n[1/4] Building AzerothCore + mod-playerbots (this takes 20-60 min)..." -ForegroundColor Yellow
$env:MYSQL_ROOT_PASSWORD = 'acore'
& bash -lc "./acore.sh compiler all"

# --- Database ---
Write-Host "`n[2/4] Creating databases..." -ForegroundColor Yellow
Require-Command mysql

# Standard AC databases (user acore / password acore)
Get-Content "$Root\data\sql\create\create_mysql.sql" | mysql -u root -pacore 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Trying mysql root without password..."
    Get-Content "$Root\data\sql\create\create_mysql.sql" | mysql -u root
}

# Playerbots database
Get-Content "$Root\modules\mod-playerbots\data\sql\playerbots\create\create_mysql.sql" | mysql -u root -pacore 2>$null
if ($LASTEXITCODE -ne 0) {
    Get-Content "$Root\modules\mod-playerbots\data\sql\playerbots\create\create_mysql.sql" | mysql -u root
}

# Import playerbots SQL into characters/world
Write-Host "Importing playerbots SQL..."
foreach ($f in Get-ChildItem "$Root\modules\mod-playerbots\data\sql\characters\base\*.sql") {
    Get-Content $f.FullName | mysql -u acore -pacore acore_characters
}
foreach ($f in Get-ChildItem "$Root\modules\mod-playerbots\data\sql\world\base\*.sql") {
    Get-Content $f.FullName | mysql -u acore -pacore acore_world
}

# --- Config ---
Write-Host "`n[3/4] Configuring playerbots..." -ForegroundColor Yellow
$ConfDir = "$Root\env\dist\etc"
$ModulesDir = "$ConfDir\modules"
New-Item -ItemType Directory -Force -Path $ModulesDir | Out-Null

# Copy module config if build placed it elsewhere, fall back to source
$PbDist = Get-ChildItem -Recurse -Filter "playerbots.conf.dist" -Path "$Root\env","$Root\modules\mod-playerbots\conf" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($PbDist) {
    Copy-Item $PbDist.FullName "$ModulesDir\playerbots.conf.dist" -Force
    if (-not (Test-Path "$ModulesDir\playerbots.conf")) {
        Copy-Item "$ModulesDir\playerbots.conf.dist" "$ModulesDir\playerbots.conf"
    }
}

# Tune worldserver.conf
$WsDist = "$ConfDir\worldserver.conf.dist"
$WsConf = "$ConfDir\worldserver.conf"
if (Test-Path $WsDist) {
    if (-not (Test-Path $WsConf)) { Copy-Item $WsDist $WsConf }
    (Get-Content $WsConf) -replace 'MapUpdate\.Threads\s*=\s*\d+', 'MapUpdate.Threads = 4' | Set-Content $WsConf
}

# --- Client data ---
Write-Host "`n[4/4] Downloading client data (maps, vmaps, mmaps, dbc)..." -ForegroundColor Yellow
& bash -lc "./acore.sh client-data"

Write-Host ""
Write-Host "=== Setup complete ===" -ForegroundColor Green
Write-Host "Start servers:"
Write-Host "  bash -lc './acore.sh run-authserver'"
Write-Host "  bash -lc './acore.sh run-worldserver'"
Write-Host ""
Write-Host "Config: $ModulesDir\playerbots.conf"
Write-Host "MySQL:  acore / acore (change in production!)"
