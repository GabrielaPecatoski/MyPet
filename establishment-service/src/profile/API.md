# API de Perfil de Estabelecimento - Establishment Service

## Endpoints

### 1. Obter Perfil do Estabelecimento
```http
GET /establishment-profiles/:establishmentId
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "ownerId": "uuid-usuario",
  "name": "Petshop ABC",
  "email": "contato@petshop.com",
  "phone": "11987654321",
  "address": "Rua das Flores, 123",
  "city": "São Paulo",
  "state": "SP",
  "zipCode": "01234567",
  "cnpj": "12345678000190",
  "type": "PET_SHOP",
  "profileImage": "https://...",
  "coverImage": "https://...",
  "bio": "Melhor petshop da região",
  "services": ["Banho", "Tosa", "Vacinação"],
  "rating": 4.5,
  "followers": 250,
  "isVerified": true,
  "isActive": true,
  "openingHours": {
    "monday": "09:00-18:00",
    "tuesday": "09:00-18:00",
    "wednesday": "09:00-18:00",
    "thursday": "09:00-18:00",
    "friday": "09:00-18:00",
    "saturday": "09:00-17:00",
    "sunday": "closed"
  },
  "createdAt": "2026-04-13T10:30:00Z",
  "updatedAt": "2026-04-13T10:30:00Z"
}
```

### 2. Obter Perfil por ID do Proprietário
```http
GET /establishment-profiles/owner/:ownerId
```

**Response:** `200 OK` (mesma estrutura acima)

### 3. Atualizar Perfil do Estabelecimento
```http
PUT /establishment-profiles/:establishmentId
Content-Type: application/json

{
  "name": "Petshop ABC Premium",
  "bio": "Agora com novos serviços",
  "services": ["Banho", "Tosa", "Vacinação", "Cirurgia"],
  "profileImage": "https://...",
  "coverImage": "https://...",
  "openingHours": {
    "monday": "08:00-19:00",
    "tuesday": "08:00-19:00",
    "wednesday": "08:00-19:00",
    "thursday": "08:00-19:00",
    "friday": "08:00-19:00",
    "saturday": "08:00-18:00",
    "sunday": "10:00-17:00"
  }
}
```

**Response:** `200 OK` (perfil atualizado)

### 4. Obter Estatísticas do Estabelecimento
```http
GET /establishment-profiles/:establishmentId/stats
```

**Response:** `200 OK`
```json
{
  "totalBookings": 250,
  "totalReviews": 85,
  "averageRating": 4.5,
  "followers": 250,
  "followers_growth": 15,
  "services_count": 4
}
```

### 5. Listar Estabelecimentos
```http
GET /establishment-profiles
GET /establishment-profiles?type=PET_SHOP
```

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "name": "Petshop ABC",
    "city": "São Paulo",
    "type": "PET_SHOP",
    "rating": 4.5,
    "followers": 250,
    "services": ["Banho", "Tosa"]
  }
]
```

### 6. Buscar Estabelecimentos
```http
GET /establishment-profiles/search?q=petshop
```

Busca por:
- Nome do estabelecimento
- Cidade
- Serviços oferecidos

**Response:** `200 OK` (array de estabelecimentos)

### 7. Adicionar Seguidor
```http
POST /establishment-profiles/:establishmentId/follow
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "followers": 251
}
```

### 8. Atualizar Avaliação
```http
PUT /establishment-profiles/:establishmentId/rating
Content-Type: application/json

{
  "rating": 4.8
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "rating": 4.8
}
```

## Tipos de Estabelecimento

- `PET_SHOP` - Pet shop/Loja de animais
- `VET_CLINIC` - Clínica veterinária
- `GROOMING` - Serviço de higiene e tosa
- `HOTEL` - Hotel para animais
- `TRAINING` - Treinamento de animais
- `OTHER` - Outro tipo

## Campos Atualizáveis

- `name` - Nome do estabelecimento
- `phone` - Telefone
- `address` - Endereço
- `city` - Cidade
- `state` - Estado (UF)
- `zipCode` - CEP
- `type` - Tipo de estabelecimento
- `profileImage` - URL da imagem de perfil
- `coverImage` - URL da imagem de capa
- `bio` - Descrição/biografia
- `services` - Array de serviços
- `openingHours` - Horário de funcionamento (JSON)

## Erros

### Estabelecimento não encontrado
```json
{
  "statusCode": 404,
  "message": "Perfil de estabelecimento \"xyz\" não encontrado",
  "error": "Not Found"
}
```

### CNPJ duplicado
```json
{
  "statusCode": 409,
  "message": "CNPJ já registrado",
  "error": "Conflict"
}
```

### Avaliação inválida
```json
{
  "statusCode": 400,
  "message": "Avaliação deve estar entre 0 e 5",
  "error": "Bad Request"
}
```
