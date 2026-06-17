import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerDriver,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  scrollToText,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;
let driver1Name: string;
let driver2Name: string;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Motoristas Lista E2E",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Mot Lista ${Date.now()}`,
  });
  estabId = estab.id;
  const d1 = await registerDriver(api, owner, estabId, {
    name: `Motorista Um ${Date.now().toString().slice(-4)}`,
  });
  const d2 = await registerDriver(api, owner, estabId, {
    name: `Motorista Dois ${(Date.now() + 1).toString().slice(-4)}`,
  });
  driver1Name = d1.name;
  driver2Name = d2.name;
});

test.afterAll(async () => {
  await api.dispose();
});

test("estabelecimento pode ter múltiplos motoristas (regra de 1-ativo removida)", async () => {
  const res = await api.get(`/drivers/establishment/${estabId}`, {
    headers: { Authorization: `Bearer ${owner.token}` },
  });
  expect(res.ok()).toBe(true);
  const lista = await res.json();
  const nomes = (lista as any[]).map((d) => d.name);
  expect(nomes).toContain(driver1Name);
  expect(nomes).toContain(driver2Name);
});

test("lista de Motoristas no perfil do estab exibe os motoristas associados", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Motoristas/);
  await tapText(page, "Motoristas");
  await waitForText(page, /Motoristas|Nenhum motorista/);
  await scrollToText(page, driver1Name);
  await expectText(page, driver2Name);
});
