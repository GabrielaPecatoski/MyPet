# MyPet — Documentação DDD para Microserviços

> **Sistema:** MyPet  
> **Versão:** 1.0  
> **Base:** Levantamento de Requisitos v1.0 (09/03/2026) + Aulas 02–05 Prof. Guilherme Alves

---

## 1. Visão Geral do Domínio

**Domínio:** Plataforma digital de agendamento de serviços para pets.

O MyPet resolve o problema de conectar **donos de pets** a **estabelecimentos** (pet shops e clínicas veterinárias), permitindo visualizar serviços, horários disponíveis e realizar agendamentos de forma prática.

> "Domínio = o problema que o software resolve." — Prof. Guilherme Alves

---

## 2. Classificação dos Subdomínios

| Subdomínio | Tipo | Justificativa |
|---|---|---|
| **Agendamento** | Core Domain | Diferencial competitivo. É a razão de existir do MyPet. Alta complexidade de negócio. |
| **Estabelecimentos** | Supporting Domain | Específico da empresa. Gerencia os dados dos parceiros (pet shops e clínicas). |
| **Pets** | Supporting Domain | Específico da empresa. Gerencia os dados dos animais dos usuários. |
| **Avaliações** | Supporting Domain | Apoia o core com informações de qualidade dos estabelecimentos. |
| **Identidade** | Generic Domain | Cadastro e autenticação de usuários. Solução comum ao mercado. |
| **Notificações** | Generic Domain | Envio de confirmações e lembretes. Solução terceirizável. |

---

## 3. Linguagem Ubíqua (Ubiquitous Language)

A linguagem abaixo deve ser usada igualmente nas conversas de negócio e no código-fonte.

| Termo do Negócio | Termo no Código | Descrição |
|---|---|---|
| Dono de Pet | `PetOwner` | Usuário que cadastra pets e realiza agendamentos |
| Estabelecimento | `Establishment` | Pet shop ou clínica veterinária cadastrada |
| Pet / Animal de Estimação | `Pet` | Animal vinculado a um `PetOwner` |
| Serviço | `Service` | Serviço oferecido pelo estabelecimento (banho, tosa, consulta) |
| Horário Disponível | `AvailableSlot` | Horário que o estabelecimento disponibiliza para agendamento |
| Agendamento | `Appointment` | Vínculo entre `PetOwner`, `Pet`, `Service` e `AvailableSlot` |
| Confirmação | `Confirmation` | Aceite do agendamento pelo estabelecimento |
| Recusa | `Rejection` | Recusa do agendamento com justificativa |
| Lembrete | `Reminder` | Notificação enviada ao usuário antes do agendamento |
| Veterinário | `Veterinarian` | Profissional vinculado a uma clínica veterinária |
| Histórico de Serviços | `ServiceHistory` | Registro de agendamentos realizados para um pet |
| Avaliação | `Review` | Opinião de um `PetOwner` sobre um `Establishment` |

---

## 4. Bounded Contexts

### 4.1 Identidade (`identity`) — Generic

**Conceitos:**
- Dono de Pet (`PetOwner`)
- Credenciais (`Credentials`)
- Perfil do usuário (`UserProfile`)

**Responsabilidades:**
- Cadastrar dono de pet (RF01)
- Autenticar usuário
- Editar informações pessoais (RF16)

**Glossário local:**

| Termo | Descrição |
|---|---|
| `PetOwner` | Entidade principal. Possui `id`, `name`, `email`, `phone` |
| `Credentials` | Value Object com `email` e senha hasheada |
| `UserProfile` | Value Object com dados editáveis: `name`, `phone` |

---

### 4.2 Pets (`pets`) — Supporting

**Conceitos:**
- Pet (`Pet`)
- Raça (`Breed`)
- Histórico de Serviços (`ServiceHistory`)

**Responsabilidades:**
- Cadastrar pet com nome, raça e idade (RF03)
- Editar informações do pet (RF16)
- Visualizar histórico de serviços do pet (RF10)

