import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3002";

let api: APIRequestContext;
const userId = `user-pet-${Date.now()}`;
let petId: string;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test("listar pets de usuário sem pets retorna array vazio", async () => {
  const res = await api.get(`/pets/user/${userId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("criar pet", async () => {
  const res = await api.post(`/pets/user/${userId}`, {
    data: {
      name: "Rex",
      species: "Cachorro",
      breed: "Labrador",
      age: 3,
      weight: 25.5,
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.name).toBe("Rex");
  expect(body.userId).toBe(userId);
  petId = body.id;
});

test("listar pets retorna o pet criado", async () => {
  const res = await api.get(`/pets/user/${userId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === petId)).toBe(true);
});

test("buscar pet por id", async () => {
  const res = await api.get(`/pets/${petId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(petId);
  expect(body.name).toBe("Rex");
});

test("buscar pet inexistente retorna 404", async () => {
  const res = await api.get("/pets/id-invalido-xyz");
  expect(res.status()).toBe(404);
});

test("atualizar pet", async () => {
  const res = await api.patch(`/pets/${petId}`, {
    data: { name: "Rex Jr", weight: 28.0 },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.name).toBe("Rex Jr");
  expect(body.weight).toBe(28.0);
});

test("criar segundo pet para o mesmo usuário", async () => {
  const res = await api.post(`/pets/user/${userId}`, {
    data: { name: "Mia", species: "Gato", breed: "Siamês", age: 2 },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.name).toBe("Mia");
});

test("listar pets retorna ambos os pets", async () => {
  const res = await api.get(`/pets/user/${userId}`);
  const body: any[] = await res.json();
  expect(body.length).toBe(2);
});

test("deletar pet", async () => {
  const res = await api.delete(`/pets/${petId}`);
  expect(res.status()).toBe(204);
});

test("pet deletado não é encontrado", async () => {
  const res = await api.get(`/pets/${petId}`);
  expect(res.status()).toBe(404);
});
