import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../models/veterinarian.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/app_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedChip = 0;
  final _searchController = TextEditingController();

  static const _chips = ['Todos', 'Banho', 'Tosa', 'Veterinário', 'Acessórios'];
  static const _vetChipIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<HomeProvider>().load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onChipTap(int idx) {
    setState(() => _selectedChip = idx);
    final home = context.read<HomeProvider>();
    home.filterByType(_chips[idx]);
    if (idx == _vetChipIndex && home.availableVets.isEmpty) {
      final token = context.read<AuthProvider>().token ?? '';
      home.loadAvailableVets(token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final user = context.watch<AuthProvider>().user;
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;
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
            SliverToBoxAdapter(
              child: Container(
                height: 60,
                color: AppColors.primary,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo branca.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 26),
                            if (unreadCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      child: GestureDetector(
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
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: (value) =>
                                  context.read<HomeProvider>().search(value),
                              decoration: const InputDecoration(
                                hintText: 'Buscar pet shop, clínica...',
                                hintStyle:
                                    TextStyle(color: AppColors.grey, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (home.query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                context.read<HomeProvider>().search('');
                              },
                              child: const Icon(Icons.close,
                                  color: AppColors.grey, size: 20),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/emergencia'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.emergency,
                                color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergência Veterinária',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    'Encontre clínicas disponíveis agora',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

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
                                    '${confirmedToday.first.serviceName} às ${confirmedToday.first.time}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (home.isLoading)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)))
                    else if (home.error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.wifi_off,
                                  size: 48, color: AppColors.greyLight),
                              const SizedBox(height: 12),
                              Text(home.error!,
                                  style: const TextStyle(color: AppColors.grey),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<HomeProvider>().load(),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                child: const Text('Tentar novamente',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (home.establishments.isEmpty)
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
                      if (_selectedChip == _vetChipIndex) ...[
                        const Text(
                          'Veterinários disponíveis',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Profissionais prontos para atender seu pet',
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                        const SizedBox(height: 12),
                        if (home.loadingVets)
                          const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF16A34A))))
                        else if (home.availableVets.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.greyLight),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.medical_services_outlined,
                                    color: AppColors.greyLight, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Nenhum veterinário disponível no momento.\nVeja as clínicas abaixo.',
                                    style: TextStyle(
                                        color: AppColors.grey, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final v in home.availableVets) _VetHomeCard(vet: v),
                        const SizedBox(height: 8),
                        const Text(
                          'Clínicas e Pet shops',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_selectedChip != _vetChipIndex) ...[
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
                            itemCount: home.establishments.take(5).length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (ctx, i) =>
                                _HighlightCard(establishment: home.establishments[i]),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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

            if (!home.isLoading && home.error == null && home.establishments.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _EstabCard(establishment: home.establishments[i]),
                  ),
                  childCount: home.establishments.length,
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: AppColors.primaryLight,
                child: AppImage(
                  url: e.imageUrl,
                  fit: BoxFit.cover,
                  fallback: Center(
                    child: Icon(
                      e.isVeterinario ? Icons.local_hospital : Icons.pets,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
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

class _VetHomeCard extends StatelessWidget {
  final VeterinarianModel vet;
  const _VetHomeCard({required this.vet});

  static const _green = Color(0xFF16A34A);
  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/emergencia'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: _green, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${vet.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(vet.especialidade ?? 'Clínico geral',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Disponível',
                            style: TextStyle(
                                fontSize: 10,
                                color: _green,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (vet.atendeDomicilio) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_outlined,
                                  size: 10, color: _orange),
                              SizedBox(width: 3),
                              Text('Domiciliar',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _orange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
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
            PhotoBox(
              url: e.imageUrl,
              size: 60,
              radius: 10,
              background: AppColors.primaryLight,
              fallback: Icon(
                e.isVeterinario ? Icons.local_hospital : Icons.pets,
                color: AppColors.primary,
                size: 28,
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
                    '${e.serviceCount} serv.',
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
