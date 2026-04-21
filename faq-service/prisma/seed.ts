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
];

async function main() {
  console.log('Seeding FAQ items...');
  await prisma.faqItem.deleteMany();

  for (const faq of faqs) {
    await prisma.faqItem.create({ data: faq });
  }

  console.log(`✓ ${faqs.length} FAQ items created.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
