import { APIRequestContext, expect, test } from "@playwright/test";
import { apiContext } from "../playwright-front/_api";

let api: APIRequestContext;

const ts = Date.now();
const email = `apiauth${ts}@mypet.com`;
const cpf = `${ts}`.slice(-11).padStart(11, "0");
const password = "senha123";
let token: string;
let userId: string;

const authHeader = () => ({ Authorization: `Bearer ${token}` });

test.beforeAll(async () => {
  api = await apiContext();
});

test.afterAll(async () => {
  await api.dispose();
});

test("POST /auth/register cria usuário e retorna accessToken", async () => {
  const res = await api.post("/auth/register", {
    data: {
      name: "Usuário API",
      email,
      password,
      phone: "41999990000",
      cpf,
      role: "CLIENTE",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.accessToken).toBeTruthy();
  expect(body.user.email).toBe(email);
  expect(body.user.role).toBe("CLIENTE");
  token = body.accessToken;
  userId = body.user.id;
});

test("registro com email duplicado retorna 409", async () => {
  const res = await api.post("/auth/register", {
    data: {
      name: "Outro",
      email,
      password,
      phone: "41988880000",
      cpf: String(ts + 100).slice(-11),
      role: "CLIENTE",
    },
  });
  expect(res.status()).toBe(409);
});

test("registro sem campos obrigatórios retorna 400", async () => {
  const res = await api.post("/auth/register", {
    data: { email: "incompleto@test.com" },
  });
  expect(res.status()).toBe(400);
});

test("POST /auth/login com credenciais corretas retorna token", async () => {
  const res = await api.post("/auth/login", { data: { email, password } });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.accessToken).toBeTruthy();
  expect(body.user.id).toBe(userId);
});

test("login com senha errada retorna 401", async () => {
  const res = await api.post("/auth/login", {
    data: { email, password: "errada" },
  });
  expect(res.status()).toBe(401);
});

test("login com email inexistente retorna 401", async () => {
  const res = await api.post("/auth/login", {
    data: { email: "naoexiste@mypet.com", password },
  });
  expect(res.status()).toBe(401);
});

test("GET /auth/me com JWT retorna o perfil (sem senha)", async () => {
  const res = await api.get("/auth/me", { headers: authHeader() });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(userId);
  expect(body.email).toBe(email);
  expect(body.password).toBeUndefined();
});

test("GET /auth/me sem token retorna 401", async () => {
  const res = await api.get("/auth/me");
  expect(res.status()).toBe(401);
});

test("PATCH /auth/me atualiza nome e telefone", async () => {
  const res = await api.patch("/auth/me", {
    headers: authHeader(),
    data: { name: "Nome Atualizado", phone: "41977770000" },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.name).toBe("Nome Atualizado");
  expect(body.phone).toBe("41977770000");
});

test("DELETE /auth/me remove a conta (204)", async () => {
  const reg = await api.post("/auth/register", {
    data: {
      name: "Para Deletar",
      email: `del${ts}@mypet.com`,
      password,
      phone: "41911110000",
      cpf: String(ts + 50000).slice(-11),
      role: "CLIENTE",
    },
  });
  const { accessToken } = await reg.json();

  const res = await api.delete("/auth/me", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  expect(res.status()).toBe(204);
});
