import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
  seedPaidOrder,
} from "./_api";
import {
  bootAndLogin,
  byText,
  expectText,
  openClientTab,
  openLojaSearch,
  pollTap,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let owner: SeededUser;
let estabId: string;
test.beforeAll(async () => {
  api = await apiContext();
  owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab E2E",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop E2E ${Date.now()}`,
  });
  estabId = estab.id;
});
test.afterAll(async () => {
  await api.dispose();
});
test("cliente vê o acompanhamento do pedido na loja", async ({ page }) => {
  const seed = await seedPaidOrder(api, owner, estabId);
  await bootAndLogin(page, seed.cliente.email, seed.cliente.password);
  await openLojaSearch(page);
  await pollTap(page, "Pedidos", "Enviando já");
  await expectText(page, "Enviando já");
  await expectText(page, "Indo até o endereço");
});
test("estabelecimento acompanha e avança o pedido até finalizado", async ({
  page,
}) => {
  await seedPaidOrder(api, owner, estabId);
  await bootAndLogin(page, owner.email, owner.password);
  await openClientTab(page, "Produtos", "Pedidos");
  // pedido pago entra em "Preparando" (ENVIANDO) com o botão "Saiu para entrega"
  await pollTap(page, "Pedidos", "Saiu para entrega");
  await byText(page, "Saiu para entrega").first().click({ force: true });
  // ao sair para entrega o pedido migra para a aba "A caminho"
  await byText(page, "A caminho").first().click({ force: true });
  await waitForText(page, "Finalizar pedido");
  await byText(page, "Finalizar pedido").first().click({ force: true });
  // finalizado, o pedido passa para a aba "Entregues"
  await byText(page, "Entregues").first().click({ force: true });
  await waitForText(page, "Pedido finalizado");
});
