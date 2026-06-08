import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:3004';
const ESTAB_ID = 'estab-test-001';

let api: APIRequestContext;
let productId: string;
const productName = `Ração Teste ${Date.now()}`;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test('listar produtos - retorna array', async () => {
  const res = await api.get('/marketplace/products');
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
});

test('criar produto', async () => {
  const res = await api.post('/marketplace/products', {
    data: {
      name: productName,
      brand: 'Marca Teste',
      price: 49.9,
      stock: 10,
      category: 'Alimentação',
      establishmentId: ESTAB_ID,
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.name).toBe(productName);
  expect(body.stock).toBe(10);
  productId = body.id;
});

test('buscar produto por id', async () => {
  const res = await api.get(`/marketplace/products/${productId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(productId);
  expect(body.name).toBe(productName);
});

test('listar produtos filtrados por estabelecimento', async () => {
  const res = await api.get(`/marketplace/products?establishmentId=${ESTAB_ID}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === productId)).toBe(true);
});

test('buscar produto por nome (search)', async () => {
  const keyword = productName.split(' ')[1];
  const res = await api.get(`/marketplace/products?search=${keyword}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === productId)).toBe(true);
});

test('atualizar produto - preço e estoque', async () => {
  const res = await api.patch(`/marketplace/products/${productId}`, {
    data: { price: 55.0, stock: 20 },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.price).toBe(55.0);
  expect(body.stock).toBe(20);
});

test('produto inexistente retorna 404', async () => {
  const res = await api.get('/marketplace/products/nao-existe-id');
  expect(res.status()).toBe(404);
});

test('excluir produto (soft delete)', async () => {
  const res = await api.delete(`/marketplace/products/${productId}`);
  expect(res.status()).toBe(204);
});

test('produto deletado não aparece na listagem pública', async () => {
  const res = await api.get('/marketplace/products');
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === productId)).toBe(false);
});
