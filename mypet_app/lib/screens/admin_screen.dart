import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/admin_repository.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  AdminProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final p = AdminProvider(AdminRepository(token: auth.token ?? ''));
      p.addListener(_rebuild);
      setState(() => _provider = p);
      p.loadAll();
    });
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _provider?.removeListener(_rebuild);
    _provider?.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que quer sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _provider;
    if (p == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final pages = [
      _DashboardPage(
        users: p.users,
        faqItems: p.faqItems,
        userQuestions: p.userQuestions,
        loading: p.isLoading,
        error: p.error,
        onRetry: p.loadAll,
        onGoToFaq: () => setState(() => _selectedIndex = 2),
        onGoToUsers: () => setState(() => _selectedIndex = 1),
      ),
      _UsuariosPage(users: p.users, loading: p.isLoading),
      _FaqPage(
        faqItems: p.faqItems,
        userQuestions: p.userQuestions,
        loading: p.isLoading,
        onCreateFaq: p.createFaq,
        onUpdateFaq: p.updateFaq,
        onDeleteFaq: p.deleteFaq,
        onAnswer: p.answerQuestion,
        onClose: p.closeQuestion,
      ),
      _EstatisticasPage(users: p.users, loading: p.isLoading),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedIndex == 0 ? null : const MypetAppBar(showBack: false),
      body: pages[_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        items: adminNavItems,
        onTap: (i) {
          if (i == 4) { _logout(); return; }
          setState(() => _selectedIndex = i);
        },
        badges: {
          2: p.userQuestions.where((q) => q['status'] == 'PENDENTE').length,
        },
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> faqItems;
  final List<Map<String, dynamic>> userQuestions;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onGoToFaq;
  final VoidCallback onGoToUsers;

  const _DashboardPage({
    required this.users,
    required this.faqItems,
    required this.userQuestions,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onGoToFaq,
    required this.onGoToUsers,
  });

  String _fmt(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          const Text('Sem conexão com o servidor', style: TextStyle(color: AppColors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
    }

    final clientes = users.where((u) => u['role'] == 'CLIENTE').length;
    final vendedores = users.where((u) => u['role'] == 'VENDEDOR').length;
    final pendentes = userQuestions.where((q) => q['status'] == 'PENDENTE').length;
    final now = DateTime.now();
    final novosNoMes = users.where((u) {
      try {
        final d = DateTime.parse(u['createdAt'] as String);
        return d.year == now.year && d.month == now.month;
      } catch (_) {
        return false;
      }
    }).length;

    final recentes = [...users]..sort((a, b) {
        final da = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });

    return ListView(
      padding: EdgeInsets.zero,
      children: [

        Builder(builder: (ctx) {
          final topPad = MediaQuery.of(ctx).padding.top;
          return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B3FF2), Color(0xFF5B2FBF)],
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Image.asset('assets/images/logo branca.png', height: 48, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(
              'Painel Administrativo',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, letterSpacing: 0.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Row(children: [
                _BannerStat('${users.length}', 'Usuários'),
                _bannerDivider(),
                _BannerStat('$clientes', 'Clientes'),
                _bannerDivider(),
                _BannerStat('$vendedores', 'Fornecedores'),
                _bannerDivider(),
                _BannerStat('$novosNoMes', 'Novos/mês'),
              ]),
            ),
          ]),
        );
        }),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if (pendentes > 0) ...[
              GestureDetector(
                onTap: onGoToFaq,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.mark_chat_unread_outlined, color: AppColors.warning, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '$pendentes ${pendentes == 1 ? 'dúvida pendente' : 'dúvidas pendentes'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning),
                      ),
                      const Text('Toque para responder', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                    ])),
                    const Icon(Icons.chevron_right, color: AppColors.warning),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(children: [
              _ActionCard(
                icon: Icons.people,
                color: const Color(0xFF4285F4),
                label: 'Usuários',
                value: '${users.length}',
                sub: '$clientes clientes · $vendedores fornec.',
                onTap: onGoToUsers,
              ),
              const SizedBox(width: 12),
              _ActionCard(
                icon: Icons.help,
                color: AppColors.primary,
                label: 'FAQ',
                value: '${faqItems.length}',
                sub: '${faqItems.where((f) => f['active'] == true).length} publicadas',
                onTap: onGoToFaq,
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _ActionCard(
                icon: Icons.question_answer,
                color: pendentes > 0 ? AppColors.warning : AppColors.success,
                label: 'Dúvidas',
                value: '${userQuestions.length}',
                sub: '$pendentes pendentes',
                onTap: onGoToFaq,
              ),
              const SizedBox(width: 12),
              _ActionCard(
                icon: Icons.person_add,
                color: const Color(0xFF34A853),
                label: 'Novos',
                value: '$novosNoMes',
                sub: 'cadastros este mês',
                onTap: onGoToUsers,
              ),
            ]),

            const SizedBox(height: 20),
            const Text('Últimos cadastros', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            ...recentes.take(5).map((u) {
              final role = u['role'] as String? ?? 'CLIENTE';
              final isVendedor = role == 'VENDEDOR';
              final color = isVendedor ? const Color(0xFF4285F4) : AppColors.success;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Text(
                      (u['name'] as String? ?? '?')[0].toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark), overflow: TextOverflow.ellipsis),
                    Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 11, color: AppColors.grey), overflow: TextOverflow.ellipsis),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(isVendedor ? 'Fornec.' : 'Cliente', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 2),
                    Text(_fmt(u['createdAt'] as String?), style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                  ]),
                ]),
              );
            }),
          ]),
        ),
      ],
    );
  }
}

