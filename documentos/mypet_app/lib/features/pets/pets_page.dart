import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class PetsPage extends StatelessWidget {
  const PetsPage({super.key});

  final _pets = const [
    {'name': 'Rex', 'breed': 'Golden Retriever', 'age': '3 anos', 'cv': 0xFFD4A574},
    {'name': 'Luna', 'breed': 'Siames', 'age': '2 anos', 'cv': 0xFF607D8B},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MyPetAppBar(showBack: false, onProfileTap: () => Navigator.pushNamed(context, '/add-pet')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-pet'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pets.length,
        separatorBuilder: (_, ignore) => const SizedBox(height:10),
        itemBuilder: (_, i) {
          final p = _pets[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              CircleAvatar(radius:28, backgroundColor: Color(p['cv'] as int), child: const Icon(Icons.pets, color: Colors.white, size:24)),
              const SizedBox(width:14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:16)),
                Text('${p['breed']} - ${p['age']}', style: const TextStyle(color: AppColors.textSecondary, fontSize:13)),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