**Glossário local:**

| Termo | Descrição |
|---|---|
| `Pet` | Entidade. Possui `id`, `name`, `breed`, `age`, `ownerId` |
| `Breed` | Value Object. Raça do animal |
| `ServiceHistory` | Entidade. Lista de agendamentos concluídos vinculados ao pet |

---

### 4.3 Estabelecimentos (`establishments`) — Supporting

**Conceitos:**
- Estabelecimento (`Establishment`)
- Serviço oferecido (`OfferedService`)
- Horário disponível (`AvailableSlot`)
- Veterinário (`Veterinarian`)

**Responsabilidades:**
- Cadastrar e gerenciar estabelecimentos (RF04, RF14)
- Cadastrar serviços oferecidos com preços (RF11, RF13, RF15)
- Gerenciar horários disponíveis (RF06)
- Cadastrar veterinários disponíveis (RF12)
- Pesquisar estabelecimentos (RF14)

**Glossário local:**

| Termo | Descrição |
|---|---|
| `Establishment` | Entidade raiz. Possui `id`, `name`, `type` (PetShop / VetClinic), `address`, `phone` |
| `EstablishmentType` | Value Object: `PET_SHOP` ou `VET_CLINIC` |
| `OfferedService` | Entidade. Serviço oferecido: `id`, `name`, `price`, `duration` |
| `AvailableSlot` | Entidade. Horário disponível: `id`, `date`, `startTime`, `endTime`, `serviceId` |
| `Veterinarian` | Entidade. Profissional: `id`, `name`, `specialty`, `crmv` |
| `Price` | Value Object imutável com `amount` e `currency` |

---

### 4.4 Agendamento (`scheduling`) — **Core Domain**

**Conceitos:**
- Agendamento (`Appointment`)
- Status do Agendamento (`AppointmentStatus`)
- Horário Reservado (`BookedSlot`)

**Responsabilidades:**
- Agendar serviço para um pet (RF02)
- Confirmar ou recusar agendamento pelo estabelecimento (RF09)
- Consultar horários disponíveis
- Cancelar agendamento

**Glossário local:**

| Termo | Descrição |
|---|---|
| `Appointment` | Aggregate Root. `id`, `petOwnerId`, `petId`, `establishmentId`, `serviceId`, `slotId`, `status` |
| `AppointmentStatus` | Value Object: `PENDING`, `CONFIRMED`, `REJECTED`, `CANCELLED`, `COMPLETED` |
| `BookedSlot` | Value Object. Referência ao slot reservado: `slotId`, `date`, `startTime` |
| `RejectionReason` | Value Object. Justificativa de recusa pelo estabelecimento |

**Regras de negócio do domínio:**
- Um agendamento só pode ser confirmado ou recusado pelo estabelecimento quando está `PENDING`
- Um agendamento só pode ser cancelado quando está `PENDING` ou `CONFIRMED`
- Um slot reservado não pode ser ocupado por dois agendamentos simultâneos

---

### 4.5 Notificações (`notifications`) — Generic

**Conceitos:**
- Notificação (`Notification`)
- Tipo de Notificação (`NotificationType`)

**Responsabilidades:**
- Enviar confirmação de agendamento ao usuário (RF05)
- Enviar lembrete de agendamento ao usuário (RF05)

**Glossário local:**

| Termo | Descrição |
|---|---|
| `Notification` | Entidade. `id`, `recipientId`, `type`, `message`, `sentAt` |
| `NotificationType` | Value Object: `APPOINTMENT_CONFIRMATION`, `APPOINTMENT_REMINDER`, `APPOINTMENT_REJECTION` |

---

### 4.6 Avaliações (`reviews`) — Supporting

**Conceitos:**
- Avaliação (`Review`)
- Nota (`Rating`)

**Responsabilidades:**
- Visualizar avaliações de outros clientes (RF17)
- Registrar avaliação após serviço concluído

