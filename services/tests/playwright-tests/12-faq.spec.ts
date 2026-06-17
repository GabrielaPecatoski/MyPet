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
let cliente: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  admin = await getAdmin(api);
  cliente = await registerUser(api, { role: "CLIENTE" });
});

test.afterAll(async () => {
  await api.dispose();
});

test("GET /faq (público) retorna array", async () => {
  const res = await api.get("/faq");
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("GET /faq/categories (público) retorna array", async () => {
  const res = await api.get("/faq/categories");
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("POST /faq/admin (admin) cria uma FAQ", async () => {
  const pergunta = `Como funciona a entrega? ${Date.now()}`;
  const res = await api.post("/faq/admin", {
    headers: authHeader(admin),
    data: {
      question: pergunta,
      answer: "A entrega é feita por motoristas parceiros.",
      category: "Entrega",
    },
  });
  expect([200, 201]).toContain(res.status());

  const faqs: any[] = await (await api.get("/faq")).json();
  expect(faqs.some((f) => f.question === pergunta)).toBe(true);
});

test("criar FAQ sem permissão de admin retorna 403", async () => {
  const res = await api.post("/faq/admin", {
    headers: authHeader(cliente),
    data: { question: "x", answer: "y" },
  });
  expect(res.status()).toBe(403);
});

test("POST /faq/questions (cliente) envia uma pergunta", async () => {
  const res = await api.post("/faq/questions", {
    headers: authHeader(cliente),
    data: { question: `Vocês atendem aos domingos? ${Date.now()}` },
  });
  expect([200, 201]).toContain(res.status());
});

test("GET /faq/questions/user/:id lista as perguntas do usuário", async () => {
  const res = await api.get(`/faq/questions/user/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBeGreaterThan(0);
});

test("enviar pergunta sem token retorna 401", async () => {
  const res = await api.post("/faq/questions", {
    data: { question: "sem auth" },
  });
  expect(res.status()).toBe(401);
});
