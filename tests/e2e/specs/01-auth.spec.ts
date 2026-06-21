/**
 * Testes de autenticação: login, registro, logout e validações de formulário.
 * Estes testes passam pela UI completa (sem injeção de token).
 */

import { test, expect } from '@playwright/test';
import { waitForSplash, fillField, clickButton, waitForText, waitForSnackbar } from '../utils/flutter';

const APP = process.env.APP_URL ?? 'http://localhost:8080';

// Credenciais de usuários já existentes no seed
const SEED_CLIENT = { email: 'cliente@test.com', password: 'senha123' };
const SEED_VENDOR = { email: 'carlos@petshop.com', password: 'senha123' };
const SEED_ADMIN = { email: 'admin@mypet.com', password: 'admin123' };

// Credenciais únicas para o teste de registro
const timestamp = Date.now();
const NEW_CLIENT = {
  name: `Teste E2E ${timestamp}`,
  email: `e2e.new.${timestamp}@test.com`,
  cpf: '123.456.789-00',
  phone: '(11) 91234-5678',
  password: 'Teste@123',
};
const NEW_VENDOR = {
  name: `Vendedor E2E ${timestamp}`,
  email: `e2e.vendor.${timestamp}@test.com`,
  cpf: '987.654.321-00',
  phone: '(11) 98765-4321',
  password: 'Teste@123',
  businessName: `Pet Shop E2E ${timestamp}`,
};

