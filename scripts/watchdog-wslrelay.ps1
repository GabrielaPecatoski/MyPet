$log = Join-Path $env:LOCALAPPDATA 'mypet-watchdog.log'

function Write-Log([string]$msg) {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
  Add-Content -Path $log -Value $line
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
