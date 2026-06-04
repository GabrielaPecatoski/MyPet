import { test, expect, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, expectText, waitForText } from './_helpers';
import {
  apiContext, registerUser, createPet, seedFullEstablishment, createBooking, payBooking,
  registerDriver, listDriverTransports, getBooking, SeededUser,
} from './_api';
let api: APIRequestContext;
let owner: SeededUser;
let estab: { id: string; name: string };
let cliente: SeededUser;
let bookingId: string;
let petName: string;
test.beforeAll(async () => {
  api = await apiContext();
  const seed = await seedFullEstablishment(api);
  owner = seed.owner;
  estab = seed.estab;
  await registerDriver(api, owner, estab.id);
  cliente = await registerUser(api, { role: 'CLIENTE' });
  const pet = await createPet(api, cliente, { name: `Thor ${Date.now().toString().slice(-4)}` });
  petName = pet.name;
  const scheduledAt = new Date();
  scheduledAt.setHours(13, 0, 0, 0);
  const booking = await createBooking(api, cliente, {
    petId: pet.id,
    petName: pet.name,
    serviceName: seed.service.name,
    establishmentId: estab.id,
    establishmentName: estab.name,
    price: 80,
    scheduledAt,
  });
  await payBooking(api, cliente, booking.id);
  bookingId = booking.id;
});
test.afterAll(async () => { await api.dispose(); });
test('transporte só aparece ao motorista depois que o estabelecimento aceita', async ({ page }) => {
  const antes = await getBooking(api, cliente, bookingId);
  expect(antes.status).toBe('PENDENTE');
  const filaAntes = await listDriverTransports(api, owner, estab.id);
  expect(filaAntes.some((b) => b.id === bookingId)).toBe(false);
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, 'Agenda');
  await waitForText(page, petName, 40_000);
  await tapButton(page, 'Confirmar');
  await expectText(page, 'Agendamento confirmado!');
  await expect.poll(async () => (await getBooking(api, cliente, bookingId)).status, { timeout: 20_000 })
    .toBe('CONFIRMADO');
  const filaDepois = await listDriverTransports(api, owner, estab.id);
  expect(filaDepois.some((b) => b.id === bookingId)).toBe(true);
});
