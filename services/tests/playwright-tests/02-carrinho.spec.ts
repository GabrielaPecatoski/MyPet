import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:3004';
const USER_ID = `user-carrinho-${Date.now()}`;
const ESTAB_ID = 'estab-cart-test';

let api: APIRequestContext;
let productId: string;
let orderId: string;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });

  // cria produto para usar no carrinho
  const res = await api.post('/marketplace/products', {
    data: {
      name: `Produto Carrinho ${Date.now()}`,
      price: 30.0,
      stock: 50,
      establishmentId: ESTAB_ID,
    },
  });
  const body = await res.json();
  productId = body.id;
});

test.afterAll(async () => {
  await api.delete(`/marketplace/cart/${USER_ID}`);
  await api.delete(`/marketplace/products/${productId}`);
  await api.dispose();
});

test('carrinho começa vazio', async () => {
  const res = await api.get(`/marketplace/cart/${USER_ID}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test('adicionar item ao carrinho', async () => {
  const res = await api.post(`/marketplace/cart/${USER_ID}`, {
    data: { productId, quantity: 2 },
  });
  expect(res.status()).toBe(201);
  const body: any[] = await res.json();
  const item = body.find((i) => i.productId === productId);
  expect(item).toBeTruthy();
  expect(item.quantity).toBe(2);
});

test('adicionar mesmo item incrementa quantidade', async () => {
  const res = await api.post(`/marketplace/cart/${USER_ID}`, {
    data: { productId, quantity: 1 },
  });
  expect(res.status()).toBe(201);
  const body: any[] = await res.json();
  const item = body.find((i) => i.productId === productId);
  expect(item.quantity).toBe(3);
});

test('atualizar quantidade do item', async () => {
  const res = await api.patch(`/marketplace/cart/${USER_ID}/${productId}`, {
    data: { quantity: 5 },
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  const item = body.find((i) => i.productId === productId);
  expect(item.quantity).toBe(5);
});

test('atualizar quantidade para 0 remove item', async () => {
  // adiciona um segundo produto temporário
  const tempRes = await api.post('/marketplace/products', {
    data: { name: `Temp ${Date.now()}`, price: 10.0, stock: 5, establishmentId: ESTAB_ID },
  });
  const tempProduct = await tempRes.json();

  await api.post(`/marketplace/cart/${USER_ID}`, {
    data: { productId: tempProduct.id, quantity: 1 },
  });

  const res = await api.patch(`/marketplace/cart/${USER_ID}/${tempProduct.id}`, {
    data: { quantity: 0 },
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((i) => i.productId === tempProduct.id)).toBe(false);

  await api.delete(`/marketplace/products/${tempProduct.id}`);
});

test('remover item específico do carrinho', async () => {
  // garante que o item principal está no carrinho
  const cartRes = await api.get(`/marketplace/cart/${USER_ID}`);
  const cart: any[] = await cartRes.json();
  expect(cart.some((i) => i.productId === productId)).toBe(true);

  const res = await api.delete(`/marketplace/cart/${USER_ID}/${productId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((i) => i.productId === productId)).toBe(false);
});

test('checkout cria pedido e limpa carrinho', async () => {
  // recoloca item no carrinho
  await api.post(`/marketplace/cart/${USER_ID}`, {
    data: { productId, quantity: 2 },
  });

  const res = await api.post(`/marketplace/orders/${USER_ID}`);
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.status).toBe('AWAITING_PAYMENT');
  expect(body.total).toBeGreaterThan(0);
  expect(Array.isArray(body.items)).toBe(true);
  orderId = body.id;

  // carrinho deve estar vazio após checkout
  const cartRes = await api.get(`/marketplace/cart/${USER_ID}`);
  const cart = await cartRes.json();
  expect(cart.length).toBe(0);
});

test('checkout com carrinho vazio retorna 404', async () => {
  const res = await api.post(`/marketplace/orders/${USER_ID}`);
  expect(res.status()).toBe(404);
});

test('listar pedidos do usuário inclui pedido criado', async () => {
  const res = await api.get(`/marketplace/orders/${USER_ID}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((o) => o.id === orderId)).toBe(true);
});
