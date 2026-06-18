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

async function pedidoPago(opts: {
  qty?: number;
  deliveryMethod?: string;
  deliveryAddress?: string;
}): Promise<string> {
  const cliente = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliente, productId, opts.qty ?? 1);
  const order = await checkoutOrder(api, cliente);
  await payOrder(api, cliente, order.id, {
    method: "PIX",
    deliveryMethod: opts.deliveryMethod ?? "PICKUP",
    deliveryAddress: opts.deliveryAddress,
  });
  return order.id;
}

async function pedidosDoEstab(): Promise<any[]> {
  return (
    await api.get(`/marketplace/orders/establishment/${estabId}`, {
      headers: authHeader(owner),
    })
  ).json();
}

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Vendas",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Vendas ${Date.now()}`,
  });
  estabId = estab.id;
  const product = await createProduct(api, owner, estabId, {
    name: `Produto Vendas ${Date.now()}`,
    price: 50,
    stock: 100,
  });
  productId = product.id;
});

test.afterAll(async () => {
  await api.dispose();
});

test("listagem de vendas exige autenticação (401 sem token)", async () => {
  const res = await api.get(`/marketplace/orders/establishment/${estabId}`);
  expect(res.status()).toBe(401);
});

test("pedido pago aparece na tela de vendas do estabelecimento (ENVIANDO)", async () => {
  const orderId = await pedidoPago({});
  const res = await api.get(
    `/marketplace/orders/establishment/${estabId}`,
    { headers: authHeader(owner) },
  );
  expect(res.status()).toBe(200);
  const orders: any[] = await res.json();
  const found = orders.find((o) => o.id === orderId);
  expect(found).toBeTruthy();
  expect(found.status).toBe("ENVIANDO");
});

test("pedido traz itens com produto, quantidade e preço", async () => {
  const orderId = await pedidoPago({ qty: 2 });
  const order = (await pedidosDoEstab()).find((o) => o.id === orderId);
  expect(Array.isArray(order.items)).toBe(true);
  const item = order.items[0];
  expect(item.productId).toBe(productId);
  expect(item.quantity).toBe(2);
  expect(item.price).toBeGreaterThan(0);
  expect(order.total).toBeGreaterThan(0);
});

test("pedido de entrega traz método e endereço", async () => {
  const orderId = await pedidoPago({
    deliveryMethod: "DELIVERY",
    deliveryAddress: "Av. Paulista, 1000",
  });
  const order = (await pedidosDoEstab()).find((o) => o.id === orderId);
  expect(order.deliveryMethod).toBe("DELIVERY");
  expect(order.deliveryAddress).toBe("Av. Paulista, 1000");
});

test("avanço do pedido reflete na tela de vendas", async () => {
  const orderId = await pedidoPago({});
  await api.patch(`/marketplace/orders/${orderId}/advance`, {
    headers: authHeader(owner),
  });
  const order = (await pedidosDoEstab()).find((o) => o.id === orderId);
  expect(order.status).toBe("A_CAMINHO");
});
