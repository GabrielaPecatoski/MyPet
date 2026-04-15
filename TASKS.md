# MyPet — Documentação Técnica de Tarefas

---

## Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTE (Flutter Web/Mobile)             │
└───────────────────────────────┬─────────────────────────────────┘
                                │ HTTP / REST
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY  :3000                          │
│   JWT Middleware  │  Rate Limit  │  Proxy  │  CORS              │
└──┬──────┬─────────┬──────┬──────┬──────────┬───────┬───────────┘
   │      │         │      │      │          │       │
  3001   3002      3003   3004   3005        3006   3007
   │      │         │      │      │          │       │
┌──▼──┐ ┌─▼──────┐ ┌▼───┐ ┌▼────┐ ┌────────▼─┐ ┌──▼──┐ ┌───▼──┐
│Auth │ │UserPet │ │Est.│ │Mark │ │ Booking  │ │Noti │ │Review│
│Svc  │ │Service │ │Svc │ │Svc  │ │ Service  │ │Svc  │ │ Svc  │
└──┬──┘ └─┬──────┘ └┬───┘ └┬────┘ └────┬─────┘ └──┬──┘ └───┬──┘
   │      │         │      │           │           │        │
   └──────┴────┬────┴──────┘           │           │        │
               │                       │           │        │
        ┌──────▼──────┐         ┌──────▼───────────▼────────▼────┐
        │  PostgreSQL  │         │         RabbitMQ (Events)       │
        └─────────────┘         └────────────────────────────────┘
```

---

## Fluxo de Autenticação JWT

```
Cliente                API Gateway             Auth Service           DB
  │                        │                        │                  │
  │  POST /auth/login       │                        │                  │
  │ ─────────────────────► │                        │                  │
  │                        │  proxy /auth/login      │                  │
  │                        │ ───────────────────────►│                  │
  │                        │                        │  SELECT user      │
  │                        │                        │ ─────────────────►│
  │                        │                        │  user row         │
  │                        │                        │ ◄─────────────────│
  │                        │                        │  bcrypt.compare   │
  │                        │                        │  jwt.sign(payload)│
  │                        │  { access_token, user } │                  │
  │                        │ ◄───────────────────────│                  │
  │  { access_token, user } │                        │                  │
  │ ◄───────────────────── │                        │                  │
  │                        │                        │                  │
  │  GET /bookings          │                        │                  │
  │  Authorization: Bearer <token>                   │                  │
  │ ─────────────────────► │                        │                  │
  │                        │  AuthGuardMiddleware    │                  │
  │                        │  jwt.verify(token)      │                  │
  │                        │  inject x-user-id       │                  │
  │                        │  inject x-user-role     │                  │
  │                        │  proxy /bookings ──────────────────────►  │
  │                        │                        │                  │
```

---

## Comunicação entre Microserviços (Eventos)

```
Booking Service
    │
    │  booking.created      ──────────────────► Notification Service
    │  booking.confirmed    ──────────────────► Notification Service
    │  booking.cancelled    ──────────────────► Notification Service
    │  booking.completed    ──────────────────► Review Service (trigger)
    │
Review Service
    │
    │  review.created       ──────────────────► Notification Service
    │
Complaint Service
    │
    │  complaint.opened     ──────────────────► Notification Service (admin)
    │  complaint.resolved   ──────────────────► Notification Service (user)
