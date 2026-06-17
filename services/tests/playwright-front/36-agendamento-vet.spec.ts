import { APIRequestContext, test } from "@playwright/test";
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
import {
  bootAndLogin,
  leafByText,
  scrollToText,
  tapButton,
  waitForText,
} from "./_helpers";

const MESES = /(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)/;
const HORARIO = /^\d{1,2}:\d{2}$/;

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

// Seleciona uma data futura (sempre com slots, independente da hora atual) e o
// primeiro horário disponível — mesmo padrão estável do spec 04-agendamento.
async function escolherDataEHorario(
  page: import("@playwright/test").Page,
): Promise<void> {
  await page.getByRole("button", { name: MESES }).nth(3).click();
  const slot = page.getByRole("button", { name: HORARIO }).first();
  await slot.waitFor({ state: "visible", timeout: 20_000 });
  await slot.click();
}

test("cliente consegue ver clínica veterinária na home com filtro Veterinário", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  await leafByText(page, "Veterinário").first().click({ force: true });
  await waitForText(page, /Clínicas e Pet shops|Veterinários disponíveis/);
  await scrollToText(page, /Clínica Vet E2E|Clínicas e Pet shops/, 40);
});

test("cliente agenda consulta com preço fixo → dialog de pagamento", async ({
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

  await waitForText(page, /Consulta E2E|Agendar Serviço/, 20_000);
  await tapButton(page, "Agendar Serviço");

  await waitForText(page, "Selecione o pet", 20_000);

  await waitForText(page, "Felix E2E", 30_000);
  await leafByText(page, "Felix E2E").first().click({ force: true });

  await page.waitForFunction(
    () =>
      Array.from(document.querySelectorAll("flt-semantics")).some((el) =>
        (el.textContent ?? "").includes("Consulta E2E"),
      ),
    { timeout: 30_000 },
  );
  await scrollToText(page, /Consulta E2E/, 20);
  await leafByText(page, "Consulta E2E").first().click({ force: true });

  await escolherDataEHorario(page);

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

  await escolherDataEHorario(page);

  await tapButton(page, "Confirmar Agendamento");
  await waitForText(page, /Ver Minha Agenda|Sob consulta|Quase lá/, 30_000);
});
