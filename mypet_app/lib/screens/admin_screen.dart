import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/admin_data.dart';
import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  List<AdminUserModel> _users = [];
  List<AdminEstabModel> _estabs = [];
  List<ComplaintModel> _complaints = [];
  List<dynamic> _faqItems = [];
  List<dynamic> _userQuestions = [];
  Map<String, dynamic> _reviewStats = {};
  bool _loading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = Provider.of<AuthProvider>(context, listen: false).token;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Future.wait([
        _loadUsers(),
        _loadEstabs(),
        _loadComplaints(),
        _loadFaq(),
        _loadReviewStats(),
        _loadUserQuestions(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _loadUsers() async {
    final data = await ApiService.get('/users', token: _token);
    final list = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    setState(() => _users = list.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<void> _loadEstabs() async {
    try {
      final data = await ApiService.get('/establishments/admin/all', token: _token);
      setState(() => _estabs = (data as List).map((e) => AdminEstabModel.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {
      final data = await ApiService.get('/establishments');
      setState(() => _estabs = (data as List).map((e) => AdminEstabModel.fromJson(e as Map<String, dynamic>)).toList());
    }
  }

  Future<void> _loadComplaints() async {
    try {
      final data = await ApiService.get('/reviews/admin/complaints', token: _token);
      setState(() => _complaints = (data as List).map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {
      setState(() => _complaints = []);
    }
  }

  Future<void> _loadFaq() async {
    try {
      final data = await ApiService.get('/faq/admin/all', token: _token);
      setState(() => _faqItems = data as List<dynamic>);
    } catch (_) {
      setState(() => _faqItems = []);
    }
  }

  Future<void> _loadReviewStats() async {
    try {
      final data = await ApiService.get('/reviews/admin/stats', token: _token);
      setState(() => _reviewStats = data as Map<String, dynamic>);
    } catch (_) {
      setState(() => _reviewStats = {});
    }
  }

  Future<void> _loadUserQuestions() async {
    try {
      final data = await ApiService.get('/faq/questions/admin/all', token: _token);
      setState(() => _userQuestions = data as List<dynamic>);
    } catch (_) {
      setState(() => _userQuestions = []);
    }
  }

  Future<void> _resolveComplaint(String id) async {
    await ApiService.patch('/reviews/admin/complaints/$id/resolve', {}, token: _token);
    await _loadComplaints();
  }

  Future<void> _rejectComplaint(String id) async {
    await ApiService.patch('/reviews/admin/complaints/$id/reject', {}, token: _token);
    await _loadComplaints();
  }

  Future<void> _createFaq(String question, String answer, String category, String targetRole) async {
    await ApiService.post('/faq/admin', {
      'question': question, 'answer': answer,
      'category': category, 'targetRole': targetRole,
    }, token: _token);
    await _loadFaq();
  }

  Future<void> _updateFaq(String id, Map<String, dynamic> data) async {
    await ApiService.put('/faq/admin/$id', data, token: _token);
    await _loadFaq();
  }

  Future<void> _deleteFaq(String id) async {
    await ApiService.delete('/faq/admin/$id', token: _token);
    await _loadFaq();
  }

  Future<void> _answerUserQuestion(String id, String answer) async {
    await ApiService.put('/faq/questions/admin/$id/answer', {'answer': answer}, token: _token);
    await _loadUserQuestions();
  }

  Future<void> _closeUserQuestion(String id) async {
    await ApiService.put('/faq/questions/admin/$id/close', {}, token: _token);
    await _loadUserQuestions();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: const Text('Tem certeza que deseja sair?', style: TextStyle(color: AppColors.grey, fontSize: 14)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.grey)),
            ),
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
    final isWide = MediaQuery.of(context).size.width > 600;
    final pendingComplaints = _complaints.where((c) => c.status == 'PENDENTE').length;
    final pendingQuestions = _userQuestions.where((q) => (q as Map)['status'] == 'PENDENTE').length;
    final badges = {
      1: pendingComplaints,
      4: pendingQuestions,
    };

    final pages = [
      _PainelPage(
        users: _users,
        estabs: _estabs,
        complaints: _complaints,
        reviewStats: _reviewStats,
        loading: _loading,
        error: _error,
        onRetry: _loadAll,
        onLogout: _logout,
        onGoToComplaints: () => setState(() => _selectedIndex = 1),
        onGoToStats: () => setState(() => _selectedIndex = 5),
      ),
      _ReclamacoesPage(
        complaints: _complaints,
        estabs: _estabs,
        loading: _loading,
        onResolve: _resolveComplaint,
        onReject: _rejectComplaint,
      ),
      _UsuariosPage(users: _users, loading: _loading),
      _LojasPage(estabs: _estabs, loading: _loading),
      _FaqPage(
        faqItems: _faqItems,
        userQuestions: _userQuestions,
        loading: _loading,
        onCreateFaq: _createFaq,
        onUpdateFaq: _updateFaq,
        onDeleteFaq: _deleteFaq,
        onAnswerQuestion: _answerUserQuestion,
        onCloseQuestion: _closeUserQuestion,
      ),
      _EstatisticasPage(
        users: _users,
        estabs: _estabs,
        complaints: _complaints,
        reviewStats: _reviewStats,
        faqItems: _faqItems,
        userQuestions: _userQuestions,
        loading: _loading,
      ),
    ];

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(children: [
          _AdminSidebar(
            selectedIndex: _selectedIndex,
            badges: badges,
            onTap: (i) => setState(() => _selectedIndex = i),
            onLogout: _logout,
          ),
          Expanded(child: pages[_selectedIndex]),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedIndex == 0
          ? null
          : MypetAppBar(
              showBack: false,
              purple: _selectedIndex == 5,
              actions: [_AdminSairButton(onPressed: _logout, onPurple: _selectedIndex == 5)],
            ),
      body: pages[_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        items: adminNavItems,
        onTap: (i) => setState(() => _selectedIndex = i),
        badges: badges,
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Map<int, int> badges;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.selectedIndex,
    required this.badges,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(children: [
        Container(
          height: 64,
          color: AppColors.primary,
          child: Center(
            child: Image.asset('assets/images/logo branca.png', height: 30, fit: BoxFit.contain),
          ),
        ),
        Expanded(
          child: NavigationRail(
            backgroundColor: Colors.white,
            minWidth: 220,
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: const IconThemeData(color: AppColors.grey),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.grey, fontSize: 12),
            destinations: adminNavItems.asMap().entries.map((entry) {
              final item = entry.value;
              final badge = badges[entry.key] ?? 0;

              return NavigationRailDestination(
                icon: _badgeIcon(item.icon, badge),
                selectedIcon: _badgeIcon(item.activeIcon, badge),
                label: Text(item.label),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: const Text('Sair', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          onTap: onLogout,
        ),
      ]),
    );
  }

  Widget _badgeIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);

    return Badge.count(
      count: count,
      backgroundColor: AppColors.danger,
      child: Icon(icon),
    );
  }
}

class _AdminSairButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool onPurple;

  const _AdminSairButton({required this.onPressed, required this.onPurple});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: onPurple ? Colors.white.withValues(alpha: 0.15) : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: onPurple ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.logout, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text('Sair', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}


class _PainelPage extends StatelessWidget {
  final List<AdminUserModel> users;
  final List<AdminEstabModel> estabs;
  final List<ComplaintModel> complaints;
  final Map<String, dynamic> reviewStats;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;
  final VoidCallback onGoToComplaints;
  final VoidCallback onGoToStats;

  const _PainelPage({
    required this.users,
    required this.estabs,
    required this.complaints,
    required this.reviewStats,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onLogout,
    required this.onGoToComplaints,
    required this.onGoToStats,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, size: 48, color: AppColors.grey),
        const SizedBox(height: 12),
        const Text('Sem conexão com o servidor', style: TextStyle(color: AppColors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
        ),
      ]));
    }

    final pendingComplaints = complaints.where((c) => c.status == 'PENDENTE').length;
    final now = DateTime.now();
    final newUsers = users.where((u) {
      final d = u.createdAt;
      return d != null && d.year == now.year && d.month == now.month;
    }).length;
    final avgRating = (reviewStats['avgRating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = (reviewStats['totalReviews'] as num?)?.toInt() ?? 0;
    final authUser = context.watch<AuthProvider>().user;
    final userName = authUser?.name.split(' ').first ?? 'Admin';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Builder(builder: (ctx) {
          final topPad = MediaQuery.of(ctx).padding.top;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B3FF2), Color(0xFF5B2FBF)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/images/logo branca.png', height: 36, fit: BoxFit.contain),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          Icon(Icons.logout, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Sair', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'SISTEMA · MY PET ADMIN',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text('Olá, $userName', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Você tem $pendingComplaints ${pendingComplaints == 1 ? 'reclamação' : 'reclamações'} e $newUsers novos cadastros aguardando.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onGoToComplaints,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Ver Reclamações', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onGoToStats,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Estatísticas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ]),
          );
        }),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _StatCard('Usuários', '${users.length}', Icons.people_outlined, const Color(0xFF4285F4)),
              const SizedBox(width: 12),
              _StatCard('Estabelecimentos', '${estabs.length}', Icons.store_outlined, AppColors.primary),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard('Reclamações', '${complaints.length}', Icons.warning_amber_outlined, AppColors.warning),
              const SizedBox(width: 12),
              _StatCard('Avaliação Média', avgRating > 0 ? avgRating.toStringAsFixed(1) : '—', Icons.star_outline, const Color(0xFFF59E0B)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard('Avaliações', '$totalReviews', Icons.chat_bubble_outline, AppColors.danger),
              const SizedBox(width: 12),
              _StatCard('Novos usuários', '+${users.where((u) { final d = u.createdAt; final now = DateTime.now(); return d != null && d.year == now.year && d.month == now.month; }).length}', Icons.trending_up_outlined, AppColors.success),
            ]),

            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Movimentação de hoje', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
              Text(
                _dayMonth(DateTime.now()),
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ]),
            const SizedBox(height: 12),
            _MovCard(
              icon: Icons.calendar_today_outlined,
              iconColor: AppColors.primary,
              title: '— agendamentos confirmados',
              sub: 'dados em tempo real',
            ),
            const SizedBox(height: 8),
            _MovCard(
              icon: Icons.favorite_outline,
              iconColor: AppColors.danger,
              title: '— serviços em atendimento',
              sub: 'banho, tosa, consultas vet',
            ),
            const SizedBox(height: 8),
            _MovCard(
              icon: Icons.trending_up_outlined,
              iconColor: AppColors.success,
              title: '— transações hoje',
              sub: 'valor total estimado',
            ),
          ]),
        ),
      ],
    );
  }

  String _dayMonth(DateTime d) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            Icon(icon, size: 18, color: color),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.dark)),
        ]),
      ),
    );
  }
}

