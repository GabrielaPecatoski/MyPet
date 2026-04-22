import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const faqs = [
  // ── Agendamento ───────────────────────────────────────────────────
  {
    category: 'Agendamento',
    order: 1,
    question: 'Como faço para agendar um serviço?',
    answer:
      'Acesse a aba "Agenda" no menu inferior, escolha o estabelecimento desejado, selecione o serviço, escolha a data e horário disponível e confirme o agendamento. Você receberá uma notificação quando o estabelecimento confirmar.',
  },
  {
    category: 'Agendamento',
    order: 2,
    question: 'Posso cancelar um agendamento?',
    answer:
      'Sim. Acesse "Agenda", localize o agendamento e toque em "Cancelar agendamento". Cancelamentos feitos com menos de 2 horas de antecedência podem estar sujeitos à política de cancelamento do estabelecimento.',
  },
  {
    category: 'Agendamento',
    order: 3,
    question: 'Por que um horário aparece bloqueado?',
    answer:
      'Horários bloqueados já foram reservados por outro cliente ou foram definidos como indisponíveis pelo estabelecimento. Tente escolher outro horário ou outra data.',
  },
  {
    category: 'Agendamento',
    order: 4,
    question: 'Como acompanho meu serviço em tempo real?',
    answer:
      'Após o agendamento ser confirmado, acesse "Agenda" e toque em "Acompanhar serviço". Você verá o status atual e um mapa simulado da localização do estabelecimento.',
  },
  {
    category: 'Agendamento',
    order: 5,
    question: 'Recebi a confirmação mas o horário sumiu. O que fazer?',
    answer:
      'Tente puxar a lista para baixo para recarregar os dados. Se o problema persistir, entre em contato com o estabelecimento diretamente.',
  },
  // ── Pets ──────────────────────────────────────────────────────────
  {
    category: 'Pets',
    order: 1,
    question: 'Como cadastro meu pet?',
    answer:
      'Acesse a aba "Pets" no menu inferior e toque no botão "+". Preencha o nome, espécie, raça e idade do seu pet. Após salvar, o pet estará disponível para agendamentos.',
  },
  {
    category: 'Pets',
    order: 2,
    question: 'Quantos pets posso cadastrar?',
    answer:
      'Não há limite de pets por conta. Você pode cadastrar todos os seus animais e selecionar qual será atendido em cada agendamento.',
  },
  {
    category: 'Pets',
    order: 3,
    question: 'Posso cadastrar pets de espécies diferentes?',
    answer:
      'Sim! O MyPet aceita cães, gatos, pássaros, roedores e outras espécies. Basta informar a espécie no momento do cadastro.',
  },
  // ── Conta e Perfil ────────────────────────────────────────────────
  {
    category: 'Conta e Perfil',
    order: 1,
    question: 'Como altero meus dados cadastrais?',
    answer:
      'Acesse a aba "Perfil", toque em "Editar perfil" e atualize as informações desejadas. Salve ao finalizar.',
  },
  {
    category: 'Conta e Perfil',
    order: 2,
    question: 'Esqueci minha senha. O que faço?',
    answer:
      'Na tela de login, toque em "Esqueci minha senha" e siga as instruções enviadas para o seu e-mail cadastrado.',
  },
  {
    category: 'Conta e Perfil',
    order: 3,
    question: 'Como excluo minha conta?',
    answer:
      'Para exclusão de conta, entre em contato com o suporte pelo formulário de dúvidas ou pelo e-mail suporte@mypet.com.br. Sua solicitação será processada em até 5 dias úteis.',
  },
  {
    category: 'Conta e Perfil',
    order: 4,
    question: 'Como altero minha foto de perfil?',
    answer:
      'Acesse "Perfil" e toque na foto atual (ou no ícone de câmera). Selecione uma imagem da sua galeria para substituir.',
  },
  // ── Avaliações ────────────────────────────────────────────────────
  {
    category: 'Avaliações',
    order: 1,
    question: 'Como avalio um serviço realizado?',
    answer:
      'Após o serviço ser concluído, ele aparecerá no seu "Histórico". Toque em "Avaliar" no card do serviço, escolha de 1 a 5 estrelas e deixe um comentário opcional.',
  },
  {
    category: 'Avaliações',
    order: 2,
    question: 'Posso editar ou remover minha avaliação?',
    answer:
      'No momento, avaliações enviadas não podem ser editadas. Caso haja um problema com sua avaliação, entre em contato com o suporte.',
  },
  {
    category: 'Avaliações',
    order: 3,
    question: 'Por que minha avaliação não aparece no estabelecimento?',
    answer:
      'Avaliações passam por uma verificação automática antes de serem publicadas. Em até 24h sua avaliação estará visível.',
  },
  // ── Pagamentos ────────────────────────────────────────────────────
  {
    category: 'Pagamentos',
    order: 1,
    question: 'Quais formas de pagamento são aceitas?',
    answer:
      'As formas de pagamento variam por estabelecimento. Cada estabelecimento define os métodos aceitos (dinheiro, cartão, Pix, etc). Consulte as informações do estabelecimento antes de agendar.',
  },
  {
    category: 'Pagamentos',
    order: 2,
    question: 'O aplicativo cobra alguma taxa?',
    answer:
      'O MyPet é gratuito para clientes. O pagamento é feito diretamente ao estabelecimento pelos serviços contratados.',
  },
  {
    category: 'Pagamentos',
    order: 3,
    question: 'Como solicito reembolso?',
    answer:
      'Reembolsos são tratados diretamente com o estabelecimento. Em caso de não resolução, entre em contato com nosso suporte pelo formulário de dúvidas.',
  },
  // ── Estabelecimentos ──────────────────────────────────────────────
  {
    category: 'Estabelecimentos',
    order: 1,
    question: 'Como confirmo um agendamento recebido?',
    answer:
      'Acesse a aba "Agenda" no painel do estabelecimento. Agendamentos pendentes aparecem na aba "Pendentes". Toque no card e confirme ou recuse conforme sua disponibilidade.',
  },
  {
    category: 'Estabelecimentos',
    order: 2,
    question: 'Como bloqueio um horário na minha agenda?',
    answer:
      'Acesse "Agenda" e depois "Horários". Você pode definir os horários de atendimento e bloquear períodos específicos diretamente nas configurações de disponibilidade.',
  },
  {
    category: 'Estabelecimentos',
    order: 3,
    question: 'Como adiciono produtos ao meu catálogo?',
    answer:
      'Acesse a aba "Produtos" no menu do estabelecimento e toque no botão "+" ou "Novo Produto". Preencha nome, categoria, preço e estoque do produto.',
  },
  {
    category: 'Estabelecimentos',
    order: 4,
    question: 'Como vejo meu faturamento e estatísticas?',
    answer:
      'Acesse a aba "Estatísticas" no menu inferior do estabelecimento. Lá você encontra faturamento total, ticket médio, agendamentos realizados e estimativas para o próximo mês.',
  },
  {
    category: 'Estabelecimentos',
    order: 5,
    question: 'Como respondo a avaliação de um cliente?',
    answer:
      'Acesse a aba "Avaliações" no menu do estabelecimento. Toque na avaliação desejada para visualizá-la. A funcionalidade de resposta estará disponível em breve.',
  },
];

async function main() {
  console.log('Seeding FAQ items...');

  // Limpa apenas se não houver perguntas de usuário (evita apagar dados de produção)
  const existingCount = await prisma.faqItem.count();
  if (existingCount === 0) {
    for (const faq of faqs) {
      await prisma.faqItem.create({ data: faq });
    }
    console.log(`✓ ${faqs.length} FAQ items created.`);
  } else {
    console.log(`✓ Seed pulado — já existem ${existingCount} FAQs no banco.`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
