// Gateway local (npm run start) por padrão; use SEED_BASE=http://127.0.0.1
// para semear contra a stack Docker (via Nginx).
//
// Popula: admin, FAQs, estabelecimentos em Toledo-PR (com fotos da internet),
// serviços, produtos (com fotos) e clientes que deixam avaliações (notas).
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

// Fotos hospedadas no Unsplash (hotlink direto, verificadas 200 OK).
const IMG = {
  // estabelecimentos / cenas
  petshopLoja:
    "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=800&q=80",
  vetClinica:
    "https://images.unsplash.com/photo-1628009368231-7bb7cfcb0def?w=800&q=80",
  vetExame:
    "https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800&q=80",
  banhoTosa:
    "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800&q=80",
  banhoTosa2:
    "https://images.unsplash.com/photo-1591946614720-90a587da4a36?w=800&q=80",
  cachorroFeliz:
    "https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=800&q=80",
  gatoFeliz:
    "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800&q=80",
  // produtos
  racaoCao:
    "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=800&q=80",
  racaoGato:
    "https://images.unsplash.com/photo-1606214174585-fe31582dc6ee?w=800&q=80",
  petisco:
    "https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=800&q=80",
  shampoo:
    "https://images.unsplash.com/photo-1606856110002-d0991ce78250?w=800&q=80",
  brinquedo:
    "https://images.unsplash.com/photo-1535930891776-0c2dfb7fda1a?w=800&q=80",
  acessorio:
    "https://images.unsplash.com/photo-1574158622682-e40e69881006?w=800&q=80",
};

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
    console.log(`    + serviço: ${svc.name}`);
    return data;
  }
  throw new Error(`Serviço falhou [${status}]: ${JSON.stringify(data)}`);
}

async function addProduct(token, estabId, prod) {
  const { status, data } = await post(
    "/marketplace/products",
    { ...prod, establishmentId: estabId },
    token,
  );
  if (status === 201 || status === 200) {
    console.log(`    + produto: ${prod.name}`);
    return data;
  }
  throw new Error(`Produto falhou [${status}]: ${JSON.stringify(data)}`);
}

async function addReview(token, estabId, review) {
  const { status, data } = await post(
    `/reviews/establishment/${estabId}`,
    review,
    token,
  );
  if (status === 201 || status === 200) {
    console.log(`    ⭐ ${review.rating} — "${review.comment}"`);
    return data;
  }
  throw new Error(`Avaliação falhou [${status}]: ${JSON.stringify(data)}`);
}

