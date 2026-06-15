import { APIRequestContext, test } from "@playwright/test";
import {
  addToCart,
  apiContext,
  checkoutOrder,
  createEstablishment,
  createProduct,
  payOrder,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  pollTap,
  scrollToText,
  searchProduct,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

// C18 — Histórico do produto da loja.
// Um único pedido pago alimenta as duas visões:
//  - cliente: "Você já comprou este produto" + "Comprar novamente" no detalhe;
//  - loja: sheet "Histórico de vendas" no card do produto.

let api: APIRequestContext;
let owner: SeededUser;
let cliente: SeededUser;
let produtoNome: string;
const QTD_COMPRADA = 2;

test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Historico E2E",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Historico ${Date.now()}`,
  });
  const ts = Date.now().toString().slice(-5);
  produtoNome = `Historico E2E ${ts}`;
  const product = await createProduct(api, owner, estab.id, {
    name: produtoNome,
    brand: "Marca Historico",
    price: 39.9,
    stock: 12,
    category: "Higiene",
  });

  // cliente compra e paga -> pedido vira ENVIANDO (venda concretizada)
  cliente = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliente, product.id, QTD_COMPRADA);
  const order = await checkoutOrder(api, cliente);
  await payOrder(api, cliente, order.id, {
    method: "PIX",
    deliveryMethod: "DELIVERY",
  });
});

test.afterAll(async () => {
  await api.dispose();
});

async function openDetail(page: Parameters<typeof bootAndLogin>[0]) {
  await bootAndLogin(page, cliente.email, cliente.password);
  await searchProduct(page, produtoNome);
  await tapText(page, produtoNome);
  await waitForText(page, "Adicionar ao Carrinho");
}

test("cliente vê o histórico de compra do produto no detalhe", async ({
  page,
}) => {
  await openDetail(page);
  await expectText(page, "Você já comprou este produto");
  await expectText(page, "unidades compradas");
});

test('cliente recompra pelo botão "Comprar novamente"', async ({ page }) => {
  await openDetail(page);
  await expectText(page, "Você já comprou este produto");
  await tapButton(page, "Comprar novamente");
  // a recompra usa a quantidade do último pedido (2) -> snackbar no plural
  await expectText(page, `${QTD_COMPRADA} unidades adicionadas ao carrinho`);
});

test("loja vê o histórico de vendas do produto", async ({ page }) => {
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Produtos");
  await waitForText(page, "Meu Catálogo", 40_000);
  // catálogo carrega via 2 chamadas em sequência; espera o card renderizar
  await waitForText(page, produtoNome, 40_000);
  await scrollToText(page, produtoNome);

  // abre o sheet de vendas pelo botão "Vendas"; o probe na linha de venda
  // ("vendidas") faz o tap repetir até os dados realmente renderizarem
  await pollTap(page, "Vendas", "vendidas");

  await expectText(page, "Histórico de vendas");
  await expectText(page, produtoNome);
  await expectText(page, "R$");
  // o pedido pago aparece como "Em preparo" (status ENVIANDO)
  await expectText(page, "Em preparo");
});
