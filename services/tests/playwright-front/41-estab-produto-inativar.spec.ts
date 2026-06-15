import { APIRequestContext, test } from "@playwright/test";
import {
  apiContext,
  createEstablishment,
  createProduct,
  registerUser,
  SeededUser,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  pollTap,
  scrollToText,
  tapButton,
  tapText,
  waitForText,
} from "./_helpers";

let api: APIRequestContext;
// um dono por teste -> catálogo com 1 produto -> sem botões "Pausar"/"Excluir" duplicados
let ownerPausar: SeededUser;
let prodPausar: string;
let ownerExcluir: SeededUser;
let prodExcluir: string;

test.beforeAll(async () => {
  api = await apiContext();

  ownerPausar = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Pausar E2E",
  });
  const estabP = await createEstablishment(api, ownerPausar, {
    name: `Pet Shop Pausar ${Date.now()}`,
  });
  prodPausar = `Pausar E2E ${Date.now().toString().slice(-5)}`;
  await createProduct(api, ownerPausar, estabP.id, {
    name: prodPausar,
    price: 19.9,
    stock: 10,
  });

  ownerExcluir = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab Excluir E2E",
  });
  const estabE = await createEstablishment(api, ownerExcluir, {
    name: `Pet Shop Excluir ${Date.now()}`,
  });
  prodExcluir = `Excluir E2E ${(Date.now() + 1).toString().slice(-5)}`;
  await createProduct(api, ownerExcluir, estabE.id, {
    name: prodExcluir,
    price: 29.9,
    stock: 10,
  });
});

test.afterAll(async () => {
  await api.dispose();
});

test("pausar mantém o produto no catálogo (não some) e vira inativo", async ({
  page,
}) => {
  await bootAndLogin(page, ownerPausar.email, ownerPausar.password);
  await tapText(page, "Produtos");
  await waitForText(page, "Meu Catálogo", 40_000);

  await scrollToText(page, prodPausar);

  // pausa: o botão "Pausar" do card vira "Ativar" quando o produto fica inativo
  await pollTap(page, "Pausar", "Ativar");

  // o produto NÃO sumiu do catálogo (era esse o bug) — segue visível, agora inativo
  await scrollToText(page, prodPausar);
  await expectText(page, prodPausar);
});

test("pausado aparece na aba Inativos", async ({ page }) => {
  await bootAndLogin(page, ownerPausar.email, ownerPausar.password);
  await tapText(page, "Produtos");
  await waitForText(page, "Meu Catálogo", 40_000);

  // produto já está pausado pelo teste anterior; a aba Inativos deve listá-lo
  await pollTap(page, "Inativos", prodPausar);
  await expectText(page, prodPausar);
});

test("excluir remove o produto do catálogo", async ({ page }) => {
  await bootAndLogin(page, ownerExcluir.email, ownerExcluir.password);
  await tapText(page, "Produtos");
  await waitForText(page, "Meu Catálogo", 40_000);

  await scrollToText(page, prodExcluir);

  // exclui via diálogo de confirmação
  await pollTap(page, "Excluir", "Remover produto");
  await tapButton(page, "Remover");

  // catálogo fica vazio (produto removido de vez)
  await waitForText(page, "Nenhum produto nesta categoria", 20_000);
});
