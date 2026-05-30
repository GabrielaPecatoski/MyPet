import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:3001';
const ADMIN_SECRET = 'mypet_admin_secret';

let api: APIRequestContext;

const ts = Date.now();
const email = `teste${ts}@mypet.com`;
const cpf = `${ts}`.slice(-11).padStart(11, '0');
let userId: string;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

// ---- registro ----

test('registrar novo usuário CLIENTE', async () => {
  const res = await api.post('/auth/register', {
    data: {
      name: 'Usuário Teste',
      email,
      password: 'senha123',
      phone: '41999990000',
      cpf,
      role: 'CLIENTE',
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.access_token).toBeTruthy();
  expect(body.user.email).toBe(email);
  expect(body.user.role).toBe('CLIENTE');
  userId = body.user.id;
});

test('registrar com email duplicado retorna 409', async () => {
  const res = await api.post('/auth/register', {
    data: {
      name: 'Outro',
      email,
      password: 'senha123',
      phone: '41988880000',
      cpf: String(ts + 100).slice(-11),
    },
  });
  expect(res.status()).toBe(409);
});

test('registrar sem campos obrigatórios retorna 400', async () => {
  const res = await api.post('/auth/register', {
    data: { email: 'incompleto@test.com' },
  });
  expect(res.status()).toBe(400);
});

// ---- login ----

test('login com credenciais corretas retorna token', async () => {
  const res = await api.post('/auth/login', {
    data: { email, password: 'senha123' },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.access_token).toBeTruthy();
  expect(body.user.id).toBe(userId);
});

test('login com senha errada retorna 401', async () => {
  const res = await api.post('/auth/login', {
    data: { email, password: 'senhaerrada' },
  });
  expect(res.status()).toBe(401);
});

test('login com email inexistente retorna 401', async () => {
  const res = await api.post('/auth/login', {
    data: { email: 'naoexiste@mypet.com', password: 'senha123' },
  });
  expect(res.status()).toBe(401);
});

// ---- me ----

test('GET /auth/me com x-user-id retorna perfil', async () => {
  const res = await api.get('/auth/me', {
    headers: { 'x-user-id': userId },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(userId);
  expect(body.email).toBe(email);
  expect(body.password).toBeUndefined();
});

test('GET /auth/me sem header retorna 401', async () => {
  const res = await api.get('/auth/me');
  expect(res.status()).toBe(401);
});

test('PATCH /auth/me atualiza nome e telefone', async () => {
  const res = await api.patch('/auth/me', {
    headers: { 'x-user-id': userId },
    data: { name: 'Nome Atualizado', phone: '41977770000' },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.name).toBe('Nome Atualizado');
  expect(body.phone).toBe('41977770000');
});

// ---- refresh ----

test('POST /auth/refresh retorna novo token', async () => {
  const res = await api.post('/auth/refresh', {
    headers: { 'x-user-id': userId },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.access_token).toBeTruthy();
});

// ---- admin ----

test('GET /auth/admin/users com secret retorna lista', async () => {
  const res = await api.get('/auth/admin/users', {
    headers: { 'x-admin-secret': ADMIN_SECRET },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.some((u: any) => u.id === userId)).toBe(true);
});

test('GET /auth/admin/users sem secret retorna 403', async () => {
  const res = await api.get('/auth/admin/users', {
    headers: { 'x-admin-secret': 'secret_errado' },
  });
  expect(res.status()).toBe(403);
});

// ---- delete (por último) ----

test('DELETE /auth/me remove conta', async () => {
  // cria usuário descartável com CPF único e diferente
  const delTs = Date.now() + 999;
  const delEmail = `del${delTs}@mypet.com`;
  const delCpf = String(delTs + 50000).slice(-11);

  const reg = await api.post('/auth/register', {
    data: {
      name: 'Deletar',
      email: delEmail,
      password: 'senha123',
      phone: '41911110000',
      cpf: delCpf,
    },
  });
  expect(reg.status()).toBe(201);
  const { user } = await reg.json();

  const res = await api.delete('/auth/me', {
    headers: { 'x-user-id': user.id },
  });
  expect(res.status()).toBe(204);

  // usuário deletado não deve mais existir (retorna 404 ou 401)
  const check = await api.get('/auth/me', {
    headers: { 'x-user-id': user.id },
  });
  expect(check.status()).toBeGreaterThanOrEqual(400);
});
