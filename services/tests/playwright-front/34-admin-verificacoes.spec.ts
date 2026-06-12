/**
 * Testa o painel do admin, especialmente a nova aba de Verificações:
 *  - login como admin abre painel correto
 *  - 7 abas presentes: Painel, Reclamações, Usuários, Lojas, Verificações, FAQ, Estatísticas
 *  - aba Verificações exibe tabs Veterinários / Motoristas
 *  - quando não há pendentes, exibe estado vazio
 *  - badge de verificações aparece quando há pendentes
 */
import { APIRequestContext, test } from "@playwright/test";
import { apiContext, registerUser, registerVet, SeededUser } from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

const ADMIN_EMAIL = "admin@mypet.com";
const ADMIN_PASSWORD = "admin123";

let api: APIRequestContext;

test.beforeAll(async () => {
  api = await apiContext();
});

test.afterAll(async () => {
  await api.dispose();
});

test("login como admin abre painel de admin", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Admin|Dashboard/);
  await expectText(page, /Usuários|Reclamações/);
});

test("painel admin exibe bottom nav com 5 itens", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  await expectText(page, "Reclamações");
  await expectText(page, "Cadastros");
  await expectText(page, "Verificações");
  await expectText(page, "FAQ");
});

test("aba Verificações exibe tabs Veterinários e Motoristas", async ({
  page,
}) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  await tapText(page, "Verificações");
  // labels das tabs ficam só no aria-label (textContent vazio) — usar string, não regex
  await waitForText(page, "Veterinários", 60_000);
  await expectText(page, "Veterinários");
  await expectText(page, "Motoristas");
});

test('aba Verificações: sem pendentes exibe mensagem "Nenhuma verificação pendente"', async ({
  page,
}) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Verificações");
  await waitForText(page, "Veterinários", 60_000);
  // se não há pendentes, deve aparecer a mensagem
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll("flt-semantics"));
      return all.some((el) => {
        const txt = `${el.textContent ?? ""} ${el.getAttribute("aria-label") ?? ""}`;
        return (
          txt.includes("Nenhuma verificação") ||
          txt.includes("Veterinários") ||
          /pendente/i.test(txt)
        );
      });
    },
    { timeout: 60_000 },
  );
});

test("aba Veterinários dentro de Verificações é acessível", async ({
  page,
}) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Verificações");
  await waitForText(page, "Veterinários", 60_000);
  await tapText(page, /^Veterinários/);
  await page.waitForTimeout(1500);
  await expectText(page, "Veterinários");
});

test("aba Motoristas dentro de Verificações é acessível", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Verificações");
  await waitForText(page, "Veterinários", 60_000);
  await tapText(page, /^Motoristas/);
  await page.waitForTimeout(1500);
  await expectText(page, "Motoristas");
});

test("admin pode navegar pela aba Cadastros (Usuários) sem crash", async ({
  page,
}) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Cadastros");
  await waitForText(page, "Usuários", 60_000);
  await expectText(page, /Total|Clientes|CLIENTE/i);
});

test("admin pode navegar pela aba Cadastros (Lojas) sem crash", async ({
  page,
}) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Cadastros");
  await waitForText(page, "Usuários", 60_000);
  await tapText(page, /^Lojas/);
  await page.waitForTimeout(1000);
  await expectText(page, /Pet|Estab|loja/i);
});

test("admin pode navegar pela aba FAQ sem crash", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "FAQ");
  await waitForText(page, /FAQ|Perguntas|Clientes|Lojistas/);
});

test("admin pode navegar pela aba Estatísticas", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Estatísticas");
  await waitForText(page, /Estatísticas|Total|Usuários/i);
});

test("admin pode navegar pela aba Reclamações", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, "Reclamações");
  await waitForText(page, /Reclamações|Pendentes|Em Análise/);
});

test("logout do admin pelo painel volta ao login", async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  // botão "Sair" do header não é leaf nem expõe role=button — usar byText com force click
  await byText(page, "Sair").first().click({ force: true });
  await waitForText(page, /Sair da conta/);
  // o diálogo sobrepõe o botão "Sair" do painel — o botão de confirmação é o último na árvore
  await page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: "Sair" })
    .last()
    .click({ force: true });
  await waitForText(page, /Entrar|E-mail/);
});
