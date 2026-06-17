import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  registerUser,
  SeededUser,
  seedFullEstablishment,
} from "./_api";
import { bootAndLogin, expectText, scrollToText, tapText } from "./_helpers";

let api: APIRequestContext;
let cliente: SeededUser;
let estabNome: string;
test.beforeAll(async () => {
  api = await apiContext();
  cliente = await registerUser(api, { role: "CLIENTE" });
  const seed = await seedFullEstablishment(api);
  estabNome = seed.estab.name;
});
test.afterAll(async () => {
  await api.dispose();
});
test("cliente encontra o estabelecimento na home e abre seus detalhes", async ({
  page,
}) => {
  await bootAndLogin(page, cliente.email, cliente.password);
  await page.waitForTimeout(2000);
  await scrollToText(page, estabNome);
  await tapText(page, estabNome);
  await expectText(page, "Serviços Oferecidos");
  await expectText(page, "Agendar Serviço");
});
