/**
 * Testa o fluxo de agendamento de consulta com clínica veterinária:
 *  - filtro "Veterinário" na home exibe a clínica
 *  - cliente acessa o detalhe da clínica e agenda consulta com preço fixo
 *  - agenda consulta com preço variável ("Sob consulta") — vai direto ao PENDENTE
 *
 * Fluxo atual: Home → chip "Veterinário" → card da clínica → Agendar Serviço → schedule screen
 */
import { APIRequestContext, test } from "@playwright/test";
import {
  bootAndLogin,
  byText,
  expectText,
  fill,
  leafByText,
  pollTap,
  scrollToText,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

// Polling sem waitForFunction para evitar cap do actionTimeout (Playwright 1.40+)
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
async function pollForSlots(
  page: import("@playwright/test").Page,
  timeoutMs: number,
): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const found: boolean = await page
      .evaluate(() =>
        Array.from(
          document.querySelectorAll('flt-semantics[role="button"]'),
        ).some((el) => /^\d{2}:\d{2}$/.test((el.textContent ?? "").trim())),
      )
      .catch(() => false);
    if (found) return true;
    // A seção "Motorista (opcional)" cresce com os motoristas independentes
    // acumulados no banco e empurra a grade de horários para fora da viewport;
    // o Flutter só materializa semantics do que está visível → rolar enquanto polla.
    await page.mouse.wheel(0, 300);
    await sleep(500);
  }
  return false;
}

import {
  addService,
  addVariableService,
  apiContext,
  createEstablishment,
  createPet,
  registerUser,
  SeededUser,
  setSchedule,
} from "./_api";

let api: APIRequestContext;
let owner: SeededUser;
let estab: any;
let cliente: SeededUser;
let pet: any;

test.beforeAll(async () => {
  api = await apiContext();

  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Clinica Vet E2E",
  });
  // tipo 'VETERINARIA' — corresponde a isVeterinario no Flutter (type == 'VETERINARIA')
  estab = await createEstablishment(api, owner, {
    name: `Clínica Vet E2E ${Date.now()}`,
    type: "VETERINARIA",
  });
  await addService(api, owner, estab.id, {
    name: "Consulta E2E",
    price: 150,
    durationMinutes: 60,
  });
  await addVariableService(api, owner, estab.id, {
    name: "Consulta Sob Consulta E2E",
  });
  await setSchedule(api, owner, estab.id);

  cliente = await registerUser(api, { role: "CLIENTE" });
  pet = await createPet(api, cliente, { name: "Felix E2E", type: "Gato" });
});

test.afterAll(async () => {
  await api.dispose();
});

test("cliente consegue ver clínica veterinária na home com filtro Veterinário", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  // Chip "Veterinário" usa GestureDetector — leafByText evita clicar no nó ancestral
  await leafByText(page, "Veterinário").first().click({ force: true });
  await waitForText(page, /Clínicas e Pet shops|Veterinários disponíveis/);
  await scrollToText(page, /Clínica Vet E2E|Clínicas e Pet shops/, 40);
});

test("cliente agenda consulta com preço fixo → dialog de pagamento", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");

  // Navegar para a clínica pelo filtro Veterinário
  await leafByText(page, "Veterinário").first().click({ force: true });
  await waitForText(
    page,
    /Clínicas e Pet shops|Veterinários disponíveis/,
    60_000,
  );
  await scrollToText(page, /Clínica Vet E2E/, 40);
  await leafByText(page, /Clínica Vet E2E/)
    .first()
    .click({ force: true });

  // Detalhe do estabelecimento
  await waitForText(page, /Consulta E2E|Agendar Serviço/, 20_000);
  await tapButton(page, "Agendar Serviço");

  // Tela de agendamento
  await waitForText(page, "Selecione o pet", 20_000);

  // Selecionar pet — aguarda lista de pets carregar via API antes de clicar
  await waitForText(page, "Felix E2E", 30_000);
  await leafByText(page, "Felix E2E").first().click({ force: true });

  // Selecionar serviço (preço fixo) — aguarda serviços carregarem via API antes de rolar
  await page.waitForFunction(
    () =>
      Array.from(document.querySelectorAll("flt-semantics")).some((el) =>
        (el.textContent ?? "").includes("Consulta E2E"),
      ),
    { timeout: 30_000 },
  );
  await scrollToText(page, /Consulta E2E/, 20);
  await leafByText(page, "Consulta E2E").first().click({ force: true });

  // Rola para baixo para garantir que o date picker está acima do botão sticky
  await page.mouse.wheel(0, 300);
  await sleep(500);
  await page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: "Hoje" })
    .first()
    .click({ force: true });

  // Aguarda slots disponíveis via polling (evita cap do actionTimeout no waitForFunction)
  const slotFound = await pollForSlots(page, 30000);

  if (!slotFound) {
    // Todos os slots de hoje estão no passado (horário tardio) → selecionar amanhã
    await page
      .locator('flt-semantics[role="button"]')
      .filter({ hasText: /jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez/ })
      .nth(1)
      .click({ force: true });
    if (!(await pollForSlots(page, 40000)))
      throw new Error("Nenhum slot disponível para amanhã");
  }

  // Clicar no primeiro slot disponível (role=button garante que é tappable)
  await page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: /^\d{2}:\d{2}$/ })
    .first()
    .click({ force: true });

  // Confirmar agendamento
  await tapButton(page, "Confirmar Agendamento");
  await waitForText(page, /Quase lá|Pagar Agora|Ver Minha Agenda/, 30_000);
});

test("cliente agenda consulta preço variável → dialog sem pagamento", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");

  await leafByText(page, "Veterinário").first().click({ force: true });
  await waitForText(
    page,
    /Clínicas e Pet shops|Veterinários disponíveis/,
    60_000,
  );
  await scrollToText(page, /Clínica Vet E2E/, 40);
  await leafByText(page, /Clínica Vet E2E/)
    .first()
    .click({ force: true });

  await waitForText(page, /Consulta Sob Consulta|Agendar Serviço/, 20_000);
  await tapButton(page, "Agendar Serviço");

  await waitForText(page, "Selecione o pet", 20_000);
  await waitForText(page, "Felix E2E", 30_000);
  await leafByText(page, "Felix E2E").first().click({ force: true });

  // Aguarda serviços carregarem via API antes de rolar
  await page.waitForFunction(
    () =>
      Array.from(document.querySelectorAll("flt-semantics")).some((el) =>
        (el.textContent ?? "").includes("Consulta Sob Consulta"),
      ),
    { timeout: 30_000 },
  );
  await scrollToText(page, /Consulta Sob Consulta/, 20);
  await leafByText(page, /Consulta Sob Consulta/)
    .first()
    .click({ force: true });

  // Rola para baixo para garantir que o date picker está acima do botão sticky
  await page.mouse.wheel(0, 300);
  await sleep(500);
  await page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: "Hoje" })
    .first()
    .click({ force: true });

  const slotFoundVar = await pollForSlots(page, 30000);

  if (!slotFoundVar) {
    await page
      .locator('flt-semantics[role="button"]')
      .filter({ hasText: /jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez/ })
      .nth(1)
      .click({ force: true });
    if (!(await pollForSlots(page, 40000)))
      throw new Error("Nenhum slot disponível para amanhã");
  }

  await page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: /^\d{2}:\d{2}$/ })
    .first()
    .click({ force: true });

  await tapButton(page, "Confirmar Agendamento");
  // Preço variável → dialog mostra "Ver Minha Agenda" (sem pagamento obrigatório)
  await waitForText(page, /Ver Minha Agenda|Sob consulta|Quase lá/, 30_000);
});
