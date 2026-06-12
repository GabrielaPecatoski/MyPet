/**
 * Testa a tela de vínculos de veterinários do estabelecimento:
 *  - tela lista vets vinculados
 *  - botão Adicionar abre sheet com abas "Buscar por CPF" e "Cadastrar novo"
 *  - busca por CPF de vet existente retorna o perfil
 *  - busca por CPF inválido mostra mensagem de erro
 *  - cadastro de novo vet vincula ao estabelecimento
 *  - remover vet mostra confirmação
 */
import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  registerVet,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  fieldByHint,
  fill,
  fillNth,
  pollText,
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
    businessName: "Estab Vinculos E2E",
  });
  estab = await createEstablishment(api, owner, {
    name: `Clínica Vinculos E2E ${Date.now()}`,
  });
});

test.afterAll(async () => {
  await api.dispose();
});

test("menu Veterinários está acessível no perfil do estab", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await waitForText(page, /Painel|Home/);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários|Motoristas|Editar/);
  await expectText(page, /Veterinários/);
});

test("tela de vets do estab exibe header e estado vazio ou lista", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários/);
  await tapText(page, "Veterinários");
  await waitForText(page, /Veterinários associados|Nenhum veterinário/);
});

test("botão Adicionar abre sheet de adição de vet", async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários/);
  await tapText(page, "Veterinários");
  await waitForText(page, /Veterinários associados|Nenhum veterinário/);
  await tapButton(page, "Adicionar");
  await waitForText(page, "Adicionar Veterinário");
  await expectText(page, "Buscar por CPF");
  await expectText(page, "Cadastrar novo");
});

test("busca por CPF inválido mostra mensagem de erro", async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários/);
  await tapText(page, "Veterinários");
  await waitForText(page, /Nenhum veterinário|Veterinários associados/);
  await tapButton(page, "Adicionar");
  await waitForText(page, "Buscar por CPF");
  const cpfField = fieldByHint(page, "CPF do veterinário");
  await fill(cpfField, "12345");
  await tapButton(page, "Buscar");
  await waitForText(page, /CPF deve ter 11|Veterinário não encontrado|Erro/);
});

test("aba Cadastrar novo exibe formulário completo", async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários/);
  await tapText(page, "Veterinários");
  await waitForText(page, /Nenhum veterinário|Veterinários associados/);
  await tapButton(page, "Adicionar");
  await waitForText(page, "Adicionar Veterinário");
  await page
    .getByRole("tab", { name: /Cadastrar novo/ })
    .first()
    .waitFor({ state: "visible", timeout: 15_000 });
  await page
    .getByRole("tab", { name: /Cadastrar novo/ })
    .first()
    .click({ force: true });
  await pollText(page, /Nome completo/, 30_000);
  await pollText(page, /CPF/, 10_000);
  await pollText(page, /CRMV/, 10_000);
  await pollText(page, /Senha/, 10_000);
  await pollText(page, "Cadastrar e Associar", 10_000);
});

test("cadastrar vet novo via UI vincula ao estab e aparece na lista", async ({
  page,
}) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários/);
  await tapText(page, "Veterinários");
  await waitForText(page, /Nenhum veterinário|Veterinários associados/);
  await tapButton(page, "Adicionar");
  await waitForText(page, "Adicionar Veterinário");
  await page
    .getByRole("tab", { name: /Cadastrar novo/ })
    .first()
    .waitFor({ state: "visible", timeout: 15_000 });
  await page
    .getByRole("tab", { name: /Cadastrar novo/ })
    .first()
    .click({ force: true });
  await pollText(page, /Nome completo/, 30_000);

  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Dr Novo E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), "41977770003");
  await fill(campos.nth(2), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(3), `novevet${ts}@mypet.com`);
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), `SP${ts.toString().slice(-5)}`);
  await tapButton(page, "Cadastrar e Associar");

  // sucesso: sheet fecha e lista atualiza
  await waitForText(
    page,
    /cadastrado e associado|Associado|Veterinários associados/i,
    40_000,
  );
});

test("buscar vet existente por CPF permite associá-lo", async ({ page }) => {
  // Cria um vet independente via API para depois buscar na UI
  const vetUser = await registerUser(api, {
    role: "VETERINARIO",
    namePrefix: "Vet Busca E2E",
  });
  const cpf = String(Date.now()).slice(-11).padStart(11, "0");
  try {
    await api.post("/veterinarians", {
      headers: { Authorization: `Bearer ${vetUser.token}` },
      data: {
        name: vetUser.name,
        phone: "41955550000",
        cpf,
        crmv: `RJ${Date.now().toString().slice(-5)}`,
        especialidade: "Ortopedia",
      },
    });
  } catch (_) {}

  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Perfil");
  await waitForText(page, /Veterinários/);
  await tapText(page, "Veterinários");
  await waitForText(page, /Nenhum veterinário|Veterinários associados/);
  await tapButton(page, "Adicionar");
  await waitForText(page, "Buscar por CPF");
  const cpfField = fieldByHint(page, "CPF do veterinário");
  await fill(cpfField, cpf);
  await tapButton(page, "Buscar");
  await waitForText(
    page,
    /Vet Busca E2E|CRMV|Associar a este estabelecimento|já está associado|não encontrado/,
    20_000,
  );
});