class _MovCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  const _MovCard({required this.icon, required this.iconColor, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark)),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        ])),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.greyLight),
      ]),
    );
  }
}


class _ReclamacoesPage extends StatefulWidget {
  final List<ComplaintModel> complaints;
  final List<AdminEstabModel> estabs;
  final bool loading;
  final Future<void> Function(String id) onResolve;
  final Future<void> Function(String id) onReject;

  const _ReclamacoesPage({
    required this.complaints,
    required this.estabs,
    required this.loading,
    required this.onResolve,
    required this.onReject,
  });

  @override
  State<_ReclamacoesPage> createState() => _ReclamacoesPageState();
}

class _ReclamacoesPageState extends State<_ReclamacoesPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _estabName(String id) {
    final e = widget.estabs.where((e) => e.id == id).firstOrNull;
    return e?.name ?? id;
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  List<ComplaintModel> _filtered(String filter) {
    switch (filter) {
      case 'pendente': return widget.complaints.where((c) => c.status == 'PENDENTE').toList();
      case 'analise': return widget.complaints.where((c) => c.status == 'EM_ANALISE').toList();
      case 'resolvida': return widget.complaints.where((c) => c.status == 'RESOLVIDA' || c.status == 'REJEITADA').toList();
      default: return widget.complaints;
    }
  }