**Glossário local:**

| Termo | Descrição |
|---|---|
| `Review` | Entidade. `id`, `petOwnerId`, `establishmentId`, `appointmentId`, `rating`, `comment` |
| `Rating` | Value Object. Valor de 1 a 5 com validação interna |

---

## 5. Context Mapping

O diagrama abaixo representa as relações entre os Bounded Contexts. `U` = Upstream (fornece) / `D` = Downstream (depende).

```
                    ┌─────────────────────────────────────────────┐
                    │                  DOMAIN                      │
                    │                                             │
                    │  ┌─────────────┐       ┌───────────────┐   │
                    │  │  identity   │──U──►D│     pets      │   │
                    │  │  (Generic)  │──U──►D│  (Supporting) │   │
                    │  └──────┬──────┘       └───────┬───────┘   │
                    │         │ U                     │ U         │
                    │         ▼ D                     ▼ D         │
                    │  ┌──────────────────────────────────────┐   │
                    │  │          scheduling (Core)           │   │
                    │  └──────────────────┬─────────────────┬─┘   │
                    │         U ▲          │ U               │ U  │
                    │           │          ▼ D               ▼ D  │
                    │  ┌────────────┐ ┌──────────────┐ ┌─────────┐│
                    │  │establish-  │ │notifications │ │reviews  ││
                    │  │ments       │ │  (Generic)   │ │(Support)││
                    │  │(Supporting)│ └──────────────┘ └─────────┘│
                    │  └────────────┘                             │
                    └─────────────────────────────────────────────┘
```

**Relações:**

| De | Para | Tipo | Descrição |
|---|---|---|---|
| `identity` | `scheduling` | U → D | Scheduling consulta dados do PetOwner autenticado |
| `identity` | `pets` | U → D | Pets pertence a um PetOwner de identity |
| `pets` | `scheduling` | U → D | Scheduling referencia o Pet do agendamento |
| `establishments` | `scheduling` | U → D | Scheduling usa AvailableSlot e Service do estabelecimento |
| `scheduling` | `notifications` | U → D | Scheduling emite eventos que disparam notificações |
| `scheduling` | `reviews` | U → D | Reviews só são criadas após Appointment COMPLETED |

---

## 6. Design Tático por Bounded Context

### 6.1 Building Blocks — `scheduling` (Core Domain)

```
Appointment (Aggregate Root)
├── AppointmentStatus    (Value Object)
├── BookedSlot           (Value Object)
└── RejectionReason      (Value Object)
```

**Entities:**
```typescript
// Aggregate Root
class Appointment {
  private id: AppointmentId
  private petOwnerId: string
  private petId: string
  private establishmentId: string
  private serviceId: string
  private slot: BookedSlot
  private status: AppointmentStatus

  confirm(): void               // regra: só se PENDING
  reject(reason: string): void  // regra: só se PENDING
  cancel(): void                // regra: só se PENDING ou CONFIRMED
  complete(): void              // regra: só se CONFIRMED
}
```

**Value Objects:**
```typescript
class AppointmentStatus {
  // PENDING | CONFIRMED | REJECTED | CANCELLED | COMPLETED
  canConfirm(): boolean
  canReject(): boolean
  canCancel(): boolean
}

class BookedSlot {
  readonly slotId: string
  readonly date: Date
  readonly startTime: string
}

class RejectionReason {
  readonly value: string  // não pode ser vazio
}
```

**Repository:**
```typescript
interface AppointmentRepository {
  findById(id: string): Promise<Appointment>
  findByPetOwner(petOwnerId: string): Promise<Appointment[]>
  findByEstablishment(establishmentId: string): Promise<Appointment[]>
  save(appointment: Appointment): Promise<void>
}
```

**Domain Service:**
```typescript
// Regra que envolve múltiplos agregados
class SlotAvailabilityService {
  verifySlotIsAvailable(slotId: string, date: Date): Promise<boolean>
}
```

