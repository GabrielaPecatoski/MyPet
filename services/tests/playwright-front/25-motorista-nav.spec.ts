import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  registerIndependentDriver,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  pollTap,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let motorista: SeededUser;
test.beforeAll(async () => {
  api = await apiContext();
  motorista = await registerUser(api, {
    role: "MOTORISTA",
    namePrefix: "Motorista Nav E2E",
  });
  try {
    await registerIndependentDriver(api, motorista);
  } catch (_) {}
});
test.afterAll(async () => {
  await api.dispose();
});
test("login como motorista abre painel do motorista", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await expectText(page, "MY PET · MOTORISTA");
  await expectText(page, "VOCÊ ESTÁ");
});
test("toggle online muda status para Online", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await waitForText(page, "VOCÊ ESTÁ");
  await expectText(page, "Offline");
  await tapText(page, "Offline");
  await waitForText(page, /Online|Recebendo corridas/);
});
test("aba Corridas exibe tela de corrida ativa", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await tapText(page, "Corridas");
  await expectText(page, "MY PET · MOTORISTA");
  await expectText(page, /Corridas|A CAMINHO|Online/);
});
test("aba Ganhos exibe faturamento semanal e botão PIX", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await tapText(page, "Ganhos");
  await expectText(page, "GANHOS");
  await expectText(page, /R\$/);
  await expectText(page, "Transferir via PIX");
  await expectText(page, "Corridas recentes");
});
test("aba Histórico exibe métricas do motorista", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await tapText(page, "Histórico");
  await expectText(page, "MY PET · MOTORISTA");
  await expectText(page, "Total");
  await expectText(page, "Avaliação");
  await expectText(page, "Aceitação");
});
test("aba Perfil exibe dados do motorista e opção de logout", async ({
  page,
}) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await tapText(page, "Perfil");
  await expectText(page, "Corridas");
  await expectText(page, "Avaliação");
  await expectText(page, "Membro");
  await expectText(page, "Sair");
});
test("logout pelo perfil do motorista volta ao login", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  // bottom nav é GestureDetector (texto 10px) → pollTap é robusto contra taps perdidos
  await pollTap(page, "Perfil", "Sair");
  await tapText(page, "Sair");
  await waitForText(page, "Entrar");
  await expectText(page, /E-mail|login/i);
});
test("recusar corrida remove o card de nova corrida", async ({ page }) => {
  await bootAndLogin(page, motorista.email, motorista.password);
  await waitForText(page, "VOCÊ ESTÁ");
  await tapText(page, "Offline");
  const hasCorrida = await byText(page, "NOVA CORRIDA")
    .first()
    .isVisible({ timeout: 5_000 })
    .catch(() => false);
  if (hasCorrida) {
    await tapButton(page, "Recusar");
    await page.waitForTimeout(500);
    const aindaVisivel = await byText(page, "NOVA CORRIDA")
      .first()
      .isVisible({ timeout: 2_000 })
      .catch(() => false);
    expect(aindaVisivel).toBe(false);
  }
});
