param([switch]$Remove)

$taskName = 'MyPetLocalhostWatchdog'
$launcher = Join-Path $env:LOCALAPPDATA 'mypet-watchdog.vbs'

if ($Remove) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
  Remove-Item $launcher -Force -ErrorAction SilentlyContinue
  Write-Host "Tarefa '$taskName' removida."
  return
}

$logic = @'
$l = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
if ($l) {
  $w = @($l | Where-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -eq 'wslrelay' })
  $o = @($l | Where-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -ne 'wslrelay' })
  if ($w.Count -gt 0 -and $o.Count -gt 0) {
    $log = Join-Path $env:LOCALAPPDATA 'mypet-watchdog.log'
    foreach ($c in $w) {
      Add-Content $log "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') matando wslrelay PID $($c.OwningProcess) em $($c.LocalAddress):80"
      try { Stop-Process -Id $c.OwningProcess -Force -Confirm:$false } catch {}
    }
    $lines = Get-Content $log -ErrorAction SilentlyContinue
    if ($lines.Count -gt 200) { $lines | Select-Object -Last 200 | Set-Content $log }
  }
}
'@

$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($logic))

$vbs = 'CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $encoded + '", 0, False'
Set-Content -Path $launcher -Value $vbs -Encoding ascii

$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "//B //Nologo `"$launcher`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
  -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
  -Description 'Mata o wslrelay zumbi quando ele trava ::1:80 e derruba http://localhost (MyPet) - sem janela (wscript), nao depende do repo' -Force | Out-Null

Write-Host "Tarefa '$taskName' registrada (invisivel via wscript, roda a cada 5 min)."
Write-Host "Lancador: $launcher"
Write-Host "Log: $env:LOCALAPPDATA\mypet-watchdog.log"
Write-Host "Para remover: powershell -File scripts\register-watchdog.ps1 -Remove"
