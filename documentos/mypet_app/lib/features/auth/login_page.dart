import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal:24), child: Column(children: [
        const SizedBox(height:48),
        Container(width:90, height:90, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle), child: const Icon(Icons.pets, color: AppColors.primary, size:48)),
        const SizedBox(height:12),
        const Text('My Pet', style: TextStyle(fontSize:28, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height:6),
        const Text('Agende servicos para seu pet com facilidade', style: TextStyle(fontSize:13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height:32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius:16, offset: const Offset(0,4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600, fontSize:14)),
            const SizedBox(height:8),
            const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'loren@hotmail.com')),
            const SizedBox(height:16),
            const Text('Senha', style: TextStyle(fontWeight: FontWeight.w600, fontSize:14)),
            const SizedBox(height:8),
            TextField(
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '................',
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size:20), onPressed: () => setState(() => _obscure = !_obscure)),
              ),
            ),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Esqueceu sua senha?', style: TextStyle(color: AppColors.primary, fontSize:13)))),
            ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/shell'), child: const Text('Entrar')),
            const SizedBox(height:16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Nao tem uma conta?  ', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
              GestureDetector(onTap: () => Navigator.pushNamed(context, '/register'), child: const Text('Criar Conta', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize:13))),
            ]),
          ]),
        ),
        const SizedBox(height:32),
        const Text('Sou um estabelecimento', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
        const SizedBox(height:24),
      ]))),
    );
  }
}
