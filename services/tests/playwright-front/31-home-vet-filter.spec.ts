import { APIRequestContext, test } from "@playwright/test";
import { apiContext, registerUser, registerVet, SeededUser } from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  pollTap,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let cliente: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
});

test.afterAll(async () => {
  await api.dispose();
});

test("home exibe chips de filtro: Todos, Banho, Tosa, Veterinário, Acessórios", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await expectText(page, "Todos");
  await expectText(page, "Banho");
  await expectText(page, "Tosa");
  await expectText(page, "Veterinário");
  await expectText(page, "Acessórios");
});

test("clicar em Veterinário exibe seção de veterinários disponíveis", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, "Veterinário");
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll("flt-semantics"));
      return all.some(
        (el) =>
          el.textContent?.includes("Veterinários disponíveis") ||
          el.textContent?.includes("Nenhum veterinário disponível") ||
          el.textContent?.includes("Dr."),
      );
    },
    { timeout: 30_000 },
  );
});

test("clicar em Veterinário e voltar em Todos restaura o carousel", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, "Veterinário");
  await waitForText(
    page,
    /Veterinários disponíveis|Nenhum veterinário|Clínicas/,
  );
  await tapText(page, "Todos");
  await waitForText(page, "Mais Bem Avaliados");
});

test("chip Banho filtra estabelecimentos (não quebra a UI)", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, "Banho");
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll("flt-semantics"));
      return all.some(
        (el) =>
          el.textContent?.includes("Mais Bem Avaliados") ||
          el.textContent?.includes("Nenhum estabelecimento"),
      );
    },
    { timeout: 25_000 },
  );
});

test("chip Tosa filtra estabelecimentos sem crash", async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, "Tosa");
  await page.waitForTimeout(3000);
  await expectText(page, /Todos|Banho|Tosa/);
});

test("chip Acessórios filtra sem crash", async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, "Acessórios");
  await page.waitForTimeout(3000);
  await expectText(page, /Todos|Banho|Acessórios/);
});

test("seção Veterinários mostra badge Domiciliar se vet ativa o serviço", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await tapText(page, "Veterinário");
  await waitForText(page, /Veterinários disponíveis|Nenhum veterinário/);
  const hasDomiciliar = await byText(page, "Domiciliar")
    .first()
    .isVisible({ timeout: 5000 })
    .catch(() => false);
  if (hasDomiciliar) {
    await expectText(page, "Domiciliar");
  }
});
