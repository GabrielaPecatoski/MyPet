# MyPet - inicia toda a stack
# Se travar em politica de execucao: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

$ErrorActionPreference = 'Continue'
$compose = "$PSScriptRoot\docker-compose.yml"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  MyPet - Iniciando stack" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verifica / aguarda Docker Desktop
Write-Host "[1/3] Verificando Docker Desktop..." -ForegroundColor Yellow
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "      Docker Desktop nao esta rodando. Iniciando..." -ForegroundColor Yellow
  $dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
  if (Test-Path $dockerExe) { Start-Process $dockerExe }
  $elapsed = 0
  do {
    Start-Sleep -Seconds 4
    $elapsed += 4
    docker info 2>&1 | Out-Null
  } while ($LASTEXITCODE -ne 0 -and $elapsed -lt 120)
  if ($LASTEXITCODE -ne 0) {
    Write-Host "      Docker Desktop nao iniciou. Abra manualmente e rode novamente." -ForegroundColor Red
    exit 1
  }
}
Write-Host "      Docker pronto." -ForegroundColor Green

# 2. Sobe containers (sem rebuild - usa imagens ja construidas)
Write-Host ""
Write-Host "[2/3] Subindo containers..." -ForegroundColor Yellow
docker compose -f $compose up -d
if ($LASTEXITCODE -ne 0) {
  Write-Host "      Erro ao subir containers." -ForegroundColor Red
  exit 1
}

# 3. Aguarda o gateway responder
Write-Host ""
Write-Host "[3/3] Aguardando API Gateway (http://localhost:3000/health)..." -ForegroundColor Yellow
$maxWait = 90
$waited  = 0
$ready   = $false
while ($waited -lt $maxWait) {
  Start-Sleep -Seconds 3
  $waited += 3
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
  Write-Host "      aguardando... ($waited/$maxWait s)" -ForegroundColor DarkGray
}

# Resultado
Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
docker ps --format "table {{.Names}}`t{{.Status}}"
Write-Host ""
if ($ready) {
  Write-Host "  Stack pronta!" -ForegroundColor Green
} else {
  Write-Host "  Gateway ainda nao respondeu. Verifique:" -ForegroundColor Yellow
  Write-Host "  docker compose logs api-gateway" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  API Gateway  -> http://localhost:3000"
Write-Host "  RabbitMQ UI  -> http://localhost:15672  (mypet / mypet123)"
Write-Host "  Flutter emulador Android -> http://10.0.2.2:3000"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""