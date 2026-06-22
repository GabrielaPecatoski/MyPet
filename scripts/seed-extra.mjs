// Seed complementar: pets, agendamentos e pedidos para os clientes já criados
// pelo seed.mjs. Descobre estabelecimentos/serviços/produtos existentes via API.
//
// Docker:  SEED_BASE=http://127.0.0.1 node scripts/seed-extra.mjs
// Local:   node scripts/seed-extra.mjs
const BASE = process.env.SEED_BASE ?? "http://localhost:3000";

async function req(method, path, body, token) {
  const headers = {};
  if (body) headers["Content-Type"] = "application/json";
  if (token) headers["Authorization"] = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    data = text;
  }
  return { status: res.status, data };
}
const get = (p, t) => req("GET", p, undefined, t);
const post = (p, b, t) => req("POST", p, b, t);
const patch = (p, b, t) => req("PATCH", p, b, t);

function userIdFromJwt(token) {
  try {
    const payload = JSON.parse(
      Buffer.from(token.split(".")[1], "base64").toString("utf8"),
    );
    return payload.sub;
  } catch {
    return undefined;
  }
}

async function login(email, password) {
  const { status, data } = await post("/auth/login", { email, password });
  if (status !== 200 && status !== 201) {
    throw new Error(`Login falhou para ${email}: ${JSON.stringify(data)}`);
  }
  const id = data.user?.id ?? userIdFromJwt(data.accessToken);
  return { token: data.accessToken, id, name: data.user?.name ?? email };
}

const IMG = {
  cao1: "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=800&q=80",
  cao2: "https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=800&q=80",
  cao3: "https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=800&q=80",
  gato1: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800&q=80",
  gato2: "https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=800&q=80",
};

// Pets por cliente (e-mail -> lista de pets)
const PETS = {
  "maria@teste.com": [
    { name: "Thor", type: "Cachorro", breed: "Golden Retriever", age: 4, weight: 30, imageUrl: IMG.cao1, notes: "Muito dócil, adora água." },
    { name: "Mel", type: "Gato", breed: "Siamês", age: 2, weight: 4, imageUrl: IMG.gato1, notes: "Tímida com estranhos." },
  ],
  "joao@teste.com": [
    { name: "Rex", type: "Cachorro", breed: "Labrador", age: 3, weight: 28, imageUrl: IMG.cao2, notes: "Alérgico a frango." },
  ],
  "beatriz@teste.com": [
    { name: "Nina", type: "Cachorro", breed: "Poodle", age: 5, weight: 8, imageUrl: IMG.cao3, notes: "Faz tosa a cada 2 meses." },
    { name: "Frajola", type: "Gato", breed: "SRD", age: 1, weight: 3.5, imageUrl: IMG.gato2 },
  ],
  "rafael@teste.com": [
    { name: "Bidu", type: "Cachorro", breed: "Beagle", age: 6, weight: 14, imageUrl: IMG.cao1, notes: "Precisa de coleira antipulgas." },
  ],
};

function atHour(daysFromNow, hour) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  d.setHours(hour, 0, 0, 0);
  return d.toISOString();
}