  void _openDetail(ComplaintModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintDetailSheet(
        complaint: c,
        estabName: _estabName(c.establishmentId),
        onResolve: () async {
          Navigator.pop(context);
          await widget.onResolve(c.id);
        },
        onReject: () async {
          Navigator.pop(context);
          await widget.onReject(c.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final pendente = widget.complaints.where((c) => c.status == 'PENDENTE').length;
    final analise = widget.complaints.where((c) => c.status == 'EM_ANALISE').length;
    final resolvida = widget.complaints.where((c) => c.status == 'RESOLVIDA' || c.status == 'REJEITADA').length;

    return Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            const Tab(text: 'Todas'),
            Tab(child: _tabLabel('Pendentes', pendente)),
            const Tab(text: 'Análise'),
            const Tab(text: 'Resolvidas'),
          ],
        ),
      ),
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _SummaryChip('Pendente', '$pendente', Icons.schedule_outlined, AppColors.warning),
          const SizedBox(width: 12),
          _SummaryChip('Em análise', '$analise', Icons.chat_bubble_outline, const Color(0xFF4285F4)),
          const SizedBox(width: 12),
          _SummaryChip('Resolvida', '$resolvida', Icons.check_circle_outline, AppColors.success),
        ]),
      ),
      Expanded(
        child: TabBarView(controller: _tab, children: [
          _complaintList(_filtered('todas')),
          _complaintList(_filtered('pendente')),
          _complaintList(_filtered('analise')),
          _complaintList(_filtered('resolvida')),
        ]),
      ),
    ]);
  }

  Widget _tabLabel(String label, int count) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(label),
    if (count > 0) ...[
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    ],
  ]);

  Widget _complaintList(List<ComplaintModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Nenhuma reclamação aqui.', style: TextStyle(color: AppColors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _ComplaintCard(
        complaint: list[i],
        estabName: _estabName(list[i].establishmentId),
        onTap: () => _openDetail(list[i]),
        fmtDate: _fmtDate,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryChip(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
          ])),
        ]),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final String estabName;
  final VoidCallback onTap;
  final String Function(DateTime) fmtDate;
  const _ComplaintCard({required this.complaint, required this.estabName, required this.onTap, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _StatusBadge(complaint.status),
            const SizedBox(width: 6),
            if (complaint.category.isNotEmpty)
              _CategoryBadge(complaint.category),
            const Spacer(),
            Text(fmtDate(complaint.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(complaint.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('De', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                Text(complaint.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark), overflow: TextOverflow.ellipsis),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.greyLight),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Contra', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                Text(estabName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ComplaintDetailSheet extends StatelessWidget {
  final ComplaintModel complaint;
  final String estabName;
  final VoidCallback onResolve;
  final VoidCallback onReject;

  const _ComplaintDetailSheet({
    required this.complaint,
    required this.estabName,
    required this.onResolve,
    required this.onReject,
  });

  String _fmtFull(DateTime d) {
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} às ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPending = complaint.status == 'PENDENTE' || complaint.status == 'EM_ANALISE';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
              Row(children: [
                _StatusBadge(complaint.status),
                const SizedBox(width: 6),
                if (complaint.category.isNotEmpty) _CategoryBadge(complaint.category),
              ]),
              const SizedBox(height: 12),
              Text(complaint.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
              const SizedBox(height: 4),
              Text(_fmtFull(complaint.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('RECLAMANTE', style: TextStyle(fontSize: 10, color: AppColors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(complaint.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
                    const Text('Cliente', style: TextStyle(fontSize: 11, color: AppColors.grey)),
                  ]),
                )),
                const SizedBox(width: 10),
                Expanded(child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('CONTRA', style: TextStyle(fontSize: 10, color: AppColors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(estabName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
                    const Text('Estabelecimento', style: TextStyle(fontSize: 11, color: AppColors.grey)),
                  ]),
                )),
              ]),
              const SizedBox(height: 16),
              const Text('DESCRIÇÃO', style: TextStyle(fontSize: 11, color: AppColors.grey, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(complaint.description, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.5)),
              const SizedBox(height: 20),
              const Text('TIMELINE', style: TextStyle(fontSize: 11, color: AppColors.grey, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _TimelineItem(
                label: 'Reclamação aberta',
                detail: '${_fmtDay(complaint.createdAt)} · ${complaint.userName}',
                done: true,
              ),
              _TimelineItem(
                label: 'Em análise pela equipe',
                detail: complaint.status != 'PENDENTE' ? '${_fmtDay(complaint.createdAt)} · Admin' : '— Aguardando',
                done: complaint.status != 'PENDENTE',
              ),
              _TimelineItem(
                label: 'Resposta do estabelecimento',
                detail: complaint.response != null ? complaint.response! : '— Aguardando',
                done: complaint.response != null,
                isLast: true,
              ),
            ]),
          ),
          if (isPending)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Rejeitar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onResolve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Marcar resolvida', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  String _fmtDay(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final String detail;
  final bool done;
  final bool isLast;
  const _TimelineItem({required this.label, required this.detail, required this.done, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: done ? AppColors.success : AppColors.greyLight,
            shape: BoxShape.circle,
          ),
        ),
        if (!isLast)
          Container(width: 1, height: 32, color: AppColors.greyLight),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: done ? AppColors.dark : AppColors.grey)),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        ]),
      )),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'RESOLVIDA': color = AppColors.success; label = 'Resolvida'; break;
      case 'REJEITADA': color = AppColors.danger; label = 'Rejeitada'; break;
      case 'EM_ANALISE': color = const Color(0xFF4285F4); label = 'Em análise'; break;
      default: color = AppColors.warning; label = 'Pendente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(20)),
      child: Text(category, style: const TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}


