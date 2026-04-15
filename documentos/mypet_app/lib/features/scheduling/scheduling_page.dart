import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});
  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage> {
  int _selPet = 0, _selService = 0, _selDate = 0;

  final _pets = [
    {'name': 'Rex', 'breed': 'Golden Retriever', 'age': '3 anos'},
    {'name': 'Luna', 'breed': 'Siames', 'age': '2 anos'},
  ];
  final _services = [
    {'name': 'Banho', 'price': 'R\$ 50,00', 'desc': 'Banho completo com shampoo premium', 'dur': '60 min'},
    {'name': 'Tosa', 'price': 'R\$ 80,00', 'desc': 'Tosa higienica ou estetica', 'dur': '90 min'},
    {'name': 'Banho e Tosa', 'price': 'R\$ 80,00', 'desc': 'Pacote completo de banho e tosa', 'dur': '120 min'},
  ];
  final _dates = ['Ter, 18 Mar', 'Qua, 19 Mar', 'Qui, 20 Mar', 'Sex, 21 Mar'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Selecione o pet', style: TextStyle(fontSize:17, fontWeight: FontWeight.w800)),
          const SizedBox(height:10),
          ...List.generate(_pets.length, (i) {
            final p = _pets[i]; final sel = i == _selPet;
            return GestureDetector(
              onTap: () => setState(() => _selPet = i),
              child: Container(
                margin: const EdgeInsets.only(bottom:8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 1.5),
                ),
                child: Row(children: [
                  CircleAvatar(radius:24, backgroundColor: const Color(0xFFD4A574), child: const Icon(Icons.pets, color: Colors.white)),
                  const SizedBox(width:12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:15)),
                    Text('${p['breed']} - ${p['age']}', style: const TextStyle(color: AppColors.textSecondary, fontSize:13)),
                  ]),
                ]),
              ),
            );
          }),
          const SizedBox(height:16),
          const Text('Selecione o servico', style: TextStyle(fontSize:17, fontWeight: FontWeight.w800)),
          const SizedBox(height:10),
          ...List.generate(_services.length, (i) {
            final s = _services[i]; final sel = i == _selService;
            return GestureDetector(
              onTap: () => setState(() => _selService = i),
              child: Container(
                margin: const EdgeInsets.only(bottom:8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 1.5),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:14)),
                      const SizedBox(width:8),
                      Text(s['price']!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize:14)),
                    ]),
                    Text(s['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize:12)),
                  ])),
                  const SizedBox(width:8),
                  Text('Duracao:\n${s['dur']}', style: const TextStyle(color: AppColors.textSecondary, fontSize:12), textAlign: TextAlign.right),
                ]),
              ),
            );
          }),
          const SizedBox(height:16),
          const Text('Selecione a data', style: TextStyle(fontSize:17, fontWeight: FontWeight.w800)),
          const SizedBox(height:10),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:8, mainAxisSpacing:8, childAspectRatio:2.8),
            itemCount: _dates.length,
            itemBuilder: (_, i) {
              final sel = i == _selDate;
              return GestureDetector(
                onTap: () => setState(() => _selDate = i),
                child: Container(
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primary : Colors.transparent),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.calendar_today_outlined, size:16, color: sel ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width:6),
                    Text(_dates[i], style: TextStyle(fontSize:13, color: sel ? AppColors.primary : AppColors.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height:80),
        ]))),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento confirmado!'), backgroundColor: AppColors.confirmed));
              Navigator.popUntil(context, (r) => r.isFirst || r.settings.name == '/shell');
            },
            child: const Text('Confirmar Agendamento'),
          ),
        ),
      ]),
    );
  }
}
