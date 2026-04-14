export const REGISTRATION_MESSAGES = {
  // Success
  CREATED: 'Registro criado com sucesso',
  UPDATED: 'Registro atualizado com sucesso',
  DELETED: 'Registro removido com sucesso',
  STATUS_UPDATED: 'Status atualizado com sucesso',

  // Errors
  NOT_FOUND: (id: string) => `Registro com ID "${id}" não encontrado`,
  EMAIL_ALREADY_EXISTS: 'Email já registrado',
  CNPJ_ALREADY_EXISTS: 'CNPJ já registrado',
  INVALID_STATUS: 'Status inválido',

  // Validations
  INVALID_EMAIL: 'Email inválido',
  INVALID_PHONE: 'Telefone deve ser um número válido',
  INVALID_STATE: 'Estado deve ser um código UF válido (ex: SP, RJ)',
  INVALID_ZIPCODE: 'CEP deve ter 8 dígitos',
  INVALID_CNPJ: 'CNPJ deve ter 14 dígitos',
  INVALID_NAME: 'Nome deve ter entre 3 e 100 caracteres',
  INVALID_ADDRESS: 'Endereço deve ter entre 5 e 150 caracteres',
  INVALID_CITY: 'Cidade deve ter entre 2 e 50 caracteres',
  INVALID_DESCRIPTION: 'Descrição não pode exceder 500 caracteres',
  INVALID_SERVICES: 'Serviços deve ser um array com pelo menos 1 item',
};

export const REGISTRATION_CONSTRAINTS = {
  NAME: { MIN: 3, MAX: 100 },
  EMAIL: { MAX: 255 },
  PHONE: { LENGTH: 11 }, // BR format
  PHONE_GLOBAL: { MIN: 7, MAX: 15 },
  ADDRESS: { MIN: 5, MAX: 150 },
  CITY: { MIN: 2, MAX: 50 },
  STATE: { LENGTH: 2 }, // UF Code
  ZIPCODE: { LENGTH: 8 }, // Brazilian zipcode
  CNPJ: { LENGTH: 14 }, // Brazilian CNPJ
  DESCRIPTION: { MAX: 500 },
  SERVICES: { MIN: 1, MAX: 50 },
};

export const REGISTRATION_PATTERNS = {
  STATE: /^[A-Z]{2}$/, // SP, RJ, MG, etc
  ZIPCODE: /^\d{8}$/, // 12345678
  CNPJ: /^\d{14}$/, // 12345678000190
  PHONE: /^\d{10,11}$/, // Can be (10) or (11) digits
};
