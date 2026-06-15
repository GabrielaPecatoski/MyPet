# MyPet

Plataforma de serviços para pets composta por um app Flutter multiplataforma e dez microsserviços NestJS orquestrados via Docker Compose.

---

## Arquitetura

```
Flutter App (web · Windows · Android)
        │
        ▼
  API Gateway :3000  ──── JWT · CORS · Rate limit
        │
  ┌─────┼──────────────────────────────────────────────┐
  │     │                                              │
auth  user-pet  establishment  marketplace  booking  notification  review  faq  chat
:3001  :3002      :3003          :3004       :3005      :3006       :3007  :3008 :3009
  │     │                                              │
  └─────┴──────────── PostgreSQL :5433 ────────────────┘
                      RabbitMQ   :5672
```

Cada microsserviço tem seu próprio banco PostgreSQL. RabbitMQ transporta eventos entre booking, notification, marketplace e review. O chat usa Socket.IO (WebSocket) em tempo real e o serviço de notificações expõe um stream SSE para o app Flutter.

---

## Serviços

| Serviço | Porta | Banco | Responsabilidade |
|---|---|---|---|
| api-gateway | 3000 | — | Roteamento, auth JWT, rate limit, proxy WS |
| user-auth | 3001 | mypet_auth | Login, registro, emissão de token |
| user-pet | 3002 | mypet_users | Perfil de usuário e cadastro de pets |
| establishment | 3003 | mypet_estab | Cadastro e gestão de estabelecimentos e serviços |
| marketplace | 3004 | mypet_market | Catálogo de produtos, carrinho e pedidos |
| booking | 3005 | mypet_booking | Agendamentos e disponibilidade |
| notification | 3006 | mypet_notif | Push (FCM), e-mail (Nodemailer) e SSE stream |
| review | 3007 | mypet_review | Avaliações e reclamações de estabelecimentos |
| faq | 3008 | mypet_faq | Perguntas frequentes gerenciadas pelo admin |
| chat | 3009 | mypet_chat | Mensagens em tempo real via Socket.IO |

---

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 24+
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.11+
- Node.js 18+ (só para rodar localmente sem Docker)

---

## Rodar com Docker (recomendado)

### Script automático (Windows)

```powershell
.\start.ps1
```

O script sobe toda a stack, aguarda os serviços iniciarem e exibe o status de saúde de cada um com resultado colorido (OK / ERRO). Requer Docker Desktop em execução.

### Manual

```bash
# Subir toda a stack (infraestrutura + 10 serviços)
docker compose up -d --build

# Verificar saúde de cada serviço
curl http://localhost:3000/health   # gateway
curl http://localhost:3001/health   # auth
# ... portas 3002–3009 seguem o mesmo padrão
```

Aguarde ~60 segundos na primeira execução para os serviços terminarem as migrations e o seed inicial.

### Variáveis de ambiente

Cada serviço lê um arquivo `.env` na sua pasta (use o `.env.example` como base). Os valores padrão já estão configurados no `docker-compose.yml` para uso local. Para produção, sobrescreva:

| Variável | Serviços | Descrição |
|---|---|---|
| `JWT_SECRET` | todos | Segredo de assinatura dos tokens JWT |
| `DATABASE_URL` | todos (exceto gateway) | Connection string PostgreSQL |
| `RABBITMQ_URL` | auth, booking, notification, faq, chat | URL do broker RabbitMQ |
| `ADMIN_SECRET` | faq | Senha de acesso às rotas admin |
| `MAIL_HOST` / `MAIL_PORT` / `MAIL_USER` / `MAIL_PASS` / `MAIL_FROM` | notification | Configuração SMTP (Mailtrap em dev, SendGrid em prod) |
| `FCM_SERVICE_ACCOUNT` | notification | JSON da service account do Firebase (push notifications) |

---

## Rodar localmente (sem Docker)

