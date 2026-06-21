/**
 * E2E tests for the Chat Service.
 *
 * Prerequisites:
 *   - Chat service running on CHAT_URL (default: http://localhost:3009)
 *   - Env var DATABASE_URL and JWT_SECRET set (or defaults used)
 *
 * Run:
 *   node test/chat.e2e.js
 */

"use strict";

const { io } = require("socket.io-client");
const jwt = require("jsonwebtoken");
const http = require("http");

const JWT_SECRET =
  process.env.JWT_SECRET || "mypet_super_secret_change_in_production";
const CHAT_URL = process.env.CHAT_URL || "http://localhost:3009";

// ─── Test helpers ─────────────────────────────────────────────────────────────

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✓ ${message}`);
    passed++;
  } else {
    console.error(`  ✗ FAIL: ${message}`);
    failed++;
  }
}

function wait(ms) {
  return new Promise((res) => setTimeout(res, ms));
}

function makeToken(sub, role) {
  return jwt.sign(
    { sub, role, permissions: ["chat:read", "chat:write"] },
    JWT_SECRET,
    { expiresIn: "1h" },
  );
}

function restPost(path, body, token) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const parsed = new URL(CHAT_URL + path);
    const options = {
      hostname: parsed.hostname,
      port: parseInt(parsed.port || "80"),
      path: parsed.pathname,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(data),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    };
    const req = http.request(options, (res) => {
      let raw = "";
      res.on("data", (c) => (raw += c));
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(raw));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${raw}`));
        }
      });
    });
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

function connectSocket(token) {
  const socket = io(`${CHAT_URL}/chat`, {
    transports: ["websocket"],
    auth: { token },
    reconnection: false,
  });
  return new Promise((resolve, reject) => {
    socket.once("connect", () => resolve(socket));
    socket.once("connect_error", (e) => {
      socket.disconnect();
      reject(e);
    });
    setTimeout(() => {
      socket.disconnect();
      reject(new Error("Socket connect timeout"));
    }, 5000);
  });
}

function once(socket, event, timeoutMs = 3000) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(
      () => reject(new Error(`Timeout waiting for "${event}"`)),
      timeoutMs,
    );
    socket.once(event, (data) => {
      clearTimeout(t);
      resolve(data);
    });
  });
}

// ─── Test fixtures ─────────────────────────────────────────────────────────────

const clientId = `test-client-${Date.now()}`;
const vendorId = `test-vendor-${Date.now()}`;
const bookingId = `test-booking-${Date.now()}`;

const clientToken = makeToken(clientId, "CLIENTE");
const vendorToken = makeToken(vendorId, "VENDEDOR");

// ─── Tests ────────────────────────────────────────────────────────────────────

