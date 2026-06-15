# MyPet

Plataforma de serviços para pets: app Flutter multiplataforma + 12 microsserviços NestJS (Clean Architecture/DDD, Drizzle ORM) orquestrados via Docker Compose, com Nginx na frente e RabbitMQ entre os serviços.

---

## Arquitetura

```
Flutter App (web · Android · desktop)
        │  http://localhost (web usa 127.0.0.1; Android usa 10.0.2.2)
        ▼
     Nginx :80
        │
  API Gateway :3000 ─── JWT · CORS · Rate limit
        │
  ┌─────┴────────────────────────────────────────────────────────┐
  user-auth  user-pet  establishment  marketplace  booking        │
   :3001      :3002      :3003          :3004       :3005         │
  notification  review   faq    user-driver   user-vet   chat    │
   :3006        :3007   :3008     :3009        :3010      :3011  │
  └───────────────┬──────────────────────────────────────────────┘
            PostgreSQL :5433 (um banco por serviço)
            RabbitMQ   :5672 (eventos entre serviços)
```

- Cada serviço tem banco próprio e segue `domain / application / infra` por feature.
- RabbitMQ transporta eventos (booking, marketplace, notificações, chamados de emergência).
- O notification-service expõe **SSE** (`GET /notifications/stream/:userId?token=`) — toda notificação criada vira push em tempo real. É assim que o alarme de emergência do veterinário dispara em <1s (com polling de 15s como fallback).
- O chat-service usa **Socket.IO** (WebSocket) para mensagens em tempo real entre cliente e estabelecimento.
- `shared/` concentra guards (JWT + permissões RBAC), Drizzle, RabbitMQ e contratos de eventos, importado por todos os serviços.

---

## Serviços

| Serviço | Porta | Banco | Responsabilidade |
|---|---|---|---|
| api-gateway | 3000 | — | Roteamento, auth JWT, rate limit, proxy WS |
| user-auth | 3001 | mypet_auth | Login, registro, JWT com permissões |
| user-pet | 3002 | mypet_users | Pets do usuário |
| establishment | 3003 | mypet_estab | Estabelecimentos, serviços, vínculos com vets |
| marketplace | 3004 | mypet_market | Produtos, carrinho, pedidos, pagamento |
| booking | 3005 | mypet_booking | Agendamentos, disponibilidade, escrow de pagamento |
| notification | 3006 | mypet_notif | Push (FCM), e-mail (Nodemailer) e SSE stream |
| review | 3007 | mypet_review | Avaliações e reclamações de estabelecimentos |
| faq | 3008 | mypet_faq | Central de ajuda (admin) |
| user-driver | 3009 | mypet_driver | Motoristas (cadastro PENDENTE → aprovação do admin) |
| user-vet | 3010 | mypet_vet | Veterinários, disponibilidade 24h, chamados de emergência |
| chat | 3011 | mypet_chat | Mensagens em tempo real via Socket.IO |

---

## App Flutter — Arquitetura (MVVM) e padrões

O app (`mypet_app/`) segue **MVVM**, com camadas explícitas e regra de negócio fora da interface.

### Camadas MVVM

| Camada | Pasta | Responsabilidade |
|---|---|---|
| **Model** | `lib/models/` | Entidades + `factory fromJson` (ex.: `EstablishmentModel`, `UserModel`) |
| **View** | `lib/screens/` · `lib/widgets/` | Só renderiza e captura interação; observa o ViewModel via `context.watch` |
| **ViewModel** | `lib/providers/` | `ChangeNotifier` com estado (loading / erro / dados) e ações; não concentra UI |
| Repository | `lib/repositories/` | Abstrai a origem dos dados (interface + implementação) |
| Service | `lib/services/` | HTTP (`ApiService`), armazenamento (`StorageService`), SSE |

Fluxo: **View → ViewModel (Provider) → Repository → Service (HTTP/SSE) → Model**.

### Padrões de projeto

- **Observer** — `provider` + `ChangeNotifier` / `notifyListeners()`. As Views se inscrevem (`context.watch`) e reagem automaticamente às mudanças de estado do ViewModel.
- **Repository** — interface desacopla o ViewModel da fonte de dados.
- **Factory** — `factory Model.fromJson(...)` em todos os models converte o JSON da API em objetos de domínio.
- **Singleton (acesso estático)** — `ApiService` e `StorageService` expõem operações estáticas.

### Comunicação com API

- Cliente HTTP central em `lib/services/api_service.dart` (pacote `http`), com **timeout de 15s**.
- `baseUrl` resolve por plataforma (web `127.0.0.1` · Android `10.0.2.2` · desktop `localhost`) — `lib/core/constants.dart`.
- Os três estados são tratados na interface: *Carregamento* → `CircularProgressIndicator` · *Sucesso* → lista · *Erro* → botão **"Tentar novamente"**.

### Armazenamento local

- **`shared_preferences`** via `lib/services/storage_service.dart`.
- Persiste o **token JWT** e o **usuário logado** (serializado em JSON).
- **Recuperação ao reabrir o app**: a `SplashScreen` chama `AuthProvider.loadFromStorage()` no boot, restaurando a sessão sem exigir novo login.

---

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 24+
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.11+
- Node.js 18+ (instalação única de dependências na raiz — não há node_modules por serviço)

---

## Como rodar

