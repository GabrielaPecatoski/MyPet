# Watchdog do wslrelay zumbi (roda via Tarefa Agendada a cada 5 min).
#
# Problema: `wslrelay` (WSL) às vezes fica preso escutando ::1:80 SEM responder.
# Como `localhost` resolve primeiro para ::1, http://localhost inteiro trava
# (timeout), enquanto http://127.0.0.1 (Docker) segue funcionando.
#
# Regra de segurança: só mata o wslrelay se OUTRO processo (Docker) também
# estiver servindo a porta 80 — ou seja, só em situação de conflito, nunca
# quando o wslrelay for o único dono legítimo da porta.
#
# Registro/remoção da tarefa: scripts/register-watchdog.ps1

$log = Join-Path $env:LOCALAPPDATA 'mypet-watchdog.log'

function Write-Log([string]$msg) {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
  Add-Content -Path $log -Value $line
  # mantém o log pequeno (últimas 200 linhas)
  $lines = Get-Content $log -ErrorAction SilentlyContinue
  if ($lines.Count -gt 200) { $lines | Select-Object -Last 200 | Set-Content $log }
}

$listeners = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
if (-not $listeners) { return }

$wslrelay = @($listeners | Where-Object {
  (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -eq 'wslrelay'
})
$outros = @($listeners | Where-Object {
  (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -ne 'wslrelay'
})

if ($wslrelay.Count -gt 0 -and $outros.Count -gt 0) {
  foreach ($c in $wslrelay) {
    Write-Log "conflito na porta 80: matando wslrelay PID $($c.OwningProcess) em $($c.LocalAddress):80 (Docker tambem escuta)"
    try { Stop-Process -Id $c.OwningProcess -Force -Confirm:$false -ErrorAction Stop } catch {
      Write-Log "falha ao matar PID $($c.OwningProcess): $($_.Exception.Message)"
    }
  }
}
