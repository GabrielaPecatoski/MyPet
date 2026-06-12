import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, expectText, waitForText } from './_helpers';
import {
  apiContext, registerUser, createPet, seedFullEstablishment, createBooking, payBooking, SeededUser,
} from './_api';

let api: APIRequestContext;
let owner: SeededUser;
let petName: string;

test.beforeAll(async () => {
  api = await apiContext();
  const serviceName = 'Banho E2E';
  const seed = await seedFullEstablishment(api, serviceName);
  owner = seed.owner;

  const cliente = await registerUser(api, { role: 'CLIENTE' });
  const pet = await createPet(api, cliente, { name: `Bidu ${Date.now().toString().slice(-4)}` });
  petName = pet.name;

  const hoje = new Date();
  hoje.setHours(12, 0, 0, 0);
  const booking = await createBooking(api, cliente, {
    petId: pet.id,
    petName: pet.name,
    serviceName,
    establishmentId: seed.estab.id,
    establishmentName: seed.estab.name,
    price: 80,
    scheduledAt: hoje,
  });
  await payBooking(api, cliente, booking.id);
});

test.afterAll(async () => { await api.dispose(); });

test('estabelecimento vê e confirma um agendamento pago', async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);

  await tapText(page, 'Agenda');
  await waitForText(page, petName, 40_000);

  await tapButton(page, 'Confirmar');
  await expectText(page, 'Agendamento confirmado!');
});
