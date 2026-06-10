import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
class RegisterScreen extends StatefulWidget {
  final int initialTipo;
  const RegisterScreen({super.key, this.initialTipo = 0});
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
  final _cnhCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehiclePlateCtrl = TextEditingController();
  final _crmvCtrl = TextEditingController();
  final _especialidadeVetCtrl = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirm = true;
  late int _tipoUsuario;
  String _vehicleType = 'CARRO';
  String? _photoPath;
  String? _crmvPhotoPath;
  static const _vehicleTypes = [
    ('CARRO', 'Carro', Icons.directions_car),
    ('MOTO', 'Moto', Icons.two_wheeler),
    ('VAN', 'Van', Icons.airport_shuttle),
  ];
  static const _tiposMeta = [
    _TipoMeta(
      tipo: 0,
      label: 'Tutor',
      icon: Icons.pets_rounded,
      accent: AppColors.primary,
      desc: 'Tutores de pets',
    ),
    _TipoMeta(
      tipo: 1,
      label: 'Estabelecimento',
      icon: Icons.store_rounded,
      accent: Color(0xFF0EA5E9),
      desc: 'Pet shop, clínica...',
    ),
    _TipoMeta(
      tipo: 2,
      label: 'Motorista',
      icon: Icons.airport_shuttle_rounded,
      accent: Color(0xFFF97316),
      desc: 'Transporte de pets',
    ),
    _TipoMeta(
      tipo: 3,
      label: 'Veterinário',
      icon: Icons.medical_services_rounded,
      accent: Color(0xFF16A34A),
      desc: 'Atendimento clínico',
    ),
  ];
  _TipoMeta get _meta =>
      _tiposMeta.firstWhere((t) => t.tipo == _tipoUsuario);

