import { APIRequestContext, expect, Page, test } from "@playwright/test";
import {
  apiContext,
  createPet,
  registerUser,
  registerVet,
  SeededUser,
  updateVetAvailability,
} from "./_api";
import {
  bootAndLogin,
  fieldByHint,
  fill,
  leafByText,
  pollTap,
  scrollToText,
  tapButton,
  waitForText,
} from "./_helpers";

const MESES = /(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)/;
const HORARIO = /^\d{1,2}:\d{2}$/;
const ENDERECO = "Rua das Acácias 456, Bairro Jardim";

let api: APIRequestContext;
let cliente: SeededUser;
let pet: any;
let vet: any;
let vetName: string;

// Veterinário SEM clínica vinculada (independente) + aprovado + disponível →
// aparece em "Veterinários disponíveis" e cai no fluxo de consulta domiciliar.
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
  pet = await createPet(api, cliente, { name: "Toto E2E", type: "Cachorro" });

  vetName = `VetDom ${Date.now()}`;
  const vetUser = await registerUser(api, {
    role: "VETERINARIO",
    namePrefix: vetName,
  });
  vet = await registerVet(api, vetUser);
  await updateVetAvailability(api, vetUser, vet.id, {
    disponivel: true,
    atendeDomicilio: true,
  });
});

test.afterAll(async () => {
  await api.dispose();
});

async function abrirVetDomiciliar(page: Page): Promise<void> {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, "Emergência Veterinária");
  // pollTap re-tapa o chip até a seção de vets carregar (o tap pode não
  // registrar de primeira no canvas do Flutter).
  await pollTap(
    page,
    "Veterinário",
    /Veterinários disponíveis|Nenhum veterinário/,
    60_000,
  );
  // A lista de vets disponíveis cresce com os acumulados de rodadas anteriores —
  // rola até o vet recém-criado (orçamento maior) e re-tapa até abrir a agenda.
  await page.waitForTimeout(1000);
  await scrollToText(page, new RegExp(vetName), 80);
  await pollTap(page, new RegExp(vetName), "Selecione o pet", 45_000);
}

test("vet sem clínica abre agendamento domiciliar com campo de endereço", async ({
  page,
}) => {
  await abrirVetDomiciliar(page);
  // O campo de endereço aparece justamente ao escolher o veterinário domiciliar.
  await waitForText(page, "Endereço do atendimento", 20_000);
  await waitForText(page, /Consulta domiciliar com/, 10_000);
});

test("cliente agenda consulta domiciliar informando o endereço (sem pagamento)", async ({
  page,
}) => {
  await abrirVetDomiciliar(page);

  await waitForText(page, "Toto E2E", 30_000);
  await leafByText(page, "Toto E2E").first().click({ force: true });

  // Serviço único de consulta domiciliar (preço variável → "Sob consulta").
  // Seleciono pelo preço para não colidir com o banner "Consulta domiciliar com...".
  await page.waitForFunction(
    () =>
      Array.from(document.querySelectorAll("flt-semantics")).some((el) =>
        (el.textContent ?? "").includes("Sob consulta"),
      ),
    { timeout: 30_000 },
  );
  await leafByText(page, "Sob consulta").first().click({ force: true });

  // Endereço do atendimento (obrigatório). fieldByHint mira o campo certo
  // (hint "Rua, número...") e não o campo de busca da home.
  await scrollToText(page, /Endereço do atendimento/, 20);
  await fill(fieldByHint(page, "Rua"), ENDERECO);

  // Data futura + primeiro horário (mesmo padrão estável do spec 04/36).
  await page.getByRole("button", { name: MESES }).nth(3).click();
  const slot = page.getByRole("button", { name: HORARIO }).first();
  await slot.waitFor({ state: "visible", timeout: 20_000 });
  await slot.click();

  await tapButton(page, "Confirmar Agendamento");
  // Preço variável → vai direto para PENDENTE, sem etapa de pagamento.
  await waitForText(page, /Ver Minha Agenda|Sob consulta|Quase lá/, 30_000);

  // Prova no backend: o booking foi criado com o endereço, vinculado ao vet e
  // SEM estabelecimento (consulta domiciliar).
  await expect
    .poll(
      async () => {
        const res = await api.get(`/bookings/user/${cliente.id}`, {
          headers: { Authorization: `Bearer ${cliente.token}` },
        });
        if (!res.ok()) return null;
        const list = await res.json();
        const mine = (Array.isArray(list) ? list : []).find(
          (b: any) => b.vetId === vet.id,
        );
        return mine ? mine.address : null;
      },
      { timeout: 15_000, intervals: [1_000, 2_000, 3_000] },
    )
    .toBe(ENDERECO);

  const res = await api.get(`/bookings/user/${cliente.id}`, {
    headers: { Authorization: `Bearer ${cliente.token}` },
  });
  const list = await res.json();
  const mine = (list as any[]).find((b) => b.vetId === vet.id);
  expect(mine.status).toBe("PENDENTE");
  expect(mine.establishmentId == null || mine.establishmentId === "").toBe(true);
});
