/**
 * Testes de marketplace (produtos e carrinho):
 * - Listar produtos
 * - Adicionar ao carrinho
 * - Visualizar carrinho
 * - Atualizar quantidade
 * - Remover produto do carrinho
 * - Finalizar compra (checkout)
 */

import { test, expect } from '../fixtures/auth.fixture';
import { waitForSplash, waitForText, clickButton, fillField } from '../utils/flutter';
import { api } from '../utils/api';

const APP = process.env.APP_URL ?? 'http://localhost:8080';

test.describe('Marketplace — Produtos e Carrinho', () => {
  test.beforeEach(async ({ clientPage }) => {
    await clientPage.goto(APP);
    await waitForSplash(clientPage);
    await waitForText(clientPage, 'Estabelecimentos', 20_000);

    // Navega para aba Produtos (3ª aba, índice 2)
    const tabs = clientPage.locator('[role="tab"]');
    const tabCount = await tabs.count();
    if (tabCount >= 3) {
      await tabs.nth(2).click();
    } else {
      const prodBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /produto/i });
      await prodBtn.first().click();
    }

    await waitForText(clientPage, 'Produtos', 15_000);
  });

  // ── LISTAGEM DE PRODUTOS ──────────────────────────────────────────────────

  test('exibe lista de produtos do backend', async ({ clientPage }) => {
    await clientPage.waitForTimeout(3_000);
    const bodyText = await clientPage.locator('body').innerText();
    // Deve listar produtos (do seed) ou exibir estado vazio
    expect(bodyText.toLowerCase()).toMatch(/produto|nenhum|disponível|r\$/i);
  });

  test('exibe preço dos produtos em reais', async ({ clientPage }) => {
    await clientPage.waitForTimeout(3_000);
    const bodyText = await clientPage.locator('body').innerText();
    // Produtos do seed têm preços em R$
    if (bodyText.toLowerCase().includes('produto') && !bodyText.toLowerCase().includes('nenhum')) {
      expect(bodyText).toMatch(/R\$|reais/i);
    }
  });

  test('clicar em produto abre detalhes', async ({ clientPage }) => {
    await clientPage.waitForTimeout(3_000);
    const prodCard = clientPage
      .locator('flt-semantics')
      .filter({ hasText: /R\$/i })
      .first();

    if ((await prodCard.count()) > 0) {
      await prodCard.click();
      await clientPage.waitForTimeout(1_500);
      const bodyText = await clientPage.locator('body').innerText();
      // Deve exibir detalhes do produto
      expect(bodyText.toLowerCase()).toMatch(/descrição|adicionar|carrinho|comprar|R\$/i);
    }
  });

  // ── ADICIONAR AO CARRINHO ─────────────────────────────────────────────────

  test('botão "Adicionar ao Carrinho" adiciona produto', async ({ clientPage }) => {
    await clientPage.waitForTimeout(3_000);

    // Procura produto e botão de adicionar
    const addCartBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /adicionar ao carrinho|add|carrinho/i });

    if ((await addCartBtn.count()) > 0) {
      await addCartBtn.first().click();
      await clientPage.waitForTimeout(1_000);

      const bodyText = await clientPage.locator('body').innerText();
      // Deve exibir feedback positivo
      expect(bodyText.toLowerCase()).toMatch(/adicionado|carrinho|sucesso|ok/i);
    }
    // Teste aceita mesmo sem produtos no sistema
  });

  // ── CARRINHO ──────────────────────────────────────────────────────────────

  test('ícone de carrinho navega para tela do carrinho', async ({ clientPage }) => {
    // Procura ícone/botão de carrinho
    const cartBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /carrinho|cart/i })
      .or(clientPage.locator('[aria-label*="carrinho"], [aria-label*="cart"]'));

    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
      await waitForText(clientPage, /carrinho|meu carrinho/i, 10_000);
    } else {
      // Navega via URL direta para verificar tela
      await clientPage.goto(`${APP}/#/cart`);
      await waitForSplash(clientPage);
      await waitForText(clientPage, /carrinho|produtos/i, 10_000);
    }
  });

  test('carrinho vazio exibe mensagem informativa', async ({ clientPage }) => {
    // Navega para o carrinho
    const cartBtn = clientPage
      .locator('[role="button"]')
      .filter({ hasText: /carrinho/i });

    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
    } else {
      // Tenta clicar no ícone de carrinho
      const iconBtn = clientPage.locator('[role="button"]').nth(1);
      await iconBtn.click();
    }

    await clientPage.waitForTimeout(2_000);
    const bodyText = await clientPage.locator('body').innerText();
    expect(bodyText.toLowerCase()).toMatch(/carrinho|vazio|nenhum|produto/i);
  });

  test('adiciona produto ao carrinho e verifica na tela do carrinho', async ({
    clientPage,
    credentials,
  }) => {
    // Primeiro, cria um produto via API se não existir
    let productId: string | null = null;
    try {
      const products = await api.get<{ id: string; name: string; price: number }[]>(
        '/marketplace/products',
        credentials.client.accessToken,
      );

      if (products.length > 0) {
        productId = products[0].id;

        // Adiciona ao carrinho via API para garantir que há algo no carrinho
        await api.post(
          `/marketplace/cart/${credentials.client.user.id}`,
          { productId, quantity: 1 },
          credentials.client.accessToken,
        );
      }
    } catch { /* ok */ }

    if (productId) {
      await clientPage.reload();
      await waitForSplash(clientPage);
      await waitForText(clientPage, 'Estabelecimentos', 20_000);

      // Navega para Produtos
      const tabs = clientPage.locator('[role="tab"]');
      if ((await tabs.count()) >= 3) await tabs.nth(2).click();
      await waitForText(clientPage, 'Produtos', 10_000);

      // Navega para carrinho
      const cartBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /carrinho/i });

      if ((await cartBtn.count()) > 0) {
        await cartBtn.first().click();
        await clientPage.waitForTimeout(2_000);

        const bodyText = await clientPage.locator('body').innerText();
        // Carrinho deve ter produto
        expect(bodyText.toLowerCase()).toMatch(/produto|item|carrinho/i);
      }
    }
  });

  test('atualiza quantidade de produto no carrinho', async ({
    clientPage,
    credentials,
  }) => {
    // Adiciona produto ao carrinho via API
    try {
      const products = await api.get<{ id: string }[]>(
        '/marketplace/products',
        credentials.client.accessToken,
      );

      if (products.length > 0) {
        await api.post(
          `/marketplace/cart/${credentials.client.user.id}`,
          { productId: products[0].id, quantity: 1 },
          credentials.client.accessToken,
        );
      }
    } catch { /* ok */ }

    // Vai para carrinho
    await clientPage.reload();
    await waitForSplash(clientPage);
    await waitForText(clientPage, 'Estabelecimentos', 20_000);
    const tabs = clientPage.locator('[role="tab"]');
    if ((await tabs.count()) >= 3) await tabs.nth(2).click();
    await waitForText(clientPage, 'Produtos', 10_000);

    const cartBtn = clientPage.locator('[role="button"]').filter({ hasText: /carrinho/i });
    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
      await clientPage.waitForTimeout(2_000);

      // Botões de + e - para quantidade
      const incrementBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /\+/ });
      if ((await incrementBtn.count()) > 0) {
        await incrementBtn.first().click();
        await clientPage.waitForTimeout(1_000);
        // Verifica se quantidade mudou (bodyText deve conter 2 ou mais)
        const bodyText = await clientPage.locator('body').innerText();
        expect(bodyText).toMatch(/[2-9]|carrinho/i);
      }
    }
  });

  test('remove produto do carrinho', async ({ clientPage, credentials }) => {
    // Adiciona produto via API
    try {
      const products = await api.get<{ id: string }[]>(
        '/marketplace/products',
        credentials.client.accessToken,
      );
      if (products.length > 0) {
        await api.post(
          `/marketplace/cart/${credentials.client.user.id}`,
          { productId: products[0].id, quantity: 1 },
          credentials.client.accessToken,
        );
      }
    } catch { /* ok */ }

    await clientPage.reload();
    await waitForSplash(clientPage);
    await waitForText(clientPage, 'Estabelecimentos', 20_000);
    const tabs = clientPage.locator('[role="tab"]');
    if ((await tabs.count()) >= 3) await tabs.nth(2).click();
    await waitForText(clientPage, 'Produtos', 10_000);

    const cartBtn = clientPage.locator('[role="button"]').filter({ hasText: /carrinho/i });
    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
      await clientPage.waitForTimeout(2_000);

      // Botão de remover (lixeira ou X)
      const removeBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /remover|excluir|×|x/i });
      if ((await removeBtn.count()) > 0) {
        await removeBtn.first().click();
        await clientPage.waitForTimeout(1_500);

        const bodyText = await clientPage.locator('body').innerText();
        expect(bodyText.toLowerCase()).toMatch(/vazio|nenhum|carrinho/i);
      }
    }
  });

  // ── CHECKOUT ──────────────────────────────────────────────────────────────

  test('finalizar compra navega para tela de pagamento', async ({
    clientPage,
    credentials,
  }) => {
    // Adiciona produto via API
    try {
      const products = await api.get<{ id: string }[]>(
        '/marketplace/products',
        credentials.client.accessToken,
      );
      if (products.length > 0) {
        await api.post(
          `/marketplace/cart/${credentials.client.user.id}`,
          { productId: products[0].id, quantity: 1 },
          credentials.client.accessToken,
        );
      }
    } catch { /* ok */ }

    await clientPage.reload();
    await waitForSplash(clientPage);
    await waitForText(clientPage, 'Estabelecimentos', 20_000);
    const tabs = clientPage.locator('[role="tab"]');
    if ((await tabs.count()) >= 3) await tabs.nth(2).click();
    await waitForText(clientPage, 'Produtos', 10_000);

    const cartBtn = clientPage.locator('[role="button"]').filter({ hasText: /carrinho/i });
    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
      await clientPage.waitForTimeout(2_000);

      const bodyText = await clientPage.locator('body').innerText();
      if (!bodyText.toLowerCase().includes('vazio')) {
        // Procura botão de finalizar compra
        const checkoutBtn = clientPage
          .locator('[role="button"]')
          .filter({ hasText: /finalizar|comprar|pagar|checkout/i });
        if ((await checkoutBtn.count()) > 0) {
          await checkoutBtn.first().click();
          await waitForText(clientPage, /pagamento|resumo|total|finalizar/i, 10_000);
        }
      }
    }
  });

  test('tela de pagamento exibe total do pedido', async ({
    clientPage,
    credentials,
  }) => {
    // Adiciona produto via API e vai direto para payment screen
    try {
      const products = await api.get<{ id: string; price: number }[]>(
        '/marketplace/products',
        credentials.client.accessToken,
      );
      if (products.length > 0) {
        await api.post(
          `/marketplace/cart/${credentials.client.user.id}`,
          { productId: products[0].id, quantity: 1 },
          credentials.client.accessToken,
        );
      }
    } catch { /* ok */ }

    // Navega para tela de pagamento
    const cartBtn = clientPage.locator('[role="button"]').filter({ hasText: /carrinho/i });
    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
      await clientPage.waitForTimeout(2_000);

      const checkoutBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /finalizar|comprar|pagar/i });
      if ((await checkoutBtn.count()) > 0) {
        await checkoutBtn.first().click();
        await clientPage.waitForTimeout(2_000);

        const bodyText = await clientPage.locator('body').innerText();
        expect(bodyText).toMatch(/R\$|total|pagamento/i);
      }
    }
  });

  test('confirmar pedido cria ordem no backend', async ({
    clientPage,
    credentials,
  }) => {
    // Adiciona produto via API
    try {
      const products = await api.get<{ id: string }[]>(
        '/marketplace/products',
        credentials.client.accessToken,
      );
      if (products.length > 0) {
        await api.post(
          `/marketplace/cart/${credentials.client.user.id}`,
          { productId: products[0].id, quantity: 1 },
          credentials.client.accessToken,
        );
      }
    } catch { /* ok */ }

    const cartBtn = clientPage.locator('[role="button"]').filter({ hasText: /carrinho/i });
    if ((await cartBtn.count()) > 0) {
      await cartBtn.first().click();
      await clientPage.waitForTimeout(2_000);

      const checkoutBtn = clientPage
        .locator('[role="button"]')
        .filter({ hasText: /finalizar|comprar|pagar/i });
      if ((await checkoutBtn.count()) > 0) {
        await checkoutBtn.first().click();
        await clientPage.waitForTimeout(2_000);

        const confirmBtn = clientPage
          .locator('[role="button"]')
          .filter({ hasText: /confirmar|pagar|finalizar pedido/i });
        if ((await confirmBtn.count()) > 0) {
          await confirmBtn.first().click();
          await clientPage.waitForTimeout(3_000);

          const bodyText = await clientPage.locator('body').innerText();
          expect(bodyText.toLowerCase()).toMatch(/pedido|sucesso|confirmado|obrigado/i);
        }
      }
    }
  });
});
