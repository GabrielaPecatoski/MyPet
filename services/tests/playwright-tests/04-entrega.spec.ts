import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3004";
const ESTAB_ID = "estab-entrega-test";
const INITIAL_STOCK = 15;

let api: APIRequestContext;
let productId: string;
let orderId: string;
const userId = `user-entrega-${Date.now()}`;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });

  const prodRes = await api.post("/marketplace/products", {
    data: {
      name: `Produto Entrega ${Date.now()}`,
      price: 80.0,
      stock: INITIAL_STOCK,
      establishmentId: ESTAB_ID,
    },
  });
  const prod = await prodRes.json();
  productId = prod.id;

  await api.post(`/marketplace/cart/${userId}`, {
    data: { productId, quantity: 3 },
  });
  const orderRes = await api.post(`/marketplace/orders/${userId}`);
  const order = await orderRes.json();
  orderId = order.id;

  await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 240.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
});

test.afterAll(async () => {
  await api.dispose();
});

test("pedido começa com deliveryStatus PENDING", async () => {
  const orders: any[] = await (
    await api.get(`/marketplace/orders/${userId}`)
  ).json();
  const order = orders.find((o) => o.id === orderId);
  expect(order?.deliveryStatus).toBe("PENDING");
});

test("avançar para PREPARING", async () => {
  const res = await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "PREPARING" },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.deliveryStatus).toBe("PREPARING");
});

test("avançar para READY", async () => {
  const res = await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "READY" },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.deliveryStatus).toBe("READY");
});

test("estoque NÃO foi decrementado antes de DELIVERED", async () => {
  const res = await api.get(`/marketplace/products/${productId}`);
  const prod = await res.json();
  expect(prod.stock).toBe(INITIAL_STOCK);
});

test("avançar para DELIVERED decrementa estoque", async () => {
  const res = await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "DELIVERED" },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.deliveryStatus).toBe("DELIVERED");

  const prodRes = await api.get(`/marketplace/products/${productId}`);
  const prod = await prodRes.json();
  expect(prod.stock).toBe(INITIAL_STOCK - 3);
});

test("pedido Cash (AWAITING_PAYMENT) aparece no endpoint do estabelecimento", async () => {
  const cashUser = `user-cash-entrega-${Date.now()}`;

  const prodRes = await api.post("/marketplace/products", {
    data: {
      name: `Prod Cash ${Date.now()}`,
      price: 50.0,
      stock: 10,
      establishmentId: ESTAB_ID,
    },
  });
  const cashProd = await prodRes.json();

  await api.post(`/marketplace/cart/${cashUser}`, {
    data: { productId: cashProd.id, quantity: 1 },
  });
  const orderRes = await api.post(`/marketplace/orders/${cashUser}`);
  const cashOrder = await orderRes.json();

  await api.post("/marketplace/payments", {
    data: {
      orderId: cashOrder.id,
      userId: cashUser,
      amount: 50.0,
      method: "CASH",
      deliveryMethod: "PICKUP",
    },
  });

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  expect(res.status()).toBe(200);
  const orders: any[] = await res.json();
  expect(orders.some((o) => o.id === cashOrder.id)).toBe(true);
});

test("pedido com pagamento rejeitado (PAYMENT_FAILED) não aparece no estabelecimento", async () => {
  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  const orders: any[] = await res.json();
  const statuses = orders.map((o) => o.status);
  expect(
    statuses.every((s) => ["CONFIRMED", "AWAITING_PAYMENT"].includes(s)),
  ).toBe(true);
});

test("delivery em pedido inexistente lança erro", async () => {
  const res = await api.patch("/marketplace/orders/id-invalido-xyz/delivery", {
    data: { deliveryStatus: "PREPARING" },
  });
  expect(res.status()).toBeGreaterThanOrEqual(400);
});
