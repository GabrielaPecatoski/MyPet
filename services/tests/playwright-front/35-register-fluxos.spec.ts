import { APIRequestContext, expect, test } from "@playwright/test";
import { apiContext } from "./_api";
import {
  bootFlutter,
  byText,
  expectText,
  fill,
  fillNth,
  skipOnboardingIfPresent,
  tapButton,
  tapText,
  textFields,
  waitForText,
} from "./_helpers";

// Envia o cadastro e aguarda a tela seguinte. Re-tenta "Criar conta" enquanto o
// botão continuar visível (registro + auto-login podem demorar sob carga), sem
// risco de duplo envio depois que a navegação acontece.
async function criarContaEAguardar(
  page: import("@playwright/test").Page,
  probe: RegExp,
): Promise<void> {
  await expect
    .poll(
      async () => {
        if (
          await byText(page, probe)
            .first()
            .isVisible()
            .catch(() => false)
        ) {
          return true;
        }
        const btn = page.getByRole("button", { name: "Criar conta" }).first();
        if (await btn.isVisible().catch(() => false)) {
          await btn.click({ force: true }).catch(() => {});
        }
        return false;
      },
      { timeout: 70_000, intervals: [2000] },
    )
    .toBe(true);
}

let api: APIRequestContext;
test.beforeAll(async () => {
  api = await apiContext();
});
test.afterAll(async () => {
  await api.dispose();
});

async function goToWelcome(page: Parameters<typeof bootFlutter>[0]) {
  await bootFlutter(page, "/");
  await skipOnboardingIfPresent(page);
}

test("cadastro Tutor completo → home do cliente", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Tutor E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41988881111");
  await fill(campos.nth(3), `tutor${ts}@e2e.com`);
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "Senha@123");
  await tapButton(page, "Criar conta");
  await expectText(page, "Agenda");
  await expectText(page, "Pets");
});

test("cadastro Estabelecimento completo → home do estab", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Estabelecimento");
  await tapButton(page, /Continuar como Estabelecimento/);
  await waitForText(page, "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Responsavel E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), `Pet Shop E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(3), "41977772222");
  await fill(campos.nth(4), `estab${ts}@e2e.com`);
  await fill(campos.nth(5), "Senha@123");
  await fill(campos.nth(6), "Senha@123");
  await tapButton(page, "Criar conta");
  await waitForText(page, /Painel|Agenda|Home/, 40_000);
});

test("cadastro Veterinário completo → painel do vet", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Veterinário");
  await tapButton(page, /Continuar como Veteri/);
  await waitForText(page, "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Dr Vet E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41966663333");
  await fill(campos.nth(3), `vet${ts}@e2e.com`);
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "Senha@123");
  await fill(campos.nth(6), `MG${ts.toString().slice(-5)}`);
  await tapButton(page, "Criar conta");
  await expectText(page, "MY PET · VETERINÁRIO");
  await expectText(page, "Agenda");
});

test("cadastro Motorista completo → painel do motorista", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Motorista");
  await tapButton(page, /Continuar como Motorista/);
  await waitForText(page, "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Mot E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41955554444");
  await fill(campos.nth(3), `mot${ts}@e2e.com`);
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "Senha@123");
  await fill(campos.nth(6), String(ts).slice(-9));
  await fill(campos.nth(7), "Honda Civic");
  await fill(campos.nth(8), `ABC${ts.toString().slice(-4)}`);
  await criarContaEAguardar(
    page,
    /MY PET · MOTORISTA|Painel|Início|Corridas/,
  );
});

test("submeter form vazio mostra erros de validação", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  await tapButton(page, "Criar conta");
  await expectText(page, "Criar conta");
  await expectText(page, /Informe|obrigatório/i);
});

test("senha com menos de 6 caracteres é rejeitada", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  const campos = textFields(page);
  const ts = Date.now();
  await fill(campos.nth(0), "Teste Curto");
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41988880000");
  await fill(campos.nth(3), `curto${ts}@e2e.com`);
  await fill(campos.nth(4), "123");
  await fill(campos.nth(5), "123");
  await tapButton(page, "Criar conta");
  await expectText(page, /Mínimo 6|senha|caracteres/i);
});

test("senhas diferentes mostram erro de confirmação", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  const campos = textFields(page);
  const ts = Date.now();
  await fill(campos.nth(0), "Teste Senha Diff");
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41988880000");
  await fill(campos.nth(3), `diff${ts}@e2e.com`);
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "senhaXXX");
  await tapButton(page, "Criar conta");
  await expectText(page, /Senhas não coincidem|senhas/i);
});

test("e-mail duplicado mostra mensagem de erro sem crash", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), "Duplicado Teste");
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41988889999");
  await fill(campos.nth(3), "admin@mypet.com");
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "Senha@123");
  await tapButton(page, "Criar conta");
  await waitForText(page, /erro|existente|utilizado|inválido|email/i, 20_000);
});

test("vet sem CRMV não passa validação", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Veterinário");
  await tapButton(page, /Continuar como Veteri/);
  await waitForText(page, "Nome completo");
  const campos = textFields(page);
  const ts = Date.now();
  await fill(campos.nth(0), "Vet Sem CRMV");
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41966663333");
  await fill(campos.nth(3), `vetcrmv${ts}@e2e.com`);
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "Senha@123");
  await tapButton(page, "Criar conta");
  await expectText(page, /CRMV|Informe|obrigatório/i);
});

test("motorista sem CNH não passa validação", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Motorista");
  await tapButton(page, /Continuar como Motorista/);
  await waitForText(page, "Nome completo");
  const campos = textFields(page);
  const ts = Date.now();
  await fill(campos.nth(0), "Mot Sem CNH");
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41955554444");
  await fill(campos.nth(3), `motcnh${ts}@e2e.com`);
  await fill(campos.nth(4), "Senha@123");
  await fill(campos.nth(5), "Senha@123");
  await fill(campos.nth(7), "Fiat Uno");
  await fill(campos.nth(8), `XX${ts.toString().slice(-4)}`);
  await tapButton(page, "Criar conta");
  await expectText(page, /CNH|Informe|obrigatório/i);
});
