import { APIRequestContext, expect, test } from "@playwright/test";
import {
  addService,
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Estabelecimentos",
  });
});

test.afterAll(async () => {
  await api.dispose();
});

test("GET /establishments (público) retorna array", async () => {
  const res = await api.get("/establishments");
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("GET /establishments/emergency (público) retorna array", async () => {
  const res = await api.get("/establishments/emergency");
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("POST /establishments/owner/:id cria estabelecimento (auth)", async () => {
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop API ${Date.now()}`,
  });
  expect(estab.id).toBeTruthy();
  estabId = estab.id;
});

test("criar estabelecimento sem token retorna 401", async () => {
  const res = await api.post(`/establishments/owner/${owner.id}`, {
    data: { name: "Sem Auth", address: "x", city: "y", type: "PET_SHOP" },
  });
  expect(res.status()).toBe(401);
});

test("GET /establishments/:id (público) retorna o estabelecimento", async () => {
  const res = await api.get(`/establishments/${estabId}`);
  expect(res.status()).toBe(200);
  expect((await res.json()).id).toBe(estabId);
});

test("GET /establishments/owner/:id lista os do dono (auth)", async () => {
  const res = await api.get(`/establishments/owner/${owner.id}`, {
    headers: authHeader(owner),
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((e) => e.id === estabId)).toBe(true);
});

test("PATCH /establishments/:id atualiza (204)", async () => {
  const novoNome = `Pet Shop Renomeado ${Date.now()}`;
  const res = await api.patch(`/establishments/${estabId}`, {
    headers: authHeader(owner),
    data: { name: novoNome },
  });
  expect(res.status()).toBe(204);
  const after = await (await api.get(`/establishments/${estabId}`)).json();
  expect(after.name).toBe(novoNome);
});

test("serviços do estabelecimento: criar e listar (público)", async () => {
  const service = await addService(api, owner, estabId, {
    name: `Banho API ${Date.now()}`,
    price: 80,
  });
  expect(service.name).toContain("Banho API");

  const res = await api.get(`/establishments/${estabId}/services`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((s) => s.name === service.name)).toBe(true);
});
