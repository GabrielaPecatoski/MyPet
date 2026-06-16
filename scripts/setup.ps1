Write-Host "=== MyPet Setup ===" -ForegroundColor Cyan

$root = Split-Path -Parent $PSScriptRoot

Write-Host "`n[1/2] Instalando dependencias Node (node_modules unico na raiz)..." -ForegroundColor Yellow
npm install --prefix $root

Write-Host "`n[2/2] Instalando dependencias Flutter..." -ForegroundColor Yellow
Set-Location "$root\mypet_app"
flutter pub get

Set-Location $root
Write-Host "`n=== Setup concluido! ===" -ForegroundColor Green
Write-Host "Suba a stack com: powershell -File scripts\start.ps1" -ForegroundColor Cyan
