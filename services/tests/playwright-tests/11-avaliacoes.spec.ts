import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let cliente: SeededUser;
let estabId: string;

test.beforeAll(async () => {
  api = await apiContext();
  const owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Avaliacoes",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Avaliacoes ${Date.now()}`,
  });
  estabId = estab.id;
  cliente = await registerUser(api, { role: "CLIENTE" });
});

test.afterAll(async () => {
  await api.dispose();
});

test("GET /reviews/establishment/:id (público) retorna array", async () => {
  const res = await api.get(`/reviews/establishment/${estabId}`);
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("GET /reviews/establishment/:id/stats (público) retorna estatísticas", async () => {
  const res = await api.get(`/reviews/establishment/${estabId}/stats`);
  expect(res.status()).toBe(200);
  expect(await res.json()).toBeTruthy();
});

test("POST /reviews/establishment/:id cria avaliação (auth cliente)", async () => {
  const res = await api.post(`/reviews/establishment/${estabId}`, {
    headers: authHeader(cliente),
    data: { rating: 5, comment: "Excelente atendimento!" },
  });
  expect([200, 201, 204]).toContain(res.status());
});

test("avaliação sem token retorna 401", async () => {
  const res = await api.post(`/reviews/establishment/${estabId}`, {
    data: { rating: 4 },
  });
  expect(res.status()).toBe(401);
});

test("a avaliação criada aparece na listagem do estabelecimento", async () => {
  const body: any[] = await (
    await api.get(`/reviews/establishment/${estabId}`)
  ).json();
  expect(body.some((r) => (r.rating ?? r._rating) === 5)).toBe(true);
});

test("GET /reviews/user/me lista as avaliações do cliente", async () => {
  const res = await api.get("/reviews/user/me", {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("stats refletem a avaliação (média > 0)", async () => {
  const stats = await (
    await api.get(`/reviews/establishment/${estabId}/stats`)
  ).json();
  const avg = stats.average ?? stats.averageRating ?? stats.media ?? 0;
  expect(Number(avg)).toBeGreaterThan(0);
});
