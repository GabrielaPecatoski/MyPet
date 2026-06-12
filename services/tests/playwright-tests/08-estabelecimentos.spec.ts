import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3003";

let api: APIRequestContext;
const ownerId = `owner-${Date.now()}`;
let estabId: string;
let serviceId: string;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test("listar estabelecimentos retorna array", async () => {
  const res = await api.get("/establishments");
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
});

test("listar por owner sem estabelecimento retorna array vazio", async () => {
  const res = await api.get(`/establishments/owner/${ownerId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("criar estabelecimento", async () => {
  const res = await api.post(`/establishments/owner/${ownerId}`, {
    data: {
      name: `PetShop Teste ${Date.now()}`,
      description: "Descrição de teste",
      address: "Rua das Flores, 100",
      city: "Curitiba",
      phone: "41999998888",
      type: "PET_SHOP",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.ownerId).toBe(ownerId);
  estabId = body.id;
});

test("buscar estabelecimento por id", async () => {
  const res = await api.get(`/establishments/${estabId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(estabId);
});

test("buscar por owner retorna o estabelecimento criado", async () => {
  const res = await api.get(`/establishments/owner/${ownerId}`);
  const body: any[] = await res.json();
  expect(body.some((e) => e.id === estabId)).toBe(true);
});

test("buscar por search filtra por nome", async () => {
  const res = await api.get("/establishments?search=PetShop Teste");
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((e) => e.id === estabId)).toBe(true);
});

test("buscar estabelecimento inexistente retorna 404", async () => {
  const res = await api.get("/establishments/id-invalido-xyz");
  expect(res.status()).toBe(404);
});

test("atualizar estabelecimento", async () => {
  const res = await api.patch(`/establishments/${estabId}`, {
    data: { description: "Descrição atualizada", city: "São Paulo" },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.description).toBe("Descrição atualizada");
  expect(body.city).toBe("São Paulo");
});

test("adicionar serviço ao estabelecimento", async () => {
  // POST retorna o estabelecimento completo com os serviços
  const res = await api.post(`/establishments/${estabId}/services`, {
    data: {
      name: "Banho e Tosa",
      price: 80.0,
      durationMinutes: 60,
      description: "Banho completo com tosa",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  // resposta é o estabelecimento; pegamos o último serviço adicionado
  expect(Array.isArray(body.services)).toBe(true);
  expect(body.services.length).toBeGreaterThan(0);
  serviceId = body.services[body.services.length - 1].id;
});

test("estabelecimento com serviço aparece ao buscar por id", async () => {
  const res = await api.get(`/establishments/${estabId}`);
  const body = await res.json();
  expect(body.services?.some((s: any) => s.id === serviceId)).toBe(true);
});

test("buscar estatísticas do estabelecimento", async () => {
  const res = await api.get(`/establishments/${estabId}/stats`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  // campos reais: totalBookings, avgRating, totalReviews
  expect(typeof body.totalBookings).toBe("number");
  expect(typeof body.avgRating).toBe("number");
});

test("remover serviço do estabelecimento", async () => {
  const res = await api.delete(
    `/establishments/${estabId}/services/${serviceId}`,
  );
  expect(res.status()).toBe(200);
});

test("deletar estabelecimento", async () => {
  const res = await api.delete(`/establishments/${estabId}`);
  expect(res.status()).toBe(204);
});