**Factory:**
```typescript
// Usada porque a criação envolve múltiplas validações e o agregado
// precisa nascer consistente (status sempre PENDING, slot não ocupado).
class AppointmentFactory {
  static create(props: {
    petOwnerId: string
    petId: string
    establishmentId: string
    serviceId: string
    slotId: string
    date: Date
    startTime: string
  }): Appointment {
    // valida que nenhum ID está vazio
    // cria BookedSlot e AppointmentStatus(PENDING)
    // retorna Appointment já consistente
  }
}
```

---

### 6.2 Building Blocks — `establishments` (Supporting)

```
Establishment (Aggregate Root)
├── OfferedService    (Entity)
├── AvailableSlot     (Entity)
├── Veterinarian      (Entity)
├── EstablishmentType (Value Object)
└── Price             (Value Object)
```

**Repository:**
```typescript
interface EstablishmentRepository {
  findById(id: string): Promise<Establishment>
  search(query: string): Promise<Establishment[]>
  findAvailableSlots(establishmentId: string, date: Date): Promise<AvailableSlot[]>
  save(establishment: Establishment): Promise<void>
}
```

**Factory:**
```typescript
// Usada porque a criação exige validação do tipo (PET_SHOP | VET_CLINIC)
// e garante que o estabelecimento já nasça com lista de serviços vazia e
// consistente, sem depender de setters externos.
class EstablishmentFactory {
  static create(props: {
    name: string
    type: 'PET_SHOP' | 'VET_CLINIC'
    address: string
    phone: string
  }): Establishment {
    // valida type, name não vazio, phone no formato esperado
    // retorna Establishment com offeredServices = [], availableSlots = []
  }
}

// Separada porque OfferedService tem suas próprias invariantes (price > 0, duration > 0)
class OfferedServiceFactory {
  static create(props: {
    name: string
    amount: number
    currency: string
    durationMinutes: number
  }): OfferedService {
    // valida amount > 0, durationMinutes > 0
    // cria Price(amount, currency) internamente
  }
}
```

---

### 6.3 Building Blocks — `pets` (Supporting)

```
Pet (Aggregate Root)
├── Breed          (Value Object)
└── ServiceHistory (Entity)
```

**Repository:**
```typescript
interface PetRepository {
  findById(id: string): Promise<Pet>
  findByOwner(petOwnerId: string): Promise<Pet[]>
  save(pet: Pet): Promise<void>
}
```

**Factory:**
```typescript
// Usada porque a criação envolve validação de idade (>= 0),
// criação do Value Object Breed e vínculo obrigatório com o PetOwner.
class PetFactory {
  static create(props: {
    name: string
    breed: string
    ageYears: number
    petOwnerId: string
  }): Pet {
    // valida name não vazio, ageYears >= 0
    // cria Breed(breed) internamente
    // retorna Pet com serviceHistory vazio
  }
}
```

---

### 6.4 Building Blocks — `identity` (Generic)

```
PetOwner (Aggregate Root)
├── Credentials  (Value Object)
└── UserProfile  (Value Object)
```

**Factory:**
```typescript
// Usada porque a criação exige hash da senha antes de montar o
// Value Object Credentials — lógica que não pertence ao construtor.
class PetOwnerFactory {
  static async create(props: {
    name: string
    email: string
    rawPassword: string
    phone: string
  }): Promise<PetOwner> {
    // valida formato de email
    // valida senha mínimo 8 caracteres
    // aplica hash na senha (bcrypt)
    // cria Credentials(email, hashedPassword) e UserProfile(name, phone)
    // retorna PetOwner consistente
  }
}
```

---

### 6.5 Building Blocks — `reviews` (Supporting)

```
Review (Aggregate Root)
├── Rating  (Value Object)
```

**Repository:**
```typescript
interface ReviewRepository {
  findById(id: string): Promise<Review>
  findByEstablishment(establishmentId: string): Promise<Review[]>
  save(review: Review): Promise<void>
}
```

