/**
 * Testa os toggles e a navegação do painel do veterinário (UI nova):
 *  - toggles de domicílio e emergência 24h aparecem na home
 *  - o card de toggle é tappável (texto vira aria-label → clicar via byText)
 *  - perfil exibe CRMV/especialidade
 *  - navegação por todas as abas (Agenda usa pollTap por causa do botão "Ver agenda")
 */
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
let vet: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  vet = await registerUser(api, {
    role: "VETERINARIO",
    namePrefix: "Vet Domicilio E2E",
  });
  try {
    await registerVet(api, vet, { especialidade: "Dermatologia" });
  } catch (_) {
    /* já existe */
  }
});

test.afterAll(async () => {
  await api.dispose();
});

test("home do vet exibe toggle de atendimento domiciliar", async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, "MY PET · VETERINÁRIO");
  // card tappável → texto vai pro aria-label; usar string exata (não regex, que olha só textContent)
  await expectText(page, "Atendimento domiciliar inativo");
});

test("home do vet exibe toggle de emergência 24h", async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, "MY PET · VETERINÁRIO");
  await expectText(page, "Emergências 24h desativado");
});

test("clicar no toggle domiciliar muda o texto de estado", async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, "Atendimento domiciliar inativo");
  await byText(page, "Atendimento domiciliar inativo")
    .first()
    .click({ force: true });
  await waitForText(page, "Atendimento domiciliar ativo");
});

test("clicar no toggle de emergência 24h muda estado", async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, "Emergências 24h desativado");
  await byText(page, "Emergências 24h desativado")
    .first()
    .click({ force: true });
  await waitForText(page, "Atender emergências 24h");
});

test("perfil do vet exibe CRMV e especialidade cadastrados", async ({
  page,
}) => {
  await bootAndLogin(page, vet.email, vet.password);
  await pollTap(page, "Perfil", /CRMV|Registro|Dermatologia/);
  await expectText(page, /Dermatologia/);
});

test("vet pode navegar por todas as abas sem crash", async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, "MY PET · VETERINÁRIO");

  await pollTap(page, /^Agenda$/, "Hoje"); // "Ver agenda" (no-op) intercepta o seletor por substring
  await pollTap(page, "Chamados", /Chamados|Nenhum chamado/);
  await pollTap(page, "Pacientes", /Pacientes|Nenhum paciente/);
  await pollTap(page, "Perfil", /CRMV|Sair da conta/);
  await pollTap(page, "Início", "MY PET · VETERINÁRIO");
});