async function main() {
  console.log("\n🌱 Seed complementar (pets, agendamentos, pedidos)...\n");

  // 1) Clientes
  const emails = Object.keys(PETS);
  const clients = {};
  for (const email of emails) {
    clients[email] = await login(email, "Senha@123");
    console.log(`  ✓ login: ${email}`);
  }

  // 2) Pets
  console.log("\n🐶 Pets");
  const petsByEmail = {};
  for (const email of emails) {
    const c = clients[email];
    petsByEmail[email] = [];
    // evita duplicar: lê os pets já existentes
    const { data: existentes } = await get(`/pets/user/${c.id}`, c.token);
    const jaTem = new Set(
      (Array.isArray(existentes) ? existentes : []).map((p) => p.name),
    );
    for (const pet of PETS[email]) {
      if (jaTem.has(pet.name)) {
        const found = existentes.find((p) => p.name === pet.name);
        petsByEmail[email].push(found);
        console.log(`    ~ ${pet.name} já existe (${email})`);
        continue;
      }
      const { status, data } = await post("/pets", pet, c.token);
      if (status === 200 || status === 201) {
        petsByEmail[email].push(data);
        console.log(`    + ${pet.name} (${pet.breed}) — ${email}`);
      } else {
        console.log(`    ! falha pet ${pet.name}: ${JSON.stringify(data)}`);
      }
    }
  }

  // 3) Descobre estabelecimentos + serviços + produtos
  console.log("\n🔎 Descobrindo estabelecimentos/serviços/produtos");
  const admin = await login("admin@mypet.com", "Admin@123");
  const { data: estabs } = await get("/establishments");
  const lista = (Array.isArray(estabs) ? estabs : []).filter((e) =>
    String(e.city ?? "").toLowerCase().includes("toledo"),
  );
  for (const e of lista) {
    const { data: svcs } = await get(`/establishments/${e.id}/services`);
    e._services = Array.isArray(svcs) ? svcs : [];
  }
  const { data: prods } = await get("/marketplace/products");
  const produtos = Array.isArray(prods) ? prods : [];
  console.log(
    `  ✓ ${lista.length} estabelecimento(s) em Toledo, ${produtos.length} produto(s)`,
  );

  // 4) Agendamentos — mistura de status
  console.log("\n📅 Agendamentos");
  const planos = [
    { email: "maria@teste.com", petIdx: 0, estabIdx: 0, svcIdx: 0, when: atHour(3, 10), action: "pay" },
    { email: "maria@teste.com", petIdx: 1, estabIdx: 1, svcIdx: 0, when: atHour(-5, 14), action: "complete" },
    { email: "joao@teste.com", petIdx: 0, estabIdx: 0, svcIdx: 2, when: atHour(2, 9), action: "none" },
    { email: "beatriz@teste.com", petIdx: 0, estabIdx: 2, svcIdx: 0, when: atHour(1, 11), action: "confirm" },
    { email: "beatriz@teste.com", petIdx: 1, estabIdx: 1, svcIdx: 1, when: atHour(-10, 16), action: "complete" },
    { email: "rafael@teste.com", petIdx: 0, estabIdx: 0, svcIdx: 1, when: atHour(4, 15), action: "pay" },
  ];
  for (const p of planos) {
    const c = clients[p.email];
    const pet = petsByEmail[p.email]?.[p.petIdx];
    const estab = lista[p.estabIdx];
    const svc = estab?._services?.[p.svcIdx];
    if (!pet || !estab || !svc) {
      console.log(`    ! pulado (faltam dados): ${p.email}`);
      continue;
    }
    const { status, data } = await post(
      "/bookings",
      {
        petId: pet.id,
        petName: pet.name,
        petBreed: pet.breed,
        petAge: pet.age,
        petPhotoUrl: pet.imageUrl,
        serviceName: svc.name,
        establishmentId: estab.id,
        establishmentName: estab.name,
        establishmentAddress: estab.address,
        scheduledAt: p.when,
        price: svc.price ?? 0,
        userName: c.name,
      },
      c.token,
    );
    if (status !== 200 && status !== 201) {
      console.log(`    ! falha booking ${pet.name}: ${JSON.stringify(data)}`);
      continue;
    }
    let label = "AGUARDANDO_PAGAMENTO";
    if (p.action === "pay" || p.action === "confirm" || p.action === "complete") {
      await patch(`/bookings/${data.id}/pay`, { method: "PIX" }, c.token);
      label = "PENDENTE (pago)";
    }
    if (p.action === "confirm") {
      await patch(`/bookings/${data.id}/status`, { status: "CONFIRMADO" }, c.token);
      label = "CONFIRMADO";
    }
    if (p.action === "complete") {
      await patch(`/bookings/${data.id}/complete`, {}, c.token);
      label = "CONCLUIDO";
    }
    console.log(`    + ${pet.name} → ${svc.name} @ ${estab.name} [${label}]`);
  }

  // 5) Pedidos — carrinho + checkout
  console.log("\n🛒 Pedidos (loja)");
  const comprasPlano = [
    { email: "maria@teste.com", itens: [0, 1] },
    { email: "joao@teste.com", itens: [2] },
    { email: "beatriz@teste.com", itens: [3, 4] },
    { email: "rafael@teste.com", itens: [5] },
  ];
  for (const compra of comprasPlano) {
    const c = clients[compra.email];
    let adicionou = 0;
    for (const idx of compra.itens) {
      const prod = produtos[idx % produtos.length];
      if (!prod) continue;
      const { status } = await post(
        `/marketplace/cart/${c.id}`,
        { productId: prod.id, quantity: 1 + (idx % 2) },
        c.token,
      );
      if (status === 200 || status === 201) adicionou++;
    }
    if (adicionou === 0) {
      console.log(`    ~ ${compra.email}: nada para comprar`);
      continue;
    }
    const { status, data } = await post(
      `/marketplace/orders/${c.id}`,
      undefined,
      c.token,
    );
    if (status === 200 || status === 201) {
      const total = data?.total ?? data?.totalAmount ?? "?";
      console.log(`    + pedido de ${compra.email}: ${adicionou} item(ns), total R$ ${total}`);
    } else {
      console.log(`    ! checkout falhou (${compra.email}): ${JSON.stringify(data)}`);
    }
  }

  // 6) Reclamações
  console.log("\n📣 Reclamações");
  const byName = (n) => lista.find((e) => e.name === n);
  const reclamacoes = [
    {
      email: "maria@teste.com",
      estab: "Pet Shop Patinhas",
      subject: "Demora no atendimento",
      description:
        "Cheguei no horário agendado mas esperei mais de 40 minutos para o banho começar.",
      category: "atendimento",
    },
    {
      email: "joao@teste.com",
      estab: "Mundo Animal Pet",
      subject: "Produto em falta após a compra",
      description:
        "Finalizei o pedido e depois fui avisado que o item estava sem estoque.",
      category: "produto",
    },
    {
      email: "beatriz@teste.com",
      estab: "Clínica VetCare",
      subject: "Cobrança duplicada",
      description:
        "Fui cobrada duas vezes pela mesma consulta no cartão. Preciso do estorno.",
      category: "pagamento",
    },
    {
      email: "rafael@teste.com",
      estab: "Pet Shop Patinhas",
      subject: "Tosa fora do combinado",
      description:
        "Pedi tosa higiênica e o pet voltou com tosa completa, bem diferente do combinado.",
      category: "servico",
    },
  ];
  for (const r of reclamacoes) {
    const c = clients[r.email];
    const estab = byName(r.estab);
    if (!c || !estab) {
      console.log(`    ! pulado (faltam dados): ${r.subject}`);
      continue;
    }
    // dedupe por assunto
    const { data: existentes } = await get(
      `/reviews/complaints/establishment/${estab.id}`,
      c.token,
    );
    const jaTem = (Array.isArray(existentes) ? existentes : []).some(
      (x) => x.subject === r.subject && x.userId === c.id,
    );
    if (jaTem) {
      console.log(`    ~ já existe: "${r.subject}"`);
      continue;
    }
    const { status, data } = await post(
      "/reviews/complaints",
      {
        establishmentId: estab.id,
        subject: r.subject,
        description: r.description,
        category: r.category,
      },
      c.token,
    );
    if (status === 200 || status === 201) {
      console.log(`    + "${r.subject}" → ${r.estab} (${r.email})`);
    } else {
      console.log(`    ! falha: ${r.subject} — ${JSON.stringify(data)}`);
    }
  }

  console.log("\n✅ Seed complementar concluído!\n");
}

main().catch((e) => {
  console.error("❌ Erro no seed extra:", e.message);
  process.exit(1);
});