class _UsuariosPage extends StatefulWidget {
  final List<AdminUserModel> users;
  final bool loading;
  const _UsuariosPage({required this.users, required this.loading});

  @override
  State<_UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<_UsuariosPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

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

  List<AdminUserModel> _filtered(String role) {
    var list = widget.users;
    if (role == 'CLIENTE') list = list.where((u) => u.role == 'CLIENTE').toList();
    if (role == 'VENDEDOR') list = list.where((u) => u.role == 'VENDEDOR').toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final total = widget.users.length;
    final now = DateTime.now();
    final ativos = widget.users.where((u) {
      final d = u.lastLoginAt;
      return d != null && now.difference(d).inDays <= 30;
    }).length;
    final novos = widget.users.where((u) {
      final d = u.createdAt;
      return d != null && d.year == now.year && d.month == now.month;
    }).length;

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar usuário ou email',
            hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
            suffixIcon: const Icon(Icons.tune_outlined, color: AppColors.grey, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Todos'), Tab(text: 'Clientes'), Tab(text: 'Lojistas')],
        ),
      ),
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _UserStat('Total', '$total', Icons.people_outlined, AppColors.primary),
          const SizedBox(width: 12),
          _UserStat('Ativos', '$ativos', Icons.check_circle_outline, AppColors.success),
          const SizedBox(width: 12),
          _UserStat('Novos', '+$novos', Icons.trending_up, AppColors.warning),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Usuários cadastrados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tab, children: [
          _UserList(users: _filtered('TODOS')),
          _UserList(users: _filtered('CLIENTE')),
          _UserList(users: _filtered('VENDEDOR')),
        ]),
      ),
    ]);
  }
}

