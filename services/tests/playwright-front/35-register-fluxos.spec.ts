/**
 * Testa todos os fluxos de cadastro pelo caminho da welcome screen:
 *  - Tutor → home do cliente
 *  - Estabelecimento → home do estab
 *  - Veterinário → painel do vet
 *  - Motorista → painel do motorista
 *  - Validação de campos obrigatórios
 *  - Senha inválida (menos de 6 chars)
 *  - Senhas que não coincidem
 *  - E-mail duplicado mostra erro sem crash
 */
import { APIRequestContext, test } from "@playwright/test";
import { apiContext } from "./_api";
import {
  bootFlutter,
  expectText,
  fill,
  fillNth,
  pollText,
  skipOnboardingIfPresent,
  tapButton,
  tapText,
  textFields,
  waitForText,
} from "./_helpers";

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

// ─── Tutor ───────────────────────────────────────────────────────────────────

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
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  await tapButton(page, "Criar conta");
  await expectText(page, "Agenda");
  await expectText(page, "Pets");
});

// ─── Estabelecimento ─────────────────────────────────────────────────────────

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
  await fill(campos.nth(5), "senha123");
  await fill(campos.nth(6), "senha123");
  await tapButton(page, "Criar conta");
  await waitForText(page, /Painel|Agenda|Home/, 40_000);
});

// ─── Veterinário ──────────────────────────────────────────────────────────────

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
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  await fill(campos.nth(6), `MG${ts.toString().slice(-5)}`);
  await tapButton(page, "Criar conta");
  await expectText(page, "MY PET · VETERINÁRIO");
  await expectText(page, "Agenda");
});

// ─── Motorista ────────────────────────────────────────────────────────────────

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
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  await fill(campos.nth(6), String(ts).slice(-9));
  await fill(campos.nth(7), "Honda Civic");
  await fill(campos.nth(8), `ABC${ts.toString().slice(-4)}`);
  await tapButton(page, "Criar conta");
  await pollText(page, /MY PET · MOTORISTA|Painel|Início|Corridas/, 40_000);
});

// ─── Validações ──────────────────────────────────────────────────────────────

test("submeter form vazio mostra erros de validação", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  await tapButton(page, "Criar conta");
  // deve continuar na tela de cadastro (não navega)
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
  await fill(campos.nth(4), "123"); // muito curto
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
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senhaXXX");
  await tapButton(page, "Criar conta");
  await expectText(page, /Senhas não coincidem|senhas/i);
});

test("e-mail duplicado mostra mensagem de erro sem crash", async ({ page }) => {
  // usa seed — email fixo que deve existir depois do seed
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), "Duplicado Teste");
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41988889999");
  await fill(campos.nth(3), "admin@mypet.com"); // email já existente
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  await tapButton(page, "Criar conta");
  // deve mostrar snackbar de erro sem crash
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
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  // deixa CRMV (campos.nth(6)) vazio
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
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  // deixa CNH vazio (campos.nth(6))
  await fill(campos.nth(7), "Fiat Uno");
  await fill(campos.nth(8), `XX${ts.toString().slice(-4)}`);
  await tapButton(page, "Criar conta");
  await expectText(page, /CNH|Informe|obrigatório/i);
});
