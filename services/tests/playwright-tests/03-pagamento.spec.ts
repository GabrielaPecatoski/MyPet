import { APIRequestContext, expect, test } from "@playwright/test";
import {
  addToCart,
  apiContext,
  checkoutOrder,
  createEstablishment,
  createProduct,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;
let productId: string;

// cada pagamento muda o status do pedido, então cada teste usa um pedido novo
async function novoPedido(): Promise<{ cliente: SeededUser; orderId: string }> {
  const cliente = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliente, productId, 1);
  const order = await checkoutOrder(api, cliente);
  return { cliente, orderId: order.id };
}

async function pagar(
  cliente: SeededUser,
  data: Record<string, unknown>,
): Promise<{ status: number; body: any }> {
  const res = await api.post("/marketplace/payments", {
    headers: authHeader(cliente),
    data,
  });
  return { status: res.status(), body: await res.json() };
}

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Pagamento",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Pagamento ${Date.now()}`,
  });
  estabId = estab.id;
  const product = await createProduct(api, owner, estabId, {
    name: `Produto Pagamento ${Date.now()}`,
    price: 100,
    stock: 100,
  });
  productId = product.id;
});

test.afterAll(async () => {
  await api.dispose();
});

test("PIX é aprovado e move o pedido para ENVIANDO", async () => {
  const { cliente, orderId } = await novoPedido();
  const { status, body } = await pagar(cliente, {
    orderId,
    method: "PIX",
    deliveryMethod: "PICKUP",
  });
  expect([200, 201]).toContain(status);
  expect(body.payment.status).toBe("APPROVED");
  expect(body.payment.pixKey).toBe("mypet@pagamentos.com");
  expect(body.order.status).toBe("ENVIANDO");
});

test("débito aprovado retorna os 4 últimos dígitos", async () => {
  const { cliente, orderId } = await novoPedido();
  const { body } = await pagar(cliente, {
    orderId,
    method: "DEBIT_CARD",
    cardNumber: "4111111111111111",
    deliveryMethod: "PICKUP",
  });
  expect(body.payment.status).toBe("APPROVED");
  expect(body.payment.cardLastFour).toBe("1111");
});

test("boleto é aprovado e gera código", async () => {
  const { cliente, orderId } = await novoPedido();
  const { body } = await pagar(cliente, {
    orderId,
    method: "BOLETO",
    deliveryMethod: "DELIVERY",
    deliveryAddress: "Rua Teste, 123",
  });
  expect(body.payment.status).toBe("APPROVED");
  expect(body.payment.boletoCode).toBeTruthy();
  expect(body.order.deliveryMethod).toBe("DELIVERY");
});

test("crédito retorna APPROVED ou REJECTED (simulação)", async () => {
  const { cliente, orderId } = await novoPedido();
  const { body } = await pagar(cliente, {
    orderId,
    method: "CREDIT_CARD",
    cardNumber: "5500000000000004",
    installments: 3,
    deliveryMethod: "PICKUP",
  });
  expect(["APPROVED", "REJECTED"]).toContain(body.payment.status);
  if (body.payment.status === "APPROVED") {
    expect(body.payment.cardLastFour).toBe("0004");
  }
});

test("dinheiro é aprovado (método simulado)", async () => {
  const { cliente, orderId } = await novoPedido();
  const { body } = await pagar(cliente, {
    orderId,
    method: "CASH",
    deliveryMethod: "PICKUP",
  });
  expect(body.payment.status).toBe("APPROVED");
});

test("pagar pedido inexistente retorna 404", async () => {
  const cliente = await registerUser(api, { role: "CLIENTE" });
  const { status } = await pagar(cliente, {
    orderId: "00000000-0000-0000-0000-000000000000",
    method: "PIX",
  });
  expect(status).toBe(404);
});

test("pagamento exige autenticação (401 sem token)", async () => {
  const res = await api.post("/marketplace/payments", {
    data: { orderId: "x", method: "PIX" },
  });
  expect(res.status()).toBe(401);
});
