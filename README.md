# MyPet

Plataforma de serviços para pets: app Flutter multiplataforma + 11 microsserviços NestJS (Clean Architecture/DDD, Drizzle ORM) orquestrados via Docker Compose, com Nginx na frente e RabbitMQ entre os serviços. O chat usa Socket.IO em tempo real (porta 3009).

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
  notification  review   faq    chat   user-driver   user-vet     │
   :3006        :3007   :3008  :3009     :3009        :3010       │
  └───────────────┬──────────────────────────────────────────────┘
            PostgreSQL :5433 (um banco por serviço)
            RabbitMQ   :5672 (eventos entre serviços)
```

- Cada serviço tem banco próprio e segue `domain / application / infra` por feature.
- RabbitMQ transporta eventos (booking, marketplace, notificações, chamados de emergência).
- O notification-service expõe **SSE** (`GET /notifications/stream/:userId?token=`) — toda notificação criada vira push em tempo real. É assim que o alarme de emergência do veterinário dispara em <1s (com polling de 15s como fallback).
- O chat usa Socket.IO (WebSocket) em tempo real.
- `shared/` concentra guards (JWT + permissões RBAC), Drizzle, RabbitMQ e contratos de eventos, importado por todos os serviços.

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
| faq | 3008 | mypet_faq | Perguntas frequentes gerenciadas pelo admin |
| chat | 3009 | mypet_chat | Mensagens em tempo real via Socket.IO |
| user-driver | 3009 | mypet_driver | Motoristas (cadastro PENDENTE → aprovação do admin) |
| user-vet | 3010 | mypet_vet | Veterinários, disponibilidade 24h, chamados de emergência |

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

Exemplo concreto: a `HomeScreen` apenas observa o estado; o `HomeProvider.load()` busca os dados pelo `EstablishmentListRepository`, que chama `ApiService.get('/establishments')` e converte a resposta em `EstablishmentModel`. A tela não tem regra de negócio — só decide o que mostrar a partir do estado do ViewModel.

### Padrão de projeto adotado

- **Observer / reatividade (padrão principal)** — `provider` + `ChangeNotifier` / `notifyListeners()`. As Views se inscrevem (`context.watch`) e reagem automaticamente às mudanças de estado do ViewModel. Os ViewModels são registrados em `lib/main.dart` via `MultiProvider`.
- **Repository** — interface (`IEstablishmentListRepository`) desacopla o ViewModel da fonte de dados.
- **Factory** — `factory Model.fromJson(...)` em todos os models converte o JSON da API em objetos de domínio.
- **Singleton (acesso estático)** — `ApiService` e `StorageService` expõem operações estáticas; `SharedPreferences.getInstance()` reaproveita a mesma instância.

### Comunicação com API

- Cliente HTTP central em `lib/services/api_service.dart` (pacote `http`), com **timeout de 15s** e helpers `get/post/patch/put/delete`.
- `baseUrl` resolve por plataforma (web `127.0.0.1` · Android `10.0.2.2` · desktop `localhost`) — `lib/core/constants.dart`.
- **Os três estados são tratados na interface** (ex.: `lib/screens/home_screen.dart`):
  - *Carregamento* → `CircularProgressIndicator`
  - *Sucesso* → lista renderizada (com estado vazio tratado)
  - *Erro* → ícone offline + mensagem + botão **"Tentar novamente"**; falhas de rede/timeout são detectadas por `ApiService.isNetworkError`.

### Armazenamento local

- **`shared_preferences`** via `lib/services/storage_service.dart`.
- Persiste o **token JWT**, o **usuário logado** (serializado em JSON) e caminhos de fotos (CNH/CRMV/veículo).
- **Recuperação ao reabrir o app**: a `SplashScreen` chama `AuthProvider.loadFromStorage()` no boot, restaurando a sessão sem exigir novo login.

### Rodar apenas o app

```powershell
cd mypet_app
flutter pub get
flutter run -d chrome   # requer a stack no ar (ver "Como rodar")
```

## Pré-requisitos

- Docker Desktop 24+
- Flutter SDK 3.x
- Node.js 18+ (instalação única de dependências na raiz — não há node_modules por serviço)

## Como rodar

```powershell
# 1. dependências (npm raiz + flutter pub get)
.\scripts\setup.ps1

# 2. stack completa (Docker: infra + 11 serviços + nginx)
.\scripts\start.ps1

# 3. app
cd mypet_app
flutter run -d chrome
```

O `start.ps1` cria o `.env` a partir do `.env.example` na primeira execução, espera o Docker Desktop, sobe os containers e aguarda o Nginx responder. Schema do banco é aplicado no startup de cada container (`drizzle-kit push`).

> Dica: rodando `scripts\register-watchdog.ps1` uma vez, os comandos também ficam disponíveis como atalhos de terminal — basta digitar `start`, `setup`, `migrations` ou `fix-localhost` (configurados no perfil do PowerShell).

### Sem Docker (desenvolvimento)

```bash
docker compose up -d postgres rabbitmq nginx   # só infra
npm start                                      # 11 serviços em watch mode
npm run db:seed                                # dados de exemplo
```

## Funcionalidades principais

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

**Veterinário** — cadastro com aprovação do admin, toggles online/24h/domicílio, agenda própria, **alarme de emergência em tempo real** (overlay + sirene via RabbitMQ→SSE), pacientes.

**Motorista** — cadastro com aprovação, transporte vinculado a agendamentos.

**Admin** — aprovação de vets/motoristas, reclamações, cadastros, estatísticas, FAQ.

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
| `booking.today-reminder` | booking | notification |
| `marketplace.order-created` | marketplace | notification |
| `review.created` | review | notification · establishment |
| `emergency.vet-call` | user-vet | notification |

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

## Scripts PowerShell (`scripts/`)

| Script | Descrição |
|---|---|
| `start.ps1` | Sobe a stack inteira e espera ficar saudável |
| `setup.ps1` | Instala dependências (npm raiz + Flutter) |
| `run_migrations.ps1` | Migrations dos 10 serviços com banco |
| `fix-localhost.ps1` | Mata zumbis de porta (wslrelay em `::1:80`, python órfão na 8080) |
| `register-watchdog.ps1` | Registra tarefa agendada que mata o wslrelay zumbi a cada 5 min (`-Remove` desfaz) |

## Testes E2E (Playwright)

Suíte de ~180 testes que dirige a **UI real do Flutter Web contra o backend real** (sem mocks), em `services/tests/playwright-front/`.

```powershell
# pré-requisitos: stack no ar + build web do app
cd mypet_app; flutter build web --base-href "/"; cd ..

npx playwright test --config playwright.front.config.ts            # suíte completa
npx playwright test 40-vet-alarme --config playwright.front.config.ts  # um spec
```

O `globalSetup` da suíte limpa automaticamente os zumbis de porta antes de rodar. O app web é servido em `:8080` pelo próprio Playwright.

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
│   ├── chat/              # Chat em tempo real (Socket.IO)
│   ├── user-driver/       # Motoristas
│   ├── user-vet/          # Veterinários
│   └── tests/             # Suíte Playwright E2E
├── shared/                # Código compartilhado (auth, DB, messaging, HATEOAS)
├── mypet_app/             # App Flutter
├── scripts/               # Automação (start, setup, migrations, watchdog)
├── docker/                # nginx, init de bancos
└── docker-compose.yml
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
