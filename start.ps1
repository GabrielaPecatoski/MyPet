# MyPet - inicia toda a stack
# Se travar em politica de execucao: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

$ErrorActionPreference = 'Continue'
$compose = "$PSScriptRoot\docker-compose.yml"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  MyPet - Iniciando stack" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verifica arquivo .env
$envFile = "$PSScriptRoot\.env"
if (-not (Test-Path $envFile)) {
  $envExample = "$PSScriptRoot\.env.example"
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
Write-Host "[2/5] Verificando Docker Desktop..." -ForegroundColor Yellow
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

# 3. Aplica schema nos bancos com alteracoes pendentes
Write-Host ""
Write-Host "[3/5] Aplicando schema (db:push)..." -ForegroundColor Yellow
docker compose -f $compose up -d postgres | Out-Null
$pgReady = $false
for ($i = 0; $i -lt 15; $i++) {
  Start-Sleep -Seconds 2
  docker compose -f $compose exec postgres pg_isready -U postgres 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { $pgReady = $true; break }
}
if ($pgReady) {
  $services = @(
    @{ prefix = 'services/establishment'; db = 'mypet_estab'   },
    @{ prefix = 'services/booking';       db = 'mypet_booking' },
    @{ prefix = 'services/driver';        db = 'mypet_driver'  }
  )
  foreach ($svc in $services) {
    $env:DATABASE_URL = "postgresql://postgres:root@localhost:5433/$($svc.db)"
    npm run db:push --prefix $svc.prefix 2>&1 | Out-Null
  }
  Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue
  Write-Host "      Schema aplicado." -ForegroundColor Green
} else {
  Write-Host "      Postgres nao respondeu -- pulando db:push." -ForegroundColor Yellow
}

# 4. Sobe containers (sem rebuild - usa imagens ja construidas)
Write-Host ""
Write-Host "[4/5] Subindo containers..." -ForegroundColor Yellow
docker compose -f $compose up -d
if ($LASTEXITCODE -ne 0) {
  Write-Host "      Erro ao subir containers." -ForegroundColor Red
  exit 1
}
docker compose -f $compose restart nginx | Out-Null

# 5. Aguarda o gateway responder
Write-Host ""
Write-Host "[5/5] Aguardando Nginx (http://localhost/health)..." -ForegroundColor Yellow
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
Write-Host "  RabbitMQ UI    -> http://localhost:15672  (mypet / mypet123)"
Write-Host "  Flutter Android -> http://10.0.2.2"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""