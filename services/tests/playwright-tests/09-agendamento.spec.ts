import { APIRequestContext, expect, test } from "@playwright/test";
import {
  addService,
  apiContext,
  createBooking,
  createEstablishment,
  createPet,
  payBooking,
  registerUser,
  SeededUser,
  setSchedule,
  updateBookingStatus,
} from "../playwright-front/_api";

const authHeader = (u: SeededUser) => ({ Authorization: `Bearer ${u.token}` });

let api: APIRequestContext;
let owner: SeededUser;
let cliente: SeededUser;
let estabId: string;
let estabName: string;
let serviceName: string;
let petId: string;
let petName: string;
let bookingId: string;

function futureDate(days = 3): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab API Agenda",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Agenda ${Date.now()}`,
  });
  estabId = estab.id;
  estabName = estab.name;
  const service = await addService(api, owner, estabId, {
    name: `Banho Agenda ${Date.now()}`,
  });
  serviceName = service.name;
  cliente = await registerUser(api, { role: "CLIENTE" });
  const pet = await createPet(api, cliente, { name: `Pet Agenda ${Date.now()}` });
  petId = pet.id;
  petName = pet.name;
});

test.afterAll(async () => {
  await api.dispose();
});

// ---- Disponibilidade ----

test("POST /availability/schedule define a agenda", async () => {
  const schedule = await setSchedule(api, owner, estabId);
  expect(schedule).toBeTruthy();
});

test("GET /availability/schedule/:id retorna a agenda", async () => {
  const res = await api.get(`/availability/schedule/${estabId}`, {
    headers: authHeader(owner),
  });
  expect(res.status()).toBe(200);
});

test("GET /availability/:id?date= retorna horários disponíveis (público)", async () => {
  const res = await api.get(`/availability/${estabId}?date=${futureDate()}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body.slots)).toBe(true);
});

test("bloquear e desbloquear horário", async () => {
  const date = futureDate(4);
  const block = await api.post("/availability/block", {
    headers: authHeader(owner),
    data: {
      establishmentId: estabId,
      date,
      startTime: "08:00",
      endTime: "09:00",
      reason: "Manutenção",
    },
  });
  expect([200, 201, 204]).toContain(block.status());

  // o endpoint não retorna o bloqueio; busca na listagem para obter o id
  const blocked: any[] = await (
    await api.get(`/availability/blocked/${estabId}`, {
      headers: authHeader(owner),
    })
  ).json();
  expect(Array.isArray(blocked)).toBe(true);
  // a listagem serializa a entidade crua (campos privados com prefixo "_")
  const created = blocked.find((b) => (b._date ?? b.date) === date);
  const blockId = created?._id ?? created?.id;
  expect(blockId).toBeTruthy();

  const del = await api.delete(`/availability/block/${blockId}`, {
    headers: authHeader(owner),
  });
  expect(del.status()).toBe(204);
});

// ---- Agendamentos ----

test("GET /bookings/user/:id começa vazio", async () => {
  const res = await api.get(`/bookings/user/${cliente.id}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
  expect(body.length).toBe(0);
});

test("POST /bookings cria agendamento (PENDENTE)", async () => {
  const scheduledAt = new Date();
  scheduledAt.setDate(scheduledAt.getDate() + 3);
  scheduledAt.setHours(12, 0, 0, 0);
  const booking = await createBooking(api, cliente, {
    petId,
    petName,
    serviceName,
    establishmentId: estabId,
    establishmentName: estabName,
    price: 80,
    scheduledAt,
  });
  bookingId = booking.id;
  expect(booking.id).toBeTruthy();
  // serviço de preço fixo entra aguardando pagamento
  expect(booking.status).toBe("AGUARDANDO_PAGAMENTO");
});

test("GET /bookings/:id retorna o agendamento", async () => {
  const res = await api.get(`/bookings/${bookingId}`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  expect((await res.json()).id).toBe(bookingId);
});

test("PATCH /bookings/:id/pay processa o pagamento", async () => {
  const result = await payBooking(api, cliente, bookingId);
  expect(result).toBeTruthy();
});

test("estabelecimento confirma o agendamento (status CONFIRMADO)", async () => {
  const updated = await updateBookingStatus(
    api,
    owner,
    bookingId,
    "CONFIRMADO",
  );
  expect(updated.status).toBe("CONFIRMADO");
});

test("cliente cancela o agendamento", async () => {
  const res = await api.patch(`/bookings/${bookingId}/cancel`, {
    headers: authHeader(cliente),
  });
  expect(res.status()).toBe(200);
  expect((await res.json()).status).toBe("CANCELADO");
});

test("agendamento exige autenticação (401 sem token)", async () => {
  const res = await api.get(`/bookings/user/${cliente.id}`);
  expect(res.status()).toBe(401);
});
