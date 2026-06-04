import { test, APIRequestContext } from '@playwright/test';
import {
  bootFlutter, tapText, tapButton, fillNth, expectText, waitForText,
  skipOnboardingIfPresent, textFields, fill,
} from './_helpers';
import { apiContext } from './_api';
let api: APIRequestContext;
test.beforeAll(async () => { api = await apiContext(); });
test.afterAll(async () => { await api.dispose(); });
test('cadastro de motorista pela UI cria perfil e abre painel do motorista', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await tapText(page, 'Sou Motorista');
  await tapButton(page, /Continuar como Motorista/);
  await waitForText(page, 'Nome completo');
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Motorista UI ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, '0'));
  await fill(campos.nth(2), '41977770001');
  await fill(campos.nth(3), `mot${ts}@mypet.com`);
  await fill(campos.nth(4), 'senha123');
  await fill(campos.nth(5), 'senha123');
  await fill(campos.nth(6), String(ts).slice(-9));
  await fill(campos.nth(7), 'Fiat Uno');
  await fill(campos.nth(8), `M${ts.toString().slice(-4)}`);
  await tapButton(page, 'Criar conta');
  await expectText(page, 'MY PET · MOTORISTA');
  await expectText(page, 'Início');
  await expectText(page, 'Ganhos');
  await expectText(page, 'Histórico');
  await expectText(page, 'Perfil');
});
test('cadastro de veterinário pela UI cria perfil e abre painel do vet', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await tapText(page, 'Sou Veterinário');
  await tapButton(page, /Continuar como Veteri/);
  await waitForText(page, 'Nome completo');
  const ts = Date.now();
  const campos = textFields(page);
  await fill(campos.nth(0), `Vet UI ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), String(ts).slice(-11).padStart(11, '0'));
  await fill(campos.nth(2), '41966660002');
  await fill(campos.nth(3), `vet${ts}@mypet.com`);
  await fill(campos.nth(4), 'senha123');
  await fill(campos.nth(5), 'senha123');
  await fill(campos.nth(6), `SP${ts.toString().slice(-5)}`);
  await tapButton(page, 'Criar conta');
  await expectText(page, 'MY PET · VETERINÁRIO');
  await expectText(page, 'Agenda');
  await expectText(page, 'Chamados');
  await expectText(page, 'Pacientes');
  await expectText(page, 'Perfil');
});
test('cadastro com campo vazio exibe validação e não avança', async ({ page }) => {
  await bootFlutter(page, '/');
  await skipOnboardingIfPresent(page);
  await tapText(page, 'Sou Tutor');
  await tapButton(page, /Continuar como Tutor/);
  await waitForText(page, 'Nome completo');
  await tapButton(page, 'Criar conta');
  await expectText(page, 'Criar conta');
});
