import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;
let productId: string;
const productName = `Ração Teste ${Date.now()}`;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Produtos",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop API ${Date.now()}`,
  });
  estabId = estab.id;
});

test.afterAll(async () => {
  await api.dispose();
});

test("GET /marketplace/products (público) retorna array", async () => {
  const res = await api.get("/marketplace/products");
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("POST /marketplace/products cria produto (auth do vendedor)", async () => {
  const res = await api.post("/marketplace/products", {
    headers: authHeader(owner),
    data: {
      name: productName,
      brand: "Marca Teste",
      price: 49.9,
      stock: 10,
      category: "Alimentação",
      establishmentId: estabId,
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.name).toBe(productName);
  expect(body.stock).toBe(10);
  productId = body.id;
});

test("POST /marketplace/products sem token retorna 401", async () => {
  const res = await api.post("/marketplace/products", {
    data: { name: "Sem Auth", price: 1, establishmentId: estabId },
  });
  expect(res.status()).toBe(401);
});

test("GET /marketplace/products/:id (público) retorna o produto", async () => {
  const res = await api.get(`/marketplace/products/${productId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(productId);
  expect(body.name).toBe(productName);
});

test("GET /marketplace/products/establishment/:id lista do estabelecimento", async () => {
  const res = await api.get(`/marketplace/products/establishment/${estabId}`, {
    headers: authHeader(owner),
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === productId)).toBe(true);
});

test("GET /marketplace/products?search= encontra por nome", async () => {
  const keyword = productName.split(" ")[1];
  const res = await api.get(`/marketplace/products?search=${keyword}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === productId)).toBe(true);
});

test("PATCH /marketplace/products/:id atualiza preço e estoque (204)", async () => {
  const res = await api.patch(`/marketplace/products/${productId}`, {
    headers: authHeader(owner),
    data: { price: 55.0, stock: 20 },
  });
  expect(res.status()).toBe(204);
  const after = await (
    await api.get(`/marketplace/products/${productId}`)
  ).json();
  expect(after.price).toBe(55.0);
  expect(after.stock).toBe(20);
});

test("DELETE de produto inexistente retorna 404", async () => {
  const res = await api.delete(
    "/marketplace/products/00000000-0000-0000-0000-000000000000",
    { headers: authHeader(owner) },
  );
  expect(res.status()).toBe(404);
});

test("DELETE /marketplace/products/:id remove o produto (204)", async () => {
  const res = await api.delete(`/marketplace/products/${productId}`, {
    headers: authHeader(owner),
  });
  expect(res.status()).toBe(204);
});

test("produto excluído não aparece na listagem pública", async () => {
  const res = await api.get("/marketplace/products");
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === productId)).toBe(false);
});
