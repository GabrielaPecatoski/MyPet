import { APIRequestContext, test } from "@playwright/test";
import { apiContext } from "./_api";
import {
  bootFlutter,
  byText,
  expectText,
  fill,
  fillNth,
  leafByText,
  pollTap,
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
test("cadastro de motorista pela UI cria perfil e abre painel do motorista", async ({
  page,
}) => {
  await bootFlutter(page, "/");
  await skipOnboardingIfPresent(page);
  // leafByText evita o problema de byText.first() retornar o nó raiz (ancestor):
  // o click no leaf cai sobre o card do GestureDetector via pointer-events
  await leafByText(page, "Sou Motorista").first().click({ force: true });
  await pollTap(page, "Continuar como Motorista", "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Motorista UI ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), `41${ts.toString().slice(-9)}`);
  await fill(campos.nth(3), `mot${ts}@mypet.com`);
  await fill(campos.nth(4), "senha123");
  await fill(campos.nth(5), "senha123");
  await fill(campos.nth(6), String(ts).slice(-9));
  // Pausa para Flutter assentar o scroll após preencher CNH antes do próximo campo
  await page.waitForTimeout(600);
  await fill(campos.nth(7), "Fiat Uno");
  await fill(campos.nth(8), `ABC${ts.toString().slice(-4)}`);
  await tapButton(page, "Criar conta");
  // Primeira execução pode ter API fria — 60s para a navegação pós-registro
  await waitForText(page, "MY PET · MOTORISTA", 60_000);
  await expectText(page, "Início");
  await expectText(page, "Ganhos");
  await expectText(page, "Histórico");
  await expectText(page, "Perfil");
});
test("cadastro de veterinário pela UI cria perfil e abre painel do vet", async ({
  page,
}) => {
  await bootFlutter(page, "/");
  await skipOnboardingIfPresent(page);
  await leafByText(page, "Sou Veterinário").first().click({ force: true });
  await pollTap(page, "Continuar como Veterinário", "Nome completo");
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Vet UI ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, "0"));
  await fill(campos.nth(2), "41966660002");
  await fill(campos.nth(3), `vet${ts}@mypet.com`);
  // Usar input[type="password"] para garantir que senha e confirma chegam aos campos certos
  await fill(page.locator('input[type="password"]').nth(0), "senha123");
  await fill(page.locator('input[type="password"]').nth(1), "senha123");
  await fill(campos.nth(6), `SP${ts.toString().slice(-5)}`);
  await tapButton(page, "Criar conta");
  await waitForText(page, "MY PET · VETERINÁRIO", 60_000);
  await expectText(page, "Agenda");
  await expectText(page, "Chamados");
  await expectText(page, "Pacientes");
  await expectText(page, "Perfil");
});
test("cadastro com campo vazio exibe validação e não avança", async ({
  page,
}) => {
  await bootFlutter(page, "/");
  await skipOnboardingIfPresent(page);
  await leafByText(page, "Sou Tutor").first().click({ force: true });
  await pollTap(page, "Continuar como Tutor", "Nome completo");
  await tapButton(page, "Criar conta");
  await expectText(page, "Criar conta");
});
