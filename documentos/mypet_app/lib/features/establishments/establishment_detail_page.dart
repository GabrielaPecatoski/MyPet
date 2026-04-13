import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class EstablishmentDetailPage extends StatelessWidget {
  const EstablishmentDetailPage({super.key});

  final _services = const [
    {'name': 'Banho', 'price': 'R\$ 50,00', 'desc': 'Banho completo com shampoo premium', 'dur': '60 minutos'},
    {'name': 'Tosa', 'price': 'R\$ 80,00', 'desc': 'Tosa higienica ou estetica', 'dur': '90 minutos'},
    {'name': 'Banho e Tosa', 'price': 'R\$ 80,00', 'desc': 'Pacote completo de banho e tosa', 'dur': '120 minutos'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height:190, width: double.infinity, color: const Color(0xFF2E7D32), child: const Icon(Icons.storefront, color: Colors.white54, size:64)),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Clinica Veterinaria Vida Animal', style: TextStyle(fontSize:18, fontWeight: FontWeight.w800)),
              const SizedBox(height:6),
              Row(children: const [Icon(Icons.star, color: AppColors.star, size:18), SizedBox(width:4), Text('4.9(89)', style: TextStyle(fontSize:14, fontWeight: FontWeight.w500))]),
              const SizedBox(height:8),
              const Text('Clinica Veterinaria com profissionais especializados e equipamentos modernos.', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
              const SizedBox(height:12),
              _infoRow(Icons.location_on_outlined, 'Rua do Comercio, 789 - Vila Nova'),
              const SizedBox(height:6),
              _infoRow(Icons.phone_outlined, '(11) 3456-7892'),
              const SizedBox(height:6),
              _infoRow(Icons.access_time_outlined, 'Seg - Sex: 8h as 18h | Sab: 8h as 14h'),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal:16), child: Text('Servicos Oferecidos', style: TextStyle(fontSize:17, fontWeight: FontWeight.w800))),
          const SizedBox(height:10),
          ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal:16),
            itemCount: _services.length,
            separatorBuilder: (_, ignore) => const SizedBox(height:10),
            itemBuilder: (_, i) {
              final s = _services[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:15)),
                    const Spacer(),
                    Text(s['price']!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize:15)),
                  ]),
                  const SizedBox(height:4),
                  Text(s['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize:13)),
                  const SizedBox(height:4),
                  Text('Duracao: ${s['dur']}', style: const TextStyle(color: AppColors.textSecondary, fontSize:12)),
                ]),
              );
            },
          ),
          const SizedBox(height:100),
        ]))),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/scheduling'),
            child: const Text('Agendar Servico'),
          ),
        ),
      ]),
    );
  }

  static Widget _infoRow(IconData icon, String text) => Row(
    children: [Icon(icon, size:16, color: AppColors.textSecondary), const SizedBox(width:8), Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize:13)))],
  );
}
