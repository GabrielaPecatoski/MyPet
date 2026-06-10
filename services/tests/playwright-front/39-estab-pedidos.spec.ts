/**
 * Gerenciamento de pedidos da loja pelo estabelecimento.
 * Testa a aba "Pedidos" dentro de EstabProdutosScreen (EstabPedidosView):
 *  - pedido DELIVERY: badge, endereço, total, barra de progresso, avanço completo
 *  - pedido PICKUP: badge "Preparando", "Retirada no local", avanço para "Pronto p/ retirada"
 *  - pedido AGUARDANDO_PAGAMENTO: banner de alerta, sem botão de avanço
 *  - pedido FINALIZADO: banner verde, sem botão de avanço
 */
import { test, expect, APIRequestContext, Page } from '@playwright/test';
import {
  bootAndLogin, expectText, openClientTab, pollTap, byText,
} from './_helpers';
import {
  apiContext, registerUser, createEstablishment, createProduct,
  addToCart, checkoutOrder, payOrder,
  seedPaidOrder, seedFinalizedOrder, SeededUser,
} from './_api';

let api: APIRequestContext;

// Um dono por grupo de testes para isolar estados
let ownerDelivery: SeededUser;
let estabDeliveryId: string;

let ownerPickup: SeededUser;
let estabPickupId: string;

let ownerUnpaid: SeededUser;

let ownerFinal: SeededUser;
let estabFinalId: string;

test.beforeAll(async () => {
  api = await apiContext();

  // Delivery: pedido pago, status ENVIANDO
  ownerDelivery = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Ped Del E2E' });
  const eDelivery = await createEstablishment(api, ownerDelivery, { name: `PetDel ${Date.now()}` });
  estabDeliveryId = eDelivery.id;
  await seedPaidOrder(api, ownerDelivery, estabDeliveryId);

  // Pickup: pedido pago com retirada no local
  ownerPickup = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Ped Pick E2E' });
  const ePickup = await createEstablishment(api, ownerPickup, { name: `PetPick ${Date.now() + 1}` });
  estabPickupId = ePickup.id;
  const prodPick = await createProduct(api, ownerPickup, estabPickupId, {
    name: 'Prod Pick E2E', price: 19.9, stock: 10,
  });
  const cliPick = await registerUser(api, { role: 'CLIENTE' });
  await addToCart(api, cliPick, prodPick.id, 1);
  const oPick = await checkoutOrder(api, cliPick);
  await payOrder(api, cliPick, oPick.id, { method: 'PIX', deliveryMethod: 'PICKUP' });

  // Unpaid: pedido criado mas não pago (AGUARDANDO_PAGAMENTO)
  ownerUnpaid = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Ped Unp E2E' });
  const eUnpaid = await createEstablishment(api, ownerUnpaid, { name: `PetUnp ${Date.now() + 2}` });
  const prodUnp = await createProduct(api, ownerUnpaid, eUnpaid.id, {
    name: 'Prod Unp E2E', price: 9.9, stock: 5,
  });
  const cliUnp = await registerUser(api, { role: 'CLIENTE' });
  await addToCart(api, cliUnp, prodUnp.id, 1);
  await checkoutOrder(api, cliUnp); // não paga → AGUARDANDO_PAGAMENTO

  // Finalizado: pedido já em FINALIZADO
  ownerFinal = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Ped Fin E2E' });
  const eFinal = await createEstablishment(api, ownerFinal, { name: `PetFin ${Date.now() + 3}` });
  estabFinalId = eFinal.id;
  await seedFinalizedOrder(api, ownerFinal, estabFinalId);
});

test.afterAll(async () => { await api.dispose(); });

// Navega ao painel do estab e abre a aba Pedidos, esperando que `probe` apareça
async function abrirPedidosEstab(page: Page, owner: SeededUser, probe: string | RegExp) {
  await bootAndLogin(page, owner.email, owner.password);
  await openClientTab(page, 'Produtos', 'Pedidos');
  await pollTap(page, 'Pedidos', probe);
}

// ─── PEDIDOS DE ENTREGA (DELIVERY) ───────────────────────────────────────────

test('aba Pedidos exibe pedido de entrega com badge "Enviando já"', async ({ page }) => {
  await abrirPedidosEstab(page, ownerDelivery, 'Saiu para entrega');
  await expectText(page, 'Enviando já');
});

test('pedido de entrega mostra label "Entrega" e endereço', async ({ page }) => {
  await abrirPedidosEstab(page, ownerDelivery, 'Saiu para entrega');
  await expectText(page, 'Entrega');
  await expectText(page, /Rua dos Testes/);
});

test('pedido de entrega exibe total do pedido', async ({ page }) => {
  await abrirPedidosEstab(page, ownerDelivery, 'Saiu para entrega');
  await expectText(page, /Total:.*R\$/);
});