Widget _bannerDivider() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8));

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;
  const _BannerStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.chevron_right, color: AppColors.greyLight, size: 18),
            ]),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
          ]),
        ),
      ),
    );
  }
}

class _UsuariosPage extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool loading;
  const _UsuariosPage({required this.users, required this.loading});

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN': return AppColors.danger;
      case 'VENDEDOR': return const Color(0xFF4285F4);
      default: return AppColors.success;
    }
  }

  String _fmt(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (users.isEmpty) return const Center(child: Text('Nenhum usuário encontrado', style: TextStyle(color: AppColors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final u = users[i];
        final role = u['role'] as String? ?? 'CLIENTE';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor(role).withValues(alpha: 0.12),
              child: Text(
                (u['name'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.email_outlined, size: 12, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Flexible(child: Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.grey), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('Cadastro: ${_fmt(u['createdAt'] as String?)}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                ]),
                Row(children: [
                  const Icon(Icons.login_outlined, size: 11, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('Último acesso: ${_fmt(u['lastLoginAt'] as String?)}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _roleColor(role).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(role, style: TextStyle(color: _roleColor(role), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }
}

class _FaqPage extends StatefulWidget {
  final List<Map<String, dynamic>> faqItems;
  final List<Map<String, dynamic>> userQuestions;
  final bool loading;
  final Future<void> Function(String q, String a, String cat) onCreateFaq;
  final Future<void> Function(String id, Map<String, dynamic> data) onUpdateFaq;
  final Future<void> Function(String id) onDeleteFaq;
  final Future<void> Function(String id, String answer) onAnswer;
  final Future<void> Function(String id) onClose;

  const _FaqPage({
    required this.faqItems,
    required this.userQuestions,
    required this.loading,
    required this.onCreateFaq,
    required this.onUpdateFaq,
    required this.onDeleteFaq,
    required this.onAnswer,
    required this.onClose,
  });

  @override
  State<_FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<_FaqPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showFaqDialog({Map<String, dynamic>? existing}) {
    final qCtrl = TextEditingController(text: existing?['question'] as String? ?? '');
    final aCtrl = TextEditingController(text: existing?['answer'] as String? ?? '');
    final catCtrl = TextEditingController(text: existing?['category'] as String? ?? 'Geral');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Nova pergunta' : 'Editar pergunta'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Categoria')),
            const SizedBox(height: 8),
            TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Pergunta'), maxLines: 2),
            const SizedBox(height: 8),
            TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'Resposta'), maxLines: 4),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(context);
              if (existing == null) {
                await widget.onCreateFaq(qCtrl.text.trim(), aCtrl.text.trim(), catCtrl.text.trim());
              } else {
                await widget.onUpdateFaq(existing['id'] as String, {
                  'question': qCtrl.text.trim(),
                  'answer': aCtrl.text.trim(),
                  'category': catCtrl.text.trim(),
                });
              }
            },
            child: Text(existing == null ? 'Criar' : 'Salvar', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(Map<String, dynamic> q) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Responder dúvida'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${q['userName']} (${q['userRole']})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey)),
              const SizedBox(height: 4),
              Text(q['question'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.dark, fontStyle: FontStyle.italic)),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Sua resposta'), maxLines: 4),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await widget.onAnswer(q['id'] as String, ctrl.text.trim());
            },
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final pending = widget.userQuestions.where((q) => q['status'] == 'PENDENTE').length;

    return Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(text: 'Perguntas Frequentes'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Dúvidas dos clientes'),
                if (pending > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tab, children: [

          Stack(children: [
            widget.faqItems.isEmpty
                ? const Center(child: Text('Nenhuma pergunta cadastrada.\nToque no + para adicionar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: widget.faqItems.length,
                    itemBuilder: (ctx, i) {
                      final f = widget.faqItems[i];
                      final active = f['active'] as bool? ?? true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: active ? AppColors.greyLight : AppColors.greyLight.withValues(alpha: 0.4)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(f['category'] as String? ?? 'Geral', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const Spacer(),
                            if (!active)
                              const Padding(padding: EdgeInsets.only(right: 8), child: Text('inativo', style: TextStyle(color: AppColors.grey, fontSize: 11))),
                            GestureDetector(
                              onTap: () => _showFaqDialog(existing: f),
                              child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.grey),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Excluir pergunta?'),
                                    content: const Text('Esta ação não pode ser desfeita.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Excluir', style: TextStyle(color: AppColors.danger))),
                                    ],
                                  ),
                                );
                                if (ok == true) await widget.onDeleteFaq(f['id'] as String);
                              },
                              child: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(f['question'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
                          const SizedBox(height: 4),
                          Text(f['answer'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.grey, height: 1.4)),
                        ]),
                      );
                    },
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => _showFaqDialog(),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ]),

          widget.userQuestions.isEmpty
              ? const Center(child: Text('Nenhuma dúvida enviada ainda.', style: TextStyle(color: AppColors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.userQuestions.length,
                  itemBuilder: (ctx, i) {
                    final q = widget.userQuestions[i];
                    final status = q['status'] as String? ?? '';
                    final isPendente = status == 'PENDENTE';
                    final role = q['userRole'] as String? ?? 'CLIENTE';
                    final isVendedor = role == 'VENDEDOR';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isPendente ? AppColors.warning.withValues(alpha: 0.4) : AppColors.greyLight),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: (isVendedor ? const Color(0xFF4285F4) : AppColors.success).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                                isVendedor ? 'Estabelecimento' : 'Cliente',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isVendedor ? const Color(0xFF4285F4) : AppColors.success)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(q['userName'] as String? ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark), overflow: TextOverflow.ellipsis),
                          ),
                          _StatusBadge(status),
                        ]),
                        const SizedBox(height: 8),
                        Text(q['question'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.4)),
                        if (q['answer'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Expanded(child: Text(q['answer'] as String, style: const TextStyle(fontSize: 12, color: AppColors.success, height: 1.3))),
                            ]),
                          ),
                        ],
                        if (isPendente) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async => await widget.onClose(q['id'] as String),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.grey, side: const BorderSide(color: AppColors.greyLight)),
                                child: const Text('Fechar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showAnswerDialog(q),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: const Text('Responder', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ]),
                        ],
                      ]),
                    );
                  },
                ),
        ]),
      ),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'RESPONDIDA': color = AppColors.success; break;
      case 'FECHADA': color = AppColors.grey; break;
      default: color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _EstatisticasPage extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final bool loading;
  const _EstatisticasPage({required this.users, required this.loading});

  @override
  State<_EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<_EstatisticasPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final clientes = widget.users.where((u) => u['role'] == 'CLIENTE').toList();
    final vendedores = widget.users.where((u) => u['role'] == 'VENDEDOR').toList();
    final todos = widget.users;

    return Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(text: 'Clientes'),
            Tab(text: 'Fornecedores'),
            Tab(text: 'Geral'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tab, children: [
          _StatsView(users: clientes, label: 'Clientes', color: AppColors.success),
          _StatsView(users: vendedores, label: 'Fornecedores', color: const Color(0xFF4285F4)),
          _StatsView(users: todos, label: 'Todos', color: AppColors.primary, showBreakdown: true),
        ]),
      ),
    ]);
  }
}

