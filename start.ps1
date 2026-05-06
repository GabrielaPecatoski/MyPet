# MyPet - Start Stack
$ErrorActionPreference = 'SilentlyContinue'

$services = @(
  @{ name = 'gateway';      port = 3000 },
  @{ name = 'auth';         port = 3001 },
  @{ name = 'user-pet';     port = 3002 },
  @{ name = 'establishment';port = 3003 },
  @{ name = 'marketplace';  port = 3004 },
  @{ name = 'booking';      port = 3005 },
  @{ name = 'notification'; port = 3006 },
  @{ name = 'review';       port = 3007 },
  @{ name = 'faq';          port = 3008 }
)

Write-Host ""
Write-Host "Verificando Docker..." -ForegroundColor Cyan
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Docker nao esta rodando. Abra o Docker Desktop e tente novamente." -ForegroundColor Red
  exit 1
}

Write-Host "Subindo a stack..." -ForegroundColor Cyan
docker compose down > $null 2>&1
docker compose up -d --build
if (-not $?) {
  Write-Host "Erro ao subir os containers." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Aguardando servicos iniciarem (60s)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "Status dos servicos:" -ForegroundColor Cyan
Write-Host "--------------------"

$allOk = $true
foreach ($svc in $services) {
  try {
    $res = Invoke-WebRequest -Uri "http://localhost:$($svc.port)/health" -TimeoutSec 5 -UseBasicParsing
    if ($res.StatusCode -eq 200) {
      Write-Host "  $($svc.name.PadRight(15)) [OK]" -ForegroundColor Green
    } else {
      Write-Host "  $($svc.name.PadRight(15)) [ERRO - HTTP $($res.StatusCode)]" -ForegroundColor Red
      $allOk = $false
    }
  } catch {
    Write-Host "  $($svc.name.PadRight(15)) [ERRO - sem resposta]" -ForegroundColor Red
    $allOk = $false
  }
}

Write-Host ""
Write-Host "Infraestrutura:" -ForegroundColor Cyan
Write-Host "  PostgreSQL      -> localhost:5433"
Write-Host "  RabbitMQ UI     -> http://localhost:15672  (mypet/mypet123)"
Write-Host "  Consul UI       -> http://localhost:8500"
Write-Host ""
Write-Host "Para o Flutter app (dispositivo fisico/emulador):"
Write-Host "  API Gateway     -> http://172.18.16.1:3000"
Write-Host ""
Write-Host "Bancos de dados:"
Write-Host "  mypet_auth, mypet_users, mypet_estab, mypet_market,"
Write-Host "  mypet_booking, mypet_notif, mypet_review, mypet_faq"
Write-Host ""
Write-Host "Comandos uteis:"
Write-Host "  docker compose logs -f gateway  # logs do gateway"
Write-Host "  docker compose logs -f auth     # logs de um servico"
Write-Host "  docker compose ps               # status dos containers"
Write-Host "  docker compose down             # parar tudo"
Write-Host "  docker compose down -v          # parar + apagar volumes (reset DB)"
Write-Host ""

if ($allOk) {
  Write-Host "================================================" -ForegroundColor Green
  Write-Host "  Todos os servicos estao rodando!" -ForegroundColor Green
  Write-Host "================================================" -ForegroundColor Green
} else {
  Write-Host "================================================" -ForegroundColor Yellow
  Write-Host "  Alguns servicos falharam. Verifique os logs." -ForegroundColor Yellow
  Write-Host "================================================" -ForegroundColor Yellow
}
Write-Host ""