```bash
# 1. Instalar dependências de todos os serviços
npm install

# 2. Subir apenas a infraestrutura (banco e fila)
docker compose up -d postgres rabbitmq

# 3. Executar migrations em todos os bancos
npm run db:migrate:all

# 4. Popular seed inicial
npm run db:seed

# 5. Iniciar todos os serviços em paralelo
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
- Chat · Conversações
- Notificações · Ajuda

**Estabelecimento**
- Dashboard · Perfil · Horários
- Gestão de produtos · Agenda
- Avaliações · Estatísticas · Suporte

**Admin**
- Painel administrativo · FAQ

---

## Fluxos de eventos (RabbitMQ)

| Evento | Publicado por | Consumido por |
|---|---|---|
| `user-auth.user-created` | user-auth | notification |
| `booking.created` | booking | notification |
| `booking.status-updated` | booking | notification |
| `booking.completed` | booking | notification |
| `booking.canceled` | booking | notification |
| `booking.reminder` | booking | notification |
| `marketplace.order-created` | marketplace | notification |
| `review.created` | review | notification · establishment |

---

## Scripts disponíveis (raiz)

| Comando | Descrição |
|---|---|
| `npm start` | Inicia todos os serviços em paralelo com saída colorida |
| `npm run start:<serviço>` | Inicia um serviço específico (ex: `start:booking`) |
| `npm run db:migrate:all` | Executa migrations em todos os bancos |
| `npm run db:seed` | Popula dados iniciais |
| `npm run test:notification` | Testes unitários do serviço de notificação |
| `npm run test:booking` | Testes unitários do serviço de agendamento |
| `npm run test:backend` | Todos os testes backend (notification + booking) |
| `npm run test:flutter` | Testes unitários do app Flutter |
| `npm run test:all` | Backend + Flutter |
| `npm run typecheck:all` | Verifica tipos TypeScript de todos os serviços |
| `npm run check:all` | Biome check (lint + format) |
| `npm run validate:all` | check:all + typecheck:all |

---

## Testes

```bash
# Backend — notification (C9/C35): SSE stream, heartbeat, handler RabbitMQ
npx jest --config services/notification/jest.config.js

# Backend — booking (C36): entity, service, campos petBreed/petAge
npx jest --config services/booking/jest.config.js

# Chat (C37): Socket.IO E2E (requer serviço rodando na porta 3009)
node services/chat/test/chat.e2e.js

# Flutter — models, providers, chat
cd mypet_app && flutter test --reporter compact
```

---

## Estrutura do repositório

```
MyPet/
├── services/
│   ├── api-gateway/       # Gateway NestJS — proxy + JWT + rate limit
│   ├── user-auth/         # Autenticação e emissão de tokens
│   ├── user-pet/          # Perfil de usuário e pets
│   ├── establishment/     # Estabelecimentos e serviços oferecidos
│   ├── marketplace/       # Produtos, carrinho e pedidos
│   ├── booking/           # Agendamentos e disponibilidade
│   ├── notification/      # Push (FCM), e-mail e SSE stream
│   ├── review/            # Avaliações e reclamações
│   ├── faq/               # Perguntas frequentes
│   └── chat/              # Chat em tempo real (Socket.IO)
├── shared/                # Código compartilhado (auth, DB, messaging, HATEOAS)
├── mypet_app/             # App Flutter
├── tests/
│   └── e2e/               # Testes E2E Playwright
├── scripts/               # seed.mjs e utilitários
├── docker/                # init-dbs.sql (criação dos bancos)
├── docker-compose.yml     # Orquestração completa
├── package.json           # Scripts do monorepo e dependências compartilhadas
└── biome.json             # Configuração de lint e formatação
```

---

## Stack tecnológico

| Camada | Tecnologia |
|---|---|
| Backend | NestJS 11 + TypeScript 5.7 |
| ORM | Drizzle ORM 0.45 + PostgreSQL 15 |
| Messaging | RabbitMQ 3 (amqplib) |
| Auth | JWT + bcryptjs + RBAC por permissões |
| Real-time | Socket.IO (chat) + SSE via rxjs (notificações) |
| Push | Firebase Cloud Messaging (FCM) |
| E-mail | Nodemailer |
| Frontend | Flutter 3.11 + Provider |
| Containerização | Docker Compose |
| Testes | Jest 30 + ts-jest + flutter_test + Playwright |
| Lint/Format | Biome 2.4 |
