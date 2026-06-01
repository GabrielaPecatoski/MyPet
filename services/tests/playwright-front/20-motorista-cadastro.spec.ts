import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, tapButton, expectText, waitForText, fill, textFields,
} from './_helpers';
import {
  apiContext, registerUser, createEstablishment, SeededUser,
  registerDriver, deactivateDriver,
} from './_api';

interface TestSeed {
  owner: SeededUser;
  estabId: string;
}

let api: APIRequestContext;

let seed1: TestSeed;
let seed2: TestSeed;
let seed3: TestSeed;

test.beforeAll(async () => {
  api = await apiContext();

  const [o1, o2, o3] = await Promise.all([
    registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Motor 1' }),
    registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Motor 2' }),
    registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Motor 3' }),
  ]);
  const [e1, e2, e3] = await Promise.all([
    createEstablishment(api, o1, { name: `Pet Shop Motor 1 ${Date.now()}` }),
    createEstablishment(api, o2, { name: `Pet Shop Motor 2 ${Date.now()}` }),
    createEstablishment(api, o3, { name: `Pet Shop Motor 3 ${Date.now()}` }),
  ]);
  seed1 = { owner: o1, estabId: e1.id };
  seed2 = { owner: o2, estabId: e2.id };
  seed3 = { owner: o3, estabId: e3.id };

  // seed2: 1 motorista ativo (para testar conflito)
  await registerDriver(api, seed2.owner, seed2.estabId);

  // seed3: 1 motorista ativo → desativado (para testar reativação)
  const d3 = await registerDriver(api, seed3.owner, seed3.estabId);
  await deactivateDriver(api, seed3.owner, d3.id);
});

test.afterAll(async () => { await api.dispose(); });

test('vendedor cadastra motorista pela UI e vê confirmação com nome e placa', async ({ page }) => {
  const ts = Date.now().toString().slice(-5);

  await bootAndLogin(page, seed1.owner.email, seed1.owner.password);
  await tapText(page, 'Perfil');
  await waitForText(page, 'Motoristas', 30_000);
  await tapText(page, 'Motoristas');
  await waitForText(page, 'Cadastro de Motorista');

  const campos = textFields(page);
  await fill(campos.nth(0), `Motorista E2E ${ts}`);
  await fill(campos.nth(1), '41988880000');
  await fill(campos.nth(2), String(Date.now()).slice(-11).padStart(11, '0'));
  await fill(campos.nth(3), `CNH${ts}`);
  // tipo de veículo: Carro é o padrão (primeiro selecionado)
  await fill(campos.nth(4), 'Fiat Uno');
  await fill(campos.nth(5), `E2E${ts.slice(-4)}`);

  await tapButton(page, 'Cadastrar Motorista');

  await waitForText(page, 'Motorista cadastrado!');
  await expectText(page, `Motorista E2E ${ts}`);
  await expectText(page, `E2E${ts.slice(-4)}`);

  await tapButton(page, 'Concluir');
});

test('tentativa de cadastrar segundo motorista é bloqueada — regra de negócio', async ({ page }) => {
  const ts = Date.now().toString().slice(-5);

  await bootAndLogin(page, seed2.owner.email, seed2.owner.password);
  await tapText(page, 'Perfil');
  await waitForText(page, 'Motoristas', 30_000);
  await tapText(page, 'Motoristas');
  await waitForText(page, 'Cadastro de Motorista');

  const campos = textFields(page);
  await fill(campos.nth(0), `Segundo E2E ${ts}`);
  await fill(campos.nth(1), '41977770000');
  await fill(campos.nth(2), String(Date.now() + 7).slice(-11).padStart(11, '0'));
  await fill(campos.nth(3), `CNH9${ts}`);
  await fill(campos.nth(4), 'Honda Biz');
  await fill(campos.nth(5), `E2E${ts.slice(-4)}X`);

  await tapButton(page, 'Cadastrar Motorista');

  await expectText(page, /já possui um motorista ativo/i);
});

test('desativar motorista atual libera cadastro de novo', async ({ page }) => {
  const ts = Date.now().toString().slice(-5);

  await bootAndLogin(page, seed3.owner.email, seed3.owner.password);
  await tapText(page, 'Perfil');
  await waitForText(page, 'Motoristas', 30_000);
  await tapText(page, 'Motoristas');
  await waitForText(page, 'Cadastro de Motorista');

  const campos = textFields(page);
  await fill(campos.nth(0), `Novo E2E ${ts}`);
  await fill(campos.nth(1), '41966660000');
  await fill(campos.nth(2), String(Date.now() + 13).slice(-11).padStart(11, '0'));
  await fill(campos.nth(3), `CNH0${ts}`);
  await fill(campos.nth(4), 'Toyota Corolla');
  await fill(campos.nth(5), `E2E${ts.slice(-4)}Y`);

  await tapButton(page, 'Cadastrar Motorista');

  await waitForText(page, 'Motorista cadastrado!');
  await expectText(page, `Novo E2E ${ts}`);
  await tapButton(page, 'Concluir');
});