class _StatsView extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String label;
  final Color color;
  final bool showBreakdown;

  const _StatsView({
    required this.users,
    required this.label,
    required this.color,
    this.showBreakdown = false,
  });

  int _cadastrosNoMes(List<dynamic> list, int monthsAgo) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - monthsAgo, 1);
    final to = DateTime(now.year, now.month - monthsAgo + 1, 1);
    return list.where((u) {
      try {
        final d = DateTime.parse(u['createdAt'] as String);
        return d.isAfter(from) && d.isBefore(to);
      } catch (_) { return false; }
    }).length;
  }

  int _ativosUltimos30(List<dynamic> list) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return list.where((u) {
      try {
        final d = DateTime.parse(u['lastLoginAt'] as String? ?? '');
        return d.isAfter(cutoff);
      } catch (_) { return false; }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final ativos = _ativosUltimos30(users);
    final inativos = total - ativos;
    final mesAtual = _cadastrosNoMes(users, 0);
    final mesAnterior = _cadastrosNoMes(users, 1);

    final clientes = showBreakdown ? users.where((u) => u['role'] == 'CLIENTE').length : 0;
    final vendedores = showBreakdown ? users.where((u) => u['role'] == 'VENDEDOR').length : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        Row(children: [
          _MiniCard('Total', '$total', Icons.people_outlined, color),
          const SizedBox(width: 12),
          _MiniCard('Ativos (30d)', '$ativos', Icons.check_circle_outline, AppColors.success),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _MiniCard('Inativos', '$inativos', Icons.person_off_outlined, AppColors.grey),
          const SizedBox(width: 12),
          _MiniCard('Novos (mês)', '$mesAtual', Icons.person_add_outlined, AppColors.warning),
        ]),

        if (showBreakdown) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Distribuição por tipo',
            child: Column(children: [
              _BarRow('Clientes', clientes, total, AppColors.success),
              const SizedBox(height: 10),
              _BarRow('Fornecedores', vendedores, total, const Color(0xFF4285F4)),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        _SectionCard(
          title: 'Cadastros — últimos 3 meses',
          child: Column(children: [
            _BarRow(_monthLabel(0), mesAtual, mesAtual + mesAnterior + 1, color),
            const SizedBox(height: 10),
            _BarRow(_monthLabel(1), mesAnterior, mesAtual + mesAnterior + 1, color.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            _BarRow(_monthLabel(2), _cadastrosNoMes(users, 2), mesAtual + mesAnterior + 1, color.withValues(alpha: 0.3)),
          ]),
        ),

        const SizedBox(height: 16),
        _SectionCard(
          title: 'Engajamento',
          child: Column(children: [
            _InfoRow('Taxa de usuários ativos', total > 0 ? '${(ativos / total * 100).toStringAsFixed(0)}%' : '—'),
            const SizedBox(height: 8),
            _InfoRow('Sem acesso registrado', '${users.where((u) => u['lastLoginAt'] == null).length}'),
            const SizedBox(height: 8),
            _InfoRow('Crescimento vs. mês anterior',
                mesAnterior == 0 ? '—' : '${mesAtual >= mesAnterior ? '+' : ''}${mesAtual - mesAnterior} usuários'),
          ]),
        ),
      ],
    );
  }

  String _monthLabel(int ago) {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final now = DateTime.now();
    final m = (now.month - 1 - ago) % 12;
    return months[(m + 12) % 12];
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _BarRow(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.greyLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('$value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
    ]);
  }
}
