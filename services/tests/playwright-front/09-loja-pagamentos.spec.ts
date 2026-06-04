import { test, APIRequestContext } from '@playwright/test';
import {
  bootAndLogin, tapText, tapButton, expectText, waitForText, fill, textFields, searchProduct, pollTap,
} from './_helpers';
import { apiContext, registerUser, seedFullEstablishment, SeededUser } from './_api';
let api: APIRequestContext;
let cliente: SeededUser;
let produtoNome: string;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: 'CLIENTE' });
  const seed = await seedFullEstablishment(api);
  produtoNome = seed.product.name;
});
test.afterAll(async () => { await api.dispose(); });
async function adicionarAoCarrinho(page: import('@playwright/test').Page) {
  await searchProduct(page, produtoNome);
  await tapText(page, produtoNome);
  await waitForText(page, 'Adicionar ao Carrinho');
  await tapButton(page, 'Adicionar ao Carrinho');
  await tapButton(page, 'Voltar');
  await tapButton(page, 'Carrinho');
  await waitForText(page, 'Ir para Pagamento');
  await tapButton(page, 'Ir para Pagamento');
  await waitForText(page, 'Forma de pagamento');
}
test('pagar com cartão de crédito gera comprovante aprovado', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await adicionarAoCarrinho(page);
  await pollTap(page, 'Crédito', /cartão/i);
  const campos = textFields(page);
  await fill(campos.nth(0), '4111 1111 1111 1111');
  await fill(campos.nth(1), 'CLIENTE E2E');
  await fill(campos.nth(2), '12/30');
  await fill(campos.nth(3), '123');
  await tapButton(page, 'Confirmar Pedido');
  await expectText(page, /Pagamento Aprovado|Pagamento Recusado/);
});
test('pagar com boleto mostra o código do boleto', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await adicionarAoCarrinho(page);
  await tapText(page, 'Boleto');
  await tapButton(page, 'Confirmar Pedido');
  await expectText(page, 'Código do Boleto');
});
