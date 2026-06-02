import 'dart:io';
<<<<<<< HEAD
=======
import 'package:flutter/foundation.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _telefoneCtrl;
  String? _newPhotoPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nomeCtrl = TextEditingController(text: user?.name ?? '');
    _telefoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
<<<<<<< HEAD
=======
    if (kIsWeb) return;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _newPhotoPath = picked.path);
    }
  }

<<<<<<< HEAD
  void _salvar() {
=======
  Future<void> _salvar() async {
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final ok = await auth.updateProfile(
      name: _nomeCtrl.text.trim(),
      phone: _telefoneCtrl.text.trim(),
<<<<<<< HEAD
      cpf: current.cpf,
      role: current.role,
      photoPath: _newPhotoPath ?? current.photoPath,
    );
    auth.updateUser(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
=======
    );

    if (!mounted) return;

    if (ok) {
      if (_newPhotoPath != null) {
        auth.updateUser(auth.user!.copyWith(photoPath: _newPhotoPath));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao atualizar perfil.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onNavTap(int index) {
    if (index == 4) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false,
          arguments: index);
    }
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  }

  void _onNavTap(int index) {
    if (index == 4) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false,
          arguments: index);
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final user = context.watch<AuthProvider>().user;
=======
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    final photoPath = _newPhotoPath ?? user?.photoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        items: clientNavItems,
        onTap: _onNavTap,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
<<<<<<< HEAD
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage:
                          photoPath != null ? FileImage(File(photoPath)) : null,
                      child: photoPath == null
                          ? const Icon(Icons.person,
                              size: 52, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
=======
            if (!kIsWeb)
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage:
                            photoPath != null ? FileImage(File(photoPath)) : null,
                        child: photoPath == null
                            ? const Icon(Icons.person,
                                size: 52, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!kIsWeb) const SizedBox(height: 24),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nome Completo'),
<<<<<<< HEAD
                    _field(_nomeCtrl,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe o nome' : null),
                    const SizedBox(height: 16),
                    _label('E-mail'),
                    _field(_emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'E-mail inválido'
                            : null),
                    const SizedBox(height: 16),
                    _label('Telefone'),
                    _field(_telefoneCtrl,
                        keyboardType: TextInputType.phone),
=======
                    _field(
                      _nomeCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Telefone'),
                    _field(
                      _telefoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _label('E-mail'),
                    _readOnlyField(user?.email ?? ''),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
<<<<<<< HEAD
                ),
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
=======
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Salvar Alterações',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.greyLight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
      );

  Widget _field(
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: AppColors.grey),
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.greyLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.greyLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
<<<<<<< HEAD
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
=======
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
        ),
        validator: validator,
      );

  Widget _readOnlyField(String value) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.greyLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.grey),
        ),
      );
}
