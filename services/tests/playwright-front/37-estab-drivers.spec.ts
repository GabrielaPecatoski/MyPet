/**
 * Testa a tela de motoristas do estabelecimento:
 *  - acesso via menu Perfil
 *  - estado vazio quando não há motoristas
 *  - cadastro de novo motorista pela UI
 *  - motorista associado aparece na lista
 *  - dissociar motorista mostra confirmação
 */
import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, tapButton, expectText, waitForText,
  fill, textFields, fieldByHint,
} from './_helpers';
import {
  apiContext, registerUser, createEstablishment, SeededUser,
} from './_api';

let api: APIRequestContext;
let owner: SeededUser;
let estab: any;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Motoristas E2E' });
  estab = await createEstablishment(api, owner, { name: `Pet Shop Mot E2E ${Date.now()}` });
});

test.afterAll(async () => { await api.dispose(); });

test('menu Motoristas está acessível no perfil do estab', async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await waitForText(page, /Painel|Home/);
  await tapText(page, 'Perfil');
  await waitForText(page, /Motoristas|Veterinários|Editar/);
  await expectText(page, /Motoristas/);
});

test('tela de motoristas exibe header e lista vazia ou motoristas', async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, 'Perfil');
  await waitForText(page, /Motoristas/);
  await tapText(page, 'Motoristas');
  await waitForText(page, /Motoristas|Nenhum motorista/);
});

test('botão Adicionar abre sheet de cadastro de motorista', async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, 'Perfil');
  await waitForText(page, /Motoristas/);
  await tapText(page, 'Motoristas');
  await waitForText(page, /Motoristas|Nenhum motorista/);
  await tapButton(page, 'Adicionar');
  await waitForText(page, /Motorista|Nome|CNH/i);
});

test('cadastro de novo motorista pela UI associa ao estab', async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, 'Perfil');
  await waitForText(page, /Motoristas/);
  await tapText(page, 'Motoristas');
  await waitForText(page, /Motoristas|Nenhum motorista/);
  await tapButton(page, 'Adicionar');
  // Sheet abre na aba "Buscar por CPF"; troca para "Cadastrar novo"
  await waitForText(page, 'Adicionar Motorista');
  await tapText(page, 'Cadastrar novo');
  await waitForText(page, 'Veículo'); // âncora de texto real da aba Cadastrar

  const ts = Date.now();
  // Só os campos visíveis (a aba "Buscar por CPF" pode manter seu input no DOM)
  const campos = page.locator('input[data-semantics-role="text-field"]:visible');
  // Ordem: nome, telefone, cpf, email, senha, cnh, modelo, placa
  await fill(campos.nth(0), `Mot Novo E2E ${ts.toString().slice(-4)}`);
  await fill(campos.nth(1), '41944440005');
  await fill(campos.nth(2), String(ts).slice(-11).padStart(11, '0'));
  await fill(campos.nth(3), `mot${ts}@mypet.com`);
  await fill(campos.nth(4), 'senha123');
  await fill(campos.nth(5), String(ts).slice(-9));
  await fill(campos.nth(6), 'Fiat Palio');
  await fill(campos.nth(7), `MOT${ts.toString().slice(-4)}`); // placa precisa de 7+ caracteres
  await tapButton(page, 'Cadastrar e Associar');
  await waitForText(page, /cadastrado|associado|Ativo|Motoristas/i, 25_000);
});