```

Protocolo: **RabbitMQ** — filas do tipo `direct`, persistentes, com `ack` manual.

---

---

# C11 — API de Login

## Descrição

Endpoint responsável pela autenticação de usuários cadastrados. Recebe e-mail e senha, valida as credenciais e retorna um JWT assinado para uso nas demais rotas protegidas.

## Requisitos Funcionais

- Receber e-mail e senha via POST
- Buscar usuário pelo e-mail no banco
- Comparar senha com hash armazenado usando bcrypt
- Gerar e retornar JWT com payload contendo `sub`, `email` e `role`
- Retornar dados públicos do usuário junto com o token

## Requisitos Não Funcionais

- Senha nunca trafega em texto puro em logs ou respostas
- JWT deve expirar em 7 dias
- Tempo de resposta abaixo de 300ms em condições normais
- Rate limit de 10 tentativas por minuto por IP

## Critérios de Aceitação

- [ ] POST /auth/login retorna 200 com `access_token` e `user` para credenciais válidas
- [ ] Retorna 401 para e-mail inexistente
- [ ] Retorna 401 para senha incorreta
- [ ] O JWT contém `sub`, `email` e `role` no payload
- [ ] O token é verificável pelo API Gateway
- [ ] Senha incorreta e e-mail inexistente retornam a mesma mensagem genérica
- [ ] O endpoint aceita `Content-Type: application/json`

## Rotas / Endpoints

```
POST /auth/login
```

### Request

```json
{
  "email": "joao@mypet.com",
  "password": "senha123"
}
```

### Response 200

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-v4",
    "name": "João Silva",
    "email": "joao@mypet.com",
    "phone": "(11) 99999-9999",
    "role": "CLIENTE"
  }
}
```

### Response 401

```json
{
  "statusCode": 401,
  "message": "Credenciais inválidas"
}
```

## JWT Payload

```json
{
  "sub": "uuid-do-usuario",
  "email": "joao@mypet.com",
  "role": "CLIENTE",
  "iat": 1712000000,
  "exp": 1712604800
}
```

## Tecnologias

- NestJS + TypeORM + PostgreSQL
- `@nestjs/jwt` para geração e verificação
- `bcrypt` para comparação de hash
- `class-validator` para validação do DTO

## Erros e Tratamentos

| Situação | HTTP | Mensagem |
|---|---|---|
| E-mail não encontrado | 401 | Credenciais inválidas |
| Senha incorreta | 401 | Credenciais inválidas |
| Campo ausente | 400 | Validation failed |
| Banco indisponível | 500 | Internal server error |

## Integração com outros microserviços

- O token gerado aqui é verificado pelo **API Gateway** em todas as rotas protegidas
- O campo `role` no JWT é usado pelos microserviços downstream para autorização via header `x-user-role`

---

---

# C12 — API de Registro de Usuário

## Descrição

Endpoint responsável pela criação de novos usuários na plataforma. Valida unicidade de e-mail, faz hash da senha e persiste o usuário, retornando o JWT diretamente para que o cliente já fique autenticado.

## Requisitos Funcionais

- Receber nome, e-mail, senha, telefone e CPF
- Verificar se o e-mail já está cadastrado
- Fazer hash da senha com bcrypt (salt rounds: 10)
- Persistir o usuário com role padrão `CLIENTE`
- Retornar JWT e dados públicos do usuário criado

## Requisitos Não Funcionais

- CPF e telefone são opcionais mas devem ser validados se fornecidos
- E-mail deve ser único na tabela
- Senha mínima de 6 caracteres
- Resposta com status 201

## Critérios de Aceitação

- [ ] POST /auth/register retorna 201 com `access_token` e `user`
- [ ] Retorna 409 se o e-mail já estiver cadastrado
- [ ] Retorna 400 se campos obrigatórios estiverem ausentes ou inválidos
- [ ] A senha nunca é armazenada em texto puro
- [ ] O usuário criado tem `role: CLIENTE` por padrão
- [ ] O token gerado é válido e aceito pelo API Gateway

## Rotas / Endpoints

```
POST /auth/register
```

### Request

```json
{
  "name": "João Silva",
  "email": "joao@mypet.com",
  "password": "senha123",
  "phone": "(11) 99999-9999",
  "cpf": "123.456.789-00"
}
```

