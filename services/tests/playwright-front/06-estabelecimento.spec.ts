import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, expectText, waitForText } from './_helpers';
import {
  apiContext, registerUser, createEstablishment, addService, createProduct, SeededUser,
} from './_api';

let api: APIRequestContext;
let owner: SeededUser;
let produtoNome: string;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab E2E' });
  const estab = await createEstablishment(api, owner, { name: `Pet Shop E2E ${Date.now()}` });
  await addService(api, owner, estab.id, { name: 'Tosa E2E' });
  produtoNome = `Coleira E2E ${Date.now().toString().slice(-4)}`;
  await createProduct(api, owner, estab.id, { name: produtoNome });
});

test.afterAll(async () => { await api.dispose(); });

test('login de vendedor abre o painel e navega para Produtos', async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);

  await expectText(page, 'Agenda');
  await expectText(page, 'Produtos');
  await expectText(page, 'Avaliações');
  await expectText(page, 'Estatísticas');

  await tapText(page, 'Produtos');
  await waitForText(page, produtoNome, 40_000);
});
