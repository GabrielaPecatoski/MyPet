import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../widgets/mypet_app_bar.dart';

class EstablishmentDetailScreen extends StatelessWidget {
  const EstablishmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final establishment =
        ModalRoute.of(context)!.settings.arguments as EstablishmentModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner do estabelecimento
                Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.primaryLight,
                  child: Center(
                    child: Icon(
                      establishment.type == 'PET_SHOP'
                          ? Icons.pets
                          : Icons.local_hospital,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e tipo
                      Text(
                        establishment.name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        establishment.typeLabel,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey),
                      ),
                      const SizedBox(height: 12),
                      // Avaliação
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFC107), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${establishment.rating}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            ' (${establishment.reviewCount} avaliações)',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Endereço
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppColors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              establishment.address,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 16, color: AppColors.grey),
                          const SizedBox(width: 4),
                          Text(
                            establishment.phone,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Serviços
                      const Text(
                        'Serviços Oferecidos',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final service = establishment.services[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.dark),
                              ),
                              if (service.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  service.description!,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.grey),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Duração: ${service.durationMinutes} min',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'R\$ ${service.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: establishment.services.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/schedule',
                    arguments: establishment,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Agendar Serviço',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