### Response 201

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-v4",
    "name": "João Silva",
    "email": "joao@mypet.com",
    "phone": "(11) 99999-9999",
    "role": "CLIENTE"
  }
}
```

### Response 409

```json
{
  "statusCode": 409,
  "message": "Email já cadastrado"
}
```

## Entidade User (PostgreSQL)

```json
{
  "id": "uuid-v4",
  "name": "João Silva",
  "email": "joao@mypet.com",
  "password_hash": "$2b$10$...",
  "phone": "(11) 99999-9999",
  "cpf": "123.456.789-00",
  "role": "CLIENTE",
  "created_at": "2026-04-14T12:00:00Z"
}
```

## Tecnologias

- NestJS + TypeORM + PostgreSQL
- `bcrypt` para hash de senha
- `@nestjs/jwt` para geração do token
- `class-validator` + `class-transformer`

## Erros e Tratamentos

| Situação | HTTP | Mensagem |
|---|---|---|
| E-mail duplicado | 409 | Email já cadastrado |
| Campos inválidos | 400 | Validation failed |
| Banco indisponível | 500 | Internal server error |

## Integração com outros microserviços

- Após registro, nenhum evento é emitido por padrão
- O token retornado é usado pelo cliente nas próximas requisições ao **API Gateway**

---

---

# C14 — Tela de Login

## Descrição

Interface de autenticação do aplicativo Flutter. Permite ao usuário informar e-mail e senha para acessar a plataforma. Inclui acesso rápido para demonstração com credenciais pré-definidas e navegação para a tela de cadastro.

## Requisitos Funcionais

- Formulário com campos de e-mail e senha
- Validação de formato de e-mail e comprimento mínimo de senha
- Chamada à API de login e armazenamento do token em SharedPreferences
- Redirecionamento baseado no `role` do usuário após login bem-sucedido
- Exibição de mensagem de erro em caso de falha
- Botão para navegar à tela de registro
- Acesso rápido com credenciais de demonstração
- Fallback para usuários mock quando o backend estiver offline

## Requisitos Não Funcionais

- Compatível com Flutter Web (Chrome) e Android
- Tratamento de erros de rede (`SocketException`, `ClientException`, `XMLHttpRequest error`)
- Feedback visual durante carregamento (CircularProgressIndicator)
- Token e dados do usuário persistidos via SharedPreferences

## Critérios de Aceitação

- [ ] Formulário valida e-mail e senha antes de submeter
- [ ] Exibe loading enquanto aguarda resposta da API
- [ ] Redireciona para `/home` (CLIENTE), `/estab-home` (VENDEDOR) ou `/admin` (ADMIN)
- [ ] Exibe SnackBar com mensagem de erro em caso de falha
- [ ] Ao clicar nos botões de acesso rápido, os campos são preenchidos automaticamente
- [ ] Funciona offline com usuários mock
- [ ] Botão "Criar Conta" navega para `/register`

## Fluxo de Navegação

```
/splash
   │
   ├─ isAuthenticated ──► /home | /estab-home | /admin
   │
   └─ não autenticado ──► /login
                              │
                              ├─ login OK ──► /home | /estab-home | /admin
                              │
                              └─ "Criar Conta" ──► /register
                                                        │
                                                        └─ register OK ──► /home
