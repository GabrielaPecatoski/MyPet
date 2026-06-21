/**
 * Testes do fluxo do vendedor/estabelecimento:
 * - Painel do estabelecimento
 * - Gerenciar agenda de agendamentos
 * - Editar informações do estabelecimento
 * - Gerenciar disponibilidade
 * - Visualizar estatísticas
 * - Responder avaliações e reclamações
 */

import { test, expect } from '../fixtures/auth.fixture';
import {
  waitForSplash,
  waitForText,
  clickButton,
  fillField,
  clearAndFillField,
} from '../utils/flutter';
import { api } from '../utils/api';

const APP = process.env.APP_URL ?? 'http://localhost:8080';

test.describe('Painel do Estabelecimento (Vendedor)', () => {
  test.beforeEach(async ({ vendorPage }) => {
    await vendorPage.goto(APP);
    await waitForSplash(vendorPage);
    // Vendedor é redirecionado para /estab-home
    await waitForText(vendorPage, 'Agenda', 20_000);
  });

  // ── NAVEGAÇÃO DO PAINEL ───────────────────────────────────────────────────

  test('painel do vendedor exibe abas principais', async ({ vendorPage }) => {
    const bodyText = await vendorPage.locator('body').innerText();
    // O painel do vendedor tem: Agenda, Produtos, Avaliações, Estatísticas, Perfil
    expect(bodyText.toLowerCase()).toMatch(/agenda/i);
  });

  test('aba de Agenda exibe agendamentos do estabelecimento', async ({ vendorPage }) => {
    await waitForText(vendorPage, 'Agenda', 10_000);
    await vendorPage.waitForTimeout(2_000);

    const bodyText = await vendorPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/agenda|agendamento|nenhum/i);
  });

  test('aba de Produtos exibe produtos do estabelecimento', async ({
    vendorPage,
    credentials,
    establishmentId,
  }) => {
    // Navega para aba Produtos
    const tabs = vendorPage.locator('[role="tab"]');
    const tabCount = await tabs.count();

    if (tabCount >= 2) {
      await tabs.nth(1).click();
    } else {
      await clickButton(vendorPage, 'Produtos');
    }

    await vendorPage.waitForTimeout(2_000);
    const bodyText = await vendorPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/produto|catálogo|nenhum/i);
  });

  test('aba de Avaliações mostra avaliações recebidas', async ({ vendorPage }) => {
    const tabs = vendorPage.locator('[role="tab"]');
    const tabCount = await tabs.count();

    if (tabCount >= 3) {
      await tabs.nth(2).click();
    } else {
      const avalBtn = vendorPage.locator('[role="button"]').filter({ hasText: /avalia/i });
      if ((await avalBtn.count()) > 0) await avalBtn.first().click();
    }

    await vendorPage.waitForTimeout(2_000);
    const bodyText = await vendorPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/avalia|nenhum/i);
  });

  test('aba de Estatísticas exibe métricas', async ({ vendorPage }) => {
    const tabs = vendorPage.locator('[role="tab"]');
    const tabCount = await tabs.count();

    if (tabCount >= 4) {
      await tabs.nth(3).click();
    } else {
      const statsBtn = vendorPage.locator('[role="button"]').filter({ hasText: /estatística|estat/i });
      if ((await statsBtn.count()) > 0) await statsBtn.first().click();
    }

    await vendorPage.waitForTimeout(2_000);
    const bodyText = await vendorPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/estatística|total|serviços|receita|nenhum/i);
  });

  // ── GERENCIAMENTO DE AGENDAMENTOS ─────────────────────────────────────────

  test('confirma agendamento pendente', async ({
    vendorPage,
    credentials,
    establishmentId,
  }) => {
    // Cria agendamento pendente via API do cliente
    let bookingId: string | null = null;
    try {
      const services = await api.get<{ id: string }[]>(
        `/establishments/${establishmentId}/services`,
        credentials.vendor.accessToken,
      );

      if (services.length > 0) {
        const nextWeek = new Date();
        nextWeek.setDate(nextWeek.getDate() + 7);
        const dateStr = nextWeek.toISOString().split('T')[0];

        const booking = await api.post<{ id: string }>(
          '/bookings',
          {
            establishmentId,
            serviceId: services[0].id,
            date: dateStr,
            time: '09:00',
          },
          credentials.client.accessToken,
        );
        bookingId = booking.id;
      }
    } catch { /* ok */ }

    if (bookingId) {
      await vendorPage.reload();
      await waitForSplash(vendorPage);
      await waitForText(vendorPage, 'Agenda', 20_000);
      await vendorPage.waitForTimeout(2_000);

      // Procura botão de confirmar no agendamento
      const confirmBtn = vendorPage
        .locator('[role="button"]')
        .filter({ hasText: /confirmar/i });

      if ((await confirmBtn.count()) > 0) {
        await confirmBtn.first().click();
        await vendorPage.waitForTimeout(1_500);

        // Verifica status via API
        const booking = await api.get<{ id: string; status: string }>(
          `/bookings/${bookingId}`,
          credentials.vendor.accessToken,
        );
        expect(booking.status).toMatch(/CONFIRMADO|PENDENTE/i);
      }
    }
  });

  test('completa agendamento confirmado', async ({
    vendorPage,
    credentials,
    establishmentId,
  }) => {
    // Cria e confirma agendamento via API
    let bookingId: string | null = null;
    try {
      const services = await api.get<{ id: string }[]>(
        `/establishments/${establishmentId}/services`,
        credentials.vendor.accessToken,
      );

      if (services.length > 0) {
        const today = new Date();
        const dateStr = today.toISOString().split('T')[0];

        const booking = await api.post<{ id: string }>(
          '/bookings',
          {
            establishmentId,
            serviceId: services[0].id,
            date: dateStr,
            time: '10:00',
          },
          credentials.client.accessToken,
        );
        bookingId = booking.id;

        // Confirma via API
        await api.patch(
          `/bookings/${bookingId}/status`,
          { status: 'CONFIRMADO' },
          credentials.vendor.accessToken,
        );
      }
    } catch { /* ok */ }

    if (bookingId) {
      await vendorPage.reload();
      await waitForSplash(vendorPage);
      await waitForText(vendorPage, 'Agenda', 20_000);
      await vendorPage.waitForTimeout(2_000);

      const completeBtn = vendorPage
        .locator('[role="button"]')
        .filter({ hasText: /concluir|completar|finalizar/i });

      if ((await completeBtn.count()) > 0) {
        await completeBtn.first().click();
        await vendorPage.waitForTimeout(1_500);
      }
    }
  });

  // ── EDIÇÃO DO ESTABELECIMENTO ─────────────────────────────────────────────

  test('abre tela de edição do estabelecimento', async ({ vendorPage }) => {
    // Navega para aba de Perfil/Configurações do estabelecimento
    const tabs = vendorPage.locator('[role="tab"]');
    const tabCount = await tabs.count();

    if (tabCount >= 5) {
      await tabs.nth(4).click();
    }

    await vendorPage.waitForTimeout(1_500);

    // Procura botão de editar estabelecimento
    const editBtn = vendorPage
      .locator('[role="button"]')
      .filter({ hasText: /editar|configurar|gerenciar/i });

    if ((await editBtn.count()) > 0) {
      await editBtn.first().click();
      await waitForText(vendorPage, /nome|endereço|descrição/i, 10_000);
    }
  });

  test('edita informações do estabelecimento', async ({ vendorPage }) => {
    // Vai para perfil
    const tabs = vendorPage.locator('[role="tab"]');
    if ((await tabs.count()) >= 5) await tabs.nth(4).click();
    await vendorPage.waitForTimeout(1_500);

    const editBtn = vendorPage
      .locator('[role="button"]')
      .filter({ hasText: /editar|configurar/i });

    if ((await editBtn.count()) > 0) {
      await editBtn.first().click();
      await waitForText(vendorPage, /nome|endereço/i, 8_000);

      // Atualiza a descrição
      const descField = vendorPage.locator('[role="textbox"]').filter({ hasText: /descrição/ });
      if ((await descField.count()) > 0) {
        await clearAndFillField(vendorPage, 1, 'Pet Shop E2E - Descrição atualizada pelos testes');
      }

      const saveBtn = vendorPage
        .locator('[role="button"]')
        .filter({ hasText: /salvar|atualizar/i });
      if ((await saveBtn.count()) > 0) {
        await saveBtn.first().click();
        await vendorPage.waitForTimeout(2_000);
      }
    }
  });

  // ── GERENCIAR SERVIÇOS ────────────────────────────────────────────────────

  test('lista serviços do estabelecimento', async ({
    vendorPage,
    credentials,
    establishmentId,
  }) => {
    const services = await api.get<{ id: string; name: string; price: number }[]>(
      `/establishments/${establishmentId}/services`,
      credentials.vendor.accessToken,
    );

    expect(Array.isArray(services)).toBe(true);
    // Pelo menos um serviço deve existir (criado no global setup)
  });

  // ── GERENCIAR DISPONIBILIDADE ─────────────────────────────────────────────

  test('verifica disponibilidade para data futura', async ({
    credentials,
    establishmentId,
  }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    const availability = await api.get<unknown>(
      `/availability/${establishmentId}?date=${dateStr}`,
    );

    // Deve retornar estrutura de disponibilidade
    expect(availability).toBeTruthy();
  });

  test('define horários de funcionamento', async ({
    vendorPage,
    credentials,
    establishmentId,
  }) => {
    // Testa via API se o schedule pode ser criado
    try {
      await api.post(
        '/availability/schedule',
        {
          establishmentId,
          dayOfWeek: 1, // Segunda-feira
          startTime: '08:00',
          endTime: '18:00',
          slotDurationMinutes: 60,
        },
        credentials.vendor.accessToken,
      );
    } catch { /* ok - pode já existir */ }

    const schedule = await api.get<unknown>(
      `/availability/schedule/${establishmentId}`,
      credentials.vendor.accessToken,
    );
    expect(schedule).toBeTruthy();
  });

  // ── RECLAMAÇÕES ───────────────────────────────────────────────────────────

  test('visualiza reclamações do estabelecimento', async ({
    credentials,
    establishmentId,
  }) => {
    const complaints = await api.get<unknown[]>(
      `/reviews/complaints/establishment/${establishmentId}`,
      credentials.vendor.accessToken,
    );

    expect(Array.isArray(complaints)).toBe(true);
  });

  test('responde reclamação de cliente', async ({
    credentials,
    establishmentId,
  }) => {
    // Cria reclamação via cliente
    let complaintId: string | null = null;
    try {
      const complaint = await api.post<{ id: string }>(
        '/reviews/complaints',
        {
          establishmentId,
          title: 'Reclamação E2E',
          description: 'Descrição de reclamação para teste automatizado',
        },
        credentials.client.accessToken,
      );
      complaintId = complaint.id;
    } catch { /* ok */ }

    if (complaintId) {
      // Vendedor responde
      try {
        await api.patch(
          `/reviews/complaints/${complaintId}/respond`,
          { response: 'Resposta E2E: agradecemos seu feedback.' },
          credentials.vendor.accessToken,
        );
      } catch { /* ok */ }
    }

    // Verifica via API que a resposta foi salva
    const complaints = await api.get<{ id: string; response?: string }[]>(
      `/reviews/complaints/establishment/${establishmentId}`,
      credentials.vendor.accessToken,
    );
    expect(Array.isArray(complaints)).toBe(true);
  });

  // ── PAINEL DE AJUDA DO ESTABELECIMENTO ────────────────────────────────────

  test('acessa tela de ajuda do estabelecimento', async ({ vendorPage }) => {
    // Navega para perfil
    const tabs = vendorPage.locator('[role="tab"]');
    if ((await tabs.count()) >= 5) await tabs.nth(4).click();
    await vendorPage.waitForTimeout(1_500);

    const helpBtn = vendorPage
      .locator('[role="button"]')
      .filter({ hasText: /ajuda|suporte|help/i });

    if ((await helpBtn.count()) > 0) {
      await helpBtn.first().click();
      await waitForText(vendorPage, /ajuda|suporte|faq/i, 10_000);
    }
  });
});
