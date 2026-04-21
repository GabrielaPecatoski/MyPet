import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/faq.dart';
import '../providers/auth_provider.dart';
import '../services/faq_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabHelpScreen extends StatefulWidget {
  const EstabHelpScreen({super.key});
  @override
  State<EstabHelpScreen> createState() => _EstabHelpScreenState();
}

class _EstabHelpScreenState extends State<EstabHelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<FaqItem> _faqs = [];
  List<UserQuestion> _myQuestions = [];
  bool _loadingFaq = false;
  bool _loadingQuestions = false;
  String _search = '';
  String? _selectedCategory;
  List<String> _categories = [];
  final Set<String> _expanded = {};

  // Categorias relevantes para estabelecimentos
  static const _estabCategories = [
    'Agendamento',
    'Estabelecimentos',
    'Avaliações',
    'Pagamentos',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFaqs();
      _loadMyQuestions();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() => _loadingFaq = true);
    try {
      final cats = await FaqService.getCategories();
      final faqs = await FaqService.getFaqs();
      final estabFaqs =
          faqs.where((f) => _estabCategories.contains(f.category)).toList();
      setState(() {
        _categories =
            cats.where((c) => _estabCategories.contains(c)).toList();
        _faqs = estabFaqs;
      });
    } catch (_) {
    } finally {
      setState(() => _loadingFaq = false);
    }
  }

  Future<void> _loadMyQuestions() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    setState(() => _loadingQuestions = true);
    try {
      final qs = await FaqService.getUserQuestions(
        auth.user!.id,
        token: auth.token,
      );
      setState(() => _myQuestions = qs);
    } catch (_) {
    } finally {
      setState(() => _loadingQuestions = false);
    }
  }

  List<FaqItem> get _filtered {
    var list = _selectedCategory != null
        ? _faqs.where((f) => f.category == _selectedCategory).toList()
        : _faqs;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _showAskDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enviar dúvida',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.dark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Não encontrou o que procurava? Envie sua dúvida e nossa equipe responderá em breve.',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Descreva sua dúvida...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.grey))),
          ElevatedButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              try {
                await FaqService.submitQuestion(
                  userId: auth.user?.id ?? '',
                  userName: auth.user?.name ?? 'Estabelecimento',
                  userRole: 'ESTABELECIMENTO',
                  question: text,
                  token: auth.token,
                );
                await _loadMyQuestions();
                _tabs.animateTo(1);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Dúvida enviada! Responderemos em breve.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao enviar. Tente novamente.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Central de Ajuda',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark)),
                        Text('Suporte para estabelecimentos',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar nas perguntas frequentes...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.grey),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.grey, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.greyLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.greyLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.grey,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: [
                      const Tab(text: 'Perguntas Frequentes'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Minhas Dúvidas'),
                            if (_myQuestions
                                .any((q) => q.status == 'RESPONDIDA')) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_myQuestions.where((q) => q.status == 'RESPONDIDA').length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          // ── Conteúdo ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _EstabFaqTab(
                  loading: _loadingFaq,
                  faqs: _filtered,
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  expanded: _expanded,
                  onCategorySelected: (c) =>
                      setState(() => _selectedCategory = c),
                  onToggle: (id) => setState(() {
                    if (_expanded.contains(id)) {
                      _expanded.remove(id);
                    } else {
                      _expanded.add(id);
                    }
                  }),
                  onAskTap: _showAskDialog,
                ),
                _EstabQuestionsTab(
                  loading: _loadingQuestions,
                  questions: _myQuestions,
                  onAskTap: _showAskDialog,
                  onRefresh: _loadMyQuestions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ Tab (estabelecimento) ────────────────────────────────────────
class _EstabFaqTab extends StatelessWidget {
  final bool loading;
  final List<FaqItem> faqs;
  final List<String> categories;
  final String? selectedCategory;
  final Set<String> expanded;
  final void Function(String?) onCategorySelected;
  final void Function(String) onToggle;
  final VoidCallback onAskTap;

  const _EstabFaqTab({
    required this.loading,
    required this.faqs,
    required this.categories,
    required this.selectedCategory,
    required this.expanded,
    required this.onCategorySelected,
    required this.onToggle,
    required this.onAskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final grouped = <String, List<FaqItem>>{};
    for (final f in faqs) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (categories.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(
                  label: 'Todos',
                  selected: selectedCategory == null,
                  onTap: () => onCategorySelected(null),
                ),
                ...categories.map((c) => _Chip(
                      label: c,
                      selected: selectedCategory == c,
                      onTap: () => onCategorySelected(
                          selectedCategory == c ? null : c),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (faqs.isEmpty)
          _Empty(onAskTap: onAskTap)
        else
          ...grouped.entries.map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(e.key,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                  ...e.value.map((f) => _FaqTile(
                        faq: f,
                        isExpanded: expanded.contains(f.id),
                        onToggle: () => onToggle(f.id),
                      )),
                  const SizedBox(height: 6),
                ],
              )),
        const SizedBox(height: 8),
        _Banner(onTap: onAskTap),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.greyLight),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.grey)),
        ),
      );
}

class _FaqTile extends StatelessWidget {
  final FaqItem faq;
  final bool isExpanded;
  final VoidCallback onToggle;
  const _FaqTile(
      {required this.faq, required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
          ],
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(faq.question,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark)),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.grey,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.greyLight),
                  const SizedBox(height: 10),
                  Text(faq.answer,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey, height: 1.5)),
                ],
              ],
            ),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  final VoidCallback onAskTap;
  const _Empty({required this.onAskTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.search_off,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Nenhuma pergunta encontrada',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark)),
            const SizedBox(height: 6),
            const Text('Tente outra busca ou envie sua dúvida',
                style: TextStyle(fontSize: 13, color: AppColors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAskTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Enviar minha dúvida',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}

class _Banner extends StatelessWidget {
  final VoidCallback onTap;
  const _Banner({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Precisa de ajuda específica?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.dark)),
                  SizedBox(height: 2),
                  Text('Nossa equipe responde em até 24h',
                      style: TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: const Text('Perguntar',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ── Perguntas Tab (estabelecimento) ─────────────────────────────────
class _EstabQuestionsTab extends StatelessWidget {
  final bool loading;
  final List<UserQuestion> questions;
  final VoidCallback onAskTap;
  final Future<void> Function() onRefresh;

  const _EstabQuestionsTab({
    required this.loading,
    required this.questions,
    required this.onAskTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(Icons.forum_outlined,
                        size: 34, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nenhuma dúvida enviada',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark)),
                  const SizedBox(height: 6),
                  const Text('Envie sua pergunta para nossa equipe',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.grey)),
                ],
              ),
            )
          else
            ...questions.map((q) => _QCard(question: q)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAskTap,
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            label: const Text('Nova dúvida',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QCard extends StatelessWidget {
  final UserQuestion question;
  const _QCard({required this.question});

  Color get _color {
    switch (question.status) {
      case 'RESPONDIDA':
        return AppColors.success;
      case 'FECHADA':
        return AppColors.grey;
      default:
        return AppColors.warning;
    }
  }

  String get _label {
    switch (question.status) {
      case 'RESPONDIDA':
        return 'Respondida';
      case 'FECHADA':
        return 'Fechada';
      default:
        return 'Aguardando';
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = question.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(question.question,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_label,
                      style: TextStyle(
                          fontSize: 11,
                          color: _color,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Enviada em $date',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.grey)),
            if (question.answer != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.greyLight),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.support_agent,
                        size: 16, color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resposta do suporte',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                        const SizedBox(height: 3),
                        Text(question.answer!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.dark,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
