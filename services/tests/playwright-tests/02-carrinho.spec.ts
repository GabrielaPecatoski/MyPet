import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  createProduct,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let cliente: SeededUser;
let estabId: string;
let productId: string;
let orderId: string;

test.beforeAll(async () => {
  api = await apiContext();
  const owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Carrinho",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Carrinho ${Date.now()}`,
  });
  estabId = estab.id;
  const product = await createProduct(api, owner, estabId, {
    name: `Produto Carrinho ${Date.now()}`,
    price: 30,
    stock: 50,
  });
  productId = product.id;
  cliente = await registerUser(api, { role: "CLIENTE" });
});

test.afterAll(async () => {
  await api.delete(`/marketplace/cart/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  await api.dispose();
});

test("GET carrinho começa vazio", async () => {
  const res = await api.get(`/marketplace/cart/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("carrinho exige autenticação (401 sem token)", async () => {
  const res = await api.get(`/marketplace/cart/${cliente.id}`);
  expect(res.status()).toBe(401);
});

async function getCart(): Promise<any[]> {
  return (
    await api.get(`/marketplace/cart/${cliente.id}`, {
      headers: authHeader(cliente),
    })
  ).json();
}

test("POST adiciona item ao carrinho", async () => {
  const res = await api.post(`/marketplace/cart/${cliente.id}`, {
    headers: authHeader(cliente),
    data: { productId, quantity: 2 },
  });
  expect(res.status()).toBe(201);
  const cart = await getCart();
  expect(cart.find((i) => i.productId === productId)?.quantity).toBe(2);
});

test("adicionar o mesmo item define a nova quantidade (upsert)", async () => {
  const res = await api.post(`/marketplace/cart/${cliente.id}`, {
    headers: authHeader(cliente),
    data: { productId, quantity: 4 },
  });
  expect(res.status()).toBe(201);
  const cart = await getCart();
  expect(cart.find((i) => i.productId === productId)?.quantity).toBe(4);
});

test("PATCH atualiza a quantidade do item (204)", async () => {
  const res = await api.patch(`/marketplace/cart/${cliente.id}/${productId}`, {
    headers: authHeader(cliente),
    data: { quantity: 5 },
  });
  expect(res.status()).toBe(204);
  const cart: any[] = await (
    await api.get(`/marketplace/cart/${cliente.id}`, {
      headers: authHeader(cliente),
    })
  ).json();
  expect(cart.find((i) => i.productId === productId)?.quantity).toBe(5);
});

test("DELETE remove um item específico do carrinho (204)", async () => {
  const res = await api.delete(
    `/marketplace/cart/${cliente.id}/${productId}`,
    { headers: authHeader(cliente) },
  );
  expect(res.status()).toBe(204);
  const cart: any[] = await (
    await api.get(`/marketplace/cart/${cliente.id}`, {
      headers: authHeader(cliente),
    })
  ).json();
  expect(cart.some((i) => i.productId === productId)).toBe(false);
});

test("checkout com carrinho vazio retorna 400", async () => {
  const res = await api.post(`/marketplace/orders/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(400);
});

test("checkout cria pedido (AGUARDANDO_PAGAMENTO) e limpa o carrinho", async () => {
  await api.post(`/marketplace/cart/${cliente.id}`, {
    headers: authHeader(cliente),
    data: { productId, quantity: 2 },
  });
  const res = await api.post(`/marketplace/orders/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.status).toBe("AGUARDANDO_PAGAMENTO");
  expect(body.total).toBeGreaterThan(0);
  expect(Array.isArray(body.items)).toBe(true);
  orderId = body.id;

  const cart: any[] = await (
    await api.get(`/marketplace/cart/${cliente.id}`, {
      headers: authHeader(cliente),
    })
  ).json();
  expect(cart.length).toBe(0);
});

test("GET pedidos do usuário inclui o pedido criado", async () => {
  const res = await api.get(`/marketplace/orders/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((o) => o.id === orderId)).toBe(true);
});