test.describe('Autenticação', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(APP);
    await waitForSplash(page);
  });

  // ── TELA DE LOGIN ─────────────────────────────────────────────────────────

  test('exibe tela de login com logo e campos', async ({ page }) => {
    // A splash deve redirecionar para /login quando sem token
    await waitForText(page, 'E-mail');
    await waitForText(page, 'Senha');
    await waitForText(page, 'Entrar');
    await waitForText(page, 'Criar Conta');
    await waitForText(page, 'Sou um estabelecimento');
  });

  test('login com credenciais inválidas exibe erro', async ({ page }) => {
    await waitForText(page, 'E-mail');

    await fillField(page, 0, 'invalido@email.com');
    await fillField(page, 1, 'senhaerrada');
    await clickButton(page, 'Entrar');

    await waitForSnackbar(page, 'login', 10_000);
  });

  test('validação: email inválido mostra mensagem', async ({ page }) => {
    await waitForText(page, 'Entrar');

    await fillField(page, 0, 'email-sem-arroba');
    await fillField(page, 1, 'minhasenha');
    await clickButton(page, 'Entrar');

    await waitForText(page, 'inválido');
  });

  test('validação: senha curta mostra mensagem', async ({ page }) => {
    await waitForText(page, 'Entrar');

    await fillField(page, 0, 'teste@email.com');
    await fillField(page, 1, '123');
    await clickButton(page, 'Entrar');

    await waitForText(page, '6 caracteres');
  });

  test('login como CLIENTE redireciona para home', async ({ page }) => {
    await waitForText(page, 'Entrar');

    await fillField(page, 0, 'e2e.client@mypet.test');
    await fillField(page, 1, 'Senha@123');
    await clickButton(page, 'Entrar');

    // Aguarda navegação para home do cliente
    await waitForText(page, 'Estabelecimentos', 20_000);
  });

  test('login como VENDEDOR redireciona para painel do estabelecimento', async ({ page }) => {
    await waitForText(page, 'Entrar');

    await fillField(page, 0, 'e2e.vendor@mypet.test');
    await fillField(page, 1, 'Senha@123');
    await clickButton(page, 'Entrar');

    // Vendedor vai para /estab-home
    await waitForText(page, 'Agenda', 20_000);
  });

  test('login como ADMIN redireciona para painel admin', async ({ page }) => {
    await waitForText(page, 'Entrar');

    await fillField(page, 0, SEED_ADMIN.email);
    await fillField(page, 1, SEED_ADMIN.password);
    await clickButton(page, 'Entrar');

    await waitForText(page, 'Admin', 20_000);
  });

  // ── NAVEGAÇÃO PARA REGISTRO ───────────────────────────────────────────────

  test('botão "Criar Conta" abre tela de registro', async ({ page }) => {
    await waitForText(page, 'Criar Conta');
    await clickButton(page, 'Criar Conta');

    await waitForText(page, 'Nome Completo', 15_000);
    await waitForText(page, 'CPF');
    await waitForText(page, 'Telefone');
  });

  test('toggle "Sou um estabelecimento" muda campos do formulário de registro', async ({ page }) => {
    await waitForText(page, 'Criar Conta');
    await clickButton(page, 'Criar Conta');

    // Verifica campos de cliente
    await waitForText(page, 'Nome Completo');

    // Clica no toggle de estabelecimento
    await clickButton(page, 'Sou um estabelecimento');

    // Campos de vendedor devem aparecer
    await waitForText(page, 'Nome do Estabelecimento', 10_000);
    await waitForText(page, 'Nome completo do responsável');
  });

  // ── REGISTRO DE NOVO CLIENTE ──────────────────────────────────────────────

  test('registra novo cliente com sucesso', async ({ page }) => {
    await waitForText(page, 'Criar Conta');
    await clickButton(page, 'Criar Conta');

    await waitForText(page, 'Nome Completo');

    // Preenche todos os campos
    await fillField(page, 0, NEW_CLIENT.name);
    await fillField(page, 1, NEW_CLIENT.cpf);
    await fillField(page, 2, NEW_CLIENT.phone);
    await fillField(page, 3, NEW_CLIENT.email);
    await fillField(page, 4, NEW_CLIENT.password);
    await fillField(page, 5, NEW_CLIENT.password);

    await clickButton(page, 'Criar Conta');

    // Após registro, redireciona para home do cliente
    await waitForText(page, 'Estabelecimentos', 20_000);
  });

  test('registra novo vendedor com sucesso', async ({ page }) => {
    await waitForText(page, 'Criar Conta');
    await clickButton(page, 'Criar Conta');

    await waitForText(page, 'Nome Completo');

    // Muda para modo estabelecimento
    await clickButton(page, 'Sou um estabelecimento');
    await waitForText(page, 'Nome do Estabelecimento');

    // Preenche: responsável, CPF, nome estab, telefone, email, senha, confirma
    await fillField(page, 0, NEW_VENDOR.name);
    await fillField(page, 1, NEW_VENDOR.cpf);
    await fillField(page, 2, NEW_VENDOR.businessName);
    await fillField(page, 3, NEW_VENDOR.phone);
    await fillField(page, 4, NEW_VENDOR.email);
    await fillField(page, 5, NEW_VENDOR.password);
    await fillField(page, 6, NEW_VENDOR.password);

    await clickButton(page, 'Criar Conta');

    // Vendedor vai para /estab-home
    await waitForText(page, 'Agenda', 20_000);
  });

  test('validação de registro: senhas não coincidem', async ({ page }) => {
    await waitForText(page, 'Criar Conta');
    await clickButton(page, 'Criar Conta');

    await waitForText(page, 'Nome Completo');

    await fillField(page, 0, 'Nome Teste');
    await fillField(page, 1, '000.000.000-99');
    await fillField(page, 2, '(11) 90000-0000');
    await fillField(page, 3, 'teste@email.com');
    await fillField(page, 4, 'senha123');
    await fillField(page, 5, 'senhadiferente');

    await clickButton(page, 'Criar Conta');

    await waitForText(page, 'não coincidem');
  });

  // ── LOGOUT ────────────────────────────────────────────────────────────────

  test('logout retorna para tela de login', async ({ page }) => {
    // Faz login
    await waitForText(page, 'Entrar');
    await fillField(page, 0, 'e2e.client@mypet.test');
    await fillField(page, 1, 'Senha@123');
    await clickButton(page, 'Entrar');

    await waitForText(page, 'Estabelecimentos', 20_000);

    // Navega para perfil (última aba do bottom nav)
    const profileTabs = page.locator('[role="tab"]');
    const tabCount = await profileTabs.count();
    if (tabCount > 0) {
      await profileTabs.last().click();
    } else {
      // Fallback via texto
      await clickButton(page, 'Perfil');
    }

    await waitForText(page, 'Sair', 10_000);
    await clickButton(page, 'Sair');

    // Deve voltar para login
    await waitForText(page, 'Entrar', 15_000);
  });
});
