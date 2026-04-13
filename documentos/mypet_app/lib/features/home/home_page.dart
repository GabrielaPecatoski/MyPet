import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _cat = 0;
  final _cats = ['Todos', 'Banho', 'Tosa', 'Veterinario', 'Acessorios'];
  final _estabs = [
    {'name': 'Clinica Veterinaria Vida Animal', 'rating': '4.9', 'reviews': '89', 'dist': '1.2 km', 'desc': 'Clinica Veterinaria com profissionais especializados e equipamentos modernos.', 'cv': 0xFF2E7D32},
    {'name': 'Petlove', 'rating': '4.7', 'reviews': '197', 'dist': '1.2 km', 'desc': 'Tudo para seu pet! Racoes, acessorios, higiene e produtos veterinarios.', 'cv': 0xFF6A1B9A},
    {'name': 'Pet Shop Amor e Carinho', 'rating': '4.8', 'reviews': '134', 'dist': '2.0 km', 'desc': 'Banho, tosa e acessorios com muito carinho para o seu pet.', 'cv': 0xFF1565C0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width:28, height:28, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.pets, color: Colors.white, size:16)),
                    const SizedBox(width:6),
                    const Text('My Pet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize:18)),
                    const Spacer(),
                    const CircleAvatar(radius:16, backgroundColor: Colors.white24, child: Icon(Icons.person_outline, color: Colors.white, size:18)),
                  ]),
                  const SizedBox(height:8),
                  const Text('Encontre o melhor servico para o seu Pet', style: TextStyle(color: Colors.white, fontSize:13)),
                ]),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar pet shop ou clinica',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size:20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical:10),
                    fillColor: Colors.transparent, filled: false,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height:12),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal:16),
              itemCount: _cats.length,
              itemBuilder: (_, i) {
                final sel = i == _cat;
                return GestureDetector(
                  onTap: () => setState(() => _cat = i),
                  child: Container(
                    margin: const EdgeInsets.only(right:8),
                    padding: const EdgeInsets.symmetric(horizontal:16),
                    decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: Text(_cats[i], style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize:13)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height:16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/scheduling'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryLight, width:1.5)),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(width:52, height:52, color: const Color(0xFFD4A574), child: const Icon(Icons.pets, color: Colors.white))),
                  const SizedBox(width:12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('Servico Confirmado', style: TextStyle(fontWeight: FontWeight.w700, fontSize:14)),
                      const SizedBox(width:8),
                      Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2), decoration: BoxDecoration(color: AppColors.confirmed, borderRadius: BorderRadius.circular(20)), child: const Text('Hoje', style: TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height:4),
                    const Text('Goden - Banho', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
                    const Text('14:00  -  Pet Shop amor e Carinho', style: TextStyle(color: AppColors.textSecondary, fontSize:12)),
                  ])),
                  const Icon(Icons.arrow_forward, color: AppColors.primary),
                ]),
              ),
            ),
          ),
          const SizedBox(height:20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16),
            child: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: AppColors.confirmed, borderRadius: BorderRadius.circular(20)), child: const Text('Melhores Avaliacoes', style: TextStyle(color: Colors.white, fontSize:12, fontWeight: FontWeight.w600))),
              const Spacer(),
              const Icon(Icons.add, color: AppColors.textSecondary),
            ]),
          ),
          const SizedBox(height:12),
          const Padding(padding: EdgeInsets.symmetric(horizontal:16), child: Text('Mais Bem Avaliados', style: TextStyle(fontSize:18, fontWeight: FontWeight.w800))),
          const SizedBox(height:12),
          ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal:16),
            itemCount: _estabs.length,
            separatorBuilder: (_, ignore) => const SizedBox(height:12),
            itemBuilder: (_, i) {
              final e = _estabs[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/establishment'),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius:8)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: Container(height:130, width: double.infinity, color: Color(e['cv'] as int), child: const Icon(Icons.storefront, color: Colors.white54, size:48))),
                    Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:15)),
                      const SizedBox(height:4),
                      Row(children: [
                        const Icon(Icons.star, color: AppColors.star, size:16),
                        const SizedBox(width:4),
                        Text('${e['rating']}(${e['reviews']})', style: const TextStyle(fontSize:13, fontWeight: FontWeight.w500)),
                        const SizedBox(width:12),
                        const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size:14),
                        Text(e['dist'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize:13)),
                      ]),
                      const SizedBox(height:4),
                      Text(e['desc'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize:12)),
                    ])),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height:24),
        ])),
      ]),
    );
  }
}
