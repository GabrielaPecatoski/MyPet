import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  getAdmin,
  registerUser,
  SeededUser,
} from "../playwright-front/_api";

const auth = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let owner: SeededUser; // VENDEDOR: VETS_READ/WRITE/DELETE
let vetUser: SeededUser; // VETERINARIO: VETS_READ/WRITE (próprio)
let cliente: SeededUser; // CLIENTE: só VETS_READ
let admin: SeededUser;
let estabId: string;
let vetId: string;
let vetCpf: string;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Vet",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Clínica API ${Date.now()}`,
  });
  estabId = estab.id;
  vetUser = await registerUser(api, { role: "VETERINARIO" });
  cliente = await registerUser(api, { role: "CLIENTE" });
  admin = await getAdmin(api);
});

test.afterAll(async () => {
  await api.dispose();
});

// ---- Autenticação JWT ----

test("GET /veterinarians sem token retorna 401", async () => {
  const res = await api.get("/veterinarians");
  expect(res.status()).toBe(401);
});

test("GET /veterinarians com token adulterado retorna 401", async () => {
  const tampered = `${vetUser.token.slice(0, -3)}xyz`;
  const res = await api.get("/veterinarians", {
    headers: { Authorization: `Bearer ${tampered}` },
  });
  expect(res.status()).toBe(401);
});

// ---- Autorização por permissão ----

test("cliente não pode registrar veterinário (403)", async () => {
  const res = await api.post("/veterinarians", {
    headers: auth(cliente),
    data: {
      name: "Vet Cliente",
      phone: "41999990000",
      cpf: String(Date.now()).slice(-11),
      crmv: `SP${String(Date.now()).slice(-5)}`,
    },
  });
  expect(res.status()).toBe(403);
});

test("veterinário registra a si mesmo (201)", async () => {
  const ts = Date.now();
  vetCpf = String(ts).slice(-11).padStart(11, "0");
  const res = await api.post("/veterinarians", {
    headers: auth(vetUser),
    data: {
      establishmentId: estabId,
      name: "Dra. API",
      phone: "41999991111",
      cpf: vetCpf,
      crmv: `SP${String(ts).slice(-5)}`,
      especialidade: "Clínica geral",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  vetId = body.id;
});

test("cliente pode listar veterinários disponíveis (VETS_READ → 200)", async () => {
  const res = await api.get("/veterinarians/available", {
    headers: auth(cliente),
  });
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("GET /veterinarians/by-cpf encontra o veterinário", async () => {
  const res = await api.get(`/veterinarians/by-cpf?cpf=${vetCpf}`, {
    headers: auth(vetUser),
  });
  expect(res.status()).toBe(200);
});

test("fila do admin: cliente 403, admin 200", async () => {
  const cli = await api.get("/veterinarians/admin/pending", {
    headers: auth(cliente),
  });
  expect(cli.status()).toBe(403);
  const adm = await api.get("/veterinarians/admin/pending", {
    headers: auth(admin),
  });
  expect(adm.status()).toBe(200);
});

test("admin aprova o veterinário (200)", async () => {
  const res = await api.patch(`/veterinarians/${vetId}/approve`, {
    headers: auth(admin),
  });
  expect(res.status()).toBe(200);
});

test("disponibilidade: cliente 403, veterinário 200", async () => {
  const cli = await api.patch(`/veterinarians/${vetId}/availability`, {
    headers: auth(cliente),
    data: { disponivel: true },
  });
  expect(cli.status()).toBe(403);

  const vet = await api.patch(`/veterinarians/${vetId}/availability`, {
    headers: auth(vetUser),
    data: { disponivel: true, atendeDomicilio: true },
  });
  expect(vet.status()).toBe(200);
});

test("cliente dispara chamado de emergência (VETS_READ → 2xx)", async () => {
  const res = await api.post(`/veterinarians/${vetId}/emergency-call`, {
    headers: auth(cliente),
    data: {
      callerName: "Cliente API",
      callerPhone: "41999990000",
      petDescription: "Cachorro com dificuldade para respirar",
    },
  });
  expect([200, 201]).toContain(res.status());
});

test("excluir veterinário: cliente 403, admin 204", async () => {
  const cli = await api.delete(`/veterinarians/${vetId}`, {
    headers: auth(cliente),
  });
  expect(cli.status()).toBe(403);

  const adm = await api.delete(`/veterinarians/${vetId}`, {
    headers: auth(admin),
  });
  expect(adm.status()).toBe(204);
});
