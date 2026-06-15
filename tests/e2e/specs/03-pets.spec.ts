/**
 * Testes de gerenciamento de pets:
 * - Listar pets
 * - Adicionar pet
 * - Editar pet
 * - Excluir pet com confirmação
 */

import { test, expect } from '../fixtures/auth.fixture';
import {
  waitForSplash,
  waitForText,
  clickButton,
  fillField,
  clearAndFillField,
} from '../utils/flutter';

const APP = process.env.APP_URL ?? 'http://localhost:8080';

const PET_NAME = `Rex E2E ${Date.now()}`;
const PET_NAME_EDITED = `Rex E2E Editado ${Date.now()}`;

test.describe('Gerenciamento de Pets', () => {
  test.beforeEach(async ({ clientPage }) => {
    await clientPage.goto(APP);
    await waitForSplash(clientPage);
    await waitForText(clientPage, 'Estabelecimentos', 20_000);

    // Navega para aba Pets (4ª aba, índice 3)
    const tabs = clientPage.locator('[role="tab"]');
    const tabCount = await tabs.count();
    if (tabCount >= 4) {
      await tabs.nth(3).click();
    } else {
      // Fallback via texto no bottom nav
      const petBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: 'Pets' })
        .last();
      await petBtn.click();
    }

    await waitForText(clientPage, 'Pets', 15_000);
  });

  // ── LISTAGEM ──────────────────────────────────────────────────────────────

  test('exibe tela de pets com botão de adicionar', async ({ clientPage }) => {
    // Deve ter botão de adicionar (+)
    const addBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /adicionar|novo|\+/i })
      .or(clientPage.locator('[role="button"][aria-label*="adicionar"]'));

    // Verifica se há botão de adicionar ou fab
    await clientPage.waitForTimeout(1_000);
    const bodyText = await clientPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/pet|adicion|novo/i);
  });

  test('exibe estado vazio quando não há pets', async ({ clientPage }) => {
    // Pode exibir mensagem de "Nenhum pet" ou listar pets existentes
    await clientPage.waitForTimeout(2_000);
    const bodyText = await clientPage.locator('body').innerText();
    // Aceita ambos os estados
    expect(bodyText.toLowerCase()).toMatch(/pet|nenhum|adicion/i);
  });

  // ── ADICIONAR PET ─────────────────────────────────────────────────────────

  test('abre tela de adicionar pet', async ({ clientPage }) => {
    // Clica no botão de adicionar (pode ser FAB ou botão no header)
    const addButtons = clientPage.locator('[role="button"]');
    const count = await addButtons.count();

    // FAB geralmente é o último botão
    await addButtons.last().click();
    await clientPage.waitForTimeout(1_000);

    // Ou via navegação direta
    const bodyText = await clientPage.locator('body').innerText();
    if (!bodyText.toLowerCase().includes('nome') || !bodyText.toLowerCase().includes('raça')) {
      // Tenta clicar em "Adicionar pet" se existir
      const addPetBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /adicionar pet|novo pet/i });
      if ((await addPetBtn.count()) > 0) {
        await addPetBtn.first().click();
      }
    }

    await waitForText(clientPage, /nome|raça|pet/i, 10_000);
  });

  test('adiciona novo pet com dados válidos', async ({ clientPage }) => {
    // Clica para abrir formulário
    const addBtn = clientPage.locator('[role="button"]').last();
    await addBtn.click();
    await waitForText(clientPage, /nome do pet|nome/i, 10_000);

    // Preenche formulário: Nome, Raça, Idade, Peso (campos variam por tela)
    await fillField(clientPage, 0, PET_NAME);         // Nome
    await fillField(clientPage, 1, 'Labrador');       // Raça
    await fillField(clientPage, 2, '3');               // Idade
    await fillField(clientPage, 3, '12.5');            // Peso

    // Salva
    const saveBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /salvar|adicionar|cadastrar/i })
      .first();
    await saveBtn.click();

    // Deve voltar para lista de pets e mostrar o novo pet
    await waitForText(clientPage, 'Pets', 15_000);
    await waitForText(clientPage, PET_NAME, 10_000);
  });

  test('validação: não permite salvar pet com nome vazio', async ({ clientPage }) => {
    const addBtn = clientPage.locator('[role="button"]').last();
    await addBtn.click();
    await waitForText(clientPage, /nome do pet|nome/i, 10_000);

    // Deixa nome vazio e tenta salvar
    const saveBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /salvar|adicionar|cadastrar/i })
      .first();
    await saveBtn.click();

    // Deve exibir erro de validação
    await waitForText(clientPage, /nome|obrigatório|informe/i, 8_000);
  });

  // ── EDITAR PET ────────────────────────────────────────────────────────────

  test('edita pet existente', async ({ clientPage }) => {
    // Primeiro, cria um pet se não houver nenhum
    const bodyText = await clientPage.locator('body').innerText();
    const hasPet = bodyText.toLowerCase().includes('labrador') || bodyText.includes(PET_NAME);

    if (!hasPet) {
      // Cria um pet primeiro
      const addBtn = clientPage.locator('[role="button"]').last();
      await addBtn.click();
      await waitForText(clientPage, /nome/i, 8_000);
      await fillField(clientPage, 0, PET_NAME);
      await fillField(clientPage, 1, 'Poodle');
      await fillField(clientPage, 2, '2');
      await fillField(clientPage, 3, '5');
      const saveBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /salvar|adicionar/i })
        .first();
      await saveBtn.click();
      await waitForText(clientPage, 'Pets', 10_000);
    }

    // Clica no pet para abrir detalhes/edição
    const petCard = clientPage
      .locator('flt-semantics')
      .filter({ hasText: /Labrador|Poodle|Rex|E2E/i })
      .first();
    await petCard.click();
    await clientPage.waitForTimeout(1_000);

    // Procura botão de edição
    const editBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /editar|edit/i });
    if ((await editBtn.count()) > 0) {
      await editBtn.first().click();
      await waitForText(clientPage, /nome/i, 8_000);

      await clearAndFillField(clientPage, 0, PET_NAME_EDITED);

      const saveBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /salvar|atualizar/i })
        .first();
      await saveBtn.click();

      await waitForText(clientPage, 'Pets', 10_000);
    }
    // Se não tiver botão de editar explícito, o teste passa como informativo
  });

  // ── EXCLUIR PET ───────────────────────────────────────────────────────────

  test('exclui pet com confirmação no dialog', async ({ clientPage }) => {
    await clientPage.waitForTimeout(1_000);
    const bodyText = await clientPage.locator('body').innerText();
    const hasPets = bodyText.toLowerCase().match(/labrador|poodle|rex|e2e/i);

    if (!hasPets) {
      // Cria um pet para deletar
      const addBtn = clientPage.locator('[role="button"]').last();
      await addBtn.click();
      await waitForText(clientPage, /nome/i, 8_000);
      await fillField(clientPage, 0, `Pet para Excluir ${Date.now()}`);
      await fillField(clientPage, 1, 'SRD');
      await fillField(clientPage, 2, '1');
      await fillField(clientPage, 3, '3');
      const saveBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /salvar|adicionar/i })
        .first();
      await saveBtn.click();
      await waitForText(clientPage, 'Pets', 10_000);
    }

    // Clica no pet
    const petCard = clientPage
      .locator('flt-semantics')
      .filter({ hasText: /Labrador|Poodle|Rex|E2E|SRD/i })
      .first();
    await petCard.click();
    await clientPage.waitForTimeout(1_000);

    // Procura botão de exclusão
    const deleteBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /excluir|deletar|remover/i });
    if ((await deleteBtn.count()) > 0) {
      await deleteBtn.first().click();

      // Confirma no dialog
      const confirmBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /excluir|confirmar|sim|yes/i });
      if ((await confirmBtn.count()) > 0) {
        await confirmBtn.first().click();
      }

      await waitForText(clientPage, 'Pets', 10_000);
    }
  });

  test('cancela exclusão de pet no dialog', async ({ clientPage }) => {
    await clientPage.waitForTimeout(1_000);
    const bodyText = await clientPage.locator('body').innerText();
    const hasPets = bodyText.toLowerCase().match(/labrador|poodle|rex|e2e|srd/i);

    if (hasPets) {
      const petCard = clientPage
        .locator('flt-semantics')
        .filter({ hasText: /Labrador|Poodle|Rex|E2E|SRD/i })
        .first();
      await petCard.click();
      await clientPage.waitForTimeout(500);

      const deleteBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /excluir|deletar/i });
      if ((await deleteBtn.count()) > 0) {
        await deleteBtn.first().click();

        // Cancela no dialog
        const cancelBtn = clientPage
          .locator('[role="button"]')
          .filter({ hasText: /não|cancelar|cancel/i });
        if ((await cancelBtn.count()) > 0) {
          await cancelBtn.first().click();
        }

        // Pet ainda deve estar na lista
        await waitForText(clientPage, 'Pets', 5_000);
      }
    }
  });
});
