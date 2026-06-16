// Gateway local (npm run start) por padrão; use SEED_BASE=http://127.0.0.1
// para semear contra a stack Docker (via Nginx).
const BASE = process.env.SEED_BASE ?? "http://localhost:3000";

async function post(path, body, token) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
  const text = await res.text();
  try {
    return { status: res.status, data: JSON.parse(text) };
  } catch {
    return { status: res.status, data: text };
  }
}

async function get(path, token) {
  const headers = {};
  if (token) headers["Authorization"] = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, { headers });
  const text = await res.text();
  try {
    return { status: res.status, data: JSON.parse(text) };
  } catch {
    return { status: res.status, data: text };
  }
}

const FAQS = [
  {
    question: "Como agendar um serviço?",
    answer:
      "Abra o estabelecimento desejado, toque em Agendar Serviço, escolha o pet, o serviço e um horário disponível.",
    category: "Agendamento",
  },
  {
    question: "Posso cancelar ou remarcar um agendamento?",
    answer:
      "Sim. Na aba Agenda, abra o agendamento e toque em Cancelar. Pagamentos retidos são estornados automaticamente.",
    category: "Agendamento",
  },
  {
    question: "Como acompanho meu pedido na loja?",
    answer:
      "Na Loja, vá em Pedidos para ver o status e a barra de progresso da entrega em tempo real.",
    category: "Loja",
  },
  {
    question: "Quais formas de pagamento são aceitas?",
    answer: "PIX, cartão de crédito e débito, boleto e dinheiro na retirada.",
    category: "Pagamento",
  },
  {
    question: "Como me torno um estabelecimento parceiro?",
    answer:
      "Cadastre-se como Vendedor, crie o seu estabelecimento no perfil e comece a oferecer produtos e serviços.",
    category: "Conta",
  },
];

async function seedFaqs(adminToken) {
  const { data: existentes } = await get("/faq");
  const jaTem = new Set(
    (Array.isArray(existentes) ? existentes : []).map((f) => f.question),
  );
  let novas = 0;
  for (const faq of FAQS) {
    if (jaTem.has(faq.question)) continue;
    const { status } = await post("/faq/admin", faq, adminToken);
    if (status === 201 || status === 200) {
      console.log(`    + FAQ: ${faq.question}`);
      novas++;
    }
  }
  console.log(`  ✓ FAQs semeadas: ${novas} nova(s), ${jaTem.size} já existiam`);
}

async function register(user) {
  const { status, data } = await post("/auth/register", user);
  if (status === 201 || status === 200) {
    console.log(`  ✓ ${user.role} criado: ${user.email}`);
    return data;
  }
  if (status === 409) {
    console.log(`  ~ ${user.role} já existe: ${user.email} — fazendo login`);
    const { status: ls, data: ld } = await post("/auth/login", {
      email: user.email,
      password: user.password,
    });
    if (ls === 200) return ld;
    throw new Error(`Login falhou para ${user.email}: ${JSON.stringify(ld)}`);
  }
  throw new Error(
    `Registro falhou para ${user.email}: ${JSON.stringify(data)}`,
  );
}

async function createEstab(token, body) {
  const { status, data } = await post("/establishments", body, token);
  if (status === 201 || status === 200) {
    console.log(`  ✓ Estabelecimento criado: ${body.name} (id: ${data.id})`);
    return data;
  }
  throw new Error(
    `Estabelecimento falhou [${status}]: ${JSON.stringify(data)}`,
  );
}

async function addService(token, estabId, svc) {
  const { status, data } = await post(
    `/establishments/${estabId}/services`,
    svc,
    token,
  );
  if (status === 201 || status === 200) {
    console.log(`    + ${svc.name}`);
    return data;
  }
  throw new Error(`Serviço falhou [${status}]: ${JSON.stringify(data)}`);
}

