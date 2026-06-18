import { APIRequestContext, expect, test } from "@playwright/test";
import { apiContext, registerUser, SeededUser } from "./_api";
import {
  bootAndLogin,
  button,
  byText,
  expectText,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
let cliente: SeededUser;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
});
test.afterAll(async () => {
  await api.dispose();
});
test("cliente abre a tela de notificações (carrega contra o backend real)", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapText(page, "Perfil");
  await waitForText(page, "Notificações");
  const alvo = button(page, "Notificações").first();
  await expect
    .poll(
      async () => {
        await alvo.click({ force: true }).catch(() => {});
        return byText(page, /Nenhuma notificação|Você está em dia/)
          .first()
          .isVisible()
          .catch(() => false);
      },
      { timeout: 40_000, intervals: [1000] },
    )
    .toBe(true);
  await expectText(page, "Você está em dia!");
});
