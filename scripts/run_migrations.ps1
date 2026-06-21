$root = Split-Path -Parent $PSScriptRoot

$services = @(
  @{name="user-auth"; db="mypet_auth"},
  @{name="user-pet"; db="mypet_users"},
  @{name="establishment"; db="mypet_estab"},
  @{name="marketplace"; db="mypet_market"},
  @{name="booking"; db="mypet_booking"},
  @{name="review"; db="mypet_review"},
  @{name="faq"; db="mypet_faq"},
  @{name="notification"; db="mypet_notif"},
  @{name="user-driver"; db="mypet_driver"},
  @{name="user-vet"; db="mypet_vet"},
  @{name="chat"; db="mypet_chat"}
)

foreach ($svc in $services) {
  Write-Host "Migrando $($svc.name)..." -ForegroundColor Cyan
  $env:DATABASE_URL = "postgresql://postgres:root@localhost:5433/$($svc.db)"
  npm run db:migrate --prefix "$root\services\$($svc.name)" 2>&1 |
    Select-String -Pattern "Migrations applied|Error|error" | ForEach-Object { Write-Host $_ }
}
