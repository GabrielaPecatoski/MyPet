import { test } from "@playwright/test";
import {
  bootFlutter,
  byText,
  expectText,
  skipOnboardingIfPresent,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

async function goToWelcome(page: Parameters<typeof bootFlutter>[0]) {
  await bootFlutter(page, "/");
  await skipOnboardingIfPresent(page);
}

test("welcome exibe os 4 papéis disponíveis", async ({ page }) => {
  await goToWelcome(page);
  await expectText(page, "Como você quer usar o app?");
  await expectText(page, "Sou Tutor");
  await expectText(page, "Estabelecimento");
  await expectText(page, "Sou Veterinário");
  await expectText(page, "Sou Motorista");
});

test("botão Continuar fica desabilitado sem seleção", async ({ page }) => {
  await goToWelcome(page);
  await waitForText(page, "Como você quer usar o app?");
  await expectText(page, "Continuar");
});

test('selecionar Tutor muda botão para "Continuar como Tutor"', async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await waitForText(page, /Continuar como Tutor/);
});

test('selecionar Estabelecimento muda botão para "Continuar como Estabelecimento"', async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Estabelecimento");
  await waitForText(page, /Continuar como Estabelecimento/);
});

test('selecionar Veterinário muda botão para "Continuar como Veterinário"', async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Veterinário");
  await waitForText(page, /Continuar como Veteri/);
});

test('selecionar Motorista muda botão para "Continuar como Motorista"', async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Motorista");
  await waitForText(page, /Continuar como Motorista/);
});

test("trocar seleção de Tutor para Vet muda o botão", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await waitForText(page, /Continuar como Tutor/);
  await tapText(page, "Sou Veterinário");
  await waitForText(page, /Continuar como Veteri/);
});

test("continuar como Tutor abre tela de registro com header Tutor", async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  await expectText(page, "Criar conta");
});

test("continuar como Veterinário abre registro com campos de CRMV", async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Veterinário");
  await tapButton(page, /Continuar como Veteri/);
  await waitForText(page, "Nome completo");
  await expectText(page, /CRMV/);
  await expectText(page, "Criar conta");
});

test("continuar como Motorista abre registro com campos de veículo", async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Motorista");
  await tapButton(page, /Continuar como Motorista/);
  await waitForText(page, "Nome completo");
  await expectText(page, /CNH|veículo/i);
  await expectText(page, "Criar conta");
});

test("continuar como Estabelecimento abre registro com campo Nome do estabelecimento", async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Estabelecimento");
  await tapButton(page, /Continuar como Estabelecimento/);
  await waitForText(page, "Nome do estabelecimento");
  await expectText(page, "Criar conta");
});

test("link Entrar da welcome vai para tela de login", async ({ page }) => {
  await goToWelcome(page);
  await tapText(page, "Entrar");
  await waitForText(page, "E-mail");
  await expectText(page, /Senha/);
  await expectText(page, "Entrar");
});

test('"Entrar agora" no register leva de volta ao login (não para welcome)', async ({
  page,
}) => {
  await goToWelcome(page);
  await tapText(page, "Sou Tutor");
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, "Nome completo");
  await tapText(page, "Entrar agora");
  await waitForText(page, "E-mail");
  await expectText(page, /Senha/);
});
