import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_register_provider.dart';
import '../repositories/driver_register_repository.dart';
import '../widgets/app_image.dart';
import '../widgets/mypet_app_bar.dart';

class MotoristaRegisterScreen extends StatelessWidget {
  const MotoristaRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverRegisterProvider(DriverRegisterRepository()),
      child: const _MotoristaRegisterView(),
    );
  }
}

class _MotoristaRegisterView extends StatefulWidget {
  const _MotoristaRegisterView();

  @override
  State<_MotoristaRegisterView> createState() => _MotoristaRegisterViewState();
}

class _MotoristaRegisterViewState extends State<_MotoristaRegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _cnhCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehiclePlateCtrl = TextEditingController();

  String _vehicleType = 'CARRO';
  Uint8List? _cnhPhotoBytes;

  String? _establishmentId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    _establishmentId ??= arg is String ? arg : null;
  }

  static const _vehicleTypes = [
    ('CARRO', 'Carro', Icons.directions_car),
    ('MOTO', 'Moto', Icons.two_wheeler),
    ('VAN', 'Van', Icons.airport_shuttle),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cpfCtrl.dispose();
    _cnhCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehiclePlateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCnhPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _cnhPhotoBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cnhPhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anexe a foto da CNH para continuar'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    final provider = context.read<DriverRegisterProvider>();
    final cpf = _cpfCtrl.text.trim();
    final driver = await provider.submit(
      token: auth.token!,
      establishmentId: _establishmentId,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      cpf: cpf,
      cnh: _cnhCtrl.text.trim(),
      vehicleType: _vehicleType,
      vehicleModel: _vehicleModelCtrl.text.trim(),
      vehiclePlate: _vehiclePlateCtrl.text.trim().toUpperCase(),
      cnhPhotoUrl: dataUrlFromBytes(_cnhPhotoBytes!),
    );
    if (!mounted) return;
    if (driver != null) {
      _showSuccess(driver);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erro ao cadastrar motorista'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(DriverModel driver) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Motorista cadastrado!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Nome:', driver.name),
            _infoRow('Tipo:', driver.vehicleTypeLabel),
            _infoRow('Veículo:', driver.vehicleModel),
            _infoRow('Placa:', driver.vehiclePlate),
            const SizedBox(height: 8),
            const Text(
              'Cadastro enviado. Aguardando aprovação do administrador.',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, driver);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Concluir', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DriverRegisterProvider>().isLoading;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cadastro de Motorista',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark),
              ),
              const SizedBox(height: 4),
              Text(
                _establishmentId != null
                    ? 'O motorista será associado a este estabelecimento.'
                    : 'O motorista ficará disponível para se associar a um estabelecimento.',
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Dados pessoais'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Nome completo', Icons.person, required: true),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Telefone', Icons.phone, required: true, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_cpfCtrl, 'CPF', Icons.badge, required: true, keyboard: TextInputType.number,
                  validator: (v) {
                final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.length != 11) return 'CPF deve ter 11 dígitos';
                return null;
              }),
              const SizedBox(height: 12),
              _field(_cnhCtrl, 'CNH (número)', Icons.credit_card, required: true),
              const SizedBox(height: 12),
              _CnhPhotoField(
                photoBytes: _cnhPhotoBytes,
                onPick: _pickCnhPhoto,
              ),

              const SizedBox(height: 24),
              _sectionTitle('Veículo'),
              const SizedBox(height: 12),

              Row(
                children: _vehicleTypes.map((t) {
                  final (value, label, icon) = t;
                  final selected = _vehicleType == value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _vehicleType = value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.greyLight,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(icon, color: selected ? Colors.white : AppColors.grey, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              _field(_vehicleModelCtrl, 'Modelo (ex: Fiat Uno)', Icons.directions_car, required: true),
              const SizedBox(height: 12),
              _field(
                _vehiclePlateCtrl,
                'Placa (ex: ABC1D23)',
                Icons.confirmation_number,
                required: true,
                caps: TextCapitalization.characters,
                validator: (v) {
                  final plate = v?.trim().toUpperCase() ?? '';
                  if (plate.length < 7) return 'Placa inválida';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Cadastrar Motorista',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.words,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        textCapitalization: caps,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
                : null),
      );
}

class _CnhPhotoField extends StatelessWidget {
  final Uint8List? photoBytes;
  final VoidCallback onPick;
  const _CnhPhotoField({required this.photoBytes, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoBytes != null;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto ? AppColors.success : AppColors.greyLight,
          ),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (hasPhoto ? AppColors.success : AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(photoBytes!, fit: BoxFit.cover),
                  )
                : Icon(Icons.credit_card, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                hasPhoto ? 'Foto da CNH anexada' : 'Foto da CNH *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: hasPhoto ? AppColors.success : AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasPhoto ? 'Toque para trocar' : 'Obrigatória — o admin usa para aprovar o cadastro',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ]),
          ),
          Icon(
            hasPhoto ? Icons.check_circle : Icons.add_a_photo_outlined,
            color: hasPhoto ? AppColors.success : AppColors.primary,
            size: 20,
          ),
        ]),
      ),
    );
  }
}
