import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, expectText, waitForText } from './_helpers';
import {
  apiContext, registerUser, createEstablishment, seedPaidOrder, SeededUser,
} from './_api';

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab E2E' });
  const estab = await createEstablishment(api, owner, { name: `Pet Shop E2E ${Date.now()}` });
  estabId = estab.id;
});

test.afterAll(async () => { await api.dispose(); });

test('cliente vê o acompanhamento do pedido na loja', async ({ page }) => {
  const seed = await seedPaidOrder(api, owner, estabId);

  await bootAndLogin(page, seed.cliente.email, seed.cliente.password);
  await tapText(page, 'Loja');
  await tapText(page, 'Pedidos');

  await expectText(page, 'Enviando já');
  await expectText(page, 'Indo até o endereço');
});

test('estabelecimento acompanha e avança o pedido até finalizado', async ({ page }) => {
  await seedPaidOrder(api, owner, estabId);

  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, 'Produtos');
  await tapText(page, 'Pedidos');

  await waitForText(page, 'Enviando já', 40_000);
  await tapText(page, 'Saiu para entrega');
  await expectText(page, 'Indo até o endereço');
  await tapText(page, 'Finalizar pedido');
  await expectText(page, 'Finalizado');
});
