import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, expectText, openClientTab } from './_helpers';
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
test('cliente cancela um agendamento pago e o valor é estornado', async ({ page }) => {
  const seed = await seedBooking(api, owner, estab, { pay: true });
  await bootAndLogin(page, seed.cliente.email, seed.cliente.password);
  await openClientTab(page, 'Agenda', seed.pet.name);
  await tapButton(page, 'Cancelar agendamento');
  await tapButton(page, 'Cancelar', true);
  await expectText(page, 'Agendamento cancelado');
  await tapText(page, 'Histórico');
  await expectText(page, 'Valor estornado');
});
