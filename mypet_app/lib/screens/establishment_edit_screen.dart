import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../widgets/mypet_app_bar.dart';

class EstabEditScreen extends StatefulWidget {
  const EstabEditScreen({super.key});

  @override
  State<EstabEditScreen> createState() => _EstabEditScreenState();
}

class _EstabEditScreenState extends State<EstabEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _enderecoCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _crmvCtrl;
  String _tipo = 'PET_SHOP';
  bool _atendeEmergencia = false;
  bool _atendimento24h = false;
  bool _receberAlertaSonoro = false;
  bool _receberPushEmergencia = false;
  Uint8List? _imageBytes;
  String? _existingImageUrl;

  bool get _isVeterinario => _tipo == 'VETERINARIA' || _tipo == 'HIBRIDO';

  @override
  void initState() {
    super.initState();
    final estab = context.read<EstablishmentProvider>().establishment;
    _nomeCtrl = TextEditingController(text: estab?.name ?? '');
    _descCtrl = TextEditingController(text: estab?.description ?? '');
    _enderecoCtrl = TextEditingController(text: estab?.rawAddress ?? '');
    _cidadeCtrl = TextEditingController(text: estab?.city ?? '');
    _telefoneCtrl = TextEditingController(text: estab?.phone ?? '');
    _crmvCtrl = TextEditingController(text: estab?.crmv ?? '');
    _tipo = estab?.type ?? 'PET_SHOP';
    _atendeEmergencia = estab?.atendeEmergencia ?? false;
    _atendimento24h = estab?.atendimento24h ?? false;
    _receberAlertaSonoro = estab?.receberAlertaSonoro ?? false;
    _receberPushEmergencia = estab?.receberPushEmergencia ?? false;
    _existingImageUrl = estab?.imageUrl;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _enderecoCtrl.dispose();
    _cidadeCtrl.dispose();
    _telefoneCtrl.dispose();
    _crmvCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  void _showImageOptions() {
    if (kIsWeb) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.estab),
              ),
              title: const Text('Galeria de fotos',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.estab),
              ),
              title: const Text('Câmera',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<EstablishmentProvider>();

    String? imageUrl;
    if (_imageBytes != null) {
      imageUrl = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
    } else {
      imageUrl = _existingImageUrl;
    }

    final ok = await provider.updateEstablishment(
      token: auth.token ?? '',
      name: _nomeCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      address: _enderecoCtrl.text.trim(),
      city: _cidadeCtrl.text.trim(),
      phone: _telefoneCtrl.text.trim(),
      type: _tipo,
      imageUrl: imageUrl,
      crmv: _crmvCtrl.text.trim().isEmpty ? null : _crmvCtrl.text.trim(),
      atendeEmergencia: _atendeEmergencia,
      atendimento24h: _atendimento24h,
      receberAlertaSonoro: _receberAlertaSonoro,
      receberPushEmergencia: _receberPushEmergencia,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estabelecimento atualizado com sucesso!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erro ao atualizar estabelecimento.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EstablishmentProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar Estabelecimento',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Atualize as informações do seu negócio',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 24),

              if (!kIsWeb) ...[
                Center(
                  child: GestureDetector(
                    onTap: _showImageOptions,
                    child: Stack(
                      children: [
                        _buildAvatar(),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppColors.estab,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              _sectionTitle('Tipo de Estabelecimento'),
              const SizedBox(height: 10),
              _buildTipoSelector(),
              const SizedBox(height: 20),

              _sectionTitle('Nome do Estabelecimento'),
              const SizedBox(height: 8),
              _field(
                controller: _nomeCtrl,
                hint: 'Ex: Pet Shop do João',
                icon: Icons.store_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              _sectionTitle('Telefone'),
              const SizedBox(height: 8),
              _field(
                controller: _telefoneCtrl,
                hint: 'Ex: (11) 99999-9999',
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _sectionTitle('Descrição'),
              const SizedBox(height: 8),
              _field(
                controller: _descCtrl,
                hint: 'Descreva seu estabelecimento...',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Endereço'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _enderecoCtrl,
                          hint: 'Rua, número...',
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Cidade'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _cidadeCtrl,
                          hint: 'Cidade',
                          icon: Icons.location_city_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isVeterinario) ...[
                _dividerSection('Informações Veterinárias'),
                const SizedBox(height: 12),

                _sectionTitle('CRMV (opcional)'),
                const SizedBox(height: 8),
                _field(
                  controller: _crmvCtrl,
                  hint: 'Ex: CRMV-SP 12345',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),

                _dividerSection('Configurações de Atendimento'),
                const SizedBox(height: 8),
                _switchTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.danger,
                  title: 'Atende Emergências',
                  subtitle: 'Recebe solicitações de emergência veterinária',
                  value: _atendeEmergencia,
                  onChanged: (v) => setState(() => _atendeEmergencia = v),
                ),
                _switchTile(
                  icon: Icons.access_time_filled,
                  iconColor: AppColors.estab,
                  title: 'Atendimento 24 Horas',
                  subtitle: 'Funciona 24h por dia',
                  value: _atendimento24h,
                  onChanged: (v) => setState(() => _atendimento24h = v),
                ),

                _dividerSection('Notificações de Emergência'),
                const SizedBox(height: 8),
                _switchTile(
                  icon: Icons.volume_up_rounded,
                  iconColor: AppColors.warning,
                  title: 'Receber Alerta Sonoro',
                  subtitle: 'Emite som ao receber emergência',
                  value: _receberAlertaSonoro,
                  onChanged: (v) => setState(() => _receberAlertaSonoro = v),
                ),
                _switchTile(
                  icon: Icons.notifications_active_outlined,
                  iconColor: AppColors.warning,
                  title: 'Receber Push de Emergência',
                  subtitle: 'Notificação push para emergências',
                  value: _receberPushEmergencia,
                  onChanged: (v) => setState(() => _receberPushEmergencia = v),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: AppColors.greyLight),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w500,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.estab,
                        disabledBackgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Column(
      children: [
        _switchTile(
          icon: Icons.local_hospital_outlined,
          iconColor: const Color(0xFF16A34A),
          title: 'Tem atendimento veterinário',
          subtitle: 'Ativa categorias de serviços veterinários',
          value: _isVeterinario,
          onChanged: (v) => setState(() {
            _tipo = v ? 'HIBRIDO' : 'PET_SHOP';
          }),
        ),
        if (_isVeterinario) ...[
          const SizedBox(height: 6),
          _switchTile(
            icon: Icons.store_outlined,
            iconColor: AppColors.estab,
            title: 'Também é pet shop',
            subtitle: 'Desative se for apenas clínica veterinária',
            value: _tipo == 'HIBRIDO',
            onChanged: (v) => setState(() {
              _tipo = v ? 'HIBRIDO' : 'VETERINARIA';
            }),
          ),
        ],
      ],
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          value: value,
          activeThumbColor: AppColors.estab,
          onChanged: onChanged,
        ),
      );

  Widget _dividerSection(String label) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey)),
            const SizedBox(width: 8),
            const Expanded(child: Divider(color: AppColors.greyLight)),
          ],
        ),
      );

  Widget _buildAvatar() {
    if (_imageBytes != null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
              image: MemoryImage(_imageBytes!), fit: BoxFit.cover),
        ),
      );
    }
    final url = _existingImageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image/')) {
        final bytes = base64Decode(url.split(',').last);
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: MemoryImage(bytes), fit: BoxFit.cover),
          ),
        );
      }
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
              image: NetworkImage(url), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.store, size: 40, color: AppColors.estab),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.grey, size: 20)
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.greyLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.greyLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.estab, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 1.5)),
        ),
        validator: validator,
      );
}
