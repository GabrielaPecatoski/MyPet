# MyPet — Guia de Desenvolvimento e Deploy com Docker

> Cada microserviço roda em um container Docker próprio e é implantado em um servidor dedicado.  
> Stack: **NestJS · TypeScript · PostgreSQL · RabbitMQ · JWT**

---

## Índice

1. [Visão geral da infraestrutura](#1-visão-geral-da-infraestrutura)
2. [Pré-requisitos](#2-pré-requisitos)
3. [Estrutura de pastas do repositório](#3-estrutura-de-pastas-do-repositório)
4. [Estrutura interna de cada microserviço](#4-estrutura-interna-de-cada-microserviço)
5. [Dockerfile padrão](#5-dockerfile-padrão)
6. [Variáveis de ambiente por serviço](#6-variáveis-de-ambiente-por-serviço)
7. [Docker Compose — ambiente local de desenvolvimento](#7-docker-compose--ambiente-local-de-desenvolvimento)
8. [Deploy em servidores separados](#8-deploy-em-servidores-separados)
9. [Mensageria com RabbitMQ](#9-mensageria-com-rabbitmq)
10. [Comunicação entre serviços](#10-comunicação-entre-serviços)
11. [Ordem de inicialização](#11-ordem-de-inicialização)
12. [Checklist de go-live](#12-checklist-de-go-live)

---

## 1. Visão geral da infraestrutura

```
┌─────────────────────────────────────────────────────────────────┐
│  App Mobile (React Native)                                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS
                    ┌──────▼──────┐
                    │ API Gateway │  (nginx ou AWS API GW)
                    └──────┬──────┘
          ┌────────────────┼────────────────────────┐
          │                │                        │
   ┌──────▼──────┐  ┌──────▼───────┐  ┌────────────▼──────────┐
   │  Servidor 1 │  │  Servidor 2  │  │      Servidor 3        │
   │  identity   │  │     pets     │  │   establishments       │
   │   :3001     │  │    :3002     │  │        :3003           │
   │  PostgreSQL │  │  PostgreSQL  │  │     PostgreSQL         │
   └─────────────┘  └──────────────┘  └───────────────────────┘

   ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
   │  Servidor 4  │  │  Servidor 5  │  │     Servidor 6        │
   │  scheduling  │  │notifications │  │      reviews          │
   │    :3004     │  │    :3005     │  │       :3006           │
   │  PostgreSQL  │  │      —       │  │    PostgreSQL         │
   └──────────────┘  └──────────────┘  └──────────────────────┘

   ┌─────────────────────────────────────┐
   │  Servidor de Mensageria             │
   │  RabbitMQ  :5672 (AMQP)            │
   │            :15672 (painel web)      │
   └─────────────────────────────────────┘
```

| Serviço | Servidor | Porta | Banco |
|---|---|---|---|
| `identity-service` | Servidor 1 | 3001 | PostgreSQL |
| `pets-service` | Servidor 2 | 3002 | PostgreSQL |
| `establishments-service` | Servidor 3 | 3003 | PostgreSQL |
| `scheduling-service` | Servidor 4 | 3004 | PostgreSQL |
| `notifications-service` | Servidor 5 | 3005 | — |
| `reviews-service` | Servidor 6 | 3006 | PostgreSQL |
| `rabbitmq` | Servidor 7 | 5672 / 15672 | — |

---

## 2. Pré-requisitos

### Máquina local (desenvolvimento)

| Ferramenta | Versão mínima |
|---|---|
| Node.js | 20.x LTS |
| npm | 10.x |
| Docker Desktop | 24.x |
| Docker Compose | 2.x (embutido no Desktop) |
| NestJS CLI | `npm i -g @nestjs/cli` |

### Cada servidor de produção (VPS/VM)

| Ferramenta | Como instalar |
|---|---|
| Docker Engine | `curl -fsSL https://get.docker.com \| sh` |
| Docker Compose plugin | incluso no Docker Engine moderno |
| Git | `apt install git` |

---

## 3. Estrutura de repositórios

O projeto passa por duas fases com estratégias diferentes:

### Fase 1 — Desenvolvimento (monorepo)

Um único repositório Git com todos os microserviços em subdiretórios. Facilita rodar tudo junto localmente e manter consistência durante o desenvolvimento.

```
mypet/                           ← repositório de desenvolvimento
├── identity-service/
│   ├── Dockerfile
│   ├── docker-compose.yml       ← sobe só este serviço + seu banco
│   └── src/
├── pets-service/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
├── establishments-service/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
├── scheduling-service/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
├── notifications-service/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
├── reviews-service/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
└── docker-compose.yml           ← sobe tudo junto localmente
```

### Fase 2 — Deploy (repositório por serviço)

Quando o serviço estiver pronto para ir ao ar, o conteúdo do subdiretório é extraído para um repositório próprio. Cada servidor aponta para o seu repositório.

```
mypet-identity-service/        → Servidor 1
mypet-pets-service/            → Servidor 2
mypet-establishments-service/  → Servidor 3
mypet-scheduling-service/      → Servidor 4
mypet-notifications-service/   → Servidor 5
mypet-reviews-service/         → Servidor 6
```

**Como extrair um serviço do monorepo para repositório próprio:**
```bash
# Exemplo: extraindo o scheduling-service
git subtree split --prefix=scheduling-service -b branch-scheduling

# Criar o novo repo e fazer o push
git init ../mypet-scheduling-service
cd ../mypet-scheduling-service
git pull ../mypet branch-scheduling
git remote add origin <url-do-novo-repo>
git push -u origin main
```

---

Criação inicial de cada projeto NestJS (rodar na raiz do monorepo):

```bash
nest new identity-service       --strict --package-manager npm
nest new pets-service           --strict --package-manager npm
nest new establishments-service --strict --package-manager npm
nest new scheduling-service     --strict --package-manager npm
nest new notifications-service  --strict --package-manager npm
nest new reviews-service        --strict --package-manager npm
```

---

## 4. Estrutura interna de cada microserviço

Todos os serviços seguem a **Onion Architecture** (domínio no centro, infraestrutura nas bordas).

```
<nome>-service/
├── src/
│   ├── <contexto>/
│   │   ├── <contexto>.module.ts
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── value-objects/
│   │   │   ├── repositories/        ← interfaces (ports)
│   │   │   └── services/            ← domain services
│   │   ├── application/
│   │   │   └── use-cases/
│   │   ├── infrastructure/
│   │   │   ├── repositories/        ← implementações TypeORM
│   │   │   └── messaging/           ← publishers / consumers RabbitMQ
│   │   └── interface/
│   │       ├── controllers/
│   │       └── dtos/
│   ├── app.module.ts
│   └── main.ts
├── .env.example
├── Dockerfile
├── docker-compose.yml               ← sobe só este serviço + seu banco
└── package.json
```

Dependências comuns a instalar em cada serviço:

```bash
npm install @nestjs/config @nestjs/typeorm typeorm pg
npm install @nestjs/jwt @nestjs/passport passport passport-jwt
npm install @nestjs/swagger swagger-ui-express
npm install @nestjs/microservices amqplib amqp-connection-manager
npm install class-validator class-transformer
npm install --save-dev @types/passport-jwt
```

---

## 5. Dockerfile padrão

O mesmo `Dockerfile` serve para todos os microserviços. Copie e cole na raiz de cada um.

```dockerfile
# ── Estágio 1: build ───────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ── Estágio 2: imagem final (menor) ───────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main"]
```

> A porta interna é sempre `3000`. A porta pública de cada serviço é mapeada no `docker-compose.yml` ou nas configurações do servidor.

### `.dockerignore`

```
node_modules
dist
.env
*.log
```

---

## 6. Variáveis de ambiente por serviço

Cada serviço tem seu próprio arquivo `.env`. Nunca suba esses arquivos para o Git — use `.env.example` versionado.

### `identity-service/.env`

```env
PORT=3001
NODE_ENV=production

# Banco de dados próprio do serviço
DB_HOST=localhost
DB_PORT=5432
DB_NAME=identity_db
DB_USER=identity_user
DB_PASS=senha_segura

# JWT (segredo compartilhado entre todos os serviços para validação)
JWT_SECRET=chave_secreta_longa_e_aleatoria
JWT_EXPIRES_IN=7d
```

### `pets-service/.env`

```env
PORT=3002
NODE_ENV=production

DB_HOST=localhost
DB_PORT=5432
DB_NAME=pets_db
DB_USER=pets_user
DB_PASS=senha_segura

# URL do identity-service para validação de token
IDENTITY_SERVICE_URL=http://<ip-servidor-1>:3001

JWT_SECRET=chave_secreta_longa_e_aleatoria
```

### `establishments-service/.env`

```env
PORT=3003
NODE_ENV=production

DB_HOST=localhost
DB_PORT=5432
DB_NAME=establishments_db
DB_USER=establishments_user
DB_PASS=senha_segura

IDENTITY_SERVICE_URL=http://<ip-servidor-1>:3001

JWT_SECRET=chave_secreta_longa_e_aleatoria
```

### `scheduling-service/.env`

```env
PORT=3004
NODE_ENV=production

DB_HOST=localhost
DB_PORT=5432
DB_NAME=scheduling_db
DB_USER=scheduling_user
DB_PASS=senha_segura

# Serviços consultados de forma síncrona
IDENTITY_SERVICE_URL=http://<ip-servidor-1>:3001
PETS_SERVICE_URL=http://<ip-servidor-2>:3002
ESTABLISHMENTS_SERVICE_URL=http://<ip-servidor-3>:3003

# Mensageria (publica eventos)
RABBITMQ_URL=amqp://admin:senha@<ip-servidor-rabbitmq>:5672

JWT_SECRET=chave_secreta_longa_e_aleatoria
```

### `notifications-service/.env`

```env
PORT=3005
NODE_ENV=production

# Só consome eventos, sem banco próprio
RABBITMQ_URL=amqp://admin:senha@<ip-servidor-rabbitmq>:5672

# Credenciais para envio de e-mail (ex: SendGrid, SMTP)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=sua_api_key
```

### `reviews-service/.env`

```env
PORT=3006
NODE_ENV=production

DB_HOST=localhost
DB_PORT=5432
DB_NAME=reviews_db
DB_USER=reviews_user
DB_PASS=senha_segura

RABBITMQ_URL=amqp://admin:senha@<ip-servidor-rabbitmq>:5672

IDENTITY_SERVICE_URL=http://<ip-servidor-1>:3001

JWT_SECRET=chave_secreta_longa_e_aleatoria
```

---

## 7. Docker Compose — ambiente local de desenvolvimento

O arquivo na raiz do monorepo sobe todos os serviços e seus bancos de uma vez para o desenvolvimento local.

```yaml
# docker-compose.yml (raiz do monorepo)
version: "3.9"

services:

  # ── Mensageria ──────────────────────────────────────────────
  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    container_name: mypet-rabbitmq
    ports:
      - "5672:5672"    # AMQP (conexão dos serviços)
      - "15672:15672"  # Painel web de administração
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ── identity-service ────────────────────────────────────────
  identity-db:
    image: postgres:16-alpine
    container_name: identity-db
    environment:
      POSTGRES_DB: identity_db
      POSTGRES_USER: identity_user
      POSTGRES_PASSWORD: senha_dev
    volumes:
      - identity-db-data:/var/lib/postgresql/data

  identity-service:
    build: ./identity-service
    container_name: identity-service
    ports:
      - "3001:3000"
    env_file: ./identity-service/.env
    environment:
      DB_HOST: identity-db
    depends_on:
      identity-db:
        condition: service_started

  # ── pets-service ─────────────────────────────────────────────
  pets-db:
    image: postgres:16-alpine
    container_name: pets-db
    environment:
      POSTGRES_DB: pets_db
      POSTGRES_USER: pets_user
      POSTGRES_PASSWORD: senha_dev
    volumes:
      - pets-db-data:/var/lib/postgresql/data

  pets-service:
    build: ./pets-service
    container_name: pets-service
    ports:
      - "3002:3000"
    env_file: ./pets-service/.env
    environment:
      DB_HOST: pets-db
      IDENTITY_SERVICE_URL: http://identity-service:3000
    depends_on:
      - pets-db
      - identity-service

  # ── establishments-service ───────────────────────────────────
  establishments-db:
    image: postgres:16-alpine
    container_name: establishments-db
    environment:
      POSTGRES_DB: establishments_db
      POSTGRES_USER: establishments_user
      POSTGRES_PASSWORD: senha_dev
    volumes:
      - establishments-db-data:/var/lib/postgresql/data

  establishments-service:
    build: ./establishments-service
    container_name: establishments-service
    ports:
      - "3003:3000"
    env_file: ./establishments-service/.env
    environment:
      DB_HOST: establishments-db
      IDENTITY_SERVICE_URL: http://identity-service:3000
    depends_on:
      - establishments-db
      - identity-service

  # ── scheduling-service ───────────────────────────────────────
  scheduling-db:
    image: postgres:16-alpine
    container_name: scheduling-db
    environment:
      POSTGRES_DB: scheduling_db
      POSTGRES_USER: scheduling_user
      POSTGRES_PASSWORD: senha_dev
    volumes:
      - scheduling-db-data:/var/lib/postgresql/data

  scheduling-service:
    build: ./scheduling-service
    container_name: scheduling-service
    ports:
      - "3004:3000"
    env_file: ./scheduling-service/.env
    environment:
      DB_HOST: scheduling-db
      IDENTITY_SERVICE_URL: http://identity-service:3000
      PETS_SERVICE_URL: http://pets-service:3000
      ESTABLISHMENTS_SERVICE_URL: http://establishments-service:3000
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    depends_on:
      rabbitmq:
        condition: service_healthy
      scheduling-db:
        condition: service_started
      identity-service:
        condition: service_started
      pets-service:
        condition: service_started
      establishments-service:
        condition: service_started

  # ── notifications-service ────────────────────────────────────
  notifications-service:
    build: ./notifications-service
    container_name: notifications-service
    ports:
      - "3005:3000"
    env_file: ./notifications-service/.env
    environment:
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    depends_on:
      rabbitmq:
        condition: service_healthy

  # ── reviews-service ──────────────────────────────────────────
  reviews-db:
    image: postgres:16-alpine
    container_name: reviews-db
    environment:
      POSTGRES_DB: reviews_db
      POSTGRES_USER: reviews_user
      POSTGRES_PASSWORD: senha_dev
    volumes:
      - reviews-db-data:/var/lib/postgresql/data

  reviews-service:
    build: ./reviews-service
    container_name: reviews-service
    ports:
      - "3006:3000"
    env_file: ./reviews-service/.env
    environment:
      DB_HOST: reviews-db
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
      IDENTITY_SERVICE_URL: http://identity-service:3000
    depends_on:
      rabbitmq:
        condition: service_healthy
      reviews-db:
        condition: service_started

volumes:
  identity-db-data:
  pets-db-data:
  establishments-db-data:
  scheduling-db-data:
  reviews-db-data:
```

### Comandos do ambiente local

```bash
# Subir tudo (primeira vez faz o build das imagens)
docker compose up --build

# Subir em segundo plano
docker compose up -d

# Ver logs de um serviço específico
docker compose logs -f scheduling-service

# Parar tudo sem apagar os volumes (banco mantido)
docker compose stop

# Parar e apagar tudo (banco zerado)
docker compose down -v

# Recompilar só um serviço após mudança de código
docker compose up --build scheduling-service
```

---

## 8. Deploy em servidores separados

Cada servidor segue exatamente os mesmos passos. As diferenças estão só nas variáveis de ambiente.

### 8.1 Preparar o servidor (executar uma vez em cada VM)

```bash
# 1. Atualizar o sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 3. Verificar instalação
docker --version
docker compose version
```

### 8.2 Estrutura de arquivos no servidor

Em cada servidor, crie a seguinte estrutura mínima:

```
/opt/mypet/
├── docker-compose.yml   ← específico deste servidor
└── .env                 ← variáveis de produção
```

### 8.3 `docker-compose.yml` por servidor

Cada servidor tem um arquivo `docker-compose.yml` que sobe apenas **um serviço + seu banco**.

#### Servidor 1 — `identity-service`

```yaml
version: "3.9"

services:
  identity-db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: identity_db
      POSTGRES_USER: identity_user
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes:
      - identity-db-data:/var/lib/postgresql/data

  identity-service:
    image: ghcr.io/seu-usuario/mypet-identity-service:latest
    restart: always
    ports:
      - "3001:3000"
    env_file: .env
    environment:
      DB_HOST: identity-db
    depends_on:
      - identity-db

volumes:
  identity-db-data:
```

#### Servidor 2 — `pets-service`

```yaml
version: "3.9"

services:
  pets-db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: pets_db
      POSTGRES_USER: pets_user
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes:
      - pets-db-data:/var/lib/postgresql/data

  pets-service:
    image: ghcr.io/seu-usuario/mypet-pets-service:latest
    restart: always
    ports:
      - "3002:3000"
    env_file: .env
    environment:
      DB_HOST: pets-db
    depends_on:
      - pets-db

volumes:
  pets-db-data:
```

#### Servidor 3 — `establishments-service`

```yaml
version: "3.9"

services:
  establishments-db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: establishments_db
      POSTGRES_USER: establishments_user
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes:
      - establishments-db-data:/var/lib/postgresql/data

  establishments-service:
    image: ghcr.io/seu-usuario/mypet-establishments-service:latest
    restart: always
    ports:
      - "3003:3000"
    env_file: .env
    environment:
      DB_HOST: establishments-db
    depends_on:
      - establishments-db

volumes:
  establishments-db-data:
```

#### Servidor 4 — `scheduling-service`

```yaml
version: "3.9"

services:
  scheduling-db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: scheduling_db
      POSTGRES_USER: scheduling_user
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes:
      - scheduling-db-data:/var/lib/postgresql/data

  scheduling-service:
    image: ghcr.io/seu-usuario/mypet-scheduling-service:latest
    restart: always
    ports:
      - "3004:3000"
    env_file: .env
    environment:
      DB_HOST: scheduling-db
    depends_on:
      - scheduling-db

volumes:
  scheduling-db-data:
```

#### Servidor 5 — `notifications-service`

```yaml
version: "3.9"

services:
  notifications-service:
    image: ghcr.io/seu-usuario/mypet-notifications-service:latest
    restart: always
    ports:
      - "3005:3000"
    env_file: .env
```

#### Servidor 6 — `reviews-service`

```yaml
version: "3.9"

services:
  reviews-db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: reviews_db
      POSTGRES_USER: reviews_user
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes:
      - reviews-db-data:/var/lib/postgresql/data

  reviews-service:
    image: ghcr.io/seu-usuario/mypet-reviews-service:latest
    restart: always
    ports:
      - "3006:3000"
    env_file: .env
    environment:
      DB_HOST: reviews-db
    depends_on:
      - reviews-db

volumes:
  reviews-db-data:
```

#### Servidor 7 — `rabbitmq`

```yaml
version: "3.9"

services:
  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    restart: always
    ports:
      - "5672:5672"    # conexão AMQP dos microserviços
      - "15672:15672"  # painel web (proteger com firewall em produção)
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASS}
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq

volumes:
  rabbitmq-data:
```

### 8.4 Deploy em cada servidor

Na fase de deploy, cada servidor clona o repositório próprio do seu microserviço (extraído do monorepo conforme a seção 3).

```bash
# No servidor — primeira vez
git clone <url-do-repo-do-servico> /opt/mypet
cd /opt/mypet

# Criar o .env com as variáveis de produção deste servidor
cp .env.example .env
nano .env   # preencher os valores reais

# Construir e subir
docker compose up -d --build

# Verificar se está saudável
docker compose ps
docker compose logs -f
```

### 8.5 Atualizar um serviço em produção

```bash
cd /opt/mypet

# Baixar as últimas alterações do repositório do serviço
git pull

# Reconstruir e restartar
docker compose up -d --build
```

---

## 9. Mensageria com RabbitMQ

O `scheduling-service` publica eventos. Os serviços `notifications-service` e `reviews-service` os consomem.

### Exchanges e filas

| Exchange | Tipo | Fila | Consumidor |
|---|---|---|---|
| `appointment.events` | `topic` | `notifications.appointment` | `notifications-service` |
| `appointment.events` | `topic` | `reviews.appointment.completed` | `reviews-service` |

### Routing keys dos eventos

| Evento de Domínio | Routing Key |
|---|---|
| `AppointmentCreated` | `appointment.created` |
| `AppointmentConfirmed` | `appointment.confirmed` |
| `AppointmentRejected` | `appointment.rejected` |
| `AppointmentCompleted` | `appointment.completed` |

### Configuração no `scheduling-service` (NestJS)

```typescript
// scheduling-service/src/app.module.ts
import { ClientsModule, Transport } from '@nestjs/microservices';

ClientsModule.register([
  {
    name: 'RABBITMQ_CLIENT',
    transport: Transport.RMQ,
    options: {
      urls: [process.env.RABBITMQ_URL],
      exchange: 'appointment.events',
      exchangeType: 'topic',
      noAck: false,
    },
  },
])
```

### Configuração no `notifications-service` (NestJS)

```typescript
// notifications-service/src/main.ts
import { NestFactory } from '@nestjs/core';
import { Transport } from '@nestjs/microservices';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice(AppModule, {
    transport: Transport.RMQ,
    options: {
      urls: [process.env.RABBITMQ_URL],
      queue: 'notifications.appointment',
      queueOptions: { durable: true },
      noAck: false,
    },
  });
  await app.listen();
}
bootstrap();
```

---

## 10. Comunicação entre serviços

### Chamadas síncronas (REST)

Serviços que precisam de dados em tempo real usam HTTP. Recomenda-se usar `@nestjs/axios` com retry e timeout configurados.

```typescript
// Exemplo: scheduling-service consultando pets-service
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

const pet = await firstValueFrom(
  this.httpService.get(`${process.env.PETS_SERVICE_URL}/pets/${petId}`, {
    headers: { Authorization: `Bearer ${token}` },
    timeout: 3000,
  })
);
```

### Fluxo de autenticação entre serviços

Todos os serviços validam o JWT do usuário localmente (sem chamar o `identity-service` em cada requisição), pois compartilham o mesmo `JWT_SECRET`.

```typescript
// Qualquer serviço — validação local do JWT
import { JwtModule } from '@nestjs/jwt';

JwtModule.register({
  secret: process.env.JWT_SECRET,
  signOptions: { expiresIn: process.env.JWT_EXPIRES_IN },
})
```

O `identity-service` é consultado diretamente apenas quando é necessário buscar dados do perfil do usuário (nome, telefone etc.), não para validar tokens.

---

## 11. Ordem de inicialização

Ao subir o ambiente pela primeira vez, respeite esta sequência para evitar erros de dependência:

```
1. Servidor 7: rabbitmq              ← mensageria precisa estar up antes dos consumidores
2. Servidor 1: identity-service      ← todos os outros dependem de autenticação
3. Servidor 2: pets-service
4. Servidor 3: establishments-service
5. Servidor 4: scheduling-service    ← depende de pets + establishments + rabbitmq
6. Servidor 5: notifications-service ← depende só do rabbitmq
7. Servidor 6: reviews-service       ← depende do rabbitmq
```

No ambiente local com Docker Compose, a ordem é gerenciada automaticamente pelo `depends_on`.

---

## 12. Checklist de go-live

Antes de colocar em produção, verifique cada item:

**Segurança**
- [ ] Senhas do banco de dados são fortes e únicas por serviço
- [ ] `JWT_SECRET` é longo (mínimo 32 caracteres) e igual em todos os serviços
- [ ] Porta `15672` do RabbitMQ está bloqueada no firewall externo (acesso só interno)
- [ ] Bancos de dados não expõem a porta `5432` externamente
- [ ] HTTPS configurado no API Gateway

**Infraestrutura**
- [ ] `restart: always` nos containers de produção
- [ ] Volumes nomeados para persistência do banco e do RabbitMQ
- [ ] Imagens publicadas no registry com tag versionada (não apenas `latest`)

**Operação**
- [ ] Logs acessíveis via `docker compose logs`
- [ ] Migrations do banco executadas antes de subir o serviço
- [ ] Variáveis de ambiente conferidas em cada servidor
- [ ] Healthcheck funcionando em todos os containers

**Comunicação**
- [ ] IPs ou hostnames dos servidores configurados corretamente nas variáveis `*_SERVICE_URL` e `RABBITMQ_URL`
- [ ] Firewall libera as portas `3001–3006` e `5672` entre os servidores internamente