async function main() {
  console.log("\n🌱 Iniciando seed...\n");

  console.log("👤 Admin");
  const admin = await register({
    name: "Administrador",
    email: "admin@mypet.com",
    password: "Admin@123",
    phone: "(11) 99999-0001",
    cpf: "000.000.000-01",
    role: "ADMIN",
  });

  console.log("\n❓ FAQ");
  await seedFaqs(admin.accessToken);

  console.log("\n🏪 Vendedor 1 — Pet Shop Patinhas");
  const v1 = await register({
    name: "Carlos Mendes",
    email: "carlos@petshop.com",
    password: "Senha@123",
    phone: "(11) 98888-0001",
    cpf: "111.111.111-01",
    role: "VENDEDOR",
  });
  const e1 = await createEstab(v1.accessToken, {
    name: "Pet Shop Patinhas",
    description: "Cuidado e amor para o seu pet.",
    address: "Rua das Flores, 123",
    city: "São Paulo",
    phone: "(11) 3333-0001",
    type: "PET_SHOP",
  });
  await addService(v1.accessToken, e1.id, {
    name: "Banho",
    price: 60,
    durationMinutes: 60,
    description: "Banho completo com shampoo especial",
  });
  await addService(v1.accessToken, e1.id, {
    name: "Tosa",
    price: 80,
    durationMinutes: 90,
    description: "Tosa higiênica ou completa",
  });
  await addService(v1.accessToken, e1.id, {
    name: "Banho + Tosa",
    price: 120,
    durationMinutes: 120,
    description: "Pacote completo banho e tosa",
  });

  console.log("\n🏥 Vendedor 2 — Clínica VetCare");
  const v2 = await register({
    name: "Dra. Ana Lima",
    email: "ana@vetcare.com",
    password: "Senha@123",
    phone: "(11) 98888-0002",
    cpf: "222.222.222-02",
    role: "VENDEDOR",
  });
  const e2 = await createEstab(v2.accessToken, {
    name: "Clínica VetCare",
    description: "Saúde e bem-estar animal com profissionais especializados.",
    address: "Av. Paulista, 456",
    city: "São Paulo",
    phone: "(11) 3333-0002",
    type: "VET_CLINIC",
  });
  await addService(v2.accessToken, e2.id, {
    name: "Consulta Clínica",
    price: 150,
    durationMinutes: 30,
    description: "Consulta veterinária geral",
  });
  await addService(v2.accessToken, e2.id, {
    name: "Vacinação",
    price: 80,
    durationMinutes: 20,
    description: "Aplicação de vacinas",
  });
  await addService(v2.accessToken, e2.id, {
    name: "Exame de Sangue",
    price: 120,
    durationMinutes: 15,
    description: "Hemograma completo",
  });

  console.log("\n🐾 Vendedor 3 — Mundo Animal");
  const v3 = await register({
    name: "Fernanda Costa",
    email: "fernanda@mundoanimal.com",
    password: "Senha@123",
    phone: "(11) 98888-0003",
    cpf: "333.333.333-03",
    role: "VENDEDOR",
  });
  const e3 = await createEstab(v3.accessToken, {
    name: "Mundo Animal Pet",
    description: "Tudo para o seu bichinho em um só lugar.",
    address: "Rua Augusta, 789",
    city: "São Paulo",
    phone: "(11) 3333-0003",
    type: "PET_SHOP",
  });
  await addService(v3.accessToken, e3.id, {
    name: "Banho Pequeno Porte",
    price: 45,
    durationMinutes: 45,
    description: "Para pets até 8kg",
  });
  await addService(v3.accessToken, e3.id, {
    name: "Banho Grande Porte",
    price: 90,
    durationMinutes: 90,
    description: "Para pets acima de 8kg",
  });
  await addService(v3.accessToken, e3.id, {
    name: "Hospedagem Diária",
    price: 80,
    durationMinutes: 1440,
    description: "Hospedagem por dia",
  });

  console.log("\n👥 Cliente de teste");
  await register({
    name: "Maria Souza",
    email: "maria@teste.com",
    password: "Senha@123",
    phone: "(11) 97777-0001",
    cpf: "444.444.444-04",
    role: "CLIENTE",
  });

  console.log("\n✅ Seed concluído!\n");
  console.log("Credenciais:");
  console.log("  Admin:    admin@mypet.com        / Admin@123");
  console.log("  Vendedor: carlos@petshop.com     / Senha@123");
  console.log("  Cliente:  maria@teste.com        / Senha@123");
  console.log("");
}

main().catch((e) => {
  console.error("❌ Erro no seed:", e.message);
  process.exit(1);
});