```

## Dados Armazenados (SharedPreferences)

```json
{
  "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "auth_user": "{\"id\":\"uuid\",\"name\":\"João\",\"email\":\"joao@mypet.com\",\"role\":\"CLIENTE\"}"
}
```

## Tecnologias

- Flutter + Dart
- `provider` para gerenciamento de estado (AuthProvider)
- `shared_preferences` para persistência local
- `http` para chamadas à API
- `dart:convert` para JSON

## Erros e Tratamentos

| Situação | Tratamento |
|---|---|
| Backend offline | Fallback para mock local |
| Credenciais inválidas | SnackBar com mensagem do backend |
| Campo vazio | Validação inline no formulário |
| XMLHttpRequest error (web) | Detectado via `http.ClientException` |

## Integração com outros microserviços

- Consome **C11 (API de Login)** via `POST /auth/login`
- O token retornado é usado em todas as requisições subsequentes aos demais microserviços

---

---

# C7 — Microserviço de Agendamento

## Descrição

Microserviço responsável pelo ciclo de vida completo dos agendamentos de serviços pet. Permite que clientes criem agendamentos, que prestadores confirmem ou recusem, e que qualquer parte cancele dentro das regras definidas. Emite eventos para os demais microserviços ao mudar de status.

## Requisitos Funcionais

- Criar agendamento com pet, serviço, estabelecimento, data e hora
- Listar agendamentos por usuário (cliente ou prestador)
- Confirmar agendamento (apenas VENDEDOR/ADMIN)
- Recusar agendamento com motivo opcional
- Cancelar agendamento (CLIENTE pode cancelar antes da confirmação; VENDEDOR pode cancelar com antecedência mínima de 2h)
- Marcar agendamento como concluído
- Emitir eventos via RabbitMQ ao mudar de status

## Requisitos Não Funcionais

- Status válidos: `PENDENTE`, `CONFIRMADO`, `RECUSADO`, `CANCELADO`, `CONCLUIDO`
- Regras de transição de status devem ser validadas no service
- Índices na coluna `userId`, `establishmentId` e `scheduledAt`
- Paginação nos endpoints de listagem

## Critérios de Aceitação

- [ ] POST /bookings cria agendamento com status `PENDENTE`
- [ ] GET /bookings retorna lista do usuário autenticado
- [ ] PATCH /bookings/:id/confirm altera status para `CONFIRMADO`
- [ ] PATCH /bookings/:id/cancel altera status para `CANCELADO`
- [ ] PATCH /bookings/:id/complete altera status para `CONCLUIDO`
- [ ] Retorna 403 ao tentar confirmar agendamento de outro usuário
- [ ] Evento `booking.created` é publicado no RabbitMQ ao criar
- [ ] Evento `booking.confirmed` é publicado ao confirmar
- [ ] Evento `booking.cancelled` é publicado ao cancelar
- [ ] Evento `booking.completed` é publicado ao concluir

## Rotas / Endpoints

```
POST   /bookings
GET    /bookings
GET    /bookings/:id
PATCH  /bookings/:id/confirm
PATCH  /bookings/:id/cancel
PATCH  /bookings/:id/complete
DELETE /bookings/:id
```

### Request — Criar agendamento

```json
{
  "petId": "uuid-pet",
  "serviceId": "uuid-service",
  "establishmentId": "uuid-estab",
  "scheduledAt": "2026-04-20T10:00:00Z",
  "notes": "Pet com alergia a perfume"
}
```

### Response 201

```json
{
  "id": "uuid-booking",
  "userId": "uuid-user",
  "petId": "uuid-pet",
  "serviceId": "uuid-service",
  "establishmentId": "uuid-estab",
  "scheduledAt": "2026-04-20T10:00:00Z",
  "status": "PENDENTE",
  "notes": "Pet com alergia a perfume",
  "createdAt": "2026-04-14T12:00:00Z"
}
```

### Evento RabbitMQ — booking.created

```json
{
  "event": "booking.created",
  "data": {
    "bookingId": "uuid-booking",
    "userId": "uuid-user",
    "establishmentId": "uuid-estab",
    "scheduledAt": "2026-04-20T10:00:00Z",
    "status": "PENDENTE"
  }
}
```

## Entidade Booking (PostgreSQL)

```json
{
  "id": "uuid-v4",
  "user_id": "uuid-v4",
  "pet_id": "uuid-v4",
  "service_id": "uuid-v4",
  "establishment_id": "uuid-v4",
  "scheduled_at": "2026-04-20T10:00:00Z",
  "status": "PENDENTE",
  "notes": "string | null",
  "cancel_reason": "string | null",
  "created_at": "2026-04-14T12:00:00Z",
  "updated_at": "2026-04-14T12:00:00Z"
}
```

## Tecnologias

- NestJS + TypeORM + PostgreSQL
- `@nestjs/microservices` + `amqplib` para RabbitMQ
- `class-validator` para validação dos DTOs
- JWT via headers `x-user-id` e `x-user-role` injetados pelo API Gateway

## Erros e Tratamentos

| Situação | HTTP | Mensagem |
|---|---|---|
| Agendamento não encontrado | 404 | Booking not found |
| Tentativa de confirmar sem permissão | 403 | Forbidden |
| Transição de status inválida | 422 | Invalid status transition |
| Data no passado | 400 | Scheduled date must be in the future |
| RabbitMQ indisponível | Log de erro, operação continua | — |

## Integração com outros microserviços

- Emite eventos para **C9 (Notificação)**: `booking.created`, `booking.confirmed`, `booking.cancelled`, `booking.completed`
- Emite evento para **C8 (Avaliação)**: `booking.completed` habilita avaliação do serviço

---

---

# C8 — Microserviço de Avaliação

## Descrição

Microserviço responsável pelo sistema de avaliações de serviços e estabelecimentos. Permite que clientes avaliem com nota (1–5) e comentário após a conclusão de um agendamento. Calcula e expõe a média de avaliações por estabelecimento.

## Requisitos Funcionais

- Criar avaliação vinculada a um agendamento concluído
- Um agendamento só pode ser avaliado uma vez
- Listar avaliações por estabelecimento com paginação
- Calcular média de notas por estabelecimento
- ADMIN pode remover avaliações ofensivas
- Consumir evento `booking.completed` do RabbitMQ para liberar a avaliação

## Requisitos Não Funcionais

- Nota deve ser inteiro entre 1 e 5
- Comentário é opcional, máximo 500 caracteres
- Índice em `establishmentId` para performance de cálculo de média
- Avaliação só pode ser criada pelo dono do agendamento

## Critérios de Aceitação

- [ ] POST /reviews cria avaliação com nota e comentário
- [ ] Retorna 409 se o agendamento já foi avaliado
- [ ] Retorna 403 se o usuário não é o dono do agendamento
- [ ] GET /reviews?establishmentId=X retorna lista paginada
- [ ] GET /reviews/average/:establishmentId retorna média calculada
- [ ] DELETE /reviews/:id retorna 204 (apenas ADMIN)
- [ ] Nota fora do intervalo 1–5 retorna 400

## Rotas / Endpoints

```
POST   /reviews
GET    /reviews?establishmentId=:id&page=1&limit=10
GET    /reviews/:id
GET    /reviews/average/:establishmentId
DELETE /reviews/:id
```

### Request — Criar avaliação

```json
{
  "bookingId": "uuid-booking",
  "establishmentId": "uuid-estab",
  "rating": 5,
  "comment": "Excelente atendimento, voltarei com certeza!"
}
```

### Response 201

```json
{
  "id": "uuid-review",
  "userId": "uuid-user",
  "bookingId": "uuid-booking",
  "establishmentId": "uuid-estab",
  "rating": 5,
  "comment": "Excelente atendimento, voltarei com certeza!",
  "createdAt": "2026-04-14T12:00:00Z"
}
```

### Response — Média

```json
{
  "establishmentId": "uuid-estab",
  "average": 4.6,
  "totalReviews": 23
}
```

### Response — Listagem

```json
{
  "data": [
    {
      "id": "uuid-review",
      "userId": "uuid-user",
      "rating": 5,
      "comment": "Excelente!",
      "createdAt": "2026-04-14T12:00:00Z"
    }
  ],
  "total": 23,
  "page": 1,
  "limit": 10
}
```

## Entidade Review (PostgreSQL)

```json
{
  "id": "uuid-v4",
  "user_id": "uuid-v4",
  "booking_id": "uuid-v4",
  "establishment_id": "uuid-v4",
  "rating": 5,
  "comment": "string | null",
  "created_at": "2026-04-14T12:00:00Z"
}
```

## Tecnologias

- NestJS + TypeORM + PostgreSQL
- `AVG()` via QueryBuilder do TypeORM para cálculo de média
- `@nestjs/microservices` + RabbitMQ para consumir `booking.completed`

## Erros e Tratamentos

| Situação | HTTP | Mensagem |
|---|---|---|
| Agendamento já avaliado | 409 | Booking already reviewed |
| Agendamento não encontrado | 404 | Booking not found |
| Permissão negada | 403 | Forbidden |
| Nota inválida | 400 | Rating must be between 1 and 5 |
| Comentário muito longo | 400 | Comment exceeds 500 characters |

## Integração com outros microserviços

- Consome evento `booking.completed` de **C7 (Agendamento)** para validar que o agendamento foi concluído antes de permitir avaliação
- Emite evento `review.created` para **C9 (Notificação)** alertar o prestador de nova avaliação

---

---

# C9 — Microserviço de Notificação

## Descrição

Microserviço responsável pelo envio e armazenamento de notificações geradas por eventos do sistema. Consome mensagens do RabbitMQ, persiste o registro da notificação no banco e expõe endpoints para que o cliente possa listar e marcar notificações como lidas.

## Requisitos Funcionais

- Consumir eventos de booking e review via RabbitMQ
- Persistir cada notificação com destinatário, tipo e mensagem
- Listar notificações por usuário autenticado
- Marcar notificações como lidas (individualmente ou todas)
- Contagem de notificações não lidas
- Suporte a tipos: `BOOKING_CREATED`, `BOOKING_CONFIRMED`, `BOOKING_CANCELLED`, `BOOKING_COMPLETED`, `REVIEW_RECEIVED`, `COMPLAINT_RESOLVED`

## Requisitos Não Funcionais

- Notificações devem ser persistidas mesmo que o cliente esteja offline
- Processamento assíncrono via fila com ack manual
- Idempotência: o mesmo evento não deve gerar notificação duplicada
- Paginação nas listagens

## Critérios de Aceitação

- [ ] GET /notifications retorna lista paginada do usuário autenticado
- [ ] GET /notifications/unread-count retorna contagem de não lidas
- [ ] PATCH /notifications/:id/read marca uma como lida
- [ ] PATCH /notifications/read-all marca todas como lidas
- [ ] Evento `booking.created` gera notificação para o prestador
- [ ] Evento `booking.confirmed` gera notificação para o cliente
- [ ] Evento `booking.cancelled` gera notificação para ambas as partes
- [ ] Evento `booking.completed` gera notificação para o cliente (solicitando avaliação)
- [ ] Evento `review.created` gera notificação para o prestador
- [ ] Eventos duplicados (mesmo `bookingId` + `event`) não geram duplicata

## Rotas / Endpoints

```
GET    /notifications?page=1&limit=20
GET    /notifications/unread-count
PATCH  /notifications/:id/read
PATCH  /notifications/read-all
DELETE /notifications/:id
```

### Response — Listagem

```json
{
  "data": [
    {
      "id": "uuid-notification",
      "userId": "uuid-user",
      "type": "BOOKING_CONFIRMED",
      "title": "Agendamento Confirmado",
      "message": "Seu agendamento de Banho foi confirmado para 20/04 às 10:00.",
      "read": false,
      "createdAt": "2026-04-14T12:00:00Z"
    }
  ],
  "total": 12,
  "unreadCount": 3,
  "page": 1,
  "limit": 20
}
```

### Response — Contagem não lidas

```json
{
  "unreadCount": 3
}
```

## Mapeamento de Eventos → Notificações

```
booking.created    → destinatário: VENDEDOR  → "Novo agendamento recebido"
booking.confirmed  → destinatário: CLIENTE   → "Agendamento confirmado"
booking.cancelled  → destinatário: AMBOS     → "Agendamento cancelado"
booking.completed  → destinatário: CLIENTE   → "Avalie seu atendimento"
review.created     → destinatário: VENDEDOR  → "Você recebeu uma nova avaliação"
complaint.opened   → destinatário: ADMIN     → "Nova reclamação aberta"
complaint.resolved → destinatário: CLIENTE   → "Sua reclamação foi resolvida"
```

## Entidade Notification (PostgreSQL)

```json
{
  "id": "uuid-v4",
  "user_id": "uuid-v4",
  "type": "BOOKING_CONFIRMED",
  "title": "Agendamento Confirmado",
  "message": "string",
  "read": false,
  "source_event_id": "uuid-booking",
  "created_at": "2026-04-14T12:00:00Z"
}
```

## Tecnologias

- NestJS + TypeORM + PostgreSQL
- `@nestjs/microservices` + RabbitMQ (consumer)
- Estratégia de idempotência por `source_event_id` + `type`

## Erros e Tratamentos

| Situação | Tratamento |
|---|---|
| Evento com formato inválido | Log de erro, `nack` sem requeue |
| Notificação duplicada | Ignorada via constraint unique |
| Notificação não encontrada | 404 |
| Usuário sem permissão | 403 |

## Integração com outros microserviços

- Consome eventos de **C7 (Agendamento)**: `booking.created`, `booking.confirmed`, `booking.cancelled`, `booking.completed`
- Consome eventos de **C8 (Avaliação)**: `review.created`
- Consome eventos de **C10 (Reclamação)**: `complaint.opened`, `complaint.resolved`

---

---

# C10 — Microserviço de Reclamação

## Descrição

Microserviço responsável pelo fluxo completo de reclamações dentro da plataforma. Clientes podem abrir reclamações sobre serviços ou agendamentos. Prestadores podem responder. Administradores têm visão global e podem moderar (resolver, arquivar ou remover).

## Requisitos Funcionais

- Cliente abre reclamação vinculada a um agendamento ou estabelecimento
- Prestador pode adicionar resposta à reclamação
- ADMIN pode alterar status para `RESPONDIDA`, `ARQUIVADA` ou `REMOVIDA`
- Listar reclamações por usuário (cliente vê as suas; VENDEDOR vê as do seu estabelecimento; ADMIN vê todas)
- Filtros por status e por estabelecimento
- Emitir evento `complaint.opened` ao criar e `complaint.resolved` ao resolver

## Requisitos Não Funcionais

- Status válidos: `PENDENTE`, `RESPONDIDA`, `ARQUIVADA`, `REMOVIDA`
- Apenas o autor pode editar a reclamação enquanto está `PENDENTE`
- ADMIN pode alterar qualquer reclamação
- Paginação obrigatória nas listagens

## Critérios de Aceitação

- [ ] POST /complaints cria reclamação com status `PENDENTE`
- [ ] GET /complaints retorna lista filtrada pelo role do usuário
- [ ] GET /complaints/:id retorna detalhes da reclamação
- [ ] PATCH /complaints/:id/respond permite que VENDEDOR adicione resposta
- [ ] PATCH /complaints/:id/resolve permite que ADMIN mude status para `RESPONDIDA`
- [ ] PATCH /complaints/:id/archive permite que ADMIN arquive
- [ ] DELETE /complaints/:id permite que ADMIN remova (soft delete)
- [ ] Evento `complaint.opened` é publicado ao criar
- [ ] Evento `complaint.resolved` é publicado ao resolver
- [ ] CLIENTE não pode ver reclamações de outros usuários

## Rotas / Endpoints

```
POST   /complaints
GET    /complaints?status=PENDENTE&establishmentId=:id&page=1
GET    /complaints/:id
PATCH  /complaints/:id/respond
PATCH  /complaints/:id/resolve
PATCH  /complaints/:id/archive
DELETE /complaints/:id
```

### Request — Abrir reclamação

```json
{
  "establishmentId": "uuid-estab",
  "bookingId": "uuid-booking",
  "subject": "Atraso no atendimento",
  "description": "Aguardei mais de 1 hora além do horário marcado sem nenhuma comunicação."
}
```

### Response 201

```json
{
  "id": "uuid-complaint",
  "userId": "uuid-user",
  "establishmentId": "uuid-estab",
  "bookingId": "uuid-booking",
  "subject": "Atraso no atendimento",
  "description": "Aguardei mais de 1 hora...",
  "status": "PENDENTE",
  "response": null,
  "createdAt": "2026-04-14T12:00:00Z"
}
```

### Request — Responder reclamação (VENDEDOR)

```json
{
  "response": "Pedimos desculpas pelo ocorrido. Tivemos um imprevisto naquele dia e já tomamos medidas para evitar que aconteça novamente."
}
```

### Response — Listagem (ADMIN)

```json
{
  "data": [
    {
      "id": "uuid-complaint",
      "userId": "uuid-user",
      "establishmentId": "uuid-estab",
      "subject": "Atraso no atendimento",
      "status": "PENDENTE",
      "createdAt": "2026-04-14T12:00:00Z"
    }
  ],
  "total": 5,
  "page": 1,
  "limit": 10
}
```

### Evento RabbitMQ — complaint.opened

```json
{
  "event": "complaint.opened",
  "data": {
    "complaintId": "uuid-complaint",
    "userId": "uuid-user",
    "establishmentId": "uuid-estab",
    "subject": "Atraso no atendimento"
  }
}
```

## Entidade Complaint (PostgreSQL)

```json
{
  "id": "uuid-v4",
  "user_id": "uuid-v4",
  "establishment_id": "uuid-v4",
  "booking_id": "uuid-v4 | null",
  "subject": "string",
  "description": "string",
  "status": "PENDENTE",
  "response": "string | null",
  "deleted_at": "timestamp | null",
  "created_at": "2026-04-14T12:00:00Z",
  "updated_at": "2026-04-14T12:00:00Z"
}
```

## Tecnologias

- NestJS + TypeORM + PostgreSQL
- `@nestjs/microservices` + RabbitMQ para emissão de eventos
- Soft delete via coluna `deleted_at`
- Filtros dinâmicos via `QueryBuilder`

## Erros e Tratamentos

| Situação | HTTP | Mensagem |
|---|---|---|
| Reclamação não encontrada | 404 | Complaint not found |
| Permissão negada | 403 | Forbidden |
| Reclamação já respondida | 409 | Complaint already has a response |
| Reclamação arquivada ou removida | 410 | Complaint no longer active |
| Campos obrigatórios ausentes | 400 | Validation failed |

## Integração com outros microserviços

- Emite `complaint.opened` e `complaint.resolved` para **C9 (Notificação)**
- Referencia agendamentos de **C7 (Agendamento)** via `bookingId`
- O API Gateway roteia `/complaints` para este serviço na porta `3007`

---

---

## Sumário de Portas e Rotas

| Serviço | Porta | Prefixo de rota |
|---|---|---|
| API Gateway | 3000 | / |
| Auth Service | 3001 | /auth |
| User & Pet Service | 3002 | /users, /pets |
| Establishment Service | 3003 | /establishments |
| Marketplace Service | 3004 | /marketplace |
| Booking Service | 3005 | /bookings |
| Notification Service | 3006 | /notifications |
| Review & Complaint Service | 3007 | /reviews, /complaints |

---

## Regras de Autorização por Role

| Ação | CLIENTE | VENDEDOR | ADMIN |
|---|---|---|---|
| Criar agendamento | ✓ | — | ✓ |
| Confirmar agendamento | — | ✓ | ✓ |
| Avaliar serviço | ✓ | — | — |
| Remover avaliação | — | — | ✓ |
| Abrir reclamação | ✓ | — | — |
| Responder reclamação | — | ✓ | ✓ |
| Resolver/arquivar reclamação | — | — | ✓ |
| Ver todas as reclamações | — | — | ✓ |
| Gerenciar estabelecimentos | — | ✓ (próprio) | ✓ |

---

## Variáveis de Ambiente (por serviço)

```
DATABASE_URL=postgresql://postgres:root@localhost:5432/mypet
JWT_SECRET=mypet_super_secret_change_in_production
RABBITMQ_URL=amqp://mypet:mypet123@localhost:5672
CONSUL_HOST=localhost
CONSUL_PORT=8500
PORT=300X
```
