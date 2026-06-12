import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3004";
const ESTAB_ID = "estab-pag-test";

let api: APIRequestContext;

async function createOrderForUser(
  userId: string,
  price = 100.0,
): Promise<string> {
  const prodRes = await api.post("/marketplace/products", {
    data: {
      name: `Prod Pag ${Date.now()}`,
      price,
      stock: 20,
      establishmentId: ESTAB_ID,
    },
  });
  const prod = await prodRes.json();

  await api.post(`/marketplace/cart/${userId}`, {
    data: { productId: prod.id, quantity: 1 },
  });

  const orderRes = await api.post(`/marketplace/orders/${userId}`);
  const order = await orderRes.json();
  return order.id;
}

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test("pagamento PIX é aprovado imediatamente", async () => {
  const userId = `user-pix-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const res = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.status).toBe("APPROVED");
  expect(body.pixKey).toMatch(/mypet-/);
});

test("pagamento PIX atualiza pedido para CONFIRMED", async () => {
  const userId = `user-pix2-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });

  const orders: any[] = await (
    await api.get(`/marketplace/orders/${userId}`)
  ).json();
  const order = orders.find((o) => o.id === orderId);
  expect(order?.status).toBe("CONFIRMED");
});

test("pagamento no débito é aprovado", async () => {
  const userId = `user-deb-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const res = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "DEBIT_CARD",
      cardNumber: "4111111111111111",
      deliveryMethod: "PICKUP",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.status).toBe("APPROVED");
  expect(body.cardLastFour).toBe("1111");
});

test("pagamento em dinheiro fica PENDING (AWAITING_PAYMENT)", async () => {
  const userId = `user-cash-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const res = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "CASH",
      deliveryMethod: "PICKUP",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.status).toBe("PENDING");

  const orders: any[] = await (
    await api.get(`/marketplace/orders/${userId}`)
  ).json();
  const order = orders.find((o) => o.id === orderId);
  expect(order?.status).toBe("AWAITING_PAYMENT");
});

test("pagamento por boleto fica PENDING e gera código", async () => {
  const userId = `user-boleto-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const res = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "BOLETO",
      deliveryMethod: "DELIVERY",
      deliveryAddress: "Rua Teste, 123",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.status).toBe("PENDING");
  expect(body.boletoCode).toBeTruthy();
  expect(body.deliveryMethod).toBe("DELIVERY");
  expect(body.deliveryAddress).toBe("Rua Teste, 123");
});

test("pagamento crédito retorna APPROVED ou REJECTED (simulação)", async () => {
  const userId = `user-cc-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const res = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "CREDIT_CARD",
      cardNumber: "5500000000000004",
      installments: 3,
      deliveryMethod: "PICKUP",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(["APPROVED", "REJECTED"]).toContain(body.status);
  expect(body.cardLastFour).toBe("0004");
  if (body.status === "REJECTED") {
    expect(body.rejectionReason).toBeTruthy();
  }
});

test("buscar pagamento por id", async () => {
  const userId = `user-findpay-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
  const payment = await payRes.json();

  const res = await api.get(`/marketplace/payments/${payment.id}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(payment.id);
  expect(body.order).toBeTruthy();
});

test("buscar pagamentos por usuário", async () => {
  const userId = `user-listpay-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
  const payment = await payRes.json();

  const res = await api.get(`/marketplace/payments/user/${userId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === payment.id)).toBe(true);
});

test("buscar pagamentos por pedido", async () => {
  const userId = `user-orderpay-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
  const payment = await payRes.json();

  const res = await api.get(`/marketplace/payments/order/${orderId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === payment.id)).toBe(true);
});

test("cancelar pagamento PENDING", async () => {
  const userId = `user-cancel-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "CASH",
      deliveryMethod: "PICKUP",
    },
  });
  const payment = await payRes.json();
  expect(payment.status).toBe("PENDING");

  const res = await api.patch(`/marketplace/payments/${payment.id}/cancel`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.status).toBe("CANCELLED");
});

test("estornar pagamento APPROVED", async () => {
  const userId = `user-refund-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
  const payment = await payRes.json();
  expect(payment.status).toBe("APPROVED");

  const res = await api.patch(`/marketplace/payments/${payment.id}/refund`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.status).toBe("REFUNDED");
});

test("não pode cancelar pagamento APPROVED", async () => {
  const userId = `user-cancelapproved-${Date.now()}`;
  const orderId = await createOrderForUser(userId);

  const payRes = await api.post("/marketplace/payments", {
    data: {
      orderId,
      userId,
      amount: 100.0,
      method: "PIX",
      deliveryMethod: "PICKUP",
    },
  });
  const payment = await payRes.json();

  const res = await api.patch(`/marketplace/payments/${payment.id}/cancel`);
  expect(res.status()).toBe(400);
});
