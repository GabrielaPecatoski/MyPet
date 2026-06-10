$services = @(
  @{name="user-auth"; db="mypet_auth"},
  @{name="user-pet"; db="mypet_pet"},
  @{name="establishment"; db="mypet_estab"},
  @{name="marketplace"; db="mypet_marketplace"},
  @{name="booking"; db="mypet_booking"},
  @{name="review"; db="mypet_review"},
  @{name="faq"; db="mypet_faq"},
  @{name="notification"; db="mypet_notif"},
  @{name="driver"; db="mypet_driver"}
)

foreach ($svc in $services) {
  Write-Host "Migrando $($svc.name)..." -ForegroundColor Cyan
  $env:DATABASE_URL = "postgresql://postgres:root@localhost:5433/$($svc.db)"
  cd "services/$($svc.name)"
  npm run db:migrate 2>&1 | Select-String -Pattern "Migrations applied|Error|error" | ForEach-Object { Write-Host $_ }
  cd ../..
}
