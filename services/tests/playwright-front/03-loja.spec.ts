import { test, APIRequestContext } from '@playwright/test';
import { bootAndLogin, tapText, tapButton, expectText, waitForText, searchProduct } from './_helpers';
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
test('comprar um produto: loja → carrinho → pagamento', async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await searchProduct(page, produtoNome);
  await tapText(page, produtoNome);
  await waitForText(page, 'Adicionar ao Carrinho');
  await tapButton(page, 'Adicionar ao Carrinho');
  await tapButton(page, 'Voltar');
  await tapButton(page, 'Carrinho');
  await waitForText(page, 'Ir para Pagamento');
  await tapButton(page, 'Ir para Pagamento');
  await waitForText(page, 'Forma de pagamento');
  await tapButton(page, 'Confirmar Pedido');
  await expectText(page, /Chave Pix|Aguardando Pagamento|Pagamento Aprovado/);
});
