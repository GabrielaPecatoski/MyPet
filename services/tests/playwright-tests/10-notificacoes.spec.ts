import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3006";

let api: APIRequestContext;
const userId = `user-notif-${Date.now()}`;
let notifId: string;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test("usuário sem notificações retorna array vazio", async () => {
  const res = await api.get(`/notifications/user/${userId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("contagem de não lidas começa em 0", async () => {
  const res = await api.get(`/notifications/user/${userId}/unread`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.count).toBe(0);
});

test("criar notificação", async () => {
  const res = await api.post("/notifications", {
    data: {
      userId,
      title: "Pedido confirmado",
      body: "Seu pedido foi confirmado com sucesso!",
      type: "ORDER",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.userId).toBe(userId);
  expect(body.read).toBe(false);
  notifId = body.id;
});

test("criar segunda notificação", async () => {
  const res = await api.post("/notifications", {
    data: {
      userId,
      title: "Agendamento confirmado",
      body: "Seu banho e tosa está confirmado para amanhã.",
      type: "BOOKING",
    },
  });
  expect(res.status()).toBe(201);
});

test("listar notificações retorna as criadas", async () => {
  const res = await api.get(`/notifications/user/${userId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.length).toBe(2);
  expect(body.some((n) => n.id === notifId)).toBe(true);
});

test("contagem de não lidas é 2", async () => {
  const res = await api.get(`/notifications/user/${userId}/unread`);
  const body = await res.json();
  expect(body.count).toBe(2);
});

test("marcar notificação como lida", async () => {
  const res = await api.patch(`/notifications/${notifId}/read`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.read).toBe(true);
});

test("contagem de não lidas cai para 1", async () => {
  const res = await api.get(`/notifications/user/${userId}/unread`);
  const body = await res.json();
  expect(body.count).toBe(1);
});

test("marcar todas como lidas", async () => {
  const res = await api.patch(`/notifications/user/${userId}/read-all`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.ok).toBe(true);
});

test("contagem de não lidas é 0 após marcar todas", async () => {
  const res = await api.get(`/notifications/user/${userId}/unread`);
  const body = await res.json();
  expect(body.count).toBe(0);
});

test("todas as notificações aparecem como lidas", async () => {
  const res = await api.get(`/notifications/user/${userId}`);
  const body: any[] = await res.json();
  expect(body.every((n) => n.read === true)).toBe(true);
});
