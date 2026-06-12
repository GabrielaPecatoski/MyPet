import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../models/pet.dart';
import '../widgets/mypet_app_bar.dart';

class AddPetScreen extends StatefulWidget {
  final PetModel? initialPet;
  const AddPetScreen({super.key, this.initialPet});
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _racaCtrl = TextEditingController();
  final _idadeCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _outroCtrl = TextEditingController();
  String _tipoSelecionado = 'Cachorro';
  Uint8List? _imageBytes;
  String? _existingImageUrl;

  bool get _isEditing => widget.initialPet != null;

  static const _tipos = [
    ('Cachorro', '🐶', Icons.pets),
    ('Gato', '🐱', Icons.cruelty_free_outlined),
    ('Outro', '🐾', Icons.emoji_nature_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final pet = widget.initialPet;
    if (pet != null) {
      _nomeCtrl.text = pet.name;
      _racaCtrl.text = pet.breed;
      _idadeCtrl.text = pet.age.toString();
      _pesoCtrl.text = pet.weight != null ? pet.weight.toString() : '';
      _existingImageUrl = pet.imageUrl;
      if (pet.type == 'Cachorro' || pet.type == 'Gato') {
        _tipoSelecionado = pet.type;
      } else {
        _tipoSelecionado = 'Outro';
        _outroCtrl.text = pet.type;
      }
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _racaCtrl.dispose();
    _idadeCtrl.dispose();
    _pesoCtrl.dispose();
    _outroCtrl.dispose();
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
                    color: AppColors.primary),
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
                    color: AppColors.primary),
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

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSelecionado == 'Outro' && _outroCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o tipo do animal')),
      );
      return;
    }
    String? imageUrl;
    if (_imageBytes != null) {
      imageUrl = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
    } else {
      imageUrl = _existingImageUrl;
    }
    final peso = double.tryParse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final tipo = _tipoSelecionado == 'Outro'
        ? _outroCtrl.text.trim()
        : _tipoSelecionado;
    final pet = PetModel(
      id: widget.initialPet?.id ?? '',
      name: _nomeCtrl.text.trim(),
      type: tipo,
      breed: _racaCtrl.text.trim(),
      age: int.tryParse(_idadeCtrl.text.trim()) ?? 0,
      weight: peso,
      imageUrl: imageUrl,
    );
    Navigator.pop(context, pet);
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                _isEditing ? 'Editar Pet' : 'Cadastrar Pet',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Atualize as informações do seu pet'
                    : 'Adicione as informações do seu pet',
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 24),

              if (!kIsWeb)
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
                              color: AppColors.primary,
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
              if (!kIsWeb) const SizedBox(height: 28),

              _sectionTitle('Tipo do Pet'),
              const SizedBox(height: 10),
              Row(
                children: _tipos.map((t) {
                  final selected = _tipoSelecionado == t.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tipoSelecionado = t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.greyLight,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              t.$1 == 'Cachorro'
                                  ? '🐶'
                                  : t.$1 == 'Gato'
                                      ? '🐱'
                                      : '🐾',
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(t.$1,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.dark)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_tipoSelecionado == 'Outro') ...[
                const SizedBox(height: 14),
                _sectionTitle('Qual é o animal?'),
                const SizedBox(height: 8),
                _field(
                  controller: _outroCtrl,
                  hint: 'Ex: Coelho, Hamster, Pássaro...',
                  icon: Icons.emoji_nature_outlined,
                ),
              ],
              const SizedBox(height: 20),

              _sectionTitle('Nome do Pet'),
              const SizedBox(height: 8),
              _field(
                controller: _nomeCtrl,
                hint: 'Ex: Rex, Mel, Bolinha...',
                icon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              _sectionTitle('Raça'),
              const SizedBox(height: 8),
              _field(
                controller: _racaCtrl,
                hint: 'Ex: Labrador, Persa, Vira-lata...',
                icon: Icons.category_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a raça' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Idade'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _idadeCtrl,
                          hint: 'Anos',
                          icon: Icons.cake_outlined,
                          isNumber: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Informe';
                            if (int.tryParse(v) == null) return 'Inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Peso (kg)'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _pesoCtrl,
                          hint: 'Ex: 4.5',
                          icon: Icons.monitor_weight_outlined,
                          isDecimal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

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
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEditing ? 'Salvar Alterações' : 'Cadastrar Pet',
                        style: const TextStyle(
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
          image:
              DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 36, color: AppColors.primary),
        ],
      ),
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
    bool isNumber = false,
    bool isDecimal = false,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : isNumber
                ? TextInputType.number
                : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.grey, size: 20),
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
                  const BorderSide(color: AppColors.primary, width: 1.5)),
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