async function main() {
  console.log("\n🌱 Iniciando seed (Toledo-PR)...\n");

  console.log("👤 Admin");
  const admin = await register({
    name: "Administrador",
    email: "admin@mypet.com",
    password: "Admin@123",
    phone: "(45) 99999-0001",
    cpf: "000.000.000-01",
    role: "ADMIN",
  });

  console.log("\n❓ FAQ");
  await seedFaqs(admin.accessToken);

  // ───────────────────────── Estabelecimento 1 ─────────────────────────
  console.log("\n🏪 Vendedor 1 — Pet Shop Patinhas (Toledo-PR)");
  const v1 = await register({
    name: "Carlos Mendes",
    email: "carlos@petshop.com",
    password: "Senha@123",
    phone: "(45) 98888-0001",
    cpf: "111.111.111-01",
    role: "VENDEDOR",
  });
  const e1 = await createEstab(v1.accessToken, {
    name: "Pet Shop Patinhas",
    description: "Cuidado e amor para o seu pet no coração de Toledo.",
    address: "Rua Sete de Setembro, 1234 - Centro",
    city: "Toledo - PR",
    phone: "(45) 3333-0001",
    type: "PET_SHOP",
    lat: -24.7136,
    lng: -53.743,
    imageUrl: IMG.petshopLoja,
  });
  await addService(v1.accessToken, e1.id, {
    name: "Banho",
    price: 60,
    durationMinutes: 60,
    description: "Banho completo com shampoo especial",
    categoria: "banho",
    imagemUrl: IMG.banhoTosa,
  });
  await addService(v1.accessToken, e1.id, {
    name: "Tosa",
    price: 80,
    durationMinutes: 90,
    description: "Tosa higiênica ou completa",
    categoria: "tosa",
    imagemUrl: IMG.banhoTosa2,
  });
  await addService(v1.accessToken, e1.id, {
    name: "Banho + Tosa",
    price: 120,
    durationMinutes: 120,
    description: "Pacote completo banho e tosa",
    categoria: "banho",
    imagemUrl: IMG.banhoTosa,
  });
  await addProduct(v1.accessToken, e1.id, {
    name: "Ração Premium Cães Adultos 15kg",
    brand: "GoldClass",
    price: 189.9,
    unit: "saco",
    category: "Alimentação",
    description: "Ração super premium para cães adultos de todas as raças.",
    stock: 40,
    imageUrl: IMG.racaoCao,
  });
  await addProduct(v1.accessToken, e1.id, {
    name: "Petisco Bifinho Carne 500g",
    brand: "DogLand",
    price: 24.9,
    unit: "pacote",
    category: "Petiscos",
    description: "Bifinhos macios sabor carne, ideais para o adestramento.",
    stock: 120,
    imageUrl: IMG.petisco,
  });
  await addProduct(v1.accessToken, e1.id, {
    name: "Brinquedo Mordedor Resistente",
    brand: "PetFun",
    price: 34.9,
    unit: "unidade",
    category: "Brinquedos",
    description: "Mordedor de borracha atóxica para cães de grande porte.",
    stock: 60,
    imageUrl: IMG.brinquedo,
  });

  // ───────────────────────── Estabelecimento 2 ─────────────────────────
  console.log("\n🏥 Vendedor 2 — Clínica VetCare (Toledo-PR)");
  const v2 = await register({
    name: "Dra. Ana Lima",
    email: "ana@vetcare.com",
    password: "Senha@123",
    phone: "(45) 98888-0002",
    cpf: "222.222.222-02",
    role: "VENDEDOR",
  });
  const e2 = await createEstab(v2.accessToken, {
    name: "Clínica VetCare",
    description: "Saúde e bem-estar animal com profissionais especializados.",
    address: "Avenida Maripá, 2050 - Jardim La Salle",
    city: "Toledo - PR",
    phone: "(45) 3333-0002",
    type: "VETERINARIA",
    lat: -24.7201,
    lng: -53.7398,
    imageUrl: IMG.vetClinica,
    crmv: "PR-12345",
    atendeEmergencia: true,
    atendimento24h: false,
  });
  await addService(v2.accessToken, e2.id, {
    name: "Consulta Clínica",
    price: 150,
    durationMinutes: 30,
    description: "Consulta veterinária geral",
    categoria: "consulta_veterinaria",
    imagemUrl: IMG.vetExame,
  });
  await addService(v2.accessToken, e2.id, {
    name: "Vacinação",
    price: 80,
    durationMinutes: 20,
    description: "Aplicação de vacinas",
    categoria: "vacinacao",
    imagemUrl: IMG.vetExame,
  });
  await addService(v2.accessToken, e2.id, {
    name: "Exame de Sangue",
    price: 120,
    durationMinutes: 15,
    description: "Hemograma completo",
    categoria: "exames",
    imagemUrl: IMG.vetExame,
  });
  await addProduct(v2.accessToken, e2.id, {
    name: "Vermífugo Cães e Gatos",
    brand: "VetProtect",
    price: 42.5,
    unit: "caixa",
    category: "Medicamentos",
    description: "Vermífugo de amplo espectro, 4 comprimidos.",
    stock: 80,
    imageUrl: IMG.shampoo,
  });
  await addProduct(v2.accessToken, e2.id, {
    name: "Ração Veterinária Renal Gatos 1,5kg",
    brand: "VetCare Nutri",
    price: 98.0,
    unit: "saco",
    category: "Alimentação",
    description: "Dieta terapêutica para gatos com problemas renais.",
    stock: 25,
    imageUrl: IMG.racaoGato,
  });

  // ───────────────────────── Estabelecimento 3 ─────────────────────────
  console.log("\n🐾 Vendedor 3 — Mundo Animal (Toledo-PR)");
  const v3 = await register({
    name: "Fernanda Costa",
    email: "fernanda@mundoanimal.com",
    password: "Senha@123",
    phone: "(45) 98888-0003",
    cpf: "333.333.333-03",
    role: "VENDEDOR",
  });
  const e3 = await createEstab(v3.accessToken, {
    name: "Mundo Animal Pet",
    description: "Tudo para o seu bichinho em um só lugar.",
    address: "Rua Barão do Rio Branco, 870 - Centro",
    city: "Toledo - PR",
    phone: "(45) 3333-0003",
    type: "HIBRIDO",
    lat: -24.7155,
    lng: -53.7461,
    imageUrl: IMG.cachorroFeliz,
  });
  await addService(v3.accessToken, e3.id, {
    name: "Banho Pequeno Porte",
    price: 45,
    durationMinutes: 45,
    description: "Para pets até 8kg",
    categoria: "banho",
    imagemUrl: IMG.banhoTosa2,
  });
  await addService(v3.accessToken, e3.id, {
    name: "Banho Grande Porte",
    price: 90,
    durationMinutes: 90,
    description: "Para pets acima de 8kg",
    categoria: "banho",
    imagemUrl: IMG.banhoTosa,
  });
  await addService(v3.accessToken, e3.id, {
    name: "Hospedagem Diária",
    price: 80,
    durationMinutes: 1440,
    description: "Hospedagem por dia",
    categoria: "outros",
    imagemUrl: IMG.cachorroFeliz,
  });
  await addProduct(v3.accessToken, e3.id, {
    name: "Coleira Ajustável com Guia",
    brand: "PetStyle",
    price: 39.9,
    unit: "unidade",
    category: "Acessórios",
    description: "Coleira em nylon resistente com guia de 1,2m.",
    stock: 90,
    imageUrl: IMG.acessorio,
  });
  await addProduct(v3.accessToken, e3.id, {
    name: "Areia Higiênica para Gatos 4kg",
    brand: "CatClean",
    price: 29.9,
    unit: "saco",
    category: "Higiene",
    description: "Areia granulada com alto poder de absorção e controle de odor.",
    stock: 70,
    imageUrl: IMG.gatoFeliz,
  });
  await addProduct(v3.accessToken, e3.id, {
    name: "Ração Filhotes Cães 10kg",
    brand: "GoldClass",
    price: 159.9,
    unit: "saco",
    category: "Alimentação",
    description: "Ração premium para filhotes em fase de crescimento.",
    stock: 35,
    imageUrl: IMG.racaoCao,
  });

  // ───────────────────────── Clientes ─────────────────────────
  console.log("\n👥 Clientes");
  const clientes = await Promise.all(
    [
      {
        name: "Maria Souza",
        email: "maria@teste.com",
        phone: "(45) 97777-0001",
        cpf: "444.444.444-04",
      },
      {
        name: "João Pereira",
        email: "joao@teste.com",
        phone: "(45) 97777-0002",
        cpf: "555.555.555-05",
      },
      {
        name: "Beatriz Almeida",
        email: "beatriz@teste.com",
        phone: "(45) 97777-0003",
        cpf: "666.666.666-06",
      },
      {
        name: "Rafael Oliveira",
        email: "rafael@teste.com",
        phone: "(45) 97777-0004",
        cpf: "777.777.777-07",
      },
    ].map((c) =>
      register({ ...c, password: "Senha@123", role: "CLIENTE" }),
    ),
  );

  // ───────────────────────── Avaliações (notas) ─────────────────────────
  console.log("\n⭐ Avaliações");
  const reviewsByEstab = [
    {
      estab: e1,
      label: "Pet Shop Patinhas",
      reviews: [
        { rating: 5, comment: "Meu cachorro saiu lindo do banho e tosa! Atendimento nota 10." },
        { rating: 4, comment: "Bom atendimento, só demorou um pouquinho para chamar." },
        { rating: 5, comment: "Equipe super carinhosa com os pets. Recomendo!" },
        { rating: 3, comment: "Serviço ok, mas achei o preço da tosa um pouco salgado." },
      ],
    },
    {
      estab: e2,
      label: "Clínica VetCare",
      reviews: [
        { rating: 5, comment: "A Dra. Ana é excelente! Salvou meu gatinho numa emergência." },
        { rating: 5, comment: "Clínica limpa, organizada e profissionais atenciosos." },
        { rating: 4, comment: "Consulta muito boa, explicaram tudo com calma." },
        { rating: 5, comment: "Melhor veterinária de Toledo, sem dúvida." },
      ],
    },
    {
      estab: e3,
      label: "Mundo Animal Pet",
      reviews: [
        { rating: 4, comment: "Boa variedade de produtos e preços justos." },
        { rating: 5, comment: "A hospedagem é ótima, meu pet adorou ficar lá." },
        { rating: 3, comment: "Faltou o produto que eu queria em estoque." },
        { rating: 4, comment: "Atendimento simpático e loja bem completa." },
      ],
    },
  ];

  for (const { estab, label, reviews } of reviewsByEstab) {
    console.log(`  ${label}:`);
    for (let i = 0; i < reviews.length; i++) {
      const cliente = clientes[i % clientes.length];
      await addReview(cliente.accessToken, estab.id, reviews[i]);
    }
    const { data: stats } = await get(`/reviews/establishment/${estab.id}/stats`);
    if (stats && typeof stats.average !== "undefined") {
      console.log(
        `    média: ${stats.average} (${stats.count} avaliações)`,
      );
    }
  }

  console.log("\n✅ Seed concluído!\n");
  console.log("Credenciais:");
  console.log("  Admin:    admin@mypet.com        / Admin@123");
  console.log("  Vendedor: carlos@petshop.com     / Senha@123");
  console.log("  Vendedor: ana@vetcare.com        / Senha@123");
  console.log("  Vendedor: fernanda@mundoanimal.com / Senha@123");
  console.log("  Cliente:  maria@teste.com        / Senha@123");
  console.log("  Cliente:  joao@teste.com         / Senha@123");
  console.log("");
}

main().catch((e) => {
  console.error("❌ Erro no seed:", e.message);
  process.exit(1);
});
