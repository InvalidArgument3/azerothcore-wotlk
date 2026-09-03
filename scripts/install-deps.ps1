#Requires -RunAsAdministrator
# Installs AzerothCore + mod-playerbots Windows dependencies (matches apps/installer/includes/os_configs/windows.sh)

$ErrorActionPreference = 'Stop'

Write-Host "=== Installing AzerothCore Playerbots dependencies ===" -ForegroundColor Cyan

# Visual Studio 2022 Community + C++ desktop workload
choco install -y --skip-checksums visualstudio2022community
choco install -y --skip-checksums visualstudio2022-workload-nativedesktop

# CMake (system PATH)
choco install -y --skip-checksums cmake.install --installargs 'ADD_CMAKE_TO_PATH=System'

# OpenSSL, Boost (VS 2022 / msvc-14.3), MySQL
choco install -y --skip-checksums openssl --force --version=3.6.2
choco install -y --skip-checksums boost-msvc-14.3 --force --version=1.87.0
choco install -y --skip-checksums mysql --force --version=8.4.9

# Refresh PATH for this session
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

Write-Host ""
Write-Host "=== Dependency install complete ===" -ForegroundColor Green
Write-Host "Next: run scripts\setup-playerbots.ps1 from a normal (non-admin) PowerShell in this repo."
