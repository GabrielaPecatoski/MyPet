# MyPet - inicia toda a stack
# Se travar em politica de execucao: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$compose = "$root\docker-compose.yml"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  MyPet - Iniciando stack" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verifica arquivo .env
$envFile = "$root\.env"
if (-not (Test-Path $envFile)) {
  $envExample = "$root\.env.example"
  if (Test-Path $envExample) {
    Copy-Item $envExample $envFile
    Write-Host "[!] .env criado. Defina o JWT_SECRET e feche o Notepad para continuar." -ForegroundColor Yellow
    Start-Process notepad.exe -ArgumentList $envFile -Wait
  } else {
    Write-Host "[!] Arquivo .env nao encontrado. Crie-o com JWT_SECRET definido." -ForegroundColor Red
    exit 1
  }
}

# 2. Verifica / aguarda Docker Desktop
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

# 2. Sobe containers (migrations rodam dentro de cada container no startup)
Write-Host ""
Write-Host "[2/3] Subindo containers..." -ForegroundColor Yellow
docker compose -f $compose up -d
if ($LASTEXITCODE -ne 0) {
  Write-Host "      Erro ao subir containers." -ForegroundColor Red
  exit 1
}
docker compose -f $compose restart nginx | Out-Null

# 3. Aguarda o gateway responder
Write-Host ""
Write-Host "[3/3] Aguardando Nginx (http://localhost/health)..." -ForegroundColor Yellow
$maxWait = 90
$waited  = 0
$ready   = $false
while ($waited -lt $maxWait) {
  Start-Sleep -Seconds 3
  $waited += 3
  try {
    $r = Invoke-WebRequest -Uri "http://localhost/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
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
Write-Host "  API (via Nginx) -> http://localhost"
Write-Host "  Flutter Android -> http://10.0.2.2"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""