import { APIRequestContext, expect, Page, test } from "@playwright/test";
import {
  addToCart,
  apiContext,
  checkoutOrder,
  createEstablishment,
  createProduct,
  payOrder,
  registerUser,
  SeededUser,
  seedFinalizedOrder,
  seedPaidOrder,
} from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  openClientTab,
  pollTap,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;

let ownerDelivery: SeededUser;
let estabDeliveryId: string;

let ownerPickup: SeededUser;
let estabPickupId: string;

let ownerFinal: SeededUser;
let estabFinalId: string;

test.beforeAll(async () => {
  api = await apiContext();

  ownerDelivery = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Ped Del E2E",
  });
  const eDelivery = await createEstablishment(api, ownerDelivery, {
    name: `PetDel ${Date.now()}`,
  });
  estabDeliveryId = eDelivery.id;
  await seedPaidOrder(api, ownerDelivery, estabDeliveryId);

  ownerPickup = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Ped Pick E2E",
  });
  const ePickup = await createEstablishment(api, ownerPickup, {
    name: `PetPick ${Date.now() + 1}`,
  });
  estabPickupId = ePickup.id;
  const prodPick = await createProduct(api, ownerPickup, estabPickupId, {
    name: "Prod Pick E2E",
    price: 19.9,
    stock: 10,
  });
  const cliPick = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliPick, prodPick.id, 1);
  const oPick = await checkoutOrder(api, cliPick);
  await payOrder(api, cliPick, oPick.id, {
    method: "PIX",
    deliveryMethod: "PICKUP",
  });

  ownerFinal = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Ped Fin E2E",
  });
  const eFinal = await createEstablishment(api, ownerFinal, {
    name: `PetFin ${Date.now() + 3}`,
  });
  estabFinalId = eFinal.id;
  await seedFinalizedOrder(api, ownerFinal, estabFinalId);
});

test.afterAll(async () => {
  await api.dispose();
});

// abre a aba Pedidos do estabelecimento; os chips de status sempre aparecem
// quando há pelo menos um pedido visível (Preparando é o primeiro chip).
async function abrirPedidosEstab(page: Page, owner: SeededUser) {
  await bootAndLogin(page, owner.email, owner.password);
  await openClientTab(page, "Produtos", "Pedidos");
  await pollTap(page, "Pedidos", "Preparando");
}

// troca de chip de status e espera um texto-prova do conteúdo daquela aba.
async function irParaAba(page: Page, chip: string, probe: string | RegExp) {
  await byText(page, chip).first().click({ force: true });
  await waitForText(page, probe);
}

test("aba Pedidos exibe os chips de status", async ({ page }) => {
  await abrirPedidosEstab(page, ownerDelivery);
  await expectText(page, "Preparando");
  await expectText(page, "A caminho");
  await expectText(page, "Prontos");
  await expectText(page, "Entregues");
});

test('pedido de entrega pago aparece em "Preparando" com badge "Enviando já"', async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerDelivery);
  await expectText(page, "Enviando já");
});

test('pedido de entrega mostra label "Entrega" e endereço', async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerDelivery);
  await expectText(page, "Entrega");
  await expectText(page, /Rua dos Testes/);
});

test("pedido de entrega exibe total do pedido", async ({ page }) => {
  await abrirPedidosEstab(page, ownerDelivery);
  await expectText(page, /Total:.*R\$/);
});

test("pedido de entrega exibe barra de progresso com todas as etapas", async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerDelivery);
  await expectText(page, "Aguardando pagamento");
  await expectText(page, "Enviando já");
  await expectText(page, "Indo até o endereço");
  await expectText(page, "Finalizado");
});

test('"Saiu para entrega" move o pedido de "Preparando" para "A caminho"', async ({
  page,
}) => {
  await seedPaidOrder(api, ownerDelivery, estabDeliveryId);
  await abrirPedidosEstab(page, ownerDelivery);
  await byText(page, "Saiu para entrega").first().click({ force: true });
  // o pedido sai de Preparando e passa a aparecer na aba "A caminho"
  await irParaAba(page, "A caminho", "Indo até o endereço");
});

test('"Finalizar pedido" conclui o ciclo e o pedido vai para "Entregues"', async ({
  page,
}) => {
  await seedPaidOrder(api, ownerDelivery, estabDeliveryId);
  await abrirPedidosEstab(page, ownerDelivery);
  await byText(page, "Saiu para entrega").first().click({ force: true });
  await irParaAba(page, "A caminho", "Finalizar pedido");
  await byText(page, "Finalizar pedido").first().click({ force: true });
  await irParaAba(page, "Entregues", "Pedido finalizado");
});

test('pedido em "Entregues" não exibe botão de avanço', async ({ page }) => {
  await abrirPedidosEstab(page, ownerFinal);
  await irParaAba(page, "Entregues", "Pedido finalizado");
  const btnVisible = await byText(page, "Saiu para entrega")
    .first()
    .isVisible({ timeout: 2_000 })
    .catch(() => false);
  expect(btnVisible).toBe(false);
});

test('pedido de retirada aparece em "Preparando" com badge "Preparando"', async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerPickup);
  await expectText(page, "Preparando");
  await expectText(page, "Marcar como pronto");
});

test('pedido de retirada mostra "Retirada no local" (sem endereço)', async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerPickup);
  await expectText(page, "Retirada no local");
});

test("pedido de retirada exibe barra de progresso com etapas de pickup", async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerPickup);
  await expectText(page, "Pronto p/ retirada");
  await expectText(page, "Finalizado");
});

test('"Marcar como pronto" move a retirada de "Preparando" para "Prontos"', async ({
  page,
}) => {
  const prodPick2 = await createProduct(api, ownerPickup, estabPickupId, {
    name: `Prod Pick2 ${Date.now()}`,
    price: 14.9,
    stock: 5,
  });
  const cliPick2 = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliPick2, prodPick2.id, 1);
  const oPick2 = await checkoutOrder(api, cliPick2);
  await payOrder(api, cliPick2, oPick2.id, {
    method: "PIX",
    deliveryMethod: "PICKUP",
  });

  await abrirPedidosEstab(page, ownerPickup);
  await byText(page, "Marcar como pronto").first().click({ force: true });
  await irParaAba(page, "Prontos", "Pronto p/ retirada");
});

test('pedido finalizado aparece na aba "Entregues" com banner verde', async ({
  page,
}) => {
  await abrirPedidosEstab(page, ownerFinal);
  await irParaAba(page, "Entregues", "Pedido finalizado");
  await expectText(page, "Finalizado");
});

test('pedido finalizado não aparece na aba "Preparando"', async ({ page }) => {
  await abrirPedidosEstab(page, ownerFinal);
  // default é Preparando; o finalizado não deve estar aqui
  const visivel = await byText(page, "Pedido finalizado")
    .first()
    .isVisible({ timeout: 2_000 })
    .catch(() => false);
  expect(visivel).toBe(false);
});
