import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/platform_file_image.dart';
import '../models/pet.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';
import 'add_pet_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<PetModel> _pets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '${ApiConstants.petsEndpoint}/$userId',
        token: token,
      );
      if (mounted) {
        setState(() {
          _pets = (data as List<dynamic>)
              .map((p) => PetModel.fromJson(p as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPet() async {
    final pet = await Navigator.push<PetModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    if (pet == null || !mounted) return;

    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;

    try {
      await ApiService.post(
        '${ApiConstants.petsEndpoint}/$userId',
        {
          'name': pet.name,
          'type': pet.type,
          'breed': pet.breed,
          'age': pet.age,
        },
        token: token,
      );
      await _loadPets();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao cadastrar pet'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _deletePet(PetModel pet) async {
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.delete('/pets/${pet.id}', token: token);
      await _loadPets();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao remover pet'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _confirmDelete(PetModel pet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover pet'),
        content: Text('Deseja remover ${pet.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePet(pet);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remover',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _pets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets,
                          size: 64, color: AppColors.greyLight),
                      const SizedBox(height: 16),
                      const Text('Nenhum pet cadastrado',
                          style:
                              TextStyle(color: AppColors.grey, fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text('Toque no + para adicionar',
                          style:
                              TextStyle(color: AppColors.grey, fontSize: 13)),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadPets,
                        icon: const Icon(Icons.refresh,
                            color: AppColors.primary),
                        label: const Text('Atualizar',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPets,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: _pets.length,
                    itemBuilder: (ctx, i) => _PetCard(
                      pet: _pets[i],
                      onDelete: () => _confirmDelete(_pets[i]),
                    ),
                  ),
                ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onDelete;
  const _PetCard({required this.pet, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: fileImageProvider(pet.imageUrl),
            child: pet.imageUrl == null
                ? Text(pet.typeIcon, style: const TextStyle(fontSize: 24))
                : null,
          ),
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
                Text('${pet.breed} • ${pet.age} anos',
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.grey)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Remover')),
            ],
            child: const Icon(Icons.more_vert, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
