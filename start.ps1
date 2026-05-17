# MyPet - Start Stack (Docker)
# Se travar na politica de execucao, rode no terminal:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "Verificando Docker..." -ForegroundColor Cyan
docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Docker nao esta rodando. Abra o Docker Desktop e tente novamente." -ForegroundColor Red
  exit 1
}

Write-Host "Parando containers anteriores..." -ForegroundColor Cyan
docker compose down | Out-Null

Write-Host "Subindo a stack (pode demorar no primeiro build)..." -ForegroundColor Cyan
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
  Write-Host "Erro ao subir os containers. Verifique se o Docker Desktop esta aberto." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Aguardando servicos iniciarem (90s)..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

Write-Host ""
Write-Host "Status do gateway:" -ForegroundColor Cyan
Write-Host "--------------------"

try {
  $res = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
  if ($res.StatusCode -eq 200) {
    Write-Host "  gateway          [OK]" -ForegroundColor Green
  } else {
    Write-Host "  gateway          [ERRO - HTTP $($res.StatusCode)]" -ForegroundColor Red
  }
} catch {
  Write-Host "  gateway          [ERRO - sem resposta]" -ForegroundColor Red
}

Write-Host ""
Write-Host "Verificando containers:" -ForegroundColor Cyan
docker compose ps

Write-Host ""
Write-Host "Infraestrutura:" -ForegroundColor Cyan
Write-Host "  PostgreSQL      -> localhost:5433"
Write-Host "  RabbitMQ UI     -> http://localhost:15672  (mypet/mypet123)"
Write-Host ""

$wslIp = $null
try {
  $wslIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -like '*WSL*' } |
    Select-Object -First 1 -ExpandProperty IPAddress)
} catch { }

Write-Host "Para Flutter em dispositivo fisico / emulador Android:" -ForegroundColor Cyan
if ($wslIp) {
  Write-Host "  Esta maquina (WSL) -> http://${wslIp}:3000"
} else {
  Write-Host "  Descubra seu IP:      ipconfig | findstr IPv4"
  Write-Host "  Use o IP da maquina-> http://<SEU-IP>:3000"
}
Write-Host "  Emulador Android   -> http://10.0.2.2:3000"
Write-Host ""
Write-Host "Comandos uteis:"
Write-Host "  docker compose logs -f api-gateway   # logs do gateway"
Write-Host "  docker compose logs -f user-auth     # logs de um servico"
Write-Host "  docker compose ps                    # status dos containers"
Write-Host "  docker compose down                  # parar tudo"
Write-Host "  docker compose down -v               # parar + apagar volumes (reset DB)"
Write-Host ""
