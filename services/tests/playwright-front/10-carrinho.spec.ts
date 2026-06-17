import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  registerUser,
  SeededUser,
  seedFullEstablishment,
} from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  searchProduct,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let cliente: SeededUser;
let produtoNome: string;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
  const seed = await seedFullEstablishment(api);
  produtoNome = seed.product.name;
});
test.afterAll(async () => {
  await api.dispose();
});
test("adicionar 2 unidades ao carrinho e depois esvaziar", async ({ page }) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await searchProduct(page, produtoNome);
  await tapText(page, produtoNome);
  await waitForText(page, "Adicionar ao Carrinho");
  await tapButton(page, "Adicionar ao Carrinho");
  await tapButton(page, "Voltar");
  await tapButton(page, "Carrinho");
  await waitForText(page, produtoNome);
  await expectText(page, "Ir para Pagamento");
  await expectText(page, /1 item/);
  await tapText(page, "Limpar");
  await expectText(page, "Seu carrinho está vazio");
  await expect
    .poll(async () => byText(page, "Ir para Pagamento").count())
    .toBe(0);
});
