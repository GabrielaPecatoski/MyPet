import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        GestureDetector(
          onTap: () {},
          child: const CircleAvatar(radius:48, backgroundColor: Color(0xFF607D8B), child: Icon(Icons.person, color: Colors.white, size:48)),
        ),
        const SizedBox(height:24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _field('Nome Completo', 'loren'),
            const SizedBox(height:14),
            _field('Email', 'loren@hotmail.com', type: TextInputType.emailAddress),
            const SizedBox(height:14),
            _field('Telefone', '(11)11111111111', type: TextInputType.phone),
          ]),
        ),
        const SizedBox(height:24),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Salvar Alteracoes')),
        const SizedBox(height:10),
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ])),
    );
  }

  static Widget _field(String label, String hint, {TextInputType type = TextInputType.text}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:14)),
      const SizedBox(height:6),
      TextField(keyboardType: type, decoration: InputDecoration(hintText: hint)),
    ],
  );
}
