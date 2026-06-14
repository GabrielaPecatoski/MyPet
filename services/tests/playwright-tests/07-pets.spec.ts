import { APIRequestContext, expect, test } from "@playwright/test";
import { apiContext, registerUser, SeededUser } from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let user: SeededUser;
let petId: string;

test.beforeAll(async () => {
  api = await apiContext();
  user = await registerUser(api, { role: "CLIENTE" });
});

test.afterAll(async () => {
  await api.dispose();
});

test("GET /pets/user/:id começa vazio", async () => {
  const res = await api.get(`/pets/user/${user.id}`, {
    headers: authHeader(user),
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("pets exigem autenticação (401 sem token)", async () => {
  const res = await api.get(`/pets/user/${user.id}`);
  expect(res.status()).toBe(401);
});

test("POST /pets/user/:id cria pet", async () => {
  const res = await api.post(`/pets/user/${user.id}`, {
    headers: authHeader(user),
    data: { name: "Rex", type: "Cachorro", breed: "Labrador", age: 3 },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.name).toBe("Rex");
  expect(body.userId).toBe(user.id);
  petId = body.id;
});

test("GET /pets/user/:id retorna o pet criado", async () => {
  const res = await api.get(`/pets/user/${user.id}`, {
    headers: authHeader(user),
  });
  const body: any[] = await res.json();
  expect(body.some((p) => p.id === petId)).toBe(true);
});

test("GET /pets/:id retorna o pet", async () => {
  const res = await api.get(`/pets/${petId}`, { headers: authHeader(user) });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(petId);
  expect(body.name).toBe("Rex");
});

test("PATCH /pets/:id atualiza o pet (204)", async () => {
  const res = await api.patch(`/pets/${petId}`, {
    headers: authHeader(user),
    data: { name: "Rex Atualizado", age: 4 },
  });
  expect(res.status()).toBe(204);
  const after = await (
    await api.get(`/pets/${petId}`, { headers: authHeader(user) })
  ).json();
  expect(after.name).toBe("Rex Atualizado");
  expect(after.age).toBe(4);
});

test("DELETE de pet inexistente retorna 404", async () => {
  const res = await api.delete(
    "/pets/00000000-0000-0000-0000-000000000000",
    { headers: authHeader(user) },
  );
  expect(res.status()).toBe(404);
});

test("DELETE /pets/:id remove o pet (204)", async () => {
  const res = await api.delete(`/pets/${petId}`, { headers: authHeader(user) });
  expect(res.status()).toBe(204);
  const list: any[] = await (
    await api.get(`/pets/user/${user.id}`, { headers: authHeader(user) })
  ).json();
  expect(list.some((p) => p.id === petId)).toBe(false);
});
