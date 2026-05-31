import { test, expect, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, expectText, waitForText, openClientTab } from './_helpers';
import {
  apiContext, seedFullEstablishment, seedBooking, getEstablishmentReviews, SeededUser,
} from './_api';

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

test('cliente avalia serviço concluído e a nota persiste no backend', async ({ page }) => {
  const seed = await seedBooking(api, owner, estab, { finalStatus: 'CONCLUIDO' });

  await bootAndLogin(page, seed.cliente.email, seed.cliente.password);

  await openClientTab(page, 'Agenda', 'Histórico');
  await tapText(page, 'Histórico');
  await waitForText(page, seed.pet.name, 40_000);

  await tapButton(page, 'Avaliar estabelecimento');
  await waitForText(page, 'Como foi sua experiência?');

  const starButtons = page.getByRole('button', { name: '' });
  await expect.poll(async () => starButtons.count(), { timeout: 20_000 }).toBeGreaterThanOrEqual(5);
  await starButtons.nth(4).click({ force: true });

  await tapButton(page, 'Enviar Avaliação');
  await expectText(page, 'Avaliação enviada!');

  await expect.poll(
    async () => (await getEstablishmentReviews(api, estab.id)).length,
    { timeout: 15_000 },
  ).toBeGreaterThan(0);
});
