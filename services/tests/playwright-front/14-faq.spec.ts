import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, tapButton, expectText, waitForText, fill, fieldByHint, textFields,
} from './_helpers';
import { apiContext, registerUser, SeededUser } from './_api';
let api: APIRequestContext;
let cliente: SeededUser;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: 'CLIENTE' });
});
test.afterAll(async () => { await api.dispose(); });
test('cliente abre a Central de Ajuda, busca FAQ e envia uma dúvida', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Perfil');
  await tapText(page, 'Ajuda');
  await waitForText(page, 'Central de Ajuda');
  await fill(fieldByHint(page, 'Buscar nas perguntas frequentes'), 'agendar');
  await expectText(page, /agendar/i);
  await tapText(page, 'Minhas Dúvidas');
  await tapText(page, 'Enviar dúvida');
  await waitForText(page, 'Cancelar');
  await fill(textFields(page).last(), 'Minha dúvida de teste E2E sobre pagamentos');
  await tapButton(page, 'Enviar');
  await expectText(page, 'Dúvida enviada! Responderemos em breve.');
  await expectText(page, 'Minha dúvida de teste E2E sobre pagamentos');
});
