import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  fill,
  tapButton,
  tapText,
  textFields,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let owner: SeededUser;
test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab E2E",
  });
  await createEstablishment(api, owner, { name: `Pet Shop E2E ${Date.now()}` });
});
test.afterAll(async () => {
  await api.dispose();
});
test("vendedor cadastra um produto pela UI e ele aparece no catálogo", async ({
  page,
}) => {
  const nome = `Shampoo E2E ${Date.now().toString().slice(-5)}`;
  await bootAndLogin(page, owner.email, owner.password);
  await tapText(page, "Produtos");
  await waitForText(page, "Meu Catálogo", 40_000);
  await tapButton(page, "Produto");
  await waitForText(page, "Novo Produto");
  const campos = textFields(page);
  await fill(campos.nth(0), nome);
  await fill(campos.nth(1), "Marca E2E");
  await fill(campos.nth(3), "29.90");
  await fill(campos.nth(4), "15");
  await tapButton(page, "Adicionar Produto");
  await expectText(page, nome);
});
