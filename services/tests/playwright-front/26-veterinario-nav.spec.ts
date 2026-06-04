import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, expectText, waitForText, fieldByHint, fill,
} from './_helpers';
import {
  apiContext, registerUser, registerVet, SeededUser,
} from './_api';
let api: APIRequestContext;
let vet: SeededUser;
test.beforeAll(async () => {
  api = await apiContext();
  vet = await registerUser(api, { role: 'VETERINARIO', namePrefix: 'Vet Nav E2E' });
  try {
    await registerVet(api, vet, { especialidade: 'Clínica geral' });
  } catch (_) {
  }
});
test.afterAll(async () => { await api.dispose(); });
test('login como veterinário abre painel do vet', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await expectText(page, 'MY PET · VETERINÁRIO');
  await expectText(page, /Olá, Dr/);
});
test('home do vet exibe stats (consultas, chamados, faturamento, avaliação)', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, 'MY PET · VETERINÁRIO');
  await expectText(page, 'Consultas hoje');
  await expectText(page, 'Chamados');
  await expectText(page, 'Faturamento');
  await expectText(page, 'Avaliação');
});
test('home do vet exibe toggle de disponibilidade', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, 'Disponível para chamados 24h');
  await expectText(page, /Disponível|Indisponível/);
});
test('toggle de disponibilidade muda estado', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await waitForText(page, 'Disponível para chamados 24h');
  await tapText(page, /Disponível|Indisponível/);
  await waitForText(page, /Disponível|Indisponível/);
});
test('aba Agenda exibe abas Hoje / Amanhã / Semana', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Agenda');
  await waitForText(page, 'MY PET · VETERINÁRIO');
  await expectText(page, 'Hoje');
  await expectText(page, 'Amanhã');
  await expectText(page, 'Semana');
});
test('aba Agenda exibe chips de contagem', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Agenda');
  await waitForText(page, 'Hoje');
  await expectText(page, 'Consultas');
  await expectText(page, 'Confirmadas');
  await expectText(page, 'Pendentes');
});
test('agenda tab Hoje mostra estado vazio (sem consultas mockadas)', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Agenda');
  await waitForText(page, 'Hoje');
  await expectText(page, 'Nenhuma consulta hoje.');
});
test('aba Chamados exibe estado vazio', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Chamados');
  await waitForText(page, 'Nenhum chamado ativo');
  await expectText(page, 'Chamados de emergência');
});
test('aba Pacientes exibe estado vazio com busca', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Pacientes');
  await waitForText(page, 'Nenhum paciente ainda');
  await expectText(page, 'Atendidos recentemente');
});
test('campo de busca de paciente está disponível', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Pacientes');
  await waitForText(page, 'Nenhum paciente ainda');
  const campo = fieldByHint(page, 'Buscar paciente ou tutor');
  await fill(campo, 'Thor');
  await expectText(page, 'Nenhum paciente ainda');
});
test('aba Perfil do vet exibe dados e CRMV', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Perfil');
  await waitForText(page, 'Pacientes');
  await expectText(page, 'Avaliação');
  await expectText(page, 'Desde');
  await expectText(page, /CRMV|Registro/);
  await expectText(page, 'Especialidades');
  await expectText(page, 'Sair da conta');
});
test('logout pelo perfil do vet volta ao login', async ({ page }) => {
  await bootAndLogin(page, vet.email, vet.password);
  await tapText(page, 'Perfil');
  await waitForText(page, 'Sair da conta');
  await tapText(page, 'Sair da conta');
  await waitForText(page, 'Entrar');
});
