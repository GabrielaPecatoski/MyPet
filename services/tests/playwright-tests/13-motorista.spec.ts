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
let owner: SeededUser; // VENDEDOR: tem DRIVERS_READ/WRITE/DELETE
let cliente: SeededUser; // CLIENTE: sem permissões de motorista
let admin: SeededUser;
let estabId: string;
let driverId: string;
let driverCpf: string;

function novoMotorista() {
  const ts = Date.now() + Math.floor(Math.random() * 100000);
  return {
    establishmentId: estabId,
    name: `Motorista API ${String(ts).slice(-4)}`,
    phone: "41988880000",
    cpf: String(ts).slice(-11).padStart(11, "0"),
    cnh: String(ts).slice(-9),
    vehicleType: "CARRO",
    vehicleModel: "Fiat Uno",
    vehiclePlate: `API${String(ts).slice(-4)}`,
  };
}

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Motorista",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Motorista ${Date.now()}`,
  });
  estabId = estab.id;
  cliente = await registerUser(api, { role: "CLIENTE" });
  admin = await getAdmin(api);
});

test.afterAll(async () => {
  await api.dispose();
});

// ---- Autenticação JWT ----

test("GET /drivers sem token retorna 401 (Missing token)", async () => {
  const res = await api.get("/drivers");
  expect(res.status()).toBe(401);
});

test("GET /drivers com token adulterado retorna 401 (assinatura inválida)", async () => {
  const tampered = `${owner.token.slice(0, -3)}xyz`;
  const res = await api.get("/drivers", {
    headers: { Authorization: `Bearer ${tampered}` },
  });
  expect(res.status()).toBe(401);
});

// ---- Autorização por permissão ----

test("cliente não pode registrar motorista (403 — sem DRIVERS_WRITE)", async () => {
  const res = await api.post("/drivers", {
    headers: auth(cliente),
    data: novoMotorista(),
  });
  expect(res.status()).toBe(403);
});

test("vendedor registra motorista (201)", async () => {
  const dados = novoMotorista();
  driverCpf = dados.cpf;
  const res = await api.post("/drivers", {
    headers: auth(owner),
    data: dados,
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  driverId = body.id;
});

test("GET /drivers/establishment/:id lista o motorista (vendedor)", async () => {
  const res = await api.get(`/drivers/establishment/${estabId}`, {
    headers: auth(owner),
  });
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((d) => d.id === driverId)).toBe(true);
});

test("GET /drivers/by-cpf encontra o motorista", async () => {
  const res = await api.get(`/drivers/by-cpf?cpf=${driverCpf}`, {
    headers: auth(owner),
  });
  expect(res.status()).toBe(200);
});

test("GET /drivers/:id retorna o motorista", async () => {
  const res = await api.get(`/drivers/${driverId}`, { headers: auth(owner) });
  expect(res.status()).toBe(200);
  expect((await res.json()).id).toBe(driverId);
});

test("fila do admin: cliente recebe 403", async () => {
  const res = await api.get("/drivers/admin/pending", {
    headers: auth(cliente),
  });
  expect(res.status()).toBe(403);
});

test("fila do admin: admin recebe 200", async () => {
  const res = await api.get("/drivers/admin/pending", {
    headers: auth(admin),
  });
  expect(res.status()).toBe(200);
});

test("aprovar motorista: cliente 403, admin 200", async () => {
  const cli = await api.patch(`/drivers/${driverId}/approve`, {
    headers: auth(cliente),
  });
  expect(cli.status()).toBe(403);

  const adm = await api.patch(`/drivers/${driverId}/approve`, {
    headers: auth(admin),
  });
  expect(adm.status()).toBe(200);
});

test("excluir motorista: cliente 403, vendedor 204", async () => {
  const cli = await api.delete(`/drivers/${driverId}`, {
    headers: auth(cliente),
  });
  expect(cli.status()).toBe(403);

  const vend = await api.delete(`/drivers/${driverId}`, {
    headers: auth(owner),
  });
  expect(vend.status()).toBe(204);
});