class _UserStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _UserStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
          ])),
        ]),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<AdminUserModel> users;
  const _UserList({required this.users});

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN': return AppColors.danger;
      case 'VENDEDOR': return const Color(0xFF4285F4);
      default: return AppColors.success;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'VENDEDOR': return 'Lojista';
      case 'ADMIN': return 'Admin';
      default: return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const Center(child: Text('Nenhum usuário encontrado.', style: TextStyle(color: AppColors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final u = users[i];
        final initials = u.name.trim().isEmpty ? '?' : u.name.trim().split(' ').take(2).map((s) => s[0].toUpperCase()).join();
        final color = _roleColor(u.role);
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
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
              Text(u.email, style: const TextStyle(fontSize: 12, color: AppColors.grey), overflow: TextOverflow.ellipsis),
              if (u.phone.isNotEmpty)
                Text(u.phone, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              if (u.petsCount > 0)
                Text('${u.petsCount} pet${u.petsCount != 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(_roleLabel(u.role), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }
}


class _LojasPage extends StatefulWidget {
  final List<AdminEstabModel> estabs;
  final bool loading;
  const _LojasPage({required this.estabs, required this.loading});

  @override
  State<_LojasPage> createState() => _LojasPageState();
}

class _LojasPageState extends State<_LojasPage> {
  String _search = '';

  List<AdminEstabModel> get _filtered {
    if (_search.isEmpty) return widget.estabs;
    final q = _search.toLowerCase();
    return widget.estabs.where((e) => e.name.toLowerCase().contains(q) || e.city.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final avgRating = widget.estabs.isEmpty ? 0.0 : widget.estabs.map((e) => e.rating).reduce((a, b) => a + b) / widget.estabs.length;

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar estabelecimento',
            hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _EstabStat('Parceiros ativos', '${widget.estabs.length}', Icons.store_outlined, AppColors.primary),
          const SizedBox(width: 12),
          _EstabStat('Avaliação média', avgRating.toStringAsFixed(1), Icons.star_outline, const Color(0xFFF59E0B)),
        ]),
      ),
      Expanded(
        child: _filtered.isEmpty
            ? const Center(child: Text('Nenhum estabelecimento encontrado.', style: TextStyle(color: AppColors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) => _EstabCard(estab: _filtered[i]),
              ),
      ),
    ]);
  }
}

class _EstabStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _EstabStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
          ])),
        ]),
      ),
    );
  }
}

class _EstabCard extends StatelessWidget {
  final AdminEstabModel estab;
  const _EstabCard({required this.estab});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(estab.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
          if (estab.address.isNotEmpty)
            Text(estab.address + (estab.city.isNotEmpty ? ' · ${estab.city}' : ''), style: const TextStyle(fontSize: 12, color: AppColors.grey), overflow: TextOverflow.ellipsis),
          if (estab.phone.isNotEmpty)
            Text(estab.phone, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(estab.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
            if (estab.reviewCount > 0)
              Text(' (${estab.reviewCount})', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            const SizedBox(width: 10),
            Text('${estab.servicesCount} ${estab.servicesCount == 1 ? 'serviço' : 'serviços'}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ]),
        ])),
      ]),
    );
  }
}


class _FaqPage extends StatefulWidget {
  final List<dynamic> faqItems;
  final List<dynamic> userQuestions;
  final bool loading;
  final Future<void> Function(String q, String a, String cat, String targetRole) onCreateFaq;
  final Future<void> Function(String id, Map<String, dynamic> data) onUpdateFaq;
  final Future<void> Function(String id) onDeleteFaq;
  final Future<void> Function(String id, String answer) onAnswerQuestion;
  final Future<void> Function(String id) onCloseQuestion;

  const _FaqPage({
    required this.faqItems,
    required this.userQuestions,
    required this.loading,
    required this.onCreateFaq,
    required this.onUpdateFaq,
    required this.onDeleteFaq,
    required this.onAnswerQuestion,
    required this.onCloseQuestion,
  });

  @override
  State<_FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<_FaqPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

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

