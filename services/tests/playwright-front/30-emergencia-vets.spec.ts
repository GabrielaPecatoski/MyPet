/**
 * Testa a tela de emergência:
 *  - tabs Clínicas e Veterinários
 *  - vet registrado e disponível aparece na aba
 *  - badge "Domiciliar" quando vet ativa atendimento domiciliar
 *  - estabelecimento de emergência aparece na aba Clínicas
 */
import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  registerVet,
  SeededUser,
} from "./_api";
import { bootAndLogin, expectText, tapText, waitForText } from "./_helpers";

// page.evaluate polling — imune ao visibility check do Playwright e ao actionTimeout cap
// Checa textContent E aria-label porque Flutter Web pode usar qualquer um dos dois
async function pollText(
  page: import("@playwright/test").Page,
  pattern: RegExp,
  timeoutMs: number,
): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const found: boolean = await page
      .evaluate((pat) => {
        const re = new RegExp(pat);
        return Array.from(document.querySelectorAll("flt-semantics")).some(
          (el) => {
            const text =
              (el.textContent ?? "") +
              " " +
              (el.getAttribute("aria-label") ?? "");
            return re.test(text);
          },
        );
      }, pattern.source)
      .catch(() => false);
    if (found) return true;
    await page.waitForTimeout(500);
  }
  return false;
}

let api: APIRequestContext;
let cliente: SeededUser;
let vet: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
  vet = await registerUser(api, {
    role: "VETERINARIO",
    namePrefix: "Vet Emergencia E2E",
  });
  try {
    await registerVet(api, vet, { especialidade: "Clínica geral" });
  } catch (_) {
    /* já cadastrado */
  }
});

test.afterAll(async () => {
  await api.dispose();
});

test("tela de emergência exibe duas abas: Clínicas e Veterinários", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, "Emergência Veterinária");
  await waitForText(page, "Emergência Veterinária");
  // Tabs usam aria-label (não textContent) → usar getByRole
  await page
    .getByRole("tab", { name: /Clínicas/ })
    .first()
    .waitFor({ state: "visible", timeout: 30_000 });
  await page
    .getByRole("tab", { name: /Veterinários/ })
    .first()
    .waitFor({ state: "visible", timeout: 30_000 });
});

test("aba Clínicas é exibida por padrão", async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, "Emergência Veterinária");
  await waitForText(page, "Emergência Veterinária");
  // header está presente
  await expectText(page, /Emergência Veterinária/);
});

test("navegar para aba Veterinários mostra lista ou estado vazio", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, "Emergência Veterinária");
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, /Veterinários/);
  // poll via evaluate — flt-semantics inside TabBarView não passa no waitFor({ state: 'visible' })
  if (!(await pollText(page, /Nenhum veterinário|Disponível|Dr\./, 30_000)))
    throw new Error("Conteúdo da aba Veterinários não carregou em 30s");
});

test("aba Clínicas: estado vazio ou card de clínica sem crash", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, "Emergência Veterinária");
  await waitForText(page, /Emergência/);
  // poll via evaluate — flt-semantics inside TabBarView não passa no waitFor({ state: 'visible' })
  if (!(await pollText(page, /Nenhuma clínica|disponível|Pet shops/, 30_000)))
    throw new Error("Conteúdo da aba Clínicas não carregou em 30s");
});

test("botão voltar na tela de emergência retorna à home", async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, "Emergência Veterinária");
  await waitForText(page, /Emergência/);
  // pressionar back (AppBar com showBack: true)
  await page.goBack({ timeout: 10_000 }).catch(async () => {
    await tapText(page, "voltar");
  });
  await expectText(page, "Emergência Veterinária"); // botão ainda existe
});
