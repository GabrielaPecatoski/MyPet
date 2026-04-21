import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscureSenha = true;
  bool _isEstabelecimento = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, auth.homeRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao fazer login'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 112),

              Image.asset('assets/images/logo.png', height: 110),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('E-mail'),
                      _field(
                        _emailCtrl,
                        'lorem@hotmail.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || !v.contains('@') ? 'E-mail inválido' : null,
                      ),
                      const SizedBox(height: 14),

                      _label('Senha'),
                      TextFormField(
                        controller: _senhaCtrl,
                        obscureText: _obscureSenha,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: _decoration('••••••••••••').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureSenha = !_obscureSenha),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Esqueceu sua senha?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não tem uma conta? ',
                      style: TextStyle(color: AppColors.grey, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/register',
                      arguments: _isEstabelecimento,
                    ),
                    child: const Text(
                      'Criar Conta',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => setState(() => _isEstabelecimento = !_isEstabelecimento),
                child: Text(
                  _isEstabelecimento ? 'Sou um Cliente' : 'Sou um estabelecimento',
                  style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        enableSuggestions: false,
        autocorrect: false,
        decoration: _decoration(hint),
        validator: validator,
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.greyLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.greyLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
      );
}
