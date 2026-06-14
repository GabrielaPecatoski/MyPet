import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  registerUser,
  SeededUser,
  seedFullEstablishment,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  fill,
  scrollToText,
  tapText,
  textFields,
} from "./_helpers";

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
  // A home lista TODOS os estabelecimentos; usa a busca para filtrar até o
  // recém-criado (a lista cresce com os dados acumulados das rodadas).
  await fill(textFields(page).first(), estabNome);
  await page.waitForTimeout(800);
  await scrollToText(page, estabNome);
  await tapText(page, estabNome);
  await expectText(page, "Serviços Oferecidos");
  await expectText(page, "Agendar Serviço");
});
