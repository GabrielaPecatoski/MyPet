import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});
  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  String _species = 'Cachorro';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            GestureDetector(
              onTap: () {},
              child: Container(width:90, height:90, decoration: const BoxDecoration(color: AppColors.divider, shape: BoxShape.circle), child: const Icon(Icons.download, color: AppColors.textSecondary, size:32)),
            ),
            const SizedBox(height:20),
            _field('Nome do Pet', 'Rex'),
            const SizedBox(height:14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              'Cachorro', 'Gato', 'Outro'
            ].map((s) => GestureDetector(
              onTap: () => setState(() => _species = s),
              child: Row(children: [
                Container(
                  width:16, height:16,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _species == s ? AppColors.primary : AppColors.textSecondary, width:2)),
                  child: _species == s ? Container(margin: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
                ),
                const SizedBox(width:8),
                Text(s, style: TextStyle(fontSize:14, color: _species == s ? AppColors.primary : AppColors.textPrimary, fontWeight: _species == s ? FontWeight.w600 : FontWeight.normal)),
              ]),
            )).toList()),
            const SizedBox(height:14),
            _field('Raca', 'Ex: Vira-lata, Persa, etc.'),
            const SizedBox(height:14),
            _field('Idade (Anos)', 'Ex: 3', type: TextInputType.number),
            const SizedBox(height:24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
              const SizedBox(width:12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cadastrar'))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, String hint, {TextInputType type = TextInputType.text}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:14)),
      const SizedBox(height:6),
      TextField(keyboardType: type, decoration: InputDecoration(hintText: hint)),
    ],
  );
}
