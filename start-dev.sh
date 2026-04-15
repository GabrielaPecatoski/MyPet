#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# MyPet — Script de desenvolvimento local
# Sobe infra (Docker), todos os microserviços e o app Flutter de uma vez.
#
# Uso:
#   ./start-dev.sh          → sobe tudo
#   ./start-dev.sh infra    → só Docker (postgres, rabbitmq, consul)
#   ./start-dev.sh services → só microserviços (infra já rodando)
#   ./start-dev.sh flutter  → só o app Flutter
#   ./start-dev.sh stop     → para tudo
# ─────────────────────────────────────────────────────────────────────────────

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
PIDS_FILE="$ROOT/.dev-pids"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[MyPet]${NC} $1"; }
warn() { echo -e "${YELLOW}[MyPet]${NC} $1"; }
info() { echo -e "${CYAN}[MyPet]${NC} $1"; }
err()  { echo -e "${RED}[MyPet]${NC} $1"; }

# ── Parar tudo ───────────────────────────────────────────────────────────────
stop_all() {
  if [ -f "$PIDS_FILE" ]; then
    log "Parando microserviços..."
    while IFS= read -r pid; do
      kill "$pid" 2>/dev/null && log "  PID $pid encerrado" || true
    done < "$PIDS_FILE"
    rm -f "$PIDS_FILE"
  fi
  log "Parando infraestrutura Docker..."
  cd "$ROOT" && docker compose stop
  log "Tudo parado."
}

if [ "${1:-}" = "stop" ]; then
  stop_all
  exit 0
fi

# ── Infraestrutura ───────────────────────────────────────────────────────────
start_infra() {
  log "Subindo infraestrutura (PostgreSQL, RabbitMQ, Consul)..."
  cd "$ROOT"
  docker compose up -d postgres rabbitmq consul

  # Aguardar PostgreSQL
  info "Aguardando PostgreSQL ficar pronto..."
  for i in $(seq 1 30); do
    if docker exec mypet-postgres pg_isready -U postgres -q 2>/dev/null; then
      log "PostgreSQL pronto!"
      break
    fi
    sleep 2
    if [ "$i" -eq 30 ]; then
      err "PostgreSQL não respondeu em 60s. Verifique o Docker."
      exit 1
    fi
  done

  # Aguardar RabbitMQ
  info "Aguardando RabbitMQ ficar pronto..."
  for i in $(seq 1 20); do
    if docker exec mypet-rabbitmq rabbitmq-diagnostics ping -q 2>/dev/null; then
      log "RabbitMQ pronto!"
      break
    fi
    sleep 3
    if [ "$i" -eq 20 ]; then
      warn "RabbitMQ ainda não respondeu — continuando mesmo assim."
      break
    fi
  done
}

# ── Microserviços ────────────────────────────────────────────────────────────
start_service() {
  local name="$1"
  local dir="$ROOT/$2"
  local port="$3"
  local log_file="$ROOT/logs/${name}.log"

  mkdir -p "$ROOT/logs"

  if [ ! -d "$dir/node_modules" ]; then
    warn "node_modules não encontrado em $name — rodando npm install..."
    (cd "$dir" && npm install --silent)
  fi

  info "Iniciando $name (porta $port)..."
  (cd "$dir" && npm run start:dev > "$log_file" 2>&1) &
  echo $! >> "$PIDS_FILE"
  log "  $name → http://localhost:$port  |  log: logs/${name}.log"
}

start_services() {
  rm -f "$PIDS_FILE"
  touch "$PIDS_FILE"

  start_service "api-gateway"          "api-gateway"          3000
  start_service "auth-service"         "auth-service"         3001
  start_service "user-pet-service"     "user-pet-service"     3002
  start_service "establishment-service" "establishment-service" 3003
  start_service "marketplace-service"  "marketplace-service"  3004
  start_service "booking-service"      "booking-service"      3005
  start_service "notification-service" "notification-service" 3006
  start_service "review-service"       "review-service"       3007
}

# ── Flutter ──────────────────────────────────────────────────────────────────
start_flutter() {
  local flutter_dir="$ROOT/mypet_app"
  local log_file="$ROOT/logs/flutter.log"

  mkdir -p "$ROOT/logs"

  if ! command -v flutter &>/dev/null; then
    warn "Flutter não encontrado no PATH. Pule esta etapa ou adicione flutter ao PATH."
    return
  fi

  info "Iniciando Flutter..."
  (cd "$flutter_dir" && flutter run -d chrome > "$log_file" 2>&1) &
  echo $! >> "$PIDS_FILE"
  log "  Flutter → iniciando no Chrome  |  log: logs/flutter.log"
}

# ── Main ─────────────────────────────────────────────────────────────────────
MODE="${1:-all}"

case "$MODE" in
  infra)
    start_infra
    ;;
  services)
    start_services
    ;;
  flutter)
    start_flutter
    ;;
  all|*)
    start_infra
    start_services

    echo ""
    log "Aguardando serviços iniciarem (10s)..."
    sleep 10

    start_flutter

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  MyPet rodando! 🐾${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  API Gateway:   ${CYAN}http://localhost:3000${NC}"
    echo -e "  Auth:          ${CYAN}http://localhost:3001${NC}"
    echo -e "  User/Pet:      ${CYAN}http://localhost:3002${NC}"
    echo -e "  Establishment: ${CYAN}http://localhost:3003${NC}"
    echo -e "  Marketplace:   ${CYAN}http://localhost:3004${NC}"
    echo -e "  Booking:       ${CYAN}http://localhost:3005${NC}"
    echo -e "  Notification:  ${CYAN}http://localhost:3006${NC}"
    echo -e "  Review:        ${CYAN}http://localhost:3007${NC}"
    echo ""
    echo -e "  Consul UI:     ${CYAN}http://localhost:8500${NC}"
    echo -e "  RabbitMQ UI:   ${CYAN}http://localhost:15672${NC}  (mypet / mypet123)"
    echo ""
    echo -e "  Logs:  ${YELLOW}./logs/<service>.log${NC}"
    echo -e "  Parar: ${YELLOW}./start-dev.sh stop${NC}"
    echo ""

    # Tratar Ctrl+C
    trap stop_all INT TERM
    wait
    ;;
esac