  @override
  void initState() {
    super.initState();
    _tipoUsuario = widget.initialTipo;
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
    _cnhCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehiclePlateCtrl.dispose();
    _crmvCtrl.dispose();
    _especialidadeVetCtrl.dispose();
    super.dispose();
  }
  Future<void> _pickPhoto() async {
    if (kIsWeb) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) setState(() => _photoPath = picked.path);
  }

  Future<void> _pickCrmvPhoto() async {
    if (kIsWeb) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) setState(() => _crmvPhotoPath = picked.path);
  }
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final role = switch (_tipoUsuario) {
      1 => 'VENDEDOR',
      2 => 'MOTORISTA',
      3 => 'VETERINARIO',
      _ => 'CLIENTE',
    };
    final ok = await auth.register(
      name: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _senhaCtrl.text,
      phone: _telefoneCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      role: role,
      businessName:
          _tipoUsuario == 1 ? _nomeEstabCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao criar conta'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (_photoPath != null && auth.user != null) {
      auth.updateUser(auth.user!.copyWith(photoPath: _photoPath));
    }
    if (_tipoUsuario == 2) {
      await _registerDriverProfile(auth);
    } else if (_tipoUsuario == 3) {
      await _registerVetProfile(auth);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, auth.homeRoute, (r) => false);
    }
  }
  Future<void> _registerDriverProfile(AuthProvider auth) async {
    final err = await auth.registerDriverProfile(
      name: _nomeCtrl.text.trim(),
      phone: _telefoneCtrl.text.trim(),
      cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
      cnh: _cnhCtrl.text.trim(),
      vehicleType: _vehicleType,
      vehicleModel: _vehicleModelCtrl.text.trim(),
      vehiclePlate: _vehiclePlateCtrl.text.trim().toUpperCase(),
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Conta criada, mas erro ao salvar veículo: $err'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, auth.homeRoute, (r) => false);
    }
  }

  Future<void> _registerVetProfile(AuthProvider auth) async {
    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    final err = await auth.registerVetProfile(
      name: _nomeCtrl.text.trim(),
      phone: _telefoneCtrl.text.trim(),
      cpf: cpf,
      crmv: _crmvCtrl.text.trim().toUpperCase(),
      especialidade: _especialidadeVetCtrl.text.trim().isEmpty
          ? null
          : _especialidadeVetCtrl.text.trim(),
    );
    if (_crmvPhotoPath != null) {
      await StorageService.saveCrmvPhoto(cpf, _crmvPhotoPath);
    }
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Conta criada, mas erro ao salvar perfil vet: $err'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, auth.homeRoute, (r) => false);
    }
  }
  void _switchTipo(int tipo) {
    setState(() {
      _tipoUsuario = tipo;
      _nomeCtrl.clear();
      _cpfCtrl.clear();
      _emailCtrl.clear();
      _telefoneCtrl.clear();
      _senhaCtrl.clear();
      _confirmSenhaCtrl.clear();
      _nomeEstabCtrl.clear();
      _cnhCtrl.clear();
      _vehicleModelCtrl.clear();
      _vehiclePlateCtrl.clear();
      _crmvCtrl.clear();
      _especialidadeVetCtrl.clear();
    });
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meta = _meta;
    final top = MediaQuery.of(context).padding.top;
    final isEstab = _tipoUsuario == 1;
    final isMotorista = _tipoUsuario == 2;
    final isVeterinario = _tipoUsuario == 3;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(
            top: top,
            meta: meta,
            photoPath: _photoPath,
            onPickPhoto: _pickPhoto,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoleChips(
                    selected: _tipoUsuario,
                    tipos: _tiposMeta,
                    onSelect: _switchTipo,
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.person_outline,
                          label: 'Dados pessoais',
                          color: meta.accent,
                        ),
                        const SizedBox(height: 14),
                        _label(isEstab
                            ? 'Nome completo do responsável'
                            : 'Nome completo'),
                        _field(_nomeCtrl, 'Ex: Maria Silva',
                            keyboardType: TextInputType.name,
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Informe o nome'
                                    : null),
                        const SizedBox(height: 14),
                        _label(isEstab ? 'CPF do responsável' : 'CPF'),
                        _field(
                            _cpfCtrl,
                            isEstab
                                ? 'CPF do responsável'
                                : '000.000.000-00',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Informe o CPF';
                              if (isMotorista) {
                                final d = v.replaceAll(RegExp(r'\D'), '');
                                if (d.length != 11)
                                  return 'CPF deve ter 11 dígitos';
                              }
                              return null;
                            }),
                        const SizedBox(height: 14),
                        if (isEstab) ...[
                          _label('Nome do estabelecimento'),
                          _field(_nomeEstabCtrl, 'Ex: Pet Shop do Bairro',
                              keyboardType: TextInputType.text,
                              validator: (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o nome do estabelecimento'
                                      : null),
                          const SizedBox(height: 14),
                        ],
                        _label('Telefone'),
                        _field(_telefoneCtrl, '(11) 99999-9999',
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Informe o telefone'
                                    : null),
                        const SizedBox(height: 14),
                        _label('E-mail'),
                        _field(_emailCtrl, 'voce@email.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v == null || !v.contains('@')
                                    ? 'E-mail inválido'
                                    : null),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          icon: Icons.lock_outline,
                          label: 'Segurança',
                          color: meta.accent,
                        ),
                        const SizedBox(height: 14),
                        _label('Senha'),
                        _passwordField(
                          ctrl: _senhaCtrl,
                          obscure: _obscureSenha,
                          onToggle: () => setState(
                              () => _obscureSenha = !_obscureSenha),
                          validator: (v) =>
                              v == null || v.length < 6
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        _label('Confirmar senha'),
                        _passwordField(
                          ctrl: _confirmSenhaCtrl,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          validator: (v) =>
                              v != _senhaCtrl.text
                                  ? 'Senhas não coincidem'
                                  : null,
                        ),
                        if (isVeterinario) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            icon: Icons.badge_outlined,
                            label: 'Dados profissionais',
                            color: meta.accent,
                          ),
                          const SizedBox(height: 14),
                          _label('CRMV (ex: SP-12345)'),
                          _field(_crmvCtrl, 'Ex: SP-12345',
                              caps: TextCapitalization.characters,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Informe o CRMV'
                                      : null),
                          const SizedBox(height: 14),
                          _label('Especialidade (opcional)'),
                          _field(_especialidadeVetCtrl,
                              'Ex: Ortopedia, Dermatologia'),
                          const SizedBox(height: 14),
                          _CrmvPhotoField(
                            photoPath: _crmvPhotoPath,
                            onPick: _pickCrmvPhoto,
                          ),
                        ],
                        if (isMotorista) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            icon: Icons.directions_car_outlined,
                            label: 'Dados do veículo',
                            color: meta.accent,
                          ),
                          const SizedBox(height: 14),
                          _label('CNH (número)'),
                          _field(_cnhCtrl, 'Número da CNH',
                              validator: (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe a CNH'
                                      : null),
                          const SizedBox(height: 14),
                          _label('Tipo de veículo'),
                          Row(
                            children: _vehicleTypes.map((t) {
                              final (value, label, icon) = t;
                              final sel = _vehicleType == value;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _vehicleType = value),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    margin:
                                        const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? meta.accent
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? meta.accent
                                            : AppColors.greyLight,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(icon,
                                            size: 20,
                                            color: sel
                                                ? Colors.white
                                                : AppColors.grey),
                                        const SizedBox(height: 3),
                                        Text(label,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: sel
                                                    ? Colors.white
                                                    : AppColors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          _label('Modelo do veículo (ex: Fiat Uno)'),
                          _field(_vehicleModelCtrl, 'Ex: Fiat Uno',
                              validator: (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o modelo'
                                      : null),
                          const SizedBox(height: 14),
                          _label('Placa (ex: ABC1D23)'),
                          _field(
                            _vehiclePlateCtrl,
                            'Ex: ABC1D23',
                            caps: TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Informe a placa';
                              if (v.trim().length < 7)
                                return 'Placa inválida';
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                meta.accent,
                                meta.accent.withValues(alpha: 0.78),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: meta.accent.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: auth.isLoading ? null : _register,
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'Criar conta',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Já tem uma conta? ',
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text(
                                'Entrar agora',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
      );
  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    TextCapitalization caps = TextCapitalization.none,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: caps,
        style: const TextStyle(fontSize: 14, color: AppColors.dark),
        decoration: _decoration(hint),
        validator: validator,
      );
  Widget _passwordField({
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: AppColors.dark),
        decoration: _decoration('••••••••••••').copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.grey,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
        validator: validator,
      );
  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.greyLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.greyLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.danger, width: 1.5)),
      );
}
class _Header extends StatelessWidget {
  final double top;
  final _TipoMeta meta;
  final String? photoPath;
  final VoidCallback onPickPhoto;
  const _Header({
    required this.top,
    required this.meta,
    required this.photoPath,
    required this.onPickPhoto,
  });
  @override
  Widget build(BuildContext context) {
    final accent = meta.accent;
    final accentDark =
        Color.lerp(accent, Colors.black, 0.25) ?? accent;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentDark, accent],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/welcome'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  Icon(meta.icon, color: Colors.white, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'Cadastro — ${meta.label}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPickPhoto,
            child: Stack(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2.5),
                  ),
                  child: photoPath != null && !kIsWeb
                      ? ClipOval(
                          child: Image.file(
                            File(photoPath!),
                            fit: BoxFit.cover,
                            width: 82,
                            height: 82,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 26),
                            const SizedBox(height: 2),
                            Text(
                              'Foto',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6)
                      ],
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 16, color: accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toque para adicionar sua foto',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
class _RoleChips extends StatelessWidget {
  final int selected;
  final List<_TipoMeta> tipos;
  final void Function(int) onSelect;
  const _RoleChips({
    required this.selected,
    required this.tipos,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de conta',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tipos.map((t) {
              final sel = selected == t.tipo;
              return GestureDetector(
                onTap: () => onSelect(t.tipo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel
                        ? t.accent
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: sel ? t.accent : AppColors.greyLight,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: t.accent.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon,
                          size: 15,
                          color: sel ? Colors.white : AppColors.grey),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              sel ? Colors.white : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.dark),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: AppColors.greyLight)),
      ],
    );
  }
}
class _TipoMeta {
  final int tipo;
  final String label;
  final IconData icon;
  final Color accent;
  final String desc;
  const _TipoMeta({
    required this.tipo,
    required this.label,
    required this.icon,
    required this.accent,
    required this.desc,
  });
}

class _CrmvPhotoField extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPick;
  const _CrmvPhotoField({required this.photoPath, required this.onPick});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    const green = Color(0xFF16A34A);

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: photoPath != null ? green : AppColors.greyLight,
          ),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (photoPath != null ? green : green).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: photoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(photoPath!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.badge_outlined, color: green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                photoPath != null ? 'Diploma/CRMV anexado' : 'Foto do diploma ou CRMV',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: photoPath != null ? green : AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                photoPath != null ? 'Toque para trocar' : 'Enviar comprovante (só o admin verá)',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ]),
          ),
          Icon(
            photoPath != null ? Icons.check_circle : Icons.add_a_photo_outlined,
            color: photoPath != null ? green : green,
            size: 20,
          ),
        ]),
      ),
    );
  }
}
