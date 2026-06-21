import { APIRequestContext, expect, test } from "@playwright/test";
import {
  addService,
  apiContext,
  createBooking,
  createEstablishment,
  createPet,
  getBooking,
  payBooking,
  registerDriver,
  registerUser,
  registerVet,
  SeededUser,
  setSchedule,
  updateBookingStatus,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  scrollToText,
  tapText,
  waitForText,
} from "./_helpers";

// data URLs base64 (conteúdo não precisa ser imagem válida — só exercita o
// round-trip do campo back -> UI, igual ao 42-fotos-atendimento).
const FOTO_ESTAB = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBA";
const FOTO_VET = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBB";
const FOTO_DRIVER = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBC";

let api: APIRequestContext;
let owner: SeededUser;
let cliente: SeededUser;
let estab: { id: string; name: string };
let vetUser: SeededUser;
let vet: { id: string };
let driver: { id: string; name: string };
let petName: string;
let serviceName: string;
let bookingId: string;

function authHdr(u: SeededUser) {
  return { Authorization: `Bearer ${u.token}` };
}
async function getJson(url: string, u: SeededUser) {
  return (await api.get(url, { headers: authHdr(u) })).json();
}

test.beforeAll(async () => {
  api = await apiContext();

  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Fotos E2E",
  });
  estab = await createEstablishment(api, owner, {
    name: `Pet Fotos E2E ${Date.now().toString().slice(-6)}`,
    type: "HIBRIDO",
  });
  // foto de perfil do estabelecimento
  await api.patch(`/establishments/${estab.id}`, {
    headers: authHdr(owner),
    data: { imageUrl: FOTO_ESTAB },
  });
  serviceName = `Banho Fotos ${Date.now().toString().slice(-4)}`;
  await addService(api, owner, estab.id, { name: serviceName });
  await setSchedule(api, owner, estab.id);

  // veterinário COM foto, associado ao estab e aprovado
  vetUser = await registerUser(api, {
    role: "VETERINARIO",
    namePrefix: "Vet Fotos",
  });
  vet = await registerVet(api, vetUser, {
    photoUrl: FOTO_VET,
    establishmentId: estab.id,
  });

  // motorista COM foto, associado e aprovado
  driver = await registerDriver(api, owner, estab.id, {
    name: "Motorista Fotos",
    photoUrl: FOTO_DRIVER,
  });

  // cliente + pet + agendamento confirmado COM motorista (driverPhotoUrl)
  cliente = await registerUser(api, { role: "CLIENTE" });
  const pet = await createPet(api, cliente, {
    name: `Rex Fotos ${Date.now().toString().slice(-4)}`,
  });
  petName = pet.name;
  const scheduledAt = new Date();
  scheduledAt.setDate(scheduledAt.getDate() + 2);
  scheduledAt.setHours(14, 0, 0, 0);
  const booking = await createBooking(api, cliente, {
    petId: pet.id,
    petName: pet.name,
    serviceName,
    establishmentId: estab.id,
    establishmentName: estab.name,
    price: 80,
    scheduledAt,
    driverId: driver.id,
    driverName: driver.name,
    driverPhotoUrl: FOTO_DRIVER,
  });
  bookingId = booking.id;
  await payBooking(api, cliente, bookingId);
  await updateBookingStatus(api, owner, bookingId, "CONFIRMADO");
});

test.afterAll(async () => {
  await api.dispose();
});

test("backend persiste a foto de estabelecimento, veterinário, motorista e do agendamento", async () => {
  const estGet = await getJson(`/establishments/${estab.id}`, owner);
  expect(estGet.imageUrl).toBe(FOTO_ESTAB);

  const vetGet = await getJson(`/veterinarians/${vet.id}`, owner);
  expect(vetGet.photoUrl).toBe(FOTO_VET);

  const drvGet = await getJson(`/drivers/${driver.id}`, owner);
  expect(drvGet.photoUrl).toBe(FOTO_DRIVER);

  const bk = await getBooking(api, cliente, bookingId);
  expect(bk.driverPhotoUrl).toBe(FOTO_DRIVER);
  expect(bk.driverName).toBe(driver.name);
});

test("PATCH /veterinarians/:id/photo atualiza a foto do veterinário", async () => {
  const nova = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBZ";
  const res = await api.patch(`/veterinarians/${vet.id}/photo`, {
    headers: authHdr(owner),
    data: { photoUrl: nova },
  });
  expect(res.ok()).toBeTruthy();
  const vetGet = await getJson(`/veterinarians/${vet.id}`, owner);
  expect(vetGet.photoUrl).toBe(nova);
});

test("cliente vê o motorista do transporte no agendamento (agenda)", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await page
    .getByRole("button", { name: "Agenda", exact: true })
    .first()
    .click();
  // o agendamento confirmado aparece na aba Próximos
  await scrollToText(page, petName);
  // o motorista designado ("Motorista do transporte") aparece com o nome
  await expectText(page, driver.name);
});

test("cliente vê o veterinário no detalhe do estabelecimento", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await scrollToText(page, estab.name);
  await tapText(page, estab.name);
  await waitForText(page, "Agendar Serviço");
  await scrollToText(page, vetUser.name);
});
