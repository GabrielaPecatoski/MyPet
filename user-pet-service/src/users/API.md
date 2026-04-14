# API de Usuários - User Pet Service

## Endpoints

### 1. Registrar Novo Usuário
```http
POST /users/register
Content-Type: application/json

{
  "email": "usuario@example.com",
  "password": "senha123",
  "name": "João Silva",
  "phone": "11987654321",
  "birthDate": "1990-01-15",
  "cpf": "12345678900"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "email": "usuario@example.com",
  "name": "João Silva",
  "phone": "11987654321",
  "birthDate": "1990-01-15",
  "cpf": "12345678900",
  "role": "PET_OWNER",
  "isActive": true,
  "createdAt": "2026-04-13T10:30:00Z",
  "updatedAt": "2026-04-13T10:30:00Z"
}
```

### 2. Obter Perfil do Usuário
```http
GET /users/:userId
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "email": "usuario@example.com",
  "name": "João Silva",
  "phone": "11987654321",
  "birthDate": "1990-01-15",
  "cpf": "12345678900",
  "role": "PET_OWNER",
  "bio": "Amante de animais",
  "profileImage": "https://...",
  "isActive": true,
  "createdAt": "2026-04-13T10:30:00Z",
  "updatedAt": "2026-04-13T10:30:00Z"
}
```

### 3. Atualizar Perfil do Usuário
```http
PUT /users/:userId/profile
Content-Type: application/json

{
  "name": "João Silva Costa",
  "phone": "11999999999",
  "bio": "Novo bio",
  "profileImage": "https://...",
  "birthDate": "1990-01-15"
}
```

**Response:** `200 OK`

### 4. Listar Todos os Usuários
```http
GET /users
```

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "email": "usuario@example.com",
    "name": "João Silva",
    "phone": "11987654321",
    "createdAt": "2026-04-13T10:30:00Z"
  }
]
```

### 5. Obter Estatísticas de Usuários
```http
GET /users/stats/overview
```

**Response:** `200 OK`
```json
{
  "totalUsers": 150,
  "activeUsers": 145,
  "petOwners": 100,
  "establishmentOwners": 45
}
```

## Campos

### Obrigatórios (Registro)
- `email` - Email único, válido
- `password` - Minimo 6 caracteres
- `name` - Nome completo
- `phone` - Telefone BR
- `birthDate` - Data de nascimento (YYYY-MM-DD)
- `cpf` - CPF único, 11 dígitos

### Opcionais (Perfil)
- `bio` - Pequena descrição
- `profileImage` - URL da imagem de perfil

## Roles
- `USER` - Usuário padrão
- `PET_OWNER` - Proprietário de pet (padrão)
- `ESTABLISHMENT_OWNER` - Proprietário de estabelecimento
- `ADMIN` - Administrador

## Erros

### Email duplicado
```json
{
  "statusCode": 409,
  "message": "Email já registrado",
  "error": "Conflict"
}
```

### Usuário não encontrado
```json
{
  "statusCode": 404,
  "message": "Usuário com ID \"xyz\" não encontrado",
  "error": "Not Found"
}
```

### Validação de senha fraca
```json
{
  "statusCode": 400,
  "message": "Senha deve ter no mínimo 6 caracteres",
  "error": "Bad Request"
}
```
