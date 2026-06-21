import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/pet.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../widgets/mypet_app_bar.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context
        .read<PetProvider>()
        .load(auth.user!.id, token: auth.token);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Map<String, dynamic> _formToData(PetModel form, {bool nullableImage = false}) => {
        'name': form.name,
        'type': form.type,
        'breed': form.breed,
        'age': form.age,
        if (form.weight != null) 'weight': form.weight,
        if (nullableImage || form.imageUrl != null) 'imageUrl': form.imageUrl,
      };

  Future<void> _addPet() async {
    final formData =
        await Navigator.pushNamed(context, '/add-pet') as PetModel?;
    if (formData == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final saved = await context.read<PetProvider>().create(
          auth.user!.id,
          _formToData(formData),
          token: auth.token,
        );
    if (saved == null) _showError('Erro ao cadastrar pet. Tente novamente.');
  }

  Future<void> _editPet(PetModel pet) async {
    final formData = await Navigator.pushNamed(
      context, '/add-pet', arguments: pet) as PetModel?;
    if (formData == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final ok = await context.read<PetProvider>().update(
          pet.id,
          _formToData(formData, nullableImage: true),
          token: auth.token,
        );
    if (!ok) _showError('Erro ao atualizar pet. Tente novamente.');
  }

  Future<void> _deletePet(PetModel pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover pet',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.dark)),
        content: Text(
          'Tem certeza que deseja remover ${pet.name}?',
          style: const TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remover',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await context
        .read<PetProvider>()
        .remove(pet.id, token: auth.token);
    if (!ok) _showError('Erro ao remover pet. Tente novamente.');
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Semantics(
              label: 'Adicionar pet',
              button: true,
              onTap: _addPet,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: _addPet,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
      body: petProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: pets.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(Icons.pets,
                                    size: 40, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Nenhum pet cadastrado',
                                  style: TextStyle(
                                      color: AppColors.dark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              const Text('Toque no + para adicionar um pet',
                                  style: TextStyle(
                                      color: AppColors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: pets.length,
                      itemBuilder: (ctx, i) => _PetCard(
                        pet: pets[i],
                        onEdit: () => _editPet(pets[i]),
                        onDelete: () => _deletePet(pets[i]),
                      ),
                    ),
            ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final PetModel pet;
  final double radius;
  const _PetAvatar({required this.pet, required this.radius});

  Widget _placeholder() => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        child: Text(pet.typeIcon, style: TextStyle(fontSize: radius * 0.85)),
      );

  @override
  Widget build(BuildContext context) {
    final url = pet.imageUrl;
    if (url == null || url.isEmpty) return _placeholder();

    if (url.startsWith('data:image/')) {
      final base64Str = url.split(',').last;
      final bytes = base64Decode(base64Str);
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _placeholder(),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PetCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final info = [
      if (pet.breed.isNotEmpty) pet.breed,
      '${pet.age} ${pet.age == 1 ? 'ano' : 'anos'}',
      if (pet.weight != null) '${pet.weight} kg',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _PetAvatar(pet: pet, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.dark)),
                const SizedBox(height: 2),
                Text(info,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primary, size: 20),
            onPressed: onEdit,
            tooltip: 'Editar pet',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 20),
            onPressed: onDelete,
            tooltip: 'Remover pet',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
