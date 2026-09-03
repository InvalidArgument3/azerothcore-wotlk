#Requires -RunAsAdministrator
# Removes dependencies installed by scripts\install-deps.ps1

$ErrorActionPreference = 'Stop'

$packages = @(
    'boost-msvc-14.3',
    'cmake.install',
    'visualstudio2022-workload-nativedesktop',
    'visualstudio2022community',
    'openssl',
    'mysql'
)

Write-Host "=== Uninstalling AzerothCore playerbots dependencies ===" -ForegroundColor Cyan

foreach ($pkg in $packages) {
    $installed = choco list --local-only $pkg --exact 2>$null | Select-String "^$pkg "
    if ($installed) {
        Write-Host "Removing $pkg..." -ForegroundColor Yellow
        choco uninstall $pkg -y --remove-dependencies
    } else {
        Write-Host "Skipping $pkg (not installed via Chocolatey)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
