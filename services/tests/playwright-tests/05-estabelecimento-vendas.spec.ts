import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3004";
const ESTAB_ID = `estab-vendas-${Date.now()}`;

let api: APIRequestContext;
let productId: string;

async function criarPedidoPago(
  userId: string,
  method: "PIX" | "CASH" | "BOLETO" | "DEBIT_CARD",
  deliveryMethod: "PICKUP" | "DELIVERY" = "PICKUP",
  deliveryAddress?: string,
): Promise<{ orderId: string; paymentId: string }> {
  await api.post(`/marketplace/cart/${userId}`, {
    data: { productId, quantity: 1 },
  });
  const orderRes = await api.post(`/marketplace/orders/${userId}`);
  const order = await orderRes.json();

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId: order.id,
      userId,
      amount: 120.0,
      method,
      deliveryMethod,
      deliveryAddress,
    },
  });
  const payment = await payRes.json();
  return { orderId: order.id, paymentId: payment.id };
}

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });

  const prodRes = await api.post("/marketplace/products", {
    data: {
      name: `Produto Vendas ${Date.now()}`,
      price: 120.0,
      stock: 100,
      establishmentId: ESTAB_ID,
    },
  });
  const prod = await prodRes.json();
  productId = prod.id;
});

test.afterAll(async () => {
  await api.dispose();
});

test("pedido PIX (CONFIRMED) aparece na tela de vendas", async () => {
  const { orderId } = await criarPedidoPago(`user-pix-v-${Date.now()}`, "PIX");

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  expect(res.status()).toBe(200);
  const orders: any[] = await res.json();
  const found = orders.find((o) => o.id === orderId);
  expect(found).toBeTruthy();
  expect(found.status).toBe("CONFIRMED");
});

test("pedido Dinheiro (AWAITING_PAYMENT) aparece na tela de vendas", async () => {
  const { orderId } = await criarPedidoPago(
    `user-cash-v-${Date.now()}`,
    "CASH",
  );

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  const orders: any[] = await res.json();
  const found = orders.find((o) => o.id === orderId);
  expect(found).toBeTruthy();
  expect(found.status).toBe("AWAITING_PAYMENT");
});

test("pedido Boleto (AWAITING_PAYMENT) aparece na tela de vendas", async () => {
  const { orderId } = await criarPedidoPago(
    `user-bol-v-${Date.now()}`,
    "BOLETO",
  );

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  const orders: any[] = await res.json();
  const found = orders.find((o) => o.id === orderId);
  expect(found).toBeTruthy();
  expect(found.status).toBe("AWAITING_PAYMENT");
});

test("pedido retorna itens com produto e pagamento", async () => {
  const { orderId } = await criarPedidoPago(`user-data-v-${Date.now()}`, "PIX");

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  const orders: any[] = await res.json();
  const order = orders.find((o) => o.id === orderId);

  expect(Array.isArray(order.items)).toBe(true);
  expect(order.items.length).toBeGreaterThan(0);
  expect(order.items[0].product).toBeTruthy();
  expect(order.payments).toBeTruthy();
});

test("pedido de entrega (DELIVERY) inclui endereço no payment", async () => {
  const userId = `user-deliv-v-${Date.now()}`;
  const { orderId } = await criarPedidoPago(
    userId,
    "PIX",
    "DELIVERY",
    "Av. Paulista, 1000",
  );

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  const orders: any[] = await res.json();
  const order = orders.find((o) => o.id === orderId);

  expect(order).toBeTruthy();
  const payment = order.payments?.[0];
  expect(payment?.deliveryMethod).toBe("DELIVERY");
  expect(payment?.deliveryAddress).toBe("Av. Paulista, 1000");
});

test("fluxo completo: confirmar pedido → preparar → pronto → entregar", async () => {
  const userId = `user-full-v-${Date.now()}`;
  const initialStock = 100;

  const prodBefore = await (
    await api.get(`/marketplace/products/${productId}`)
  ).json();
  const stockBefore = prodBefore.stock as number;

  const { orderId } = await criarPedidoPago(userId, "PIX");

  let res = await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "PREPARING" },
  });
  expect(res.status()).toBe(200);
  expect((await res.json()).deliveryStatus).toBe("PREPARING");

  res = await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "READY" },
  });
  expect((await res.json()).deliveryStatus).toBe("READY");

  const prodMid = await (
    await api.get(`/marketplace/products/${productId}`)
  ).json();
  expect(prodMid.stock).toBe(stockBefore);

  res = await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "DELIVERED" },
  });
  expect((await res.json()).deliveryStatus).toBe("DELIVERED");

  const prodAfter = await (
    await api.get(`/marketplace/products/${productId}`)
  ).json();
  expect(prodAfter.stock).toBe(stockBefore - 1);
});

test("pedido DELIVERED continua visível (status CONFIRMED) com deliveryStatus=DELIVERED", async () => {
  const userId = `user-done-v-${Date.now()}`;
  const { orderId } = await criarPedidoPago(userId, "PIX");

  await api.patch(`/marketplace/orders/${orderId}/delivery`, {
    data: { deliveryStatus: "DELIVERED" },
  });

  const res = await api.get(`/marketplace/orders/establishment/${ESTAB_ID}`);
  const orders: any[] = await res.json();
  const order = orders.find((o) => o.id === orderId);
  expect(order).toBeTruthy();
  expect(order.status).toBe("CONFIRMED");
  expect(order.deliveryStatus).toBe("DELIVERED");
});
