# API de Registro de Estabelecimentos

API para gerenciar o registro e aprovação de novos estabelecimentos no sistema MyPet.

## Estrutura

```
registration/
├── registration.controller.ts       # Endpoints da API
├── registration.service.ts          # Lógica de negócio
├── registration.module.ts           # Módulo NestJS
├── registration.controller.spec.ts  # Testes unitários
├── dto/
│   ├── create-registration.dto.ts   # Validação para criação
│   └── update-registration.dto.ts   # Validação para atualização
└── entities/
    └── registration.entity.ts       # Modelo de dados
```

## Endpoints

### Criar Registro
```http
POST /registrations
Content-Type: application/json

{
  "name": "Petshop ABC",
  "email": "contato@petshop.com",
  "phone": "11987654321",
  "address": "Rua das Flores, 123",
  "city": "São Paulo",
  "state": "SP",
  "zipCode": "01234567",
  "cnpj": "12345678000190",
  "services": ["Banho", "Tosa"],
  "description": "Melhor petshop da região"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "name": "Petshop ABC",
  "email": "contato@petshop.com",
  "status": "PENDING",
  "createdAt": "2026-04-13T10:30:00Z",
  "updatedAt": "2026-04-13T10:30:00Z"
}
```

### Listar Registros
```http
GET /registrations
GET /registrations?status=PENDING
```

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "name": "Petshop ABC",
    "email": "contato@petshop.com",
    "status": "PENDING",
    "createdAt": "2026-04-13T10:30:00Z"
  }
]
```

### Buscar Registro
```http
GET /registrations/:id
```

**Response:** `200 OK`

### Atualizar Registro
```http
PUT /registrations/:id
Content-Type: application/json

{
  "phone": "11999999999",
  "description": "Nova descrição"
}
```

**Response:** `200 OK`

### Atualizar Status
```http
PUT /registrations/:id/status
Content-Type: application/json

{
  "status": "APPROVED"
}
```

**Status Valores:**
- `PENDING` - Aguardando aprovação
- `APPROVED` - Aprovado
- `REJECTED` - Rejeitado
- `INACTIVE` - Inativo

**Response:** `200 OK`

### Deletar Registro
```http
DELETE /registrations/:id
```

**Response:** `204 No Content`

## Validações

### CreateRegistrationDto

| Campo | Tipo | Validação |
|-------|------|-----------|
| name | string | 3-100 caracteres |
| email | string | Email válido, único |
| phone | string | Telefone BR válido |
| address | string | 5-150 caracteres |
| city | string | 2-50 caracteres |
| state | string | UF válida (ex: SP, RJ) |
| zipCode | string | 8 dígitos |
| cnpj | string (opcional) | 14 dígitos, único |
| services | array (opcional) | Mínimo 1 item |
| description | string (opcional) | Máximo 500 caracteres |

### Transformações aplicadas

- **Trim:** Nome, Email, Endereço, Cidade, Descrição
- **Lowercase:** Email
- **Uppercase:** Estado
- **Remove não-dígitos:** Telefone, CEP, CNPJ

## Tratamento de Erros

### Conflitos
```json
{
  "statusCode": 409,
  "message": "Email já registrado"
}
```

### Não Encontrado
```json
{
  "statusCode": 404,
  "message": "Registro com ID \"xyz\" não encontrado"
}
```

### Validação
```json
{
  "statusCode": 400,
  "message": [
    "Nome deve ter no mínimo 3 caracteres",
    "Email inválido"
  ],
  "error": "Bad Request"
}
```

## Testes

```bash
# Rodar testes
npm test

# Cobertura
npm run test:cov

# Watch
npm run test:watch
```

## Funcionalidades

✅ Criar registro com validações robustas
✅ Listar todos os registros com ordenação por data
✅ Filtrar por status
✅ Buscar registro por ID
✅ Atacualizações parciais (PATCH/PUT)
✅ Gerenciar status de aprovação
✅ Deletar registros
✅ Prevenção de duplicatas (email, CNPJ)
✅ Transformações e limpeza de dados
✅ Testes unitários