  List<dynamic> _forRole(String role) {
    var list = widget.faqItems;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((f) => (f['question'] as String? ?? '').toLowerCase().contains(q)).toList();
    }
    if (role == 'CLIENTE') return list.where((f) {
      final r = f['targetRole'] as String? ?? 'CLIENTE';
      return r == 'CLIENTE' || r == 'TODOS';
    }).toList();
    if (role == 'VENDEDOR') return list.where((f) {
      final r = f['targetRole'] as String? ?? 'CLIENTE';
      return r == 'VENDEDOR' || r == 'TODOS';
    }).toList();
    return list;
  }

  void _openEditSheet({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FaqEditSheet(
        item: item,
        onSave: (q, a, cat, targetRole, active) async {
          Navigator.pop(context);
          if (item == null) {
            await widget.onCreateFaq(q, a, cat, targetRole);
          } else {
            await widget.onUpdateFaq(item['id'] as String, {
              'question': q, 'answer': a, 'category': cat,
              'targetRole': targetRole, 'active': active,
            });
          }
        },
        onDelete: item == null ? null : () async {
          Navigator.pop(context);
          await widget.onDeleteFaq(item['id'] as String);
        },
      ),
    );
  }

  void _openQuestionDetail(Map<String, dynamic> q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionDetailSheet(
        question: q,
        onAnswer: (answer) async {
          Navigator.pop(context);
          await widget.onAnswerQuestion(q['id'] as String, answer);
        },
        onClose: () async {
          Navigator.pop(context);
          await widget.onCloseQuestion(q['id'] as String);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final clientes = _forRole('CLIENTE');
    final lojistas = _forRole('VENDEDOR');
    final pendingQuestions = widget.userQuestions.where((q) => (q as Map)['status'] == 'PENDENTE').length;
    final allVisible = widget.faqItems.where((f) => f['active'] == true).length;
    final rascunhos = widget.faqItems.where((f) => f['active'] != true).length;

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Central de Ajuda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
              Text('Perguntas que os usuários fazem no app', style: TextStyle(fontSize: 11, color: AppColors.grey)),
            ])),
            ElevatedButton.icon(
              onPressed: () => _openEditSheet(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ]),
        ),
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar pergunta...',
            hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(text: 'Clientes · ${clientes.length}'),
            Tab(text: 'Lojistas · ${lojistas.length}'),
            Tab(child: _pendingTabLabel('Perguntas', pendingQuestions, widget.userQuestions.length)),
          ],
        ),
      ),
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _FaqStat('Publicadas', '$allVisible', Icons.visibility_outlined, AppColors.primary),
          const SizedBox(width: 12),
          _FaqStat('Rascunho', '$rascunhos', Icons.warning_amber_outlined, AppColors.warning),
          const SizedBox(width: 12),
          _FaqStat('Perguntas', '${widget.userQuestions.length}', Icons.help_outlined, AppColors.grey),
        ]),
      ),
      Expanded(
        child: TabBarView(controller: _tab, children: [
          _FaqList(items: clientes, onEdit: _openEditSheet),
          _FaqList(items: lojistas, onEdit: _openEditSheet),
          _UserQuestionsList(questions: widget.userQuestions, onTap: _openQuestionDetail),
        ]),
      ),
    ]);
  }

  Widget _pendingTabLabel(String label, int pending, int total) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label · $total'),
      if (pending > 0) ...[
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
          child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ],
    ]);
  }
}

class _FaqStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _FaqStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  final List<dynamic> items;
  final void Function({Map<String, dynamic>? item}) onEdit;
  const _FaqList({required this.items, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Nenhuma pergunta cadastrada.', style: TextStyle(color: AppColors.grey)));

    final sorted = [...items]..sort((a, b) {
        final va = (a as Map<String, dynamic>)['viewCount'] as num? ?? 0;
        final vb = (b as Map<String, dynamic>)['viewCount'] as num? ?? 0;
        return vb.compareTo(va);
      });
    final top3 = sorted.where((f) => ((f as Map)['viewCount'] as num? ?? 0) > 0).take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (top3.isNotEmpty) ...[
          const Text('Mais procuradas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 10),
          ...top3.asMap().entries.map((e) {
            final i = e.key;
            final f = e.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
              ),
              child: Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f['question'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${f['viewCount']} visualizações', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                ])),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.greyLight),
              ]),
            );
          }),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Todas as perguntas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
            Text('${items.length} itens', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          ]),
          const SizedBox(height: 10),
        ],
        ...items.map((item) {
          final f = item as Map<String, dynamic>;
          return _FaqCard(f: f, onEdit: onEdit);
        }),
      ],
    );
  }
}

