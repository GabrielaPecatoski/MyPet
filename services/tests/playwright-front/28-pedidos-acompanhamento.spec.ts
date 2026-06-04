import { test, expect, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, expectText, waitForText, byText, pollTap, openLojaSearch,
} from './_helpers';
import {
  apiContext, registerUser, createEstablishment, createProduct,
  addToCart, checkoutOrder, payOrder, advanceOrder, seedFinalizedOrder,
  SeededUser,
} from './_api';
let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;
let clienteEmAndamento: SeededUser;
let produtoNomeAndamento: string;
let clienteFinalizado: SeededUser;
let produtoNomeFinalizado: string;
test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab Track E2E' });
  const estab = await createEstablishment(api, owner, { name: `Pet Shop Track ${Date.now()}` });
  estabId = estab.id;
  const ts1 = Date.now().toString().slice(-5);
  produtoNomeAndamento = `Racao Track ${ts1}`;
  clienteEmAndamento = await registerUser(api, { role: 'CLIENTE' });
  const prodAndamento = await createProduct(api, owner, estabId, {
    name: produtoNomeAndamento, price: 49.90, stock: 20,
  });
  await addToCart(api, clienteEmAndamento, prodAndamento.id, 1);
  const orderAndamento = await checkoutOrder(api, clienteEmAndamento);
  await payOrder(api, clienteEmAndamento, orderAndamento.id, {
    method: 'PIX', deliveryMethod: 'DELIVERY', deliveryAddress: 'Rua dos Testes, 200',
  });
  const ts2 = (Date.now() + 1).toString().slice(-5);
  produtoNomeFinalizado = `Brinquedo Track ${ts2}`;
  const prodFinalizado = await createProduct(api, owner, estabId, {
    name: produtoNomeFinalizado, price: 29.90, stock: 15,
  });
  clienteFinalizado = await registerUser(api, { role: 'CLIENTE' });
  await addToCart(api, clienteFinalizado, prodFinalizado.id, 1);
  const orderFinalizado = await checkoutOrder(api, clienteFinalizado);
  await payOrder(api, clienteFinalizado, orderFinalizado.id, {
    method: 'PIX', deliveryMethod: 'DELIVERY', deliveryAddress: 'Rua dos Testes, 300',
  });
  await advanceOrder(api, owner, orderFinalizado.id);
  await advanceOrder(api, owner, orderFinalizado.id);
});
test.afterAll(async () => { await api.dispose(); });
async function openPedidosTab(page: Parameters<typeof bootAndLogin>[0], email: string, senha: string) {
  await bootAndLogin(page, email, senha);
  await openLojaSearch(page);
  await pollTap(page, 'Pedidos', /Enviando já|Indo até|Finalizado|Nenhum pedido/);
}
test('aba Pedidos mostra pedido ENVIANDO com label correto', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  await expectText(page, 'Enviando já');
});
test('pedido ENVIANDO exibe tipo Entrega e endereço', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  await expectText(page, 'Entrega');
  await expectText(page, /Rua dos Testes/);
});
test('pedido ENVIANDO mostra barra de progresso com etapas', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  await expectText(page, 'Enviando já');
  await expectText(page, 'Finalizado');
});
test('pedido ENVIANDO mostra total do pedido', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  await expectText(page, /Total:.*R\$/);
});
test('filtro "Em andamento" mantém pedido ENVIANDO visível', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  await tapText(page, 'Em andamento');
  await waitForText(page, 'Enviando já');
  await expectText(page, 'Entrega');
});
test('filtro "Finalizados" oculta pedido ENVIANDO e mostra mensagem vazia', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  await tapText(page, 'Finalizados');
  await waitForText(page, 'Nenhum pedido finalizado');
  const visivel = await byText(page, 'Enviando já').first().isVisible({ timeout: 2_000 }).catch(() => false);
  expect(visivel).toBe(false);
});
test('filtro "Finalizados" mostra pedido FINALIZADO', async ({ page }) => {
  await openPedidosTab(page, clienteFinalizado.email, clienteFinalizado.password);
  await tapText(page, 'Finalizados');
  await waitForText(page, 'Finalizado');
});
test('filtro "Em andamento" oculta pedido FINALIZADO e mostra mensagem vazia', async ({ page }) => {
  await openPedidosTab(page, clienteFinalizado.email, clienteFinalizado.password);
  await tapText(page, 'Em andamento');
  await waitForText(page, 'Nenhum pedido em andamento');
  const visivel = await byText(page, 'Finalizado').first().isVisible({ timeout: 2_000 }).catch(() => false);
  expect(visivel).toBe(false);
});
test('filtro "Todos" mostra pedido FINALIZADO', async ({ page }) => {
  await openPedidosTab(page, clienteFinalizado.email, clienteFinalizado.password);
  await expectText(page, 'Finalizado');
});
test('pedido FINALIZADO mostra barra de progresso completa', async ({ page }) => {
  await openPedidosTab(page, clienteFinalizado.email, clienteFinalizado.password);
  await expectText(page, 'Finalizado');
  await expectText(page, 'Enviando já');
});
test('pedido ENVIANDO não exibe label de cancelado', async ({ page }) => {
  await openPedidosTab(page, clienteEmAndamento.email, clienteEmAndamento.password);
  const cancelado = await byText(page, 'Pedido cancelado').first().isVisible({ timeout: 2_000 }).catch(() => false);
  expect(cancelado).toBe(false);
});
