import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<EstablishmentModel> _mockEstablishments = [
    EstablishmentModel(
      id: '1',
      name: 'Pet Shop Amor & Carinho',
      type: 'PET_SHOP',
      address: 'Rua das Flores, 123 — Vila Nova',
      phone: '(11) 3456-7890',
      rating: 4.8,
      reviewCount: 3,
      services: [
        ServiceModel(id: 's1', name: 'Banho', price: 50, durationMinutes: 60),
        ServiceModel(id: 's2', name: 'Tosa', price: 80, durationMinutes: 90),
        ServiceModel(id: 's3', name: 'Banho e Tosa', price: 80, durationMinutes: 120),
      ],
    ),
    EstablishmentModel(
      id: '2',
      name: 'Clínica Veterinária Vida Animal',
      type: 'VET_CLINIC',
      address: 'Av. Principal, 456 — Jardim das Flores',
      phone: '(11) 3456-1884',
      rating: 4.3,
      reviewCount: 5,
      services: [
        ServiceModel(id: 's4', name: 'Consulta Veterinária', price: 120, durationMinutes: 45),
        ServiceModel(id: 's5', name: 'Vacinação', price: 80, durationMinutes: 20),
        ServiceModel(id: 's6', name: 'Banho', price: 60, durationMinutes: 60),
      ],
    ),
    EstablishmentModel(
      id: '3',
      name: 'PetCare Express',
      type: 'PET_SHOP',
      address: 'Rua Nova, 789 — Vila Nova',
      phone: '(11) 3456-1952',
      rating: 4.5,
      reviewCount: 2,
      services: [
        ServiceModel(id: 's7', name: 'Banho', price: 45, durationMinutes: 60),
        ServiceModel(id: 's8', name: 'Tosa', price: 75, durationMinutes: 90),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${user?.name.split(' ').first ?? 'visitante'} 👋',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark),
                          ),
                          const Text(
                            'Encontre o melhor serviço para o seu pet',
                            style: TextStyle(fontSize: 12, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(Icons.person, color: AppColors.primary),
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar pet shop, clínica...',
                                hintStyle: TextStyle(color: AppColors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _categoryChip('Todos', true),
                        const SizedBox(width: 8),
                        _categoryChip('Pet Shop', false),
                        const SizedBox(width: 8),
                        _categoryChip('Veterinário', false),
                        const SizedBox(width: 8),
                        _categoryChip('Acessórios', false),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mais Bem Avaliados',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mockEstablishments.take(3).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) =>
                            _highlightCard(context, _mockEstablishments[i]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Estabelecimentos Parceiros',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _establishmentCard(context, _mockEstablishments[i]),
                ),
                childCount: _mockEstablishments.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.greyLight,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _highlightCard(BuildContext context, EstablishmentModel e) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/establishment', arguments: e),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  e.type == 'PET_SHOP' ? Icons.pets : Icons.local_hospital,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 13, color: Color(0xFFFFC107)),
                const SizedBox(width: 2),
                Text('${e.rating}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                const SizedBox(width: 4),
                Text('(${e.reviewCount})',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _establishmentCard(BuildContext context, EstablishmentModel e) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/establishment', arguments: e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  e.type == 'PET_SHOP' ? Icons.pets : Icons.local_hospital,
                  color: AppColors.primary,
                  size: 26,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(e.typeLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.grey),
                      const SizedBox(width: 2),
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
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text('${e.rating}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.services.length} serv.',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
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
