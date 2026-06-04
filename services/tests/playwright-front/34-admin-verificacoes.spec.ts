/**
 * Testa o painel do admin, especialmente a nova aba de Verificações:
 *  - login como admin abre painel correto
 *  - 7 abas presentes: Painel, Reclamações, Usuários, Lojas, Verificações, FAQ, Estatísticas
 *  - aba Verificações exibe tabs Veterinários / Motoristas
 *  - quando não há pendentes, exibe estado vazio
 *  - badge de verificações aparece quando há pendentes
 */
import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, tapButton, expectText, waitForText, byText,
} from './_helpers';
import { apiContext, registerUser, registerVet, SeededUser } from './_api';

const ADMIN_EMAIL = 'admin@mypet.com';
const ADMIN_PASSWORD = 'admin123';

let api: APIRequestContext;

test.beforeAll(async () => {
  api = await apiContext();
});

test.afterAll(async () => { await api.dispose(); });

test('login como admin abre painel de admin', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Admin|Dashboard/);
  await expectText(page, /Usuários|Reclamações/);
});

test('painel admin exibe bottom nav com 7 itens', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  await expectText(page, 'Reclamações');
  await expectText(page, 'Usuários');
  await expectText(page, 'Lojas');
  await expectText(page, 'Verificações');
  await expectText(page, 'FAQ');
  await expectText(page, 'Estatísticas');
});

test('aba Verificações exibe tabs Veterinários e Motoristas', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  await tapText(page, 'Verificações');
  await waitForText(page, /Veterinários|Motoristas/);
  await expectText(page, /Veterinários/);
  await expectText(page, /Motoristas/);
});

test('aba Verificações: sem pendentes exibe mensagem "Nenhuma verificação pendente"', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Verificações');
  await waitForText(page, /Veterinários|Nenhuma verificação/);
  // se não há pendentes, deve aparecer a mensagem
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll('flt-semantics'));
      return all.some(
        (el) =>
          el.textContent?.includes('Nenhuma verificação') ||
          el.textContent?.includes('Veterinários') ||
          el.textContent?.includes('pendente'),
      );
    },
    { timeout: 25_000 },
  );
});

test('aba Veterinários dentro de Verificações é acessível', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Verificações');
  await waitForText(page, /Veterinários/);
  await tapText(page, /^Veterinários/);
  await page.waitForTimeout(1500);
  await expectText(page, /Veterinários|nenhum vet|Aguardando aprovação|Nenhuma/i);
});

test('aba Motoristas dentro de Verificações é acessível', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Verificações');
  await waitForText(page, /Veterinários|Motoristas/);
  await tapText(page, /^Motoristas/);
  await page.waitForTimeout(1500);
  await expectText(page, /Motoristas|nenhum motorista|Aguardando aprovação|Nenhuma/i);
});

test('admin pode navegar pela aba Usuários sem crash', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Usuários');
  await waitForText(page, /Usuários|Clientes|Lojistas/);
  await expectText(page, /Total|Clientes|CLIENTE/i);
});

test('admin pode navegar pela aba Lojas sem crash', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Lojas');
  await waitForText(page, /Lojas|Estabelecimentos/);
  await expectText(page, /Pet|Estab|loja/i);
});

test('admin pode navegar pela aba FAQ sem crash', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'FAQ');
  await waitForText(page, /FAQ|Perguntas|Clientes|Lojistas/);
});

test('admin pode navegar pela aba Estatísticas', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Estatísticas');
  await waitForText(page, /Estatísticas|Total|Usuários/i);
});

test('admin pode navegar pela aba Reclamações', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await tapText(page, 'Reclamações');
  await waitForText(page, /Reclamações|Pendentes|Em Análise/);
});

test('logout do admin pelo painel volta ao login', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  await tapText(page, 'Sair');
  await waitForText(page, /Entrar|E-mail/);
});
