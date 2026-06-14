import { APIRequestContext, expect, test } from "@playwright/test";
import {
  addToCart,
  apiContext,
  checkoutOrder,
  createEstablishment,
  createProduct,
  payOrder,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;
let productId: string;

async function pedidoPago(
  deliveryMethod = "PICKUP",
): Promise<{ cliente: SeededUser; orderId: string }> {
  const cliente = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliente, productId, 1);
  const order = await checkoutOrder(api, cliente);
  await payOrder(api, cliente, order.id, { method: "PIX", deliveryMethod });
  return { cliente, orderId: order.id };
}

async function advance(orderId: string) {
  return api.patch(`/marketplace/orders/${orderId}/advance`, {
    headers: authHeader(owner),
  });
}

async function statusDo(orderId: string, cliente: SeededUser): Promise<string> {
  const orders: any[] = await (
    await api.get(`/marketplace/orders/${cliente.id}`, {
      headers: authHeader(cliente),
    })
  ).json();
  return orders.find((o) => o.id === orderId)?.status;
}

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Entrega",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Entrega ${Date.now()}`,
  });
  estabId = estab.id;
  const product = await createProduct(api, owner, estabId, {
    name: `Produto Entrega ${Date.now()}`,
    price: 40,
    stock: 100,
  });
  productId = product.id;
});

test.afterAll(async () => {
  await api.dispose();
});

test("pedido pago entra em ENVIANDO", async () => {
  const { cliente, orderId } = await pedidoPago();
  expect(await statusDo(orderId, cliente)).toBe("ENVIANDO");
});

test("ciclo de avanço: ENVIANDO → A_CAMINHO → FINALIZADO", async () => {
  const { cliente, orderId } = await pedidoPago();

  let res = await advance(orderId);
  expect(res.status()).toBe(200);
  expect((await res.json()).status).toBe("A_CAMINHO");

  res = await advance(orderId);
  expect(res.status()).toBe(200);
  expect((await res.json()).status).toBe("FINALIZADO");

  expect(await statusDo(orderId, cliente)).toBe("FINALIZADO");
});

test("avançar além de FINALIZADO retorna 400", async () => {
  const { orderId } = await pedidoPago();
  await advance(orderId); // A_CAMINHO
  await advance(orderId); // FINALIZADO
  const res = await advance(orderId);
  expect(res.status()).toBe(400);
});

test("avançar pedido inexistente retorna 404", async () => {
  const res = await api.patch(
    "/marketplace/orders/00000000-0000-0000-0000-000000000000/advance",
    { headers: authHeader(owner) },
  );
  expect(res.status()).toBe(404);
});

test("método e endereço de entrega são preservados", async () => {
  const cliente = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliente, productId, 1);
  const order = await checkoutOrder(api, cliente);
  await payOrder(api, cliente, order.id, {
    method: "PIX",
    deliveryMethod: "DELIVERY",
    deliveryAddress: "Av. Paulista, 1000",
  });
  const orders: any[] = await (
    await api.get(`/marketplace/orders/${cliente.id}`, {
      headers: authHeader(cliente),
    })
  ).json();
  const o = orders.find((x) => x.id === order.id);
  expect(o.deliveryMethod).toBe("DELIVERY");
  expect(o.deliveryAddress).toBe("Av. Paulista, 1000");
});
