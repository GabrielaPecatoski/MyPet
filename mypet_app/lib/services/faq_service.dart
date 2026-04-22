import '../models/faq.dart';
import 'api_service.dart';

class FaqService {
  // Dados locais usados quando a API não está disponível
  static final List<FaqItem> _fallback = [
    const FaqItem(id: 'l1', category: 'Agendamento', order: 1, active: true,
      question: 'Como faço para agendar um serviço?',
      answer: 'Acesse a aba "Agenda" no menu inferior, escolha o estabelecimento, selecione o serviço, a data e horário disponível e confirme. Você receberá uma notificação quando o estabelecimento confirmar.'),
    const FaqItem(id: 'l2', category: 'Agendamento', order: 2, active: true,
      question: 'Posso cancelar um agendamento?',
      answer: 'Sim. Acesse "Agenda", localize o agendamento e toque em "Cancelar agendamento". Cancelamentos com menos de 2h de antecedência podem estar sujeitos à política do estabelecimento.'),
    const FaqItem(id: 'l3', category: 'Agendamento', order: 3, active: true,
      question: 'Por que um horário aparece bloqueado?',
      answer: 'Horários bloqueados já foram reservados por outro cliente ou foram marcados como indisponíveis pelo estabelecimento. Tente outro horário ou outra data.'),
    const FaqItem(id: 'l4', category: 'Agendamento', order: 4, active: true,
      question: 'Como acompanho meu serviço em tempo real?',
      answer: 'Após o agendamento ser confirmado, acesse "Agenda" e toque em "Acompanhar serviço". Você verá o status atual e a localização do estabelecimento.'),
    const FaqItem(id: 'l5', category: 'Agendamento', order: 5, active: true,
      question: 'Recebi a confirmação mas o horário sumiu. O que fazer?',
      answer: 'Puxe a lista para baixo para recarregar. Se o problema persistir, entre em contato com o estabelecimento diretamente.'),
    const FaqItem(id: 'l6', category: 'Pets', order: 1, active: true,
      question: 'Como cadastro meu pet?',
      answer: 'Acesse a aba "Pets" no menu inferior e toque no botão "+". Preencha o nome, espécie, raça e idade. O pet ficará disponível para agendamentos.'),
    const FaqItem(id: 'l7', category: 'Pets', order: 2, active: true,
      question: 'Quantos pets posso cadastrar?',
      answer: 'Não há limite de pets por conta. Cadastre todos os seus animais e selecione qual será atendido em cada agendamento.'),
    const FaqItem(id: 'l8', category: 'Pets', order: 3, active: true,
      question: 'Posso cadastrar pets de espécies diferentes?',
      answer: 'Sim! O MyPet aceita cães, gatos, pássaros, roedores e outras espécies.'),
    const FaqItem(id: 'l9', category: 'Conta e Perfil', order: 1, active: true,
      question: 'Como altero meus dados cadastrais?',
      answer: 'Acesse "Perfil", toque em "Editar perfil" e atualize as informações desejadas.'),
    const FaqItem(id: 'l10', category: 'Conta e Perfil', order: 2, active: true,
      question: 'Esqueci minha senha. O que faço?',
      answer: 'Na tela de login, toque em "Esqueci minha senha" e siga as instruções enviadas para o e-mail cadastrado.'),
    const FaqItem(id: 'l11', category: 'Conta e Perfil', order: 3, active: true,
      question: 'Como excluo minha conta?',
      answer: 'Entre em contato com o suporte pelo formulário de dúvidas ou pelo e-mail suporte@mypet.com.br. A solicitação será processada em até 5 dias úteis.'),
    const FaqItem(id: 'l12', category: 'Avaliações', order: 1, active: true,
      question: 'Como avalio um serviço realizado?',
      answer: 'Após o serviço ser concluído, ele aparece em "Histórico". Toque em "Avaliar", escolha de 1 a 5 estrelas e deixe um comentário opcional.'),
    const FaqItem(id: 'l13', category: 'Avaliações', order: 2, active: true,
      question: 'Posso editar ou remover minha avaliação?',
      answer: 'No momento avaliações não podem ser editadas. Entre em contato com o suporte caso haja algum problema.'),
    const FaqItem(id: 'l14', category: 'Pagamentos', order: 1, active: true,
      question: 'Quais formas de pagamento são aceitas?',
      answer: 'As formas variam por estabelecimento (dinheiro, cartão, Pix, etc). Consulte o estabelecimento antes de agendar.'),
    const FaqItem(id: 'l15', category: 'Pagamentos', order: 2, active: true,
      question: 'O aplicativo cobra alguma taxa?',
      answer: 'O MyPet é gratuito para clientes. O pagamento é feito diretamente ao estabelecimento.'),
    const FaqItem(id: 'l16', category: 'Estabelecimentos', order: 1, active: true,
      question: 'Como confirmo um agendamento recebido?',
      answer: 'Acesse "Agenda" no painel do estabelecimento, vá à aba "Pendentes" e confirme ou recuse o agendamento.'),
    const FaqItem(id: 'l17', category: 'Estabelecimentos', order: 2, active: true,
      question: 'Como bloqueio um horário na minha agenda?',
      answer: 'Acesse "Agenda" → "Horários" e configure os períodos de atendimento ou bloqueie datas específicas.'),
    const FaqItem(id: 'l18', category: 'Estabelecimentos', order: 3, active: true,
      question: 'Como adiciono produtos ao meu catálogo?',
      answer: 'Acesse a aba "Produtos" e toque em "Novo Produto". Preencha nome, categoria, preço e estoque.'),
    const FaqItem(id: 'l19', category: 'Estabelecimentos', order: 4, active: true,
      question: 'Como vejo meu faturamento e estatísticas?',
      answer: 'Acesse a aba "Estatísticas" no menu do estabelecimento para ver faturamento, ticket médio e estimativas.'),
  ];

  static Future<List<FaqItem>> getFaqs({String? category}) async {
    try {
      final path = category != null
          ? '/faq?category=${Uri.encodeComponent(category)}'
          : '/faq';
      final data = await ApiService.get(path);
      final list = (data as List).map((e) => FaqItem.fromJson(e)).toList();
      if (list.isNotEmpty) return list;
      return _applyCategory(_fallback, category);
    } catch (_) {
      return _applyCategory(_fallback, category);
    }
  }

  static List<FaqItem> _applyCategory(List<FaqItem> list, String? category) {
    if (category == null) return list;
    return list.where((f) => f.category == category).toList();
  }

  static Future<List<String>> getCategories() async {
    try {
      final data = await ApiService.get('/faq/categories');
      final list = (data as List).map((e) => e.toString()).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    // fallback: extrai categorias únicas dos dados locais
    final cats = _fallback.map((f) => f.category).toSet().toList()..sort();
    return cats;
  }

  static Future<UserQuestion?> submitQuestion({
    required String userId,
    required String userName,
    required String userRole,
    required String question,
    String? token,
  }) async {
    try {
      final data = await ApiService.post(
        '/faq/questions',
        {
          'userId': userId,
          'userName': userName,
          'userRole': userRole,
          'question': question,
        },
        token: token,
      );
      return UserQuestion.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      // Retorna null — a tela cria localmente
      return null;
    }
  }

  static Future<List<UserQuestion>> getUserQuestions(
    String userId, {
    String? token,
  }) async {
    try {
      final data = await ApiService.get(
        '/faq/questions/user/$userId',
        token: token,
      );
      return (data as List).map((e) => UserQuestion.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
