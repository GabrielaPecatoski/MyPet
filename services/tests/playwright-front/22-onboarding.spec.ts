import { test } from "@playwright/test";
import { bootFlutter, expectText, tapButton, waitForText } from "./_helpers";

test("exibe o primeiro slide ao abrir o app sem autenticação", async ({
  page,
}) => {
  await bootFlutter(page, "/");
  await expectText(page, "O melhor para o seu pet");
  await expectText(page, "Próximo");
});
test("avança pelos 4 slides e chega na tela de perfis", async ({ page }) => {
  await bootFlutter(page, "/");
  await waitForText(page, "Próximo");
  await tapButton(page, "Próximo");
  await waitForText(page, "Agende em minutos");
  await tapButton(page, "Próximo");
  await waitForText(page, "Acompanhe em tempo real");
  await tapButton(page, "Próximo");
  await waitForText(page, "Profissionais verificados");
  await tapButton(page, "Começar agora");
  await waitForText(page, "Como você quer usar o app?");
});
test("botão Pular leva diretamente à tela de perfis", async ({ page }) => {
  await bootFlutter(page, "/");
  await waitForText(page, "Próximo");
  await tapButton(page, "Pular");
  await waitForText(page, "Como você quer usar o app?");
  await expectText(page, "Sou Tutor");
  await expectText(page, "Sou Veterinário");
  await expectText(page, "Sou Motorista");
  await expectText(page, "Estabelecimento");
});
