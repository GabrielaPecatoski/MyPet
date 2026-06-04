import { test, APIRequestContext } from '@playwright/test';
import {
  bootFlutter, tapText, tapButton, fillNth, expectText, waitForText,
  skipOnboardingIfPresent,
} from './_helpers';
import { apiContext } from './_api';
let api: APIRequestContext;
test.beforeAll(async () => {
  api = await apiContext();
});
test.afterAll(async () => { await api.dispose(); });
test('cadastro de estabelecimento pela UI abre o painel do vendedor', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await tapText(page, 'Estabelecimento');
  await tapButton(page, /Continuar como/);
  await waitForText(page, 'Nome completo');
  const ts = Date.now();
  await fillNth(page, 0, 'Responsavel E2E');
  await fillNth(page, 1, String(ts).slice(-11));
  await fillNth(page, 2, `Pet Shop UI ${ts.toString().slice(-5)}`);
  await fillNth(page, 3, '41977776666');
  await fillNth(page, 4, `estabui${ts}@mypet.com`);
  await fillNth(page, 5, 'senha123');
  await fillNth(page, 6, 'senha123');
  await tapButton(page, 'Criar conta');
  await expectText(page, 'Produtos');
  await expectText(page, 'Avaliações');
  await expectText(page, 'Estatísticas');
});
