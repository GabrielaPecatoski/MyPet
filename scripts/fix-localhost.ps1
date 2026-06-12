# Corrige os dois "processos zumbis" que derrubam o ambiente de testes:
#
# 1. wslrelay segurando ::1:80 — `localhost` resolve primeiro para ::1 (IPv6);
#    quando o wslrelay trava nessa porta ele ACEITA a conexão e não responde
#    (timeout, sem fallback para IPv4), então http://localhost morre enquanto
#    http://127.0.0.1 segue funcionando e os containers ficam todos "Up".
#    Matar o wslrelay é seguro: ele re-spawna limpo quando o WSL precisar.
#    NÃO usar `wsl --shutdown` (derruba o engine do Docker Desktop em backend WSL2).
#
# 2. python -m http.server zumbi na 8080 — sobrou de uma rodada Playwright morta;
#    a próxima rodada o reusa (reuseExistingServer) e ele morre no meio, causando
#    ERR_CONNECTION_REFUSED em massa.
#
# Uso:  powershell -File scripts\fix-localhost.ps1 [-RestartWebServer]

param(
  # Se passado, sobe um http.server novo na 8080 servindo o build web do Flutter
  [switch]$RestartWebServer
)

$ErrorActionPreference = 'Continue'

Write-Host "== Porta 80 (localhost/nginx) =="
$port80 = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
foreach ($c in $port80) {
  $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
  Write-Host "  $($c.LocalAddress):80  PID=$($c.OwningProcess)  $($p.ProcessName)"
  if ($p.ProcessName -eq 'wslrelay') {
    Write-Host "  -> matando wslrelay zumbi (PID $($c.OwningProcess))" -ForegroundColor Yellow
    Stop-Process -Id $c.OwningProcess -Force -Confirm:$false
  }
}

Start-Sleep -Seconds 2
try {
  $r = Invoke-WebRequest -Uri http://localhost/faq -UseBasicParsing -TimeoutSec 8
  Write-Host "  http://localhost OK (HTTP $($r.StatusCode))" -ForegroundColor Green
} catch {
  if ($_.Exception.Response) {
    Write-Host "  http://localhost OK (HTTP $($_.Exception.Response.StatusCode.value__))" -ForegroundColor Green
  } else {
    Write-Host "  http://localhost AINDA FALHA: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  (containers ok? 'docker compose ps'; IPv4 ok? 'curl http://127.0.0.1')"
  }
}

Write-Host "== Porta 8080 (Flutter web dos testes) =="
$port8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($port8080 -and $RestartWebServer) {
  foreach ($c in $port8080) {
    Write-Host "  -> matando servidor antigo (PID $($c.OwningProcess))" -ForegroundColor Yellow
    Stop-Process -Id $c.OwningProcess -Force -Confirm:$false
  }
  $port8080 = $null
}
if (-not $port8080) {
  if ($RestartWebServer -or -not (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue)) {
    $webDir = Join-Path $PSScriptRoot '..\mypet_app\build\web'
    Write-Host "  -> subindo http.server desacoplado em :8080 ($webDir)"
    Start-Process python -ArgumentList '-m','http.server','8080','--directory',$webDir -WindowStyle Hidden
    Start-Sleep -Seconds 2
  }
}
try {
  $r = Invoke-WebRequest -Uri http://localhost:8080/index.html -UseBasicParsing -TimeoutSec 5
  Write-Host "  http://localhost:8080 OK (HTTP $($r.StatusCode))" -ForegroundColor Green
} catch {
  Write-Host "  http://localhost:8080 FALHA: $($_.Exception.Message)" -ForegroundColor Red
}
