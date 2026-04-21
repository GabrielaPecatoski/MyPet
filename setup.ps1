Write-Host "=== MyPet Setup ===" -ForegroundColor Cyan

$root = $PSScriptRoot
$services = @(
    "api-gateway",
    "auth-service",
    "user-pet-service",
    "establishment-service",
    "marketplace-service",
    "booking-service",
    "notification-service",
    "review-service"
)

# 1. Instalar dependencias de cada servico
Write-Host "`n[1/3] Instalando dependencias..." -ForegroundColor Yellow
foreach ($svc in $services) {
    Write-Host "  -> $svc" -ForegroundColor Gray
    npm install --prefix "$root\$svc" --silent
}

# 2. Instalar dependencias da raiz (concurrently)
Write-Host "`n[2/3] Instalando dependencias da raiz..." -ForegroundColor Yellow
npm install --prefix $root --silent

# 3. Gerar Prisma client + migration + seed
Write-Host "`n[3/3] Configurando banco de dados (auth-service)..." -ForegroundColor Yellow
Set-Location "$root\auth-service"
npx prisma generate
npx prisma migrate dev --name init
npx ts-node prisma/seed.ts

Set-Location $root
Write-Host "`n=== Setup concluido! ===" -ForegroundColor Green
Write-Host "Rode: npm start" -ForegroundColor Cyan