**Factory:**
```typescript
// Usada porque a criação depende de uma regra de negócio externa:
// só é possível criar uma Review se o Appointment estiver COMPLETED.
// Essa validação envolve múltiplos conceitos e não pertence ao construtor.
class ReviewFactory {
  static create(props: {
    petOwnerId: string
    establishmentId: string
    appointmentId: string
    appointmentStatus: string   // deve ser 'COMPLETED'
    rating: number              // 1 a 5
    comment?: string
  }): Review {
    // valida appointmentStatus === 'COMPLETED'
    // cria Rating(rating) com validação 1 <= rating <= 5
    // retorna Review consistente
  }
}
```

---

## 7. Arquitetura dos Microserviços

Cada Bounded Context corresponde a um microserviço independente, seguindo a **Onion Architecture** (também referenciada na Clean Architecture).

### 7.1 Estrutura de Camadas (por microserviço)

```
src/
├── domain/                  ← Núcleo do domínio (independente de framework)
│   ├── entities/            ← Entidades e Aggregates
│   ├── value-objects/       ← Value Objects
│   ├── repositories/        ← Interfaces dos repositórios (ports)
│   └── services/            ← Domain Services
│
├── application/             ← Casos de uso (orquestra o domínio)
│   └── use-cases/
│
├── infrastructure/          ← Implementações externas (adapters)
│   ├── repositories/        ← Implementação dos repositórios (TypeORM/Prisma)
│   └── messaging/           ← Publicação de eventos
│
└── interface/               ← Controllers HTTP (NestJS)
    ├── controllers/
    ├── dtos/
    └── modules/
```

> O fluxo de dependências vai **de fora para dentro**: `interface → application → domain`. O domínio não depende de nenhuma camada externa.

---

### 7.2 Microserviços e Portas

| Microserviço | Bounded Context | Porta | Banco |
|---|---|---|---|
| `identity-service` | identity | 3001 | PostgreSQL |
| `pets-service` | pets | 3002 | PostgreSQL |
| `establishments-service` | establishments | 3003 | PostgreSQL |
| `scheduling-service` | scheduling | 3004 | PostgreSQL |
| `notifications-service` | notifications | 3005 | — |
| `reviews-service` | reviews | 3006 | PostgreSQL |

---

### 7.3 Comunicação entre Microserviços

Seguindo os padrões das Aulas 04 e 05:

| Interação | Tipo | Protocolo | Justificativa |
|---|---|---|---|
| App móvel → Microserviços | Síncrono | **REST/HTTP** | Exposição externa, simplicidade, padronização |
| `scheduling` → `establishments` | Síncrono | **REST/HTTP** | Consulta de slots disponíveis em tempo real |
| `scheduling` → `notifications` | Assíncrono | **Mensageria** | Disparo de notificação não bloqueia o agendamento |
| `scheduling` → `reviews` | Assíncrono | **Mensageria** | Evento `AppointmentCompleted` habilita criação de review |
| `identity` → demais | Síncrono | **REST/HTTP** | Validação de token JWT |

**Eventos de Domínio publicados pelo `scheduling-service`:**

| Evento | Consumidores |
|---|---|
| `AppointmentCreated` | `notifications-service` (envia confirmação pendente) |
| `AppointmentConfirmed` | `notifications-service` (envia confirmação ao PetOwner) |
| `AppointmentRejected` | `notifications-service` (envia justificativa ao PetOwner) |
| `AppointmentCompleted` | `reviews-service` (libera avaliação) |

---

## 8. Estrutura NestJS por Microserviço

Baseado na Aula 05 do professor. Exemplo aplicado ao `scheduling-service`:

```
$ nest new scheduling-service --strict
```

