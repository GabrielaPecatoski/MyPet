import { APIRequestContext, test } from "@playwright/test";
import {
  addVariableService,
  apiContext,
  createEstablishment,
  createPet,
  createVariablePriceBooking,
  registerUser,
  SeededUser,
  setSchedule,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  leafByText,
  openClientTab,
  pollText,
  scrollToText,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

// Abre a clínica veterinária a partir do filtro "Veterinário" da home — caminho
// estável (a veterinária não fica na listagem padrão de pet shops).
async function abrirVeterinaria(
  page: import("@playwright/test").Page,
  estabNome: string,
): Promise<void> {
  await leafByText(page, "Veterinário").first().click({ force: true });
  await waitForText(
    page,
    /Clínicas e Pet shops|Veterinários disponíveis/,
    30_000,
  );
  await scrollToText(page, estabNome, 40);
  await tapText(page, estabNome);
}

const MESES = /(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)/;
const HORARIO = /^\d{1,2}:\d{2}$/;
let api: APIRequestContext;
let owner: SeededUser;
let cliente: SeededUser;
let estabNome: string;
let estabId: string;
let serviceNome: string;
let petNome: string;
test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Vet E2E",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Veterinária E2E ${Date.now()}`,
    type: "VETERINARIA",
  });
  estabNome = estab.name;
  estabId = estab.id;
  serviceNome = `Consulta ${Date.now().toString().slice(-4)}`;
  await addVariableService(api, owner, estabId, { name: serviceNome });
  await setSchedule(api, owner, estabId);
  cliente = await registerUser(api, { role: "CLIENTE" });
  const pet = await createPet(api, cliente, {
    name: `Mel ${Date.now().toString().slice(-4)}`,
  });
  petNome = pet.name;
});
test.afterAll(async () => {
  await api.dispose();
});
test('serviço com preço variável mostra "Sob consulta" na tela de agendamento', async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await page.waitForTimeout(2000);
  await abrirVeterinaria(page, estabNome);
  await waitForText(page, "Agendar Serviço");
  await tapButton(page, "Agendar Serviço");
  await waitForText(page, "Selecione o pet");
  await expectText(page, "Sob consulta");
  await expectText(page, serviceNome);
});
test("agendar serviço veterinário variável não exige pagamento e vai direto para agenda", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await page.waitForTimeout(2000);
  await abrirVeterinaria(page, estabNome);
  await waitForText(page, "Agendar Serviço");
  await tapButton(page, "Agendar Serviço");
  await waitForText(page, "Selecione o pet");
  await tapText(page, petNome);
  await tapText(page, serviceNome);
  await page.getByRole("button", { name: MESES }).nth(3).click();
  const slot = page.getByRole("button", { name: HORARIO }).first();
  await slot.waitFor({ state: "visible", timeout: 20_000 });
  await slot.click();
  await tapButton(page, "Confirmar Agendamento");
  await waitForText(page, "Sob consulta");
  await pollText(page, /valor será definido pelo estabelecimento/i, 20_000);
  await tapButton(page, "Ver Minha Agenda");
  await openClientTab(page, "Agenda", petNome);
  await expectText(page, "Aguardando confirmação");
});
test("estabelecimento vê e confirma agendamento de preço variável (já entra como PENDENTE)", async ({
  page,
}) => {
  const bCliente = await registerUser(api, { role: "CLIENTE" });
  const bPet = await createPet(api, bCliente, {
    name: `Toby ${Date.now().toString().slice(-4)}`,
  });
  const scheduledAt = new Date();
  scheduledAt.setHours(12, 0, 0, 0);
  await createVariablePriceBooking(api, bCliente, {
    petId: bPet.id,
    petName: bPet.name,
    serviceName: serviceNome,
    establishmentId: estabId,
    establishmentName: estabNome,
    scheduledAt,
  });
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Agenda");
  await pollText(page, bPet.name, 60_000);
  await tapButton(page, "Confirmar");
  await expectText(page, "Agendamento confirmado!");
});
