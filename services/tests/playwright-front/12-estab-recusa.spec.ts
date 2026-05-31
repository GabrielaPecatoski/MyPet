import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapButton, expectText, openClientTab } from './_helpers';
import { apiContext, seedFullEstablishment, seedBooking, SeededUser } from './_api';

let api: APIRequestContext;
let owner: SeededUser;
let estab: { id: string; name: string };

test.beforeAll(async () => {
  api = await apiContext();
  const seed = await seedFullEstablishment(api);
  owner = seed.owner;
  estab = seed.estab;
});

test.afterAll(async () => { await api.dispose(); });

test('estabelecimento recusa um agendamento pago e o valor é estornado ao cliente', async ({ page }) => {
  const seed = await seedBooking(api, owner, estab, { pay: true });

  await bootAndLogin(page, owner.email, owner.password);

  await openClientTab(page, 'Agenda', seed.pet.name);

  await tapButton(page, 'Recusar');
  await expectText(page, /estornad|Recusado/i);
});
