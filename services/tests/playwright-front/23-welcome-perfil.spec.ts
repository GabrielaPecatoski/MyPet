import { test } from '@playwright/test';
import {
  bootFlutter, tapText, tapButton, expectText, waitForText,
  skipOnboardingIfPresent,
} from './_helpers';
async function chegaNaWelcome(page: import('@playwright/test').Page) {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await waitForText(page, 'Como você quer usar o app?');
}
test('exibe os 4 perfis disponíveis', async ({ page }) => {
  await chegaNaWelcome(page);
  await expectText(page, 'Sou Tutor');
  await expectText(page, 'Sou Veterinário');
  await expectText(page, 'Sou Motorista');
  await expectText(page, 'Estabelecimento');
});
test('selecionar Tutor ativa "Continuar como Tutor"', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Sou Tutor');
  await expectText(page, /Continuar como Tutor/);
});
test('selecionar Veterinário ativa "Continuar como Veterinário"', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Sou Veterinário');
  await expectText(page, /Continuar como Veteri/);
});
test('selecionar Motorista ativa "Continuar como Motorista"', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Sou Motorista');
  await expectText(page, /Continuar como Motorista/);
});
test('link "Entrar" leva ao formulário de login', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Entrar');
  await waitForText(page, 'E-mail');
  await expectText(page, 'Criar Conta');
});
test('Continuar como Tutor abre o cadastro com tipo Tutor pré-selecionado', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Sou Tutor');
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, 'Nome completo');
  await expectText(page, 'Tutor');
  await expectText(page, 'Criar conta');
});
test('Continuar como Veterinário abre o cadastro com seção CRMV', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Sou Veterinário');
  await tapButton(page, /Continuar como Veteri/);
  await waitForText(page, 'Nome completo');
  await expectText(page, /Cadastro.*Veteri/i);
});
test('Continuar como Motorista abre o cadastro com seção de veículo', async ({ page }) => {
  await chegaNaWelcome(page);
  await tapText(page, 'Sou Motorista');
  await tapButton(page, /Continuar como Motorista/);
  await waitForText(page, 'Nome completo');
  await expectText(page, /Cadastro.*Motorista/i);
});
