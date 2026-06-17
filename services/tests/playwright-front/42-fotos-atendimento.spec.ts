import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  SeededUser,
  seedBooking,
  seedFullEstablishment,
  setAttendancePhotos,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  openClientTab,
  scrollToText,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

// 1px base64 jpeg-ish data URLs — conteúdo não precisa ser imagem válida,
// só exercita o fluxo de dados ponta a ponta (back -> UI).
const FOTO_A = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBA";
const FOTO_B = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBB";

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

test("cliente vê as fotos do atendimento na sua agenda", async ({ page }) => {
  // serviço concluído + fotos anexadas pelo estabelecimento (via back real)
  const seed = await seedBooking(api, owner, estab, {
    finalStatus: "CONCLUIDO",
  });
  await setAttendancePhotos(api, owner, seed.booking.id, [FOTO_A, FOTO_B]);

  await bootAndLogin(page, seed.cliente.email, seed.cliente.password);
  // serviço concluído fica na aba Histórico
  await openClientTab(page, "Agenda", "Histórico");
  await tapText(page, "Histórico");
  await scrollToText(page, seed.pet.name);

  // a seção de fotos aparece com a contagem vinda do backend
  await scrollToText(page, "Fotos do atendimento (2)");
  await expectText(page, "Fotos do atendimento (2)");
});

test("estabelecimento abre o gerenciador de fotos do atendimento", async ({
  page,
}) => {
  // agendamento confirmado de hoje aparece na agenda do estabelecimento
  const seed = await seedBooking(api, owner, estab, {
    finalStatus: "CONFIRMADO",
  });

  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Agenda");
  await waitForText(page, seed.pet.name, 40_000);

  // botão dedicado abre o sheet de fotos do atendimento
  await tapButton(page, "Fotos do atendimento");
  // o sheet abre; no Flutter Web a captura é desabilitada e exibe o aviso
  await expectText(page, "Registre o atendimento");
  await expectText(page, "apenas no app");
});
