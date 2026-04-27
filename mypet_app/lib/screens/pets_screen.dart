import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '/pets/user/${auth.user!.id}',
        token: auth.token,
      );
      final list = data as List;
      setState(() {
        _pets = list.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addPet() async {
    final formData = await Navigator.push<PetModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    if (formData == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    try {
      final result = await ApiService.post(
        '/pets/user/${auth.user!.id}',
        {
          'name': formData.name,
          'type': formData.type,
          'breed': formData.breed,
          'age': formData.age,
        },
        token: auth.token,
      );
      final saved = PetModel.fromJson(result as Map<String, dynamic>);
      setState(() => _pets.add(saved));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao cadastrar pet. Tente novamente.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _pets.isEmpty
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
                                  style:
                                      TextStyle(color: AppColors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: _pets.length,
                      itemBuilder: (ctx, i) => _PetCard(pet: _pets[i]),
                    ),
            ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage:
                pet.imageUrl != null ? FileImage(File(pet.imageUrl!)) : null,
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
                    style: const TextStyle(fontSize: 13, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
