import { APIRequestContext, expect, test } from "@playwright/test";

const BASE = "http://localhost:3005";

let api: APIRequestContext;
const ts = Date.now();
const userId = `user-booking-${ts}`;
const estabId = `estab-booking-${ts}`;
let bookingId: string;
let blockId: string;

function nextWeekday(day: number): string {
  const d = new Date();
  d.setDate(d.getDate() + ((day - d.getDay() + 7) % 7 || 7));
  return d.toISOString().split("T")[0];
}
const futureDate = nextWeekday(1);

test.beforeAll(async ({ playwright }) => {
  api = await playwright.request.newContext({ baseURL: BASE });
});

test.afterAll(async () => {
  await api.dispose();
});

test("configurar agenda do estabelecimento", async () => {
  const res = await api.post("/availability/schedule", {
    data: {
      establishmentId: estabId,
      slotDurationMinutes: 60,
      days: [
        { dayOfWeek: 1, startTime: "08:00", endTime: "18:00", isOpen: true },
        { dayOfWeek: 2, startTime: "08:00", endTime: "18:00", isOpen: true },
        { dayOfWeek: 3, startTime: "08:00", endTime: "18:00", isOpen: true },
        { dayOfWeek: 4, startTime: "08:00", endTime: "18:00", isOpen: true },
        { dayOfWeek: 5, startTime: "08:00", endTime: "18:00", isOpen: true },
        { dayOfWeek: 6, startTime: "09:00", endTime: "13:00", isOpen: true },
        { dayOfWeek: 0, startTime: "00:00", endTime: "00:00", isOpen: false },
      ],
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.establishmentId).toBe(estabId);
});

test("buscar agenda do estabelecimento", async () => {
  const res = await api.get(`/availability/schedule/${estabId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.days).toBeTruthy();
  expect(body.days.length).toBe(7);
});

test("buscar horários disponíveis", async () => {
  const res = await api.get(`/availability/${estabId}?date=${futureDate}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body.slots)).toBe(true);
  const available = body.slots.filter((s: any) => s.available);
  expect(available.length).toBeGreaterThan(0);
});

test("bloquear horário", async () => {
  const res = await api.post("/availability/block", {
    data: {
      establishmentId: estabId,
      date: futureDate,
      time: "10:00",
      reason: "Manutenção",
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  blockId = body.id;
});

test("horário bloqueado aparece como indisponível", async () => {
  const res = await api.get(`/availability/${estabId}?date=${futureDate}`);
  const body = await res.json();
  const slots: any[] = body.slots;
  const blocked = slots.find((s) => s.time === "10:00");
  expect(blocked?.available).toBe(false);
});

test("listar bloqueios do estabelecimento", async () => {
  const res = await api.get(
    `/availability/blocked/${estabId}?date=${futureDate}`,
  );
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((b) => b.id === blockId)).toBe(true);
});

test("desbloquear horário", async () => {
  const res = await api.delete(`/availability/block/${blockId}`);
  expect(res.status()).toBe(204);
});

test("listar agendamentos de usuário sem bookings retorna array", async () => {
  const res = await api.get(`/bookings/user/${userId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(Array.isArray(body)).toBe(true);
});

test("criar agendamento", async () => {
  const res = await api.post("/bookings", {
    data: {
      userId,
      userName: "Cliente Teste",
      petId: "pet-001",
      petName: "Rex",
      serviceName: "Banho e Tosa",
      establishmentId: estabId,
      establishmentName: "PetShop Teste",
      scheduledAt: `${futureDate}T10:00:00.000Z`,
      price: 80.0,
    },
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeTruthy();
  expect(body.status).toBe("PENDENTE");
  bookingId = body.id;
});

test("buscar agendamento por id", async () => {
  const res = await api.get(`/bookings/${bookingId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.id).toBe(bookingId);
  expect(body.userId).toBe(userId);
});

test("listar agendamentos do usuário inclui booking criado", async () => {
  const res = await api.get(`/bookings/user/${userId}`);
  const body: any[] = await res.json();
  expect(body.some((b) => b.id === bookingId)).toBe(true);
});

test("listar agendamentos do estabelecimento inclui booking", async () => {
  const res = await api.get(`/bookings/establishment/${estabId}`);
  expect(res.status()).toBe(200);
  const body: any[] = await res.json();
  expect(body.some((b) => b.id === bookingId)).toBe(true);
});

test("confirmar agendamento", async () => {
  const res = await api.patch(`/bookings/${bookingId}/status`, {
    data: { status: "CONFIRMADO" },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.status).toBe("CONFIRMADO");
});

test("estatísticas do estabelecimento retornam contagem", async () => {
  const res = await api.get(`/bookings/stats/establishment/${estabId}`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(typeof body.totalBookings).toBe("number");
  expect(body.totalBookings).toBeGreaterThan(0);
});

test("concluir agendamento", async () => {
  const res = await api.patch(`/bookings/${bookingId}/complete`);
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.status).toBe("CONCLUIDO");
});

test("criar e cancelar agendamento", async () => {
  const res = await api.post("/bookings", {
    data: {
      userId,
      userName: "Cliente Teste",
      petId: "pet-001",
      petName: "Rex",
      serviceName: "Banho",
      establishmentId: estabId,
      establishmentName: "PetShop Teste",
      scheduledAt: `${futureDate}T14:00:00.000Z`,
      price: 50.0,
    },
  });
  const booking = await res.json();

  const cancel = await api.patch(`/bookings/${booking.id}/cancel`, {
    headers: { "x-user-id": userId },
  });
  expect(cancel.status()).toBe(200);
  const body = await cancel.json();
  expect(body.status).toBe("CANCELADO");
});

test("recusar agendamento", async () => {
  const res = await api.post("/bookings", {
    data: {
      userId,
      userName: "Cliente Teste",
      petId: "pet-002",
      petName: "Mia",
      serviceName: "Consulta",
      establishmentId: estabId,
      establishmentName: "PetShop Teste",
      scheduledAt: `${futureDate}T16:00:00.000Z`,
      price: 120.0,
    },
  });
  const booking = await res.json();

  const refuse = await api.patch(`/bookings/${booking.id}/status`, {
    data: { status: "RECUSADO" },
  });
  expect(refuse.status()).toBe(200);
  expect((await refuse.json()).status).toBe("RECUSADO");
});
