import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3008";
const ADMIN_SECRET = "mypet_admin_secret";

let api: APIRequestContext;
let faqId: string;
let questionId: string;
const userId = `user-faq-${Date.now()}`;

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

// ---- FAQs públicas ----

test("listar FAQs ativas retorna array", async () => {
  const res = await api.get("/faq");
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
});

test("listar categorias retorna array", async () => {
  const res = await api.get("/faq/categories");
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
});

// ---- admin: criar FAQ ----

test("criar FAQ sem admin secret retorna 403", async () => {
  const res = await api.post("/faq/admin", {
    headers: { "x-admin-secret": "errado" },
    data: { question: "Teste?", answer: "Sim." },
  });
  expect(res.status()).toBe(403);
});

test("criar FAQ com admin secret", async () => {
  const res = await api.post("/faq/admin", {
    headers: { "x-admin-secret": ADMIN_SECRET },
    data: {
      question: "Como fazer um agendamento?",
      answer: "Acesse o app e vá em Agendar.",
      category: "Agendamento",
      order: 1,
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.active).toBe(true);
  faqId = body.id;
});

test("FAQ criada aparece na listagem pública", async () => {
  const res = await api.get("/faq");
  const body: any[] = await res.json();
  expect(body.some((f) => f.id === faqId)).toBe(true);
});

test("filtrar FAQs por categoria", async () => {
  const res = await api.get("/faq?category=Agendamento");
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((f) => f.id === faqId)).toBe(true);
});

test("admin: listar todas as FAQs", async () => {
  const res = await api.get("/faq/admin/all", {
    headers: { "x-admin-secret": ADMIN_SECRET },
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((f) => f.id === faqId)).toBe(true);
});

test("admin: atualizar FAQ", async () => {
  const res = await api.put(`/faq/admin/${faqId}`, {
    headers: { "x-admin-secret": ADMIN_SECRET },
    data: { answer: "Acesse o app, vá em Agendar e escolha o serviço." },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.answer).toContain("escolha o serviço");
});

test("admin: desativar FAQ", async () => {
  const res = await api.put(`/faq/admin/${faqId}`, {
    headers: { "x-admin-secret": ADMIN_SECRET },
    data: { active: false },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.active).toBe(false);
});

test("FAQ inativa não aparece na listagem pública", async () => {
  const res = await api.get("/faq");
  const body: any[] = await res.json();
  expect(body.some((f) => f.id === faqId)).toBe(false);
});

test("admin: deletar FAQ", async () => {
  const res = await api.delete(`/faq/admin/${faqId}`, {
    headers: { "x-admin-secret": ADMIN_SECRET },
  });
  expect(res.status()).toBe(200);
});

// ---- perguntas de usuários ----

test("enviar pergunta de usuário", async () => {
  const res = await api.post("/faq/questions", {
    data: {
      userId,
      userName: "Usuário Teste",
      userRole: "CLIENTE",
      question: "Como cancelo meu agendamento?",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.status).toBe("OPEN");
  questionId = body.id;
});

test("listar perguntas do usuário", async () => {
  const res = await api.get(`/faq/questions/user/${userId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((q) => q.id === questionId)).toBe(true);
});

test("admin: listar todas as perguntas", async () => {
  const res = await api.get("/faq/questions/admin/all", {
    headers: { "x-admin-secret": ADMIN_SECRET },
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((q) => q.id === questionId)).toBe(true);
});

test("admin: filtrar perguntas por status OPEN", async () => {
  const res = await api.get("/faq/questions/admin/all?status=OPEN", {
    headers: { "x-admin-secret": ADMIN_SECRET },
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((q) => q.id === questionId)).toBe(true);
});

test("admin: responder pergunta", async () => {
  const res = await api.put(`/faq/questions/admin/${questionId}/answer`, {
    headers: { "x-admin-secret": ADMIN_SECRET },
    data: { answer: "Você pode cancelar em Meus Agendamentos até 24h antes." },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.answer).toBeTruthy();
  expect(body.status).toBe("ANSWERED");
});

test("admin: fechar pergunta", async () => {
  const res = await api.put(`/faq/questions/admin/${questionId}/close`, {
    headers: { "x-admin-secret": ADMIN_SECRET },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.status).toBe("CLOSED");
});

test("admin: responder sem texto retorna erro", async () => {
  // cria nova pergunta para testar
  const qRes = await api.post("/faq/questions", {
    data: {
      userId,
      userName: "Teste",
      userRole: "CLIENTE",
      question: "Outra dúvida?",
    },
  });
  const q = await qRes.json();

  const res = await api.put(`/faq/questions/admin/${q.id}/answer`, {
    headers: { "x-admin-secret": ADMIN_SECRET },
    data: { answer: "" },
  });
  expect(res.status()).toBeGreaterThanOrEqual(400);
});