```powershell
# 1. dependências (npm raiz + flutter pub get)
.\scripts\setup.ps1

# 2. stack completa (Docker: infra + serviços + nginx)
.\scripts\start.ps1

# 3. app
cd mypet_app
flutter run -d chrome
```

O `start.ps1` cria o `.env` a partir do `.env.example` na primeira execução, espera o Docker Desktop, sobe os containers e aguarda o Nginx responder. Schema do banco é aplicado no startup de cada container (`drizzle-kit push`).

> Dica: rodando `scripts\register-watchdog.ps1` uma vez, os comandos também ficam disponíveis como atalhos de terminal — basta digitar `start`, `setup`, `migrations` ou `fix-localhost`.

### Sem Docker (desenvolvimento)

```bash
docker compose up -d postgres rabbitmq nginx   # só infra
npm start                                      # todos os serviços em watch mode
npm run db:seed                                # dados de exemplo
```

### Variáveis de ambiente

Cada serviço lê um arquivo `.env` na sua pasta (use o `.env.example` como base). Para produção, sobrescreva:

| Variável | Serviços | Descrição |
|---|---|---|
| `JWT_SECRET` | todos | Segredo de assinatura dos tokens JWT |
| `DATABASE_URL` | todos (exceto gateway) | Connection string PostgreSQL |
| `RABBITMQ_URL` | auth, booking, notification, faq, chat | URL do broker RabbitMQ |
| `ADMIN_SECRET` | faq | Senha de acesso às rotas admin |
| `MAIL_HOST` / `MAIL_PORT` / `MAIL_USER` / `MAIL_PASS` / `MAIL_FROM` | notification | Configuração SMTP (Mailtrap em dev, SendGrid em prod) |
| `FCM_SERVICE_ACCOUNT` | notification | JSON da service account do Firebase (push notifications) |

---

## Funcionalidades principais

**Cliente** — pets, marketplace (carrinho/pedidos/pagamento), agendamento de serviços, emergência veterinária, chat com estabelecimento, avaliações, notificações, FAQ.

**Estabelecimento** — painel, produtos, agenda (confirma/recusa/conclui), horários, vínculo de veterinários e motoristas, pedidos com avanço de status.

**Veterinário** — cadastro com aprovação do admin, toggles online/24h/domicílio, agenda própria, **alarme de emergência em tempo real** (overlay + sirene via RabbitMQ→SSE).

**Motorista** — cadastro com aprovação, transporte vinculado a agendamentos.

**Admin** — aprovação de vets/motoristas, reclamações, cadastros, estatísticas, FAQ.

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

## Scripts npm (raiz)

| Comando | Descrição |
|---|---|
| `npm start` | Todos os serviços em paralelo (watch) |
| `npm run start:<serviço>` | Inicia um serviço específico (ex: `start:booking`) |
| `npm run db:migrate:all` | Migrations de todos os serviços |
| `npm run db:seed` | Seed via API real |
| `npm run test:notification` | Testes unitários do serviço de notificação |
| `npm run test:booking` | Testes unitários do serviço de agendamento |
| `npm run test:backend` | Todos os testes backend (notification + booking) |
| `npm run test:flutter` | Testes unitários do app Flutter |
| `npm run test:all` | Backend + Flutter |
| `npm run typecheck:all` | `tsc --noEmit` em todos os serviços |
| `npm run check:all` | Biome (lint + format) no repo |
| `npm run validate:all` | check:all + typecheck:all |

---

## Scripts PowerShell (`scripts/`)

| Script | Descrição |
|---|---|
| `start.ps1` | Sobe a stack inteira e espera ficar saudável |
| `setup.ps1` | Instala dependências (npm raiz + Flutter) |
| `run_migrations.ps1` | Migrations dos serviços com banco |
| `fix-localhost.ps1` | Mata zumbis de porta |
| `register-watchdog.ps1` | Registra tarefa agendada que mata o wslrelay zumbi a cada 5 min |

---

## Testes

### Unitários (backend)

```bash
# notification (C9/C35): SSE stream, heartbeat, handler RabbitMQ
npx jest --config services/notification/jest.config.js

# booking (C36): entity, service, campos petBreed/petAge
npx jest --config services/booking/jest.config.js

# todos de uma vez
npm run test:backend
```

### Chat E2E (C37) — Socket.IO

```bash
# requer serviço de chat rodando na porta 3011
node services/chat/test/chat.e2e.js
```

### Flutter

```bash
cd mypet_app && flutter test --reporter compact
```

### Playwright (E2E completo)

Suíte de ~180 testes que dirige a **UI real do Flutter Web contra o backend real** (sem mocks), em `services/tests/playwright-front/`.

```powershell
# pré-requisitos: stack no ar + build web do app
cd mypet_app; flutter build web --base-href "/"; cd ..
npx playwright test --config playwright.front.config.ts
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
│   ├── user-driver/       # Motoristas
│   ├── user-vet/          # Veterinários e emergências
│   ├── chat/              # Chat em tempo real (Socket.IO)
│   └── tests/             # Suíte Playwright E2E
├── shared/                # Código compartilhado (auth, DB, messaging, HATEOAS)
├── mypet_app/             # App Flutter
├── scripts/               # Automação (start, setup, migrations, watchdog)
├── docker/                # nginx, init-dbs.sql
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
| Frontend | Flutter 3.11 + Provider (MVVM) |
| Containerização | Docker Compose + Nginx |
| Testes | Jest 30 + ts-jest + flutter_test + Playwright (~180 E2E) |
| Lint/Format | Biome 2.4 |