async function main() {
  console.log("\n╔══════════════════════════════════════╗");
  console.log("║   Chat Service — E2E Test Suite      ║");
  console.log("╚══════════════════════════════════════╝\n");
  console.log(`Target: ${CHAT_URL}\n`);

  // ── 1. REST: Create conversation ─────────────────────────────────────────

  console.log("1. REST — Criar conversa");
  let conversationId;
  try {
    const result = await restPost(
      "/v1/conversations",
      {
        bookingId,
        clientId,
        establishmentId: vendorId,
        clientName: "Test Client",
        establishmentName: "Test Vendor",
      },
      clientToken,
    );
    conversationId = result.conversation?.id;
    assert(!!conversationId, `Conversa criada (id=${conversationId})`);
    assert(result.created === true, "Retornou created=true");
  } catch (e) {
    console.error("  FATAL — não foi possível criar conversa:", e.message);
    process.exit(1);
  }

  // ── 2. REST: Idempotência ─────────────────────────────────────────────────

  console.log("\n2. REST — Idempotência (mesmo bookingId)");
  try {
    const result2 = await restPost(
      "/v1/conversations",
      { bookingId, clientId, establishmentId: vendorId },
      clientToken,
    );
    assert(
      result2.conversation?.id === conversationId,
      "Retornou a mesma conversa",
    );
    assert(result2.created === false, "Retornou created=false");
  } catch (e) {
    assert(false, `Idempotência falhou: ${e.message}`);
  }

  // ── 3. WebSocket: Conectar dois usuários ─────────────────────────────────

  console.log("\n3. WebSocket — Conexão");
  let clientSocket, vendorSocket;
  try {
    [clientSocket, vendorSocket] = await Promise.all([
      connectSocket(clientToken),
      connectSocket(vendorToken),
    ]);
    assert(clientSocket.connected, "Cliente conectado");
    assert(vendorSocket.connected, "Vendedor conectado");
  } catch (e) {
    console.error("  FATAL — erro de conexão WS:", e.message);
    process.exit(1);
  }

  // ── 4. WebSocket: Join room + histórico + partnerStatus ──────────────────

  console.log("\n4. WebSocket — Join room + histórico + partnerStatus");
  const historyClientP = once(clientSocket, "history");
  const historyVendorP = once(vendorSocket, "history");

  // Client joins first so vendor gets partnerStatus=online when joining
  clientSocket.emit("joinRoom", { conversationId });
  await wait(150);

  const partnerOnlineForVendor = once(vendorSocket, "partnerStatus");
  vendorSocket.emit("joinRoom", { conversationId });

  const [histClient, histVendor, vendorPresence] = await Promise.all([
    historyClientP,
    historyVendorP,
    partnerOnlineForVendor,
  ]);

  assert(Array.isArray(histClient?.messages), "Cliente recebeu histórico");
  assert(Array.isArray(histVendor?.messages), "Vendedor recebeu histórico");
  assert(
    vendorPresence?.userId === clientId,
    `partnerStatus.userId = clientId`,
  );
  assert(
    vendorPresence?.online === true,
    "partnerStatus.online = true ao entrar na sala",
  );

  // ── 5. WebSocket: Envio de mensagem (cliente → vendedor) ─────────────────

  console.log("\n5. WebSocket — Mensagem cliente → vendedor");
  const vendorMsgP = once(vendorSocket, "newMessage");
  const clientMsgP = once(clientSocket, "newMessage"); // broadcast includes sender

  clientSocket.emit("sendMessage", {
    conversationId,
    content: "Olá! Gostaria de saber sobre o serviço.",
  });

  const [vendorMsg, clientOwnMsg] = await Promise.all([vendorMsgP, clientMsgP]);

  assert(
    vendorMsg?.content === "Olá! Gostaria de saber sobre o serviço.",
    `Vendedor recebeu a mensagem correta`,
  );
  assert(vendorMsg?.senderId === clientId, "senderId = clientId");
  assert(vendorMsg?.senderRole === "CLIENTE", "senderRole = CLIENTE");
  assert(vendorMsg?.readAt === null || vendorMsg?.readAt == null, "readAt inicial = null");
  assert(clientOwnMsg?.id === vendorMsg?.id, "Remetente também recebeu via broadcast");

  // ── 6. WebSocket: Resposta do vendedor ───────────────────────────────────

  console.log("\n6. WebSocket — Mensagem vendedor → cliente");
  const clientReplyP = once(clientSocket, "newMessage");
  vendorSocket.emit("sendMessage", {
    conversationId,
    content: "Claro! Podemos agendar para amanhã.",
  });

  const clientReply = await clientReplyP;
  assert(
    clientReply?.content === "Claro! Podemos agendar para amanhã.",
    "Cliente recebeu resposta",
  );
  assert(clientReply?.senderRole === "VENDEDOR", "senderRole = VENDEDOR");

  // ── 7. WebSocket: Mark as read + readAt nos eventos ──────────────────────

  console.log("\n7. WebSocket — Marcar como lido (messagesRead com readAt)");
  const clientReadP = once(clientSocket, "messagesRead");
  const vendorReadP = once(vendorSocket, "messagesRead");

  vendorSocket.emit("markRead", { conversationId });

  const [clientReadEvt, vendorReadEvt] = await Promise.all([
    clientReadP,
    vendorReadP,
  ]);

  assert(
    clientReadEvt?.readerId === vendorId,
    `messagesRead.readerId = vendorId`,
  );
  assert(
    typeof clientReadEvt?.readAt === "string" && clientReadEvt.readAt.length > 0,
    `messagesRead.readAt é timestamp válido ("${clientReadEvt?.readAt}")`,
  );
  assert(
    clientReadEvt?.conversationId === conversationId,
    "messagesRead.conversationId correto",
  );
  assert(
    vendorReadEvt?.conversationId === conversationId,
    "Vendedor também recebeu o evento messagesRead",
  );

  // ── 8. WebSocket: Typing indicator ───────────────────────────────────────

  console.log("\n8. WebSocket — Indicador de digitação");
  const typingP = once(vendorSocket, "userTyping");
  clientSocket.emit("typing", { conversationId });
  const typingEvt = await typingP;

  assert(typingEvt?.userId === clientId, `userTyping.userId = clientId`);

  // ── 9. Segurança: enviar mensagem sem entrar na sala ──────────────────────

  console.log("\n9. Segurança — enviar sem joinRoom deve retornar erro");
  let badSocket;
  try {
    badSocket = await connectSocket(clientToken);
    const errP = once(badSocket, "error");
    badSocket.emit("sendMessage", {
      conversationId,
      content: "tentativa não autorizada",
    });
    const errEvt = await errP;
    assert(
      typeof errEvt?.message === "string",
      `Erro retornado: "${errEvt?.message}"`,
    );
  } catch (e) {
    assert(false, `Teste de segurança falhou: ${e.message}`);
  } finally {
    badSocket?.disconnect();
  }

  // ── 10. Segurança: token inválido deve ser rejeitado ─────────────────────

  console.log("\n10. Segurança — token inválido rejeitado na conexão");
  const invalidSocket = io(`${CHAT_URL}/chat`, {
    transports: ["websocket"],
    auth: { token: "token.invalido.mesmo" },
    reconnection: false,
  });
  const invalidResult = await new Promise((resolve) => {
    invalidSocket.once("connect", () => {
      // If it connects, the server failed to reject it
      invalidSocket.disconnect();
      resolve("connected"); // FAIL
    });
    invalidSocket.once("disconnect", () => resolve("disconnected"));
    invalidSocket.once("connect_error", () => resolve("connect_error"));
    setTimeout(() => {
      invalidSocket.disconnect();
      resolve("timeout");
    }, 3000);
  });
  assert(
    invalidResult !== "connected",
    `Conexão com token inválido recusada (resultado: ${invalidResult})`,
  );

  // ── 11. WebSocket: Leave room → partnerStatus offline ────────────────────

  console.log("\n11. WebSocket — Leave room → partnerStatus offline");
  const offlineP = once(vendorSocket, "partnerStatus");
  clientSocket.emit("leaveRoom", { conversationId });
  const offlineEvt = await offlineP;

  assert(offlineEvt?.userId === clientId, "partnerStatus.userId = clientId");
  assert(offlineEvt?.online === false, "partnerStatus.online = false");

  // ── 12. WebSocket: Disconnect → partnerStatus offline ────────────────────

  console.log("\n12. WebSocket — Disconnect limpa presença");

  // Client rejoins first, wait for history to avoid capturing the "online=true" partnerStatus
  const rejoinHistP = once(clientSocket, "history");
  clientSocket.emit("joinRoom", { conversationId });
  await rejoinHistP;
  await wait(200); // let the online=true partnerStatus flush before attaching listener

  // Now listen for the offline event triggered by disconnect
  const disconnectOfflineP = once(vendorSocket, "partnerStatus");
  clientSocket.disconnect();
  const disconnectOffline = await disconnectOfflineP;

  assert(
    disconnectOffline?.userId === clientId,
    "partnerStatus enviado ao desconectar",
  );
  assert(
    disconnectOffline?.online === false,
    "partnerStatus.online = false ao desconectar",
  );

  // Cleanup
  vendorSocket.disconnect();

  // ── Summary ───────────────────────────────────────────────────────────────

  console.log("\n══════════════════════════════════════════");
  const total = passed + failed;
  console.log(
    `  Total: ${total}  |  Passed: ${passed} ✓  |  Failed: ${failed} ${failed > 0 ? "✗" : ""}`,
  );
  console.log("══════════════════════════════════════════\n");
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("\nFATAL — teste abortou:", err);
  process.exit(1);
});
