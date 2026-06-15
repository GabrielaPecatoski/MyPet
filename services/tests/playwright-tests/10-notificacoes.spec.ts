import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  getAdmin,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let admin: SeededUser;
let user: SeededUser;
let notifId: string;

test.beforeAll(async () => {
  api = await apiContext();
  admin = await getAdmin(api);
  user = await registerUser(api, { role: "CLIENTE" });
});

test.afterAll(async () => {
  await api.dispose();
});

test("GET /notifications/user/:id começa vazio", async () => {
  const res = await api.get(`/notifications/user/${user.id}`, {
    headers: authHeader(user),
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("notificações exigem autenticação (401 sem token)", async () => {
  const res = await api.get(`/notifications/user/${user.id}`);
  expect(res.status()).toBe(401);
});

test("POST /notifications (admin) cria notificação para o usuário", async () => {
  const res = await api.post("/notifications", {
    headers: authHeader(admin),
    data: {
      userId: user.id,
      title: "Pedido confirmado",
      body: "Seu pedido foi confirmado.",
      type: "ORDER",
    },
  });
  expect([200, 201]).toContain(res.status());
});

test("usuário comum não pode criar notificação (403)", async () => {
  const res = await api.post("/notifications", {
    headers: authHeader(user),
    data: { userId: user.id, title: "x", body: "y", type: "ORDER" },
  });
  expect(res.status()).toBe(403);
});

test("GET /notifications/user/:id lista a notificação criada", async () => {
  const body: any[] = await (
    await api.get(`/notifications/user/${user.id}`, {
      headers: authHeader(user),
    })
  ).json();
  expect(body.length).toBeGreaterThan(0);
  notifId = body[0].id ?? body[0]._id;
  expect(notifId).toBeTruthy();
});

test("GET /notifications/user/:id/unread retorna a contagem de não lidas", async () => {
  const res = await api.get(`/notifications/user/${user.id}/unread`, {
    headers: authHeader(user),
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.count).toBeGreaterThan(0);
});

test("marcar como lida exige NOTIFICATIONS_WRITE (cliente recebe 403)", async () => {
  const res = await api.patch(`/notifications/${notifId}/read`, {
    headers: authHeader(user),
  });
  expect(res.status()).toBe(403);
});

test("PATCH /notifications/:id/read marca como lida (admin, 204)", async () => {
  const res = await api.patch(`/notifications/${notifId}/read`, {
    headers: authHeader(admin),
  });
  expect(res.status()).toBe(204);
});

test("PATCH /notifications/user/:id/read-all zera as não lidas (admin)", async () => {
  const res = await api.patch(`/notifications/user/${user.id}/read-all`, {
    headers: authHeader(admin),
  });
  expect(res.status()).toBe(204);
  const unread = await (
    await api.get(`/notifications/user/${user.id}/unread`, {
      headers: authHeader(user),
    })
  ).json();
  expect(unread.count).toBe(0);
});
