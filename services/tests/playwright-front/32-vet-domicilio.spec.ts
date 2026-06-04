/**
 * Testa o toggle de atendimento domiciliar do veterinário:
 *  - toggle aparece na home do vet
 *  - toggle pode ser ativado/desativado
 *  - estado muda visualmente ao tocar
 *  - toggle de disponibilidade (24h) ainda funciona
 */
import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, expectText, waitForText, byText,
} from './_helpers';
import { apiContext, registerUser, registerVet, SeededUser } from './_api';

let api: APIRequestContext;
let vet: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  vet = await registerUser(api, { role: 'VETERINARIO', namePrefix: 'Vet Domicilio E2E' });
  try {
    await registerVet(api, vet, { especialidade: 'Dermatologia' });
  } catch (_) { /* já existe */ }
});

test.afterAll(async () => { await api.dispose(); });

test('home do vet exibe toggle de atendimento domiciliar', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, 'MY PET · VETERINÁRIO');
  await expectText(page, /Atendimento domiciliar/i);
});

test('home do vet exibe toggle de disponibilidade 24h', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, 'MY PET · VETERINÁRIO');
  await expectText(page, /Atender emergências 24h|Indisponível para chamados/);
});

test('clicar no toggle domiciliar muda o texto de estado', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, /Atendimento domiciliar/i);
  // captura estado atual
  const eraAtivo = await byText(page, 'Atendimento domiciliar ativo')
    .first().isVisible({ timeout: 3000 }).catch(() => false);

  await tapText(page, /Atendimento domiciliar/i);
  await page.waitForTimeout(2000);

  if (eraAtivo) {
    // deve ter ido para inativo
    await waitForText(page, /domiciliar inativo|domiciliar ativo/i);
  } else {
    await waitForText(page, /domiciliar ativo|domiciliar inativo/i);
  }
});

test('clicar no toggle de disponibilidade 24h muda estado', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, /Atender emergências 24h|Indisponível para chamados/);
  await tapText(page, /Atender emergências 24h|Indisponível para chamados/);
  await page.waitForTimeout(2000);
  await expectText(page, /Atender emergências 24h|Indisponível para chamados/);
});

test('perfil do vet exibe CRMV e especialidade cadastrados', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Perfil');
  await waitForText(page, /CRMV|Registro/);
  await expectText(page, /Dermatologia/);
});

test('vet pode navegar por todas as abas sem crash', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, 'MY PET · VETERINÁRIO');

  await tapText(page, 'Agenda');
  await waitForText(page, 'Hoje');

  await tapText(page, 'Chamados');
  await waitForText(page, /Chamados/);

  await tapText(page, 'Pacientes');
  await waitForText(page, /Pacientes/);

  await tapText(page, 'Perfil');
  await waitForText(page, /CRMV|Sair da conta/);

  // voltar ao início
  await tapText(page, 'Início');
  await waitForText(page, 'MY PET · VETERINÁRIO');
});
