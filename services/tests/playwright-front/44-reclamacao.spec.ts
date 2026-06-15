import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  getAdmin,
  getMyComplaints,
  resolveComplaint,
  SeededUser,
  seedBooking,
  seedFullEstablishment,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  fill,
  openClientTab,
  tapButton,
  tapText,
  textFields,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let owner: SeededUser;
let estab: { id: string; name: string };

test.beforeAll(async () => {
  api = await apiContext();
  const seed = await seedFullEstablishment(api);
  owner = seed.owner;
  estab = seed.estab;
});
test.afterAll(async () => {
  await api.dispose();
});

test("cliente abre reclamação, acompanha o status e vê a moderação refletida", async ({
  page,
}) => {
  const seed = await seedBooking(api, owner, estab, {
    finalStatus: "CONCLUIDO",
  });
  const subject = `Reclamacao E2E ${Date.now()}`;

  await bootAndLogin(page, seed.cliente.email, seed.cliente.password);

  // 1) ABERTURA — botão "Reclamar" no histórico (Perfil > Histórico) abre o diálogo
  await openClientTab(page, "Perfil", "Editar Perfil");
  await tapText(page, "Histórico");
  await waitForText(page, seed.pet.name, 40_000);
  await tapText(page, "Reclamar");
  await waitForText(page, "Abrir Reclamação");

  // categoria fica no padrão do dropdown; preenche assunto + descrição
  const fields = textFields(page);
  await fill(fields.nth(0), subject);
  await fill(fields.nth(1), "Servico atrasou e o atendimento foi ruim.");
  await tapText(page, "Enviar Reclamação");
  await expectText(page, "Reclamação enviada");

  // 2) STATUS — persiste no backend como PENDENTE
  await expect
    .poll(async () => (await getMyComplaints(api, seed.cliente)).length, {
      timeout: 15_000,
    })
    .toBeGreaterThan(0);
  const created = (await getMyComplaints(api, seed.cliente)).find(
    (c: any) => c.subject === subject,
  );
  expect(created, "reclamação criada deve existir no backend").toBeTruthy();
  expect(created.status).toBe("PENDENTE");

  // 3) STATUS (UI) — tela "Minhas Reclamações" mostra a reclamação como "Aberta"
  await openClientTab(page, "Perfil", "Editar Perfil");
  await tapText(page, "Minhas Reclamações");
  await waitForText(page, subject, 30_000);
  await expectText(page, "Aberta");

  // 4) MODERAÇÃO — admin resolve; reabrindo a tela o cliente vê "Resolvida"
  const admin = await getAdmin(api);
  await resolveComplaint(api, admin, created.id);
  await tapButton(page, "Voltar");
  await waitForText(page, "Editar Perfil", 20_000);
  await tapText(page, "Minhas Reclamações");
  await waitForText(page, subject, 30_000);
  await expectText(page, "Resolvida");
});
