# MyPet

Plataforma de serviços para pets composta por um app Flutter multiplataforma e nove microsserviços NestJS orquestrados via Docker Compose.

---

## Arquitetura

```
Flutter App (web · Windows · Android)
        │
        ▼
  API Gateway :3000  ──── JWT · CORS · Rate limit
        │
  ┌─────┼──────────────────────────────────────┐
  │     │                                      │
auth  user-pet  establishment  marketplace  booking  notification  review  faq
:3001  :3002      :3003          :3004       :3005      :3006       :3007  :3008
  │     │                                      │
  └─────┴──────────── PostgreSQL :5433 ────────┘
                      RabbitMQ   :5672
                      Consul     :8500
```

Cada microsserviço tem seu próprio banco PostgreSQL. RabbitMQ transporta eventos entre booking, notification, marketplace e review. Consul faz service discovery.

---

## Serviços

| Serviço | Porta | Banco | Responsabilidade |
|---|---|---|---|
| api-gateway | 3000 | — | Roteamento, auth JWT, rate limit |
| auth-service | 3001 | mypet_auth | Login, registro, emissão de token |
| user-pet-service | 3002 | mypet_users | Perfil de usuário e cadastro de pets |
| establishment-service | 3003 | mypet_estab | Cadastro e gestão de estabelecimentos |
| marketplace-service | 3004 | mypet_market | Catálogo e vitrine de produtos |
| booking-service | 3005 | mypet_booking | Agendamentos e disponibilidade |
| notification-service | 3006 | mypet_notif | Notificações por evento RabbitMQ |
| review-service | 3007 | mypet_review | Avaliações de estabelecimentos |
| faq-service | 3008 | mypet_faq | Perguntas frequentes (admin) |

---

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 24+
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- Node.js 18+ (só para rodar localmente sem Docker)

---

## Rodar com Docker (recomendado)

```bash
# Subir toda a stack (infraestrutura + 9 serviços)
docker compose up -d --build

# Verificar saúde de cada serviço
curl http://localhost:3000/health   # gateway
curl http://localhost:3001/health   # auth
# ... portas 3002–3008 seguem o mesmo padrão
```

Aguarde ~60 segundos na primeira execução para o auth-service terminar as migrations e o seed inicial.

### Variáveis de ambiente

Cada serviço lê um arquivo `.env` na sua pasta. Os valores padrão já estão configurados no `docker-compose.yml` para uso local. Para produção, sobrescreva:

| Variável | Descrição |
|---|---|
| `JWT_SECRET` | Segredo de assinatura dos tokens JWT |
| `DATABASE_URL` | Connection string PostgreSQL |
| `RABBITMQ_URL` | URL do broker RabbitMQ |
| `ADMIN_SECRET` | Senha de acesso às rotas admin do faq-service |

---

## Rodar localmente (sem Docker)

```bash
# 1. Instalar dependências de todos os serviços
npm run install:all

# 2. Subir apenas a infraestrutura (banco, fila, consul)
docker compose up -d postgres rabbitmq consul

# 3. Executar migrations e seed
npm run setup

# 4. Iniciar todos os serviços em paralelo
npm start
```

---

## App Flutter

```bash
cd mypet_app

# Web
flutter run -d chrome

# Windows desktop
flutter run -d windows

# Android (emulador)
flutter run -d android
```

O app detecta a plataforma automaticamente e aponta para o gateway correto:

- Web e desktop → `http://localhost:3000`
- Android emulator → `http://10.0.2.2:3000`

---

## Telas do app

**Cliente**
- Splash · Login · Registro
- Home · Perfil · Editar perfil
- Pets (lista e cadastro)
- Marketplace (produtos e detalhes)
- Carrinho · Pagamento
- Estabelecimento (detalhes e agendamento)
- Histórico · Rastreamento · Agenda
- Notificações · Ajuda

**Estabelecimento**
- Dashboard · Perfil · Horários
- Gestão de produtos · Agenda
- Avaliações · Estatísticas · Suporte

**Admin**
- Painel administrativo · FAQ

---

## Scripts disponíveis (raiz)

| Comando | Descrição |
|---|---|
| `npm start` | Inicia todos os serviços em paralelo com saída colorida |
| `npm run dev` | Para containers conflitantes e inicia localmente |
| `npm run install:all` | Instala dependências de todos os serviços |
| `npm run setup` | Instala, migra banco e popula seed inicial |

---

## Estrutura do repositório

```
MyPet/
├── api-gateway/          # Gateway NestJS
├── auth-service/         # Autenticação
├── user-pet-service/     # Usuários e pets
├── establishment-service/# Estabelecimentos
├── marketplace-service/  # Marketplace
├── booking-service/      # Agendamentos
├── notification-service/ # Notificações
├── review-service/       # Avaliações
├── faq-service/          # FAQ
├── mypet_app/            # App Flutter
└── docker-compose.yml    # Orquestração completa
```
