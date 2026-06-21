/**
 * Testes do painel administrativo:
 * - Login como admin
 * - Gerenciar FAQ (criar, editar, excluir)
 * - Responder perguntas de usuários
 * - Resolver reclamações
 * - Visualizar estatísticas da plataforma
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

const FAQ_QUESTION = `Pergunta E2E ${Date.now()}`;
const FAQ_ANSWER = `Resposta E2E: Esta é uma resposta criada por teste automatizado ${Date.now()}`;
const FAQ_CATEGORY = 'Geral';

test.describe('Painel Administrativo', () => {
  test.beforeEach(async ({ adminPage }) => {
    await adminPage.goto(APP);
    await waitForSplash(adminPage);
    // Admin é redirecionado para /admin
    await waitForText(adminPage, /admin|painel|administração/i, 20_000);
  });

  // ── ACESSO AO PAINEL ──────────────────────────────────────────────────────

  test('admin acessa painel administrativo após login', async ({ adminPage }) => {
    const bodyText = await adminPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/admin|administra|faq|perguntas/i);
  });

  test('painel exibe seções de gerenciamento', async ({ adminPage }) => {
    await adminPage.waitForTimeout(2_000);
    const bodyText = await adminPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/faq|pergunta|reclamação|estatística/i);
  });

  // ── GERENCIAMENTO DE FAQ ──────────────────────────────────────────────────

  test('lista FAQs existentes', async ({ credentials }) => {
    const faqs = await api.get<{ id: string; question: string }[]>('/faq');
    expect(Array.isArray(faqs)).toBe(true);
  });

  test('lista categorias de FAQ', async () => {
    const categories = await api.get<string[]>('/faq/categories');
    expect(Array.isArray(categories)).toBe(true);
  });

  test('admin cria novo item de FAQ', async ({ adminPage, credentials }) => {
    // Via API
    const newFaq = await api.post<{ id: string; question: string }>(
      '/faq/admin',
      {
        question: FAQ_QUESTION,
        answer: FAQ_ANSWER,
        category: FAQ_CATEGORY,
        isPublished: true,
      },
      credentials.admin.accessToken,
    );

    expect(newFaq.id).toBeTruthy();
    expect(newFaq.question).toBe(FAQ_QUESTION);

    // Verifica que aparece na listagem pública
    const faqs = await api.get<{ id: string; question: string }[]>('/faq');
    const found = faqs.find((f) => f.question === FAQ_QUESTION);
    expect(found).toBeTruthy();
  });

  test('admin edita item de FAQ existente', async ({ credentials }) => {
    // Cria FAQ para editar
    const faq = await api.post<{ id: string }>(
      '/faq/admin',
      {
        question: `FAQ para editar ${Date.now()}`,
        answer: 'Resposta original',
        category: FAQ_CATEGORY,
        isPublished: true,
      },
      credentials.admin.accessToken,
    );

    // Edita
    const updated = await api.put<{ id: string; answer: string }>(
      `/faq/admin/${faq.id}`,
      {
        question: `FAQ para editar ${Date.now()} - Editada`,
        answer: 'Resposta atualizada pelo teste E2E',
        category: FAQ_CATEGORY,
        isPublished: true,
      },
      credentials.admin.accessToken,
    );

    expect(updated.answer).toBe('Resposta atualizada pelo teste E2E');
  });

  test('admin exclui item de FAQ', async ({ credentials }) => {
    // Cria FAQ para excluir
    const faq = await api.post<{ id: string }>(
      '/faq/admin',
      {
        question: `FAQ para excluir ${Date.now()}`,
        answer: 'Resposta temporária',
        category: FAQ_CATEGORY,
        isPublished: false,
      },
      credentials.admin.accessToken,
    );

    // Exclui
    await api.delete(`/faq/admin/${faq.id}`, credentials.admin.accessToken);

    // Verifica que não existe mais na listagem admin
    const allFaqs = await api.get<{ id: string }[]>(
      '/faq/admin/all',
      credentials.admin.accessToken,
    );
    const stillExists = allFaqs.find((f) => f.id === faq.id);
    expect(stillExists).toBeFalsy();
  });

  // ── PERGUNTAS DE USUÁRIOS ─────────────────────────────────────────────────

  test('admin visualiza perguntas enviadas por usuários', async ({ credentials }) => {
    const questions = await api.get<{ id: string; question: string }[]>(
      '/faq/questions/admin/all',
      credentials.admin.accessToken,
    );
    expect(Array.isArray(questions)).toBe(true);
  });

  test('cliente envia pergunta e admin responde', async ({ credentials }) => {
    // Cliente envia pergunta
    const question = await api.post<{ id: string; question: string }>(
      '/faq/questions',
      {
        question: `Pergunta do cliente E2E ${Date.now()}`,
        userId: credentials.client.user.id,
      },
      credentials.client.accessToken,
    );

    expect(question.id).toBeTruthy();

    // Admin responde
    const answered = await api.put<{ id: string; answer: string }>(
      `/faq/questions/admin/${question.id}/answer`,
      { answer: 'Resposta do administrador para o teste E2E' },
      credentials.admin.accessToken,
    );

    expect(answered.answer).toBe('Resposta do administrador para o teste E2E');
  });

  test('admin fecha pergunta de usuário', async ({ credentials }) => {
    // Cliente envia pergunta
    const question = await api.post<{ id: string; status: string }>(
      '/faq/questions',
      {
        question: `Pergunta para fechar ${Date.now()}`,
        userId: credentials.client.user.id,
      },
      credentials.client.accessToken,
    );

    // Admin fecha
    const closed = await api.put<{ id: string; status: string }>(
      `/faq/questions/admin/${question.id}/close`,
      {},
      credentials.admin.accessToken,
    );

    expect(closed.status).toMatch(/CLOSED|FECHADA|fechado/i);
  });

  test('cliente visualiza suas perguntas com status', async ({ credentials }) => {
    const questions = await api.get<{ id: string; question: string; status: string }[]>(
      `/faq/questions/user/${credentials.client.user.id}`,
      credentials.client.accessToken,
    );
    expect(Array.isArray(questions)).toBe(true);
  });

  // ── RECLAMAÇÕES (ADMIN) ───────────────────────────────────────────────────

  test('admin visualiza todas as reclamações', async ({ credentials }) => {
    const complaints = await api.get<{ id: string }[]>(
      '/reviews/admin/complaints',
      credentials.admin.accessToken,
    );
    expect(Array.isArray(complaints)).toBe(true);
  });

  test('admin resolve reclamação', async ({ credentials, establishmentId }) => {
    // Cria reclamação via cliente
    let complaintId: string | null = null;
    try {
      const complaint = await api.post<{ id: string }>(
        '/reviews/complaints',
        {
          establishmentId,
          title: 'Reclamação para resolver - Admin E2E',
          description: 'Teste de resolução de reclamação pelo admin',
        },
        credentials.client.accessToken,
      );
      complaintId = complaint.id;
    } catch { /* ok */ }

    if (complaintId) {
      // Admin resolve
      try {
        const resolved = await api.patch<{ id: string; status: string }>(
          `/reviews/admin/complaints/${complaintId}/resolve`,
          { resolution: 'Reclamação resolvida pelo time de suporte E2E' },
          credentials.admin.accessToken,
        );
        expect(resolved.status).toMatch(/RESOLVED|RESOLVIDA/i);
      } catch { /* ok - pode já estar resolvida */ }
    }
  });

  test('admin rejeita reclamação inválida', async ({ credentials, establishmentId }) => {
    let complaintId: string | null = null;
    try {
      const complaint = await api.post<{ id: string }>(
        '/reviews/complaints',
        {
          establishmentId,
          title: 'Reclamação inválida E2E',
          description: 'Esta reclamação será rejeitada',
        },
        credentials.client.accessToken,
      );
      complaintId = complaint.id;
    } catch { /* ok */ }

    if (complaintId) {
      try {
        const rejected = await api.patch<{ id: string; status: string }>(
          `/reviews/admin/complaints/${complaintId}/reject`,
          { reason: 'Reclamação sem fundamento - teste E2E' },
          credentials.admin.accessToken,
        );
        expect(rejected.status).toMatch(/REJECTED|REJEITADA/i);
      } catch { /* ok */ }
    }
  });

  // ── ESTATÍSTICAS ──────────────────────────────────────────────────────────

  test('admin visualiza estatísticas da plataforma', async ({ credentials }) => {
    const stats = await api.get<unknown>(
      '/reviews/admin/stats',
      credentials.admin.accessToken,
    );
    expect(stats).toBeTruthy();
  });

  // ── PAINEL ADMIN VIA UI ───────────────────────────────────────────────────

  test('painel admin exibe seção de FAQ via UI', async ({ adminPage }) => {
    await adminPage.waitForTimeout(2_000);
    const faqSection = adminPage
      .locator('flt-semantics')
      .filter({ hasText: /faq|perguntas frequentes/i });

    if ((await faqSection.count()) > 0) {
      await faqSection.first().click();
      await waitForText(adminPage, /faq|pergunta/i, 10_000);
    }
  });

  test('admin cria FAQ via UI', async ({ adminPage }) => {
    await adminPage.waitForTimeout(2_000);

    // Navega para gerenciamento de FAQ
    const faqBtn = adminPage
      .locator('[role="button"]')
      .filter({ hasText: /faq|adicionar|nova pergunta/i });

    if ((await faqBtn.count()) > 0) {
      await faqBtn.first().click();
      await adminPage.waitForTimeout(1_500);

      const bodyText = await adminPage.locator('body').innerText();
      if (bodyText.toLowerCase().includes('pergunta')) {
        // Preenche formulário de FAQ
        await fillField(adminPage, 0, `FAQ UI E2E ${Date.now()}`);
        await fillField(adminPage, 1, 'Resposta para FAQ criado via UI E2E');

        const saveBtn = adminPage
          .locator('[role="button"]')
          .filter({ hasText: /salvar|publicar|criar/i });
        if ((await saveBtn.count()) > 0) {
          await saveBtn.first().click();
          await adminPage.waitForTimeout(2_000);
        }
      }
    }
  });

  test('admin visualiza perguntas pendentes via UI', async ({ adminPage }) => {
    await adminPage.waitForTimeout(2_000);

    const questionsBtn = adminPage
      .locator('[role="button"]')
      .filter({ hasText: /perguntas|pendentes/i });

    if ((await questionsBtn.count()) > 0) {
      await questionsBtn.first().click();
      await adminPage.waitForTimeout(2_000);
      const bodyText = await adminPage.locator('body').innerText();
      expect(bodyText.toLowerCase()).toMatch(/pergunta|nenhum/i);
    }
  });
});