class _FaqCard extends StatelessWidget {
  final Map<String, dynamic> f;
  final void Function({Map<String, dynamic>? item}) onEdit;
  const _FaqCard({required this.f, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final active = f['active'] as bool? ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? AppColors.greyLight : AppColors.greyLight.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: active ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(active ? 'Publicada' : 'Rascunho', style: TextStyle(color: active ? AppColors.success : AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          if ((f['category'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text(f['category'] as String? ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => onEdit(item: f),
            child: const Text('Editar →', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(f['question'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark)),
        const SizedBox(height: 4),
        Text(f['answer'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.grey, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
        if ((f['viewCount'] as num? ?? 0) > 0) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Text('${f['viewCount']} visualizações', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ]),
        ],
      ]),
    );
  }
}


class _UserQuestionsList extends StatelessWidget {
  final List<dynamic> questions;
  final void Function(Map<String, dynamic>) onTap;
  const _UserQuestionsList({required this.questions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(child: Text('Nenhuma pergunta enviada por usuários.', style: TextStyle(color: AppColors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (ctx, i) {
        final q = questions[i] as Map<String, dynamic>;
        final status = q['status'] as String? ?? 'PENDENTE';
        final Color statusColor;
        final String statusLabel;
        switch (status) {
          case 'RESPONDIDA': statusColor = AppColors.success; statusLabel = 'Respondida'; break;
          case 'FECHADA': statusColor = AppColors.grey; statusLabel = 'Fechada'; break;
          default: statusColor = AppColors.warning; statusLabel = 'Pendente';
        }
        final isVendedor = q['userRole'] == 'VENDEDOR';

        return GestureDetector(
          onTap: () => onTap(q),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVendedor ? const Color(0xFF4285F4).withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isVendedor ? 'Lojista' : 'Cliente',
                    style: TextStyle(
                      color: isVendedor ? const Color(0xFF4285F4) : AppColors.success,
                      fontSize: 10, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.greyLight),
              ]),
              const SizedBox(height: 8),
              Text(q['question'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Por: ${q['userName'] as String? ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              if ((q['answer'] as String?) != null) ...[
                const SizedBox(height: 6),
                Text(q['answer'] as String, style: const TextStyle(fontSize: 12, color: AppColors.grey, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _QuestionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> question;
  final Future<void> Function(String answer) onAnswer;
  final Future<void> Function() onClose;

  const _QuestionDetailSheet({required this.question, required this.onAnswer, required this.onClose});

  @override
  State<_QuestionDetailSheet> createState() => _QuestionDetailSheetState();
}

class _QuestionDetailSheetState extends State<_QuestionDetailSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final status = q['status'] as String? ?? 'PENDENTE';
    final hasAnswer = (q['answer'] as String?) != null;
    final isClosed = status == 'FECHADA';
    final isVendedor = q['userRole'] == 'VENDEDOR';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVendedor ? const Color(0xFF4285F4).withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isVendedor ? 'Lojista' : 'Cliente',
                    style: TextStyle(
                      color: isVendedor ? const Color(0xFF4285F4) : AppColors.success,
                      fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${q['userName']}', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ]),
              const SizedBox(height: 14),
              const Text('PERGUNTA', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text(q['question'] as String? ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark, height: 1.4)),
              if (hasAnswer) ...[
                const SizedBox(height: 20),
                const Text('RESPOSTA', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Text(q['answer'] as String, style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.5)),
                ),
              ],
              if (!hasAnswer && !isClosed) ...[
                const SizedBox(height: 20),
                const Text('SUA RESPOSTA', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Digite a resposta para o usuário...',
                    hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ]),
          ),
          if (!hasAnswer && !isClosed)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey,
                      side: const BorderSide(color: AppColors.greyLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_ctrl.text.trim().isNotEmpty) {
                        widget.onAnswer(_ctrl.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Responder', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _FaqEditSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Future<void> Function(String q, String a, String cat, String targetRole, bool active) onSave;
  final Future<void> Function()? onDelete;

  const _FaqEditSheet({required this.item, required this.onSave, this.onDelete});

  @override
  State<_FaqEditSheet> createState() => _FaqEditSheetState();
}

class _FaqEditSheetState extends State<_FaqEditSheet> {
  late TextEditingController _qCtrl;
  late TextEditingController _aCtrl;
  late TextEditingController _catCtrl;
  late bool _active;
  bool _visCliente = true;
  bool _visLojista = false;
  bool _destaque = false;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.item?['question'] as String? ?? '');
    _aCtrl = TextEditingController(text: widget.item?['answer'] as String? ?? '');
    _catCtrl = TextEditingController(text: widget.item?['category'] as String? ?? '');
    _active = widget.item?['active'] as bool? ?? true;
    final role = widget.item?['targetRole'] as String? ?? 'CLIENTE';
    _visCliente = role == 'CLIENTE' || role == 'TODOS';
    _visLojista = role == 'VENDEDOR' || role == 'TODOS';
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _aCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
              if (widget.item != null)
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _active ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_active ? 'Publicada' : 'Rascunho', style: TextStyle(color: _active ? AppColors.success : AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text('ID #${(widget.item!['id'] as String).substring(0, 6)}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                ]),

              const SizedBox(height: 14),
              const Text('PERGUNTA', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _qCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),
              const Text('RESPOSTA', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _aCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),
              const Text('CATEGORIA', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _catCtrl,
                decoration: InputDecoration(
                  hintText: 'Ex: Agendamento, Pagamento...',
                  hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              const Text('VISIBILIDADE', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              _ToggleRow('Visível no app do cliente', _visCliente, (v) => setState(() => _visCliente = v)),
              _ToggleRow('Visível no app do lojista', _visLojista, (v) => setState(() => _visLojista = v)),
              _ToggleRow('Aparece em destaque na home', _destaque, (v) => setState(() => _destaque = v)),
              _ToggleRow('Publicada', _active, (v) => setState(() => _active = v)),
            ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(children: [
              if (widget.onDelete != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Excluir'),
                  ),
                ),
              if (widget.onDelete != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final role = (_visCliente && _visLojista) ? 'TODOS'
                        : _visLojista ? 'VENDEDOR'
                        : 'CLIENTE';
                    widget.onSave(_qCtrl.text.trim(), _aCtrl.text.trim(), _catCtrl.text.trim(), role, _active);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Salvar e Publicar', style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  const _ToggleRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.dark)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ]),
    );
  }
}


class _EstatisticasPage extends StatelessWidget {
  final List<AdminUserModel> users;
  final List<AdminEstabModel> estabs;
  final List<ComplaintModel> complaints;
  final Map<String, dynamic> reviewStats;
  final List<dynamic> faqItems;
  final List<dynamic> userQuestions;
  final bool loading;

  const _EstatisticasPage({
    required this.users,
    required this.estabs,
    required this.complaints,
    required this.reviewStats,
    required this.faqItems,
    required this.userQuestions,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final now = DateTime.now();

    final totalUsers = users.length;
    final clientes = users.where((u) => u.role == 'CLIENTE').length;
    final vendedores = users.where((u) => u.role == 'VENDEDOR').length;
    final newUsersMonth = users.where((u) {
      final d = u.createdAt;
      return d != null && d.year == now.year && d.month == now.month;
    }).length;
    final activeUsers = users.where((u) {
      final d = u.lastLoginAt;
      return d != null && now.difference(d).inDays <= 30;
    }).length;

    final totalEstabs = estabs.length;
    final avgEstabRating = estabs.isEmpty ? 0.0 : estabs.map((e) => e.rating).reduce((a, b) => a + b) / estabs.length;

    final avgReviewRating = (reviewStats['avgRating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = (reviewStats['totalReviews'] as num?)?.toInt() ?? 0;

    final totalComplaints = complaints.length;
    final pendingComplaints = complaints.where((c) => c.status == 'PENDENTE').length;
    final resolvedComplaints = complaints.where((c) => c.status == 'RESOLVIDA').length;
    final rejectedComplaints = complaints.where((c) => c.status == 'REJEITADA').length;

    final totalFaq = faqItems.length;
    final activeFaq = faqItems.where((f) => (f as Map)['active'] == true).length;

    final totalQuestions = userQuestions.length;
    final pendingQuestions = userQuestions.where((q) => (q as Map)['status'] == 'PENDENTE').length;
    final answeredQuestions = userQuestions.where((q) => (q as Map)['status'] == 'RESPONDIDA').length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Builder(builder: (ctx) {
          final topPad = MediaQuery.of(ctx).padding.top;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B3FF2), Color(0xFF5B2FBF)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'SISTEMA · MY PET ADMIN',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              const Text('Estatísticas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Visão geral de toda a plataforma',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ]),
          );
        }),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _StatsSection(
              title: 'Usuários',
              icon: Icons.people_outlined,
              color: const Color(0xFF4285F4),
              rows: [
                _StatsRowData('Total de usuários', '$totalUsers'),
                _StatsRowData('Clientes', '$clientes'),
                _StatsRowData('Lojistas', '$vendedores'),
                _StatsRowData('Novos este mês', '+$newUsersMonth'),
                _StatsRowData('Ativos (30 dias)', '$activeUsers'),
              ],
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Estabelecimentos',
              icon: Icons.store_outlined,
              color: AppColors.primary,
              rows: [
                _StatsRowData('Total de parceiros', '$totalEstabs'),
                _StatsRowData('Avaliação média', avgEstabRating > 0 ? avgEstabRating.toStringAsFixed(1) : '—'),
              ],
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Avaliações',
              icon: Icons.star_outline,
              color: const Color(0xFFF59E0B),
              rows: [
                _StatsRowData('Total de avaliações', '$totalReviews'),
                _StatsRowData('Nota média geral', avgReviewRating > 0 ? avgReviewRating.toStringAsFixed(1) : '—'),
              ],
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Reclamações',
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
              rows: [
                _StatsRowData('Total', '$totalComplaints'),
                _StatsRowData('Pendentes', '$pendingComplaints'),
                _StatsRowData('Resolvidas', '$resolvedComplaints'),
                _StatsRowData('Rejeitadas', '$rejectedComplaints'),
              ],
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Base de Conhecimento (FAQ)',
              icon: Icons.help_outline,
              color: AppColors.success,
              rows: [
                _StatsRowData('Total de artigos', '$totalFaq'),
                _StatsRowData('Publicados', '$activeFaq'),
                _StatsRowData('Rascunhos', '${totalFaq - activeFaq}'),
              ],
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Perguntas de Usuários',
              icon: Icons.chat_bubble_outline,
              color: AppColors.danger,
              rows: [
                _StatsRowData('Total de perguntas', '$totalQuestions'),
                _StatsRowData('Aguardando resposta', '$pendingQuestions'),
                _StatsRowData('Respondidas', '$answeredQuestions'),
              ],
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ],
    );
  }
}

class _StatsRowData {
  final String label;
  final String value;
  const _StatsRowData(this.label, this.value);
}

class _StatsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_StatsRowData> rows;

  const _StatsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
          ]),
        ),
        const Divider(height: 1),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(r.label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
            Text(r.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
          ]),
        )),
      ]),
    );
  }
}
