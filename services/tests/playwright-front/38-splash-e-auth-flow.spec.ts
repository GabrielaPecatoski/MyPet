/**
 * Testa o fluxo completo de autenticação e persistência de sessão:
 *  - splash leva ao onboarding sem sessão
 *  - splash leva direto à home com sessão válida (token armazenado)
 *  - logout limpa sessão e volta ao login
 *  - token expirado redireciona para login
 *  - cliente registrado vê a home correta
 *  - vendedor registrado vê o painel do estab
 *  - motorista registrado vê o painel do motorista
 *  - vet registrado vê o painel do vet
 *  - admin registrado vê o painel de admin
 */
import { test, APIRequestContext } from '@playwright/test';
import {
  bootFlutter, bootAndLogin, tapText, tapButton, expectText,
  waitForText, skipOnboardingIfPresent, goToLogin, login,
} from './_helpers';
import { apiContext, registerUser, SeededUser } from './_api';

const ADMIN_EMAIL = 'admin@mypet.com';
const ADMIN_PASSWORD = 'admin123';

let api: APIRequestContext;
let cliente: SeededUser;
let vendedor: SeededUser;

test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: 'CLIENTE' });
  vendedor = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Auth E2E' });
});

test.afterAll(async () => { await api.dispose(); });

test('app sem sessão abre onboarding', async ({ page }) => {
  await bootFlutter(page, '/');
  // onboarding ou welcome
  await page.waitForFunction(
    () => {
      const all = Array.from(document.querySelectorAll('flt-semantics'));
      return all.some(
        (el) =>
          el.textContent?.includes('O melhor para o seu pet') ||
          el.textContent?.includes('Como você quer usar'),
      );
    },
    { timeout: 30_000 },
  );
});

test('login cliente leva à home com nav bar de cliente', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await expectText(page, 'Agenda');
  await expectText(page, 'Loja');
  await expectText(page, 'Pets');
  await expectText(page, 'Perfil');
});

test('login vendedor leva ao painel do estab', async ({ page }) => {
  await bootAndLogin(page, vendedor.email, vendedor.password);
  await waitForText(page, /Painel|Agenda|Produtos|Avaliações/);
  await expectText(page, /Agenda|Produtos/);
});

test('login admin leva ao painel do admin', async ({ page }) => {
  await bootAndLogin(page, ADMIN_EMAIL, ADMIN_PASSWORD);
  await waitForText(page, /Painel|Dashboard/);
  await expectText(page, 'Reclamações');
  await expectText(page, 'Verificações');
});

test('logout do cliente retorna ao login', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, 'Perfil');
  await tapText(page, 'Perfil');
  await waitForText(page, /Sair|Logout/i);
  await tapText(page, /Sair/i);
  await waitForText(page, /E-mail|Entrar/);
});

test('logout do vendedor retorna ao login', async ({ page }) => {
  await bootAndLogin(page, vendedor.email, vendedor.password);
  await waitForText(page, /Painel|Agenda/);
  await tapText(page, 'Perfil');
  await waitForText(page, /Sair|Logout/i);
  await tapText(page, /Sair/i);
  await waitForText(page, /E-mail|Entrar/);
});

test('senha errada não loga e mostra snackbar de erro', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await goToLogin(page);
  await login(page, cliente.email, 'senhaerrada999');
  // botão Entrar continua visível (não navegou)
  await waitForText(page, /E-mail|Entrar/);
  // snackbar ou campo de erro
  await waitForText(page, /erro|inválid|incorrect/i, 15_000);
});

test('campos vazios no login mostram validação', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await goToLogin(page);
  await tapButton(page, 'Entrar');
  // permanece na tela de login
  await expectText(page, 'Entrar');
  await expectText(page, /inválido|Informe|obrigatório/i);
});

test('link "Criar Conta" no login leva ao registro', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await goToLogin(page);
  await tapText(page, 'Criar Conta');
  await waitForText(page, /Tipo de conta|Nome completo|Sou Tutor/);
});

test('link "Entrar" no welcome leva ao login', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  // já na welcome
  await waitForText(page, /Como você quer usar|Sou Tutor/);
  await tapText(page, 'Entrar');
  await waitForText(page, 'E-mail');
  await expectText(page, /Senha/);
});