test('pedido de entrega exibe barra de progresso com todas as etapas', async ({ page }) => {
  await abrirPedidosEstab(page, ownerDelivery, 'Saiu para entrega');
  // Barra de progresso: 4 etapas de entrega
  await expectText(page, 'Aguardando pagamento');
  await expectText(page, 'Enviando já');
  await expectText(page, 'Indo até o endereço');
  await expectText(page, 'Finalizado');
});

test('botão "Saiu para entrega" avança pedido e mostra badge "Indo até o endereço"', async ({ page }) => {
  // Seed pedido isolado para este teste de transição
  await seedPaidOrder(api, ownerDelivery, estabDeliveryId);
  await abrirPedidosEstab(page, ownerDelivery, 'Saiu para entrega');
  await pollTap(page, 'Saiu para entrega', /Indo até o endereço|Finalizar pedido/);
  await expectText(page, 'Indo até o endereço');
});

test('botão "Finalizar pedido" conclui o ciclo e mostra banner "Pedido finalizado"', async ({ page }) => {
  await seedPaidOrder(api, ownerDelivery, estabDeliveryId);
  await abrirPedidosEstab(page, ownerDelivery, 'Saiu para entrega');
  await pollTap(page, 'Saiu para entrega', 'Finalizar pedido');
  await pollTap(page, 'Finalizar pedido', 'Pedido finalizado');
  await expectText(page, 'Pedido finalizado');
});

test('pedido FINALIZADO não exibe botão de avanço', async ({ page }) => {
  await abrirPedidosEstab(page, ownerFinal, 'Pedido finalizado');
  const btnVisible = await byText(page, 'Saiu para entrega').first()
    .isVisible({ timeout: 2_000 }).catch(() => false);
  expect(btnVisible).toBe(false);
});

// ─── PEDIDOS DE RETIRADA (PICKUP) ─────────────────────────────────────────────

test('pedido de retirada exibe badge "Preparando" em vez de "Enviando já"', async ({ page }) => {
  await abrirPedidosEstab(page, ownerPickup, /Preparando|Marcar como pronto/);
  await expectText(page, 'Preparando');
});

test('pedido de retirada mostra "Retirada no local" (sem endereço)', async ({ page }) => {
  await abrirPedidosEstab(page, ownerPickup, /Preparando|Marcar como pronto/);
  await expectText(page, 'Retirada no local');
});

test('pedido de retirada exibe barra de progresso com etapas de pickup', async ({ page }) => {
  await abrirPedidosEstab(page, ownerPickup, /Preparando|Marcar como pronto/);
  await expectText(page, 'Preparando');
  await expectText(page, 'Pronto p/ retirada');
  await expectText(page, 'Finalizado');
});

test('botão "Marcar como pronto" avança pickup e mostra "Pronto p/ retirada"', async ({ page }) => {
  // Seed pedido pickup isolado para este teste
  const prodPick2 = await createProduct(api, ownerPickup, estabPickupId, {
    name: `Prod Pick2 ${Date.now()}`, price: 14.9, stock: 5,
  });
  const cliPick2 = await registerUser(api, { role: 'CLIENTE' });
  await addToCart(api, cliPick2, prodPick2.id, 1);
  const oPick2 = await checkoutOrder(api, cliPick2);
  await payOrder(api, cliPick2, oPick2.id, { method: 'PIX', deliveryMethod: 'PICKUP' });

  await abrirPedidosEstab(page, ownerPickup, 'Marcar como pronto');
  await pollTap(page, 'Marcar como pronto', /Pronto p\/ retirada|Finalizar pedido/);
  await expectText(page, 'Pronto p/ retirada');
});

// ─── PEDIDO AGUARDANDO PAGAMENTO ──────────────────────────────────────────────

test('pedido aguardando pagamento mostra banner "Aguardando pagamento do cliente"', async ({ page }) => {
  await abrirPedidosEstab(page, ownerUnpaid, 'Aguardando pagamento do cliente');
  await expectText(page, 'Aguardando pagamento do cliente');
});

test('pedido aguardando pagamento não exibe botão de avanço', async ({ page }) => {
  await abrirPedidosEstab(page, ownerUnpaid, 'Aguardando pagamento do cliente');
  const btn = await byText(page, /Saiu para entrega|Marcar como pronto/).first()
    .isVisible({ timeout: 2_000 }).catch(() => false);
  expect(btn).toBe(false);
});

// ─── PEDIDO FINALIZADO ────────────────────────────────────────────────────────

test('pedido finalizado exibe badge "Finalizado"', async ({ page }) => {
  await abrirPedidosEstab(page, ownerFinal, 'Pedido finalizado');
  await expectText(page, 'Finalizado');
});

test('pedido finalizado exibe banner verde "Pedido finalizado"', async ({ page }) => {
  await abrirPedidosEstab(page, ownerFinal, 'Pedido finalizado');
  await expectText(page, 'Pedido finalizado');
});
