import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  fieldByHint,
  fill,
  tapButton,
  tapText,
  textFields,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let owner: SeededUser;
let estab: any;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Motoristas E2E",
  });
  estab = await createEstablishment(api, owner, {
    name: `Pet Shop Mot E2E ${Date.now()}`,
  });
});

test.afterAll(async () => {
  await api.dispose();
});

test("menu Motoristas está acessível no perfil do estab", async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await waitForText(page, /Painel|Home/);
  await tapText(page, "Perfil");
  await waitForText(page, /Motoristas|Veterinários|Editar/);
  await expectText(page, /Motoristas/);
});

test("tela de motoristas exibe header e lista vazia ou motoristas", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Motoristas/);
  await tapText(page, "Motoristas");
  await waitForText(page, /Motoristas|Nenhum motorista/);
});

test("botão Adicionar abre sheet de cadastro de motorista", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Motoristas/);
  await tapText(page, "Motoristas");
  await waitForText(page, /Motoristas|Nenhum motorista/);
  await tapButton(page, "Adicionar");
  await waitForText(page, /Motorista|Nome|CNH/i);
});

test("cadastro de novo motorista pela UI associa ao estab", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Motoristas/);
  await tapText(page, "Motoristas");
  await waitForText(page, /Motoristas|Nenhum motorista/);
  await tapButton(page, "Adicionar");
  await waitForText(page, "Adicionar Motorista");
  await tapText(page, "Cadastrar novo");
  await waitForText(page, "Veículo");

  const ts = Date.now();
  const campos = page.locator(
    'input[data-semantics-role="text-field"]:visible',
  );
  await fill(campos.nth(0), `Mot Novo E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), "41944440005");
  await fill(campos.nth(2), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(3), `mot${ts}@mypet.com`);
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), String(ts).slice(-9));
  await fill(campos.nth(6), "Fiat Palio");
  await fill(campos.nth(7), `MOT${ts.toString().slice(-4)}`);
  await tapButton(page, "Cadastrar e Associar");
  await waitForText(page, /cadastrado|associado|Ativo|Motoristas/i, 25_000);
});
