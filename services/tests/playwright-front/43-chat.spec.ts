import { APIRequestContext, expect, Page, test } from "@playwright/test";
import {
  apiContext,
  getMyConversations,
  SeededUser,
  seedBooking,
  seedFullEstablishment,
} from "./_api";
import {
  bootAndLogin,
  expectText,
  pollTap,
  tapButton,
  textFields,
  waitForText,
} from "./_helpers";

// C37 — Chat cliente ⇄ estabelecimento (REST + WebSocket Socket.IO via Nginx),
// dirigindo a UI real do Flutter Web contra o backend real (sem mocks).
//
// O chat é aberto a partir de um agendamento CONFIRMADO: o cliente vê o botão
// "Mensagem" (Agenda → Próximos) e o estabelecimento "Responder cliente"
// (Agenda do estabelecimento). A lista de conversas fica em Perfil → "Mensagens".

let api: APIRequestContext;
let owner: SeededUser;
let estab: { id: string; name: string };

test.beforeAll(async () => {
  api = await apiContext();
  const seed = await seedFullEstablishment(api);
  owner = seed.owner;
  estab = seed.estab;
});

test.afterAll(async () => {
  await api.dispose();
});

// Abre o chat do cliente a partir do agendamento confirmado (Agenda → Próximos).
async function clienteAbreChat(
  page: Page,
  cliente: SeededUser,
  petName: string,
): Promise<void> {
  await bootAndLogin(page, cliente.email, cliente.password);
  await tapButton(page, "Agenda", true);
  await waitForText(page, petName, 40_000);
  await tapButton(page, "Mensagem", true);
  // Tela de chat: o campo de input ("Digite uma mensagem...") confirma que abriu.
  await expect
    .poll(async () => textFields(page).count(), { timeout: 30_000 })
    .toBeGreaterThan(0);
}

// Envia uma mensagem pelo campo de input (Enter dispara onSubmitted → sendMessage).
async function enviarMensagem(page: Page, texto: string): Promise<void> {
  const campo = textFields(page).first();
  await campo.waitFor({ state: "attached", timeout: 20_000 });
  await campo.click();
  await campo.fill(texto);
  await page.keyboard.press("Enter");
}

test("cliente abre chat de um agendamento confirmado e envia mensagem", async ({
  page,
}) => {
  const seed = await seedBooking(api, owner, estab, {
    finalStatus: "CONFIRMADO",
  });

  await clienteAbreChat(page, seed.cliente, seed.pet.name);

  const msg = `Oi! Confirmando o ${seed.serviceName} (e2e ${Date.now()})`;
  await enviarMensagem(page, msg);

  // A bolha da mensagem enviada aparece na conversa.
  await waitForText(page, msg, 30_000);

  // E a conversa passa a existir no backend para o ESTABELECIMENTO (o bug que
  // foi corrigido: a conversa é indexada pelo user id do dono, não pelo id da
  // entidade estabelecimento) — prova o fluxo ponta a ponta.
  await expect
    .poll(async () => (await getMyConversations(api, owner)).length, {
      timeout: 15_000,
    })
    .toBeGreaterThan(0);
});

test("conversa aparece na lista 'Mensagens' do cliente com a última mensagem", async ({
  page,
}) => {
  const seed = await seedBooking(api, owner, estab, {
    finalStatus: "CONFIRMADO",
  });

  await clienteAbreChat(page, seed.cliente, seed.pet.name);
  const msg = `Tudo certo para amanhã? (e2e ${Date.now()})`;
  await enviarMensagem(page, msg);
  await waitForText(page, msg, 30_000);

  // Volta (o botão de voltar do chat é um IconButton sem label → usa goBack do
  // browser, que o roteador do Flutter Web converte em Navigator.pop) e abre a
  // lista de conversas via Perfil → Mensagens.
  await page.goBack({ timeout: 10_000 }).catch(() => {});
  await tapButton(page, "Perfil", true);
  await tapButton(page, "Mensagens", true);

  // Tile da conversa: nome do parceiro (estabelecimento) + prévia da mensagem.
  await waitForText(page, estab.name, 30_000);
  await expectText(page, msg);
});

test("estabelecimento lê a conversa e responde; cliente recebe em tempo real", async ({
  browser,
}) => {
  const seed = await seedBooking(api, owner, estab, {
    finalStatus: "CONFIRMADO",
  });

  // Dois contextos independentes (sessões reais separadas).
  const ctxCliente = await browser.newContext({
    viewport: { width: 1100, height: 900 },
  });
  const ctxEstab = await browser.newContext({
    viewport: { width: 1100, height: 900 },
  });
  const pageCliente = await ctxCliente.newPage();
  const pageEstab = await ctxEstab.newPage();

  try {
    // 1) Cliente abre o chat (cria a conversa + entra na sala) e manda 1ª msg.
    await clienteAbreChat(pageCliente, seed.cliente, seed.pet.name);
    const msgCliente = `Olá, agendei um ${seed.serviceName} (e2e ${Date.now()})`;
    await enviarMensagem(pageCliente, msgCliente);
    await waitForText(pageCliente, msgCliente, 30_000);

    // 2) Estabelecimento entra: Perfil → Mensagens → abre a conversa do cliente.
    await bootAndLogin(pageEstab, owner.email, owner.password);
    await tapButton(pageEstab, "Perfil", true);
    await tapButton(pageEstab, "Mensagens", true);
    // O tile mostra o nome do cliente; abre o chat e confirma que o histórico
    // (via joinRoom) trouxe a mensagem do cliente — só funciona porque a
    // conversa é indexada pelo ownerId após o fix.
    await waitForText(pageEstab, seed.cliente.name, 30_000);
    await pollTap(pageEstab, seed.cliente.name, msgCliente);

    // 3) Estabelecimento responde.
    const msgEstab = `Perfeito! Pode trazer às 14h (e2e ${Date.now()})`;
    await enviarMensagem(pageEstab, msgEstab);
    await waitForText(pageEstab, msgEstab, 30_000);

    // 4) Cliente (ainda na tela do chat) recebe a resposta EM TEMPO REAL,
    //    sem recarregar — prova a entrega via WebSocket através do Nginx.
    await waitForText(pageCliente, msgEstab, 30_000);
  } finally {
    await ctxCliente.close();
    await ctxEstab.close();
  }
});
