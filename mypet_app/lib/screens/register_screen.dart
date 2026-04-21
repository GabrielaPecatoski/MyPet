import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmSenhaCtrl = TextEditingController();
  final _nomeEstabCtrl = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirm = true;
  bool _isEstabelecimento = false;
  String? _photoPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is bool) _isEstabelecimento = arg;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmSenhaCtrl.dispose();
    _nomeEstabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (kIsWeb) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _senhaCtrl.text,
      phone: _telefoneCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      role: _isEstabelecimento ? 'VENDEDOR' : 'CLIENTE',
      businessName: _isEstabelecimento ? _nomeEstabCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (ok) {
      if (_photoPath != null && auth.user != null) {
        auth.updateUser(auth.user!.copyWith(photoPath: _photoPath));
      }
      Navigator.pushReplacementNamed(context, auth.homeRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao criar conta'),
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
              const SizedBox(height: 10),

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
                child: Column(
                  children: [
                    // Foto de perfil
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(43),
                        ),
                        child: _photoPath != null && !kIsWeb
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(43),
                                child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                              )
                            : const Icon(Icons.download, size: 32, color: AppColors.dark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(_isEstabelecimento
                              ? 'Nome completo do responsável'
                              : 'Nome Completo'),
                          _field(_nomeCtrl, 'Ex: Maria Silva',
                              keyboardType: TextInputType.name,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Informe o nome' : null),
                          const SizedBox(height: 14),

                          _label(_isEstabelecimento ? 'CPF do responsável' : 'CPF'),
                          _field(
                              _cpfCtrl,
                              _isEstabelecimento
                                  ? 'CPF do responsável'
                                  : '000.000.000-00',
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Informe o CPF' : null),
                          const SizedBox(height: 14),

                          if (_isEstabelecimento) ...[
                            _label('Nome do Estabelecimento'),
                            _field(_nomeEstabCtrl, 'Ex: Pet Shop do Bairro',
                                keyboardType: TextInputType.text,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Informe o nome do estabelecimento'
                                    : null),
                            const SizedBox(height: 14),
                          ],

                          _label('Telefone'),
                          _field(_telefoneCtrl, '(11) 99999-9999',
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Informe o telefone' : null),
                          const SizedBox(height: 14),

                          _label('E-mail'),
                          _field(_emailCtrl, 'loren@hotmail.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v == null || !v.contains('@') ? 'E-mail inválido' : null),
                          const SizedBox(height: 14),

                          _label('Senha'),
                          TextFormField(
                            controller: _senhaCtrl,
                            obscureText: _obscureSenha,
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
                          const SizedBox(height: 14),

                          _label('Confirmar Senha'),
                          TextFormField(
                            controller: _confirmSenhaCtrl,
                            obscureText: _obscureConfirm,
                            decoration: _decoration('••••••••••••').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.grey,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) =>
                                v != _senhaCtrl.text ? 'Senhas não coincidem' : null,
                          ),
                          const SizedBox(height: 24),

                          // Botão Criar Conta
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
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
                                      'Criar Conta',
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
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem uma conta? ',
                      style: TextStyle(color: AppColors.grey, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Logar agora',
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
                onTap: () => setState(() {
                  _isEstabelecimento = !_isEstabelecimento;
                  _nomeCtrl.clear();
                  _cpfCtrl.clear();
                  _emailCtrl.clear();
                  _telefoneCtrl.clear();
                  _senhaCtrl.clear();
                  _confirmSenhaCtrl.clear();
                  _nomeEstabCtrl.clear();
                }),
                child: Text(
                  _isEstabelecimento ? 'Sou um Cliente' : 'Sou um estabelecimento',
                  style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                      decoration: TextDecoration.underline),
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