```
src/
├── scheduling/
│   ├── scheduling.module.ts          ← delimita o bounded context
│   ├── domain/
│   │   ├── appointment.entity.ts
│   │   ├── appointment-status.vo.ts
│   │   ├── booked-slot.vo.ts
│   │   └── appointment.repository.ts
│   ├── application/
│   │   └── use-cases/
│   │       ├── create-appointment.use-case.ts
│   │       ├── confirm-appointment.use-case.ts
│   │       └── reject-appointment.use-case.ts
│   ├── infrastructure/
│   │   └── appointment.repository.impl.ts
│   └── interface/
│       ├── scheduling.controller.ts  ← expõe recursos do BC
│       └── dtos/
└── main.ts
```

**Componentes NestJS utilizados:**

| Componente | Papel no Microserviço |
|---|---|
| `@Module` | Delimita as fronteiras do Bounded Context |
| `@Controller` | Expõe os recursos HTTP do BC |
| `@Injectable` (Service) | Implementa casos de uso e domain services |
| `Guards` | Validação de autenticação JWT |
| `Pipes` | Validação de DTOs de entrada (class-validator) |
| `Exception Filters` | Padronização de erros de domínio em respostas HTTP |
| `Interceptors` | Logging e transformação de resposta |

---

## 9. Mapeamento de Requisitos → Microserviços

| RF | Requisito | Microserviço Responsável |
|---|---|---|
| RF01 | Cadastro de usuários (donos de pets) | `identity-service` |
| RF02 | Agendamento de serviços | `scheduling-service` |
| RF03 | Cadastro de pets | `pets-service` |
| RF04 | Visualizar pet shops e clínicas | `establishments-service` |
| RF05 | Confirmação/lembrete de agendamento | `notifications-service` |
| RF06 | Estabelecimento gerencia horários | `establishments-service` |
| RF09 | Confirmar ou recusar agendamentos | `scheduling-service` |
| RF10 | Histórico de serviços do pet | `pets-service` |
| RF11 | Cadastro de serviços oferecidos | `establishments-service` |
| RF12 | Visualizar veterinários disponíveis | `establishments-service` |
| RF13 | Atualizar serviços e produtos | `establishments-service` |
| RF14 | Pesquisar estabelecimentos | `establishments-service` |
| RF15 | Visualizar preços dos serviços | `establishments-service` |
| RF16 | Editar informações pessoais e do pet | `identity-service` / `pets-service` |
| RF17 | Visualizar avaliações de clientes | `reviews-service` |

---

## 10. Pré-requisitos e Stack Tecnológica

| Item | Tecnologia |
|---|---|
| Linguagem | TypeScript |
| Runtime | Node.js > 20 |
| Framework | NestJS |
| Banco de Dados | PostgreSQL |
| ORM | TypeORM ou Prisma |
| Mensageria | RabbitMQ ou Kafka |
| Autenticação | JWT |
| Documentação API | Swagger (OpenAPI) |

**Setup inicial (por microserviço):**
```bash
$ npm install -g @nestjs/cli
$ nest new scheduling-service --strict
$ cd scheduling-service
$ npm run start:dev
```

---

## 11. Resumo do Design Estratégico

| Conceito DDD | Aplicação no MyPet |
|---|---|
| **Domínio** | Plataforma de agendamento de serviços para pets |
| **Core Domain** | `scheduling` — agendamento de serviços |
| **Supporting Domains** | `pets`, `establishments`, `reviews` |
| **Generic Domains** | `identity`, `notifications` |
| **Linguagem Ubíqua** | Termos definidos na seção 3, usados no código e nas conversas |
| **Bounded Contexts** | 6 contextos com fronteiras, regras e dados próprios |
| **Context Mapping** | `scheduling` é Downstream de `identity`, `pets` e `establishments` |
| **Factories** | `AppointmentFactory`, `EstablishmentFactory`, `OfferedServiceFactory`, `PetFactory`, `PetOwnerFactory`, `ReviewFactory` |
| **Microserviço** | Unidade de deploy que coincide com o Bounded Context |
