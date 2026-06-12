import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, fillNth, expectText, waitForText } from './_helpers';
import { apiContext, registerUser, SeededUser } from './_api';

let api: APIRequestContext;
let cliente: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: 'CLIENTE' });
});

test.afterAll(async () => { await api.dispose(); });

test('editar perfil e fazer logout pela UI', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);

  await tapText(page, 'Perfil');
  await expectText(page, cliente.name);
  await expectText(page, cliente.email);

  await tapText(page, 'Editar Perfil');
  await waitForText(page, 'Nome Completo');
  const novoNome = `Cliente Editado ${Date.now().toString().slice(-4)}`;
  await fillNth(page, 0, novoNome);
  await fillNth(page, 1, '41955554444');
  await tapButton(page, 'Salvar Alterações');

  await expectText(page, novoNome);

  await tapText(page, 'Sair');
  await waitForText(page, 'Entrar');
});

test('excluir conta pela UI volta ao login', async ({ page }) => {
  const descartavel = await registerUser(api, { role: 'CLIENTE' });
  await bootAndLogin(page, descartavel.email, descartavel.password);

  await tapText(page, 'Perfil');
  await tapText(page, 'Excluir Conta');
  await waitForText(page, 'Excluir conta');
  await tapButton(page, 'Excluir', true);

  await waitForText(page, 'Entrar');
});
