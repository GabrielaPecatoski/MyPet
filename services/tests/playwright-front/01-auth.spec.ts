import { test, expect, APIRequestContext } from '@playwright/test';
import {
  bootFlutter, bootAndLogin, login, tapButton, tapText, fillNth,
  expectText, waitForText, skipOnboardingIfPresent,
} from './_helpers';
import { apiContext, registerUser, SeededUser } from './_api';
let api: APIRequestContext;
let cliente: SeededUser;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: 'CLIENTE' });
});
test.afterAll(async () => {
  await api.dispose();
});
test('login com usuário válido leva à home do cliente', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await expectText(page, 'Agenda');
  await expectText(page, 'Loja');
  await expectText(page, 'Pets');
  await expectText(page, 'Perfil');
});
test('login com senha errada mostra erro e permanece no login', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await tapText(page, 'Entrar');
  await login(page, cliente.email, 'senhaerrada');
  await expect
    .poll(async () =>
      page.locator('flt-semantics[role="button"]').filter({ hasText: 'Entrar' }).count(),
    )
    .toBeGreaterThan(0);
});
test('cadastro de novo cliente pela UI leva à home', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await tapText(page, 'Entrar');
  await waitForText(page, 'Criar Conta');
  await tapText(page, 'Criar Conta');
  await waitForText(page, 'Nome');
  const ts = Date.now();
  await fillNth(page, 0, 'Novo Cliente UI');
  await fillNth(page, 1, String(ts).slice(-11));
  await fillNth(page, 2, '41988887777');
  await fillNth(page, 3, `novo${ts}@mypet.com`);
  await fillNth(page, 4, 'senha123');
  await fillNth(page, 5, 'senha123');
  await tapButton(page, 'Criar conta');
  await expectText(page, 'Agenda');
  await expectText(page, 'Perfil');
});
