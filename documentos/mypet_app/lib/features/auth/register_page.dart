import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  bool _o1 = true, _o2 = true;

  Widget _field(String label, String hint, {TextInputType type = TextInputType.text}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:14)), const SizedBox(height:6), TextField(keyboardType: type, decoration: InputDecoration(hintText: hint))],
  );
  Widget _pf(String label, bool obs, VoidCallback t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:14)), const SizedBox(height:6), TextField(obscureText: obs, decoration: InputDecoration(hintText: '................', suffixIcon: IconButton(icon: Icon(obs ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size:20), onPressed: t)))],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal:24), child: Column(children: [
        const SizedBox(height:32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width:30, height:30, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle), child: const Icon(Icons.pets, color: AppColors.primary, size:17)),
          const SizedBox(width:6),
          const Text('My Pet', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize:20)),
        ]),
        const SizedBox(height:6),
        const Text('Agende servicos para seu pet com facilidade', style: TextStyle(fontSize:12, color: AppColors.textSecondary)),
        const SizedBox(height:24),
        GestureDetector(onTap: () {}, child: Container(width:90, height:90, decoration: const BoxDecoration(color: AppColors.divider, shape: BoxShape.circle), child: const Icon(Icons.download, color: AppColors.textSecondary, size:32))),
        const SizedBox(height:24),
        _field('Nome Completo', 'loren'),
        const SizedBox(height:12),
        _field('CPF', '000.000.000-00'),
        const SizedBox(height:12),
        _field('Email', 'loren@hotmail.com', type: TextInputType.emailAddress),
        const SizedBox(height:12),
        _field('Telefone', '(11) 99999-9999', type: TextInputType.phone),
        const SizedBox(height:12),
        _pf('Senha', _o1, () => setState(() => _o1 = !_o1)),
        const SizedBox(height:12),
        _pf('Confirmar Senha', _o2, () => setState(() => _o2 = !_o2)),
        const SizedBox(height:24),
        ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/shell'), child: const Text('Criar Conta')),
        const SizedBox(height:16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Ja tem uma conta?  ', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
          GestureDetector(onTap: () => Navigator.pop(context), child: const Text('Logar agora', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize:13))),
        ]),
        const SizedBox(height:24),
      ]))),
    );
  }
}
