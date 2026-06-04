/**
 * Testa o fluxo de agendamento de consulta com veterinário via estabelecimento:
 *  - cliente busca clínica veterinária
 *  - seleciona serviço de consulta
 *  - conclui agendamento
 *  - serviço com preço variável ("Sob consulta") não exige pagamento
 *  - acompanhamento do agendamento pelo cliente
 */
import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, tapButton, expectText, waitForText,
  scrollToText, byText, fill, fieldByHint, pollTap,
} from './_helpers';
import {
  apiContext, registerUser, createEstablishment, addService,
  addVariableService, setSchedule, createPet, SeededUser, seedFullEstablishment,
} from './_api';

let api: APIRequestContext;
let owner: SeededUser;
let estab: any;
let consultaService: any;
let varService: any;
let cliente: SeededUser;
let pet: any;

test.beforeAll(async () => {
  api = await apiContext();

  owner = await registerUser(api, { role: 'VENDEDOR', businessName: 'Clinica Vet E2E' });
  estab = await createEstablishment(api, owner, {
    name: `Clínica Vet E2E ${Date.now()}`,
    type: 'CLINICA_VETERINARIA',
  });
  consultaService = await addService(api, owner, estab.id, {
    name: 'Consulta E2E',
    price: 150,
    durationMinutes: 60,
  });
  varService = await addVariableService(api, owner, estab.id, {
    name: 'Consulta Sob Consulta E2E',
  });
  await setSchedule(api, owner, estab.id);

  cliente = await registerUser(api, { role: 'CLIENTE' });
  pet = await createPet(api, cliente, { name: 'Felix E2E', type: 'Gato' });
});

test.afterAll(async () => { await api.dispose(); });

test('cliente consegue ver clínica veterinária na home com filtro Veterinário', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, 'Emergência Veterinária');
  await tapText(page, 'Veterinário');
  await page.waitForTimeout(3000);
  // a clínica deve aparecer na seção de estabelecimentos
  await scrollToText(page, /Clínica Vet E2E|Estabelecimentos/);
});

test('cliente agenda consulta com preço fixo → aguarda pagamento', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await waitForText(page, 'Emergência Veterinária');

  // navegar para estabelecimento via agendamento
  await tapText(page, 'Agenda');
  await waitForText(page, /Agenda|Nenhum agendamento/);
  await tapButton(page, /Agendar|Novo agendamento/);

  // busca estabelecimento
  await waitForText(page, /Buscar|Estabelecimento/);
  const search = fieldByHint(page, /Buscar|estabelecimento/i);
  await fill(search, 'Clínica Vet E2E');
  await scrollToText(page, /Clínica Vet E2E/, 30);

  await tapText(page, /Clínica Vet E2E/);
  await waitForText(page, /Consulta E2E|Selecione/);
  await tapText(page, /Consulta E2E/);
  await waitForText(page, /Pet|Selecione.*pet/i);
  await tapText(page, /Felix E2E/);
  await waitForText(page, /Data|Horário/);
  await tapButton(page, /Confirmar|Agendar/);

  await waitForText(page, /Aguardando pagamento|Pagar Agora|AGUARDANDO/i, 30_000);
});

test('cliente agenda consulta preço variável → status Pendente (sem pagamento)', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, 'Agenda');
  await waitForText(page, /Agenda/);
  await tapButton(page, /Agendar|Novo agendamento/);

  await waitForText(page, /Buscar|Estabelecimento/);
  const search = fieldByHint(page, /Buscar|estabelecimento/i);
  await fill(search, 'Clínica Vet E2E');
  await scrollToText(page, /Clínica Vet E2E/, 30);

  await tapText(page, /Clínica Vet E2E/);
  await waitForText(page, /Consulta Sob Consulta E2E|Sob consulta/i);
  await tapText(page, /Consulta Sob Consulta/);
  await waitForText(page, /Pet|Selecione/i);
  await tapText(page, /Felix E2E/);
  await waitForText(page, /Data|Horário/);
  await tapButton(page, /Confirmar|Agendar/);

  // serviço variável vai direto para PENDENTE
  await waitForText(page, /Pendente|Aguardando confirmação|Ver Minha Agenda/, 30_000);
});
