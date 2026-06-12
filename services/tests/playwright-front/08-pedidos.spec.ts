import { APIRequestContext, expect, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  registerUser,
  SeededUser,
  seedPaidOrder,
} from "./_api";
import {
  bootAndLogin,
  button,
  expectText,
  openClientTab,
  openLojaSearch,
  pollTap,
  tapButton,
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
  await pollTap(page, "Pedidos", "Saiu para entrega");
  await pollTap(page, "Saiu para entrega", "Finalizar pedido");
  await tapButton(page, "Finalizar pedido");
  await expect
    .poll(async () => button(page, "Finalizar pedido").count(), {
      timeout: 40_000,
    })
    .toBe(0);
});
