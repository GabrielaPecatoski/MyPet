import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:3007';

let api: APIRequestContext;
const estabId = `estab-review-${Date.now()}`;
const userId1 = `user-rev-1-${Date.now()}`;
const userId2 = `user-rev-2-${Date.now()}`;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test('estabelecimento sem avaliações retorna array vazio', async () => {
  const res = await api.get(`/reviews/establishment/${estabId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test('stats de estabelecimento sem avaliações retorna avg 0', async () => {
  const res = await api.get(`/reviews/establishment/${estabId}/stats`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  // campos reais: { avg: number, count: number }
  expect(body.avg).toBe(0);
  expect(body.count).toBe(0);
});

test('criar avaliação sem x-user-id retorna 401', async () => {
  const res = await api.post(`/reviews/establishment/${estabId}`, {
    data: { rating: 5, comment: 'Ótimo!' },
  });
  expect(res.status()).toBe(401);
});

test('criar primeira avaliação (5 estrelas)', async () => {
  const res = await api.post(`/reviews/establishment/${estabId}`, {
    headers: { 'x-user-id': userId1 },
    data: { rating: 5, comment: 'Excelente serviço!', userName: 'Cliente 1' },
  });
  expect(res.status()).toBe(201);
  // resposta: { review: {...}, avg: number, count: number }
  const body = await res.json();
  expect(body.review.id).toBeTruthy();
  expect(body.review.rating).toBe(5);
  expect(body.review.establishmentId).toBe(estabId);
  expect(body.count).toBe(1);
});

test('criar segunda avaliação (3 estrelas)', async () => {
  const res = await api.post(`/reviews/establishment/${estabId}`, {
    headers: { 'x-user-id': userId2 },
    data: { rating: 3, comment: 'Bom, mas pode melhorar.', userName: 'Cliente 2' },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.review.rating).toBe(3);
  expect(body.count).toBe(2);
});

test('listar avaliações retorna as duas', async () => {
  const res = await api.get(`/reviews/establishment/${estabId}`);
  const body: any[] = await res.json();
  expect(body.length).toBe(2);
});

test('stats calculam média corretamente (5+3)/2 = 4', async () => {
  const res = await api.get(`/reviews/establishment/${estabId}/stats`);
  const body = await res.json();
  expect(body.count).toBe(2);
  expect(body.avg).toBe(4);
});

test('avaliação sem comentário é criada com sucesso', async () => {
  const estabId2 = `estab-nocomment-${Date.now()}`;
  const res = await api.post(`/reviews/establishment/${estabId2}`, {
    headers: { 'x-user-id': userId1 },
    data: { rating: 4 },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.review.rating).toBe(4);
});

test('avaliação com rating inválido é aceita pelo serviço (sem validação de range)', async () => {
  // O serviço atual não valida o range de rating — apenas registra o valor
  const res = await api.post(`/reviews/establishment/${estabId}`, {
    headers: { 'x-user-id': userId1 },
    data: { rating: 10 },
  });
  // O serviço aceita qualquer número como rating
  expect(res.status()).toBe(201);
});
