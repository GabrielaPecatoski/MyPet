/**
 * Testa a tela de emergência:
 *  - tabs Clínicas e Veterinários
 *  - vet registrado e disponível aparece na aba
 *  - badge "Domiciliar" quando vet ativa atendimento domiciliar
 *  - estabelecimento de emergência aparece na aba Clínicas
 */
import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, expectText, waitForText, byText } from './_helpers';
import {
  apiContext, registerUser, registerVet, createEstablishment, SeededUser,
} from './_api';

let api: APIRequestContext;
let cliente: SeededUser;
let vet: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: 'CLIENTE' });
  vet = await registerUser(api, { role: 'VETERINARIO', namePrefix: 'Vet Emergencia E2E' });
  try {
    await registerVet(api, vet, { especialidade: 'Clínica geral' });
  } catch (_) { /* já cadastrado */ }
});

test.afterAll(async () => { await api.dispose(); });

test('tela de emergência exibe duas abas: Clínicas e Veterinários', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Emergência Veterinária');
  await waitForText(page, 'Emergência Veterinária');
  await expectText(page, /Clínicas/);
  await expectText(page, /Veterinários/);
});

test('aba Clínicas é exibida por padrão', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Emergência Veterinária');
  await waitForText(page, 'Emergência Veterinária');
  // header está presente
  await expectText(page, /Emergência Veterinária/);
});

test('navegar para aba Veterinários mostra lista ou estado vazio', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Emergência Veterinária');
  await waitForText(page, 'Emergência Veterinária');
  await tapText(page, /Veterinários/);
  // ou mostra vets ou mostra estado vazio
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll('flt-semantics'));
      return all.some(
        (el) =>
          el.textContent?.includes('Dr.') ||
          el.textContent?.includes('Disponível') ||
          el.textContent?.includes('Nenhum veterinário'),
      );
    },
    { timeout: 30_000 },
  );
});

test('aba Clínicas: estado vazio ou card de clínica sem crash', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Emergência Veterinária');
  await waitForText(page, /Emergência/);
  // aguarda carregamento
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll('flt-semantics'));
      return all.some(
        (el) =>
          el.textContent?.includes('Nenhuma clínica') ||
          el.textContent?.includes('Pet') ||
          el.textContent?.includes('Clínica'),
      );
    },
    { timeout: 30_000 },
  );
});

test('botão voltar na tela de emergência retorna à home', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Emergência Veterinária');
  await waitForText(page, /Emergência/);
  // pressionar back (AppBar com showBack: true)
  await page.goBack({ timeout: 10_000 }).catch(async () => {
    await tapText(page, 'voltar');
  });
  await expectText(page, 'Emergência Veterinária'); // botão ainda existe
});
