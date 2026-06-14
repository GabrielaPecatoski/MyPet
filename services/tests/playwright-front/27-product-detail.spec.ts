import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  createProduct,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  pollText,
  searchProduct,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let cliente: SeededUser;
let produtoNome: string;
let produtoPreco: number;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
  const owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Detail E2E",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop Detail ${Date.now()}`,
  });
  const ts = Date.now().toString().slice(-5);
  produtoNome = `Shampoo Detail ${ts}`;
  produtoPreco = 34.9;
  await createProduct(api, owner, estab.id, {
    name: produtoNome,
    brand: "Marca Detail",
    price: produtoPreco,
    stock: 10,
    category: "Higiene",
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
test("detalhe exibe preço do produto", async ({ page }) => {
  await openDetail(page);
  await expectText(
    page,
    new RegExp(produtoPreco.toFixed(2).replace(".", "[.,]")),
  );
});
test("detalhe exibe categoria e disponibilidade", async ({ page }) => {
  await openDetail(page);
  await expectText(page, /Categoria/);
  await expectText(page, /Disponibilidade/);
  await expectText(page, "Em estoque");
});
test("detalhe exibe nome e marca do produto", async ({ page }) => {
  await openDetail(page);
  await expectText(page, produtoNome);
  await expectText(page, "Marca Detail");
});
test("quantidade começa em 1 e incrementa ao clicar +", async ({ page }) => {
  await openDetail(page);
  await expectText(page, "1");
  await tapButton(page, "Aumentar quantidade");
  await waitForText(page, "2");
  await tapButton(page, "Aumentar quantidade");
  await waitForText(page, "3");
});
test("decremento não vai abaixo de 1", async ({ page }) => {
  await openDetail(page);
  await tapButton(page, "Diminuir quantidade");
  await page.waitForTimeout(400);
  await expectText(page, "1");
});
test("incrementa para 2 e depois decrementa para 1", async ({ page }) => {
  await openDetail(page);
  await tapButton(page, "Aumentar quantidade");
  await waitForText(page, "2");
  await tapButton(page, "Diminuir quantidade");
  await waitForText(page, "1");
});
test("adicionar 2 unidades via detalhe mostra snackbar correto", async ({
  page,
}) => {
  await openDetail(page);
  await tapButton(page, "Aumentar quantidade");
  await waitForText(page, "2");
  await tapButton(page, "Adicionar ao Carrinho");
  await expectText(page, "2 unidades adicionadas ao carrinho");
});
test("adicionar 1 unidade via detalhe mostra snackbar no singular", async ({
  page,
}) => {
  await openDetail(page);
  await tapButton(page, "Adicionar ao Carrinho");
  await expectText(page, "1 unidade adicionada ao carrinho");
});
test('badge "X unidades no carrinho" aparece na tela de detalhe após adicionar', async ({
  page,
}) => {
  await openDetail(page);
  await tapButton(page, "Adicionar ao Carrinho");
  await waitForText(page, "1 unidade adicionada ao carrinho");
  await tapButton(page, "Voltar");
  await tapText(page, produtoNome);
  await waitForText(page, "Adicionar ao Carrinho");
  await expectText(page, /1 unidade no carrinho/);
});
test("botão Voltar retorna para a loja", async ({ page }) => {
  await openDetail(page);
  await page.goBack({ timeout: 10_000 }).catch(async () => {
    await tapButton(page, "Voltar");
  });
  await pollText(page, new RegExp(produtoNome + "|Buscar produtos"), 30_000);
});
test('"Ver carrinho" no snackbar navega para o carrinho', async ({ page }) => {
  await openDetail(page);
  await tapButton(page, "Adicionar ao Carrinho");
  await waitForText(page, "1 unidade adicionada ao carrinho");
  await tapButton(page, "Ver carrinho");
  await expectText(page, /Ir para Pagamento|carrinho/i);
});
