@echo off
REM ─────────────────────────────────────────────────────────────────────────────
REM MyPet — Script de desenvolvimento local (Windows)
REM Uso: start-dev.bat [stop]
REM ─────────────────────────────────────────────────────────────────────────────

setlocal EnableDelayedExpansion

set ROOT=%~dp0

if "%1"=="stop" goto :stop_all

REM ── Infraestrutura ────────────────────────────────────────────────────────────
echo [MyPet] Subindo infraestrutura Docker (PostgreSQL, RabbitMQ, Consul)...
docker compose up -d postgres rabbitmq consul

echo [MyPet] Aguardando PostgreSQL ficar pronto (20s)...
timeout /t 20 /nobreak >nul

REM ── Microservicos ─────────────────────────────────────────────────────────────
echo [MyPet] Iniciando microservicos...

if not exist "%ROOT%logs" mkdir "%ROOT%logs"

start "api-gateway (3000)"          cmd /k "cd /d %ROOT%api-gateway          && npm run start:dev"
start "auth-service (3001)"         cmd /k "cd /d %ROOT%auth-service         && npm run start:dev"
start "user-pet-service (3002)"     cmd /k "cd /d %ROOT%user-pet-service     && npm run start:dev"
start "establishment-service (3003)" cmd /k "cd /d %ROOT%establishment-service && npm run start:dev"
start "marketplace-service (3004)"  cmd /k "cd /d %ROOT%marketplace-service  && npm run start:dev"
start "booking-service (3005)"      cmd /k "cd /d %ROOT%booking-service      && npm run start:dev"
start "notification-service (3006)" cmd /k "cd /d %ROOT%notification-service && npm run start:dev"
start "review-service (3007)"       cmd /k "cd /d %ROOT%review-service       && npm run start:dev"

echo.
echo [MyPet] Aguardando servicos iniciarem (15s)...
timeout /t 15 /nobreak >nul

REM ── Flutter ───────────────────────────────────────────────────────────────────
where flutter >nul 2>&1
if %errorlevel% equ 0 (
    echo [MyPet] Iniciando Flutter...
    start "Flutter App" cmd /k "cd /d %ROOT%mypet_app && flutter run -d chrome"
) else (
    echo [MyPet] Flutter nao encontrado no PATH - inicie manualmente com: cd mypet_app ^&^& flutter run
)

echo.
echo ════════════════════════════════════════════════
echo   MyPet rodando!
echo ════════════════════════════════════════════════
echo.
echo   API Gateway:   http://localhost:3000
echo   Auth:          http://localhost:3001
echo   User/Pet:      http://localhost:3002
echo   Establishment: http://localhost:3003
echo   Marketplace:   http://localhost:3004
echo   Booking:       http://localhost:3005
echo   Notification:  http://localhost:3006
echo   Review:        http://localhost:3007
echo.
echo   Consul UI:     http://localhost:8500
echo   RabbitMQ UI:   http://localhost:15672  (mypet / mypet123)
echo.
echo   Para parar:    start-dev.bat stop
echo.
goto :eof

:stop_all
echo [MyPet] Parando infraestrutura Docker...
docker compose stop
echo [MyPet] Feche as janelas dos servicos manualmente (ou feche o terminal).
echo [MyPet] Infraestrutura parada.
