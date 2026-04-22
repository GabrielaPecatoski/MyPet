import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../models/establishment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EstablishmentModel> _establishments = [];
  List<EstablishmentModel> _filtered = [];
  bool _loading = true;
  String? _error;
  int _selectedChip = 0;

  static const _chips = ['Todos', 'Banho', 'Tosa', 'Veterinário', 'Acessórios'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEstablishments());
  }

  Future<void> _loadEstablishments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get(ApiConstants.establishmentsEndpoint);
      final list = data as List;
      setState(() {
        _establishments =
            list.map((e) => EstablishmentModel.fromJson(e as Map<String, dynamic>)).toList();
        _filtered = _establishments;
      });
    } catch (e) {
      setState(() => _error = 'Não foi possível carregar os estabelecimentos.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onChipTap(int idx) {
    setState(() {
      _selectedChip = idx;
      if (idx == 0) {
        _filtered = _establishments;
      } else {
        final term = _chips[idx].toLowerCase();
        _filtered = _establishments
            .where((e) =>
                e.name.toLowerCase().contains(term) ||
                e.services.any((s) => s.name.toLowerCase().contains(term)))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bookings = context.watch<BookingProvider>().bookings;
    final today = DateTime.now();
    final confirmedToday = bookings.where((b) =>
        b.status == 'CONFIRMADO' &&
        b.date.year == today.year &&
        b.date.month == today.month &&
        b.date.day == today.day).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header roxo com logo ───────────────────────────
            SliverToBoxAdapter(
              child: Container(
                height: 60,
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Image.asset(
                      'assets/images/logo branca.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (user != null) {
                          Navigator.pushNamed(context, '/home', arguments: 4);
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        child: user?.photoPath != null
                            ? ClipOval(
                                child: Image.file(
                                  dart_io.File(user!.photoPath!),
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Barra de busca
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar pet shop, clínica...',
                                hintStyle:
                                    TextStyle(color: AppColors.grey, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chips de categoria
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_chips.length, (i) {
                          final sel = _selectedChip == i;
                          return Padding(
                            padding: EdgeInsets.only(right: i < _chips.length - 1 ? 8 : 0),
                            child: GestureDetector(
                              onTap: () => _onChipTap(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel ? AppColors.primary : AppColors.greyLight,
                                  ),
                                ),
                                child: Text(
                                  _chips[i],
                                  style: TextStyle(
                                    color: sel ? Colors.white : AppColors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Banner Serviço Confirmado hoje
                    if (confirmedToday.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Serviço Confirmado',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.dark),
                                  ),
                                  Text(
                                    confirmedToday.first.serviceName +
                                        ' às ' +
                                        confirmedToday.first.time,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_loading)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)))
                    else if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.wifi_off,
                                  size: 48, color: AppColors.greyLight),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: const TextStyle(color: AppColors.grey),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadEstablishments,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                child: const Text('Tentar novamente',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_filtered.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Nenhum estabelecimento encontrado.',
                            style: TextStyle(color: AppColors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else ...[
                      // Seção Mais Bem Avaliados
                      const Text(
                        'Mais Bem Avaliados',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filtered.take(5).length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (ctx, i) =>
                              _HighlightCard(establishment: _filtered[i]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seção Estabelecimentos
                      const Text(
                        'Estabelecimentos',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            if (!_loading && _error == null && _filtered.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _EstabCard(establishment: _filtered[i]),
                  ),
                  childCount: _filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final EstablishmentModel establishment;
  const _HighlightCard({required this.establishment});

  @override
  Widget build(BuildContext context) {
    final e = establishment;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/establishment', arguments: e),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(
                  e.type == 'VET_CLINIC' ? Icons.local_hospital : Icons.pets,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Color(0xFFFFC107)),
                      const SizedBox(width: 3),
                      Text(
                        '${e.rating}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.dark,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${e.reviewCount})',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstabCard extends StatelessWidget {
  final EstablishmentModel establishment;
  const _EstabCard({required this.establishment});

  @override
  Widget build(BuildContext context) {
    final e = establishment;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/establishment', arguments: e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Foto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  e.type == 'VET_CLINIC' ? Icons.local_hospital : Icons.pets,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Color(0xFFFFC107)),
                      const SizedBox(width: 3),
                      Text('${e.rating}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(e.typeLabel,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(e.address,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${e.services.length} serv.',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
